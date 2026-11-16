# Weaviate – Konfigurationen

[English](README.md)

## Version und Betriebsmodelle

Vorlagenbasis: **1.34.0**, Ordner [`Version_1.34`](Version_1.34/).

- [Docker Compose, lokale HTTP-API](Version_1.34/README-de.md)
- [Docker Compose mit Traefik und TLS](Version_1.34/reverse-proxy-traefik/README-de.md)

Die beiden Varianten sind eigenständige Setups mit getrennten Daten-Volumes. Für gleichzeitigen Betrieb müssen die standardmäßig gleichen Host-Ports angepasst werden.

## Versionsgültigkeit und Prüfstand

Die Vorlage im Ordner `Version_1.34` ist für 1.34.0 geprüft. Weitere 1.34-Patchstände und andere 1.x-Versionen sind nicht automatisch eingeschlossen.

| Plattform / Variante | Versionszuordnung | Prüfstand am 16.11.2026 |
|---|---|---|
| Compose-Basisvariante | 1.34.0 | REST-Zugriff, API-Key-Authentifizierung und RBAC laufzeitgeprüft. |
| Compose mit Traefik | 1.34.0 | HTTPS-Zugang und direkte REST-/gRPC-Zugänge einschließlich Zugriffsschutz laufzeitgeprüft; keine Ollama-Modellinferenz geprüft. |

Neue Zuordnungen und abweichende Vorlagen folgen der [gemeinsamen Versionsregel](../README-de.md#versionen-und-konfigurationsordner).

## BSI-Alignment

Für **Weaviate** gilt das [gemeinsame BSI-Alignment für alle Datenbankvorlagen](../README-de.md#bsi-alignment). Die [zentrale Umsetzungsübersicht](../README-de.md#umsetzung-je-datenbank) und die oben verlinkten Anleitungen beschreiben vorhandene Maßnahmen und noch erforderliche Schritte. Datenbankspezifische Hinweise ergänzen die gemeinsame Checkliste.

© 2026 – Sichere Datenbankkonfigurationen
