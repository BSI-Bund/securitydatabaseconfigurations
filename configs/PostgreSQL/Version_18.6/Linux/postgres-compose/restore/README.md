# Restore staging directory

[Deutsch](README-de.md) · [Linux guide](../../README.md)

This optional directory can hold supplied backups. `scripts/restore.sh` accepts a backup directory or dump path. Its private validation copy is created under `TMPDIR` or `/tmp`; this directory is not used for that automatically.

Do not commit restore material. The helper checks the dump checksum, complete readability, and database name before overwriting. The matching checksum file is required; `CONFIRM_RESTORE` must match the database name in the archive. Test restoration, including database privileges, in a separate environment.
