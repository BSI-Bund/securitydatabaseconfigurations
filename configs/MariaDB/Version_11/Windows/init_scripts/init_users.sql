-- =============================================
-- MariaDB initialization script
-- File: init_users.sql
-- Purpose: initial setup of users and base database
-- =============================================

-- Connect to system database "mysql"
USE mysql;

-- Set root password (if not set yet)
-- ALTER USER 'root'@'localhost' IDENTIFIED BY 'Str0ngRootP@ss!';

-- Create application database
CREATE DATABASE IF NOT EXISTS appdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

-- Create admin user for the application
CREATE USER IF NOT EXISTS 'app_admin'@'%' IDENTIFIED BY 'S3cur3P@ss!';
GRANT ALL PRIVILEGES ON appdb.* TO 'app_admin'@'%';

-- Optional: read-only user (e.g., for reports)
CREATE USER IF NOT EXISTS 'app_reader'@'%' IDENTIFIED BY 'Read0nly!';
GRANT SELECT ON appdb.* TO 'app_reader'@'%';

-- Apply privileges
FLUSH PRIVILEGES;

-- Success message
SELECT 'MariaDB initialization completed.' AS status;
