# PostgreSQL – Konfigurationen

[English](README.md)

## Version und Betriebsmodelle

Vorlagenbasis: **18.6**, Ordner [`Version_18.6`](Version_18.6/).

- [Linux mit Docker Compose](Version_18.6/Linux/README-de.md)
- [Windows nativ](Version_18.6/Windows/README-de.md)

## Versionsgültigkeit und Prüfstand

Vorlagenbasis ist 18.6. Die folgende Zuordnung gilt für diesen Ordner; weitere PostgreSQL-18-Patchstände oder neue Hauptversionen sind dadurch nicht automatisch freigegeben.

| Plattform / Variante | Versionszuordnung | Prüfstand am 16.11.2026 |
|---|---|---|
| Linux mit Compose | 18.6 und 18.7 | Basis- und TLS-Variante, Adminer, Rollen sowie Backup/Restore mit beiden Versionen laufzeitgeprüft; Image-Standard `postgres:18.7`. |
| Windows nativ | 18.6 | Konfiguration statisch geprüft; kein nativer Laufzeittest. |

Neue Zuordnungen und abweichende Vorlagen folgen der [gemeinsamen Versionsregel](../README-de.md#versionen-und-konfigurationsordner).

## BSI-Alignment

Für **PostgreSQL** gilt das [gemeinsame BSI-Alignment für alle Datenbankvorlagen](../README-de.md#bsi-alignment). Die [zentrale Umsetzungsübersicht](../README-de.md#umsetzung-je-datenbank) und die oben verlinkten Anleitungen beschreiben vorhandene Maßnahmen und noch erforderliche Schritte. Datenbankspezifische Hinweise ergänzen die gemeinsame Checkliste.

© 2026 – Sichere Datenbankkonfigurationen
