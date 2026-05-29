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
| `nas` | `192.168.0.11` | `C8:FF:BF:05:F4:47` | `Debian GNU/Linux 13 (trixie)` | `x86_64` | `WTR PRO` | `OpenMediaVault` con namespaces `media` y `docs`; NIC operativo actual `enp3s0`; reservation ya tomada y validada por `ping` y `SSH` |
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
- energia/WOL:
- interfaz principal `enp4s0`
- `MAC` `58:47:CA:7F:84:B5`
- driver `r8169`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- prueba real `WOL` en `2026-05-28` validada:
  - `suspend -> magic packet -> resume`
  - `poweroff -> magic packet -> boot`
- health minimo validado con:
  - `SSH`
  - `nut-monitor`
  - `/storage`
  - GPU NVIDIA visible por `lspci`
  - modulos `nvidia*` cargados

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
- energia/WOL:
- interfaz principal `eno1`
- `MAC` `C4:65:16:AC:AB:37`
- driver `e1000e`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- prueba real `WOL` en `2026-05-28` validada:
  - `suspend -> magic packet -> resume`
  - `poweroff -> magic packet -> boot`
- emisor validado para wake real:
  - `orangepi5-ultra`
- `Pi-hole` objetivo:
- DNS en `192.168.0.10:53`
- UI en `http://192.168.0.10:8200/admin`
- baseline de listas: `OISD small`
- estado staged real en `2026-05-28`:
  - contenedor `pihole` `healthy`
  - persistencia en `/opt/stacks/pihole-primary`
  - `StevenBlack` deshabilitada y `OISD small` habilitada
  - expuesto al host en `192.168.0.10:53 tcp/udp`
  - UI expuesta en `192.168.0.10:8200`
  - validado por `dig @192.168.0.10 cloudflare.com` y `curl http://192.168.0.10:8200/admin`
  - `split-horizon` staged listo en `2026-05-29` para:
    - `home.white-enciso.com`
    - `auth.white-enciso.com`
    - `jellyfin.white-enciso.com`
    - `paperless.white-enciso.com`
    - `immich.white-enciso.com`
    - `navidrome.white-enciso.com`
  - todos resolviendo localmente a `192.168.0.10` como placeholder del proxy futuro
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
- energia/WOL:
- interfaz principal `enp3s0`
- `MAC` `C8:FF:BF:05:F4:47`
- driver `igc`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- pruebas reales `WOL` en `2026-05-28`:
  - primer intento `suspend -> magic packet -> resume`: fallo
  - reintento `suspend -> magic packet -> resume`: exitoso
  - `poweroff -> magic packet -> boot` con `eno1`: exitoso
  - `poweroff -> magic packet -> boot` con `enp3s0` en prueba inicial: fallo
  - `poweroff -> magic packet -> boot` con `enp3s0` en prueba estricta y espera extra: exitoso
- caveat:
  - `nas` muestra variabilidad en `suspend/WOL`
  - `WOL` parece depender del NIC usado
  - `enp3s0` funciona para `suspend` y `poweroff`, pero responde mejor si se espera unos segundos extra antes del magic packet

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
- UI en `http://192.168.0.14:8201/admin`
- baseline de listas: `OISD small`
- estado staged real en `2026-05-28`:
- contenedor `pihole` reconciliado y expuesto en `192.168.0.14:53 tcp/udp`
- UI expuesta en `192.168.0.14:8201`
- validado por `dig @192.168.0.14 cloudflare.com` y `curl http://192.168.0.14:8201/admin`
- `192.168.0.14:8080` permanece asignado a `ntfy-local`
- replica manual de `split-horizon` staged en `2026-05-29` para:
  - `home.white-enciso.com`
  - `auth.white-enciso.com`
  - `jellyfin.white-enciso.com`
  - `paperless.white-enciso.com`
  - `immich.white-enciso.com`
  - `navidrome.white-enciso.com`
