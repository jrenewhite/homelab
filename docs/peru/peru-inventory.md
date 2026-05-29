# Perú Inventory

Inventario inicial y mapa de roles propuesto para la sede `Perú`.

Este documento esta en fase de preparacion previa a llegada. A diferencia de `Colibrí`, aqui varias columnas estan todavia en estado `pending` hasta hacer validacion fisica en sitio.

## 1. Nodos previstos

| Hostname objetivo | IP reservada objetivo | Hardware | SO objetivo | Rol | Estado |
|---|---|---|---|---|---|
| `peru-management` | `192.168.10.10` | pending | `Ubuntu Server LTS` | control plane, `Tailscale`, `Ansible`, DNS/proxy futuro | pending |
| `peru-nas` | `192.168.10.11` | gabinete NAS armado | pending | archivo frio, `NFS`, backups | deferred |
| `peru-services` | `192.168.10.12` | `Minisforum UM870 Slim` | `Ubuntu Server LTS` | apps principales, hot storage | pending |
| `peru-ai-gpu` | `192.168.10.13` | `Minisforum 790S7` + `RTX 5060` | `Ubuntu Server LTS` | media/IA pesada | pending |
| `peru-rpi5-ultra` | `192.168.10.14` | `Raspberry Pi 5 8 GB` + `SSD USB 240 GB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | DNS secundario, `Home Assistant`, sentinel | pending |
| `peru-rpi5-max` | `192.168.10.15` | `Raspberry Pi 5 8 GB` + `SSD USB 240 GB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | DNS terciario opcional, worker ARM | pending |
| `peru-rpi5-a` | `192.168.10.16` | `Raspberry Pi 5 8 GB` + `SSD USB 240 GB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | worker ARM, utilitarios | pending |
| `peru-rpi4-a` | `192.168.10.17` | `Raspberry Pi 4B 8 GB` + `SSD USB 1 TB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | watchdog, healthchecks, utilitarios | pending |
| `peru-rpi4-b` | `192.168.10.18` | `Raspberry Pi 4B 8 GB` + `SSD USB 1 TB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | watchdog, healthchecks, utilitarios | pending |

## 2. Equivalencias con Colibrí

| Perú | Equivalente en Colibrí | Nota |
|---|---|---|
| `peru-management` | `management` | misma funcion, hardware por confirmar |
| `peru-services` | `services` | cambia de `UM890` a `UM870 Slim` |
| `peru-ai-gpu` | `ai-gpu` | mismo perfil funcional |
| `peru-nas` | `nas` | puede quedar para una segunda ventana |
| `peru-rpi5-ultra` | `orangepi5-ultra` | reemplazo funcional principal |
| `peru-rpi5-max` | `orangepi5-max` | reemplazo funcional secundario |
| `peru-rpi5-a` | `orangepi5-a` | worker ARM |
| `peru-rpi4-a` | `orangepi5-b` parcial | healthchecks/watchdog |
| `peru-rpi4-b` | nodo auxiliar nuevo | healthchecks/storage ligero |

## 3. Prioridad Tailscale por nodo

| Nodo | Prioridad | Motivo |
|---|---|---|
| `peru-management` | `P0` | control remoto del sitio y punto natural para `Ansible` |
| `peru-services` | `P0` | nodo central de apps y sync local |
| `peru-ai-gpu` | `P0` | nodo costoso y util para operacion bajo demanda |
| `peru-rpi5-ultra` | `P0` | mejor candidato a nodo resiliente 24/7 si algo falla |
| `peru-rpi5-max` | `P1` | DNS terciario o worker auxiliar |
| `peru-rpi5-a` | `P1` | worker ARM util pero no bloqueante |
| `peru-rpi4-a` | `P1` | healthchecks o utilitario |
| `peru-rpi4-b` | `P1` | healthchecks o storage auxiliar |
| `peru-nas` | `P2` | no bloquea la primera fase si aun no esta listo |

## 4. Minimo aceptable por nodo en la primera visita

| Nodo | Reserva DHCP | SSH | Tailscale | Docker | Nota |
|---|---|---|---|---|---|
| `peru-management` | si | si | si | idealmente si | debe salir administrable |
| `peru-services` | si | si | si | idealmente si | base de apps |
| `peru-ai-gpu` | si | si | si | opcional si no hay tiempo | acceso remoto primero |
| `peru-rpi5-ultra` | si | si | si | opcional | resiliencia y DNS futuro |
| `peru-rpi5-max` | si | idealmente si | idealmente si | no prioritario | si hay tiempo |
| `peru-rpi5-a` | si | idealmente si | idealmente si | no prioritario | si hay tiempo |
| `peru-rpi4-a` | si | deseable | deseable | no | puede quedar para despues |
| `peru-rpi4-b` | si | deseable | deseable | no | puede quedar para despues |
| `peru-nas` | si | opcional | opcional | no | diferible |

## 5. Puertos y servicios esperados despues de base minima

| Servicio | Nodo objetivo | Exposicion inicial |
|---|---|---|
| `Tailscale SSH` o `SSH` sobre `Tailscale` | todos los nodos criticos | `tailscale-only` |
| `Pi-hole` primario | `peru-management` | LAN |
| `Pi-hole` UI | `peru-management` | LAN/Tailscale |
| `Pi-hole` secundario | `peru-rpi5-ultra` | LAN |
| `Pi-hole` UI secundaria | `peru-rpi5-ultra` | LAN/Tailscale |
| `Homepage` futuro | `peru-management` | LAN/Tailscale al inicio |
| `Caddy` futuro | `peru-management` | LAN al inicio |

## 6. Pendientes de descubrimiento en sitio

- `MAC` real de cada nodo para reservas en el `ER605`;
- hardware exacto de `peru-management`;
- sistema operativo definitivo en cada `Raspberry Pi`;
- si el `NAS` arranca ya listo o se difiere;
- nombre y rango DHCP actual del router;
- si alguna SBC necesita ajuste especial para boot por `SSD USB`.

## 7. Notas operativas ya conocidas

- los equivalentes a `orangepi5-a` y `orangepi5-b` en `Colibrí` ya cuentan con almacenamiento por USB/NVMe; en `Perú`, las `Raspberry Pi` ya parten de un esquema similar con `SSD USB`;
- por coexistencia futura entre sedes, conviene hostnames unicos globalmente; por eso se usa prefijo `peru-`;
- la primera prioridad del sitio es administrabilidad remota, no publicacion de servicios.
