# Microplan 05C — Router DNS Cutover con Rollback

## Resumen

`05C` se ejecuto como cutover mixto:

- captura manual del estado previo del router
- aplicacion controlada por `CLI` del `ER707-M2`
- validacion primero en `bd795m`
- validacion despues en un segundo cliente controlado `orangepi5-max`

No se tocaron:

- reservas `DHCP`
- IPs
- `DNS` del router hacia `192.168.0.14`
- listas de `Pi-hole`
- `split-horizon`

## Estado previo capturado

Router `ER707-M2`:

- pool `DHCP`: `LAN`
- `DHCP`: habilitado
- `show dhcp server` no mostraba `pri_dns/snd_dns`
- clientes observados antes del cutover:
  - `bd795m` usando `192.168.0.1`

Helper/script en `management`:

- `/opt/colibri-secrets/router.env` seguia con:
  - `TARGET_DNS2=192.168.0.51`
  - `CANARY_HOST=192.168.0.152`
- `/opt/colibri/bin/router-dns-cutover-with-rollback.sh` no podia capturar por si solo el DNS previo porque `show dhcp server` no devolvia `dns1/dns2` en el estado anterior

## Prechecks

En `management`:

```bash
dig +short @192.168.0.10 cloudflare.com
dig +short @192.168.0.10 google.com
dig +short @1.1.1.1 cloudflare.com
docker ps --filter name=pihole
systemctl is-active nut-server nut-monitor
```

Resultado:

- `Pi-hole` primario sano
- fallback publico `1.1.1.1` responde
- `NUT` y `ntfy` quedaron solo como observacion; no se modificaron

## Cambio aplicado en router

Aplicacion por `CLI`:

```text
ip dhcp server pool LAN
dns-server dns1 192.168.0.10
dns-server dns2 1.1.1.1
```

Validacion del router despues del cambio:

- `show dhcp server` mostro:
  - `option pri_dns 192.168.0.10`
  - `option snd_dns 1.1.1.1`
- el pool `LAN` siguio habilitado

## Validacion en cliente canary principal

Cliente:

- `bd795m`
- `192.168.0.18`
- interfaz `enp6s0`

Antes:

- `Current DNS Server: 192.168.0.1`

Despues de renovar/reaplicar la red:

- `Current DNS Server: 192.168.0.10`
- `DNS Servers: 192.168.0.10`

Comandos de validacion:

```bash
resolvectl status enp6s0
nmcli device show enp6s0
dig +short cloudflare.com
dig +short google.com
dig +short pi-hole.net
curl -I --max-time 5 https://cloudflare.com
```

Resultado:

- `cloudflare.com`: resuelve
- `google.com`: resuelve
- `pi-hole.net`: resuelve
- navegacion basica: `ok`

`split-horizon` staged:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`

Todos quedaron como `pending split-horizon`, no como fallo.

## Evidencia en Pi-hole primario

`Pi-hole` primario registro queries reales desde `192.168.0.18`, incluyendo:

- `cloudflare.com`
- `google.com`
- `pi-hole.net`
- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`

Tambien registro `NXDOMAIN` cacheado para los nombres internos staged pendientes.

## Validacion en segundo cliente controlado

Cliente:

- `orangepi5-max`
- `192.168.0.15`
- interfaz `enP3p49s0`

Antes:

- `Current DNS Server: 192.168.0.1`

Despues de `networkctl renew enP3p49s0`:

- `DNS Servers: 192.168.0.10`

Validacion:

- resolucion externa: `ok`
- `curl -I https://cloudflare.com`: `ok`
- `Pi-hole` primario registro queries desde `192.168.0.15`

## Rollback

Rollback preparado, no ejecutado:

```text
ip dhcp server pool LAN
no dns-server
```

Despues del rollback, el paso esperado seria:

- renovar red en `bd795m`
- confirmar regreso a `192.168.0.1`
- repetir validacion basica de Internet

## Anomalias

- el router quedo configurado con `DNS2 = 1.1.1.1`
- pero los dos clientes renovados solo mostraron `192.168.0.10` como `DNS` recibido/activo
- no hubo perdida de Internet ni de resolucion
- esto se registra como caveat de propagacion de `DNS2`, no como fallo funcional del cutover

## Veredicto

- cutover del router: `pass with DNS2 propagation caveat`
- `DHCP` sigue en `ER707-M2`
- `Pi-hole` primario queda en uso real por clientes LAN
- `split-horizon` sigue `pending`
- `05D` validar estabilidad post-cutover y preparar `split-horizon`: `go`
