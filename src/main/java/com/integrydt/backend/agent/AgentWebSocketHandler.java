package com.integrydt.backend.agent;

import com.fasterxml.jackson.databind.*;
import jakarta.annotation.PreDestroy;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.util.*;
import java.util.concurrent.*;

@Component
public class AgentWebSocketHandler extends TextWebSocketHandler {
    private final JdbcTemplate db;
    private final ObjectMapper json;
    private final ConcurrentMap<String,WebSocketSession> sessions=new ConcurrentHashMap<>();
    private final ConcurrentMap<String,ScheduledFuture<?>> pumps=new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler=Executors.newScheduledThreadPool(4,r->{Thread t=new Thread(r,"integry-agent-pump");t.setDaemon(true);return t;});

    public AgentWebSocketHandler(JdbcTemplate db,ObjectMapper json){this.db=db;this.json=json;}

    @Override public void afterConnectionEstablished(WebSocketSession session)throws Exception{
        String device=(String)session.getAttributes().get("deviceId");
        if(device==null){session.close(CloseStatus.NOT_ACCEPTABLE);return;}
        WebSocketSession old=sessions.put(device,session);
        if(old!=null&&old.isOpen()){try{old.close(CloseStatus.NORMAL);}catch(Exception ignored){}}
        db.update("UPDATE devices SET status='online',last_seen_at=CURRENT_TIMESTAMP(6) WHERE id=?",device);
        recoverOrphans(device);
        ScheduledFuture<?> f=scheduler.scheduleWithFixedDelay(()->{try{pump(session,device);}catch(Exception e){System.err.println("Agent pump "+device+": "+e.getMessage());}},0,500,TimeUnit.MILLISECONDS);
        ScheduledFuture<?> previous=pumps.put(device,f);if(previous!=null)previous.cancel(false);
    }

    @Override protected void handleTextMessage(WebSocketSession session,TextMessage message)throws Exception{
        String device=(String)session.getAttributes().get("deviceId");
        JsonNode root=json.readTree(message.getPayload());String type=root.path("type").asText();
        switch(type){
            case "heartbeat" -> db.update("UPDATE devices SET status='online',last_seen_at=CURRENT_TIMESTAMP(6) WHERE id=?",device);
            case "gadgetDownloading" -> {String id=root.path("jobId").asText();db.update("UPDATE jobs SET status='downloading_gadget' WHERE id=? AND device_id=? AND status='dispatched'",id,device);db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,'downloading_gadget','Client downloading/verifying gadget')",id);}
            case "gadgetVerified" -> {String id=root.path("jobId").asText(),vid=root.path("versionId").asText();db.update("INSERT INTO device_gadget_cache(device_id,gadget_version_id,status,downloaded_at,verified_at,last_used_at) VALUES(?,?,'verified',CURRENT_TIMESTAMP(6),CURRENT_TIMESTAMP(6),CURRENT_TIMESTAMP(6)) ON DUPLICATE KEY UPDATE status='verified',verified_at=CURRENT_TIMESTAMP(6),last_used_at=CURRENT_TIMESTAMP(6)",device,vid);db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,'gadget_verified','Package hash, signature and manifest verified')",id);}
            case "jobStarted" -> {String id=root.path("jobId").asText();db.update("UPDATE jobs SET status='running',started_at=CURRENT_TIMESTAMP(6) WHERE id=? AND device_id=?",id,device);db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,'running','Client started verified gadget')",id);}
            case "jobCancelled" -> {String id=root.path("jobId").asText();db.update("UPDATE jobs SET status='cancelled',finished_at=CURRENT_TIMESTAMP(6) WHERE id=? AND device_id=? AND status IN ('dispatched','downloading_gadget','running')",id,device);db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,'cancelled','Client cancelled active gadget process')",id);}
            case "jobResult" -> handleResult(device,root);
            default -> { }
        }
    }

