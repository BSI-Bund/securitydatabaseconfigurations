# PostgreSQL 18.6 - BSI-Alignment-Hinweise

Diese PostgreSQL-Baseline ist als Empfehlung und Vorlage für sichere PostgreSQL-Setups gedacht. Sie orientiert sich an den BSI-Eckpunkten für Datenbanksysteme, dem BSI-Praxisleitfaden für sichere Datenbanksysteme und dem IT-Grundschutz-Baustein APP.4.3.

Referenzen:
- [BSI Eckpunkte der IT-Sicherheitsanforderungen für die Auswahl und den Einsatz von Datenbanksystemen](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_papier.pdf?__blob=publicationFile&v=2)
- [BSI Anhang zu den Eckpunkten für Datenbanksysteme](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_anlagen.pdf?__blob=publicationFile&v=2)
- [BSI Praxisleitfaden zur sicheren Nutzung von Datenbanksystemen](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/praxisleitfaden_sichere_datenbanksysteme.pdf)
- [BSI IT-Grundschutz APP.4.3 Relationale Datenbanksysteme](https://it-grundschutzkompendium.de/app_anwendungen/app.4.3_relationale_datenbanken)

## Durch Diese Baseline Unterstützt

| BSI-Thema | Empfehlung in dieser Baseline | Hinweise für die Nutzung |
|-----------|------------------------------|-----------------------|
| Planung und Standardisierung | Versionierter PostgreSQL-Ordner, READMEs, Parameterreferenz und getestete Compose-Dateien | Als nachvollziehbare Ausgangsbasis für eigene Deployments verwenden |
| Sichere Erstinstallation | Compose-Setup, `.env.example`, Init-Skripte, Beispielrollen nach Least Privilege | Beispiel-Secrets und Rollen an die jeweilige Anwendung anpassen |
| Zugriffskontrolle und Authentifizierung | SCRAM-SHA-256, explizite `pg_hba.conf`, localhost Host-Binding | Netzbereiche, Servicekonten und Admin-Zugriff bewusst festlegen |
| Transportschutz | TLS-Override, `hostssl`-Regeln, Zertifikatsverzeichnis, Generator und lokaler TLS-Start mit einem Befehl | Für nicht-lokale Verbindungen eigene CA/Zertifikate verwenden |
| Logging und Monitoring | Logging für Verbindungen/Trennungen, DDL, langsame Queries, Locks, Autovacuum und Checkpoints | Logumfang und Weiterleitung an die Umgebung anpassen |
| Backup und Restore | `backup.sh`, `restore.sh`, Checksum-Erzeugung, Backup-Doku | Backup-Ort, Aufbewahrung und Restore-Tests passend zum Schutzbedarf wählen |
| Updates und Wartung | Versionierter Image-Tag und Dokumentation | PostgreSQL-, Image-, Host- und Plattform-Updates regelmäßig verfolgen |

## Einordnung

Die Dateien decken technische Empfehlungen für PostgreSQL ab. Sie ersetzen keine Bewertung der konkreten Umgebung, sondern geben prüfbare Ausgangswerte für Konfiguration, Compose-Betrieb, TLS, Rollen, Logging und Backup.

## Nutzungshinweise

Die Beispiele sind bewusst lauffähig gehalten und enthalten Platzhalterwerte. Für produktionsnahe Deployments sollten Secrets, Netzbereiche, Zertifikate, Rollen, Backup/Restore und Logging an den jeweiligen Schutzbedarf angepasst werden.

© 2026 - Sichere Datenbankkonfigurationen
