#!/bin/sh
set -eu

# The 8.4.6 image embeds the bootstrap root password in a quoted client option
# file. Reject unsupported escaping before it can leave a half-initialized DB.
newline='
'
carriage_return=$(printf '\r')
if [ ! -d /var/lib/mysql/mysql ]; then
    case "${MYSQL_ROOT_PASSWORD:-}" in
        *\"*|*\\*|*"$newline"*|*"$carriage_return"*)
            echo 'MYSQL_ROOT_PASSWORD must not contain double quotes, backslashes or newlines with this image. Use a long generated password.' >&2
            exit 1
            ;;
    esac
fi

# Copy only the required TLS files to a private, in-memory directory. This
# avoids relying on host UID/GID values for bind-mounted private keys.
for file in ca-cert.pem server-cert.pem server-key.pem; do
    if [ ! -s "/run/tls-source/$file" ]; then
        echo "Missing TLS file: ssl/$file. See the TLS preparation in the README." >&2
        exit 1
    fi
done
mkdir -p /etc/mysql/ssl /var/log/mysql
cp "/run/tls-source/ca-cert.pem" "/etc/mysql/ssl/ca-cert.pem"
cp "/run/tls-source/server-cert.pem" "/etc/mysql/ssl/server-cert.pem"
cp "/run/tls-source/server-key.pem" "/etc/mysql/ssl/server-key.pem"
chown mysql:mysql /etc/mysql/ssl /etc/mysql/ssl/*.pem /var/log/mysql
chmod 0700 /etc/mysql/ssl /var/log/mysql
chmod 0600 /etc/mysql/ssl/*.pem

# Keep the official image's initialization and privilege drop.
exec /usr/local/bin/docker-entrypoint.sh "$@"