    private void handleResult(String device,JsonNode root)throws Exception{
        String id=root.path("jobId").asText();boolean ok=root.path("success").asBoolean();String stdout=root.hasNonNull("stdout")?root.get("stdout").asText():null;String stderr=root.hasNonNull("stderr")?root.get("stderr").asText():null;String result=root.has("result")&&!root.get("result").isNull()?root.get("result").toString():null;
        db.update("UPDATE jobs SET status=?,finished_at=CURRENT_TIMESTAMP(6) WHERE id=? AND device_id=?",ok?"success":"error",id,device);
        db.update("INSERT INTO job_results(id,job_id,exit_code,stdout_text,stderr_text,result_json) VALUES(?,?,?,?,?,CASE WHEN ? IS NULL THEN NULL ELSE CAST(? AS JSON) END) ON DUPLICATE KEY UPDATE exit_code=VALUES(exit_code),stdout_text=VALUES(stdout_text),stderr_text=VALUES(stderr_text),result_json=VALUES(result_json)",UUID.randomUUID().toString(),id,ok?0:1,stdout,stderr,result,result);
        db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,?,?)",id,ok?"success":"error",ok?"Gadget completed":"Gadget failed");
    }

    private void pump(WebSocketSession session,String device)throws Exception{
        if(!session.isOpen()||sessions.get(device)!=session)return;
        expire(device);dispatchCancel(session,device);dispatchNext(session,device);
    }

    private void expire(String device){List<String> ids=db.queryForList("SELECT CAST(id AS CHAR) FROM jobs WHERE device_id=? AND status='queued' AND created_at<DATE_SUB(CURRENT_TIMESTAMP(6),INTERVAL 5 MINUTE)",String.class,device);if(ids.isEmpty())return;for(String id:ids){db.update("UPDATE jobs SET status='expired',finished_at=CURRENT_TIMESTAMP(6) WHERE id=? AND status='queued'",id);db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,'expired','Job expired before dispatch')",id);}}

    private void dispatchCancel(WebSocketSession session,String device)throws Exception{
        var rows=db.queryForList("SELECT CAST(j.id AS CHAR) id FROM jobs j WHERE j.device_id=? AND j.status IN ('dispatched','downloading_gadget','running') AND EXISTS(SELECT 1 FROM job_events e WHERE e.job_id=j.id AND e.event_type='cancel_requested') AND NOT EXISTS(SELECT 1 FROM job_events e WHERE e.job_id=j.id AND e.event_type='cancel_dispatched') ORDER BY j.created_at LIMIT 1",device);if(rows.isEmpty())return;String id=(String)rows.get(0).get("id");send(session,Map.of("type","cancelJob","jobId",id));db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,'cancel_dispatched','Cancellation sent to Client')",id);
    }

    private void dispatchNext(WebSocketSession session,String device)throws Exception{
        Integer active=db.queryForObject("SELECT COUNT(*) FROM jobs WHERE device_id=? AND status IN ('dispatched','downloading_gadget','running')",Integer.class,device);if(active!=null&&active>0)return;
        var rows=db.queryForList("SELECT CAST(j.id AS CHAR) id,j.action,CAST(j.payload_json AS CHAR) payloadJson,CAST(gv.id AS CHAR) versionId,gv.version,gv.sha256,JSON_UNQUOTE(JSON_EXTRACT(gv.signature_metadata,'$.signatureBase64')) signatureBase64,g.code gadgetCode FROM jobs j JOIN gadget_versions gv ON gv.id=j.gadget_version_id JOIN gadgets g ON g.id=j.gadget_id WHERE j.device_id=? AND j.status='queued' AND gv.status='published' ORDER BY j.created_at LIMIT 1",device);if(rows.isEmpty())return;var r=rows.get(0);String id=(String)r.get("id");if(db.update("UPDATE jobs SET status='dispatched',dispatched_at=CURRENT_TIMESTAMP(6) WHERE id=? AND status='queued'",id)==0)return;db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,'dispatched','Job sent to Client')",id);
        Object params=null;String p=(String)r.get("payloadJson");if(p!=null&&!p.isBlank())params=json.readTree(p);Map<String,Object> job=new LinkedHashMap<>();job.put("id",id);job.put("action",r.get("action"));job.put("parameters",params);job.put("gadgetCode",r.get("gadgetCode"));job.put("versionId",r.get("versionId"));job.put("version",r.get("version"));job.put("sha256",r.get("sha256"));job.put("signatureBase64",r.get("signatureBase64"));job.put("packageUrl","/api/v1/agent/gadget-package/"+r.get("versionId")+"?deviceId="+java.net.URLEncoder.encode(device,java.nio.charset.StandardCharsets.UTF_8));send(session,Map.of("type","job","job",job));
    }

    private void recoverOrphans(String device){var rows=db.queryForList("SELECT CAST(j.id AS CHAR) id,EXISTS(SELECT 1 FROM job_events e WHERE e.job_id=j.id AND e.event_type='cancel_requested') cancelRequested FROM jobs j WHERE j.device_id=? AND j.status IN ('dispatched','downloading_gadget','running')",device);for(var r:rows){boolean cancel=((Number)r.get("cancelRequested")).intValue()==1;String id=(String)r.get("id");db.update("UPDATE jobs SET status=?,finished_at=CURRENT_TIMESTAMP(6) WHERE id=? AND status IN ('dispatched','downloading_gadget','running')",cancel?"cancelled":"error",id);db.update("INSERT INTO job_events(job_id,event_type,message) VALUES(?,?,?)",id,cancel?"cancelled":"connection_recovered",cancel?"Cancellation completed after Client reconnect":"Orphaned job closed after Client reconnect");}}

    private void send(WebSocketSession session,Object value)throws Exception{synchronized(session){if(session.isOpen())session.sendMessage(new TextMessage(json.writeValueAsString(value)));}}

    @Override public void afterConnectionClosed(WebSocketSession session,CloseStatus status){String d=(String)session.getAttributes().get("deviceId");if(d!=null&&sessions.remove(d,session)){ScheduledFuture<?> f=pumps.remove(d);if(f!=null)f.cancel(false);db.update("UPDATE devices SET status='offline' WHERE id=?",d);}}
    @Override public void handleTransportError(WebSocketSession session,Throwable exception)throws Exception{if(session.isOpen())session.close(CloseStatus.SERVER_ERROR);}
    @PreDestroy public void close(){scheduler.shutdownNow();}
}
