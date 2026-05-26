# Microplan 01 — Red y Direccionamiento

## Propósito

Cerrar el baseline de red, direccionamiento, resolución local y acceso administrativo para que todo lo demás se construya sobre una sola verdad.

## Estado actual

- LAN efectiva: `192.168.0.0/24`
- router: `192.168.0.1`
- reservas DHCP ya importadas en el router
- los 8 nodos core ya responden en sus IPs reservadas nuevas `.10-.17`
- acceso `SSH` funcional a los nodos principales
- nombres de host actuales ya estabilizados
- `Perú` aún no está configurado, pero el diseño ya debe tolerar operación multi-site

## Objetivo final

- router con reservas DHCP aplicadas;
- todos los nodos accesibles por su IP final;
- una sola LAN operativa;
- acceso administrativo consistente por `SSH`, `Tailscale` y DNS local donde aplique;
- base lista para convivir con un segundo sitio sin cambiar la UX de URLs globales.

## Decisiones cerradas

- no habrá segunda subred en esta fase;
- `DHCP reservations` en el `ER707-M2` son la fuente de verdad para IPs fijas;
- el `ER707-M2` mantiene siempre el servicio DHCP; `Pi-hole` no asume ese rol;
- no se introducen VLANs en esta fase;
- los nodos principales deben seguir accesibles por IP incluso si DNS local falla.
- la LAN de `Colibrí` sigue siendo local a la sede, pero la arquitectura general ya asume `split-horizon DNS`
- `WireGuard site-to-site` será parte del backbone multi-site, separado de `Tailscale`
- el cambio a IPs objetivo se hace por etapas, nunca junto con el cambio de DNS del router
- primero se validan servicios en IP actual, luego se mueve DHCP/IP, y solo después se actualizan referencias aguas arriba
- el primer cutover de DNS del router debe mantener un resolvedor público de emergencia como `DNS2`

## Interfaces y valores

| Host | IP objetivo |
|---|---|
| router | `192.168.0.1` |
| `management` | `192.168.0.10` |
| `nas` | `192.168.0.11` |
| `services` | `192.168.0.12` |
| `ai-gpu` | `192.168.0.13` |
| `orangepi5-ultra` | `192.168.0.14` |
| `orangepi5-max` | `192.168.0.15` |
| `orangepi5-a` | `192.168.0.16` |
| `orangepi5-b` | `192.168.0.17` |

## Flujos

### Normal

- cliente obtiene IP por DHCP;
- reserva fija ata MAC a IP objetivo;
- `SSH` usa llave y `Tailscale` como acceso administrativo complementario;
- el sitio resuelve nombres globales hacia su proxy local mediante DNS local.
- la migración a IP objetivo se hace host por host o por grupo pequeño, con validación antes de continuar
- el cambio de DNS del router ocurre en ventana separada y no altera el rol DHCP del `ER707-M2`

### Falla

- si DNS local cae, operación por IP directa;
- si falla `Pi-hole`, el router conserva DHCP y los clientes aún pueden resolver usando el fallback público configurado;
- si `management` cae, acceso sigue por IP o `Tailscale`;
- si una reserva DHCP falla, el host sigue siendo alcanzable por IP temporal y se corrige desde router.
- si el enlace inter-sede cae, `Colibrí` sigue operando localmente.
- si un futuro cutover DNS falla, `management` ejecuta rollback automático al DNS anterior del router usando un secreto local no versionado

## Aceptación

- existe secuencia de migración sin corte para IPs finales;
- cada nodo responde por `SSH` en su IP actual o final durante toda la transición;
- todas las reservas aplicadas en router una vez que las capas superiores ya fueron probadas;
- `colibri-router-baseline.md` refleja estado aplicado, no solo objetivo.

## Prechecks mínimos

- export o captura del estado actual del router
- CSV de reservas validado sin MACs ni IPs duplicadas
- pool DHCP libre y coherente con las reservas
- acceso `SSH` a `management` y al menos un worker canary
- confirmación de que no habrá cambio simultáneo de DNS del router

## Rollback

- si una reserva falla, el host sigue por DHCP temporal y se corrige desde el router
- si un grupo pequeño de nodos no toma su IP, se aborta la tanda y no se continúa con más reboots
- si un cambio de red degrada acceso administrativo, rollback manual en el router al estado exportado o capturado

## Dependencias previas

- ninguna

## Fuera de fase

- VLANs
- múltiples LANs
- failover L3/L2
