FROM ubuntu:22.04

# Instalar dependencias y Squid
RUN apt-get update && \
    apt-get install -y wget curl ca-certificates && \
    wget https://github.com/cuza/squid/releases/download/7.1/squid_7.1-ubuntu-jammy_amd64.deb && \
    dpkg -i squid_7.1-ubuntu-jammy_amd64.deb || apt-get install -f -y && \
    dpkg -i squid_7.1-ubuntu-jammy_amd64.deb && \
    rm -f squid_7.1-ubuntu-jammy_amd64.deb

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