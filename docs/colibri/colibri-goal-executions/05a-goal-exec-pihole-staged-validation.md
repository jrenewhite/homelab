# Microplan 05A — Pi-hole Staged Validation

## Resumen

`Microplan 05A` se repitio despues de reconciliar:

- `05A.1` en `management`
- `05A.2` en `orangepi5-ultra`

Resultado final:

- primario `management`: `ready`
- secundario `orangepi5-ultra`: `ready`
- `ntfy-local` sigue sano en `192.168.0.14:8080`
- terciario `orangepi5-max`: sigue opcional y fuera de esta fase

Veredicto:

- `05B` canary DNS por cliente manual: `go`

## Prechecks

- no se toco router
- no se modifico DHCP
- no se cambiaron reservas ni IPs
- no se cambiaron DNS de clientes
- no se tocaron `Caddy`, `cloudflared`, `Tailscale`, `SSO`, `NFS`, mounts, `NUT`, `ntfy` ni apps productivas

## Conectividad

Comandos:

```bash
ping -c 1 -W 1 192.168.0.10
ping -c 1 -W 1 192.168.0.14
ssh -o BatchMode=yes jrenewhite@192.168.0.10 'echo management-ssh=ok'
ssh jrenewhite@192.168.0.14 'echo ultra-ssh=ok'
```

Resultado:

- `management`: `ping` y `SSH` ok
- `orangepi5-ultra`: `ping` y `SSH` ok

## Estado de contenedores

### `management`

Comandos:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
docker inspect pihole --format "{{json .HostConfig.PortBindings}} {{json .NetworkSettings.Ports}}"
ss -lntup | grep -E ":53 |:8200 "
```

Resultado:

- `pihole` `healthy`
- puertos publicados:
  - `192.168.0.10:53->53/tcp`
  - `192.168.0.10:53->53/udp`
  - `192.168.0.10:8200->80/tcp`

### `orangepi5-ultra`

Comandos:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
docker inspect pihole --format "{{json .HostConfig.PortBindings}} {{json .NetworkSettings.Ports}}"
ss -lntup | grep -E ":53 |:8201 |:8080 "
```

Resultado:

- `pihole` `healthy`
- `ntfy-local` `up`
- puertos publicados:
  - `192.168.0.14:53->53/tcp`
  - `192.168.0.14:53->53/udp`
  - `192.168.0.14:8201->80/tcp`
  - `192.168.0.14:8080->80/tcp` para `ntfy-local`

## Resolucion externa por IP directa

Comandos:

```bash
dig +short @192.168.0.10 cloudflare.com
dig +short @192.168.0.10 google.com
dig +short @192.168.0.14 cloudflare.com
dig +short @192.168.0.14 google.com
```

Resultado:

- `@192.168.0.10 cloudflare.com`: resuelve
- `@192.168.0.10 google.com`: resuelve
- `@192.168.0.14 cloudflare.com`: resuelve
- `@192.168.0.14 google.com`: resuelve

## Resolucion interna staged

Comandos:

```bash
dig +short @192.168.0.10 home.white-enciso.com
dig +short @192.168.0.10 auth.white-enciso.com
dig +short @192.168.0.10 jellyfin.white-enciso.com
dig +short @192.168.0.10 paperless.white-enciso.com

dig +short @192.168.0.14 home.white-enciso.com
dig +short @192.168.0.14 auth.white-enciso.com
dig +short @192.168.0.14 jellyfin.white-enciso.com
dig +short @192.168.0.14 paperless.white-enciso.com
```

Resultado:

- no devolvieron registros locales staged en esta fase

Lectura:

- `split-horizon DNS` local sigue `pending`
- no se toma como fallo de `05A`

## UI

Comandos:

```bash
curl -fsSI --max-time 5 http://192.168.0.10:8200/admin
curl -fsSI --max-time 5 http://192.168.0.14:8201/admin
curl -fsSI --max-time 5 http://192.168.0.14:8080/
```

Resultado:

- `http://192.168.0.10:8200/admin`: `HTTP/1.1 308 Permanent Redirect` a `/admin/`
- `http://192.168.0.14:8201/admin`: `HTTP/1.1 308 Permanent Redirect` a `/admin/`
- `http://192.168.0.14:8080/`: `HTTP/1.1 200 OK`

## Baseline

Validacion en ambos nodos:

- `StevenBlack` deshabilitada
- `OISD small` habilitada

Evidencia:

```text
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts|0|Migrated from /etc/pihole/adlists.list
https://small.oisd.nl|1|Colibri baseline: conservative community-recommended blocklist
```

## Estado final

- primario `management`: `ready`
- secundario `orangepi5-ultra`: `ready`
- `ntfy-local`: `ready` en `192.168.0.14:8080`
- `split-horizon DNS`: `pending`

## Anomalias

- ninguna funcional para primario o secundario
- el punto pendiente ya no es exposicion ni baseline
- el pendiente real es poblar o validar entradas locales de `split-horizon`

## Veredicto

- `05A` staged validation para primario+secundario: `pass`
- `05B` canary DNS por cliente manual: `go`
