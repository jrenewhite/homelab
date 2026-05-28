### Nota de deuda técnica: gobierno de stacks Docker

`ntfy-local` queda aceptado como despliegue funcional inicial para desbloquear alertas locales de `NUT`.

Este despliegue no representa el modelo final de operación. La dirección aprobada es:

- `git` será la fuente de verdad para stacks Docker/Compose;
- los archivos Compose vivirán versionados en el repo;
- los secretos vivirán fuera de git, por ejemplo en `/opt/colibri-secrets`;
- `Portainer`/`Dockge` podrán usarse como herramientas de operación y visibilidad desde `management`;
- los nodos secundarios, como `orangepi5-ultra`, deberán poder operar en modo headless;
- ningún servicio debe depender de configuración manual no documentada para ser reconstruible.

Esta deuda se cerrará en la fase de transición Ansible/Git/Docker governance antes de escalar más servicios.

### Nota de deuda técnica: boot delay de `services` por `wait-online`

En la prueba real de `WOL` sobre `services`, el nodo volvió por `ping` mucho antes de volver por `SSH`.

La causa observada no fue `cloud-init`:

- `cloud-init` está deshabilitado por marker file
- el cuello de botella real es `systemd-networkd-wait-online.service`

Hallazgo factual:

- `enp2s0` queda `routable` y es la interfaz LAN activa
- `enp3s0` queda `no-carrier`, pero sigue marcado como `Required For Online: yes`
- `systemd-networkd-wait-online` espera por `enp2s0` y `enp3s0`
- al no levantar `enp3s0`, el servicio agota su timeout de ~2 minutos
- `ssh.service` termina arrancando justo después de ese timeout

Impacto:

- no rompe la operación estable una vez que `services` ya está arriba
- sí degrada:
  - tiempos de recuperación tras `WOL`
  - reinicios controlados
  - ventanas de mantenimiento
  - pruebas energéticas futuras

Dirección futura sugerida:

- revisar `netplan` / `systemd-networkd` en `services`
- dejar `enp3s0` como no requerido para `network-online.target` si sigue sin uso activo
- validar que solo `enp2s0` bloquee el online del nodo

Estado:

- deuda técnica conocida
- no urgente
- safe de diferir mientras no dependamos de cold boots/WOL frecuentes
