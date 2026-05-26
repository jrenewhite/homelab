# Colibri Ansible

Base de automatizacion para la fase 1 de `Colibri`.

## Objetivos

- Estandarizar acceso por `SSH`
- Fijar hostnames
- Preparar base de paquetes y servicios
- Declarar y reflejar el layout objetivo del `NAS`
- Dejar lista la configuracion para `NFS`, `NUT` y contenedores

## Uso esperado

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/bootstrap_ssh.yml
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/bootstrap_hostname.yml
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/base_packages.yml
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/shared_identity.yml -e shared_identity_apply=true
```

Playbooks con riesgo o cambios destructivos se dejan protegidos por variables de activacion:

- `nas_storage_apply=true`
- `nas_mergerfs_apply=true`
- `nas_exports_apply=true`
- `shared_identity_apply=true`
- `nas_permissions_apply=true`

## Notas

- El inventario usa las IPs actuales verificadas por `SSH`.
- `desired_ip` guarda la IP objetivo para reservas DHCP en el router.
- `ansible_user` base es `jrenewhite`.
- `nas` queda como excepcion temporal con `root` por `SSH key`, porque `OMV` no acepto de forma consistente `jrenewhite` por llave en esta fase.
- El `NAS` ya corre en vivo con:
  - `media-cold` en `md0` `xfs`
  - `media-warm` en `nvme2n1` `btrfs`
  - `docs-cold` en `md1` `ext4`
  - `docs-warm` en `nvme0n1` `btrfs`
  - `mergerfs` unificando `/srv/media` y `/srv/docs`
  - `NFS` exportando ambos namespaces con `fsid`
- `services` ya monta `/srv/media` y `/srv/docs` desde `nas`.
- `containers_base.yml` instala:
  - en `Ubuntu`: `docker.io` y `docker-compose-v2`
  - en `Debian/Armbian`: `docker.io` y `docker-compose`
- `nut_core.yml` instala `ansible`, `nut-client` y `nut-server` en `management`, pero la configuracion del UPS sigue pendiente.
- `shared_identity.yml` crea identidades compartidas con `UID/GID` fijos para que `NFS` no rompa permisos entre hosts.
- `nas_permissions.yml` aplica politica de `groups + setgid + ACLs` sobre `media/docs`.
