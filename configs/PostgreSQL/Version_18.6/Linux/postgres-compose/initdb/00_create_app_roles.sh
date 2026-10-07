#!/usr/bin/env sh
set -eu

# Create login roles before init.sql grants database and schema privileges.
# Passwords come from the Compose environment so they are not hard-coded in SQL.

: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_APP_ADMIN_PASSWORD:?POSTGRES_APP_ADMIN_PASSWORD is required}"
: "${POSTGRES_APP_READER_PASSWORD:?POSTGRES_APP_READER_PASSWORD is required}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v app_admin_password="$POSTGRES_APP_ADMIN_PASSWORD" \
  -v app_reader_password="$POSTGRES_APP_READER_PASSWORD" <<'SQL'
SELECT format(
  'CREATE ROLE app_admin LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION',
  :'app_admin_password'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'app_admin'
)\gexec

SELECT format(
  'CREATE ROLE app_reader LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION',
  :'app_reader_password'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'app_reader'
)\gexec

ALTER ROLE app_admin
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
ALTER ROLE app_reader
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
SQL
