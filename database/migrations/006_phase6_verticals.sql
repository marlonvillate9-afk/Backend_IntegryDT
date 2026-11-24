USE integry_dt;

CREATE TABLE IF NOT EXISTS repository_profiles (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  name VARCHAR(150) NOT NULL,
  local_path VARCHAR(1000) NOT NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY(id),
  KEY ix_repository_profiles_company(company_id),
  CONSTRAINT fk_repository_profiles_company FOREIGN KEY(company_id) REFERENCES companies(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sftp_profiles (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  name VARCHAR(150) NOT NULL,
  host VARCHAR(255) NOT NULL,
  port INT NOT NULL DEFAULT 22,
  username VARCHAR(255) NOT NULL,
  remote_path VARCHAR(1000) NOT NULL,
  identity_file_path VARCHAR(1000) NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY(id),
  KEY ix_sftp_profiles_company(company_id),
  CONSTRAINT fk_sftp_profiles_company FOREIGN KEY(company_id) REFERENCES companies(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS script_catalog (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  name VARCHAR(150) NOT NULL,
  runtime ENUM('powershell') NOT NULL DEFAULT 'powershell',
  script_body MEDIUMTEXT NOT NULL,
  sha256 CHAR(64) NOT NULL,
  timeout_seconds INT NOT NULL DEFAULT 30,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY(id),
  KEY ix_script_catalog_company(company_id),
  CONSTRAINT fk_script_catalog_company FOREIGN KEY(company_id) REFERENCES companies(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS screen_recordings (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  device_id CHAR(36) NOT NULL,
  job_id CHAR(36) NOT NULL,
  artifact_path VARCHAR(1500) NULL,
  duration_seconds INT NOT NULL,
  frame_count INT NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY(id),
  KEY ix_screen_recordings_company(company_id),
  CONSTRAINT fk_screen_recordings_company FOREIGN KEY(company_id) REFERENCES companies(id),
  CONSTRAINT fk_screen_recordings_device FOREIGN KEY(device_id) REFERENCES devices(id),
  CONSTRAINT fk_screen_recordings_job FOREIGN KEY(job_id) REFERENCES jobs(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS automation_sequences (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  name VARCHAR(150) NOT NULL,
  steps_json JSON NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY(id),
  KEY ix_automation_sequences_company(company_id),
  CONSTRAINT fk_automation_sequences_company FOREIGN KEY(company_id) REFERENCES companies(id)
) ENGINE=InnoDB;

INSERT INTO gadget_versions(id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,entrypoint,package_size,sha256,status)
SELECT '83000000-0000-4000-8000-000000000001',id,'1.0.0','1','windows','x64','repository-manager/1.0.0','IntegryDT.Gadgets.RepositoryManager.exe',0,REPEAT('0',64),'draft' FROM gadgets WHERE code='repository-manager'
ON DUPLICATE KEY UPDATE version=VALUES(version);
INSERT INTO gadget_versions(id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,entrypoint,package_size,sha256,status)
SELECT '84000000-0000-4000-8000-000000000001',id,'1.0.0','1','windows','x64','sftp-files/1.0.0','IntegryDT.Gadgets.SftpFiles.exe',0,REPEAT('0',64),'draft' FROM gadgets WHERE code='sftp-files'
ON DUPLICATE KEY UPDATE version=VALUES(version);
INSERT INTO gadget_versions(id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,entrypoint,package_size,sha256,status)
SELECT '85000000-0000-4000-8000-000000000001',id,'1.0.0','1','windows','x64','script-runner/1.0.0','IntegryDT.Gadgets.ScriptRunner.exe',0,REPEAT('0',64),'draft' FROM gadgets WHERE code='script-runner'
ON DUPLICATE KEY UPDATE version=VALUES(version);
INSERT INTO gadget_versions(id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,entrypoint,package_size,sha256,status)
SELECT '86000000-0000-4000-8000-000000000001',id,'1.0.0','1','windows','x64','screen-recorder/1.0.0','IntegryDT.Gadgets.ScreenRecorder.exe',0,REPEAT('0',64),'draft' FROM gadgets WHERE code='screen-recorder'
ON DUPLICATE KEY UPDATE version=VALUES(version);
INSERT INTO gadget_versions(id,gadget_id,version,sdk_protocol_version,platform,architecture,storage_key,entrypoint,package_size,sha256,status)
SELECT '87000000-0000-4000-8000-000000000001',id,'1.0.0','1','windows','x64','input-automation/1.0.0','IntegryDT.Gadgets.InputAutomation.exe',0,REPEAT('0',64),'draft' FROM gadgets WHERE code='input-automation'
ON DUPLICATE KEY UPDATE version=VALUES(version);

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('006','phase 6 repositories sftp scripts recording and automation');

