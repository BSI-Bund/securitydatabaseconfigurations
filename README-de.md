# Sichere Datenbankkonfigurationen

[English](README.md)

Dieses Repository enthält Konfigurationsvorlagen und Betriebsanleitungen für MariaDB, MongoDB, MySQL, PostgreSQL, Redis Enterprise und Weaviate. Es dient als Ausgangspunkt für die Härtung eigener Datenbankumgebungen. Welche Maßnahmen eine Vorlage bereits umsetzt und welche Vorbereitung nötig ist, steht in der jeweiligen Anleitung.

- [Einstieg](#einstieg)
- [BSI-Alignment](#bsi-alignment)
- [Verfügbare Datenbanken und Betriebsmodelle](#verfügbare-datenbanken-und-betriebsmodelle)
- [Aufbau der Dokumentation](#aufbau-der-dokumentation)
- [Sicherheitsziele und Betriebsaufgaben](#sicherheitsziele-und-betriebsaufgaben)
- [TLS und Zertifikate](#tls-und-zertifikate)

## Einstieg

1. In der folgenden Tabelle ein DBMS und dessen Anleitung auswählen.
2. Die plattformspezifische README vollständig lesen. Sie nennt Voraussetzungen, Dateien, Arbeitsverzeichnis und Startfolge.
3. Konfiguration, Beispiel-Secrets, Netzfreigaben und Speicherpfade an die Zielumgebung anpassen. Bei Compose-Setups `.env.example` im angegebenen Verzeichnis nach `.env` kopieren.
4. Zertifikate und benötigte Verzeichnisse vor dem Start bereitstellen, soweit die Anleitung dies verlangt.
5. Nach dem Start die wirksame Konfiguration, Anmeldung, TLS und Protokollierung prüfen sowie Backup und Wiederherstellung testen.

Die Anleitungen richten sich an Administrator:innen und Entwickler:innen mit Kenntnissen des jeweiligen DBMS. Docker Compose wird nur für die ausdrücklich genannten Container-Setups benötigt.

## BSI-Alignment

**Das BSI-Alignment gilt für alle Datenbankvorlagen dieses Repositories: MariaDB, MongoDB, MySQL, PostgreSQL, Redis Enterprise und Weaviate.** Die [gemeinsame Konfigurationsübersicht](configs/README-de.md#bsi-alignment) enthält die BSI-Referenzen, die gemeinsame Checkliste und die Umsetzung je DBMS. Datenbankspezifische Ergänzungen konkretisieren diesen gemeinsamen Rahmen.

## Verfügbare Datenbanken und Betriebsmodelle

Die Versionsangaben beschreiben den Stand der Vorlagen, nicht die jeweils neueste Herstellerfreigabe.

| Datenbank | Konfigurationsstand | Enthaltene Betriebsmodelle | Einstieg |
|-----------|---------------------|---------------------------|----------|
| MariaDB | 11.8 | Linux mit Docker Compose; native Windows-Installation | [MariaDB](configs/MariaDB/README-de.md) |
| MongoDB | 8.x | Linux mit Docker Compose; native Windows-Installation | [MongoDB](configs/MongoDB/README-de.md) |
| MySQL Community Server | 8.4.6 | Linux mit Docker Compose; native Windows-Installation | [MySQL](configs/MySQL/README-de.md) |
| PostgreSQL | 18.6 | Linux mit Docker Compose; native Windows-Installation | [PostgreSQL](configs/PostgreSQL/README-de.md) |
| Redis Enterprise | 8.0.x | Native Linux-Installation als Cluster | [Redis Enterprise](configs/Redis/README-de.md) |
| Weaviate | 1.34.0 | Docker Compose; zusätzlich eigenständige Variante mit Traefik | [Weaviate](configs/Weaviate/README-de.md) |

## Aufbau der Dokumentation

```text
README-de.md                  Projektüberblick und Einstieg
configs/
├── README-de.md              Gemeinsames BSI-Alignment und Datenbankübersicht
└── <DBMS>/
    ├── README-de.md          Versionen und Links zu den enthaltenen Setups
    └── Version_*/            DBMS-spezifische Dateien und Anleitungen
```

MariaDB, MongoDB, MySQL und PostgreSQL haben unterhalb der Version getrennte Ordner für `Linux/` und `Windows/`. Redis enthält eine Linux-Anleitung für Redis Enterprise. Bei Weaviate liegen die Compose-Dateien direkt im Versionsordner; die Traefik-Variante liegt in `reverse-proxy-traefik/`.

Jede deutsche Anleitung hat eine englische Fassung ohne `-de` im Dateinamen. Die Dateinamen und Verzeichnisstrukturen unterscheiden sich je DBMS; die jeweilige README verlinkt die vorhandenen Dateien.

## Sicherheitsziele und Betriebsaufgaben

Gemeinsame Ziele sind verschlüsselte Verbindungen, begrenzte Netzwerkzugriffe, getrennte Administrations- und Anwendungskonten, minimale Rechte, nachvollziehbare Protokolle und wiederherstellbare Backups. Der Umsetzungsstand unterscheidet sich zwischen den Vorlagen.

Beispiel-Secrets sind vor Verwendung zu ersetzen. Patch-Management, Schutz von Host und Dateien, Überwachung, Aufbewahrung und Verschlüsselung von Backups sowie regelmäßige Restore-Tests müssen für die eigene Umgebung eingerichtet werden. Ein persistentes Docker-Volume oder aktivierte Replikation ersetzt kein Backup.

## TLS und Zertifikate

Die separate [TLS-Anleitung](docs/TLS-de.md) beschreibt die Erstellung und Prüfung von CA-, Server- und Client-Zertifikaten mit OpenSSL. Die jeweilige DBMS-Anleitung erklärt Dateiformat, Pfade, Einbindung und Client-Verbindung. Ein erzeugtes Zertifikat allein aktiviert TLS noch nicht.

© 2026 – Sichere Datenbankkonfigurationen
