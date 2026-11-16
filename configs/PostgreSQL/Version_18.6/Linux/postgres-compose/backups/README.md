# Backup directory

[Deutsch](README-de.md) · [Linux guide](../../README.md)

Each `scripts/backup.sh` run creates its own `appdb-<UTC-timestamp>.<random-id>` directory here with mode `0700`. It contains `database.dump`, `globals.sql`, and, after successful completion, `SHA256SUMS`; files have mode `0600`. Failed runs remove their incomplete directory. `BACKUP_DIR` changes the parent destination.

Do not commit backup files. Restrict access, encrypt and copy backups to external storage, and test restores. The script creates a database dump, global-object SQL, and checksums; it does not schedule backups, encrypt files, or automatically restore global objects.
