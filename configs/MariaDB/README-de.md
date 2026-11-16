# MariaDB – Konfigurationen

[English](README.md)

## Version und Betriebsmodelle

Vorlagenbasis: **11.8**, Ordner [`Version_11`](Version_11/).

- [Linux mit Docker Compose](Version_11/Linux/README-de.md)
- [Windows nativ](Version_11/Windows/README-de.md)

## Versionsgültigkeit und Prüfstand

Der Ordner `Version_11` enthält aktuell die Vorlage für die 11.8-Reihe. Daraus folgt keine Freigabe für sämtliche MariaDB-11-Versionen.

| Plattform / Variante | Versionszuordnung | Prüfstand am 16.11.2026 |
|---|---|---|
| Linux mit Compose | 11.8.3 | Image-Standard `mariadb:11.8.3`; laufzeitgeprüft. |
| Windows nativ | 11.8 | Konfiguration statisch geprüft; kein nativer Laufzeittest. |

Neue Zuordnungen und abweichende Vorlagen folgen der [gemeinsamen Versionsregel](../README-de.md#versionen-und-konfigurationsordner).

## BSI-Alignment

Für **MariaDB** gilt das [gemeinsame BSI-Alignment für alle Datenbankvorlagen](../README-de.md#bsi-alignment). Die [zentrale Umsetzungsübersicht](../README-de.md#umsetzung-je-datenbank) und die oben verlinkten Anleitungen beschreiben vorhandene Maßnahmen und noch erforderliche Schritte. Datenbankspezifische Hinweise ergänzen die gemeinsame Checkliste.

© 2026 – Sichere Datenbankkonfigurationen
