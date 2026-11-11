# MariaDB – Windows

[Deutsch](README-de.md) · [Database overview](../../README.md) · [BSI alignment](../../../README.md#bsi-alignment)

- [Installation and active configuration](#installation-and-active-configuration)
- [Login and users](#login-and-users)
- [Configure TLS](#configure-tls)
- [Verify the configuration](#verify-the-configuration)
- [Parameter reference](#parameter-reference)
  - [Security & network](#security--network)
  - [TLS/SSL](#tlsssl)
  - [Storage & performance](#storage--performance)
  - [Character sets](#character-sets)
  - [Logging](#logging)
  - [binary log](#binary-log)
  - [mysqldump](#mysqldump)
- [Operations](#operations)

## Installation and active configuration

Use the [MariaDB MSI and installation guide](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/installing-mariadb/installing-mariadb-msi-packages-on-windows). The following paths are examples from the supplied [`my.ini`](my.ini); check the actual installation and service paths.

| Purpose | Example path |
|---------|--------------|
| Binaries | `C:\Program Files\MariaDB 11.8\bin` |
| Active configuration, to verify in service settings | `C:\Program Files\MariaDB 11.8\data\my.ini` |
| Initialized data directory | `C:\Program Files\MariaDB 11.8\data` |
| Template log directory | `C:\Program Files\MariaDB 11.8\data\mysql` |

The data directory must already have been initialized during installation. Creating an empty directory does not initialize the DBMS. Do not overwrite an existing data directory through reinitialization.

1. Determine the actual Windows service name; the examples below use `MariaDB`.
2. Use `sc.exe qc MariaDB` to check which configuration the service loads. Keeping `my.ini` in the repository does not activate it.
3. Adapt paths and memory settings in the active configuration. Create the log and any import/export directories; grant the service account the required permissions.
4. Restart the service and inspect the configured error log.

```powershell
sc.exe qc MariaDB
net stop MariaDB
net start MariaDB
sc.exe query MariaDB
```

Service changes require an administrator PowerShell. Do not run a second manually started server against the data directory of a running service.

## Login and users

Run client commands in a regular PowerShell; the `&` call operator executes the quoted program path.

```powershell
& "C:\Program Files\MariaDB 11.8\bin\mariadb.exe" --host=127.0.0.1 --user=root --password
```

The password is requested interactively. Use administration accounts for setup and maintenance; give applications separate, restricted accounts.

First adapt passwords and allowed hosts in [`init_scripts/init_users.sql`](init_scripts/init_users.sql). Run the file in an administrative client session, for example with `SOURCE C:/path/to/repository/configs/MariaDB/Version_11/Windows/init_scripts/init_users.sql;`. It creates `appdb`, `app_admin`, and `app_reader`; it does not initialize an empty data directory.

Alternatively, run `init_scripts\init_mariadb.bat`. It only applies the adjacent `init_users.sql` through the client to the running service; it does not start or stop servers. The administration password is requested interactively. Set `MARIADB_BIN`, `MARIADB_HOST`, `MARIADB_PORT`, and `MARIADB_ADMIN` for non-default installations. Missing files and SQL/connection failures produce a nonzero exit code.

## Configure TLS

Server TLS lines in `my.ini` are commented out. The template therefore does not yet enforce a TLS connection configured by you. Follow the [shared TLS guide](../../../../docs/TLS.md) to create the CA, server certificate, and server key. Store them using the names specified in `ssl-ca`, `ssl-cert`, and `ssl-key`, and enable those server lines in `[mysqld]`. Client certificate options belong in an appropriate client section.

Grant the service account read access to the private server key. Then configure the transport requirement (`require_secure_transport=ON` or appropriate account rules) and restart the service. Enable CA and hostname verification on clients. The exact check depends on the MariaDB or MySQL client; `SHOW SESSION STATUS LIKE 'Ssl_cipher';` shows encryption for the current connection.

## Verify the configuration

The following reference contains recommendations. Check effective values with `SHOW VARIABLES`, especially file paths, network binding, TLS, and memory settings. A successful service start alone does not confirm these values.

## Parameter reference

### Security & network

| Option              | Meaning                     | Recommendation |
|---------------------|-----------------------------|----------------|
| `bind_address`      | Bind IP                     | `127.0.0.1` (or VPN IP) |
| `skip_networking`   | Disable TCP/IP              | `0`; only `1` if local-only |
| `skip_name_resolve` | Avoid DNS lookups           | `1` |
| `max_connections`   | Max clients                 | 100–500 depending on workload |
| `local_infile`      | `LOAD DATA LOCAL INFILE`    | `0` (disable) |
| `secure_file_priv` | Import/export directory | Set a dedicated directory; commented out in the template |
| `symbolic-links`    | Symlinks in tables          | `0` (disable) |

### TLS/SSL

| Option    | Meaning           | Recommendation |
|-----------|-------------------|----------------|
| `ssl-ca`  | CA certificate    | `C:/mariadb/ssl/ca-cert.pem` |
| `ssl-cert`| Server certificate| `C:/mariadb/ssl/server-cert.pem` |
| `ssl-key` | Server key        | `C:/mariadb/ssl/server-key.pem` |

> Enforce TLS via SQL: `ALTER USER 'app_admin'@'%' REQUIRE SSL;`

### Storage & performance

| Option                       | Meaning                  | Recommendation |
|------------------------------|--------------------------|----------------|
| `innodb_buffer_pool_size`    | InnoDB buffer            | Tune for available RAM and workload |
| `innodb_log_file_size`       | Redo log size            | 128–512 MB |
| `innodb_file_per_table`      | Separate tablespace      | `1` |
| `innodb_flush_log_at_trx_commit` | Durability vs performance | `1` (ACID), `2` if needed |
| `innodb_flush_method`        | I/O handling             | Do not apply automatically on Windows |
| `aria_pagecache_buffer_size` | Aria cache               | ~128 MB (workload-dependent) |
| `aria_log_file_size`         | Aria log size            | ~64 MB |

### Character sets

| Option                  | Meaning            | Recommendation |
|-------------------------|--------------------|----------------|
| `character_set_server`  | Default charset    | `utf8mb4` |
| `collation_server`      | Collation          | `utf8mb4_general_ci` |

### Logging

| Option                       | Meaning                     | Recommendation |
|------------------------------|-----------------------------|----------------|
| `log_error`                  | Error log                   | Set |
| `slow_query_log`             | Slow queries                | Enable |
| `slow_query_log_file`        | Slow query log path         | e.g., `C:/Program Files/.../mysql-slow.log` |
| `long_query_time`            | Slow threshold              | 1–2 s |
| `log_queries_not_using_indexes` | Inefficient queries     | Enable consciously |
| `general_log`                | All queries (debug)         | `0` in prod |
| `general_log_file`           | Path for general query log  | e.g. `C:/Program Files/MariaDB 11.8/data/mysql/mysql-general.log` |

### binary log

| Option                  | Meaning              | Recommendation |
|-------------------------|----------------------|----------------|
| `log_bin`               | Enable binlog        | Set path |
| `log_bin_index`         | Index file           | Set path |
| `binlog_format`         | Binlog format        | `MIXED` or `ROW` |
| `sync_binlog`           | Synchronization      | `1` |
| `expire_logs_days`      | Binlog retention     | 7–14 days |
| `binlog_expire_logs_seconds` | Binlog retention (new) | 7–14 days (604800–1209600) |

### mysqldump

| Option            | Meaning                   | Recommendation |
|-------------------|---------------------------|----------------|
| `quick`           | Stream row by row         | Enable |
| `quote-names`     | Backtick identifiers      | Enable |
| `max_allowed_packet` | Packet size for dumps  | `64M` or higher |

## Operations

Set up backups, retention, and restore tests separately. Binary logs support recovery together with a suitable backup; enabling them alone is not a backup. Review logs at the paths in the active `my.ini`. Use `tasklist /FI "IMAGENAME eq mysqld.exe"` for process information; stop the server through its service during normal operation.
