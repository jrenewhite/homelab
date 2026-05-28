# Goal Execution 04F.1 — ntfy Local-Only Alert Receiver

Fecha de ejecucion: `2026-05-28`  
Modo: `local LAN receiver`

## Objetivo

Desplegar `ntfy` como receptor local de alertas para eventos `NUT`, preferentemente en `orangepi5-ultra`, sin exposicion publica y sin afectar el logger local ni el modo observacion de `NUT`.

## Restricciones respetadas

- no se avanzo a `04G`
- no se habilito shutdown real
- no se probo blackout
- no se desconecto la UPS
- no se enviaron magic packets
- no se hizo wake/sleep
- no se tocaron:
  - DNS
  - router
  - `Pi-hole`
  - `Caddy`
  - `cloudflared`
  - `SSO`
  - `NFS`
  - mounts
  - apps productivas

## Nodo receptor

- `orangepi5-ultra` `192.168.0.14`

## Despliegue de `ntfy`

Se desplego en `orangepi5-ultra` usando Docker.

Contenedor:

- nombre: `ntfy-local`
- imagen: `binwiederhier/ntfy:latest`
- restart policy: `unless-stopped`

Binding:

- `192.168.0.14:8080 -> container:80`

Lectura:

- solo escucha en la IP LAN del nodo
- no se publico por Internet
- no se integro con proxy publico

## Storage local

Rutas locales creadas en `orangepi5-ultra`:

- `/storage/apps/ntfy/cache`
- `/storage/apps/ntfy/etc`
- `/storage/apps/ntfy/data`

Config de servidor:

- `/storage/apps/ntfy/etc/server.yml`

Contenido relevante:

```yaml
base-url: http://192.168.0.14:8080
listen-http: ":80"
cache-file: /var/cache/ntfy/cache.db
behind-proxy: false
```

## Topic y secretos

Se eligio topic no trivial:

- `colibri-ups-33883960f764a3bf`

No se guardo en git.  
Se distribuyo como URL completa en:

- `/opt/colibri-secrets/ntfy.env`

Nodos con `ntfy.env`:

- `management`
- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

Contenido:

```bash
NTFY_URL=http://192.168.0.14:8080/colibri-ups-33883960f764a3bf
```

Permisos:

- `600`
- `root:root`

No se configuro token adicional en esta fase.

## Eventos sinteticos probados

### Desde `management`

Se ejecuto:

```bash
NOTIFYTYPE=ONBATT UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic local-ntfy validation from management"
```

Evidencia journal local:

```text
host=management role=master type=ONBATT ups=linkedpro msg=synthetic local-ntfy validation from management
```

### Desde `services`

Se ejecuto:

```bash
NOTIFYTYPE=COMMOK UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic local-ntfy validation from services"
```

Evidencia journal local:

```text
host=services role=client type=COMMOK ups=linkedpro msg=synthetic local-ntfy validation from services
```

## Evidencia de recepcion en `ntfy`

No se uso receptor publico ni app externa en esta fase.  
La evidencia del lado receptor quedo en logs del contenedor:

```text
Listening on :80[http], ntfy 2.23.0
Server stats (... messages_cached=2, messages_published=2, topics_active=1 ...)
```

Lectura:

- el receptor local estaba arriba
- recibio exactamente 2 publicaciones
- coincide con las 2 pruebas sinteticas ejecutadas

## Estado del logger local

El logger local sigue funcionando aun si `ntfy` faltara o fallara:

- primero escribe a `logger -t nut-event`
- luego intenta `curl` solo si existe `NTFY_URL`
- si `curl` falla, registra `ntfy=failed`
- no bloquea `NUT`

## Estado final de `NUT`

### `management`

- `nut-server`: `active`
- `nut-monitor`: `active`

`upsc linkedpro@localhost`:

```text
battery.charge: 100
input.voltage: 117.8
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

### Clientes

Siguen activos en observacion:

- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

## Anomalias

- no se configuro token extra; la seguridad de esta fase depende de:
  - binding solo LAN
  - topic no trivial
  - ausencia de exposicion publica
- la lectura directa del topic por `curl` no se uso como evidencia final; fue mas confiable tomar evidencia del receptor desde `docker logs`

## Conclusion

`04F.1` queda cerrado con `ntfy` local funcionando como receptor LAN:

- receptor desplegado en `orangepi5-ultra`
- URL local definida
- `ntfy.env` distribuido fuera de git
- pruebas sinteticas enviadas
- evidencia de recepcion confirmada
- `NUT` sigue estable

## Deuda tecnica controlada

- `ntfy-local` se acepta aqui como despliegue funcional inicial para destrabar alertas locales
- temporalmente se tolera como contenedor Docker directo/manual en `orangepi5-ultra`
- esto no redefine la gobernanza futura de contenedores del homelab
- antes de escalar mas servicios, `ntfy` debe migrarse a un stack `Docker Compose` versionado
- los secretos deben seguir fuera de git, por ejemplo en `/opt/colibri-secrets`
- la fuente de verdad futura debe ser el repo, no `Portainer`
- `Portainer` o `Dockge` podran servir despues como herramientas de operacion/visibilidad desde `management`, pero no como el mecanismo principal para definir stacks
- `orangepi5-ultra` y los demas nodos deben mantenerse operables en modo `headless` con stacks versionados
- deuda sugerida para cierre:
  - `Microplan 07`
  - `Microplan 08`
  - `Microplan 11`
  - o una subfase dedicada de `Docker stack governance`

## Recomendacion

Go/no-go para `04G`:

- `go`
