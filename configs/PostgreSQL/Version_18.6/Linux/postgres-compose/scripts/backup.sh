#!/usr/bin/env sh
set -eu
umask 077

# Creates a logical backup of the configured PostgreSQL database plus global
# objects such as roles. For point-in-time recovery, add WAL archiving.

BACKUP_DIR="${BACKUP_DIR:-./backups}"
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
if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "POSTGRES_PASSWORD is not available; set POSTGRES_PASSWORD or provide COMPOSE_ENV_FILE." >&2
  exit 1
fi

case "$POSTGRES_DB" in
  *[!A-Za-z0-9_]*|'')
    echo "POSTGRES_DB must contain only letters, digits and underscores." >&2
    exit 1
    ;;
esac

if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
  echo "sha256sum or shasum is required." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
# mktemp reserves a unique private directory, even for concurrent runs.
BACKUP_PATH="$(mktemp -d "$BACKUP_DIR/${POSTGRES_DB}-${TIMESTAMP}.XXXXXX")"
BACKUP_COMPLETE=0
cleanup() {
  if [ "$BACKUP_COMPLETE" -ne 1 ]; then
    rm -rf "$BACKUP_PATH"
  fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

DB_BACKUP="$BACKUP_PATH/database.dump"
GLOBALS_BACKUP="$BACKUP_PATH/globals.sql"
CHECKSUMS="$BACKUP_PATH/SHA256SUMS"

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --create --verbose \
  > "$DB_BACKUP"

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  pg_dumpall -U "$POSTGRES_USER" --globals-only \
  > "$GLOBALS_BACKUP"

(
  cd "$BACKUP_PATH"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum database.dump globals.sql > SHA256SUMS.tmp
  else
    shasum -a 256 database.dump globals.sql > SHA256SUMS.tmp
  fi
  # Publish the manifest only after both backup files have completed.
  mv SHA256SUMS.tmp SHA256SUMS
)
BACKUP_COMPLETE=1

echo "Backup written:"
echo "  $DB_BACKUP"
echo "  $GLOBALS_BACKUP"
echo "  $CHECKSUMS"
