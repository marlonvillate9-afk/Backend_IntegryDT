USE integry_dt;

CREATE TABLE IF NOT EXISTS job_artifacts (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  job_id CHAR(36) NOT NULL,
  device_id CHAR(36) NOT NULL,
  filename VARCHAR(500) NOT NULL,
  storage_path VARCHAR(1500) NOT NULL,
  content_type VARCHAR(150) NOT NULL DEFAULT 'application/octet-stream',
  size_bytes BIGINT UNSIGNED NOT NULL,
  sha256 CHAR(64) NOT NULL,
  created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  expires_at TIMESTAMP(6) NULL,
  PRIMARY KEY(id),
  KEY ix_job_artifacts_company_created(company_id,created_at),
  KEY ix_job_artifacts_job(job_id),
  KEY ix_job_artifacts_expires(expires_at),
  CONSTRAINT fk_job_artifacts_company FOREIGN KEY(company_id) REFERENCES companies(id),
  CONSTRAINT fk_job_artifacts_job FOREIGN KEY(job_id) REFERENCES jobs(id),
  CONSTRAINT fk_job_artifacts_device FOREIGN KEY(device_id) REFERENCES devices(id)
) ENGINE=InnoDB;

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('007','secure job artifact transfer and retention');
