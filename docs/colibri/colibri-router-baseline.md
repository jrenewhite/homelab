# Colibri Router Baseline

Baseline objetivo para el `TP-Link ER707-M2` en `Standalone Mode`.

## Red base

- LAN unica: `192.168.0.1/24`
- DHCP dinamico: `192.168.0.100 - 192.168.0.199`
- Subred `192.168.10.0/24` retirada

## Reservas DHCP objetivo

| Host | MAC | IP objetivo |
|---|---|---|
| `management` | `C4:65:16:AC:AB:37` | `192.168.0.10` |
| `nas` | `C8:FF:BF:05:F4:46` | `192.168.0.20` |
| `services` | `58:47:CA:79:08:69` | `192.168.0.30` |
| `ai-gpu` | `58:47:CA:7F:84:B5` | `192.168.0.40` |
| `orangepi5-ultra` | `C0:74:2B:FC:59:86` | `192.168.0.51` |
| `orangepi5-max` | `C0:74:2B:FD:71:43` | `192.168.0.52` |
| `orangepi5-a` | `C6:CC:84:3D:E2:67` | `192.168.0.53` |
| `orangepi5-b` | `C6:87:B3:C0:55:95` | `192.168.0.54` |

## Estado actual verificado

- `SSH` del router esta expuesto en `192.168.0.1:22`
- El equipo ofrece `ssh-rsa`
- Autenticacion por `SSH` confirmada con el usuario administrativo del panel web
- El pool DHCP efectivo se llama `LAN`
- El DNS DHCP actual sigue sin valores explícitos (`dns1/dns2` unset)
- Las reservas DHCP objetivo siguen pendientes de aplicar

## Checklist manual en router

- habilitar `Remote Assistance / SSH`
- confirmar `Standalone Mode`
- confirmar LAN `192.168.0.1/24`
- confirmar rango DHCP `192.168.0.100 - 192.168.0.199`
- crear las reservas DHCP de la tabla
- eliminar cualquier reserva residual de `192.168.10.0/24`
