package com.integrydt.backend.security;

import jakarta.servlet.*;import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;import java.util.*;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    private final JwtService jwt; public JwtAuthFilter(JwtService jwt){this.jwt=jwt;}
    @Override protected void doFilterInternal(HttpServletRequest req,HttpServletResponse res,FilterChain chain)throws ServletException,IOException{
        String h=req.getHeader("Authorization");
        if(h!=null&&h.startsWith("Bearer ")){try{var u=jwt.parse(h.substring(7));List<SimpleGrantedAuthority>a=new ArrayList<>();u.roles().forEach(r->a.add(new SimpleGrantedAuthority("ROLE_"+r)));u.permissions().forEach(p->a.add(new SimpleGrantedAuthority("PERM_"+p)));SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(u,null,a));}catch(Exception ignored){}}
        chain.doFilter(req,res);
    }
}
