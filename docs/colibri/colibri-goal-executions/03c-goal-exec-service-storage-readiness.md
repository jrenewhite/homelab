# Microplan 03C Execution - Service Storage Readiness Reclassification

- Fecha de ejecución: `2026-05-27`
- Operador: `Codex`
- Estado: `completed`
- Resultado: `go for next subphase of Microplan 03; no-go for Microplan 04`

## Resumen

Se corrigió la clasificación de `03C` para separar dos cosas distintas:

1. `storage_readiness`
2. `operational_readiness`

La versión previa mezclaba readiness de storage con readiness de despliegue. Eso quedó corregido.

Ahora la matriz distingue además:

- `target_node`
- `redundancy_required`
- `blocking_microplan`
- `notes/risk`

Lectura central:

- `Microplan 03` decide si el patrón local-first y el destino final están claros
- `Microplan 03` no autoriza por sí solo el despliegue operacional de un servicio

## Correcciones aplicadas

### Infraestructura core

Se corrigieron nodos objetivo y clasificación:

- `Homepage` -> `management`
- `Emergency Homepage` -> `orangepi5-ultra`
- `Uptime Kuma` -> `management`
- `Diun` -> `management`
- `ntfy` -> `orangepi5-ultra` o `management`
- `IT-Tools` -> preferencia `management` si es herramienta admin
- `Portainer` -> `management` o `services`, privado/Tailscale
- `Dockge` -> `management` o `services`, privado/Tailscale

Servicios como `Caddy`, `cloudflared`, `Tailscale` y `WireGuard` ya no quedaron como `defer` genérico:

- ahora figuran como `core-infra`
- o con `blocking_microplan` explícito, por ejemplo:
  - `06-reverse-proxy-cloudflared`
  - microplan Tailscale futuro
  - microplan WireGuard futuro

### Bots y agentes

Se corrigió:

- `Matrix bots Colibrí` ya no queda `ready-for-deploy`
  - ahora: `storage_readiness=ready`
  - `operational_readiness=defer-until-implemented`
- `colibri-sentinel-bot`
  - ahora: `storage_readiness=ready`
  - `operational_readiness=needs-service-plan`
  - bloqueado además por observabilidad

### IA y seguridad

Se corrigió que estos no deben salir como listos para deploy simple:

- `Open WebUI`
- `Ollama liviano`
- `Qdrant`
- `Hermes Agent`

Ahora quedan como:

- `storage_readiness=ready`
- `operational_readiness=needs-service-plan`

### Media dependiente de NAS/GPU

Se mantuvieron bloqueados por política de energía o media:

- `Jellyfin`
- `Navidrome`
- `Audiobookshelf`
- `Kavita`
- `Tube Archivist`
- `Sync jobs`

## Servicios listos solo por storage

Estos ya tienen patrón local-first suficientemente claro, pero siguen bloqueados por operación, seguridad, implementación o energía:

- `authentik`
- `Vaultwarden`
- `Paperless-ngx`
- `Immich core`
- `Explo`
- `Hermes Agent`
- `Open WebUI`
- `Ollama liviano`
- `Qdrant`
- `Matrix Synapse Colibrí`
- `Matrix bots Colibrí`
- `colibri-sentinel-bot`

## Servicios realmente listos para deploy simple

- `Uptime Kuma`
- `ntfy`
- `Diun`
- `Restic/Kopia`
- `Homepage`
- `Emergency Homepage`
- `Portainer`
- `Dockge`
- `Mealie`
- `Homebox`
- `BookStack`
- `Memos`
- `Actual Budget`
- `Wallos`
- `Stirling PDF`
- `IT-Tools`
- `Jellyseerr`
- `SearXNG`
- `changedetection.io`

## Servicios core-infra

- `Pi-hole` primario
- `Pi-hole` secundario
- `Pi-hole` terciario opcional
- `Caddy` principal
- `Caddy` backup
- `cloudflared` principal
- `cloudflared` backup
- `Tailscale`
- `Tailscale subnet router principal`
- `Tailscale subnet router secundario`
- `WireGuard site-to-site`

## Servicios que requieren redundancia

- `Pi-hole` primario/secundario
- `Caddy` principal/backup
- `cloudflared` principal/backup
- `Tailscale` subnet routers
- `colibri-sentinel-bot`
- `Emergency Homepage`
- funciones finales de `nas`

## Servicios bloqueados por Microplan 06

- `Caddy` principal
- `Caddy` backup
- `cloudflared` principal
- `cloudflared` backup
- `CrowdSec` en su lectura actual de exposición futura

## Bots que requieren implementación previa

- `Matrix bots Colibrí`
- `colibri-sentinel-bot`

## Actualizaciones realizadas

- [colibri-service-local-first-matrix.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-service-local-first-matrix.md)
- [03-storage-local-first.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-microplans/03-storage-local-first.md)
- [03c-goal-exec-service-storage-readiness.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-goal-executions/03c-goal-exec-service-storage-readiness.md)

## Anomalías

- ninguna anomalía operativa nueva
- la corrección fue puramente documental

## Recomendación revisada del primer servicio a desplegar

Primer servicio recomendado:

- `Mealie`

Razón:

- `storage_readiness=ready`
- `operational_readiness=simple-deploy`
- vive claramente en `services`
- no depende de `nas` para arrancar
- no requiere redundancia
- no depende de `Microplan 06`
- no exige política de energía

Siguientes candidatos razonables:

- `Homebox`
- `Memos`
- `Wallos`
- `IT-Tools` si se quiere un servicio más administrativo y simple

Recomendación final:

- siguiente subfase de `Microplan 03`: `go`
- `Microplan 04`: `no-go`

Antes de `Microplan 04`, sigue siendo mejor desplegar al menos un servicio realmente simple con storage local-first cerrado y backup definido.
