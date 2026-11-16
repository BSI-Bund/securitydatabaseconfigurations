# Datenbankkonfigurationen – Gemeinsames BSI-Alignment

[English](README.md)

Diese README legt das gemeinsame BSI-Alignment für **alle Datenbankvorlagen** unter `configs/` fest: **MariaDB, MongoDB, MySQL, PostgreSQL, Redis Enterprise und Weaviate**. Es gilt unabhängig vom DBMS für die dokumentierten Container- und nativen Installationen. Datenbankspezifische Umsetzungsdetails und zusätzliche Anforderungen ergänzen diesen gemeinsamen Rahmen.

- [BSI-Alignment](#bsi-alignment)
  - [Referenzen](#referenzen)
  - [Gemeinsame Checkliste](#gemeinsame-checkliste)
  - [Freigabekriterien und Transportgrenzen](#freigabekriterien-und-transportgrenzen)
  - [Einordnung und Nutzung](#einordnung-und-nutzung)
  - [Umsetzung je Datenbank](#umsetzung-je-datenbank)
- [Versionen und Konfigurationsordner](#versionen-und-konfigurationsordner)
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
| Updates und Wartung | Datenbank und Betriebsumgebung aktuell halten | DBMS-, Image-, Host- und Plattform-Updates verfolgen; Versionszuordnung nach der untenstehenden Regel pflegen; Upgrades planen und testen |

### Freigabekriterien und Transportgrenzen

Die Sicherheitsziele und die erforderlichen Nachweise gelten für **alle sechs DBMS**. Die technischen Einstellungen unterscheiden sich; eine lokale Host-Portbindung erfüllt beispielsweise noch nicht die Anforderung an verschlüsselte Verbindungen.

- **Vor produktiver Freigabe** alle Themen der Checkliste für die Zielumgebung umsetzen und nachweisen. Dazu gehören eingeschränkte Anwendungskonten, geprüfte TLS-Verbindungen, geeignete Protokollierung, geschützte Backups mit erfolgreichem Restore-Test und ein geprüfter Patchstand.
- **Unverschlüsselte Zugänge** der PostgreSQL-Basisvariante, der noch nicht für TLS eingerichteten Windows-Vorlagen und der lokalen Weaviate-Beispiele sind ausschließlich für bewusst abgegrenzte lokale Tests vorgesehen. Sie werden durch Öffnen der Host-Bindung nicht produktionsgeeignet. Auch Verbindungen zwischen Containern müssen in die Bewertung der Vertrauensgrenze einbezogen werden.
- **TLS im DBMS oder am Proxy:** MariaDB, MySQL, MongoDB, PostgreSQL und Redis Enterprise schützen Datenbankverbindungen über ihre eigene TLS-Konfiguration. Dafür ist Traefik nicht erforderlich. Bei Weaviate schützt die enthaltene Traefik-Variante den HTTPS-Zugang; die direkten lokalen HTTP-/gRPC-Ports umgehen diese TLS-Termination. Für entfernte gRPC-Clients muss ein eigener TLS-geschützter Zugang eingerichtet werden. Die interne HTTP-Verbindung zwischen Traefik und Weaviate setzt ein vertrauenswürdiges Container-Netz voraus.
- **Prüfung aus Client-Sicht:** CA- und Servernamensprüfung auch in Administrationsclients aktivieren. Fehlende oder falsche Zugangsdaten, unzulässige Rollen und unverschlüsselte Verbindungen an TLS-pflichtigen Zugängen müssen abgewiesen werden. Ein Healthcheck allein ist dafür kein Nachweis.
- **Private Schlüssel:** Nur benötigte Server-/Clientschlüssel in die jeweiligen Dienste einbinden. Private CA-Schlüssel bleiben außerhalb der Anwendungscontainer und der bereitgestellten Zertifikatsverzeichnisse. Erneuerung und Ablaufüberwachung der Zertifikate gehören zum Betrieb.

Das Deaktivieren von Traefik-Dashboard und Docker-Provider entfernt keine Datenbank-Authentifizierung. HTTPS-Router, Zertifikate und File-Provider bleiben für die Weaviate-Proxy-Variante erforderlich. Eine vollständig erfüllte BSI-Anforderungsliste lässt sich aus den Vorlagen oder erfolgreichen Funktionstests allein nicht ableiten.

### Einordnung und Nutzung

Die Checkliste ist eine thematische Zusammenfassung, keine vollständige Zuordnung zu einzelnen BSI-Anforderungsnummern. Sie ist ein gemeinsamer Prüfrahmen und keine Aussage, dass jede Vorlage sämtliche Maßnahmen umsetzt. Die jeweilige Datenbankdokumentation beschreibt die Umsetzung und verbleibende Betriebsaufgaben. Vor dem Einsatz ist die Konfiguration mit dem Schutzbedarf und den Prozessen der Zielumgebung abzugleichen.

### Umsetzung je Datenbank

Die gemeinsame Checkliste gilt für jede der folgenden Datenbanken. Die Tabelle ordnet vorhandene Maßnahmen und noch erforderliche Schritte den jeweiligen Vorlagen zu; die verlinkten Anleitungen beschreiben die konkrete Umsetzung.

| Datenbank | Vorhandene Maßnahmen | Noch erforderliche Schritte |
|-----------|----------------------|----------------------------|
| [MariaDB](MariaDB/README-de.md) | Compose mit lokaler Host-Portbindung, Benutzerinitialisierung und Server-TLS-Konfiguration; native Windows-Vorlage | Zertifikate bereitstellen; unter Windows TLS aktivieren; Kontorechte, Backup und Restore festlegen |
| [MongoDB](MongoDB/README-de.md) | TLS-Pflicht und Autorisierung in Linux-/Windows-Konfigurationen; Bootstrap-Verfahren für das Administrationskonto | Server- und Clientzertifikate bereitstellen; eingeschränkte Anwendungskonten und Backups einrichten |
| [MySQL](MySQL/README-de.md) | Compose mit lokaler Host-Portbindung, Anwendungsnutzer und Server-TLS-Konfiguration; native Windows-Vorlage | Zertifikate bereitstellen; unter Windows TLS und Anwendungskonten einrichten; Backup und Restore festlegen |
| [PostgreSQL](PostgreSQL/README-de.md) | Lokale Standardanbindung, SCRAM-SHA-256, Anwendungsrollen, Logging, optionale TLS-Konfiguration einschließlich Adminer-Zertifikatsprüfung und logische Backup-Hilfsskripte für Linux | TLS für produktive TCP-Verbindungen aktivieren; Backup-Zeitplanung, Verschlüsselung, Aufbewahrung und Restore-Tests ergänzen; Windows-Backup-Prozess einrichten |
| [Redis Enterprise](Redis/README-de.md) | Native Cluster-Anleitung für TLS, ACL/RBAC, Netzwerkzugriff, Logging, Persistenz, Backups und Replikation | Maßnahmen über die Verwaltungswerkzeuge aktivieren und prüfen; tatsächliche Portfreigaben, Zertifikate, Replikation und Wiederherstellung testen |
| [Weaviate](Weaviate/README-de.md) | API-Key-Authentifizierung, RBAC, lokale direkte Zugänge und Container-Härtung; separate Traefik-TLS-Variante mit deaktiviertem Dashboard und lokaler Portbindung | Beispiel-Keys ersetzen, Benutzerrollen vergeben und Backups einrichten; Zertifikate für die Proxy-Variante bereitstellen und gewollte Netzwerkfreigaben prüfen |

DBMS-spezifische Umsetzung und Betriebsaufgaben stehen in den jeweiligen Versions- und Plattform-READMEs. Die gemeinsamen BSI-Referenzen und Sicherheitsziele werden hier für alle DBMS gepflegt.

## Versionen und Konfigurationsordner

Ein Versionsordner steht für eine bestimmte Konfiguration und deren Einrichtung. Sein Name allein ist keine Aussage darüber, dass alle Versionen dieser Reihe geprüft wurden.

- **Neuer Ordner bei versionsabhängigen Änderungen:** Benötigt eine Version andere Optionen, TLS-/Authentifizierungseinstellungen, Datenpfade, Init-Skripte, Client-Aufrufe oder eine andere Startfolge, wird ab dieser Version ein eigener `Version_*`-Ordner angelegt. Die bisherige Variante und ihre Versionszuordnung bleiben erhalten. Das gilt auch für Änderungen innerhalb derselben Patch- oder Minor-Reihe.
- **Gleicher Ordner bei unveränderter Vorlage:** Bleiben Konfiguration und Einrichtung gleich, wird die vorhandene Vorlage verwendet. Die Datenbank-README nennt ausdrücklich die zugeordneten Versionen oder einen belegten Versionsbereich und die konkret getesteten Versionen. Für einen bloßen Image-Versionswechsel ist kein zusätzlicher Ordner nötig.
- **Vorlagenbasis und Gültigkeit trennen:** Beispielsweise bleibt `Version_18.6` die Ordnerbezeichnung einer mit 18.6 eingeführten Vorlage, wenn sie unverändert auch mit 18.7 geprüft wurde. Die README nennt dann beide Versionen und den aktuellen Image-Standard. Eine pauschale Angabe wie „ab 18.6“ wird auf den geprüften Bereich begrenzt; künftige Patchstände und andere Hauptversionen sind nicht automatisch freigegeben.
- **Prüfstand angeben:** Linux-Compose, native Windows-Installation und native Cluster getrennt ausweisen. Einen Image-Tag ohne festgelegte Patchversion als solchen kennzeichnen. Ein erfolgreicher Test mit einem beweglichen Tag belegt keine Kompatibilität mit allen Versionen, auf die dieser Tag später zeigt.
- **Upgrades separat bewerten:** Kompatibilität einer Neuinstallation bestätigt noch kein Upgrade bestehender Daten. Herstellerhinweise, nötige Zwischenschritte sowie Backup und Restore gehören in die jeweilige Anleitung. Bei einer neuen Zuordnung auch Einstiegstabellen und beide Sprachfassungen aktualisieren.

Die Versionszuordnung in der jeweiligen Datenbank-README ist maßgeblich. Die gemeinsamen BSI-Ziele und Freigabekriterien gelten für jede neue oder weiterverwendete Variante.

## Datenbankordner

- [MariaDB](MariaDB/README-de.md)
- [MongoDB](MongoDB/README-de.md)
- [MySQL](MySQL/README-de.md)
- [PostgreSQL](PostgreSQL/README-de.md)
- [Redis](Redis/README-de.md)
- [Weaviate](Weaviate/README-de.md)

© 2026 - Sichere Datenbankkonfigurationen
