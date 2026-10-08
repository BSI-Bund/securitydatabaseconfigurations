# <img src="https://www.vectorlogo.zone/logos/postgresql/postgresql-icon.svg" alt="PostgreSQL Logo" width="26"/> PostgreSQL - Windows

- [Sicherheitsstatus](#sicherheitsstatus)
- [Installationshinweise](#installationshinweise)
- [TLS-Modus](#tls-modus)
- [Rollen und Login](#rollen-und-login)
- [Parameterreferenz](#parameterreferenz)
- [Init-Skript](#init-skript)
- [Windows-Befehle](#windows-befehle)
- [BSI-Alignment](#bsi-alignment)
- [Referenzen](#referenzen)

---

## Sicherheitsstatus

Dies ist eine sichere Baseline, aber keine Produktionsgarantie. Genutzt werden localhost-only Zugriff, SCRAM-SHA-256, explizite `pg_hba.conf`-Regeln, konservative Einstellungen für Dauerhaftigkeit und betriebliches Logging.

`postgres` ist die Bootstrap-/Wartungsrolle mit Superuser-Rechten. Für normalen Zugriff sind die Beispielrollen `app_admin` und `app_reader` vorgesehen.

Vor produktiver Nutzung: Beispielpasswörter ersetzen, TLS vor Remote-Zugriff aktivieren, Datei-ACLs beschränken, Backups konfigurieren, Restore testen und Windows-Firewall/Service-Rechte prüfen. Keine Beispielkonfiguration kann alle Sicherheitsanforderungen jeder Umgebung vollständig abdecken; Secret-Management, Verschlüsselung ruhender Daten, OS-Hardening, Firewall-Regeln, Patch-Management und Anwendungsschutz bleiben Teil des Deployments.

---

## Installationshinweise

Installation über den PostgreSQL-Windows-Installer:
[PostgreSQL Windows-Download](https://www.postgresql.org/download/windows/)

Standardpfade nach der Installation:

- Binaries: `C:\Program Files\PostgreSQL\18\bin\`
- Konfigurationsdatei: `C:\Program Files\PostgreSQL\18\data\postgresql.conf`
- HBA-Datei: `C:\Program Files\PostgreSQL\18\data\pg_hba.conf`
- Datenverzeichnis: `C:\Program Files\PostgreSQL\18\data\`
- Logverzeichnis: `C:\Program Files\PostgreSQL\18\data\log\`

Die Beispiel-`postgresql.conf` nutzt:

```ini
data_directory = 'C:/Program Files/PostgreSQL/18/data'
hba_file = 'C:/Program Files/PostgreSQL/18/data/pg_hba.conf'
```

Windows-Service starten:

```powershell
net start postgresql-x64-18
```

PostgreSQL-Client öffnen:

```powershell
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U app_admin -d appdb
```

---

## TLS-Modus

PostgreSQL kann TLS- und Nicht-TLS-Verbindungen auf demselben TCP-Port annehmen. Um TLS zu erzwingen, `ssl = on` aktivieren und `hostssl`-Zeilen in `pg_hba.conf` verwenden.

Enthaltene TLS-orientierte Dateien:

- `postgresql-tls.conf`
- `pg_hba-tls.conf`

Empfohlener Ablauf unter Windows:

1. CA-signierte Zertifikate in `C:\postgresql\ssl\` erstellen oder ablegen.
2. ACLs für `server.key` auf PostgreSQL-Servicekonto und Administratoren beschränken.
3. `pg_hba-tls.conf` in das Datenverzeichnis kopieren.
4. PostgreSQL mit `postgresql-tls.conf` starten oder die TLS-Werte in die aktive `postgresql.conf` übernehmen.
5. Clients mit `sslmode=verify-full` und vertrauenswürdigem CA-Zertifikat verbinden.

Zertifikatserstellung ist auch in der Repository-[README](../../../../README-de.md#-tls-konfiguration) beschrieben.

---

## Rollen und Login

Empfohlene Beispielrollen:

| Rolle | Zweck | Rechte |
|-------|-------|--------|
| `app_admin` | Anwendung/Administration der Beispieldatenbank | Zugriff auf `appdb`, DDL/DML im Schema `public`, kein Superuser |
| `app_reader` | Lesender Zugriff | Zugriff auf `appdb`, `SELECT` im Schema `public`, kein Superuser |
| `postgres` | Initialisierung, Backup/Restore, Wartung | Superuser; nicht für normalen Anwendungszugriff |

Die Beispielpasswörter in `init_users.sql` müssen vor produktionsnaher Nutzung geändert werden.

---

## Parameterreferenz

### Netzwerk und Authentifizierung

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `listen_addresses` | Interface-Bindung | `127.0.0.1`; für Remote-Zugriff vertrauenswürdige IP/VPN nutzen |
| `port` | PostgreSQL-Port | `5432`, sofern nichts anderes erforderlich ist |
| `max_connections` | Gleichzeitige Verbindungen | Mit 100 starten; bei Bedarf Pooling nutzen |
| `password_encryption` | Passwort-Hashformat | `scram-sha-256` |
| `pg_hba.conf` | Client-Authentifizierungsregeln | Standardmäßig nur localhost |
| `pg_hba-tls.conf` | TLS-only Client-Authentifizierungsregeln | `hostssl` nutzen; versehentliches `hostnossl` ablehnen |

### TLS

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `ssl` | Aktiviert TLS | `on` vor Remote-Zugriff |
| `ssl_cert_file` | Serverzertifikat | `C:/postgresql/ssl/server.crt` |
| `ssl_key_file` | Privater Serverschlüssel | ACLs auf Servicekonto beschränken |
| `ssl_ca_file` | CA-Zertifikat | `C:/postgresql/ssl/ca.crt` |
| `ssl_min_protocol_version` | Minimale TLS-Version | `TLSv1.2` oder strenger |

### Speicher und Dauerhaftigkeit

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `data_directory` | Datenbankdateien | Dediziertes Verzeichnis mit restriktiven Berechtigungen |
| `shared_buffers` | PostgreSQL-Buffer-Cache | Startwert ca. 25% RAM auf dedizierten Servern |
| `effective_cache_size` | Planner-Schätzung für Cache | Etwa 50-75% des verfügbaren Speichers |
| `fsync` | Schreibt WAL/Daten sicher auf Datenträger | `on` |
| `synchronous_commit` | Commit-Dauerhaftigkeit | `on` |
| `full_page_writes` | Crash-Sicherheit | `on` |
| `wal_level` | WAL-Detailgrad | `replica` für Backup-/Replikationsbereitschaft |

### Logging und Diagnose

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `logging_collector` | Sammelt Logs in Dateien | `on` für Windows-Service-Installationen |
| `log_directory` | Logverzeichnis | `log` unterhalb des Datenverzeichnisses |
| `log_connections` / `log_disconnections` | Sitzungsnachvollziehbarkeit | `all` / `on` |
| `log_checkpoints` | Checkpoint-Diagnose | `on` |
| `log_autovacuum_min_duration` | Autovacuum-Diagnose | `10min` als Basis |
| `log_min_error_statement` | Statements, die Fehler auslösen | `error` als Basis; auf sensible Query-Daten prüfen |
| `log_min_duration_statement` | Slow-Query-Schwelle | Startwert `1000` ms |
| `log_statement` | Statement-Logging | `ddl` |
| `log_lock_waits` | Diagnose für Lock-Wartezeiten | `on` |

### Laufzeitlimits

| Option | Bedeutung | Empfehlung |
|--------|-----------|------------|
| `idle_in_transaction_session_timeout` | Beendet untätige offene Transaktionen | `10min` als Basis |
| `statement_timeout` | Laufzeitlimit für Abfragen | Pro Anwendung/Workload setzen |
| `lock_timeout` | Wartezeitlimit für Locks | Pro Anwendung/Workload setzen |

---

## Init-Skript

`init_postgresql.bat` startet den Service, führt `init_users.sql` aus und gibt ausgewählte Konfigurationspfade aus. Mit Administratorrechten ausführen und `PGPASSWORD` vor der Nutzung ersetzen.

---

## Windows-Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `net start postgresql-x64-18` | Startet den PostgreSQL-18-Windows-Service. |
| `net stop postgresql-x64-18` | Stoppt den PostgreSQL-18-Windows-Service sauber. |
| `sc qc postgresql-x64-18` | Zeigt die Service-Konfiguration. |
| `sc query postgresql-x64-18` | Zeigt den Service-Status. |
| `tasklist /FI "IMAGENAME eq postgres.exe"` | Prüft, ob PostgreSQL-Prozesse laufen. |

---

## BSI-Alignment

Diese Baseline ist an den BSI-Eckpunkten für Datenbanksysteme, dem BSI-Praxisleitfaden für sichere Datenbanksysteme und APP.4.3 ausgerichtet. Abgedeckt sind insbesondere Basishärtung, geregelte Einrichtung, verschlüsselte Datenbankanbindung, Monitoring/Logging und Backup-/Restore-Vorbereitung.

Für produktionsnahe Nutzung sollte die Konfiguration mit Schutzbedarf, Netzwerkfreigaben, Secret-Management, Backup/Restore und den vorhandenen Betriebsprozessen abgeglichen werden.

Siehe [BSI-Alignment-Hinweise](../BSI-Alignment-de.md) für die Checkliste.

---

## Referenzen

- [PostgreSQL 18 SSL/TLS-Dokumentation](https://www.postgresql.org/docs/18/ssl-tcp.html)
- [PostgreSQL `pg_hba.conf`-Dokumentation](https://www.postgresql.org/docs/18/auth-pg-hba-conf.html)
- [PostgreSQL Passwortauthentifizierung und SCRAM](https://www.postgresql.org/docs/18/auth-password.html)
- [PostgreSQL Rollenattribute](https://www.postgresql.org/docs/18/role-attributes.html)
- [PostgreSQL Verbindungseinstellungen](https://www.postgresql.org/docs/18/runtime-config-connection.html)
- [PostgreSQL Resource-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-resource.html)
- [PostgreSQL WAL-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-wal.html)
- [PostgreSQL Logging-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-logging.html)
- [PostgreSQL Client-Timeout-Einstellungen](https://www.postgresql.org/docs/18/runtime-config-client.html)

© 2026 - Sichere Datenbankkonfigurationen
