# Microplan 05E — Split-Horizon Local Records Staged

## Resumen

`05E` se ejecuto sin tocar router, `DHCP`, `Caddy`, `cloudflared` ni clientes globales.

Decision explicita:

- el proxy local futuro de Colibri sigue planeado en `management`
- mientras `Caddy/proxy` no esta activo, los hostnames staged se apuntan al placeholder del proxy futuro
- IP objetivo elegida:
  - `192.168.0.10`

## Registros creados

Se crearon en `Pi-hole` primario y secundario:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Todos apuntando a:

- `192.168.0.10`

No se agregaron en esta fase:

- `ntfy.white-enciso.com`
- `pihole.white-enciso.com`

## Implementacion

Primario:

- `/opt/stacks/pihole-primary/etc-pihole/pihole.toml`

Secundario:

- `/srv/storage/appdata/pihole-secondary/etc-pihole/pihole.toml`

Hallazgo importante:

- `Pi-hole v6` no respondio desde `custom.list`
- la configuracion efectiva de local records esta en:
  - `dns.hosts` dentro de `pihole.toml`

Por eso:

- se hizo backup previo de `pihole.toml` en ambos nodos
- se replicaron manualmente los mismos seis registros en `dns.hosts`
- se reinicio el contenedor `pihole` en ambos nodos

## Validacion directa

Primario:

- `dig @192.168.0.10 <hostname>` responde `192.168.0.10` para los seis registros

Secundario:

- `dig @192.168.0.14 <hostname>` responde `192.168.0.10` para los seis registros

Consistencia `primary/secondary`:

- `ok`

## Validacion desde cliente

Cliente canary:

- `bd795m`
- usando `Pi-hole` por `DHCP`

Validacion:

- `resolvectl query <hostname>` responde `192.168.0.10`
- `dig <hostname>` responde `192.168.0.10`

## Resolucion externa

Validacion:

- `dig cloudflare.com`: `ok`
- `curl -I https://cloudflare.com`: `ok`

Lectura:

- la resolucion externa siguio normal
- no hubo impacto visible en Internet domestico

## Evidencia en Pi-hole

`Pi-hole` primario siguio registrando queries reales del canary `192.168.0.18` para:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

## Caveats

- `192.168.0.10` es placeholder del proxy local futuro
- esta fase no confirma que las aplicaciones ya respondan por esos hostnames
- solo confirma que la capa `DNS` local staged funciona
- estos registros no significan que las apps vivan en `management`
- los backends reales previstos siguen siendo:
  - `Jellyfin` en `ai-gpu`
  - `Paperless` en `services`
  - `Immich core` en `services`
  - `Navidrome` en `services`
  - `auth/authentik` en `services`
  - `home` en `management` o donde se termine definiendo
- hasta `Microplan 06`, los hostnames pueden resolver localmente pero no necesariamente servir contenido correcto aun
- los hostnames admin opcionales siguen fuera de fase

## Veredicto

- IP objetivo elegida: `192.168.0.10`
- registros creados: `6`
- consistencia primario/secundario: `ok`
- validacion desde cliente: `ok`
- resolucion externa: `ok`
- `split-horizon` local staged: `ready`
- `05F` observacion post split-horizon o cleanup de deuda del helper/router: `go`
