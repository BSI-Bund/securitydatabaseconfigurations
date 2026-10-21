#!/usr/bin/env sh
set -eu

# Generates a local development CA and PostgreSQL server certificate.
# Replace these certificates with your organization's CA-issued certificates
# before production use.

SSL_DIR="${SSL_DIR:-./ssl}"
POSTGRES_VERSION="${POSTGRES_VERSION:-18.6}"
DAYS="${DAYS:-365}"

mkdir -p "$SSL_DIR"
SSL_DIR_ABS="$(cd "$SSL_DIR" && pwd)"

openssl req -x509 -newkey rsa:4096 -sha256 -days "$DAYS" -nodes \
  -keyout "$SSL_DIR/ca.key" \
  -out "$SSL_DIR/ca.crt" \
  -subj "/CN=Local PostgreSQL Dev CA"

openssl req -newkey rsa:4096 -nodes \
  -keyout "$SSL_DIR/server.key" \
  -out "$SSL_DIR/server.csr" \
  -subj "/CN=postgres"

EXT_FILE="$(mktemp)"
trap 'rm -f "$EXT_FILE" "$SSL_DIR/server.csr"' EXIT

cat > "$EXT_FILE" <<'EOF'
subjectAltName = DNS:postgres,DNS:localhost,IP:127.0.0.1
extendedKeyUsage = serverAuth
EOF

openssl x509 -req \
  -in "$SSL_DIR/server.csr" \
  -CA "$SSL_DIR/ca.crt" \
  -CAkey "$SSL_DIR/ca.key" \
  -CAcreateserial \
  -out "$SSL_DIR/server.crt" \
  -days "$DAYS" \
  -sha256 \
  -extfile "$EXT_FILE"

chmod 600 "$SSL_DIR/server.key" "$SSL_DIR/ca.key"
chmod 644 "$SSL_DIR/server.crt" "$SSL_DIR/ca.crt"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  if ! docker run --rm \
    -v "$SSL_DIR_ABS:/ssl" \
    --entrypoint sh \
    "postgres:$POSTGRES_VERSION" \
    -c 'chown postgres:postgres /ssl/server.key /ssl/server.crt /ssl/ca.crt && chmod 600 /ssl/server.key && chmod 644 /ssl/server.crt /ssl/ca.crt'; then
    echo "Could not adjust ownership through Docker; verify server.key permissions before starting TLS mode."
  fi
else
  echo "Docker is not reachable; verify server.key ownership for the postgres user before starting TLS mode."
fi

echo "Local TLS files written to $SSL_DIR."
echo "Use ca.crt on clients and require sslmode=verify-full where hostname validation is possible."
