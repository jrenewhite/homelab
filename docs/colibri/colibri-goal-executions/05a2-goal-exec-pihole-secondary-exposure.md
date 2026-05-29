# Microplan 05A.2 — Pi-hole Secondary Exposure en `orangepi5-ultra`

## Resumen

`Microplan 05A.2` reconcilia el `Pi-hole` secundario en `orangepi5-ultra`, manteniendo `ntfy-local` intacto en `8080`.

Objetivo cumplido:

- DNS: `192.168.0.14:53 tcp/udp`
- UI: `192.168.0.14:8201/admin`

No se tocaron router, DHCP, clientes, `ntfy`, `NUT`, `Caddy`, `cloudflared`, `Tailscale`, `SSO`, `NFS`, mounts ni apps productivas.

## Stack existente

Si existia stack versionado aprobado:

- ruta: `/srv/storage/appdata/pihole-secondary`
- compose presente
- `gravity.db` presente
- baseline ya persistida

No se improviso un stack nuevo fuera del repo.

## Causa raiz

El stack existia, pero estaba desalineado con la realidad actual:

- IP vieja en compose:
  - `192.168.0.51:53:53/tcp`
  - `192.168.0.51:53:53/udp`
  - `192.168.0.51:8080:80/tcp`
- `8080` ya no es puerto valido para la UI de `Pi-hole` en la politica actual
- `8080` esta ocupado por `ntfy-local`

## Estado previo

Comandos:

```bash
ss -lntup
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
sed -n '1,160p' /srv/storage/appdata/pihole-secondary/docker-compose.yml
```

Hallazgos:

- `ntfy-local` activo en `192.168.0.14:8080->80/tcp`
- `pihole` previo en estado `Exited (128)`
- compose con IP vieja `192.168.0.51`

## Cambio aplicado

Ruta:

- `/srv/storage/appdata/pihole-secondary/docker-compose.yml`

Acciones:

1. backup local del compose
2. cambio de bindings a:
   - `192.168.0.14:53:53/tcp`
   - `192.168.0.14:53:53/udp`
   - `192.168.0.14:8201:80/tcp`
3. recreacion controlada:

```bash
docker compose up -d --force-recreate pihole
```

## Estado final del stack

`docker ps` final:

- `pihole`
  - `192.168.0.14:53->53/tcp`
  - `192.168.0.14:53->53/udp`
  - `192.168.0.14:8201->80/tcp`
- `ntfy-local`
  - `192.168.0.14:8080->80/tcp`

`ss -lntup` final:

- `192.168.0.14:53`
- `192.168.0.14:8201`
- `192.168.0.14:8080`

## Baseline de listas

Validacion:

- `StevenBlack` deshabilitada
- `OISD small` habilitada

Evidencia:

```text
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts|0|Migrated from /etc/pihole/adlists.list
https://small.oisd.nl|1|Colibri baseline: conservative community-recommended blocklist
```

## Validacion final

Comandos:

```bash
dig +short @192.168.0.14 cloudflare.com
dig +short @192.168.0.14 google.com
curl -fsSI --max-time 5 http://192.168.0.14:8201/admin
curl -fsSI --max-time 5 http://192.168.0.14:8080/
```

Resultado:

- `cloudflare.com`: resuelve
- `google.com`: resuelve
- `http://192.168.0.14:8201/admin`: `HTTP/1.1 308 Permanent Redirect` hacia `/admin/`
- `http://192.168.0.14:8080/`: `HTTP/1.1 200 OK`

## Estado de `ntfy-local`

- permanece activo
- no fue movido
- sigue respondiendo en `192.168.0.14:8080`

## Puertos finales

- `Pi-hole` secundario DNS:
  - `192.168.0.14:53/tcp`
  - `192.168.0.14:53/udp`
- `Pi-hole` secundario UI:
  - `192.168.0.14:8201`
- `ntfy-local`:
  - `192.168.0.14:8080`

## Veredicto

- `orangepi5-ultra` tenia stack `Pi-hole` existente: `si`
- cambios aplicados: `si`
- primario `management`: `ready`
- secundario `orangepi5-ultra`: `ready`
- repetir `05A` staged validation para primario+secundario: `go`
- terciario `orangepi5-max`: sigue opcional y fuera de esta fase
