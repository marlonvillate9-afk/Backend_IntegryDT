package com.integrydt.backend.service;

import com.integrydt.backend.security.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class AuthService {
    private final JdbcTemplate db; private final JwtService jwt;
    public AuthService(JdbcTemplate db,JwtService jwt){this.db=db;this.jwt=jwt;}

    public Map<String,Object> login(String email,String password,String companyId){
        var users=db.query("SELECT CAST(id AS CHAR) id,email,password_hash,display_name,status FROM users WHERE email=? LIMIT 1",(rs,n)->row(
            "id",rs.getString("id"),"email",rs.getString("email"),"passwordHash",rs.getString("password_hash"),"displayName",rs.getString("display_name"),"status",rs.getString("status")),email);
        if(users.isEmpty())return null;
        var u=users.get(0);
        if(!"active".equals(u.get("status"))||!AspNetIdentityPassword.verify((String)u.get("passwordHash"),password))return null;
        var ms=db.query("SELECT CAST(cm.id AS CHAR) membershipId,CAST(c.id AS CHAR) companyId,c.name companyName,c.slug companySlug FROM company_memberships cm JOIN companies c ON c.id=cm.company_id WHERE cm.user_id=? AND cm.status='active' AND c.status='active' ORDER BY c.name",(rs,n)->row(
            "membershipId",rs.getString("membershipId"),"companyId",rs.getString("companyId"),"companyName",rs.getString("companyName"),"companySlug",rs.getString("companySlug")),u.get("id"));
        if(ms.isEmpty())return null;
        Map<String,Object> m=companyId==null?ms.get(0):ms.stream().filter(x->companyId.equals(x.get("companyId"))).findFirst().orElse(null);
        return m==null?null:response(u,m);
    }

    public Map<String,Object> switchCompany(String userId,String companyId){
        var us=db.query("SELECT CAST(id AS CHAR) id,email,display_name,status FROM users WHERE id=? AND status='active'",(rs,n)->row("id",rs.getString("id"),"email",rs.getString("email"),"displayName",rs.getString("display_name"),"status",rs.getString("status")),userId);
        if(us.isEmpty())return null;
        var ms=db.query("SELECT CAST(cm.id AS CHAR) membershipId,CAST(c.id AS CHAR) companyId,c.name companyName,c.slug companySlug FROM company_memberships cm JOIN companies c ON c.id=cm.company_id WHERE cm.user_id=? AND cm.company_id=? AND cm.status='active' AND c.status='active'",(rs,n)->row("membershipId",rs.getString("membershipId"),"companyId",rs.getString("companyId"),"companyName",rs.getString("companyName"),"companySlug",rs.getString("companySlug")),userId,companyId);
        return ms.isEmpty()?null:response(us.get(0),ms.get(0));
    }

    public List<Map<String,Object>> companies(String userId){
        return db.query("SELECT CAST(c.id AS CHAR) id,c.name,c.slug FROM company_memberships cm JOIN companies c ON c.id=cm.company_id WHERE cm.user_id=? AND cm.status='active' AND c.status='active' ORDER BY c.name",(rs,n)->row("id",rs.getString("id"),"name",rs.getString("name"),"slug",rs.getString("slug")),userId);
    }

    private Map<String,Object> response(Map<String,Object> u,Map<String,Object> m){
        String membership=(String)m.get("membershipId");
        Set<String> roles=new LinkedHashSet<>(db.queryForList("SELECT r.code FROM membership_roles mr JOIN roles r ON r.id=mr.role_id WHERE mr.membership_id=?",String.class,membership));
        Set<String> permissions=new LinkedHashSet<>(db.queryForList("SELECT DISTINCT p.code FROM membership_roles mr JOIN role_permissions rp ON rp.role_id=mr.role_id JOIN permissions p ON p.id=rp.permission_id WHERE mr.membership_id=?",String.class,membership));
        var principal=new AuthenticatedUser((String)u.get("id"),(String)u.get("email"),(String)u.get("displayName"),(String)m.get("companyId"),(String)m.get("companySlug"),roles,permissions);
        var t=jwt.issue(principal);
        var out=new LinkedHashMap<String,Object>();
        out.put("accessToken",t.accessToken()); out.put("expiresAt",t.expiresAt());
        out.put("user",row("id",principal.id(),"email",principal.email(),"displayName",principal.displayName()));
        out.put("company",row("id",principal.companyId(),"name",m.get("companyName"),"slug",principal.companySlug()));
        out.put("roles",roles); out.put("permissions",permissions); return out;
    }

    private static Map<String,Object> row(Object... kv){var m=new LinkedHashMap<String,Object>();for(int i=0;i<kv.length;i+=2)m.put((String)kv[i],kv[i+1]);return m;}
}
