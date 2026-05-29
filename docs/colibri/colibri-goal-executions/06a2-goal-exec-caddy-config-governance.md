# Microplan 06A.2 — Caddy config governance

## Resumen

`06A.2` crea una estructura modular y versionada para `Caddy`, la deja en el repo y alinea el runtime de `management` con esa estructura sin cambiar el comportamiento actual de placeholders.

## Objetivo alcanzado

Se crea una fuente de verdad en `git` para `Caddy`:

- `infra/colibri/caddy/Caddyfile`
- `infra/colibri/caddy/snippets/`
- `infra/colibri/caddy/sites/`
- `infra/colibri/caddy/README.md`

`management` queda solo como runtime:

- `/etc/caddy/Caddyfile`
- `/etc/caddy/snippets/*.caddy`
- `/etc/caddy/sites/*.caddy`

## Config activa encontrada

Antes de la gobernanza, `management` tenia una `Caddyfile` monolitica en:

- `/etc/caddy/Caddyfile`

Contenido funcional:

- `auto_https off`
- `admin off`
- un snippet `placeholder`
- seis hostnames definidos en el mismo archivo

## Estructura creada en el repo

### Principal

- `infra/colibri/caddy/Caddyfile`

Con:

```caddyfile
{
	auto_https off
	admin off
}

import snippets/*.caddy
import sites/*.caddy
```

### Snippets

- `infra/colibri/caddy/snippets/common_headers.caddy`
- `infra/colibri/caddy/snippets/placeholder_response.caddy`

### Sites

- `infra/colibri/caddy/sites/home.white-enciso.com.caddy`
- `infra/colibri/caddy/sites/auth.white-enciso.com.caddy`
- `infra/colibri/caddy/sites/jellyfin.white-enciso.com.caddy`
- `infra/colibri/caddy/sites/paperless.white-enciso.com.caddy`
- `infra/colibri/caddy/sites/immich.white-enciso.com.caddy`
- `infra/colibri/caddy/sites/navidrome.white-enciso.com.caddy`

## Aplicacion en runtime

Se copio la estructura versionada a `management` en:

- `/etc/caddy/Caddyfile`
- `/etc/caddy/snippets/`
- `/etc/caddy/sites/`

Se dejo backup local previo de `Caddyfile` en:

- `/etc/caddy/backups/Caddyfile.<timestamp>.bak`

## Validacion

### `caddy validate`

Comando:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
```

Resultado:

- `Valid configuration`

### `reload` vs `restart`

Intento inicial:

```bash
sudo systemctl reload caddy
```

Resultado:

- fallo

Causa:

- con `admin off`, el paquete intenta usar el admin API interno para `reload`
- eso falla con `connection refused`

Patron efectivo:

```bash
sudo systemctl restart caddy
sudo systemctl is-active caddy
```

Resultado:

- `active`

## Validacion funcional de placeholders

Hostnames validados:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Resultado:

- todos responden `HTTP 200`
- siguen sirviendo placeholder local-only

Headers observados:

- `X-Colibri-Proxy: caddy-local-only`
- `X-Colibri-Phase: 06A.2`

## Puertos y reglas vigentes

- `80/tcp`: activo por `Caddy`
- `443/tcp`: sigue sin uso
- `8080`: sigue reservado para `Homepage`

No se hizo:

- `TLS`
- `cloudflared`
- conexion a backends reales
- cambio de `DNS`

## Veredicto

- estructura creada: `ok`
- runtime alineado en `management`: `ok`
- `caddy validate`: `ok`
- `systemctl restart caddy`: `ok`
- placeholders: `ok`

## Recomendacion

- `06B` conectar `ntfy.white-enciso.com` como primer backend real local: `go`
