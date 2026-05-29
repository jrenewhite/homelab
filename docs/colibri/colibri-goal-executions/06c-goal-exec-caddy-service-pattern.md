# Microplan 06C — Caddy service pattern and reverse proxy conventions

## Resumen

`06C` estandariza el patron de archivos y snippets de `Caddy` sin cambiar el comportamiento funcional del entorno, salvo limpieza no disruptiva.

## Convenciones definidas

- un archivo por hostname o servicio en `infra/colibri/caddy/sites/`
- comentarios cortos al inicio de cada `site` con:
  - `hostname`
  - `pattern`
  - `backend`
  - `nodo`
  - `puerto`
- snippets reutilizables finales:
  - `common_headers`
  - `local_only`
  - `proxy_headers`
  - `placeholder_response`
- flujo operativo oficial:
  1. editar en repo
  2. sincronizar a `/etc/caddy`
  3. `caddy validate --config /etc/caddy/Caddyfile`
  4. `systemctl restart caddy`
  5. probar con `curl`

## Archivos Caddy afectados

### Fuente de verdad

- `infra/colibri/caddy/Caddyfile`
- `infra/colibri/caddy/README.md`
- `infra/colibri/caddy/snippets/common_headers.caddy`
- `infra/colibri/caddy/snippets/local_only.caddy`
- `infra/colibri/caddy/snippets/proxy_headers.caddy`
- `infra/colibri/caddy/snippets/placeholder_response.caddy`
- `infra/colibri/caddy/sites/*.caddy`

### Runtime en management

- `/etc/caddy/Caddyfile`
- `/etc/caddy/snippets/*.caddy`
- `/etc/caddy/sites/*.caddy`

## Limpieza aplicada

- se agrego `local_only` como snippet explicito
- se agrego `proxy_headers` como snippet reutilizable para backends reales
- se actualizaron comentarios por `site`
- `common_headers` y `placeholder_response` quedan alineados a fase `06C`
- se quitaron `header_up` redundantes que provocaban warnings en `Caddy`

## Validacion

### `caddy validate`

Resultado:

- `Valid configuration`

### Reinicio

Resultado:

- `systemctl restart caddy`
- `caddy` queda `active`

## Validacion funcional

### `ntfy` por hostname

```bash
curl -I http://ntfy.white-enciso.com/
curl -X POST http://ntfy.white-enciso.com/colibri-ups-33883960f764a3bf \
  -d 'synthetic-06c-via-hostname'
```

Resultado:

- `HTTP 200`
- publish sintetico exitoso con respuesta JSON valida

### Placeholders

Validados:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Resultado:

- todos `HTTP 200`
- headers observados:
  - `X-Colibri-Proxy: caddy-local-only`
  - `X-Colibri-Phase: 06C`

## Caveats

- `Caddy` sigue bare metal en `management`
- `auto_https off`
- `admin off`
- no se usa `systemctl reload caddy` en esta fase
- no se conectaron backends nuevos

## Veredicto

- convenciones definidas: `ok`
- snippets finales: `ok`
- `validate/restart`: `ok`
- `ntfy` por hostname: `ok`
- placeholders: `ok`

## Recomendacion

- `06D` conectar `Homepage` o segundo backend real: `go`
