#!/usr/bin/env sh
set -e

SQUID_USER=${SQUID_USER:-proxy}
SQUID_GROUP=${SQUID_GROUP:-proxy}
LOG_DIR=${LOG_DIR:-/var/log/squid}
SPOOL_DIR=${SPOOL_DIR:-/var/spool/squid}
RUN_DIR=${RUN_DIR:-/var/run/squid}

CERT_DIR="/etc/ssl/squid_certs"
CA_CERT="$CERT_DIR/squid-ca-cert.pem"
CA_KEY="$CERT_DIR/squid-ca-key.pem"

# Crear directorio si no existe
mkdir -p "$CERT_DIR"

# Generar CA si falta
if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CERT" ]; then
    echo "Generando certificado CA para Squid..."
    openssl genrsa -out "$CA_KEY" 2048
    openssl req -new -x509 -days 3650 -key "$CA_KEY" -out "$CA_CERT" -subj "/CN=Squid Proxy CA"
    echo "Certificado CA generado en $CERT_DIR"
fi

mkdir -p "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

chown -R "$SQUID_USER:$SQUID_GROUP" "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

echo "Inicializando cache..."
squid -z -f /etc/squid/squid.conf || true
chown -R "$SQUID_USER:$SQUID_GROUP" "$SPOOL_DIR"

rm -f /var/run/squid.pid /run/squid.pid "$RUN_DIR/squid.pid" || true

exec squid -N -d1 -f /etc/squid/squid.conf

