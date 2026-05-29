# Microplan 06A.1 — Migracion de `ntfy-local` al rango de alerting

## Resumen

`06A.1` migra `ntfy-local` en `orangepi5-ultra` desde `192.168.0.14:8080` a `192.168.0.14:8300`, para alinear la operacion con el `port registry` y liberar `8080` para el `Homepage` principal.

La migracion se hizo sin tocar `router`, `Pi-hole`, `Caddy`, `NUT` ni otros contenedores.

## Estado previo

- nodo: `orangepi5-ultra`
- contenedor: `ntfy-local`
- exposicion previa:
  - `192.168.0.14:8080 -> 80/tcp`
- deuda tecnica ya conocida:
  - despliegue directo/manual por Docker
  - no migrado aun a `Docker Compose` versionado

## Descubrimiento y backup

Se confirmo que `ntfy-local` no estaba gestionado por `Compose`, pero si usaba persistencia local:

- `/storage/apps/ntfy/etc -> /etc/ntfy`
- `/storage/apps/ntfy/cache -> /var/cache/ntfy`

Backups/documentacion local creada en `orangepi5-ultra`:

- `server.yml.<timestamp>.bak`
- `docker-inspect.<timestamp>.json`

## Cambios aplicados

### Contenedor `ntfy-local`

Se actualizo:

- `/storage/apps/ntfy/etc/server.yml`

Cambio efectivo:

```yaml
base-url: http://192.168.0.14:8300
listen-http: :80
```

Luego se recreo solo el contenedor `ntfy-local` con el nuevo binding:

```bash
docker rm -f ntfy-local
docker run -d --name ntfy-local --restart unless-stopped \
  -p 192.168.0.14:8300:80 \
  -v /storage/apps/ntfy/etc:/etc/ntfy \
  -v /storage/apps/ntfy/cache:/var/cache/ntfy \
  binwiederhier/ntfy serve
```

### Secrets locales

Se actualizo `/opt/colibri-secrets/ntfy.env` en:

- `management`
- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

Valor efectivo:

```bash
NTFY_URL=http://192.168.0.14:8300/colibri-ups-33883960f764a3bf
```

No se cambiaron topic ni token.

## Validacion

### Puertos y reachability

```bash
curl -fsSI http://192.168.0.14:8300/
curl -fsSI http://192.168.0.14:8080/
```

Resultado:

- `http://192.168.0.14:8300/` -> `HTTP/1.1 200 OK`
- `http://192.168.0.14:8080/` -> sin respuesta de `ntfy-local`

Conclusion:

- `8300` queda operativo
- `8080` queda libre para `Homepage`

### Estado de `NUT`

En `management`:

- `nut-server`: `active`
- `nut-monitor`: `active`

En `services`:

- `nut-monitor`: `active`

### Pruebas sinteticas no destructivas

Desde `management`:

- `ONBATT` sintetico

Desde `services`:

- `COMMOK` sintetico

Eventos visibles en `journal`:

```text
May 29 05:27:48 management nut-event[...] host=management role=master type=ONBATT ups=linkedpro msg=synthetic-06a1-management-root
May 29 05:27:48 services nut-event[...] host=services role=client type=COMMOK ups=linkedpro msg=synthetic-06a1-services-root
```

Evidencia en `ntfy-local`:

- `docker logs` mostro incremento de `messages_published`
- tras la migracion se observaron estadisticas como:
  - `messages_published=5`

### Logger local ante fallo de `ntfy`

Se forzo un fallo controlado usando un `NTFY_URL` invalido.

Resultado:

- el hook siguio registrando `nut-event` localmente
- el fallo externo no bloqueo la parte local del logger

## Caveats

- la ejecucion manual del hook como usuario no privilegiado no puede leer `/opt/colibri-secrets/ntfy.env`
- para validar entrega real post-migracion se uso ejecucion privilegiada
- esto no cambia la politica `NUT`, pero conviene dejarlo visible como detalle operativo
- `ntfy-local` sigue como contenedor directo/manual; la deuda de migrarlo a `Compose` versionado sigue abierta

## Veredicto

- puerto anterior: `192.168.0.14:8080`
- puerto nuevo: `192.168.0.14:8300`
- `ntfy.env` actualizado en los 5 nodos con `upsmon`
- `curl` de salud: `ok`
- pruebas sinteticas: `ok`
- `NUT` final: sano
- `8080`: libre para `Homepage`

## Recomendacion

- `06B` conectar primer backend real local: `go`
- sin mover aun `ntfy-local` a `Compose` versionado dentro de esta fase
