package com.integrydt.backend.controller;

import com.integrydt.backend.security.AuthenticatedUser;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
public class AdministrationController {
    private final JdbcTemplate db;
    public AdministrationController(JdbcTemplate db){this.db=db;}

    @GetMapping("/members")
    @PreAuthorize("hasAuthority('PERM_users.manage')")
    public Object members(Authentication auth){
        String company=((AuthenticatedUser)auth.getPrincipal()).companyId();
        return db.queryForList("""
            SELECT CAST(u.id AS CHAR) id,u.email,u.display_name displayName,u.status,
                   GROUP_CONCAT(DISTINCT r.code ORDER BY r.code) roles
            FROM company_memberships cm
            JOIN users u ON u.id=cm.user_id
            LEFT JOIN membership_roles mr ON mr.membership_id=cm.id
            LEFT JOIN roles r ON r.id=mr.role_id
            WHERE cm.company_id=? AND cm.status='active'
            GROUP BY u.id,u.email,u.display_name,u.status
            ORDER BY u.display_name
            """,company);
    }

    @GetMapping("/roles")
    @PreAuthorize("hasAuthority('PERM_roles.manage')")
    public Object roles(Authentication auth){
        String company=((AuthenticatedUser)auth.getPrincipal()).companyId();
        return db.queryForList("""
            SELECT CAST(r.id AS CHAR) id,r.code,r.name,r.description,
                   GROUP_CONCAT(DISTINCT p.code ORDER BY p.code) permissions
            FROM roles r
            LEFT JOIN role_permissions rp ON rp.role_id=r.id
            LEFT JOIN permissions p ON p.id=rp.permission_id
            WHERE r.company_id=? OR r.company_id IS NULL
            GROUP BY r.id,r.code,r.name,r.description
            ORDER BY r.name
            """,company);
    }
}
