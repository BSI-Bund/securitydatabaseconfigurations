# Backup-Verzeichnis

[English](README.md) · [Linux-Anleitung](../../README-de.md)

Jeder Lauf von `scripts/backup.sh` erzeugt hier ein eigenes Verzeichnis `appdb-<UTC-Zeitstempel>.<Zufallskennung>` mit Modus `0700`. Es enthält `database.dump`, `globals.sql` und nach erfolgreichem Abschluss `SHA256SUMS`; die Dateien erhalten Modus `0600`. Fehlgeschlagene Läufe entfernen ihr unvollständiges Verzeichnis. `BACKUP_DIR` kann das übergeordnete Ziel ändern.

Backup-Dateien nicht einchecken. Zugriff beschränken, Backups verschlüsseln und extern ablegen sowie Restore testen. Das Skript erstellt Datenbank-Dump, SQL für globale Objekte und Checksums; es richtet weder Zeitplanung noch Verschlüsselung ein und stellt globale Objekte nicht automatisch wieder her.
