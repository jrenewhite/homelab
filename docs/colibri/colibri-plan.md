# Colibri

> Estado documental:
> Este documento se conserva como resumen inicial de trabajo. La arquitectura aprobada y el diseño `decision complete` viven en [colibri-master-plan.md](./colibri-master-plan.md) y [colibri-microplans](./colibri-microplans).

## Resumen

Casa 1 sera la base del homelab. La prioridad recomendada es:

1. Dejar red y nombres fijos
2. Definir una base 24/7 de bajo consumo
3. Instalar almacenamiento y servicios core
4. Reservar la GPU para cargas pesadas o puntuales
5. Documentar y automatizar

## Inventario declarado

### Red

- Internet: Starlink
- Router: TP-Link ER707-M2
- Switches: TP-Link DS105G-M2, TP-Link SG108
- Acceso remoto actual: Tailscale, Cloudflare Tunnel con `white-enciso.com`

### Compute

- Minisforum 890 Pro, 64 GB RAM, 2 NVMe
- Minisforum 790S7, 64 GB RAM, 2 NVMe, RTX 5060 8 GB VRAM
- HP EliteDesk 800 G4 Mini, 16 GB RAM, 1 NVMe
- Orange Pi 5 Ultra, 16 GB RAM, 1 NVMe
- Orange Pi 5 Max, 8 GB RAM, 1 NVMe
- 2 x Orange Pi 5, 8 GB RAM, 1 NVMe

### Almacenamiento

- AOOSTAR WTR Pro, 64 GB RAM
- 2 x IronWolf 4 TB en RAID1
- 2 x IronWolf Pro 12 TB en RAID1
- 3 x NVMe: 1 para SO, 2 para cache o aceleracion

### Servicios deseados

- Pi-hole
- Arr stack
- Paperless
- Immich
- Portainer
- Vaultwarden
- Jellyfin
- Home Assistant

## Hallazgos observados desde esta maquina

### Red actual

- LAN operativa unica: `192.168.0.0/24`
- Gateway: `192.168.0.1`
- Red Tailscale visible: `100.107.33.127`

### Nodos principales actuales

- `ai-gpu`: lease observado `192.168.0.186`; objetivo final `192.168.0.13`
- `nas`: lease observado `192.168.0.190`; objetivo final `192.168.0.11`
- `orangepi5-ultra`: lease observado `192.168.0.178`; objetivo final `192.168.0.14`
- `orangepi5-max`: lease observado `192.168.0.181`; objetivo final `192.168.0.15`
- `orangepi5-a`: lease observado `192.168.0.187`; objetivo final `192.168.0.16`
- `orangepi5-b`: lease observado `192.168.0.193`; objetivo final `192.168.0.17`
- `services`: lease observado `192.168.0.185`; objetivo final `192.168.0.12`
- `management`: lease observado `192.168.0.172`; objetivo final `192.168.0.10`

### Lectura preliminar

- La red base final para `Colibri` es `192.168.0.0/24`.
- El router `ER707-M2` ya responde por `SSH` y las reservas DHCP ya fueron importadas, pero varios nodos siguen temporalmente en leases previos.
- Los 8 nodos principales ya responden por `SSH`.
- `nas` ya expone `/srv/media` y `/srv/docs` por `NFS`.
- `services` ya monta ambos exports por `NFS`.
- `services`, `management` y las cuatro Orange Pi ya tienen `Docker` operativo.
- `management` ya tiene `Ansible` y `NUT` instalados.

## Arquitectura objetivo recomendada

### Principio rector

Reducir huella energetica sin perder capacidades.

La idea recomendada para `Colibri` es dividir el homelab en dos capas:

- capa 24/7 de bajo consumo para servicios criticos y livianos
- capa de alto rendimiento bajo demanda para multimedia, IA o procesos pesados

## Capa 1: red y acceso

- Mantener una sola LAN principal: `192.168.0.0/24`
- Reservar IPs estaticas o DHCP reservations para todo equipo de infraestructura
- Mantener `Tailscale` como acceso administrativo principal
- Usar `Cloudflare Tunnel` solo para servicios web concretos que de verdad quieras publicar
- Evitar exponer paneles administrativos directamente a internet

## Capa 2: plataforma

Recomendacion principal orientada a energia:

- `AOOSTAR WTR Pro` como NAS principal, idealmente siempre encendido
- `HP EliteDesk 800 G4 Mini` como nodo x86 principal 24/7
- `Orange Pi` como nodos ligeros 24/7 para DNS, agentes y servicios pequenos
- `Minisforum 790S7` como nodo de rendimiento con GPU
- `Minisforum 890 Pro` como nodo de expansion, pruebas o segundo host potente solo si hace falta

Razonamiento:

