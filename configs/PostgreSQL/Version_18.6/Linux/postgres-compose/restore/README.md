# Restore staging directory

[Deutsch](README-de.md) · [Linux guide](../../README.md)

This optional directory can hold temporary restore files. `scripts/restore.sh` accepts the dump path as an argument and does not automatically use this directory.

Do not commit restore material. Verify checksums and test restores in a separate environment. The restore helper overwrites the selected database and requires `CONFIRM_RESTORE` to match its name.
