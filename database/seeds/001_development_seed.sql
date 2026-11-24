USE integry_dt;

-- IDs fijos para que el seed de desarrollo sea repetible.
SET @company_id = '11111111-1111-4111-8111-111111111111';
SET @admin_user_id = '22222222-2222-4222-8222-222222222222';
SET @membership_id = '33333333-3333-4333-8333-333333333333';
SET @admin_role_id = '44444444-4444-4444-8444-444444444444';
SET @leader_role_id = '55555555-5555-4555-8555-555555555555';
SET @developer_role_id = '66666666-6666-4666-8666-666666666666';

INSERT INTO companies(id, name, slug, status)
VALUES (@company_id, 'Integry DT Development', 'integry-dt-development', 'active')
ON DUPLICATE KEY UPDATE name = VALUES(name), status = VALUES(status);

-- El password_hash del seed NO representa una credencial válida. Fase 2 deberá
-- generar un hash real con el algoritmo elegido por el Backend.
INSERT INTO users(id, email, password_hash, display_name, status)
VALUES (@admin_user_id, 'admin@integrydt.local', 'DEV_PASSWORD_NOT_INITIALIZED', 'Administrador Desarrollo', 'active')
ON DUPLICATE KEY UPDATE display_name = VALUES(display_name), status = VALUES(status);

INSERT INTO company_memberships(id, company_id, user_id, status)
VALUES (@membership_id, @company_id, @admin_user_id, 'active')
ON DUPLICATE KEY UPDATE status = VALUES(status);

INSERT INTO roles(id, company_id, code, name, description, is_system) VALUES
(@admin_role_id, @company_id, 'admin', 'Administrador', 'Administración completa del tenant de desarrollo', TRUE),
(@leader_role_id, @company_id, 'leader', 'Líder', 'Coordina equipo y puede emitir acciones habilitadas', TRUE),
(@developer_role_id, @company_id, 'developer', 'Desarrollador', 'Opera herramientas autorizadas', TRUE)
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

INSERT INTO permissions(id, code, name, description) VALUES
('70000000-0000-4000-8000-000000000001','companies.manage','Administrar empresa','Administrar configuración del tenant'),
('70000000-0000-4000-8000-000000000002','users.manage','Administrar usuarios','Gestionar usuarios y membresías'),
('70000000-0000-4000-8000-000000000003','roles.manage','Administrar roles','Gestionar roles y permisos'),
('70000000-0000-4000-8000-000000000004','devices.read','Consultar dispositivos','Consultar equipos registrados'),
('70000000-0000-4000-8000-000000000005','devices.manage','Administrar dispositivos','Enrolar/revocar equipos'),
('70000000-0000-4000-8000-000000000006','tools.read','Consultar herramientas','Consultar catálogo habilitado'),
('70000000-0000-4000-8000-000000000007','tools.execute','Ejecutar herramientas','Crear Jobs de herramientas'),
('70000000-0000-4000-8000-000000000008','jobs.read','Consultar Jobs','Consultar estado y resultado de Jobs'),
('70000000-0000-4000-8000-000000000009','notifications.send','Enviar notificaciones','Enviar notificaciones autorizadas a equipos'),
('70000000-0000-4000-8000-000000000010','audit.read','Consultar auditoría','Consultar eventos de auditoría')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

INSERT IGNORE INTO membership_roles(membership_id, role_id)
VALUES (@membership_id, @admin_role_id);

INSERT IGNORE INTO role_permissions(role_id, permission_id)
SELECT @admin_role_id, id FROM permissions;

INSERT IGNORE INTO role_permissions(role_id, permission_id)
SELECT @leader_role_id, id FROM permissions
WHERE code IN ('devices.read','tools.read','tools.execute','jobs.read','notifications.send','audit.read');

INSERT IGNORE INTO role_permissions(role_id, permission_id)
SELECT @developer_role_id, id FROM permissions
WHERE code IN ('devices.read','tools.read','tools.execute','jobs.read');

INSERT INTO gadgets(id, code, name, description, risk_level) VALUES
('80000000-0000-4000-8000-000000000001','system-info','System Info','Gadget técnico de diagnóstico para validar el pipeline', 'low'),
('80000000-0000-4000-8000-000000000002','desktop-notifications','Desktop Notifications','Muestra notificaciones autorizadas en el PC', 'low'),
('80000000-0000-4000-8000-000000000003','repository-manager','Repository Manager','Gestión controlada de repositorios y librerías', 'medium'),
('80000000-0000-4000-8000-000000000004','sftp-files','SFTP Files','Manejo remoto de archivos por SFTP', 'medium'),
('80000000-0000-4000-8000-000000000005','script-runner','Script Runner','Ejecución controlada de scripts', 'critical'),
('80000000-0000-4000-8000-000000000006','screen-recorder','Screen Recorder','Grabación de pantalla', 'high'),
('80000000-0000-4000-8000-000000000007','input-automation','Input Automation','Automatización de teclado y mouse', 'critical')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description), risk_level = VALUES(risk_level);

INSERT INTO tools(id, gadget_id, code, name, description, risk_level) VALUES
('90000000-0000-4000-8000-000000000001','80000000-0000-4000-8000-000000000001','system-info','Información del sistema','Diagnóstico técnico del Client', 'low'),
('90000000-0000-4000-8000-000000000002','80000000-0000-4000-8000-000000000002','desktop-notifications','Notificaciones','Enviar notificaciones al equipo', 'low'),
('90000000-0000-4000-8000-000000000003','80000000-0000-4000-8000-000000000003','repository-manager','Repositorios','Gestionar repositorios/librerías', 'medium'),
('90000000-0000-4000-8000-000000000004','80000000-0000-4000-8000-000000000004','sftp-files','SFTP','Gestionar archivos por SFTP', 'medium'),
('90000000-0000-4000-8000-000000000005','80000000-0000-4000-8000-000000000005','script-runner','Scripts','Ejecutar scripts controlados', 'critical'),
('90000000-0000-4000-8000-000000000006','80000000-0000-4000-8000-000000000006','screen-recorder','Grabación de pantalla','Grabar pantalla del equipo', 'high'),
('90000000-0000-4000-8000-000000000007','80000000-0000-4000-8000-000000000007','input-automation','Automatización de entrada','Automatizar teclado y mouse', 'critical')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description), risk_level = VALUES(risk_level);

INSERT INTO company_tools(id, company_id, tool_id, enabled)
SELECT UUID(), @company_id, t.id, TRUE
FROM tools t
WHERE NOT EXISTS (
  SELECT 1 FROM company_tools ct WHERE ct.company_id = @company_id AND ct.tool_id = t.id
);

INSERT INTO company_gadget_policies(id, company_id, gadget_id, enabled, version_policy)
SELECT UUID(), @company_id, g.id, TRUE, 'development'
FROM gadgets g
WHERE NOT EXISTS (
  SELECT 1 FROM company_gadget_policies cgp WHERE cgp.company_id = @company_id AND cgp.gadget_id = g.id
);