- todos resolviendo localmente a `192.168.0.10`
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
- UI en `http://192.168.0.15:8202/admin`
- baseline de listas: `OISD small`
- estado staged real en `2026-05-28`:
- `192.168.0.15:53` no responde por IP directa
- `192.168.0.15:8080` no responde
- `8202` queda libre como objetivo limpio para `Pi-hole`
- sin validacion por `SSH` en `05A`
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
- energia/WOL:
- interfaz principal `end1`
- `MAC` `C6:87:B3:C0:55:95`
- `Supports Wake-on: ug`
- `Wake-on: g`
- `suspend` esta deshabilitado por `/etc/systemd/sleep.conf.d/00-disable.conf`, lo cual ahora se considera esperado bajo politica `poweroff-only` para `SBC ARM`
- prueba real `poweroff -> magic packet -> boot` ejecutada en `2026-05-28`
- resultado: `WOL-from-poweroff-failed-manual-recovery`

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
- storage local-first preparado:
- `/storage/apps` -> `apps:apps` `2775`
- `/storage/cache` -> `apps:apps` `2775`
- `/storage/inbox` -> `apps:docs_rw` `2775`
- `/storage/media-staging` -> `apps:media_rw` `2775`
- `/storage/sync-out` -> `apps:apps` `2775`
- mounts `NFS` esperados:
- `/srv/media -> nas:/srv/media`
- `/srv/docs -> nas:/srv/docs`
- observación `2026-05-27`:
- `/etc/fstab` ya fue reconciliado hacia `192.168.0.11:/srv/media` y `192.168.0.11:/srv/docs`
- ambos mounts `NFS` vuelven a estar activos en `services`
- energia/WOL:
- interfaz principal `enp2s0`
- `MAC` `58:47:CA:79:08:69`
- driver `r8169`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- prueba real `WOL` en `2026-05-28` validada:
  - `suspend -> magic packet -> resume`
  - `poweroff -> magic packet -> boot`
- brecha detectada en `Microplan 03`:
- un `rsync` naive desde `/storage/sync-out` hacia `/srv/docs` preserva `apps:apps` en el destino final y no normaliza automáticamente a `docs_rw`
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
- `services` ya vuelve a montar `NFS` desde `nas` en `/srv/media` y `/srv/docs`.
- `services:/etc/fstab` ya apunta a `192.168.0.11` para ambos mounts.
- las identidades compartidas para `NFS` ya estan propagadas:
- usuario `apps` `UID 3000`
- grupos `media_rw`, `media_ro`, `docs_rw`, `docs_ro`
- `jrenewhite` ya pertenece a `media_rw` y `docs_rw`
- `services` ya puede volver a validarse como escritor sobre `NFS`
- `Microplan 03B` ya validó normalización explícita de sync:
  - `docs` puede quedar como `apps:docs_rw` `2775/664`
  - `media` puede quedar como `apps:media_rw` `2775/664`

## Matriz final WOL

| Nodo | Arq | Interfaz | MAC | `suspend -> WOL` | `poweroff -> WOL` | Emisor validado | Tiempo a ping | Tiempo a SSH | Estado operativo mínimo | Caveats | Clasificación final |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `orangepi5-ultra` | `aarch64` | `enP3p49s0` | `C0:74:2B:FC:59:86` | no probado | no probado | n/a | n/a | n/a | n/a | `wakeonlan` instalado; usar como emisor, no como target | `wake-emitter-supported` |
| `orangepi5-max` | `aarch64` | `enP3p49s0` | `C0:74:2B:FD:71:43` | no probado | no probado | n/a | n/a | n/a | n/a | SBC ARM | `always-on/manual-recovery/no-WOL-automation` |
| `orangepi5-a` | `aarch64` | `end1` | `C6:CC:84:3D:E2:67` | no probado | no probado | n/a | n/a | n/a | n/a | SBC ARM | `always-on/manual-recovery/no-WOL-automation` |
| `orangepi5-b` | `aarch64` | `end1` | `C6:87:B3:C0:55:95` | no aplica | fallo | `management` | none | none | none | requirió recuperación manual; no usar como target confiable | `always-on/manual-recovery/no-WOL-automation` |
| `services` | `x86_64` | `enp2s0` | `58:47:CA:79:08:69` | pass | pass | `management` | `10s` / `16s` | `11s` / `159s` | `SSH + nut-monitor` | `systemd-networkd-wait-online` retrasa readiness de `SSH` tras cold boot | `WOL-supported with boot-readiness caveat` |
| `ai-gpu` | `x86_64` | `enp4s0` | `58:47:CA:7F:84:B5` | pass | pass | `management` | `11s` / `20s` | `11s` / `21s` | `SSH + nut-monitor + /storage + GPU visible por driver` | `nvidia-smi` ausente; health mínimo por driver/PCI | `WOL-supported` |
| `nas` | `x86_64` | `enp3s0` preferido | `C8:FF:BF:05:F4:47` | pass con retry | pass con delay | `management` | `37s` / `33s` | `37s` / `33s` | `SSH + nut-monitor + md + mergerfs + NFS exports` | depende del NIC; `enp3s0` preferido; esperar unos segundos antes del packet en `poweroff` | `WOL-supported with NIC/timing caveat` |
| `management` | `x86_64` | `eno1` | `C4:65:16:AC:AB:37` | pass | pass con delay | `orangepi5-ultra` | `13s` / `23s` | `14s` / `24s` | `SSH + nut-server/nut-monitor + upsc + ntfy-local reachability` | control plane; mejor emisor futuro desde `SBC` | `WOL-supported/control-plane-recoverable` |

