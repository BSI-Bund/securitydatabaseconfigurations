# MySQL Community Server – Konfigurationen

[English](README.md)

## Version und Betriebsmodelle

Vorlagenbasis: **8.4.6**, Ordner [`Version_8.4.6`](Version_8.4.6/).

- [Linux mit Docker Compose](Version_8.4.6/Linux/README-de.md)
- [Windows nativ](Version_8.4.6/Windows/README-de.md)

## Versionsgültigkeit und Prüfstand

Vorlagenbasis ist 8.4.6. Die folgende Zuordnung gilt für diesen Ordner; sie bedeutet keine Freigabe anderer MySQL-8.4-Patchstände oder neuer Hauptversionen.

| Plattform / Variante | Versionszuordnung | Prüfstand am 16.11.2026 |
|---|---|---|
| Linux mit Compose | 8.4.6 und 8.4.13 | Beide Versionen mit unveränderter Vorlage laufzeitgeprüft; Image-Standard `mysql:8.4.13`, wählbar über `MYSQL_VERSION`. |
| Windows nativ | 8.4.6 | Konfiguration statisch geprüft; kein nativer Laufzeittest. |

Neue Zuordnungen und abweichende Vorlagen folgen der [gemeinsamen Versionsregel](../README-de.md#versionen-und-konfigurationsordner).

## BSI-Alignment

Für **MySQL** gilt das [gemeinsame BSI-Alignment für alle Datenbankvorlagen](../README-de.md#bsi-alignment). Die [zentrale Umsetzungsübersicht](../README-de.md#umsetzung-je-datenbank) und die oben verlinkten Anleitungen beschreiben vorhandene Maßnahmen und noch erforderliche Schritte. Datenbankspezifische Hinweise ergänzen die gemeinsame Checkliste.

© 2026 – Sichere Datenbankkonfigurationen
