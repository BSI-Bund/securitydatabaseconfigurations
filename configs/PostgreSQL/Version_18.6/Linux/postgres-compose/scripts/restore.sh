#!/usr/bin/env sh
set -eu
umask 077

# Restores a logical backup created by backup.sh.
# Run only against the intended target environment.

POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
COMPOSE_ENV_FILE="${COMPOSE_ENV_FILE:-.env}"
if [ ! -f "$COMPOSE_ENV_FILE" ] && [ -f ".env.example" ]; then
  COMPOSE_ENV_FILE=".env.example"
fi
compose() {
  docker compose --env-file "$COMPOSE_ENV_FILE" "$@"
}

POSTGRES_USER="${POSTGRES_USER:-$(compose exec -T "$POSTGRES_SERVICE" printenv POSTGRES_USER 2>/dev/null || printf '%s' postgres)}"
POSTGRES_DB="${POSTGRES_DB:-$(compose exec -T "$POSTGRES_SERVICE" printenv POSTGRES_DB 2>/dev/null || printf '%s' appdb)}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(compose exec -T "$POSTGRES_SERVICE" printenv POSTGRES_PASSWORD 2>/dev/null || true)}"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 path/to/backup-directory-or-dump" >&2
  exit 1
fi

BACKUP_FILE="$1"
if [ -d "$BACKUP_FILE" ]; then
  BACKUP_FILE="$BACKUP_FILE/database.dump"
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE" >&2
  exit 1
fi

case "$POSTGRES_DB" in
  *[!A-Za-z0-9_]*|''|postgres|template0|template1)
    echo "Unsafe POSTGRES_DB value: $POSTGRES_DB" >&2
    exit 1
    ;;
esac

if [ "${CONFIRM_RESTORE:-}" != "$POSTGRES_DB" ]; then
  echo "Refusing destructive restore." >&2
  echo "Set CONFIRM_RESTORE=$POSTGRES_DB and rerun to confirm the target database." >&2
  exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "POSTGRES_PASSWORD is not available; set POSTGRES_PASSWORD or provide COMPOSE_ENV_FILE." >&2
  exit 1
fi

# A bundle's manifest also marks the backup as complete. Older flat backups
# remain usable when their original matching checksum manifest is present.
BACKUP_PARENT="$(cd "$(dirname "$BACKUP_FILE")" && pwd)"
BACKUP_NAME="$(basename "$BACKUP_FILE")"
case "$BACKUP_NAME" in
  database.dump)
    CHECKSUM_FILE="$BACKUP_PARENT/SHA256SUMS"
    ;;
  "$POSTGRES_DB"-*.dump)
    BACKUP_STAMP="${BACKUP_NAME#"$POSTGRES_DB"-}"
    BACKUP_STAMP="${BACKUP_STAMP%.dump}"
    CHECKSUM_FILE="$BACKUP_PARENT/SHA256SUMS-$BACKUP_STAMP.txt"
    ;;
  *)
    echo "Unrecognized backup filename. Use a backup directory produced by backup.sh." >&2
    exit 1
    ;;
esac

if [ ! -f "$CHECKSUM_FILE" ]; then
  echo "Missing checksum manifest: $CHECKSUM_FILE" >&2
  exit 1
fi
EXPECTED_SHA="$(awk -v name="$BACKUP_NAME" '$2 == name { print $1; count++ } END { if (count != 1) exit 1 }' "$CHECKSUM_FILE")" || {
  echo "The checksum manifest must contain exactly one entry for the dump." >&2
  exit 1
}
if ! printf '%s\n' "$EXPECTED_SHA" | grep -Eq '^[[:xdigit:]]{64}$'; then
  echo "Invalid SHA-256 checksum in manifest." >&2
  exit 1
fi
EXPECTED_SHA="$(printf '%s' "$EXPECTED_SHA" | tr A-F a-f)"

VALIDATION_DIR="$(mktemp -d "${TMPDIR:-/tmp}/db-restore.XXXXXX")"
trap 'rm -rf "$VALIDATION_DIR"' EXIT
trap 'exit 1' HUP INT TERM
# Restore the same private snapshot that was checked, even if the source file
# changes while validation or restore is running.
ARCHIVE="$VALIDATION_DIR/database.dump"
cp "$BACKUP_FILE" "$ARCHIVE"
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL_SHA="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  ACTUAL_SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
else
  echo "sha256sum or shasum is required." >&2
  exit 1
fi
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  echo "Dump checksum mismatch; the target database has not been changed." >&2
  exit 1
fi

compose exec -T -e LC_ALL=C "$POSTGRES_SERVICE" \
  pg_restore --create --list < "$ARCHIVE" > "$VALIDATION_DIR/contents.txt"
ARCHIVE_DB="$(sed -n 's/^;[[:space:]]*dbname: //p' "$VALIDATION_DIR/contents.txt")"
if [ "$ARCHIVE_DB" != "$POSTGRES_DB" ]; then
  echo "Archive database '$ARCHIVE_DB' does not match confirmed target '$POSTGRES_DB'." >&2
  exit 1
fi
if ! grep -Eq '[[:space:]]DATABASE[[:space:]]+-[[:space:]]' "$VALIDATION_DIR/contents.txt"; then
  echo "The archive does not contain the database definition needed for a full restore." >&2
  exit 1
fi
# Listing alone does not read compressed table data. Decode the complete
# archive without executing SQL before touching the target database.
compose exec -T "$POSTGRES_SERVICE" \
  pg_restore --create --exit-on-error --file=/dev/null < "$ARCHIVE"

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${POSTGRES_DB}' AND pid <> pg_backend_pid();"

# --create restores database ownership, ACLs and database-specific settings.
# The archive's database name was checked above because --create uses it.
compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  pg_restore -U "$POSTGRES_USER" -d postgres --create --clean --if-exists --exit-on-error --verbose \
  < "$ARCHIVE"

echo "Restore completed for database $POSTGRES_DB from $BACKUP_FILE."