## Política final WOL

- No usar `WOL` mientras el sistema esté en batería.
- Prohibido despertar `nas` y `ai-gpu` en batería.
- `WOL` automático sigue prohibido por ahora.
- `WOL` manual solo está permitido si `NUT` reporta `OL`.
- Todo wake futuro debe validar por capas:
  - `ping`
  - `SSH`
  - `hostname`
  - servicios base
  - health específico de app o rol
- Las `SBC ARM` deben permanecer encendidas mientras el `UPS` lo permita; si se apagan, la recuperación es manual.

## Observacion energetica `04A`

### UPS y `NUT`

| Nodo | UPS visible en Linux | Evidencia | Estado `NUT` observado | Rol electrico propuesto |
|---|---|---|---|---|
| `management` | si, para una de dos UPS | `lsusb` muestra `MGE UPS Systems UPS`; `upower -d` muestra `Eaton` `ups_hiddev0` `100%` `on-battery: no`; `upsc linkedpro@localhost` devuelve variables utiles | `nut-server` y `nut-monitor` habilitados y activos; `upsc -l` devuelve `linkedpro` | unico candidato real a `NUT master`, ya operativo en modo observacion local para `LinkedPro LP1KRT` |
| `services` | no | sin UPS en `lsusb`; `upower` sin dispositivo UPS | `nut-client` instalado; `nut-monitor` habilitado y activo; `upsc linkedpro@192.168.0.10` devuelve variables utiles | `NUT client` remoto en observacion, nunca `master` en esta fase |
| `nas` | no | sin UPS en `lsusb`; sin UPS en `upower` | `nut-client` instalado; `nut-monitor` habilitado y activo; `upsc linkedpro@192.168.0.10` devuelve variables utiles | `NUT client` remoto en observacion |
| `ai-gpu` | no | sin UPS en `lsusb`; `upower` sin dispositivo UPS | `nut-client` instalado; `nut-monitor` habilitado y activo; `upsc linkedpro@192.168.0.10` devuelve variables utiles | `NUT client` remoto en observacion |
| `orangepi5-ultra` | no | sin UPS en `lsusb`; sin UPS util en `upower` | `nut-client` instalado; `nut-monitor` habilitado y activo; `upsc linkedpro@192.168.0.10` devuelve variables utiles | `NUT client` remoto en observacion, nunca `master` en esta fase |

### Topologia fisica por UPS

| UPS | Instrumentacion Linux | Cargas conocidas | Notas |
|---|---|---|---|
| `Epcom EPU1500LCD` linea interactiva | parcial, solo HID generico `0001:0000` | `management`, `Starlink actuated v3`, `Omada ER707-M2`, `TP-Link TL-SG108`, `DS105G-M2`, ventiladores USB `~5W` | visible por USB pero no monitorizable con `NUT` en esta fase; runbook manual |
| `LinkedPro LP1KRT` online `1000VA/900W` | si, visible desde `management` | `ai-gpu`, `nas`, `services`, `orangepi5-ultra`, `orangepi5-max`, `orangepi5-a`, `orangepi5-b`, ventiladores USB `~5W` | unica UPS candidata a `NUT` en esta fase; `management` la observa por USB, pero no se alimenta de ella |

### `WOL` read-only

| Nodo | Interfaz principal | `MAC` | Driver | `Supports Wake-on` | `Wake-on` actual | Estado | Accion futura | Politica |
|---|---|---|---|---|---|---|---|---|
| `management` | `eno1` | `C4:65:16:AC:AB:37` | `e1000e` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | deseable para recuperacion; no usar para inferir estado de UPS |
| `services` | `enp2s0` | `58:47:CA:79:08:69` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | deseable para recuperacion; no usar para inferir estado de UPS |
| `nas` | `eno1` | `C8:FF:BF:05:F4:46` | `igc` | `pumbg` | `g` | `confirmed` | `none` | permitido solo en energia normal; prohibido en bateria |
| `ai-gpu` | `enp4s0` | `58:47:CA:7F:84:B5` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | permitido solo en energia normal; prohibido en bateria |
| `orangepi5-ultra` | `enP3p49s0` | `C0:74:2B:FC:59:86` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |
| `orangepi5-max` | `enP3p49s0` | `C0:74:2B:FD:71:43` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |
| `orangepi5-a` | `end1` | `C6:CC:84:3D:E2:67` | `st_gmac` | `ug` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |
| `orangepi5-b` | `end1` | `C6:87:B3:C0:55:95` | `st_gmac` | `ug` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |

### Tooling `04A.1`

