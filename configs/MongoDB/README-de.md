# MongoDB – Konfigurationen

[English](README.md)

## Version und Betriebsmodelle

Dokumentierte Zielstände: **Linux 8.3.11 / Windows 8.0**, Ordner [`Version_8`](Version_8/).

- [Linux mit Docker Compose](Version_8/Linux/README-de.md)
- [Windows nativ](Version_8/Windows/README-de.md)

Das Compose-Beispiel nutzt den beweglichen Image-Tag `mongo:8-noble`; damit ist keine bestimmte Patchversion festgeschrieben.

## Versionsgültigkeit und Prüfstand

Der Ordner `Version_8` enthält getrennte Zielstände für Linux und Windows. Die Versionsnummer im Ordner ist keine pauschale Freigabe aller MongoDB-8.x-Versionen.

| Plattform / Variante | Versionszuordnung | Prüfstand am 16.11.2026 |
|---|---|---|
| Linux mit Compose | 8.3.11 | Laufzeitprüfung mit dem lokal vorhandenen Image `mongo:8-noble`; der Tag ist beweglich. |
| Windows nativ | 8.0 | Konfiguration und Bootstrap-Schutzprüfungen geprüft; kein nativer Windows-Laufzeittest. |

Neue Zuordnungen und abweichende Vorlagen folgen der [gemeinsamen Versionsregel](../README-de.md#versionen-und-konfigurationsordner).

## BSI-Alignment

Für **MongoDB** gilt das [gemeinsame BSI-Alignment für alle Datenbankvorlagen](../README-de.md#bsi-alignment). Die [zentrale Umsetzungsübersicht](../README-de.md#umsetzung-je-datenbank) und die oben verlinkten Anleitungen beschreiben vorhandene Maßnahmen und noch erforderliche Schritte. Datenbankspezifische Hinweise ergänzen die gemeinsame Checkliste.

© 2026 – Sichere Datenbankkonfigurationen
