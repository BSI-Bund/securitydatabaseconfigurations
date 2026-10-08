#!/usr/bin/env sh
set -eu

# Stops the PostgreSQL Compose stack. Set REMOVE_VOLUMES=1 to delete data too.

COMPOSE_ENV_FILE="${COMPOSE_ENV_FILE:-.env}"
if [ ! -f "$COMPOSE_ENV_FILE" ] && [ -f ".env.example" ]; then
  COMPOSE_ENV_FILE=".env.example"
fi

compose_files="-f docker-compose.yml"
if [ "${TLS:-0}" = "1" ]; then
  compose_files="$compose_files -f docker-compose.tls.yml"
fi

if [ "${REMOVE_VOLUMES:-0}" = "1" ]; then
  docker compose --env-file "$COMPOSE_ENV_FILE" $compose_files down -v --remove-orphans
else
  docker compose --env-file "$COMPOSE_ENV_FILE" $compose_files down --remove-orphans
fi
