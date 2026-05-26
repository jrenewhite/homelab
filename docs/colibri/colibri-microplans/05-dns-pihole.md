# Microplan 05 — DNS y Pi-hole

## Propósito

Definir resolución DNS resiliente para la casa y administración segura de Pi-hole.

## Estado actual

- la arquitectura staged de `Pi-hole` queda fijada en:
  - `management` `192.168.0.10:53`
  - `orangepi5-ultra` `192.168.0.14:53`
  - `orangepi5-max` `192.168.0.15:53`
- las tres instancias usan `OISD small` como baseline conservador
- el `ER707-M2` sigue siendo la única autoridad DHCP de la red
- tras importar reservas DHCP, varios nodos del homelab siguen temporalmente en leases previos; no se asume todavía que ya respondan en sus IP finales
- `management` ya tiene el helper y script de rollback automático en dry-run lógico validado
- el aprendizaje operativo más importante fue:
  - no volver a mezclar cambio de DNS del router con cambios de IP o reservas DHCP
  - no usar dos `Pi-hole` internos como DNS primario/secundario del router en la primera etapa
  - mantener un resolvedor público de emergencia como respaldo inmediato

## Objetivo final

- `Pi-hole` primario en `management`
- `Pi-hole` secundario en `orangepi5-ultra`
- `orangepi5-max` como terciario opcional, no obligatorio
- `split-horizon DNS` local para que las mismas URLs globales resuelvan al proxy local de la sede

## Decisiones cerradas

- el router mantiene siempre el servicio DHCP; `Pi-hole` no reemplaza DHCP en ninguna fase
- el router entrega DNS por DHCP así:
  - `DNS1` = `Pi-hole` primario cuando esté validado
  - `DNS2` = `1.1.1.1` como fallback de emergencia
- `orangepi5-ultra` sigue siendo `Pi-hole` secundario de la arquitectura, pero no será `DNS2` del router en la primera etapa
- no se introduce VIP `keepalived` en la primera fase
- paneles de Pi-hole se gestionan por red privada/Tailscale
- `Colibrí` y `Perú` usarán las mismas URLs globales bajo `white-enciso.com`
- la respuesta DNS local por sede debe priorizar el proxy local
- el cutover DNS del router ocurre solo después de validar respuestas por IP directa
- no se cambia DNS del router en la misma ventana que reservas DHCP o cambios de IP finales
- la primera etapa segura prioriza continuidad de Internet doméstico sobre filtrado perfecto

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
- el router conserva DHCP y solo reparte servidores DNS a clientes;
- clientes consultan `DNS1` en `management`;
- si `DNS1` falla o tarda demasiado, el cliente puede caer a `DNS2 = 1.1.1.1`;
- `orangepi5-ultra` queda como secundario arquitectónico para pruebas, validación y futura sincronización, no como dependencia del primer cutover del router;
- DNS local resuelve `paperless`, `immich`, `jellyfin`, `navidrome`, `home` y `auth` hacia el proxy local.

### Falla

- si cae `management`, los clientes siguen navegando por `DNS2 = 1.1.1.1`, aunque pierdan filtrado y split-horizon local;
- si cae `ultra`, la etapa 1 sigue operable porque no depende de él como `DNS2` del router;
- si ambos `Pi-hole` caen, la red mantiene salida a Internet por el fallback público mientras se restaura el filtrado;
- si cae el enlace inter-sede, la resolución local sigue funcionando sin depender del otro sitio.
- si el cambio de DNS del router genera problema, rollback inmediato al DNS anterior del router

## Aceptación

- primario y secundario responden consultas locales por IP directa;
- la migración del router tiene un orden seguro documentado y rollback simple;
- configuración del router refleja `DNS1 = Pi-hole` y `DNS2 = 1.1.1.1` solo después de la validación staged;
- el router sigue siendo autoridad DHCP durante toda la etapa;
- el diseño no depende de VIP desde el día uno.

## Prechecks mínimos

- `Pi-hole` primario responde por IP directa
- `Pi-hole` secundario responde por IP directa
- router conserva DHCP habilitado
- `DNS2` público de emergencia definido
- canary real disponible
- script de cutover y rollback probado al menos en dry-run lógico
- no mezclar el cambio con reservas DHCP o renumeración de IPs

## Rollback

- restaurar inmediatamente el DNS previo del router
- no tocar contenedores `Pi-hole` durante el rollback
- si el cutover falla, mantener `Pi-hole` staged y depurar fuera de la ruta crítica

## Dependencias previas

- red y direccionamiento final
- blackout y nodo `ultra` definidos

## Fuera de fase

- VIP `keepalived`
- anycast DNS
