# Microplan 06A — Caddy Local-Only Placeholder

## Resumen

`06A` se ejecuto en `management` para activar un proxy local minimo con `Caddy`, sin `cloudflared`, sin publicacion externa y sin conectar aun los backends reales.

## Prechecks

Validaciones previas:

- los hostnames staged ya resolvian a `192.168.0.10`
- `80/443/8080` estaban libres en `management`
- `Caddy` no estaba instalado

## Implementacion

Se instalo `Caddy` por paquete del sistema en `management`.

Configuracion aplicada:

- archivo:
  - `/etc/caddy/Caddyfile`
- modo:
  - `auto_https off`
  - `admin off`
- hostnames servidos:
  - `home.white-enciso.com`
  - `auth.white-enciso.com`
  - `jellyfin.white-enciso.com`
  - `paperless.white-enciso.com`
  - `immich.white-enciso.com`
  - `navidrome.white-enciso.com`
- respuesta:
  - placeholder controlado por `HTTP`
  - sin backend real
  - sin `TLS` publico

## Puertos usados

- `80/tcp`: activo por `Caddy`
- `443/tcp`: libre / no usado en esta fase
- `8080/tcp`: sigue reservado para `Homepage`, no usado por `Caddy`

## Validacion

Desde cliente canary:

```bash
curl http://home.white-enciso.com
curl http://auth.white-enciso.com
curl http://jellyfin.white-enciso.com
curl http://paperless.white-enciso.com
curl http://immich.white-enciso.com
curl http://navidrome.white-enciso.com
```

Resultado:

- todos responden `HTTP 200`
- todos devuelven placeholder de `Caddy` en `management`

Validacion adicional:

```bash
systemctl status caddy
ss -lntup
```

Resultado:

- `caddy.service`: `active (running)`
- listener efectivo:
  - `*:80`

## Anomalias

- el placeholder actual responde texto simple
- el cuerpo contiene secuencias `\\n` literales en vez de saltos de linea renderizados
- no rompe la validacion funcional de `06A`, pero se puede pulir mas adelante

## Veredicto

- `Caddy` en `management`: `ok`
- hostnames staged: `ok`
- placeholder local-only: `ok`
- `06B` conectar primer backend real local: `go`
