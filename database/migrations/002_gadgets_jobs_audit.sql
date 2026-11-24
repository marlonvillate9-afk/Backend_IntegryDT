USE integry_dt;

CREATE TABLE IF NOT EXISTS gadgets (
  id CHAR(36) NOT NULL,
  code VARCHAR(100) NOT NULL,
  name VARCHAR(150) NOT NULL,
  description VARCHAR(1000) NULL,
  publisher VARCHAR(150) NOT NULL DEFAULT 'Integry DT',
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  risk_level ENUM('low','medium','high','critical') NOT NULL DEFAULT 'low',
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_gadgets_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS gadget_versions (
  id CHAR(36) NOT NULL,
  gadget_id CHAR(36) NOT NULL,
  version VARCHAR(50) NOT NULL,
  sdk_protocol_version VARCHAR(30) NOT NULL,
  platform VARCHAR(50) NOT NULL,
  architecture VARCHAR(40) NOT NULL,
  storage_key VARCHAR(500) NOT NULL,
  package_size BIGINT UNSIGNED NOT NULL,
  sha256 CHAR(64) NOT NULL,
  signature_metadata JSON NULL,
  min_client_version VARCHAR(50) NULL,
  max_client_version VARCHAR(50) NULL,
  status ENUM('draft','published','deprecated','revoked') NOT NULL DEFAULT 'draft',
  published_at TIMESTAMP(6) NULL,
  revoked_at TIMESTAMP(6) NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_gadget_version_target (gadget_id, version, platform, architecture),
  KEY ix_gadget_versions_status (gadget_id, status),
  CONSTRAINT fk_gadget_versions_gadget FOREIGN KEY (gadget_id) REFERENCES gadgets(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS gadget_capabilities (
  gadget_id CHAR(36) NOT NULL,
  capability_code VARCHAR(120) NOT NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (gadget_id, capability_code),
  CONSTRAINT fk_gadget_capabilities_gadget FOREIGN KEY (gadget_id) REFERENCES gadgets(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tools (
  id CHAR(36) NOT NULL,
  gadget_id CHAR(36) NULL,
  code VARCHAR(100) NOT NULL,
  name VARCHAR(150) NOT NULL,
  description VARCHAR(1000) NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  risk_level ENUM('low','medium','high','critical') NOT NULL DEFAULT 'low',
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_tools_code (code),
  KEY ix_tools_gadget (gadget_id),
  CONSTRAINT fk_tools_gadget FOREIGN KEY (gadget_id) REFERENCES gadgets(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS company_tools (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  tool_id CHAR(36) NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  configuration_json JSON NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_company_tools (company_id, tool_id),
  CONSTRAINT fk_company_tools_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_company_tools_tool FOREIGN KEY (tool_id) REFERENCES tools(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS company_gadget_policies (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  gadget_id CHAR(36) NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  version_policy VARCHAR(100) NULL,
  configuration_json JSON NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_company_gadget_policy (company_id, gadget_id),
  CONSTRAINT fk_company_gadget_policy_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_company_gadget_policy_gadget FOREIGN KEY (gadget_id) REFERENCES gadgets(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS jobs (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  requested_by_user_id CHAR(36) NOT NULL,
  device_id CHAR(36) NOT NULL,
  tool_id CHAR(36) NOT NULL,
  gadget_id CHAR(36) NOT NULL,
  gadget_version_id CHAR(36) NOT NULL,
  action VARCHAR(120) NOT NULL,
  payload_json JSON NULL,
  status ENUM('queued','dispatched','downloading_gadget','running','success','error','cancelled','expired') NOT NULL DEFAULT 'queued',
  priority SMALLINT NOT NULL DEFAULT 0,
  idempotency_key VARCHAR(191) NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  dispatched_at TIMESTAMP(6) NULL,
  started_at TIMESTAMP(6) NULL,
  finished_at TIMESTAMP(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_jobs_company_idempotency (company_id, idempotency_key),
  KEY ix_jobs_company_status_created (company_id, status, created_at),
  KEY ix_jobs_device_status (device_id, status),
  CONSTRAINT fk_jobs_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_jobs_user FOREIGN KEY (requested_by_user_id) REFERENCES users(id),
  CONSTRAINT fk_jobs_device FOREIGN KEY (device_id) REFERENCES devices(id),
  CONSTRAINT fk_jobs_tool FOREIGN KEY (tool_id) REFERENCES tools(id),
  CONSTRAINT fk_jobs_gadget FOREIGN KEY (gadget_id) REFERENCES gadgets(id),
  CONSTRAINT fk_jobs_gadget_version FOREIGN KEY (gadget_version_id) REFERENCES gadget_versions(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS job_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  job_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  message VARCHAR(1000) NULL,
  metadata_json JSON NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_job_events_job_created (job_id, created_at),
  CONSTRAINT fk_job_events_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS job_results (
  id CHAR(36) NOT NULL,
  job_id CHAR(36) NOT NULL,
  exit_code INT NULL,
  stdout_text MEDIUMTEXT NULL,
  stderr_text MEDIUMTEXT NULL,
  result_json JSON NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_job_results_job (job_id),
  CONSTRAINT fk_job_results_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS device_gadget_cache (
  device_id CHAR(36) NOT NULL,
  gadget_version_id CHAR(36) NOT NULL,
  status ENUM('downloaded','verified','invalid','revoked','removed') NOT NULL DEFAULT 'downloaded',
  downloaded_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  verified_at TIMESTAMP(6) NULL,
  last_used_at TIMESTAMP(6) NULL,
  PRIMARY KEY (device_id, gadget_version_id),
  CONSTRAINT fk_device_gadget_cache_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
  CONSTRAINT fk_device_gadget_cache_version FOREIGN KEY (gadget_version_id) REFERENCES gadget_versions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  user_id CHAR(36) NULL,
  target_device_id CHAR(36) NULL,
  type VARCHAR(80) NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  priority ENUM('low','normal','high','urgent') NOT NULL DEFAULT 'normal',
  expires_at TIMESTAMP(6) NULL,
  read_at TIMESTAMP(6) NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_notifications_company_created (company_id, created_at),
  CONSTRAINT fk_notifications_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_notifications_device FOREIGN KEY (target_device_id) REFERENCES devices(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  company_id CHAR(36) NOT NULL,
  user_id CHAR(36) NULL,
  device_id CHAR(36) NULL,
  tool_id CHAR(36) NULL,
  gadget_id CHAR(36) NULL,
  gadget_version_id CHAR(36) NULL,
  job_id CHAR(36) NULL,
  action VARCHAR(150) NOT NULL,
  resource_type VARCHAR(100) NULL,
  resource_id VARCHAR(191) NULL,
  result VARCHAR(50) NULL,
  origin VARCHAR(80) NULL,
  ip_address VARCHAR(45) NULL,
  metadata_json JSON NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_audit_company_created (company_id, created_at),
  KEY ix_audit_job (job_id),
  CONSTRAINT fk_audit_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_audit_device FOREIGN KEY (device_id) REFERENCES devices(id),
  CONSTRAINT fk_audit_tool FOREIGN KEY (tool_id) REFERENCES tools(id),
  CONSTRAINT fk_audit_gadget FOREIGN KEY (gadget_id) REFERENCES gadgets(id),
  CONSTRAINT fk_audit_gadget_version FOREIGN KEY (gadget_version_id) REFERENCES gadget_versions(id),
  CONSTRAINT fk_audit_job FOREIGN KEY (job_id) REFERENCES jobs(id)
) ENGINE=InnoDB;

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('002', 'gadgets tools jobs notifications and audit');
