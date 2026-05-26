# Colibri Inventory

Inventario operativo de la casa `Colibri`.

Este documento separa:

- nodos verificados por `SSH`
- leases observados pero no confirmados
- notas para asignacion futura de roles e IPs fijas

## Nodos verificados por SSH

| Hostname | IP reservada objetivo | MAC | SO | Arquitectura | Modelo | Notas |
|---|---|---|---|---|---|---|
| `ai-gpu` | `192.168.0.13` | `58:47:CA:7F:84:B5` | `Ubuntu 26.04 LTS` | `x86_64` | `Micro Computer (HK) Tech Limited / MotherBoard Series` | Nodo GPU; reservation ya tomada y validada por `ping` y `SSH` |
| `management` | `192.168.0.10` | `C4:65:16:AC:AB:37` | `Ubuntu 26.04 LTS` | `x86_64` | `HP EliteDesk 800 G4 DM 35W (TAA)` | `EliteDesk`, `Docker` y `Ansible` instalados, `NUT` instalado y deshabilitado; reservation ya tomada y validada por `ping` y `SSH` |
| `nas` | `192.168.0.11` | `C8:FF:BF:05:F4:46` | `Debian GNU/Linux 13 (trixie)` | `x86_64` | `WTR PRO` | `OpenMediaVault` con namespaces `media` y `docs`; reservation ya tomada y validada por `ping` y `SSH` |
| `services` | `192.168.0.12` | `58:47:CA:79:08:69` | `Ubuntu 26.04 LTS` | `x86_64` | `EliteMini Series` | `UM890`, `Docker` instalado, mounts `NFS` activos para `media/docs`; reservation ya tomada y validada por `ping` y `SSH` |
| `orangepi5-ultra` | `192.168.0.14` | `C0:74:2B:FC:59:86` | `Armbian_community 26.2.0-trunk.904 trixie` | `aarch64` | `RK3588 OPi 5 Ultra` | Orange Pi 5 Ultra, `Docker` operativo; reservation ya tomada y validada por `ping` y `SSH` |
| `orangepi5-max` | `192.168.0.15` | `C0:74:2B:FD:71:43` | `Armbian_community 26.2.0-trunk.904 trixie` | `aarch64` | `RK3588 OPi 5 Max` | Orange Pi 5 Max, `Docker` operativo; reservation ya tomada y validada por `ping` y `SSH` |
| `orangepi5-a` | `192.168.0.16` | `C6:CC:84:3D:E2:67` | `Armbian 26.2.1 trixie` | `aarch64` | `Orange Pi 5` | Worker ARM; reservation ya tomada y validada por `ping` y `SSH` |
| `orangepi5-b` | `192.168.0.17` | `C6:87:B3:C0:55:95` | `Armbian 26.2.1 trixie` | `aarch64` | `Orange Pi 5` | Worker ARM; reservation ya tomada y validada por `ping` y `SSH` |

## Capacidades detectadas

### `ai-gpu` - probable `Minisforum 790S7`

- CPU: `AMD Ryzen 9 7940HX`, `16C/32T`
- RAM fisica declarada: `64 GiB`
- RAM visible al SO en este barrido: `45 GiB`
- nota: el usuario indico que `16 GiB` estan reservados para la iGPU
- GPU dedicada detectada: `NVIDIA GeForce RTX 5060`
- GPU integrada detectada: `AMD/ATI Raphael`
- Red: `Realtek RTL8125 2.5GbE`
- Discos:
- `119.2G NVMe ORICO` para SO actual
- `931.5G NVMe KINGSTON SNV3S1000G` montado en `/storage`
- software base:
- `Docker` no instalado actualmente
- `NVIDIA GeForce RTX 5060` visible por `nvidia-smi`

### `management` - `HP EliteDesk 800 G4`

- CPU: `Intel Core i5-8500T`, `6C/6T`
- RAM visible: `14 GiB`
- GPU integrada: `Intel UHD 630`
- Red: `Intel I219-LM`
- Disco:
- `238.5G NVMe Samsung` para SO actual
- software base:
- `Docker 29.1.3`
- `Docker Compose 2.40.3`
- `Ansible core 2.20.1`
- `expect` instalado para automatización segura del router
- `nut-client` y `nut-server` instalados
- `NUT` deshabilitado hasta definir UPS y configuracion
- `Pi-hole` objetivo:
  - DNS en `192.168.0.10:53`
  - UI en `http://192.168.0.10:8080/admin`
  - baseline de listas: `OISD small`
- automatización staged de DNS:
  - helper `router-cli.expect` desplegado en `/opt/colibri/bin`
  - script `router-dns-cutover-with-rollback.sh` desplegado en `/opt/colibri/bin`
  - secreto local esperado en `/opt/colibri-secrets/router.env`
  - dry-run lógico validado con `orangepi5-ultra` como canary
  - cutover real aplicado con rollback automático armado y no requerido

### `nas` - `AOOSTAR WTR PRO`

