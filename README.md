# docker-squid
Squid in Docker with Docker Compose

This repo contains a Docker image for Squid.

## Quick start — build and run the Squid image

1) Build the image locally, optionally specifying the Squid version and base distro:

```bash
# example: build squid 7.1 for "jammy"
docker build -t my-squid:7.1 \
    --build-arg SQUID_VERSION=7.1 \
    --build-arg DISTRO=jammy .
```

2) Use docker-compose (example included)

The `docker-compose.yml` defines a `squid` service and a `php-app` service that builds from `./sqstats`.
If you want to pass build args to the `squid` service, uncomment/add `build.args` under `services.squid.build` as shown:

```yaml
services:
  squid:
    build:
      context: .
      args:
        SQUID_VERSION: "7.1"
        DISTRO: "jammy"
```

Then run:

```bash
docker compose build --no-cache squid
docker compose up -d squid
```

Alternatively you can export environment variables and use `docker compose build`:

```bash
SQUID_VERSION=7.1 DISTRO=jammy docker compose build squid
```

### Important notes
- `SQUID_VERSION` and `DISTRO` control the URL used to download the .deb from GitHub (repo `cuza/squid`). If the URL/version does not exist the build will fail with a 404.
- For security and size reasons the `Dockerfile` installs temporary packages (wget, gnupg, etc.), installs the .deb and then removes them.
- The `Dockerfile` creates a `proxy` user/group and persistent directories. At runtime `docker-compose.yml` mounts `./squid_logs` and `./squid_cache` for persistence.

## SSL Bump certificates (root CA)
To make browsers trust the “dynamic” certificates Squid generates when intercepting HTTPS you must install the root CA that the proxy creates—**not** the per‑host certs or any other intermediate.

Three files are produced inside the container:

| File | Contents | Browser usage |
|------|----------|---------------|
| `squid-ca-cert.pem` | X.509 certificate in PEM format | not imported directly |
| `squidCA.pem` | combined PEM (cert + key) used by Squid | not imported |
| `squid.der` | root certificate converted to DER | ✅ import this one |

Distribute the `squid.der` file (or convert one of the PEMs to DER yourself) to client machines. Import it in Firefox/Chrome/Edge under **Authorities** and check “trust this CA to identify websites”.

Once the root CA is installed the browser will silently accept the TLS certificates Squid generates for each target site.

Recommended `.dockerignore` file

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

## Quick debugging
- View build logs: `docker compose build squid` and watch the output.
- If the download fails: copy the constructed URL and test it with a browser or `curl -I <URL>`.
- To enter the container and verify the binary:  
  `docker compose run --rm squid bash -c "which squid || ls -l /usr/sbin"`

Would you like me to run a test build here (with network access) using `SQUID_VERSION=7.1` and `DISTRO=jammy`? Let me know if you authorize the build.

