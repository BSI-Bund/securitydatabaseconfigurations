# MySQL – Windows

[Deutsch](README-de.md) · [Database overview](../../README.md) · [BSI alignment](../../../README.md#bsi-alignment)

- [Installation and active configuration](#installation-and-active-configuration)
- [Login and users](#login-and-users)
- [Configure TLS](#configure-tls)
- [Verify the configuration](#verify-the-configuration)
- [Parameter reference](#parameter-reference)
  - [Network & access](#network--access)
  - [TLS/SSL](#tlsssl)
  - [InnoDB – performance & durability](#innodb--performance--durability)
  - [Character sets](#character-sets)
  - [Logging & diagnostics](#logging--diagnostics)
  - [binary log](#binary-log)
  - [mysqldump](#mysqldump)
- [Operations](#operations)

## Installation and active configuration

Use the [MySQL 8.4 MSI with MySQL Configurator](https://dev.mysql.com/doc/refman/8.4/en/windows-installation.html). The following paths are examples from the supplied [`my.ini`](my.ini); check the actual installation and service paths.

| Purpose | Example path |
|---------|--------------|
| Binaries | `C:\Program Files\MySQL\MySQL Server 8.4\bin` |
| Active configuration, to verify in service settings | `C:\Program Files\MySQL\MySQL Server 8.4\my.ini` |
| Initialized data directory | `C:\ProgramData\MySQL\MySQL Server 8.4\Data` |
| Template log directory | `C:\Program Files\MySQL\MySQL Server 8.4\logs` |

The data directory must already have been initialized during installation. Creating an empty directory does not initialize the DBMS. Do not overwrite an existing data directory through reinitialization.

1. Determine the actual Windows service name; the examples below use `MySQL`.
2. Use `sc.exe qc MySQL` to check which configuration the service loads. Keeping `my.ini` in the repository does not activate it.
3. Adapt paths and memory settings in the active configuration. Create the log and any import/export directories; grant the service account the required permissions.
4. Restart the service and inspect the configured error log.

```powershell
sc.exe qc MySQL
net stop MySQL
net start MySQL
sc.exe query MySQL
```

Service changes require an administrator PowerShell. Do not run a second manually started server against the data directory of a running service.

## Login and users

Run client commands in a regular PowerShell; the `&` call operator executes the quoted program path.

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" --host=127.0.0.1 --user=root --password
```

The password is requested interactively. Use administration accounts for setup and maintenance; give applications separate, restricted accounts.

This Windows folder contains no initialization script. Create the database, application users, and privileges in an administrative SQL session according to application needs. Linux Compose environment variables do not create accounts here.

## Configure TLS

Server TLS lines in `my.ini` are commented out. The template therefore does not yet enforce a TLS connection configured by you. Follow the [shared TLS guide](../../../../docs/TLS.md) to create the CA, server certificate, and server key. Store them using the names specified in `ssl-ca`, `ssl-cert`, and `ssl-key`, and enable those server lines in `[mysqld]`. Client certificate options belong in an appropriate client section.

Grant the service account read access to the private server key. Then configure the transport requirement (`require_secure_transport=ON` or appropriate account rules) and restart the service. Enable CA and hostname verification on clients. The exact check depends on the MariaDB or MySQL client; `SHOW SESSION STATUS LIKE 'Ssl_cipher';` shows encryption for the current connection.

## Verify the configuration

The following reference contains recommendations. Check effective values with `SHOW VARIABLES`, especially file paths, network binding, TLS, and memory settings. A successful service start alone does not confirm these values.

## Parameter reference

### Network & access

| Option                  | Meaning                       | Recommendation |
|-------------------------|--------------------------------|----------------|
| `bind_address`          | Interface binding             | `127.0.0.1` (or VPN IP) |
| `skip_networking`       | Disable TCP/IP                | `0`; only `1` for named-pipe only |
| `skip_name_resolve`     | Avoid DNS lookups             | `1`; use IPs in `CREATE USER` |
| `max_connections`       | Concurrent connections        | 100–500 depending on workload |
| `local_infile`          | Client file upload via SQL    | `0` (lock down hard) |
| `secure_file_priv`      | Whitelist folder for INFILE   | Set dedicated folder or `NULL` |
| `lower_case_table_names`| Case semantics (Windows)      | `1` (required) |

### TLS/SSL

| Option                      | Meaning                     | Recommendation |
|-----------------------------|-----------------------------|----------------|
| `ssl-ca` / `ssl-cert` / `ssl-key` | CA/server certificates | Set paths; restrict permissions |
| `require_secure_transport`  | Only allow secure transport | `ON` after TLS setup |

### InnoDB – performance & durability

| Option                          | Effect                          | Recommendation |
|---------------------------------|---------------------------------|----------------|
| `innodb_buffer_pool_size`       | Main cache                      | Tune for available RAM and workload |
| `innodb_redo_log_capacity`      | Total redo log size (≥8.0)      | 1–4 GB depending on write load |
| `innodb_file_per_table`         | Separate tablespaces            | `1` |
| `innodb_flush_log_at_trx_commit`| Durability vs. throughput       | `1` (ACID), `2` if you need throughput |

### Character sets

| Option                 | Recommendation        |
|------------------------|-----------------------|
| `character_set_server` | `utf8mb4`             |
| `collation_server`     | `utf8mb4_0900_ai_ci`  |

### Logging & diagnostics

| Option                       | Purpose                       | Recommendation |
|------------------------------|-------------------------------|----------------|
| `log_error`                  | Error log                     | Always set |
| `slow_query_log`             | Slow queries                  | Enable; `long_query_time=1–2s` |
| `slow_query_log_file`        | Slow query log path           | e.g. `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Slow threshold                | 1–2 s |
| `log_queries_not_using_indexes` | Detect index misses        | Enable during tuning |
| `general_log`                | Log all queries               | Prod: `0` |
| `general_log_file`           | Path for general query log    | e.g. `C:/Program Files/MySQL/MySQL Server 8.4/logs/mysql-general.log` |

### binary log

| Option                      | Recommendation / note         |
|-----------------------------|-------------------------------|
| `log-bin`, `log-bin-index`  | Binary log for PITR/replication |
| `binlog_format`             | `ROW` recommended             |
| `sync_binlog`               | `1` for durability            |
| `binlog_expire_logs_seconds`| 7–14 days                     |

### mysqldump

| Option              | Effect                  | Recommendation |
|---------------------|-------------------------|----------------|
| `quick`             | Streams row by row      | Enable |
| `quote-names`       | Escapes identifiers     | Enable |
| `max_allowed_packet`| Larger rows/blobs       | ≥ `64M` |

## Operations

Set up backups, retention, and restore tests separately. Binary logs support recovery together with a suitable backup; enabling them alone is not a backup. Review logs at the paths in the active `my.ini`. Use `tasklist /FI "IMAGENAME eq mysqld.exe"` for process information; stop the server through its service during normal operation.
