FROM ubuntu:22.04

# Build args to make squid version and distro dynamic
ARG SQUID_VERSION=7.1
ARG DISTRO=jammy

ENV SQUID_VERSION=${SQUID_VERSION}
ENV DISTRO=${DISTRO}

# Instalar dependencias y Squid (descarga dinámica según SQUID_VERSION y DISTRO)
RUN set -eux; \
    DEB_TAG="ubuntu-${DISTRO}"; \
    DEB_NAME="squid_${SQUID_VERSION}-${DEB_TAG}_amd64.deb"; \
    URL="https://github.com/cuza/squid/releases/download/${SQUID_VERSION}/${DEB_NAME}"; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget curl ca-certificates apt-transport-https gnupg dirmngr; \
    wget -O "/tmp/${DEB_NAME}" "${URL}"; \
    # Try to install; if missing deps, fix and retry
    if ! dpkg -i "/tmp/${DEB_NAME}"; then \
        apt-get update; apt-get install -y --no-install-recommends -f; \
        dpkg -i "/tmp/${DEB_NAME}"; \
    fi; \
    rm -f "/tmp/${DEB_NAME}"; \
    apt-get purge -y --auto-remove wget ca-certificates gnupg dirmngr; \
    rm -rf /var/lib/apt/lists/*

# Asegurar grupo/usuario proxy (Ubuntu suele usar proxy:proxy)
RUN getent group proxy || groupadd -r proxy && \
    id proxy || useradd -r -g proxy -s /usr/sbin/nologin -d /var/spool/squid proxy

# Crear rutas básicas (el entrypoint ajustará permisos en runtime)
RUN mkdir -p /var/log/squid /var/spool/squid /var/run/squid && \
    chown -R proxy:proxy /var/log/squid /var/spool/squid /var/run/squid

# COPY squid.conf /etc/squid/squid.conf  # ya lo montas por volumen

# Entrypoint que corrige permisos/inicializa cache en arranque
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3128
ENTRYPOINT ["/entrypoint.sh"]