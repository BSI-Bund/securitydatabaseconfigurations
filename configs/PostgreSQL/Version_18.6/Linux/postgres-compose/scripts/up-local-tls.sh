#!/usr/bin/env sh
set -eu

# Generates local TLS certificates when needed, starts the TLS Compose variant,
# waits for PostgreSQL to become healthy, and verifies that TLS is enforced.

COMPOSE_ENV_FILE="${COMPOSE_ENV_FILE:-.env}"
if [ ! -f "$COMPOSE_ENV_FILE" ] && [ -f ".env.example" ]; then
  COMPOSE_ENV_FILE=".env.example"
fi

POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-appdb}"
POSTGRES_TLS_TEST_USER="${POSTGRES_TLS_TEST_USER:-app_admin}"
POSTGRES_TLS_TEST_PASSWORD="${POSTGRES_TLS_TEST_PASSWORD:-${POSTGRES_APP_ADMIN_PASSWORD:-S3cur3P@ss!}}"

compose_tls() {
  docker compose --env-file "$COMPOSE_ENV_FILE" -f docker-compose.yml -f docker-compose.tls.yml "$@"
}

if [ ! -f "./ssl/server.crt" ] || [ ! -f "./ssl/server.key" ] || [ ! -f "./ssl/ca.crt" ]; then
  ./scripts/generate-local-tls.sh
fi

compose_tls up -d

for _ in $(seq 1 60); do
  pg_status="$(docker inspect "$POSTGRES_SERVICE" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' 2>/dev/null || true)"
  if [ "$pg_status" = "healthy" ]; then
    break
  fi
  if [ "$pg_status" = "exited" ] || [ "$pg_status" = "dead" ]; then
    docker logs --tail 200 "$POSTGRES_SERVICE"
    exit 1
  fi
  sleep 2
done

pg_status="$(docker inspect "$POSTGRES_SERVICE" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' 2>/dev/null || true)"
if [ "$pg_status" != "healthy" ]; then
  docker logs --tail 200 "$POSTGRES_SERVICE"
  exit 1
fi

if [ -z "$POSTGRES_TLS_TEST_PASSWORD" ]; then
  POSTGRES_TLS_TEST_PASSWORD="$(compose_tls exec -T "$POSTGRES_SERVICE" printenv POSTGRES_APP_ADMIN_PASSWORD 2>/dev/null || true)"
fi

if [ -z "$POSTGRES_TLS_TEST_PASSWORD" ]; then
  echo "POSTGRES_TLS_TEST_PASSWORD is not available; set POSTGRES_APP_ADMIN_PASSWORD or provide COMPOSE_ENV_FILE." >&2
  exit 1
fi

compose_tls exec -T -e PGPASSWORD="$POSTGRES_TLS_TEST_PASSWORD" "$POSTGRES_SERVICE" \
  psql "host=127.0.0.1 port=5432 dbname=$POSTGRES_DB user=$POSTGRES_TLS_TEST_USER sslmode=verify-full sslrootcert=/etc/postgresql/ssl/ca.crt" \
  -v ON_ERROR_STOP=1 \
  -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();"

if compose_tls exec -T -e PGPASSWORD="$POSTGRES_TLS_TEST_PASSWORD" "$POSTGRES_SERVICE" \
  psql "host=127.0.0.1 port=5432 dbname=$POSTGRES_DB user=$POSTGRES_TLS_TEST_USER sslmode=disable" \
  -v ON_ERROR_STOP=1 \
  -c "SELECT 1;" >/dev/null 2>&1; then
  echo "ERROR: non-TLS connection succeeded, but TLS mode should reject it." >&2
  exit 1
fi

echo "PostgreSQL TLS stack is healthy and rejects non-TLS TCP connections."
