USE integry_dt;

ALTER TABLE notifications ADD COLUMN job_id CHAR(36) NULL AFTER target_device_id;
CREATE INDEX ix_notifications_job ON notifications(job_id);
ALTER TABLE notifications ADD CONSTRAINT fk_notifications_job FOREIGN KEY (job_id) REFERENCES jobs(id);

INSERT INTO gadget_versions(
  id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,entrypoint,package_size,sha256,status,published_at
)
SELECT
  '82000000-0000-4000-8000-000000000001',g.id,'1.0.0','1','windows','x64','desktop-notifications/1.0.0',
  'IntegryDT.Gadgets.DesktopNotifications.exe',0,REPEAT('0',64),'draft',NULL
FROM gadgets g
WHERE g.code='desktop-notifications'
  AND NOT EXISTS (
    SELECT 1 FROM gadget_versions gv
    WHERE gv.gadget_id=g.id AND gv.version='1.0.0' AND gv.platform='windows' AND gv.architecture='x64'
  );

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('005', 'desktop notifications vertical');
