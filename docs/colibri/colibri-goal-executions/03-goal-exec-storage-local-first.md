# Microplan 03 Execution - Storage Local-First

- Fecha de ejecución: `2026-05-26T23:44:29-06:00`
- Operador: `Codex`
- Estado: `completed staged validation`
- Resultado: `go for next phase of Microplan 03; no-go for Microplan 04 yet`

## Resumen

Se ejecutó `Microplan 03` en modo `staged`, sin mover apps productivas ni datos reales.

Se validó que:

- `services` tiene storage local disponible y amplio en `/storage`
- `services` sigue montando `NFS` desde `nas` en `/srv/media` y `/srv/docs`
- las identidades compartidas siguen correctas
- se pudieron preparar rutas locales base para el modelo `local-first`
- un canary local en `/storage/sync-out` funcionó correctamente
- un `rsync --dry-run` y una copia mínima real hacia `/srv/docs` funcionaron

Brecha importante detectada:

- un sync ingenuo desde `/storage/sync-out` hacia `/srv/docs` preserva `apps:apps` en el destino final
- eso no rompe el acceso por `ACL`, pero no normaliza el grupo archivístico final (`docs_rw`)
- por tanto, el modelo `local-first` queda preparado, pero la política concreta de sync/normalización todavía necesita cerrarse antes de mover servicios reales

## Nodos tocados

- `services` `192.168.0.12`
- `nas` `192.168.0.11`

## Comandos ejecutados

### Prechecks

```bash
git status --short
ping -c 1 -W 2 192.168.0.11
ping -c 1 -W 2 192.168.0.12
```

```bash
ssh ... root@192.168.0.11 hostname
ssh ... jrenewhite@192.168.0.12 hostname
```

```bash
ssh ... services '
id apps
getent group media_rw media_ro docs_rw docs_ro
id jrenewhite
findmnt /storage
findmnt /srv/media
findmnt /srv/docs
df -h /storage /srv/media /srv/docs
ls -ld /storage /srv/media /srv/docs
'
```

### Inventario no intrusivo del estado local

```bash
ssh ... services '
find /storage -maxdepth 2 -mindepth 1 -type d | sort | sed -n "1,120p"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
'
```

Resultado:

- no había contenedores corriendo en `services` en esta ventana

### Preparación de rutas locales base

Se crearon o validaron:

```bash
sudo install -d -o apps -g apps     -m 2775 /storage/apps
sudo install -d -o apps -g apps     -m 2775 /storage/cache
sudo install -d -o apps -g apps     -m 2775 /storage/sync-out
sudo install -d -o apps -g media_rw -m 2775 /storage/media-staging
sudo install -d -o apps -g docs_rw  -m 2775 /storage/inbox
```

### Canary local

Timestamp usado:

- `20260527-054228`

Creación:

```bash
sudo -u apps bash -lc '
umask 002
mkdir -p /storage/sync-out/.colibri-canary-20260527-054228
printf "local-first-canary\n" > /storage/sync-out/.colibri-canary-20260527-054228/canary.txt
'
```

Validación:

```bash
stat -c '%n %U:%G %a' \
  /storage/apps \
  /storage/cache \
  /storage/inbox \
  /storage/media-staging \
  /storage/sync-out \
  /storage/sync-out/.colibri-canary-20260527-054228 \
  /storage/sync-out/.colibri-canary-20260527-054228/canary.txt
```

### Canary sync

Dry-run:

```bash
sudo -u apps rsync -avhn \
  /storage/sync-out/.colibri-canary-20260527-054228/ \
  /srv/docs/.colibri-canary-20260527-054228/
```

Prueba mínima real:

```bash
sudo -u apps rsync -avh \
  /storage/sync-out/.colibri-canary-20260527-054228/ \
  /srv/docs/.colibri-canary-20260527-054228/
```

Validación posterior:

```bash
stat -c '%n %U:%G %a' \
  /srv/docs/.colibri-canary-20260527-054228 \
  /srv/docs/.colibri-canary-20260527-054228/canary.txt
```

