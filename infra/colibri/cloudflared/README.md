# Colibri Cloudflared

Esta carpeta es la fuente de verdad versionada para la preparacion de `cloudflared` en `Colibri`.

## Estado actual

- `cloudflared` canary ya queda desplegado en `management` por `Docker Compose`
- `cloudflared` no esta instalado en `orangepi5-ultra`
- tunel canary actual:
  - `colibri-home-canary`
- allowlist publica actual:
  - `home.white-enciso.com`
- el resto sigue fuera del tunel canary
- el patron objetivo queda alineado a `Docker Compose` para ser operable despues por `Portainer`, sin convertir a `Portainer` en fuente de verdad

## Objetivo futuro

- conector principal:
  - `management`
- conector backup:
  - `orangepi5-ultra`
- cadena objetivo:
  - Internet -> `cloudflared` -> `Caddy` local -> backend

## Reglas

- `default deny`
- solo una `allowlist` explicita puede cruzar al plano publico
- no guardar:
  - `cert.pem`
  - credenciales de tunel
  - tokens
  - `tunnel id` sensible si se decide tratarlo como secreto operativo
- no usar esta carpeta para credenciales reales
- no activar servicio `cloudflared` sin configuracion aprobada y runtime real
- `Git + Docker Compose` sigue siendo la fuente de verdad
- `Portainer` o `Dockge` seran herramientas de operacion/visibilidad, no el origen de configuracion

## Runtime futuro

Ruta de configuracion esperada:

- stack runtime:
  - `/opt/stacks/cloudflared`
- config en runtime:
  - `/opt/stacks/cloudflared/config/config.yml`
- config montada dentro del contenedor:
  - `/etc/cloudflared/config.yml`

Ruta de secretos esperada:

- `/opt/colibri-secrets/cloudflared/`

Contenido esperado fuera de `git`:

- `cert.pem`
- `<tunnel-id>.json`
- cualquier token o credencial de login

## Flujo futuro

1. editar plantilla en este repo
2. sincronizar a `/opt/stacks/cloudflared`
3. colocar `config.yml` real en `/opt/stacks/cloudflared/config/`
4. colocar credenciales en `/opt/colibri-secrets/cloudflared/`
5. validar `docker compose config`
6. levantar el stack cuando exista autenticacion aprobada
7. solo entonces evaluar allowlist publica por hostname

## Compose

Archivo versionado:

- `infra/colibri/cloudflared/docker-compose.yml`

Propiedades cerradas:

- nombre de proyecto:
  - `colibri-cloudflared`
- nombre de contenedor:
  - `cloudflared`
- `restart: unless-stopped`
- `env_file`:
  - `/opt/colibri-secrets/cloudflared/cloudflared.env`
- labels operativas:
  - `com.colibri.stack=cloudflared`
  - `com.colibri.role=edge-tunnel`
  - `com.colibri.site=colibri`
  - `com.colibri.source=git`
- patron runtime preferido:
  - `token-first`
  - `TUNNEL_TOKEN_FILE` vive en `cloudflared.env`
  - el token real vive fuera de `git` en `/opt/colibri-secrets/cloudflared/tunnel.token`
  - `config.yml` mantiene ingress y catch-all

Nota:

- el archivo `cloudflared.env` vive fuera de `git`
- no hardcodear tokens en `docker-compose.yml`
- si en la fase real se usa `TUNNEL_TOKEN`, no debe vivir en `git`
- el compose versionado ya asume `TUNNEL_TOKEN_FILE` como runtime preferido
- no usar `Global API Key` sin confirmacion explicita
- si se usa un `API token` para crear recursos, no debe quedar como variable runtime si ya no es necesario

## Allowlist documental inicial

Candidatos futuros:

- `home.white-enciso.com`
- `jellyfin.white-enciso.com`

Privados o bloqueados:

- `ntfy.white-enciso.com`
- `pihole.white-enciso.com`
- `portainer.white-enciso.com`
- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

## Hostnames nunca publicos

- `pihole.white-enciso.com`
- cualquier futura URL de `Portainer`
