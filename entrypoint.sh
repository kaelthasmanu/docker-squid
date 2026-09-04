#!/usr/bin/env sh
set -e

SQUID_USER=${SQUID_USER:-proxy}
SQUID_GROUP=${SQUID_GROUP:-proxy}
LOG_DIR=${LOG_DIR:-/var/log/squid}
SPOOL_DIR=${SPOOL_DIR:-/var/spool/squid}
RUN_DIR=${RUN_DIR:-/var/run/squid}
KEYTAB_SOURCE=${KEYTAB_SOURCE:-/etc/squid/HTTP.keytab}
KEYTAB_RUNTIME=${KEYTAB_RUNTIME:-$RUN_DIR/HTTP.keytab}
KERBEROS_DEBUG=${KERBEROS_DEBUG:-0}

mkdir -p "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

if [ ! -r "$KEYTAB_SOURCE" ]; then
	echo "ERROR: no se puede leer el keytab $KEYTAB_SOURCE" >&2
	exit 1
fi

install -o "$SQUID_USER" -g "$SQUID_GROUP" -m 640 "$KEYTAB_SOURCE" "$KEYTAB_RUNTIME"

if ! su -s /bin/sh "$SQUID_USER" -c "test -r '$KEYTAB_RUNTIME'"; then
	echo "ERROR: el usuario $SQUID_USER no puede leer el keytab $KEYTAB_RUNTIME" >&2
	namei -l "$KEYTAB_RUNTIME" >&2 || true
	exit 1
fi

if [ ! -x /usr/lib/squid/negotiate_kerberos_auth ]; then
	echo "ERROR: no existe el helper /usr/lib/squid/negotiate_kerberos_auth" >&2
	exit 1
fi

if [ "$KERBEROS_DEBUG" = "1" ]; then
	export KRB5_TRACE=/dev/stderr
	echo "Diagnostico Kerberos: usuario=$(id -u -n) keytab=$KEYTAB_RUNTIME" >&2
	ls -l "$KEYTAB_SOURCE" "$KEYTAB_RUNTIME" >&2
	namei -l "$KEYTAB_RUNTIME" >&2 || true
	su -s /bin/sh "$SQUID_USER" -c "klist -k '$KEYTAB_RUNTIME'" >&2
	debug_options='ALL,1 33,9 28,9 29,9 82,9'
else
	debug_options=''
fi

chown -R "$SQUID_USER:$SQUID_GROUP" "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

echo "Inicializando cache..."
if [ -n "$debug_options" ]; then
	squid -k parse -f /etc/squid/squid.conf -d1
else
	squid -k parse -f /etc/squid/squid.conf
fi
squid -z -f /etc/squid/squid.conf
chown -R "$SQUID_USER:$SQUID_GROUP" "$SPOOL_DIR"

rm -f /var/run/squid.pid /run/squid.pid "$RUN_DIR/squid.pid" || true

exec squid -N -d1 -f /etc/squid/squid.conf

