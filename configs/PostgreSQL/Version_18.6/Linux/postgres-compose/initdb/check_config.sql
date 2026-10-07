-- ------------------------------------------------------------------
-- PostgreSQL 18.6 - configuration validation (read-only)
-- ------------------------------------------------------------------

-- Version & build
SELECT version();

-- Active config file locations
SHOW config_file;
SHOW hba_file;
SHOW data_directory;

-- Network & authentication
SHOW listen_addresses;
SHOW port;
SHOW max_connections;
SHOW password_encryption;

-- Least-privilege role check
SELECT rolname, rolsuper, rolcreatedb, rolcreaterole, rolreplication
FROM pg_roles
WHERE rolname IN ('postgres', 'app_admin', 'app_reader')
ORDER BY rolname;

SELECT datname,
       has_database_privilege('app_admin', datname, 'CONNECT') AS app_admin_connect,
       has_database_privilege('app_reader', datname, 'CONNECT') AS app_reader_connect
FROM pg_database
WHERE datname IN (current_database(), 'postgres', 'template1')
ORDER BY datname;

-- TLS / SSL status
SHOW ssl;
SHOW ssl_min_protocol_version;
SELECT ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();

-- Memory & durability
SHOW shared_buffers;
SHOW effective_cache_size;
SHOW maintenance_work_mem;
SHOW work_mem;
SHOW fsync;
SHOW synchronous_commit;
SHOW full_page_writes;
SHOW wal_level;
SHOW checkpoint_completion_target;

-- Logging
SHOW log_destination;
SHOW logging_collector;
SHOW log_connections;
SHOW log_disconnections;
SHOW log_line_prefix;
SHOW log_checkpoints;
SHOW log_lock_waits;
SHOW log_autovacuum_min_duration;
SHOW log_min_error_statement;
SHOW log_min_duration_statement;
SHOW log_statement;

-- Runtime safety limits
SHOW idle_in_transaction_session_timeout;
SHOW statement_timeout;
SHOW lock_timeout;

-- Host-based authentication file parsing
SELECT line_number, type, database, user_name, address, auth_method, error
FROM pg_hba_file_rules
ORDER BY line_number;
