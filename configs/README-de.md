# Datenbankkonfigurationen – Gemeinsames BSI-Alignment

[English](README.md)

Diese README legt das gemeinsame BSI-Alignment für **alle Datenbankvorlagen** unter `configs/` fest: **MariaDB, MongoDB, MySQL, PostgreSQL, Redis Enterprise und Weaviate**. Es gilt unabhängig vom DBMS für die dokumentierten Container- und nativen Installationen. Datenbankspezifische Umsetzungsdetails und zusätzliche Anforderungen ergänzen diesen gemeinsamen Rahmen.

- [BSI-Alignment](#bsi-alignment)
  - [Referenzen](#referenzen)
  - [Gemeinsame Checkliste](#gemeinsame-checkliste)
  - [Einordnung und Nutzung](#einordnung-und-nutzung)
  - [Umsetzung je Datenbank](#umsetzung-je-datenbank)
- [Datenbankordner](#datenbankordner)

## BSI-Alignment

Die BSI-Eckpunkte für Datenbanksysteme und der BSI-Praxisleitfaden zur sicheren Nutzung von Datenbanksystemen bilden den gemeinsamen Orientierungsrahmen für diese Konfigurationsvorlagen. Die folgende Checkliste fasst ausgewählte übergreifende Sicherheitsziele zusammen; verfügbare Einstellungen, Skripte und betriebliche Maßnahmen sind je DBMS und Deployment zu prüfen.

Der IT-Grundschutz-Baustein APP.4.3 behandelt **relationale Datenbanksysteme**. Seine Anwendbarkeit auf andere Datenbanktypen ist für die Zielumgebung zu bewerten; sie wird nicht pauschal für jedes DBMS in diesem Repository vorausgesetzt.

### Referenzen

- [BSI Eckpunkte der IT-Sicherheitsanforderungen für die Auswahl und den Einsatz von Datenbanksystemen](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_papier.pdf?__blob=publicationFile&v=2)
- [BSI Anhang zu den Eckpunkten für Datenbanksysteme](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/datenbanksystem_eckpunkte_anlagen.pdf?__blob=publicationFile&v=2)
- [BSI Praxisleitfaden zur sicheren Nutzung von Datenbanksystemen](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Datenbanksysteme/praxisleitfaden_sichere_datenbanksysteme.pdf)
- [BSI IT-Grundschutz APP.4.3 Relationale Datenbanken (Edition 2023)](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Grundschutz/IT-GS-Kompendium_Einzel_PDFs_2023/06_APP_Anwendungen/APP_4_3_Relationale_Datenbanksysteme_Edition_2023.pdf?__blob=publicationFile&v=3)

### Gemeinsame Checkliste

| Thema | Übergreifendes Sicherheitsziel | Prüfung je DBMS und Deployment |
|-------|-------------------------------|--------------------------------|
| Planung und Standardisierung | Dokumentierte, versionierte und reproduzierbare Konfigurationen verwenden | Version und Betriebsmodell wählen; Schutzbedarf, Zuständigkeiten und Abweichungen dokumentieren |
| Sichere Erstinstallation | Dienst bewusst einrichten und initiale Zugänge schützen | Beispiel-Secrets ersetzen, Init-Skripte anpassen und Rechte auf Daten, Logs und Secrets einschränken |
| Zugriffskontrolle und Authentifizierung | Starke Authentifizierung und Rollen nach Least Privilege einsetzen | Anwendungs- und Administrationskonten, vertrauenswürdige Netze und DBMS-spezifische Zugriffsregeln festlegen |
| Transportschutz | Datenbankverbindungen verschlüsseln und Zertifikatsidentitäten prüfen | DBMS-spezifische TLS-Konfiguration aktivieren; CA, Zertifikate, Clients und Netzwerkfreigaben anpassen |
| Logging und Monitoring | Sicherheitsrelevante Ereignisse protokollieren und im Betrieb auswerten | Logumfang, Zugriffsrechte, Weiterleitung, Aufbewahrung und Zuständigkeiten für die Überwachung festlegen |
| Backup und Restore | Regelmäßige, geschützte Backups erstellen und Wiederherstellbarkeit prüfen | Zeitplanung, Verschlüsselung, externe Ablage, Aufbewahrung, Restore-Tests und Wiederherstellungsziele festlegen |
| Updates und Wartung | Datenbank und Betriebsumgebung aktuell halten | DBMS-, Image-, Host- und Plattform-Updates verfolgen; Upgrades planen und testen |

### Einordnung und Nutzung

Die Checkliste ist eine thematische Zusammenfassung, keine vollständige Zuordnung zu einzelnen BSI-Anforderungsnummern. Sie ist ein gemeinsamer Prüfrahmen und keine Aussage, dass jede Vorlage sämtliche Maßnahmen umsetzt. Die jeweilige Datenbankdokumentation beschreibt die Umsetzung und verbleibende Betriebsaufgaben. Vor dem Einsatz ist die Konfiguration mit dem Schutzbedarf und den Prozessen der Zielumgebung abzugleichen.

### Umsetzung je Datenbank

Die gemeinsame Checkliste gilt für jede der folgenden Datenbanken. Die Tabelle ordnet vorhandene Maßnahmen und noch erforderliche Schritte den jeweiligen Vorlagen zu; die verlinkten Anleitungen beschreiben die konkrete Umsetzung.

| Datenbank | Vorhandene Maßnahmen | Noch erforderliche Schritte |
|-----------|----------------------|----------------------------|
| [MariaDB](MariaDB/README-de.md) | Compose mit lokaler Host-Portbindung, Benutzerinitialisierung und Server-TLS-Konfiguration; native Windows-Vorlage | Zertifikate bereitstellen; unter Windows TLS aktivieren; Kontorechte, Backup und Restore festlegen |
| [MongoDB](MongoDB/README-de.md) | TLS-Pflicht und Autorisierung in Linux-/Windows-Konfigurationen; Bootstrap-Verfahren für das Administrationskonto | Server- und Clientzertifikate bereitstellen; eingeschränkte Anwendungskonten und Backups einrichten |
| [MySQL](MySQL/README-de.md) | Compose mit lokaler Host-Portbindung, Anwendungsnutzer und Server-TLS-Konfiguration; native Windows-Vorlage | Zertifikate bereitstellen; unter Windows TLS und Anwendungskonten einrichten; Backup und Restore festlegen |
| [PostgreSQL](PostgreSQL/README-de.md) | Lokale Standardanbindung, SCRAM-SHA-256, Anwendungsrollen, Logging, optionale TLS-Konfiguration und logische Backup-Hilfsskripte für Linux | TLS vor nicht-lokalem Zugriff aktivieren; Backup-Zeitplanung, Verschlüsselung, Aufbewahrung und Restore-Tests ergänzen; Windows-Backup-Prozess einrichten |
| [Redis Enterprise](Redis/README-de.md) | Native Cluster-Anleitung für TLS, ACL/RBAC, Netzwerkzugriff, Logging, Persistenz, Backups und Replikation | Maßnahmen über die Verwaltungswerkzeuge aktivieren und prüfen; tatsächliche Portfreigaben, Zertifikate, Replikation und Wiederherstellung testen |
| [Weaviate](Weaviate/README-de.md) | API-Key-Authentifizierung, RBAC, lokale direkte Zugänge und Container-Härtung; separate Traefik-TLS-Variante mit deaktiviertem Dashboard und lokaler Portbindung | Beispiel-Keys ersetzen, Benutzerrollen vergeben und Backups einrichten; Zertifikate für die Proxy-Variante bereitstellen und gewollte Netzwerkfreigaben prüfen |

DBMS-spezifische Umsetzung und Betriebsaufgaben stehen in den jeweiligen Versions- und Plattform-READMEs. Die gemeinsamen BSI-Referenzen und Sicherheitsziele werden hier für alle DBMS gepflegt.

## Datenbankordner

- [MariaDB](MariaDB/README-de.md)
- [MongoDB](MongoDB/README-de.md)
- [MySQL](MySQL/README-de.md)
- [PostgreSQL](PostgreSQL/README-de.md)
- [Redis](Redis/README-de.md)
- [Weaviate](Weaviate/README-de.md)

© 2026 - Sichere Datenbankkonfigurationen
