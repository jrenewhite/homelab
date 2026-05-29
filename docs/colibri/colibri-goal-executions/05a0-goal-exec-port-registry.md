# Microplan 05A.0 — Port Registry and Service Exposure Policy

## Resumen

`Microplan 05A.0` se ejecuto para fijar politica de puertos por familias y reconciliar el `Pi-hole` primario en `management`, sin tocar router, DHCP, clientes ni `Pi-hole` secundario/terciario.

Resultado final:

- politica de puertos creada
- `Pi-hole` primario reconciliado a:
  - `192.168.0.10:53/tcp`
  - `192.168.0.10:53/udp`
  - `192.168.0.10:8200`
- `ntfy-local` en `orangepi5-ultra:8080` queda como deuda de migracion
- `Pi-hole` secundario pasa a objetivo `8201`
- `Pi-hole` terciario pasa a objetivo `8202`

## Puertos ocupados por nodo

### `management`

Comandos:

```bash
ss -lntup
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
docker inspect pihole --format "{{json .HostConfig.NetworkMode}} {{json .HostConfig.PortBindings}}"
```

Puertos relevantes:

- `22/tcp` `SSH`
- `3493/tcp` `NUT`
- `53/tcp,udp` `Pi-hole` primario despues de reconciliacion
- `8200/tcp` `Pi-hole` UI despues de reconciliacion
- `127.0.0.53:53` y `127.0.0.54:53` `resolved` local

### `orangepi5-ultra`

Comandos:

```bash
ss -lntup
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
```

Puertos relevantes:

- `22/tcp` `SSH`
- `8080/tcp` `ntfy-local`
- `53` no publicado para `Pi-hole`

### `orangepi5-max`

Comandos:

```bash
ss -lntup
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
```

Puertos relevantes:

- `22/tcp` `SSH`
- sin servicios Docker publicados en esta fase
- `53` y `8202` libres para staged futuro

## Rangos reservados

- `80/443`: `Caddy/reverse proxy`
- `8080`: `Homepage` principal
- `8081`: `Emergency Homepage`
- `8100-8199`: `core infra UIs`
- `8200-8299`: `DNS/Pi-hole/red`
- `8300-8399`: `observability/alerting`
- `8400-8499`: `identity/security`
- `8500-8599`: `user apps`
- `8600-8699`: `media apps`
- `8700-8799`: `AI/agents`
- `8800-8899`: `admin tools/Docker`

## Conflictos actuales

- `orangepi5-ultra:8080` esta ocupado por `ntfy-local`
- por politica nueva, `8080` no debe usarse para `Pi-hole`
- `Pi-hole` secundario debe ir a `8201`

## Deudas de migracion

- `ntfy-local` en `orangepi5-ultra:8080` queda como `active debt`
- no se mueve en esta fase
- su migracion debe ocurrir en una fase dedicada de observability/alerting

## Politica de `Portainer`

- `Portainer Server` vivira en `management`
- `Portainer` y `Dockge` quedan como herramientas de operacion/visibilidad
- `Git + Docker Compose` queda como fuente de verdad para stacks
- `Portainer Agent` inicial solo se considera en:
  - `services`
  - `orangepi5-ultra`
  - `orangepi5-max`
  - `ai-gpu` cuando tenga workloads GPU
- `nas` queda opcional, solo si corre contenedores
- `orangepi5-a` y `orangepi5-b` quedan deferidos
- puertos reservados:
  - `Portainer Server` en `management`: `8800` preferido, `8843` alterno
  - `Portainer Agents`: solo por red privada/LAN/Tailscale, nunca publicos
- no se instala `Portainer` en esta fase

## Reconciliacion del primario `management`

Fuente de verdad local actualizada:

- `docs/colibri/ansible/host_vars/management.yml`
- `pihole_web_port: 8200`

Cambio operativo aplicado en `management`:

- backup de `/opt/stacks/pihole-primary/docker-compose.yml`
- cambio de `192.168.0.10:8080:80/tcp` a `192.168.0.10:8200:80/tcp`
- `docker compose up -d --force-recreate pihole`

Resultado:

- `docker ps` muestra:
  - `192.168.0.10:53->53/tcp`
  - `192.168.0.10:53->53/udp`
  - `192.168.0.10:8200->80/tcp`
- `ss -lntup` confirma `192.168.0.10:53` y `192.168.0.10:8200` escuchando

## Validacion `dig` y `curl`

Comandos:

```bash
dig +short @192.168.0.10 cloudflare.com
dig +short @192.168.0.10 google.com
curl -fsSI --max-time 5 http://192.168.0.10:8200/admin
```

Resultado:

- `cloudflare.com`: resuelve
- `google.com`: resuelve
- `http://192.168.0.10:8200/admin`: responde `HTTP/1.1 308 Permanent Redirect` a `/admin/`

## Puertos finales de `Pi-hole`

- primario:
  - DNS `192.168.0.10:53 tcp/udp`
  - UI `192.168.0.10:8200`
- secundario:
  - DNS `192.168.0.14:53 tcp/udp`
  - UI `192.168.0.14:8201`
- terciario opcional:
  - DNS `192.168.0.15:53 tcp/udp`
  - UI `192.168.0.15:8202`

## Veredicto

- `management` primario staged: `ready`
- `orangepi5-ultra` secundario: `not ready`, por conflicto con `ntfy-local`
- `orangepi5-max` terciario: `future`

Conclusion:

- repetir `05A` staged validation completa: `no-go` todavia
- siguiente paso sano:
  - reconciliar `orangepi5-ultra` a `8201`
  - mantener `ntfy-local` sin mover hasta su fase dedicada