- CPU: `AMD Ryzen 7 5825U`, `8C/16T`
- RAM visible: `62 GiB`
- Red:
- `2 x Intel I226-V`
- GPU integrada AMD Barcelo
- Controladoras SATA AMD detectadas
- Discos:
- `2 x 12 TB` Seagate IronWolf Pro en `md0`
- `md0` reconstruido como `media-cold`, filesystem `xfs`
- `2 x 4 TB` Seagate IronWolf en `md1`
- `md1` reconstruido como `docs-cold`, filesystem `ext4`
- `238.5G NVMe Kioxia` para SO
- `119.2G NVMe ORICO` reconstruido como `docs-warm`, filesystem `btrfs`
- `476.9G NVMe T-FORCE` reconstruido como `media-warm`, filesystem `btrfs`
- `mergerfs` unifica:
- `/srv/media-warm` + `/srv/media-cold` -> `/srv/media`
- `/srv/docs-warm` + `/srv/docs-cold` -> `/srv/docs`
- `NFS` exporta solo `/srv/media` y `/srv/docs`
- timers activos:
- `tier-media-cold.timer` a las `03:15`
- `tier-docs-cold.timer` a las `03:45`
- politica de permisos actual:
- usuario compartido `apps` con `UID 3000`
- grupos compartidos `media_rw`, `media_ro`, `docs_rw`, `docs_ro`
- `ACLs` y `setgid` ya aplicados en `media/docs`
- `root_squash` mantenido en `NFS`

### `orangepi5-ultra` - `192.168.0.14`

- CPU: `RK3588`, `4x Cortex-A76 + 4x Cortex-A55`
- RAM visible: `15 GiB`
- Red activa: `Ethernet 192.168.0.14`
- Discos:
- `57.8G` medio principal actual con raiz en `ext4`
- `119.2G NVMe ORICO` reformateado a `ext4`
- montado en `/srv/storage`
- directorios base:
  - `/srv/storage/appdata`
  - `/srv/storage/db`
  - `/srv/storage/tmp`
- software base:
- `Docker 26.1.5`
- `Docker Compose 2.26.1`
- `colibri-cpufreq-tune.service` activo con tope `2016000` en clusters grandes
- `Pi-hole` secundario objetivo:
  - DNS en `192.168.0.14:53`
  - UI en `http://192.168.0.14:8080/admin`
  - baseline de listas: `OISD small`
- canary script desplegado en `/usr/local/lib/colibri/dns-canary-check`
- `sudoers` acotado para ejecución sin password del canary checker
- canary principal usado con éxito en el cutover real de DNS LAN del router

### `orangepi5-max` - `192.168.0.15`

- CPU: `RK3588`, `4x Cortex-A76 + 4x Cortex-A55`
- RAM visible: `7.7 GiB`
- Red activa: `Ethernet 192.168.0.15`
- Discos:
- `57.8G` medio principal actual con raiz en `ext4`
- `119.2G NVMe ORICO` reformateado a `ext4`
- montado en `/srv/storage`
- directorios base:
  - `/srv/storage/appdata`
  - `/srv/storage/db`
  - `/srv/storage/tmp`
- software base:
- `Docker 26.1.5`
- `Docker Compose 2.26.1`
- `colibri-cpufreq-tune.service` activo con tope `2016000` en clusters grandes
- `Pi-hole` terciario objetivo:
  - DNS en `192.168.0.15:53`
  - UI en `http://192.168.0.15:8080/admin`
  - baseline de listas: `OISD small`
- canary script desplegado en `/usr/local/lib/colibri/dns-canary-check`
- `sudoers` acotado para ejecución sin password del canary checker

### `orangepi5-a` - `192.168.0.16`

- CPU: `RK3588S/RK3588 family`, `4x Cortex-A76 + 4x Cortex-A55`
- RAM visible: `7.7 GiB`
- Red activa: `Ethernet 192.168.0.16`
- Discos:
- `57.8G` medio principal actual con raiz en `ext4`
- arranque actual desde `/dev/mmcblk1p1`
- no se detecto `NVMe` ni dispositivo `PCIe` asociado en este barrido
- lectura: si realmente tiene `Kioxia 256G`, conviene revisar asiento fisico, adaptador M.2 y compatibilidad del carrier
- software base:
- `Docker 26.1.5`
- `Docker Compose 2.26.1`

### `orangepi5-b` - `192.168.0.17`

- CPU: `RK3588S/RK3588 family`, `4x Cortex-A76 + 4x Cortex-A55`
- RAM visible: `7.7 GiB`
- Red activa: `Ethernet 192.168.0.17`
- Discos:
- `57.8G` medio principal actual con raiz en `ext4`
- arranque actual desde `/dev/mmcblk1p1`
- no se detecto `NVMe` ni dispositivo `PCIe` asociado en este barrido
- lectura: si realmente tiene `Kioxia 256G`, conviene revisar asiento fisico, adaptador M.2 y compatibilidad del carrier
- software base:
- `Docker 26.1.5`
- `Docker Compose 2.26.1`

### `services` - `UM890`

