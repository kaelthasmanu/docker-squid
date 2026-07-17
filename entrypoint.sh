#!/usr/bin/env sh
set -e

SQUID_USER=${SQUID_USER:-proxy}
SQUID_GROUP=${SQUID_GROUP:-proxy}
LOG_DIR=${LOG_DIR:-/var/log/squid}
SPOOL_DIR=${SPOOL_DIR:-/var/spool/squid}
RUN_DIR=${RUN_DIR:-/var/run/squid}

mkdir -p "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

chown -R "$SQUID_USER:$SQUID_GROUP" "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

echo "Inicializando cache..."
squid -z -f /etc/squid/squid.conf || true
chown -R "$SQUID_USER:$SQUID_GROUP" "$SPOOL_DIR"

rm -f /var/run/squid.pid /run/squid.pid "$RUN_DIR/squid.pid" || true

exec squid -N -d1 -f /etc/squid/squid.conf

