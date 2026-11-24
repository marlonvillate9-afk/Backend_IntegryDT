USE integry_dt;

INSERT INTO gadget_versions(id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,entrypoint,package_size,sha256,status)
SELECT '87100000-0000-4000-8000-000000000001',id,'1.1.0','1','windows','x64','input-automation/1.1.0','IntegryDT.Gadgets.InputAutomation.exe',0,REPEAT('0',64),'draft'
FROM gadgets WHERE code='input-automation'
ON DUPLICATE KEY UPDATE version=VALUES(version);

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('008','input automation hotkeys and cancellation support');
