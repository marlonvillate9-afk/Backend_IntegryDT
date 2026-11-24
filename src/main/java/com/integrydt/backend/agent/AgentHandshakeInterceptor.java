package com.integrydt.backend.agent;

import com.integrydt.backend.service.DeviceTokenService;import org.springframework.http.server.*;import org.springframework.stereotype.Component;import org.springframework.util.MultiValueMap;import org.springframework.web.socket.*;import org.springframework.web.socket.server.HandshakeInterceptor;import org.springframework.web.util.UriComponentsBuilder;import java.util.*;

@Component
public class AgentHandshakeInterceptor implements HandshakeInterceptor {
 private final DeviceTokenService tokens;public AgentHandshakeInterceptor(DeviceTokenService t){tokens=t;}
 @Override public boolean beforeHandshake(ServerHttpRequest request,ServerHttpResponse response,WebSocketHandler wsHandler,Map<String,Object> attrs){MultiValueMap<String,String> q=UriComponentsBuilder.fromUri(request.getURI()).build().getQueryParams();String device=q.getFirst("deviceId"),auth=request.getHeaders().getFirst("Authorization");if(device==null||auth==null||!auth.regionMatches(true,0,"Bearer ",0,7)||!tokens.validate(device,auth.substring(7)))return false;attrs.put("deviceId",device);return true;}
 @Override public void afterHandshake(ServerHttpRequest request,ServerHttpResponse response,WebSocketHandler wsHandler,Exception ex){}
}
