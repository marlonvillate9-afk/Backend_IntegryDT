package com.integrydt.backend.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;

@Service
public class JwtService {
    private final SecretKey key; private final String issuer; private final String audience; private final long expirationMinutes;
    public JwtService(@Value("${integry.jwt.signing-key}") String signingKey,@Value("${integry.jwt.issuer}") String issuer,@Value("${integry.jwt.audience}") String audience,@Value("${integry.jwt.expiration-minutes}") long expirationMinutes){
        this.key=Keys.hmacShaKeyFor(signingKey.getBytes(StandardCharsets.UTF_8)); this.issuer=issuer; this.audience=audience; this.expirationMinutes=expirationMinutes;
    }
    public TokenResult issue(AuthenticatedUser u){
        Instant now=Instant.now(), exp=now.plusSeconds(expirationMinutes*60);
        Map<String,Object> claims=new HashMap<>(); claims.put("email",u.email()); claims.put("display_name",u.displayName()); claims.put("company_id",u.companyId()); claims.put("company_slug",u.companySlug()); claims.put("roles",u.roles()); claims.put("permissions",u.permissions());
        String token=Jwts.builder().claims(claims).subject(u.id()).issuer(issuer).audience().add(audience).and().issuedAt(Date.from(now)).expiration(Date.from(exp)).signWith(key).compact();
        return new TokenResult(token,exp);
    }
    public AuthenticatedUser parse(String token){
        Claims c=Jwts.parser().verifyWith(key).requireIssuer(issuer).requireAudience(audience).build().parseSignedClaims(token).getPayload();
        return new AuthenticatedUser(c.getSubject(),c.get("email",String.class),c.get("display_name",String.class),c.get("company_id",String.class),c.get("company_slug",String.class),toSet(c.get("roles")),toSet(c.get("permissions")));
    }
    private static Set<String> toSet(Object o){if(!(o instanceof Collection<?> c))return Set.of();Set<String>s=new LinkedHashSet<>();for(Object x:c)s.add(String.valueOf(x));return s;}
    public record TokenResult(String accessToken,Instant expiresAt){}
}
