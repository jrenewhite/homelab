# Microplan 02 Execution - Identities and Permissions

- Fecha de ejecución validada: `2026-05-26T23:06:49-06:00`
- Operador: `Codex`
- Estado: `completed`
- Resultado: `validated, no changes applied`

## Resumen

`Microplan 02` quedó validado sin aplicar cambios de identidades, grupos, `ACLs` ni `setgid`.

El único bloqueo previo era externo al microplan:

- `services` tenía mounts `NFS` caídos porque `/etc/fstab` todavía apuntaba al IP viejo `192.168.0.136`

Ese bloqueo ya había sido remediado antes de este rerun. Con los mounts restaurados:

- `apps` existe con `UID/GID 3000`
- `media_rw`, `media_ro`, `docs_rw`, `docs_ro` coinciden con el modelo esperado
- `jrenewhite` ya pertenece a `media_rw` y `docs_rw`
- `/srv/media` y `/srv/docs` en `nas` conservan `setgid` y `ACLs` correctos
- `root_squash` sigue activo
- el canary desde `services` pasó usando la identidad `apps`

No fue necesario:

- correr `shared_identity.yml`
- correr `nas_permissions.yml`
- tocar datos reales fuera de los directorios temporales canary
- tocar contenedores productivos, exports, mounts, DNS o red

## Nodos tocados

- `management` `192.168.0.10`
- `services` `192.168.0.12`
- `nas` `192.168.0.11`

## Comandos ejecutados

### Control machine

```bash
git status --short
sed -n '1,220p' docs/colibri/ansible/inventory/hosts.yml
date +%Y%m%d-%H%M%S
date --iso-8601=seconds
```

### Conectividad base

```bash
for h in 192.168.0.10 192.168.0.11 192.168.0.12; do
  ping -c 1 -W 2 "$h"
done
```

```bash
ssh -i /home/jrenewhite/.ssh/id_ed25519_jrenewhite jrenewhite@192.168.0.10 hostname
ssh -i /home/jrenewhite/.ssh/id_ed25519_jrenewhite root@192.168.0.11 hostname
ssh -i /home/jrenewhite/.ssh/id_ed25519_jrenewhite jrenewhite@192.168.0.12 hostname
```

### Snapshot lógico de identidades

```bash
ssh ... management '
hostname
id apps
getent group media_rw media_ro docs_rw docs_ro
id jrenewhite
'
```

```bash
ssh ... nas '
hostname
id apps
getent group media_rw media_ro docs_rw docs_ro
id jrenewhite
'
```

```bash
ssh ... services '
hostname
id apps
getent group media_rw media_ro docs_rw docs_ro
id jrenewhite
'
```

### Snapshot lógico de mounts y exports

```bash
ssh ... services '
findmnt /srv/media
findmnt /srv/docs
grep -E " /srv/(media|docs) " /proc/mounts
nfsstat -m
'
```

```bash
ssh ... nas '
stat -c "%n %U:%G %a" /srv/media
getfacl -p /srv/media
stat -c "%n %U:%G %a" /srv/docs
getfacl -p /srv/docs
exportfs -v
'
```

### Canary desde `services`

Se usó timestamp:

- `20260526-230522`

Creación:

```bash
sudo -u apps bash -lc '
umask 002
mkdir -p /srv/media/.colibri-canary-20260526-230522
mkdir -p /srv/docs/.colibri-canary-20260526-230522
touch /srv/media/.colibri-canary-20260526-230522/apps-write.txt
touch /srv/media/.colibri-canary-20260526-230522/apps-write-2.txt
touch /srv/docs/.colibri-canary-20260526-230522/apps-write.txt
touch /srv/docs/.colibri-canary-20260526-230522/apps-write-2.txt
'
```

Validación:

```bash
stat -c '%n %U:%G %a' /srv/media/.colibri-canary-20260526-230522 \
  /srv/media/.colibri-canary-20260526-230522/*

stat -c '%n %U:%G %a' /srv/docs/.colibri-canary-20260526-230522 \
  /srv/docs/.colibri-canary-20260526-230522/*
```

