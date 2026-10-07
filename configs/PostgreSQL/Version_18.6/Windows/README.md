# <img src="https://www.vectorlogo.zone/logos/postgresql/postgresql-icon.svg" alt="PostgreSQL Logo" width="26"/> PostgreSQL - Windows

- [Security status](#security-status)
- [Installation notes](#installation-notes)
- [TLS mode](#tls-mode)
- [Roles and login](#roles-and-login)
- [Parameter reference](#parameter-reference)
- [Init script](#init-script)
- [Windows commands](#windows-commands)
- [BSI alignment](#bsi-alignment)
- [References](#references)

---

## Security status

This is a secure baseline, not a production guarantee. It uses localhost-only access, SCRAM-SHA-256, explicit `pg_hba.conf` rules, conservative durability settings, and operational logging.

`postgres` is the bootstrap/maintenance role with superuser privileges. Use the example roles `app_admin` and `app_reader` for normal access.

Before production use, replace all example passwords, enable TLS before remote access, restrict file ACLs, configure backups, test restore, and review Windows firewall/service permissions. No sample config can cover every security requirement of every deployment; secret management, encryption at rest, OS hardening, firewall rules, patch management, and application-layer controls still belong to the deployment.

---

## Installation notes

Install via the PostgreSQL Windows installer:
[PostgreSQL Windows download](https://www.postgresql.org/download/windows/)

Default paths after installation:

- Binaries: `C:\Program Files\PostgreSQL\18\bin\`
- Config file: `C:\Program Files\PostgreSQL\18\data\postgresql.conf`
- HBA file: `C:\Program Files\PostgreSQL\18\data\pg_hba.conf`
- Data directory: `C:\Program Files\PostgreSQL\18\data\`
- Log directory: `C:\Program Files\PostgreSQL\18\data\log\`

The example `postgresql.conf` uses:

```ini
data_directory = 'C:/Program Files/PostgreSQL/18/data'
hba_file = 'C:/Program Files/PostgreSQL/18/data/pg_hba.conf'
```

Start the Windows service:

```powershell
net start postgresql-x64-18
```

Open the PostgreSQL client:

```powershell
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U app_admin -d appdb
```

---

## TLS mode

PostgreSQL can accept TLS and non-TLS connections on the same TCP port. To require TLS, enable `ssl = on` and use `hostssl` rows in `pg_hba.conf`.

Included TLS-oriented files:

- `postgresql-tls.conf`
- `pg_hba-tls.conf`

Recommended Windows flow:

1. Create or install CA-issued certificates in `C:\postgresql\ssl\`.
2. Restrict `server.key` ACLs to the PostgreSQL service account and administrators.
3. Copy `pg_hba-tls.conf` to the data directory.
4. Start PostgreSQL with `postgresql-tls.conf` or merge its TLS settings into the active `postgresql.conf`.
5. Connect clients with `sslmode=verify-full` and the trusted CA certificate.

Certificate generation is also described in the repository [README](../../../../README.md#-tls-configuration).

---

## Roles and login

Recommended example roles:

| Role | Purpose | Privileges |
|------|---------|------------|
| `app_admin` | Application/admin access to the sample database | Access to `appdb`, DDL/DML in schema `public`, no superuser |
| `app_reader` | Read-only access | Access to `appdb`, `SELECT` in schema `public`, no superuser |
| `postgres` | Initialization, backup/restore, maintenance | Superuser; not for normal application access |

Change the example passwords in `init_users.sql` before production-like use.

---

## Parameter reference

### Network and authentication

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `listen_addresses` | Interface binding | `127.0.0.1`; use a trusted IP/VPN for remote access |
| `port` | PostgreSQL port | `5432` unless required otherwise |
| `max_connections` | Concurrent connections | Start with 100; add pooling if needed |
| `password_encryption` | Password hash format | `scram-sha-256` |
| `pg_hba.conf` | Client authentication policy | Localhost only by default |
| `pg_hba-tls.conf` | TLS-only client authentication policy | Use `hostssl`; reject accidental `hostnossl` access |

### TLS

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `ssl` | Enables TLS | `on` before allowing remote clients |
| `ssl_cert_file` | Server certificate | `C:/postgresql/ssl/server.crt` |
| `ssl_key_file` | Server private key | Restrict ACLs to the service account |
| `ssl_ca_file` | CA certificate | `C:/postgresql/ssl/ca.crt` |
| `ssl_min_protocol_version` | Minimum TLS version | `TLSv1.2` or stricter |

### Storage and durability

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `data_directory` | Database files | Dedicated directory with restricted permissions |
| `shared_buffers` | PostgreSQL buffer cache | Start with 25% of RAM on dedicated servers |
| `effective_cache_size` | Planner cache estimate | Around 50-75% of available memory |
| `fsync` | Flush WAL/data safely | `on` |
| `synchronous_commit` | Commit durability | `on` |
| `full_page_writes` | Crash safety | `on` |
| `wal_level` | WAL detail | `replica` for backup/replication readiness |

### Logging and diagnostics

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `logging_collector` | Collect logs into files | `on` for Windows service installs |
| `log_directory` | Log directory | `log` below the data directory |
| `log_connections` / `log_disconnections` | Session audit trail | `all` / `on` |
| `log_checkpoints` | Checkpoint diagnostics | `on` |
| `log_autovacuum_min_duration` | Autovacuum diagnostics | `10min` baseline |
| `log_min_error_statement` | Statements that cause errors | `error` baseline; review for sensitive query data |
| `log_min_duration_statement` | Slow query threshold | `1000` ms to start |
| `log_statement` | Statement logging | `ddl` |
| `log_lock_waits` | Lock wait diagnostics | `on` |

### Runtime limits

| Option | Meaning | Recommendation |
|--------|---------|----------------|
| `idle_in_transaction_session_timeout` | Ends idle open transactions | `10min` baseline |
| `statement_timeout` | Query runtime limit | Set per app/workload |
| `lock_timeout` | Lock wait limit | Set per app/workload |

---

## Init script

`init_postgresql.bat` starts the service, runs `init_users.sql`, and prints selected configuration paths. Run it with administrator rights and replace `PGPASSWORD` before use.

---

## Windows commands

| Command | Description |
|---------|-------------|
| `net start postgresql-x64-18` | Starts the PostgreSQL 18 Windows service. |
| `net stop postgresql-x64-18` | Stops the PostgreSQL 18 Windows service cleanly. |
| `sc qc postgresql-x64-18` | Shows service configuration. |
| `sc query postgresql-x64-18` | Shows service status. |
| `tasklist /FI "IMAGENAME eq postgres.exe"` | Checks whether PostgreSQL processes are running. |

---

## BSI alignment

This baseline is aligned with the BSI key points for database systems, the BSI practical guide for secure database systems, and APP.4.3. It covers baseline hardening, regulated setup, encrypted database connections, monitoring/logging, and backup/restore preparation.

For production-like use, compare the configuration with protection needs, network exposure, secret management, backup/restore, and existing operations processes.

See [BSI alignment notes](../BSI-Alignment.md) for the checklist.

---

## References

- [PostgreSQL 18 SSL/TLS documentation](https://www.postgresql.org/docs/18/ssl-tcp.html)
- [PostgreSQL `pg_hba.conf` documentation](https://www.postgresql.org/docs/18/auth-pg-hba-conf.html)
- [PostgreSQL password authentication and SCRAM](https://www.postgresql.org/docs/18/auth-password.html)
- [PostgreSQL role attributes](https://www.postgresql.org/docs/18/role-attributes.html)
- [PostgreSQL connection settings](https://www.postgresql.org/docs/18/runtime-config-connection.html)
- [PostgreSQL resource settings](https://www.postgresql.org/docs/18/runtime-config-resource.html)
- [PostgreSQL WAL settings](https://www.postgresql.org/docs/18/runtime-config-wal.html)
- [PostgreSQL logging settings](https://www.postgresql.org/docs/18/runtime-config-logging.html)
- [PostgreSQL client timeout settings](https://www.postgresql.org/docs/18/runtime-config-client.html)

© 2026 - Secure database configurations
