FROM ubuntu:22.04

# Build args to make squid version and distro dynamic
ARG SQUID_VERSION=7.4
ARG DISTRO=jammy

ENV SQUID_VERSION=${SQUID_VERSION}
ENV DISTRO=${DISTRO}

# Instalar dependencias y Squid (descarga dinámica según SQUID_VERSION y DISTRO)
RUN set -eux; \
    DEB_TAG="ubuntu-${DISTRO}"; \
    DEB_NAME="squid_${SQUID_VERSION}-${DEB_TAG}_amd64.deb"; \
    URL="https://github.com/cuza/squid/releases/download/${SQUID_VERSION}/${DEB_NAME}"; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget curl ca-certificates apt-transport-https python3 python3-pip git gnupg dirmngr krb5-user libgssapi-krb5-2; \
    update-ca-certificates; \
    wget -O "/tmp/${DEB_NAME}" "${URL}"; \
    # Try to install; if missing deps, fix and retry
    if ! dpkg -i "/tmp/${DEB_NAME}"; then \
        apt-get update; apt-get install -y --no-install-recommends -f; \
        dpkg -i "/tmp/${DEB_NAME}"; \
    fi; \
    rm -f "/tmp/${DEB_NAME}"; \
    rm -rf /var/lib/apt/lists/*

# Asegurar grupo/usuario proxy (Ubuntu suele usar proxy:proxy)
RUN getent group proxy || groupadd -r proxy && \
    id proxy || useradd -r -g proxy -s /usr/sbin/nologin -d /var/spool/squid proxy

# Crear rutas básicas (el entrypoint ajustará permisos en runtime)
RUN mkdir -p /var/log/squid /var/spool/squid /var/run/squid /var/lib/squid /etc/squid/reglas && \
    chown -R proxy:proxy /var/log/squid /var/spool/squid /var/run/squid /var/lib/squid

COPY krb5.conf /etc/krb5.conf

# Entrypoint que corrige permisos/inicializa cache en arranque
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#RUN git clone https://github.com/kaelthasmanu/SquidStats

#RUN pip3 install -r ./SquidStats/requirements.txt

EXPOSE 3128
ENTRYPOINT ["/entrypoint.sh"]