```bash
ssh ... nas '
getfacl -p /srv/media/.colibri-canary-20260526-230522
getfacl -p /srv/docs/.colibri-canary-20260526-230522
'
```

```bash
ssh ... services '
test -w /srv/media/.colibri-canary-20260526-230522 &&
test -w /srv/docs/.colibri-canary-20260526-230522 &&
echo "jrenewhite rw ok"
'
```

Limpieza:

```bash
rm -rf /srv/media/.colibri-canary-20260526-230522 \
       /srv/docs/.colibri-canary-20260526-230522
```

## Evidencia previa

### Inventario

- `docs/colibri/ansible/inventory/hosts.yml` apunta a:
  - `management` `192.168.0.10`
  - `nas` `192.168.0.11`
  - `services` `192.168.0.12`

### Identidades compartidas

En `management`, `services` y `nas`:

- `apps`: `uid=3000 gid=3000`
- `media_rw`: `gid=3100`
- `media_ro`: `gid=3101`
- `docs_rw`: `gid=3200`
- `docs_ro`: `gid=3201`
- `jrenewhite` pertenece a `media_rw` y `docs_rw`

### `nas`

`/srv/media`

- owner/group: `apps:media_rw`
- mode: `2775`
- `setgid` activo
- `ACLs` presentes para `apps`, `media_rw`, `media_ro`

`/srv/docs`

- owner/group: `apps:docs_rw`
- mode: `2775`
- `setgid` activo
- `ACLs` presentes para `apps`, `docs_rw`, `docs_ro`

`exportfs -v`

- `/srv/media` exportado con `root_squash`
- `/srv/docs` exportado con `root_squash`

### `services`

- `/srv/media` montado desde `192.168.0.11:/srv/media`
- `/srv/docs` montado desde `192.168.0.11:/srv/docs`
- `nfsstat -m` refleja ambos mounts con `vers=4.2`

## Resultado del canary

### Escritura como `apps`

En `/srv/media`:

- directorio: `apps:media_rw` `2775`
- archivos nuevos: `apps:media_rw` `664`

En `/srv/docs`:

- directorio: `apps:docs_rw` `2775`
- archivos nuevos: `apps:docs_rw` `664`

### Herencia por `setgid`

Validada correctamente:

- el grupo heredado en `media` fue `media_rw`
- el grupo heredado en `docs` fue `docs_rw`

### ACLs RW/RO

Validadas por metadata en `nas`:

- `media_ro` aparece con `r-x` en el canary de `media`
- `docs_ro` aparece con `r-x` en el canary de `docs`
- `media_rw` y `docs_rw` aparecen con `rwx`

### Acceso de `jrenewhite`

- `jrenewhite rw ok`

### Root remoto

- no se necesitó `root` remoto para escribir sobre `NFS`
- la escritura se hizo desde `services` usando la identidad local `apps`

## Dry-runs y cambios aplicados

- `shared_identity.yml --check --diff`: no ejecutado
- `nas_permissions.yml --check --diff`: no ejecutado
- cambios aplicados al modelo de identidades/permisos: ninguno

Razón:

- no hubo desviación real en UID/GID, grupos, membresías, `ACLs` o `setgid`
- el sistema ya coincidía con el estado objetivo

## Archivos canary creados y eliminados

Rutas creadas:

- `/srv/media/.colibri-canary-20260526-230522`
- `/srv/docs/.colibri-canary-20260526-230522`

Archivos creados:

- `apps-write.txt`
- `apps-write-2.txt`

Limpieza:

- ambos directorios y sus archivos fueron eliminados
- verificado desde `services` y `nas`

## Anomalías

- `services` no tiene `getfacl` instalado localmente
- no fue bloqueante porque las `ACLs` del canary se verificaron desde `nas`
- `ansible` no está instalado en la máquina de control actual; por eso la ejecución se hizo por `ssh` directo

## Rollback

No fue necesario.

- no se aplicaron cambios persistentes al modelo de identidades/permisos
- solo se limpiaron los directorios canary

## Recomendación

- `Microplan 03`: `go`

No quedan bloqueos de `Microplan 02` en identidades y permisos.
