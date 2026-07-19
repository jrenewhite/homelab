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

- `NFS`
- `mergerfs`
- identidades compartidas de storage
- automatizacion del router
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

- el inventario usa `ansible_host` por Tailscale (`100.x`) para operar remoto
- `desired_ip` conserva la reserva LAN objetivo en `192.168.0.0/24`
- si la subred final cambia, primero se corrige `desired_ip` en `inventory/hosts.yml` y los `host_vars/`
- `pihole.yml` solo contempla:
  - `peru-rpi5-a`
  - `peru-rpi4-a`
- `peru-services` absorbe el control plane operativo y queda como `NUT` master por conexion USB a ambos `UPS`
- `Caddy` primario futuro vive en `peru-services`; `peru-rpi5-a` puede quedar como standby si se necesita
- `peru-rpi5-b` queda fuera de roles criticos hasta recuperacion fisica; intento remoto de rootfs en SSD no volvio por Tailscale
- `tailscale.yml` instala el agente y opcionalmente hace `up` solo si se proporciona una `auth key`
- los secretos no se versionan aqui
