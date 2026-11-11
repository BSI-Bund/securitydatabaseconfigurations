# Backup-Verzeichnis

[English](README.md) · [Linux-Anleitung](../../README-de.md)

Logische Backups werden standardmäßig hier abgelegt, wenn `scripts/backup.sh` aus dem Verzeichnis `postgres-compose/` ausgeführt wird. `BACKUP_DIR` kann das Ziel ändern.

Backup-Dateien nicht einchecken. Zugriff beschränken, Backups verschlüsseln und extern ablegen sowie Restore testen. Das Skript erstellt Datenbank-Dump, SQL für globale Objekte und Checksums; es richtet weder Zeitplanung noch Verschlüsselung ein und stellt globale Objekte nicht automatisch wieder her.
