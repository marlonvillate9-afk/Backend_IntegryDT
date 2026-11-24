package com.integrydt.backend.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

@Service
public class DeviceTokenService {
    private final JdbcTemplate db; private final SecureRandom random=new SecureRandom();
    public DeviceTokenService(JdbcTemplate db){this.db=db;}
    public String createToken(){byte[] b=new byte[32];random.nextBytes(b);return Base64.getEncoder().encodeToString(b);}
    public String hash(String token){try{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));}catch(Exception e){throw new IllegalStateException(e);}}
    public boolean validate(String deviceId,String token){Integer n=db.queryForObject("SELECT COUNT(*) FROM device_credentials WHERE device_id=? AND credential_hash=? AND revoked_at IS NULL AND (expires_at IS NULL OR expires_at>CURRENT_TIMESTAMP(6))",Integer.class,deviceId,hash(token));return n!=null&&n>0;}
}
