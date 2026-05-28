# Microplan 03B Execution - Sync Normalization and Local-First Matrix

- Fecha de ejecución: `2026-05-27`
- Operador: `Codex`
- Estado: `completed staged validation`
- Resultado: `go for next subphase of Microplan 03; no-go for Microplan 04`

## Resumen

Se ejecutó la subfase `03B` para cerrar dos cosas:

1. validar una política reproducible de sync final para `docs` y `media`
2. crear la matriz `local-first` por servicio para `Colibrí`

Resultado:

- la normalización explícita por destino sí funciona
- `docs` puede quedar en destino como `apps:docs_rw`, directorios `2775`, archivos `664`
- `media` puede quedar en destino como `apps:media_rw`, directorios `2775`, archivos `664`
- no se tocaron datos reales ni servicios productivos
- los canaries fueron limpiados al final
- la matriz `local-first` por servicio quedó documentada

## Nodos tocados

- `services` `192.168.0.12`
- `nas` `192.168.0.11`

## Comandos ejecutados

### Prechecks

```bash
ping -c 1 -W 2 192.168.0.11
ping -c 1 -W 2 192.168.0.12
```

```bash
ssh ... services '
findmnt /storage /srv/media /srv/docs
df -h /storage /srv/media /srv/docs
'
```

### Canary local

Creación de canaries locales:

```bash
sudo -u apps bash -lc '
umask 002
mkdir -p /storage/sync-out/docs-canary /storage/sync-out/media-canary
printf "docs-normalization-test\n" > /storage/sync-out/docs-canary/canary.txt
printf "media-normalization-test\n" > /storage/sync-out/media-canary/canary.txt
'
```

Estado local validado:

```bash
stat -c '%n %U:%G %a' \
  /storage/sync-out/docs-canary \
  /storage/sync-out/docs-canary/canary.txt \
  /storage/sync-out/media-canary \
  /storage/sync-out/media-canary/canary.txt
```

### Sync normalization - dry-run

#### Docs

```bash
sudo -u apps rsync -avhn \
  --chown=apps:docs_rw \
  --chmod=D2775,F664 \
  /storage/sync-out/docs-canary/ \
  /srv/docs/.colibri-syncnorm-docs/
```

#### Media

```bash
sudo -u apps rsync -avhn \
  --chown=apps:media_rw \
  --chmod=D2775,F664 \
  /storage/sync-out/media-canary/ \
  /srv/media/.colibri-syncnorm-media/
```

### Sync normalization - copia mínima real

#### Docs

```bash
sudo -u apps rsync -avh \
  --chown=apps:docs_rw \
  --chmod=D2775,F664 \
  /storage/sync-out/docs-canary/ \
  /srv/docs/.colibri-syncnorm-docs/
```

#### Media

```bash
sudo -u apps rsync -avh \
  --chown=apps:media_rw \
  --chmod=D2775,F664 \
  /storage/sync-out/media-canary/ \
  /srv/media/.colibri-syncnorm-media/
```

### Validación posterior

Desde `services`:

```bash
stat -c '%n %U:%G %a' \
  /srv/docs/.colibri-syncnorm-docs \
  /srv/docs/.colibri-syncnorm-docs/canary.txt \
  /srv/media/.colibri-syncnorm-media \
  /srv/media/.colibri-syncnorm-media/canary.txt
```

Desde `nas`:

```bash
getfacl -p /srv/docs/.colibri-syncnorm-docs
getfacl -p /srv/media/.colibri-syncnorm-media
```

### Limpieza

```bash
sudo -u apps rm -rf \
  /storage/sync-out/docs-canary \
  /storage/sync-out/media-canary \
  /srv/docs/.colibri-syncnorm-docs \
  /srv/media/.colibri-syncnorm-media
```

## Comandos rsync recomendados

### Docs

```bash
sudo -u apps rsync -avh \
  --chown=apps:docs_rw \
  --chmod=D2775,F664 \
  SRC/ /srv/docs/DEST/
```

### Media

```bash
sudo -u apps rsync -avh \
  --chown=apps:media_rw \
  --chmod=D2775,F664 \
  SRC/ /srv/media/DEST/
```

Lectura:

- la política de sync final ya no depende de preservar owner/grupo del staging
- el destino se normaliza según clase de archivo final

## Evidencia de owner/grupo/modo

### Docs

Validado en destino:

- directorio: `apps:docs_rw` `2775`
- archivo: `apps:docs_rw` `664`

`getfacl` básico:

- `group:docs_rw:rwx`
- `group:docs_ro:r-x`
- `setgid` presente

### Media

Validado en destino:

- directorio: `apps:media_rw` `2775`
- archivo: `apps:media_rw` `664`

`getfacl` básico:

- `group:media_rw:rwx`
- `group:media_ro:r-x`
- `setgid` presente

## Matriz creada

Documento creado:

- [colibri-service-local-first-matrix.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-service-local-first-matrix.md)

Incluye, por servicio:

- servicio
- nodo previsto en `Colibrí`
- runtime caliente
- staging/cache local
- destino final en `nas`
- tipo de sync
- si debe arrancar con `nas` dormido
- observaciones/riesgos

Fuente usada:

- secciones `7` a `13` de [white-enciso-multisite.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-multisite.md)

## Anomalías

1. `sync-out` local usa `apps:apps`, lo cual es correcto para runtime local, pero insuficiente como metadata final.
2. La subfase anterior ya había demostrado que un `rsync` naive preserva `apps:apps`; esta subfase confirmó que la normalización explícita corrige el problema.
3. La matriz por servicio sigue siendo de arquitectura y preparación; todavía no implica mover ningún servicio real.

## Confirmación de limpieza

Se confirmó que al cierre:

- `/storage/sync-out/docs-canary` no existe
- `/storage/sync-out/media-canary` no existe
- `/srv/docs/.colibri-syncnorm-docs` no existe
- `/srv/media/.colibri-syncnorm-media` no existe

## Docs actualizados

- [03-storage-local-first.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-microplans/03-storage-local-first.md)
- [colibri-service-local-first-matrix.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-service-local-first-matrix.md)
- [03b-goal-exec-sync-normalization.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-goal-executions/03b-goal-exec-sync-normalization.md)

## Recomendación

- siguiente subfase de `Microplan 03`: `go`
- `Microplan 04`: `no-go`

Razón:

- la política reproducible de sync final ya quedó validada
- la arquitectura por servicio ya quedó mapeada
- todavía falta una subfase donde se seleccione y migre un primer servicio real de forma controlada, sin saltar aún a energía/blackout
