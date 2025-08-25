# docker-squid
Squid in Docker with Docker Compose

Este repo contiene una imagen Docker para Squid y una pequeña app PHP (`sqstats`).

Instrucciones principales — construir y ejecutar la imagen de Squid

1) Construir la imagen localmente pasando la versión de Squid y la distro (opcional):

```bash
# Ejemplo: construir squid 7.1 para 'jammy'
docker build -t my-squid:7.1 \
	--build-arg SQUID_VERSION=7.1 \
	--build-arg DISTRO=jammy .
```

2) Usar docker-compose (ejemplo incluido)

El `docker-compose.yml` tiene un servicio `squid` y otro `php-app` que construye desde `./sqstats`.
Si quieres pasar los build-args al servicio `squid`, descomenta/agrega `build.args` bajo `services.squid.build` como en el ejemplo:

```yaml
services:
	squid:
		build:
			context: .
			args:
				SQUID_VERSION: "7.1"
				DISTRO: "jammy"
```

Luego:

```bash
docker compose build --no-cache squid
docker compose up -d squid
```

O puedes exportar variables de entorno y usar `docker compose build`:

```bash
SQUID_VERSION=7.1 DISTRO=jammy docker compose build squid
```

Notas importantes
- SQUID_VERSION y DISTRO controlan la URL que descarga el .deb desde GitHub (repositorio `cuza/squid`). Si la URL/versión no existe el build fallará con 404.
- Por seguridad/compactación, el `Dockerfile` instala dependencias temporales (wget, gnupg, etc.), instala el .deb y luego las purga para reducir tamaño.
- El `Dockerfile` crea un usuario/grupo `proxy` y carpetas persistentes. En runtime `docker-compose.yml` monta `./squid_logs` y `./squid_cache` para persistencia.

Archivo `.dockerignore` recomendado

```
.git
node_modules
docker-compose.yml
*.md
sqstats/Dockerfile
sqstats/.git
squid_cache
squid_logs
```

Depuración rápida
- Ver logs del build: `docker compose build squid` y revisar la salida.
- Si la descarga falla: copia la `URL` construida y pruébala en tu navegador o con `curl -I <URL>`.
- Para entrar al contenedor y comprobar binario: `docker compose run --rm squid bash -c "which squid || ls -l /usr/sbin"`

¿Quieres que ejecute un build de prueba aquí (con red) para validar la descarga e instalación con `SQUID_VERSION=7.1` y `DISTRO=jammy`? Indica si autorizas la construcción.
