# Microplan 06I — Cloudflared Home Canary

Fecha de ejecucion:

- `2026-05-29`

## Objetivo

Publicar un unico hostname canary:

- `home.white-enciso.com`

Sin exponer:

- `ntfy`
- `pihole`
- `portainer`
- `auth`
- `paperless`
- `immich`
- `navidrome`
- `jellyfin`

## Implementacion

- despliegue en `management`
- patron:
  - `Docker Compose`
- stack versionado:
  - `infra/colibri/cloudflared/docker-compose.yml`
- runtime:
  - `/opt/stacks/cloudflared`
- proyecto:
  - `colibri-cloudflared`
- contenedor:
  - `cloudflared`

## Version

- `cloudflared 2026.5.2`

## Secretos

Ruta:

- `/opt/colibri-secrets/cloudflared/`

Archivos runtime:

- `cloudflared.env`
- `tunnel.token`
- `cert.pem`
- `15852846-afc2-41d5-92d9-87b437109528.json`

## Tunnel

- nombre:
  - `colibri-home-canary`
- id:
  - `15852846-afc2-41d5-92d9-87b437109528`

## Ingress efectivo

- `home.white-enciso.com` -> `http://host.docker.internal:80`
- catch-all -> `http_status:404`

## Validaciones

- `docker compose config`: `ok`
- `cloudflared tunnel ingress validate`: `OK`
- `cloudflared tunnel info colibri-home-canary`: `ok`
- validacion publica de `home.white-enciso.com` por edge publico:
  - `HTTP 200`
  - contenido de `Homepage`

## Default deny

- solo `home.white-enciso.com` entra a la allowlist publica del tunel canary
- el resto no se agrega al ingress

## Caveat

- `portainer.white-enciso.com` resolvio publicamente a IPs de `Cloudflare`, pero devolvio `530`
- esto sugiere `DNS` publico previo o wildcard heredado
- no se trato aqui porque esta fase solo permitia el canary de `home`

## Veredicto

- `06I`: `pass with public-dns caveat`
- `06J`: `go`
