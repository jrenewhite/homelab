# Microplan 05A.1 — Pi-hole Primary Exposure en `management`

## Resumen

`Microplan 05A.1` reconcilia solo el `Pi-hole` primario en `management`, usando la politica de puertos vigente:

- DNS: `192.168.0.10:53 tcp/udp`
- UI: `192.168.0.10:8200/admin`

No se tocaron router, DHCP, clientes, `ntfy`, `NUT`, `Caddy`, `cloudflared`, `Tailscale`, `SSO`, `NFS`, mounts ni apps productivas.

## Causa raiz de `connection refused`

Hallazgo:

- el `docker-compose.yml` de `/opt/stacks/pihole-primary` ya declaraba exposicion de puertos al host
- pero el contenedor en ejecucion no habia sido recreado con esos mappings

Lectura:

- el problema no era `Pi-hole` roto
- el problema era desalineacion entre compose y contenedor vivo

## Revision previa

Comandos:

```bash
ssh -o BatchMode=yes jrenewhite@192.168.0.10 'cd /opt/stacks/pihole-primary && sed -n "1,160p" docker-compose.yml'
ssh -o BatchMode=yes jrenewhite@192.168.0.10 'docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"'
ssh -o BatchMode=yes jrenewhite@192.168.0.10 'docker inspect pihole --format "{{json .HostConfig.PortBindings}} {{json .NetworkSettings.Ports}}"'
ssh -o BatchMode=yes jrenewhite@192.168.0.10 'ss -lntup | grep -E ":53 |:8200 " || true'
```

## Cambio aplicado

Ruta:

- `/opt/stacks/pihole-primary/docker-compose.yml`

Acciones:

1. backup del compose actual
2. cambio de UI:
   - de `192.168.0.10:8080:80/tcp`
   - a `192.168.0.10:8200:80/tcp`
3. recreacion controlada:

```bash
docker compose up -d --force-recreate pihole
```

## Estado final del stack

Compose final:

```yaml
services:
  pihole:
    ports:
      - "192.168.0.10:53:53/tcp"
      - "192.168.0.10:53:53/udp"
      - "192.168.0.10:8200:80/tcp"
```

`docker ps` final:

- `192.168.0.10:53->53/tcp`
- `192.168.0.10:53->53/udp`
- `192.168.0.10:8200->80/tcp`

`ss -lntup` final:

- `192.168.0.10:53`
- `192.168.0.10:8200`

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
dig +short @192.168.0.10 cloudflare.com
dig +short @192.168.0.10 google.com
curl -fsSI --max-time 5 http://192.168.0.10:8200/admin
```

Resultado:

- `cloudflare.com`: resuelve
- `google.com`: resuelve
- `http://192.168.0.10:8200/admin`: `HTTP/1.1 308 Permanent Redirect` hacia `/admin/`

## Puertos finales

- DNS:
  - `192.168.0.10:53/tcp`
  - `192.168.0.10:53/udp`
- UI:
  - `192.168.0.10:8200`

## Anomalias

- ninguna funcional en el primario despues de la recreacion
- el bloqueo de `05A` ya no esta en `management`
- el bloqueo pendiente sigue siendo `orangepi5-ultra`, por conflicto de `8080` con `ntfy-local`

## Veredicto

- primario `management`: `ready`
- repetir `05A` staged validation completa: `no-go` todavia
- siguiente paso sano:
  - reconciliar `Pi-hole` secundario a `192.168.0.14:8201`
  - sin mover `ntfy-local` fuera de una fase dedicada
