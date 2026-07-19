# Perú Inventory

Inventario inicial y mapa de roles propuesto para la sede `Perú`.

Este documento esta en fase de preparacion previa a llegada. A diferencia de `Colibrí`, aqui varias columnas estan todavia en estado `pending` hasta hacer validacion fisica en sitio.

## 1. Nodos previstos

| Hostname objetivo | IP reservada objetivo | Hardware | SO objetivo | Rol | Estado |
|---|---|---|---|---|---|
| `peru-nas` | `192.168.0.11` | gabinete NAS armado | `OpenMediaVault` sobre `Debian 13` | archivo frio, `NFS`, backups | online: SSH, Tailscale, WOL |
| `peru-services` | `192.168.0.12` | `Minisforum UM870 Slim` | `Ubuntu Server LTS` | control plane operativo, apps principales, hot storage, `NUT` master, `Caddy` primario futuro | online: SSH, Tailscale, WOL, Docker; ambos `UPS` por USB |
| `peru-ai-gpu` | `192.168.0.13` | `Minisforum 790S7` + `RTX 5060` | `Ubuntu Server LTS` | media/IA pesada | online: SSH, Tailscale, WOL |
| `peru-rpi5-a` | `192.168.0.14` | `Raspberry Pi 5 8 GB` + `SSD USB 240 GB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | `Pi-hole` primario, `Home Assistant`, sentinel | online: SSH, Tailscale, WOL, Docker |
| `peru-rpi5-b` | `192.168.0.15` | `Raspberry Pi 5 8 GB` + `SSD USB 240 GB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | repair required antes de servicios criticos | offline tras intento remoto de migrar rootfs a SSD; requiere recuperacion fisica |
| `peru-rpi4-a` | `192.168.0.17` | `Raspberry Pi 4B 8 GB` + `SSD USB 1 TB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | `Pi-hole` secundario provisional, watchdog, healthchecks, utilitarios | online: SSH, Tailscale, WOL, Docker |
| `peru-rpi4-b` | `192.168.0.18` | `Raspberry Pi 4B 8 GB` + `SSD USB 1 TB` | `Ubuntu Server` o `Raspberry Pi OS Lite` | watchdog, healthchecks, utilitarios | online: SSH, Tailscale, WOL |

## 2. Equivalencias con Colibrí

| Perú | Equivalente en Colibrí | Nota |
|---|---|---|
| `peru-management` | `management` | retirado del sitio; funciones absorbidas por `peru-services` y cluster `RPi` |
| `peru-services` | `services` + `management` parcial | apps, control operativo, `NUT` master y `Caddy` primario futuro |
| `peru-ai-gpu` | `ai-gpu` | mismo perfil funcional |
| `peru-nas` | `nas` | puede quedar para una segunda ventana |
| `peru-rpi5-a` | `orangepi5-ultra` | reemplazo funcional principal |
| `peru-rpi5-b` | `orangepi5-max` | reemplazo funcional secundario |
| `peru-rpi4-a` | `orangepi5-b` parcial | healthchecks/watchdog |
| `peru-rpi4-b` | nodo auxiliar nuevo | healthchecks/storage ligero |

## 3. Prioridad Tailscale por nodo

| Nodo | Prioridad | Motivo |
|---|---|---|
| `peru-services` | `P0` | nodo central de apps, sync local, `Ansible`, `NUT` master y `Caddy` futuro |
| `peru-ai-gpu` | `P0` | nodo costoso y util para operacion bajo demanda |
| `peru-rpi5-a` | `P0` | `Pi-hole` primario y mejor candidato resiliente 24/7 si algo falla |
| `peru-rpi5-b` | `P2` | requiere reparar storage antes de roles criticos |
| `peru-rpi4-a` | `P0` | `Pi-hole` secundario provisional y healthchecks |
| `peru-rpi4-b` | `P1` | healthchecks o storage auxiliar |
| `peru-nas` | `P2` | no bloquea la primera fase si aun no esta listo |

## 4. Minimo aceptable por nodo en la primera visita

| Nodo | Reserva DHCP | SSH | Tailscale | Docker | Nota |
|---|---|---|---|---|---|
| `peru-services` | si | si | si | idealmente si | base de apps, control operativo y `NUT` master |
| `peru-ai-gpu` | si | si | si | opcional si no hay tiempo | acceso remoto primero |
| `peru-rpi5-a` | si | si | si | opcional | resiliencia y DNS futuro |
| `peru-rpi5-b` | si | si | si | no | reparar storage antes de usar |
| `peru-rpi4-a` | si | si | si | si | DNS secundario provisional |
| `peru-rpi4-b` | si | deseable | deseable | no | puede quedar para despues |
| `peru-nas` | si | opcional | opcional | no | diferible |

## 5. Identificacion confirmada de Raspberry Pi

| Nodo | Modelo detectado | RAM | MAC LAN | IP LAN | IP Tailscale | Serial | SSD conectado |
|---|---|---:|---|---:|---:|---|---|
| `peru-rpi5-a` | `Raspberry Pi 5 Model B Rev 1.1` | `7.8 GiB` | `88:A2:9E:0D:31:DC` | `192.168.0.14` | `100.68.9.59` | `90276522d0a432c8` | `ADATA SU630 223.6G` |
| `peru-rpi5-b` | `Raspberry Pi 5 Model B Rev 1.1` | `7.8 GiB` | `88:A2:9E:0D:33:54` | `192.168.0.15` | `100.74.71.106` | `a2ba66a1003ee120` | `ADATA SU630 223.6G` |
| `peru-rpi4-a` | `Raspberry Pi 4 Model B Rev 1.5` | `7.6 GiB` | `D8:3A:DD:24:CB:D1` | `192.168.0.17` | `100.68.148.26` | `10000000358f7173` | `WD Green 2.5 1000GB 931.5G` |
| `peru-rpi4-b` | `Raspberry Pi 4 Model B Rev 1.5` | `7.6 GiB` | `D8:3A:DD:24:B3:BB` | `192.168.0.18` | `100.121.97.111` | `100000003646544f` | `WD Green 2.5 1000GB 931.5G` |

La reserva `192.168.0.16` no existe como nodo activo en el sitio actual; el sitio tiene `2 x Raspberry Pi 5` y `2 x Raspberry Pi 4`, todas de `8 GB`.

## 6. Puertos y servicios esperados despues de base minima

| Servicio | Nodo objetivo | Exposicion inicial |
|---|---|---|
| `Tailscale SSH` o `SSH` sobre `Tailscale` | todos los nodos criticos | `tailscale-only` |
| `Pi-hole` primario | `peru-rpi5-a` | LAN |
| `Pi-hole` UI primaria | `peru-rpi5-a` | LAN/Tailscale |
| `Pi-hole` secundario | `peru-rpi4-a` | LAN |
| `Pi-hole` UI secundaria | `peru-rpi4-a` | LAN/Tailscale |
| `Homepage` futuro | `peru-services` | LAN/Tailscale al inicio |
| `Caddy` primario futuro | `peru-services` | LAN al inicio |
| `Caddy` standby opcional | `peru-rpi5-a` | LAN/Tailscale si se necesita continuidad |

## 7. Pendientes de descubrimiento en sitio

- confirmar retiro definitivo de reserva `192.168.0.10` en el `ER605`;
- sistema operativo definitivo en cada `Raspberry Pi`;
- si el `NAS` arranca ya listo o se difiere;
- nombre y rango DHCP actual del router;
- si alguna SBC necesita ajuste especial para boot por `SSD USB`.

## 8. Notas operativas ya conocidas

- los equivalentes `RPi` en `Perú` ya cuentan con `SSD USB`;
- `peru-rpi5-b` tuvo intento remoto de migracion `SD boot + SSD rootfs` el `2026-07-18`: el rootfs se copio a `/dev/sda1` (`UUID=b9618d45-c048-4f2e-bce9-b82bb7e3e094`) y `/boot/firmware/cmdline.txt` quedo apuntando a ese UUID, pero el nodo no volvio por Tailscale tras reboot; recuperar en sitio revisando SD/SSD/boot config;
- por coexistencia futura entre sedes, conviene hostnames unicos globalmente; por eso se usa prefijo `peru-`;
- la primera prioridad del sitio es administrabilidad remota, no publicacion de servicios.
