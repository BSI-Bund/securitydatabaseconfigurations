#!/usr/bin/env sh
set -eu
umask 077

# Generates a local development CA and PostgreSQL server certificate.
# Replace these certificates with your organization's CA-issued certificates
# before production use.

SSL_DIR="${SSL_DIR:-./ssl}"
CA_DIR="${CA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/db-sec-conf/postgresql-dev-ca}"
POSTGRES_VERSION="${POSTGRES_VERSION:-18.7}"
DAYS="${DAYS:-365}"

mkdir -p "$SSL_DIR" "$CA_DIR"
SSL_DIR_ABS="$(cd "$SSL_DIR" && pwd)"
CA_DIR_ABS="$(cd "$CA_DIR" && pwd)"
case "$CA_DIR_ABS/" in
  "$SSL_DIR_ABS/"*)
    echo "CA_DIR must be outside SSL_DIR; never deploy the private CA key." >&2
    exit 1
    ;;
esac
chmod 700 "$CA_DIR"

if [ ! -e "$CA_DIR/ca.key" ] && [ ! -e "$CA_DIR/ca.crt" ]; then
  openssl req -x509 -newkey rsa:4096 -sha256 -days "$DAYS" -nodes \
    -keyout "$CA_DIR/ca.key" \
    -out "$CA_DIR/ca.crt" \
    -subj "/CN=Local PostgreSQL Dev CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"
elif [ ! -f "$CA_DIR/ca.key" ] || [ ! -f "$CA_DIR/ca.crt" ]; then
  echo "CA_DIR must contain both ca.key and ca.crt, or neither." >&2
  exit 1
fi
chmod 600 "$CA_DIR/ca.key"
cp "$CA_DIR/ca.crt" "$SSL_DIR/ca.crt"

openssl req -newkey rsa:4096 -nodes \
  -keyout "$SSL_DIR/server.key" \
  -out "$SSL_DIR/server.csr" \
  -subj "/CN=postgres"

EXT_FILE="$(mktemp)"
trap 'rm -f "$EXT_FILE" "$SSL_DIR/server.csr"' EXIT

cat > "$EXT_FILE" <<'EOF'
subjectAltName = DNS:postgres,DNS:localhost,IP:127.0.0.1
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
EOF

openssl x509 -req \
  -in "$SSL_DIR/server.csr" \
  -CA "$CA_DIR/ca.crt" \
  -CAkey "$CA_DIR/ca.key" \
  -CAcreateserial \
  -out "$SSL_DIR/server.crt" \
  -days "$DAYS" \
  -sha256 \
  -extfile "$EXT_FILE"

chmod 600 "$SSL_DIR/server.key"
chmod 644 "$SSL_DIR/server.crt" "$SSL_DIR/ca.crt"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  if ! docker run --rm \
    -v "$SSL_DIR_ABS/server.key:/ssl/server.key" \
    -v "$SSL_DIR_ABS/server.crt:/ssl/server.crt" \
    -v "$SSL_DIR_ABS/ca.crt:/ssl/ca.crt" \
    --entrypoint sh \
    "postgres:$POSTGRES_VERSION" \
    -c 'chown postgres:postgres /ssl/server.key /ssl/server.crt /ssl/ca.crt && chmod 600 /ssl/server.key && chmod 644 /ssl/server.crt /ssl/ca.crt'; then
    echo "Could not adjust ownership through Docker; verify server.key permissions before starting TLS mode."
  fi
else
  echo "Docker is not reachable; verify server.key ownership for the postgres user before starting TLS mode."
fi

echo "Local TLS files written to $SSL_DIR."
echo "The private development CA stays in $CA_DIR and is not mounted into services."
echo "Use ca.crt on clients and require sslmode=verify-full where hostname validation is possible."
