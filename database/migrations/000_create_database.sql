CREATE DATABASE IF NOT EXISTS integry_dt
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE integry_dt;

CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(64) NOT NULL PRIMARY KEY,
  description VARCHAR(255) NOT NULL,
  applied_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB;

INSERT IGNORE INTO schema_migrations(version, description)
VALUES ('000', 'create database and migration registry');
