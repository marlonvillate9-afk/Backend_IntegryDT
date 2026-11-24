USE integry_dt;

INSERT INTO gadget_versions(
  id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,package_size,sha256,status,published_at
)
SELECT
  '81000000-0000-4000-8000-000000000001',
  g.id,
  '1.0.0',
  '1',
  'windows',
  'x64',
  'system-info/1.0.0',
  0,
  REPEAT('0',64),
  'published',
  CURRENT_TIMESTAMP(6)
FROM gadgets g
WHERE g.code='system-info'
  AND NOT EXISTS (
    SELECT 1 FROM gadget_versions gv
    WHERE gv.gadget_id=g.id AND gv.version='1.0.0' AND gv.platform='windows' AND gv.architecture='x64'
  );

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('003', 'phase 4 system-info published gadget version');
