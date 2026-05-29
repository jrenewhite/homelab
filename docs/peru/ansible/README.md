# Peru Ansible

Base minima de automatizacion para la primera fase de `Perú`.

Esta carpeta clona solo lo necesario de `docs/colibri/ansible` para:

- estandarizar `SSH`
- fijar hostnames
- instalar paquetes base
- preparar `Docker`
- dejar `Tailscale` listo
- tener base de `Pi-hole` para la segunda mitad de la llegada o trabajo remoto posterior

Queda intencionalmente fuera en esta fase:

- `NAS`
- `NFS`
- `mergerfs`
- identidades compartidas de storage
- automatizacion del router
- `NUT`
- playbooks destructivos o de storage frio

## Uso esperado

```bash
cd docs/peru/ansible

ansible-playbook -i inventory/hosts.yml playbooks/bootstrap_ssh.yml
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap_hostname.yml
ansible-playbook -i inventory/hosts.yml playbooks/base_packages.yml
ansible-playbook -i inventory/hosts.yml playbooks/tailscale.yml -e tailscale_apply=true
ansible-playbook -i inventory/hosts.yml playbooks/containers_base.yml -e containers_apply=true
ansible-playbook -i inventory/hosts.yml playbooks/pihole.yml -e pihole_apply=true
```

## Notas

- el inventario usa las IPs objetivo propuestas para `Perú`
- si la subred final cambia, primero se corrige `inventory/hosts.yml` y `host_vars/`
- `pihole.yml` solo contempla:
  - `peru-management`
  - `peru-rpi5-ultra`
  - `peru-rpi5-max`
- `tailscale.yml` instala el agente y opcionalmente hace `up` solo si se proporciona una `auth key`
- los secretos no se versionan aqui
