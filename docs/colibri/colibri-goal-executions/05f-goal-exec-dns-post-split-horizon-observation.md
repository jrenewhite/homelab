# Microplan 05F — Post Split-Horizon Observation and Closure

## Resumen

`05F` se ejecuto como verificacion final de estabilidad, sin tocar router, `DHCP`, `Pi-hole`, `ntfy`, proxy ni clientes fuera del canary.

Objetivo:

- confirmar que la resolucion externa sigue sana
- confirmar que `split-horizon` staged sigue resolviendo a `192.168.0.10`
- confirmar que primario, secundario y `ntfy-local` siguen estables
- cerrar `Microplan 05` como `staged-ready`

## Validaciones realizadas

Cliente canary `bd795m`:

```bash
dig cloudflare.com
dig google.com
dig home.white-enciso.com
dig auth.white-enciso.com
dig jellyfin.white-enciso.com
dig paperless.white-enciso.com
dig immich.white-enciso.com
dig navidrome.white-enciso.com
curl -I https://cloudflare.com
```

Validacion directa a `Pi-hole`:

```bash
dig @192.168.0.10 cloudflare.com
dig @192.168.0.10 home.white-enciso.com
dig @192.168.0.14 cloudflare.com
dig @192.168.0.14 home.white-enciso.com
curl -I http://192.168.0.10:8200/admin
curl -I http://192.168.0.14:8201/admin
curl -I http://192.168.0.14:8080
```

Evidencia en `Pi-hole` primario:

```bash
docker exec pihole grep -E '(home|auth|jellyfin|paperless|immich|navidrome)\.white-enciso\.com.*from 192\.168\.0\.18' /var/log/pihole/pihole.log
```

## Resultados

Cliente canary:

- `cloudflare.com`: `ok`
- `google.com`: `ok`
- `home.white-enciso.com`: `192.168.0.10`
- `auth.white-enciso.com`: `192.168.0.10`
- `jellyfin.white-enciso.com`: `192.168.0.10`
- `paperless.white-enciso.com`: `192.168.0.10`
- `immich.white-enciso.com`: `192.168.0.10`
- `navidrome.white-enciso.com`: `192.168.0.10`
- navegacion basica: `ok`

Primario:

- `dig @192.168.0.10 cloudflare.com`: `ok`
- `dig @192.168.0.10 home.white-enciso.com`: `192.168.0.10`
- UI `8200/admin`: `308` a `/admin/`
- contenedor `pihole`: `healthy`

Secundario:

- `dig @192.168.0.14 cloudflare.com`: `ok`
- `dig @192.168.0.14 home.white-enciso.com`: `192.168.0.10`
- UI `8201/admin`: `308` a `/admin/`
- sigue consistente con el primario

`ntfy-local`:

- `http://192.168.0.14:8080`: `200 OK`

## Evidencia de queries

`Pi-hole` primario siguio registrando queries reales del canary `192.168.0.18` para:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

## Caveats restantes

- `DNS2 = 1.1.1.1` sigue como caveat:
  - configurado en router
  - no observado en leases efectivos de cliente
- `split-horizon` staged apunta a `192.168.0.10` como placeholder del futuro `Caddy` local en `management`
- esto no implica que las apps ya esten sirviendo contenido correcto por hostname

## Veredicto

- `Pi-hole` primario: `healthy`
- `Pi-hole` secundario: `healthy`
- `split-horizon` staged: `ready`
- `Microplan 05`: `completed / staged-ready`

## Recomendacion

- `Microplan 06`: `go`
- foco sugerido:
  - activar `Caddy` local
  - conectar hostnames staged con los backends reales
