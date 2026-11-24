package com.integrydt.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AuditService {
    private final JdbcTemplate db;
    private final ObjectMapper json;

    public AuditService(JdbcTemplate db, ObjectMapper json) {
        this.db = db;
        this.json = json;
    }

    public void write(String companyId, String userId, String action, String resourceType,
                      String resourceId, String result, String origin, String ipAddress, Object metadata) {
        try {
            String metadataJson = metadata == null ? null : json.writeValueAsString(metadata);
            db.update("""
                INSERT INTO audit_logs(company_id,user_id,action,resource_type,resource_id,result,origin,ip_address,metadata_json)
                VALUES(?,?,?,?,?,?,?,?,CASE WHEN ? IS NULL THEN NULL ELSE CAST(? AS JSON) END)
                """,
                companyId, userId, action, resourceType, resourceId, result, origin, ipAddress,
                metadataJson, metadataJson);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