```bash
ssh ... nas '
getfacl -p /srv/docs/.colibri-canary-20260527-054228
stat -c "%n %U:%G %a" \
  /srv/docs/.colibri-canary-20260527-054228 \
  /srv/docs/.colibri-canary-20260527-054228/canary.txt
'
```

### Limpieza

```bash
sudo -u apps rm -rf \
  /storage/sync-out/.colibri-canary-20260527-054228 \
  /srv/docs/.colibri-canary-20260527-054228
```

## Rutas validadas

### Locales en `services`

- `/storage`
- `/storage/apps`
- `/storage/cache`
- `/storage/inbox`
- `/storage/media-staging`
- `/storage/sync-out`

### Finales en `nas`

- `/srv/media`
- `/srv/docs`

### Mounts NFS activos

- `192.168.0.11:/srv/media -> /srv/media`
- `192.168.0.11:/srv/docs -> /srv/docs`

## Espacio disponible

Al momento del barrido:

- `/storage`: `938G` total, `886G` disponibles
- `/srv/media`: `12T` total, `~12T` disponibles
- `/srv/docs`: `3.7T` total, `3.6T` disponibles

## Resultado del canary local

Rutas locales base quedaron así:

- `/storage/apps` -> `apps:apps` `2775`
- `/storage/cache` -> `apps:apps` `2775`
- `/storage/inbox` -> `apps:docs_rw` `2775`
- `/storage/media-staging` -> `apps:media_rw` `2775`
- `/storage/sync-out` -> `apps:apps` `2775`

Canary local:

- directorio: `/storage/sync-out/.colibri-canary-20260527-054228` -> `apps:apps` `2775`
- archivo: `canary.txt` -> `apps:apps` `664`

Lectura:

- la identidad `apps` puede trabajar localmente sobre `/storage/sync-out`
- `services` ya tiene una base local clara para el patrón `local-first`

## Resultado del canary sync

### Dry-run

- exitoso como `apps`
- confirmó ruta de origen y destino válidas

### Prueba mínima real

- exitosa como `apps`
- el canary llegó a `/srv/docs`

### Hallazgo de permisos finales

El canary remoto quedó como:

- directorio: `apps:apps` `2775`
- archivo: `apps:apps` `664`

Y en `nas` las `ACLs` del directorio muestran:

- `group:docs_rw:rwx`
- `group:docs_ro:r-x`

Lectura:

- el acceso efectivo no se rompe
- pero la sincronización naive preserva grupo `apps`, no normaliza al grupo archivístico `docs_rw`

## Brechas encontradas

1. `sync-out` con `apps:apps` funciona para runtime local, pero no es suficiente para inferir política final de archivo.
2. Un `rsync` naive preserva `apps:apps` en el destino final, lo que contradice la intención de tener archivo final más claramente alineado a `docs_rw` o `media_rw`.
3. La política exacta de normalización post-sync todavía no está cerrada:
   - si se corrige en el destino
   - si se usa otro grupo en staging
   - si el job de sync debe aplicar `chgrp/chmod/setfacl` controlado
4. `services` no tenía contenedores corriendo en esta ventana, así que no hubo evidencia de dependencia runtime actual sobre `NFS`; eso reduce riesgo, pero no sustituye una auditoría por servicio cuando toque mover apps reales.

## Restricciones respetadas

- no se tocaron apps productivas
- no se movieron datos reales
- no se cambió `DNS`, router, `Pi-hole`, `Caddy`, `Cloudflare`, `SSO` ni red
- no se tocaron exports ni layout de `nas`
- no se implementaron jobs automáticos ni auto-sleep

## Docs actualizados

- `docs/colibri/colibri-inventory.md`
- `docs/colibri/colibri-goal-executions/03-goal-exec-storage-local-first.md`

## Recomendación

- siguiente fase de `Microplan 03`: `go`
- `Microplan 04`: `no-go` todavía

Razón:

- el patrón `local-first` ya tiene base local preparada y validada
- pero antes de mover servicios reales hace falta cerrar cómo se normaliza el ownership/grupo del archivo final en `nas` durante el sync
