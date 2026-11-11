# Backup directory

[Deutsch](README-de.md) · [Linux guide](../../README.md)

Logical backups are written here by default when `scripts/backup.sh` runs from the `postgres-compose/` directory. The `BACKUP_DIR` variable can change the destination.

Do not commit backup files. Restrict access, encrypt and copy backups to external storage, and test restores. The script creates a database dump, global-object SQL, and checksums; it does not schedule backups, encrypt files, or automatically restore global objects.