- `EliteDesk` y `Orange Pi` ofrecen mejor relacion consumo-utilidad para servicios continuos
- El `AOOSTAR` tiene sentido encendido por ser el almacenamiento central
- La `Minisforum` con GPU debe usarse donde realmente amortice su consumo: transcodificacion, procesamiento de imagen o inferencia
- El segundo Minisforum puede quedarse apagado o en standby gran parte del tiempo si el objetivo principal es ahorrar energia

## Capa 3: roles sugeridos por equipo

### Nodo 1: AOOSTAR WTR Pro

- NAS principal
- namespaces unificados:
- `media`
- `docs`
- layout fisico:
- `media-warm` en NVMe
- `media-cold` en RAID1 de `12 TB`
- `docs-warm` en NVMe
- `docs-cold` en RAID1 de `4 TB`
- movimiento `warm -> cold` automatizado por `systemd timers`

### Nodo 2: HP EliteDesk 800 G4 Mini

- nodo x86 principal 24/7
- `Ubuntu 26.04` con `Docker`
- `Pi-hole` principal
- `Vaultwarden`
- `Paperless`
- `Portainer`
- `Tailscale`
- automatizaciones o servicios internos ligeros

### Nodo 3: Orange Pi

- `Pi-hole` secundario en `ultra`; `max` como terciario opcional
- `Home Assistant`, si usas dongles o integraciones que prefieras aislar
- agentes de monitoreo
- tareas ligeras y servicios auxiliares
- laboratorio de bajo consumo

### Nodo 4: Minisforum 790S7

- nodo de alto rendimiento
- `Ubuntu Server` con Docker
- `Jellyfin` con aceleracion por GPU
- `Immich` si quieres ML o procesamiento mas rapido
- inferencia local o experimentos de IA mas adelante
- cargas no permanentes o programadas

### Nodo 5: Minisforum 890 Pro

- nodo principal de servicios
- `Ubuntu 26.04` con `Docker`
- `Portainer`
- `Arr stack`
- servicios de aplicacion
- uso de NVMe local y consumo de `NFS` desde el NAS

## Distribucion inicial de servicios

### Core primero

- `NAS`
- `Tailscale`
- `Pi-hole` principal y secundario
- backups
- NTP y DNS estables

### Despues aplicaciones

- `Vaultwarden`
- `Portainer`
- `Paperless`
- `Home Assistant`

### Al final cargas pesadas

- `Arr stack`
- `Jellyfin`
- `Immich`

## Reparto recomendado por consumo

### Siempre encendidos

- `AOOSTAR`
- `HP EliteDesk`
- 1 o 2 `Orange Pi`

### Encendido segun demanda

- `Minisforum 790S7` con GPU
- `Minisforum 890 Pro`

## Uso recomendado de la GPU

La `Minisforum 790S7` con GPU tiene mas sentido para:

- transcodificacion de `Jellyfin`
- procesamiento pesado de `Immich`
- modelos locales o inferencia ligera
- tareas batch como conversion de video o analisis de imagen

No tiene tanto sentido dejarla encendida solo para:

- `Pi-hole`
- `Vaultwarden`
- `Paperless`
- `Portainer`
- servicios pequeños de administracion

## Plan de direccionamiento sugerido

Propuesta final dentro de `192.168.0.0/24`:

- `.1` router
- `.10` `management`
- `.11` `nas`
- `.12` `services`
- `.13` `ai-gpu`
- `.14` `orangepi5-ultra`
- `.15` `orangepi5-max`
- `.16` `orangepi5-a`
- `.17` `orangepi5-b`

## Orden de implementacion recomendado

1. Verificar que las reservas DHCP del router estén activas
2. Mantener DHCP en el router y usar `Pi-hole` solo como DNS
3. Renovar lease o reiniciar nodos por tandas pequeñas hasta que tomen sus nuevas IPs
4. Estandarizar `SSH key` y hostnames finales despues de las nuevas IPs
5. Desplegar `Pi-hole`, `Vaultwarden`, `Paperless` y `Portainer`
6. Integrar `Home Assistant` en `Orange Pi` si conviene por perifericos o aislamiento
7. Activar `ai-gpu` solo bajo demanda para GPU dedicada
6. Documentar credenciales, DNS, dominios, shares y restauracion

## Riesgos y decisiones pendientes

- Aplicar reservas DHCP del router y validar que todos los nodos tomen su IP final
- Auditar por que `media` ya tenia `214G` ocupados tras el rediseño del `NAS`
- Definir si `Home Assistant` vivira mejor en `Orange Pi` o en x86
- Definir politica de backups para datos y configuracion

## Siguiente paso recomendado

Aplicar reservas DHCP del documento [colibri-router-baseline.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-router-baseline.md) y despues comenzar con servicios core sobre `management` y `services`.
