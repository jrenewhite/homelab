# Microplan 05 — DNS y Pi-hole

## Propósito

Definir resolución DNS resiliente para la casa y administración segura de Pi-hole.

## Estado actual

- `Pi-hole` ya corre en prueba sobre:
  - `management` `192.168.0.161:53` con UI en `:8080`
  - `orangepi5-ultra` `192.168.0.151:53` con UI en `:8080`
  - `orangepi5-max` `192.168.0.152:53` con UI en `:8080`
- las tres instancias usan `OISD small` como baseline conservador
- el router aun no apunta a estos DNS; Internet sigue pasando por el router sin cambio de clientes
- `management` ya tiene el helper y script de rollback automático en dry-run lógico validado
- el router ya entrega:
  - DNS primario `192.168.0.161`
  - DNS secundario `192.168.0.151`
- el cutover real fue validado con `orangepi5-ultra` como canary y no requirió rollback

## Objetivo final

- `Pi-hole` primario en `management`
- `Pi-hole` secundario en `orangepi5-ultra`
- `orangepi5-max` como terciario opcional, no obligatorio
- `split-horizon DNS` local para que las mismas URLs globales resuelvan al proxy local de la sede

## Decisiones cerradas

- DNS del router apunta a:
  - `192.168.0.10`
  - `192.168.0.51`
- no se introduce VIP `keepalived` en la primera fase
- paneles de Pi-hole se gestionan por red privada/Tailscale
- `Colibrí` y `Perú` usarán las mismas URLs globales bajo `white-enciso.com`
- la respuesta DNS local por sede debe priorizar el proxy local
- el cutover DNS del router ocurre solo después de validar respuestas por IP directa
- no se cambia DNS del router en la misma ventana que reservas DHCP o cambios de IP finales

## Interfaces

- primario: `management`
- secundario: `orangepi5-ultra`
- controlador de cutover DNS: `management`
- canary principal de rollback: `orangepi5-ultra`
- canary secundario opcional: `orangepi5-max`
- secreto local esperado en `management`: `/opt/colibri-secrets/router.env`
- script operativo esperado en `management`: `/opt/colibri/bin/router-dns-cutover-with-rollback.sh`
- sincronización futura de listas y configuración: herramienta por definir en fase posterior, no bloquea el diseño

## Flujos

### Normal

- primero se valida `Pi-hole` por IP directa en modo staged, sin tocar router;
- clientes consultan primario;
- secundario absorbe parte de carga o failover práctico según cliente;
- DNS local resuelve `paperless`, `immich`, `jellyfin`, `navidrome`, `home` y `auth` hacia el proxy local.

### Falla

- si cae `management`, el secundario sigue resolviendo;
- si ambos caen, la red pierde filtrado DNS hasta restauración.
- si cae el enlace inter-sede, la resolución local sigue funcionando sin depender del otro sitio.
- si el cambio de DNS del router genera problema, rollback inmediato a DNS anterior del router

## Aceptación

- primario y secundario responden consultas locales por IP directa;
- la migración del router tiene un orden seguro documentado y rollback simple;
- configuración del router refleja ambos DNS solo despues de la validación staged;
- el diseño no depende de VIP desde el día uno.

## Dependencias previas

- red y direccionamiento final
- blackout y nodo `ultra` definidos

## Fuera de fase

- VIP `keepalived`
- anycast DNS
