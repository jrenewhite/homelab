# Colibri Router Baseline

Baseline objetivo para el `TP-Link ER707-M2` en `Standalone Mode`.

## Red base

- LAN unica: `192.168.0.1/24`
- DHCP dinamico: `192.168.0.100 - 192.168.0.199`
- Subred `192.168.10.0/24` retirada
- el `ER707-M2` conserva el rol de servidor DHCP en toda fase

## Reservas DHCP objetivo

| Host | MAC | IP objetivo |
|---|---|---|
| `management` | `C4:65:16:AC:AB:37` | `192.168.0.10` |
| `nas` | `C8:FF:BF:05:F4:46` | `192.168.0.11` |
| `services` | `58:47:CA:79:08:69` | `192.168.0.12` |
| `ai-gpu` | `58:47:CA:7F:84:B5` | `192.168.0.13` |
| `orangepi5-ultra` | `C0:74:2B:FC:59:86` | `192.168.0.14` |
| `orangepi5-max` | `C0:74:2B:FD:71:43` | `192.168.0.15` |
| `orangepi5-a` | `C6:CC:84:3D:E2:67` | `192.168.0.16` |
| `orangepi5-b` | `C6:87:B3:C0:55:95` | `192.168.0.17` |

## Estado actual verificado

- `SSH` del router esta expuesto en `192.168.0.1:22`
- El equipo ofrece `ssh-rsa`
- Autenticacion por `SSH` confirmada con el usuario administrativo del panel web
- El pool DHCP efectivo se llama `LAN`
- El baseline seguro aprobado para DNS LAN es:
  - `pri_dns 192.168.0.10` cuando `Pi-hole` primario esté validado
  - `snd_dns 1.1.1.1` como fallback de emergencia
- `orangepi5-ultra` permanece como `Pi-hole` secundario de arquitectura, pero no como `snd_dns` del router en la primera etapa segura
- Las reservas DHCP ya fueron importadas; hasta renovar lease o reiniciar, varios nodos seguirán temporalmente en leases previos

## Checklist manual en router

- habilitar `Remote Assistance / SSH`
- confirmar `Standalone Mode`
- confirmar LAN `192.168.0.1/24`
- confirmar rango DHCP `192.168.0.100 - 192.168.0.199`
- confirmar que DHCP sigue habilitado en el router y que no se delega a `Pi-hole`
- configurar DNS LAN de forma segura:
  - temporalmente `1.1.1.1` / `1.0.0.1` durante recuperación
  - objetivo de etapa 1: `192.168.0.10` / `1.1.1.1`
- verificar que las reservas DHCP de la tabla estén activas
- eliminar cualquier reserva residual de `192.168.10.0/24`
