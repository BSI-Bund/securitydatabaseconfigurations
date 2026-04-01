-- ------------------------------------------------------------------
-- MySQL 8.4 - configuration validation (read-only)
-- ------------------------------------------------------------------

-- Version & Build
SELECT @@version                      AS version,
       @@version_comment              AS build;

-- Character set & collation
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';

-- Base paths & ports
SHOW VARIABLES LIKE 'basedir';
SHOW VARIABLES LIKE 'datadir';
SHOW VARIABLES LIKE 'pid_file';
SHOW VARIABLES LIKE 'port';
SHOW VARIABLES LIKE 'socket';

-- Network & connections
SHOW VARIABLES LIKE 'bind_address';
SHOW VARIABLES LIKE 'skip_name_resolve';
SHOW VARIABLES LIKE 'max_connections';

-- Security / hardening
SHOW VARIABLES LIKE 'local_infile';        -- erwartet: OFF
SHOW VARIABLES LIKE 'secure_file_priv';    -- empfohlen: Verzeichnis oder NULL (kein Import/Export)
SHOW VARIABLES LIKE 'symbolic-links';      -- erwartet: 0 (deaktiviert)

-- TLS / SSL status
SHOW VARIABLES LIKE 'have_ssl';            -- YES if SSL available
SHOW VARIABLES LIKE 'tls_version';         -- e.g. TLSv1.2,TLSv1.3
SHOW STATUS    LIKE 'Ssl_cipher';          -- active cipher when TLS is used

-- InnoDB Engine
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'innodb_redo_log_capacity';
SHOW VARIABLES LIKE 'innodb_file_per_table';
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';
-- Optional Linux: innodb_flush_method (z. B. O_DIRECT)
SHOW VARIABLES LIKE 'innodb_flush_method';

-- Logging
SHOW VARIABLES LIKE 'log_error';
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'slow_query_log_file';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'log_queries_not_using_indexes';
SHOW VARIABLES LIKE 'general_log';
SHOW VARIABLES LIKE 'general_log_file';

-- Binärlog / Replikation
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'log_bin_basename';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'sync_binlog';

-- Hinweis: Während der INIT-Phase können die folgenden Werte 0 sein.
-- Nach dem finalen Start erneut prüfen:
-- SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
-- SHOW VARIABLES LIKE 'expire_logs_days';

-- Optional: temp tables (tune per workload)
SHOW VARIABLES LIKE 'tmp_table_size';
SHOW VARIABLES LIKE 'max_heap_table_size';
