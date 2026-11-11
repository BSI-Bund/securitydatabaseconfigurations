# TLS-Zertifikatsverzeichnis

[English](README.md) · [Linux-Anleitung](../../README-de.md)

Der TLS-Override erwartet hier `ca.crt`, `server.crt` und `server.key`. Für einen lokalen Test im Verzeichnis `postgres-compose/` den Befehl `./scripts/generate-local-tls.sh` ausführen.

Erzeugte Dateien und private Schlüssel nicht einchecken. Für andere Umgebungen Zertifikate der eigenen CA verwenden und Zugriff auf `server.key` beschränken. Zertifikatserstellung allein aktiviert den TLS-Compose-Override noch nicht.
