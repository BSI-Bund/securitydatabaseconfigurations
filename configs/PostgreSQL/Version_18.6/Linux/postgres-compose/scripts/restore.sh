#!/usr/bin/env sh
set -eu

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
  echo "Usage: $0 path/to/appdb-YYYYMMDDTHHMMSSZ.dump" >&2
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE" >&2
  exit 1
fi

case "$POSTGRES_DB" in
  *[!A-Za-z0-9_]*|'')
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

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  psql -U "$POSTGRES_USER" -d postgres \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${POSTGRES_DB}' AND pid <> pg_backend_pid();"

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  dropdb -U "$POSTGRES_USER" --if-exists "$POSTGRES_DB"

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  createdb -U "$POSTGRES_USER" "$POSTGRES_DB"

compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_SERVICE" \
  pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --verbose \
  < "$BACKUP_FILE"

echo "Restore completed for database $POSTGRES_DB from $BACKUP_FILE."
