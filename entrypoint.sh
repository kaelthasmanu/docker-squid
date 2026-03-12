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
CA_PEM="$CERT_DIR/squidCA.pem"
CA_DER="$CERT_DIR/squid.der"
SSL_DB="/var/lib/squid/ssl_db"

# Crear directorio si no existe
mkdir -p "$CERT_DIR"

# Generar CA si falta
if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CERT" ]; then
    echo "Generando certificado CA para Squid..."
    openssl genrsa -out "$CA_KEY" 2048
    openssl req -new -x509 -days 730 -key "$CA_KEY" -sha256 -extensions v3_ca -out "$CA_CERT" \
        -subj "/CN=Squid Proxy CA/O=Squid/OU=Proxy"
    echo "Certificado CA generado en $CERT_DIR"
fi

# Crear PEM combinado (cert + key) para Squid ssl-bump
cat "$CA_CERT" "$CA_KEY" > "$CA_PEM"
chown "$SQUID_USER:$SQUID_GROUP" "$CA_PEM"
chmod 400 "$CA_PEM"

# Generar certificado DER para importar en navegadores
openssl x509 -in "$CA_CERT" -outform DER -out "$CA_DER"

# Inicializar la DB de certificados SSL si no existe
CERTGEN_BIN=""
for bin in /usr/lib/squid/security_file_certgen /usr/lib64/squid/security_file_certgen /usr/libexec/security_file_certgen /usr/lib/squid/ssl_crtd; do
    if [ -x "$bin" ]; then
        CERTGEN_BIN="$bin"
        break
    fi
done

if [ -z "$CERTGEN_BIN" ]; then
    echo "ERROR: No se encontró security_file_certgen. SSL Bump no estará disponible."
else
    if [ ! -d "$SSL_DB" ]; then
        echo "Inicializando SSL DB..."
        "$CERTGEN_BIN" -c -s "$SSL_DB" -M 10MB
        echo "SSL DB inicializada."
    fi
    chown -R "$SQUID_USER:$SQUID_GROUP" "$SSL_DB"
fi

# Crear fichero de reglas si no existe
mkdir -p /etc/squid/reglas
[ -f /etc/squid/reglas/no_bump_sites ] || touch /etc/squid/reglas/no_bump_sites

mkdir -p "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

chown -R "$SQUID_USER:$SQUID_GROUP" "$LOG_DIR" "$SPOOL_DIR" "$RUN_DIR"

echo "Inicializando cache..."
squid -z -f /etc/squid/squid.conf || true
chown -R "$SQUID_USER:$SQUID_GROUP" "$SPOOL_DIR"

rm -f /var/run/squid.pid /run/squid.pid "$RUN_DIR/squid.pid" || true

exec squid -N -d1 -f /etc/squid/squid.conf

