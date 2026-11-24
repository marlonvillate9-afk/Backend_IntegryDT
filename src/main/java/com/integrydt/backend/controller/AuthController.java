package com.integrydt.backend.controller;

import com.integrydt.backend.security.AuthenticatedUser;import com.integrydt.backend.service.*;import jakarta.servlet.http.HttpServletRequest;import org.springframework.http.*;import org.springframework.security.core.Authentication;import org.springframework.web.bind.annotation.*;import java.util.*;

@RestController @RequestMapping("/api/v1/auth")
public class AuthController { private final AuthService auth;private final AuditService audit;public AuthController(AuthService a,AuditService au){auth=a;audit=au;}
 public record LoginRequest(String email,String password,String companyId){} public record SwitchRequest(String companyId){}
 @PostMapping("/login") public ResponseEntity<?> login(@RequestBody LoginRequest r,HttpServletRequest req){var x=auth.login(r.email(),r.password(),r.companyId());if(x==null)return ResponseEntity.status(401).body(Map.of("error","invalid_credentials_or_membership"));var c=(Map<?,?>)x.get("company");var u=(Map<?,?>)x.get("user");audit.write((String)c.get("id"),(String)u.get("id"),"auth.login","user",(String)u.get("id"),"success","web-api",req.getRemoteAddr(),null);return ResponseEntity.ok(x);}
 @GetMapping("/me") public Object me(Authentication a){var u=(AuthenticatedUser)a.getPrincipal();return Map.of("id",u.id(),"email",u.email(),"displayName",u.displayName(),"companyId",u.companyId(),"companySlug",u.companySlug(),"roles",u.roles(),"permissions",u.permissions());}
 @GetMapping("/companies") public Object companies(Authentication a){return auth.companies(((AuthenticatedUser)a.getPrincipal()).id());}
 @PostMapping("/switch-company") public ResponseEntity<?> sw(@RequestBody SwitchRequest r,Authentication a){var x=auth.switchCompany(((AuthenticatedUser)a.getPrincipal()).id(),r.companyId());return x==null?ResponseEntity.status(403).build():ResponseEntity.ok(x);}
}