- IP activa: `192.168.0.12`
- CPU: `AMD Ryzen 9 8945HS`, `8C/16T`
- RAM fisica declarada: `64 GiB`
- RAM visible al SO en este barrido: `46 GiB`
- nota: el usuario indico que `16 GiB` estan reservados para la iGPU
- SO actual detectado: `Ubuntu 26.04 LTS`
- Discos:
- `1 TB Kingston SKC3000S1024G` montado en `/storage`
- `500 GB Crucial CT500P3SSD8` con sistema actual (`/`)
- software base:
- `Docker 29.1.3`
- `Docker Compose 2.40.3`
- mounts `NFS`:
- `/srv/media -> nas:/srv/media`
- `/srv/docs -> nas:/srv/docs`
- rol previsto: nodo principal de servicios con `Docker` y `Portainer`

## Leases observados no confirmados

| Nombre visto en DHCP | IP | MAC | Estado | Lectura |
|---|---|---|---|---|
| `ubuntu-server` | `192.168.0.162` | `84:A9:3E:12:A6:9B` | no respondio a `ping` durante el barrido | Lease probable de un nodo apagado o en reinstalacion |
| `management` | `192.168.0.164` | `84:A9:3E:12:A6:9B` | no respondio a `ping` durante el barrido | Lease viejo del mismo MAC que `192.168.0.162` |
| `SM-R920` | `192.168.0.160` | `A2:65:6B:C4:1D:0B` | no respondio a `ping` durante el barrido | Muy probablemente un wearable Samsung |

## Lectura actual

- El bloque core ya quedó operativo en `.10-.17`.
- Los 8 nodos principales ya responden por `ping` y `SSH` en sus IPs reservadas nuevas.
- El MAC `84:A9:3E:12:A6:9B` tiene dos leases en `192.168.0.162` y `192.168.0.164`, pero ninguno estaba activo en el momento del barrido.
- `192.168.10.101` corresponde a la workstation local `bd795m`, no al `UM890 Pro`.
- `services` ya responde en `.12`.
- Las dos `Orange Pi 5` simples ya se renombraron a `orangepi5-a` y `orangepi5-b`.
- Las dos `Orange Pi 5` simples no muestran su `NVMe` a nivel de kernel en este momento.
- `services` ya monta `NFS` desde `nas` en `/srv/media` y `/srv/docs`.
- las identidades compartidas para `NFS` ya estan propagadas:
- usuario `apps` `UID 3000`
- grupos `media_rw`, `media_ro`, `docs_rw`, `docs_ro`
- `jrenewhite` ya pertenece a `media_rw` y `docs_rw`
- `services` ya puede escribir en `media/docs` por `NFS` sin desactivar `root_squash`

## Auditoría no-core de reservas

Resumen de cierre de `Microplan 01B`:

- `infra extendida`
  - activos validados: `.18`, `.30`, `.31`
  - configurado pendiente de observación: `.19`
- `red y periféricos`
  - `deco-*` `.32-.41` y `hp-officejet` `.42` quedaron validados
- `Google Home/Nest`
  - activos validados: `.50`, `.51`, `.53-.58`
  - pendiente de observación: `.52`
- `Wyze principales`
  - activos o vistos por `ARP/MAC` razonable: `.60`, `.61`, `.62`, `.64`, `.65`
  - pendiente de observación: `.63`, `.66`, `.67`
- `Wyze auxiliares`
  - activos o vistos por `ARP/MAC` razonable: `.70-.77`
- `TP-Link / Govee`
  - activos validados: `.80-.84`, `.86`, `.87`
  - pendiente de observación: `.85`

Lectura:

- no se observaron conflictos visibles IP/MAC en el rango de reservas no-core auditado
- los dispositivos no observados siguen considerándose cerrados por configuración mientras la reservation sea correcta

## Roles previstos

| Equipo | Rol previsto | SO previsto |
|---|---|---|
| `WTR PRO` | NAS | `OpenMediaVault` limpio |
| `Minisforum 790S7` | nodo GPU | `Ubuntu Server 26.04` |
| `HP EliteDesk 800 G4` | servicios 24/7 | `Ubuntu Server 26.04` |
| `Minisforum UM890 Pro` | servicios principales | `Debian 13 / Ubuntu Server 26.04` |
| `Orange Pi 5 Ultra` | servicios ligeros o `Home Assistant` | `Armbian Debian 13 Minimal` ya basado en `trixie` |
| `Orange Pi 5 Max` | laboratorio ARM fuerte y `Pi-hole` terciario opcional | `Armbian Debian 13 Minimal` ya basado en `trixie` |
| `2 x Orange Pi 5` | workers puros, monitoreo, aceleracion ligera, watchdogs | `Armbian Debian 13 Minimal` ya basado en `trixie` |

## Siguiente paso recomendado

Cuando terminen las reinstalaciones, convertir este inventario en inventario de gestion:

- hostname final
- IP fija o reserva DHCP final
- rol
- SO final
- usuario de administracion
- si ya tiene `Tailscale`
- si ya tiene `SSH keys`
