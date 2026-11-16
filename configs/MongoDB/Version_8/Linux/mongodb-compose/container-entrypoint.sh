#!/bin/sh
set -eu

# Copy only the required TLS files to a private, in-memory directory. This
# avoids relying on host UID/GID values for bind-mounted private keys.
for file in test-ca.pem test-server1.pem; do
    if [ ! -s "/run/tls-source/$file" ]; then
        echo "Missing TLS file: ssl/$file. See the TLS preparation in the README." >&2
        exit 1
    fi
done
mkdir -p /etc/ssl/mongodb /var/log/mongodb
cp "/run/tls-source/test-ca.pem" "/etc/ssl/mongodb/test-ca.pem"
cp "/run/tls-source/test-server1.pem" "/etc/ssl/mongodb/test-server1.pem"
chown mongodb:mongodb /etc/ssl/mongodb /etc/ssl/mongodb/*.pem /var/log/mongodb
chmod 0700 /etc/ssl/mongodb /var/log/mongodb
chmod 0600 /etc/ssl/mongodb/*.pem

# Keep the official image's initialization and privilege drop.
exec /usr/local/bin/docker-entrypoint.sh "$@"
