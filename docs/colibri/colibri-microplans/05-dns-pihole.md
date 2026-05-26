# Microplan 05 — DNS y Pi-hole

## Propósito

Definir resolución DNS resiliente para la casa y administración segura de Pi-hole.

## Estado actual

- no hay despliegue documentado final de Pi-hole
- `management` y `orangepi5-ultra` están destinados a primario/secundario

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

## Interfaces

- primario: `management`
- secundario: `orangepi5-ultra`
- sincronización futura de listas y configuración: herramienta por definir en fase posterior, no bloquea el diseño

## Flujos

### Normal

- clientes consultan primario;
- secundario absorbe parte de carga o failover práctico según cliente;
- DNS local resuelve `paperless`, `immich`, `jellyfin`, `navidrome`, `home` y `auth` hacia el proxy local.

### Falla

- si cae `management`, el secundario sigue resolviendo;
- si ambos caen, la red pierde filtrado DNS hasta restauración.
- si cae el enlace inter-sede, la resolución local sigue funcionando sin depender del otro sitio.

## Aceptación

- primario y secundario responden consultas locales;
- configuración del router ya refleja ambos DNS;
- el diseño no depende de VIP desde el día uno.

## Dependencias previas

- red y direccionamiento final
- blackout y nodo `ultra` definidos

## Fuera de fase

- VIP `keepalived`
- anycast DNS
