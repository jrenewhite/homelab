# Microplan 01 — Red y Direccionamiento

## Propósito

Cerrar el baseline de red, direccionamiento, resolución local y acceso administrativo para que todo lo demás se construya sobre una sola verdad.

## Estado actual

- LAN efectiva: `192.168.0.0/24`
- router: `192.168.0.1`
- reservas DHCP objetivo documentadas pero no aplicadas
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
- no se introducen VLANs en esta fase;
- los nodos principales deben seguir accesibles por IP incluso si DNS local falla.
- la LAN de `Colibrí` sigue siendo local a la sede, pero la arquitectura general ya asume `split-horizon DNS`
- `WireGuard site-to-site` será parte del backbone multi-site, separado de `Tailscale`
- el cambio a IPs objetivo se hace por etapas, nunca junto con el cambio de DNS del router
- primero se validan servicios en IP actual, luego se mueve DHCP/IP, y solo después se actualizan referencias aguas arriba

## Interfaces y valores

| Host | IP objetivo |
|---|---|
| router | `192.168.0.1` |
| `management` | `192.168.0.10` |
| `nas` | `192.168.0.20` |
| `services` | `192.168.0.30` |
| `ai-gpu` | `192.168.0.40` |
| `orangepi5-ultra` | `192.168.0.51` |
| `orangepi5-max` | `192.168.0.52` |
| `orangepi5-a` | `192.168.0.53` |
| `orangepi5-b` | `192.168.0.54` |

## Flujos

### Normal

- cliente obtiene IP por DHCP;
- reserva fija ata MAC a IP objetivo;
- `SSH` usa llave y `Tailscale` como acceso administrativo complementario;
- el sitio resuelve nombres globales hacia su proxy local mediante DNS local.
- la migración a IP objetivo se hace host por host o por grupo pequeño, con validación antes de continuar

### Falla

- si DNS local cae, operación por IP directa;
- si `management` cae, acceso sigue por IP o `Tailscale`;
- si una reserva DHCP falla, el host sigue siendo alcanzable por IP temporal y se corrige desde router.
- si el enlace inter-sede cae, `Colibrí` sigue operando localmente.
- si un futuro cutover DNS falla, `management` ejecuta rollback automático al DNS anterior del router usando un secreto local no versionado

## Aceptación

- existe secuencia de migración sin corte para IPs finales;
- cada nodo responde por `SSH` en su IP actual o final durante toda la transición;
- todas las reservas aplicadas en router una vez que las capas superiores ya fueron probadas;
- `colibri-router-baseline.md` refleja estado aplicado, no solo objetivo.

## Dependencias previas

- ninguna

## Fuera de fase

- VLANs
- múltiples LANs
- failover L3/L2
