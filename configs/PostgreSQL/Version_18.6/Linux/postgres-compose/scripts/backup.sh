#!/usr/bin/env sh
set -eu

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
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$BACKUP_DIR"

DB_BACKUP="$BACKUP_DIR/${POSTGRES_DB}-${TIMESTAMP}.dump"
GLOBALS_BACKUP="$BACKUP_DIR/globals-${TIMESTAMP}.sql"
CHECKSUMS="$BACKUP_DIR/SHA256SUMS-${TIMESTAMP}.txt"

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "POSTGRES_PASSWORD is not available; set POSTGRES_PASSWORD or provide COMPOSE_ENV_FILE." >&2
  exit 1
fi

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --verbose \
  > "$DB_BACKUP"

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  pg_dumpall -U "$POSTGRES_USER" --globals-only \
  > "$GLOBALS_BACKUP"

(
  cd "$BACKUP_DIR"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$(basename "$DB_BACKUP")" "$(basename "$GLOBALS_BACKUP")" > "$(basename "$CHECKSUMS")"
  else
    shasum -a 256 "$(basename "$DB_BACKUP")" "$(basename "$GLOBALS_BACKUP")" > "$(basename "$CHECKSUMS")"
  fi
)

echo "Backup written:"
echo "  $DB_BACKUP"
echo "  $GLOBALS_BACKUP"
echo "  $CHECKSUMS"
