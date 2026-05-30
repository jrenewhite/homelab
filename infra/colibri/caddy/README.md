# Colibri Caddy

Esta carpeta es la fuente de verdad versionada para la configuracion de `Caddy` en `Colibri`.

## Estructura

- `Caddyfile`
  - archivo principal con opciones globales e `imports`
- `snippets/`
  - bloques reutilizables
- `sites/`
  - definiciones de sitios por hostname

## Reglas actuales

- `Caddy` sigue `local-only`
- `auto_https off`
- `admin off`
- `80/tcp` activo
- `443/tcp` sin uso todavia
- `8080` reservado para `Homepage`
- no se conectan backends reales en esta fase

## Convenciones

- un archivo por hostname o servicio en `sites/`
- nombre de archivo consistente:
  - placeholders: `<hostname>.caddy`
  - backends reales simples: `<servicio>.caddy` solo si el hostname principal es inequívoco
- cada archivo en `sites/` debe incluir comentarios cortos con:
  - `hostname`
  - `pattern`
  - `backend` real o futuro
  - `nodo`
  - `puerto`
- snippets base:
  - `common_headers`
  - `local_only`
  - `proxy_headers`
  - `placeholder_response`
- el patron de rollback por cambio de sitio es:
  1. revertir el archivo en `git`
  2. sincronizar a `/etc/caddy`
  3. `caddy validate`
  4. `systemctl restart caddy`
  5. reprobar con `curl`

## Runtime en management

Runtime esperado:

- `/etc/caddy/Caddyfile`
- `/etc/caddy/snippets/*.caddy`
- `/etc/caddy/sites/*.caddy`

El flujo deseado es:

1. editar en este repo
2. copiar a `management`
3. validar con `caddy validate`
4. reiniciar `Caddy` con `systemctl restart caddy`
5. probar con `curl`

Nota:

- no usar `systemctl reload caddy` en esta fase
- con `admin off`, el paquete intenta usar el admin API interno y el `reload` falla

## Estado actual

Los hostnames staged actuales:

- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Todos responden con placeholder local en `management` hasta conectar backends reales en fases posteriores.

Backends reales actuales:

- `home.white-enciso.com`
  - `Caddy` en `management` lo proxyea a `http://127.0.0.1:8080`
- `ntfy.white-enciso.com`
  - `Caddy` en `management` lo proxyea a `http://192.168.0.14:8300`

## Politica de exposure por hostname

Antes de conectar nuevos backends o preparar exposure publica futura:

- `home.white-enciso.com`
  - clase: `local-family`
- `ntfy.white-enciso.com`
  - clase: `local-ops`
- `pihole.white-enciso.com`
  - clase: `admin-local-only`
- `portainer.white-enciso.com`
  - clase: `tailscale-only`
- `auth.white-enciso.com`
  - clase: `staged-placeholder`
- `paperless.white-enciso.com`
  - clase: `staged-placeholder`
- `immich.white-enciso.com`
  - clase: `staged-placeholder`
- `jellyfin.white-enciso.com`
  - clase: `future-public`
- `navidrome.white-enciso.com`
  - clase: `staged-placeholder`

Guardrails:

- `pihole.white-enciso.com` no debe ser publico
- `Portainer` no debe ser publico
- `auth.white-enciso.com` no avanza a backend real ni exposure mayor antes del microplan de `SSO`
- `local-only` y `tailscale-only` siguen siendo el default mas seguro hasta nueva decision explicita

## Guardrails para cloudflared futuro

- `cloudflared` sigue desactivado en esta fase
- cualquier exposure futura sigue `default deny`
- solo se permite `allowlist` explicita por hostname
- cadena objetivo futura:
  - Internet -> `cloudflared` -> `Caddy` local -> backend
- `pihole.white-enciso.com` y cualquier URL de `Portainer` quedan fuera de exposure publica
- `auth`, `paperless`, `immich` y `navidrome` no cruzan al plano publico antes de policy de auth cerrada
