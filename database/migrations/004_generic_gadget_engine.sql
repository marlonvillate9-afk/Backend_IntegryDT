USE integry_dt;

ALTER TABLE gadget_versions ADD COLUMN entrypoint VARCHAR(255) NULL AFTER storage_key;
ALTER TABLE gadget_versions ADD COLUMN manifest_json JSON NULL AFTER entrypoint;

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('004', 'generic gadget engine metadata');
