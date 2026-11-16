# TLS-Zertifikatsverzeichnis

[English](README.md) · [Linux-Anleitung](../../README-de.md)

Der TLS-Override erwartet hier `ca.crt`, `server.crt` und `server.key`. Für einen lokalen Test im Verzeichnis `postgres-compose/` den Befehl `./scripts/generate-local-tls.sh` ausführen.

Der Generator hält die private CA außerhalb des Repositorys unter `${XDG_DATA_HOME:-$HOME/.local/share}/db-sec-conf/postgresql-dev-ca` oder im ausdrücklich gesetzten `CA_DIR`. Dieses Verzeichnis darf nicht innerhalb von `ssl/` liegen. Der Override bindet ausschließlich die drei benötigten Dateien ein; Adminer erhält nur das öffentliche CA-Zertifikat.

Erzeugte Dateien und private Schlüssel nicht einchecken. Für andere Umgebungen Zertifikate der eigenen CA verwenden und Zugriff auf `server.key` beschränken. Zertifikatserstellung allein aktiviert den TLS-Compose-Override noch nicht.