| Nodo | `ethtool` | wake tool | Lectura |
|---|---|---|---|
| `management` | presente | `wakeonlan` instalado | nodo de control futuro para pruebas de wake |
| `services` | presente | ausente | no bloquea esta fase |
| `nas` | presente | ausente | no bloquea esta fase |
| `ai-gpu` | presente | ausente | no bloquea esta fase |
| `orangepi5-ultra` | presente en `/usr/sbin/ethtool` | ausente | suficiente para inventario |
| `orangepi5-max` | presente en `/usr/sbin/ethtool` | ausente | suficiente para inventario |
| `orangepi5-a` | presente en `/usr/sbin/ethtool` | ausente | suficiente para inventario |
| `orangepi5-b` | presente en `/usr/sbin/ethtool` | ausente | suficiente para inventario |

### Lectura `04A`

- `management` contradice la doc vieja: si ve una UPS compatible en Linux y por eso es el unico `master` candidato real hoy.
- `management` se alimenta de la `Epcom EPU1500LCD`, pero observa por USB la `LinkedPro LP1KRT`; esta ultima es la unica visible para Linux/NUT.
- `04A.2` refinó el caso `Epcom`: si aparece por USB como `0001:0000` y hasta como `MEC0003` durante probing, pero no entrega variables utiles a `NUT`.
- `04B` ya deja `NUT` funcional en `management` para `linkedpro@localhost`, con `ups.status=OL`, `battery.charge=100`, `battery.runtime=6060`, `input.voltage=116.3` y `output.voltage=119.8`.
- `04C` ya deja `services`, `nas`, `ai-gpu` y `orangepi5-ultra` consultando `linkedpro@192.168.0.10` en modo observacion.
- `04D` ya deja una politica uniforme de eventos `NUT` con `NOTIFYCMD` local a `logger`, sin acciones destructivas.
- `04E` ya valida la salida `nut-event` en journal/syslog con eventos sinteticos `ONBATT`, `LOWBATT`, `COMMOK` y `ONLINE`.
- `04F` ya deja una ruta de notificacion externa `best-effort` por `curl` + `ntfy`, condicionada a secretos locales fuera de git.
- `04F.1` ya deja `ntfy` corriendo en `orangepi5-ultra` en `http://192.168.0.14:8080`, con topic no trivial distribuido via `/opt/colibri-secrets/ntfy.env`.
- `services` contradice la doc vieja: no ve UPS local y no debe ser `NUT master`.
- `nas` no debe despertarse en bateria aunque su `WOL` este habilitado hoy.
- `ai-gpu` recupero `SSH` en esta ventana y quedo con `WOL` habilitado, pero no mostro UPS local.
- `orangepi5-ultra` si respondio por `SSH` al cierre de la ventana y tambien quedo con `WOL` habilitado.
- la topologia fisica ya esta identificada, pero `Microplan 04B` sigue bloqueado hasta decidir como conviviran la `LinkedPro` instrumentada y la `Epcom` no instrumentada dentro del runbook y de la futura config `NUT`.
- `04A.2` ya cierra una duda importante: no vale la pena rediseñar `04B` esperando telemetria Linux real de la `Epcom`.
- `04B` ya no esta bloqueado para observacion local; el siguiente paso posible es `04C` con clientes `NUT` remotos todavia sin shutdown automatico.
- `04C` ya no depende de abrir exposicion global: `upsd` escucha en `127.0.0.1`, `::1` y `192.168.0.10:3493`.
- `04D` ya no depende de eventos reales para validar la politica: `upsmon` cargo mensajes y flags no destructivos en todos los nodos observadores.
- `04E` ya no deja duda sobre la cadena de notificacion: `upsmon`, `NOTIFYCMD` y `logger` funcionan sin apagar ni despertar nada.
- `04F` no encontro `ntfy.env`, asi que la integracion externa queda preparada pero sin entrega real todavia.
- `04F.1` ya desbloquea entrega local real de alertas sin exponer `ntfy` a Internet.
- `04A.1` ya no queda solo como inventario: en todos los nodos principales `ethtool` expuso `Supports Wake-on` y el estado actual quedo en `Wake-on: g`.
- el siguiente trabajo ya no es descubrir soporte, sino decidir persistencia y politica real de uso por nodo.
- no se recomienda usar canaries activos o heartbeats energeticos: `NUT` ya entrega la senal correcta de la `LinkedPro` y los heartbeats solo agregarian gasto y ambiguedad.

## Recomendacion `04A.1`

- prueba real futura de `WOL`: `no-go` para fase amplia
- motivo:
  - aunque todos quedaron `confirmed` en runtime, todavia falta definir persistencia y politicas de uso
  - `nas` y `ai-gpu` siguen prohibidos para wake en bateria
  - antes de una fase amplia conviene hacer una prueba controlada por tandas y con gating de energia

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
