# Colibrí — Matriz Local-First por Servicio

Fuente base:

- [white-enciso-multisite.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-multisite.md), secciones `7` a `13`
- [white-enciso-sync-policy.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-sync-policy.md)
- [03-storage-local-first.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-microplans/03-storage-local-first.md)

## Convención

- `storage_readiness`
  - `ready`: el patrón local-first y la ruta de archivo final ya están claros para este servicio
  - `needs-sync-plan`: falta cerrar qué dataset se sincroniza o cómo se clasifica entre `docs` y `media`
  - `needs-energy-policy`: el patrón de storage existe, pero depende de política de wake/sleep, hot set o librería final remota
  - `defer`: storage no es el cuello de botella principal de esta fase, o el servicio no es candidato actual
- `operational_readiness`
  - `simple-deploy`: no se ve un bloqueo operacional fuerte más allá del despliegue normal
  - `needs-service-plan`: requiere runbook o diseño específico por DB, estado, seguridad o comportamiento
  - `core-infra`: pertenece a infraestructura y lo gobierna otro microplan
  - `defer-until-implemented`: todavía no existe implementación base o depende de otro servicio primero
- `redundancy_required`
  - `required`
  - `optional`
  - `none`

Patrón de sync final validado en `03B`:

```bash
sudo -u apps rsync -avh --chown=apps:docs_rw  --chmod=D2775,F664 SRC/ /srv/docs/DEST/
sudo -u apps rsync -avh --chown=apps:media_rw --chmod=D2775,F664 SRC/ /srv/media/DEST/
```

## Core e infraestructura

| Servicio | target_node | storage_readiness | operational_readiness | runtime path local | cache/staging path local | backup/archive path | nas dormido | tipo de sync | redundancy_required | blocking_microplan | notes/risk |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Pi-hole primario | `management` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | `05-dns-pihole` | no usar `nas` para runtime |
| Pi-hole secundario | `orangepi5-ultra` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | `05-dns-pihole` | resiliencia DNS local |
| Pi-hole terciario opcional | `orangepi5-max` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `optional` | `05-dns-pihole` | fallback local adicional |
| Caddy principal | `management` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | `06-reverse-proxy-cloudflared` | infraestructura core, no tema de storage |
| Caddy backup | `orangepi5-ultra` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | `06-reverse-proxy-cloudflared` | requiere redundancia local |
| cloudflared principal | `management` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | `06-reverse-proxy-cloudflared` | secretos y túneles fuera de storage |
| cloudflared backup | `orangepi5-ultra` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | `06-reverse-proxy-cloudflared` | requiere redundancia local |
| Tailscale | `todos los nodos principales` | `defer` | `core-infra` | local a cada nodo | none | none | `sí` | `none` | `required` | `01-network-and-addressing` o microplan Tailscale futuro | acceso admin, no storage runtime |
| Tailscale subnet router principal | `management` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | microplan Tailscale futuro | rol específico, no decidido por storage |
| Tailscale subnet router secundario | `orangepi5-ultra` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | microplan Tailscale futuro | respaldo admin |
| WireGuard site-to-site | `management` o gateway dedicado | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | microplan WireGuard futuro | backbone privado inter-sede |
| colibri-sentinel-bot | `management` + `orangepi5-ultra` | `ready` | `needs-service-plan` | local al nodo | `/storage/cache` si vive en `services` | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | `10-sentinel-bot`, `14-observability-alerting` | requiere implementación previa y plan de observabilidad |
| Uptime Kuma | `management` | `ready` | `simple-deploy` | volumen local del nodo | none | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | none | buen candidato admin-first |
| ntfy | `orangepi5-ultra` o `management` | `ready` | `simple-deploy` | volumen local del nodo | none | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | none | despliegue inicial puede ser directo, pero el estado objetivo es `Docker Compose` versionado con secretos fuera de git |
| Diun | `management` | `ready` | `simple-deploy` | local al nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `none` | none | casi stateless |
| Restic/Kopia | `services` | `ready` | `simple-deploy` | `/storage/apps/restic-kopia` | `/storage/sync-out` | `nas:/srv/docs/backups` | `parcial` | `backup` | `optional` | none | puede operar local, target final por ventana |
| Homepage | `management` | `ready` | `simple-deploy` | volumen local del nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `optional` | none | ya desplegado en `management` con runtime en `/opt/stacks/homepage`, backend `127.0.0.1:8080`, proxy local por `Caddy` en `home.white-enciso.com` y curacion inicial sin secretos para operaciones, DNS, alerting y servicios staged |
| Emergency Homepage | `orangepi5-ultra` | `ready` | `simple-deploy` | volumen local del nodo | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `required` | none | dashboard resiliente mínimo |

## Identidad y seguridad

| Servicio | target_node | storage_readiness | operational_readiness | runtime path local | cache/staging path local | backup/archive path | nas dormido | tipo de sync | redundancy_required | blocking_microplan | notes/risk |
|---|---|---|---|---|---|---|---|---|---|---|---|
| authentik | `services` | `ready` | `needs-service-plan` | `/storage/apps/authentik` | `/storage/cache` | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | `09-identity-and-sso` | storage listo, operación bloqueada por SSO/seguridad |
| Vaultwarden | `services` | `ready` | `needs-service-plan` | `/storage/apps/vaultwarden` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | `09-identity-and-sso` | single-writer, datos sensibles |
| Portainer Server | `management` | `ready` | `simple-deploy` | volumen local en `management` | none | opcional `nas:/srv/docs/backups` | `sí` | `config-export` | `optional` | none | privado/Tailscale solamente; herramienta de operacion/visibilidad, no fuente primaria de configuracion; `Git + Compose` mandan |
| Portainer Agent | `services`, `orangepi5-ultra`, `orangepi5-max`; `ai-gpu` cuando tenga workloads GPU | `defer` | `simple-deploy` | local al nodo | none | none | `sí` | `none` | `optional` | none | solo por red privada; `nas` opcional si corre contenedores; `orangepi5-a/b` deferidos |
| Dockge | `management` preferido, o `services` | `ready` | `simple-deploy` | `/storage/apps/dockge` si vive en `services`, o volumen local en `management` | none | opcional `nas:/srv/docs/backups` | `sí` | `config-export` | `optional` | none | privado/Tailscale solamente; herramienta de operacion/visibilidad, no fuente primaria de configuracion; `Git + Compose` mandan |
| CrowdSec | `defer` | `defer` | `core-infra` | local al nodo | none | opcional `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | `06-reverse-proxy-cloudflared` o seguridad futura | fuera de fase actual |

## Servicios de usuario

| Servicio | target_node | storage_readiness | operational_readiness | runtime path local | cache/staging path local | backup/archive path | nas dormido | tipo de sync | redundancy_required | blocking_microplan | notes/risk |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Paperless-ngx | `services` | `ready` | `needs-service-plan` | `/storage/apps/paperless` | `/storage/inbox` | `nas:/srv/docs` | `sí` | `archive` | `optional` | none | storage listo; falta runbook app/DB/ingest |
| SFTPGo | `services` | `needs-sync-plan` | `needs-service-plan` | `/storage/apps/sftpgo` | `/storage/inbox`, `/storage/sync-out` | `nas:/srv/docs` o `nas:/srv/media` | `parcial` | `archive` | `optional` | none | falta clasificar datasets y política de shares |
| Immich core | `services` | `ready` | `needs-service-plan` | `/storage/apps/immich` | `/storage/media-staging` | `nas:/srv/media` opcional/posterior | `sí` | `archive` | `optional` | none | storage listo; falta runbook de DB/uploads |
| Mealie | `services` | `ready` | `simple-deploy` | `/storage/apps/mealie` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | mejor primer candidato simple familiar |
| Homebox | `services` | `ready` | `simple-deploy` | `/storage/apps/homebox` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | muy buen candidato simple |
| BookStack | `services` | `ready` | `simple-deploy` | `/storage/apps/bookstack` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | none | DB local pero patrón simple |
| Memos | `services` | `ready` | `simple-deploy` | `/storage/apps/memos` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | simple y local-first |
| Actual Budget | `services` | `ready` | `simple-deploy` | `/storage/apps/actual-budget` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | datos sensibles, pero storage claro |
| Wallos | `services` | `ready` | `simple-deploy` | `/storage/apps/wallos` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | patrón simple |
| Stirling PDF | `services` | `ready` | `simple-deploy` | `/storage/apps/stirling-pdf` | `/storage/inbox` | opcional `nas:/srv/docs` | `sí` | `archive` | `none` | none | tmp local, archive opcional |
| IT-Tools | `management` preferido, o `services` | `ready` | `simple-deploy` | volumen local del nodo elegido | none | opcional `nas:/srv/docs` | `sí` | `config-export` | `none` | none | si es herramienta admin, preferir `management` |

## Media

| Servicio | target_node | storage_readiness | operational_readiness | runtime path local | cache/staging path local | backup/archive path | nas dormido | tipo de sync | redundancy_required | blocking_microplan | notes/risk |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Jellyfin | `ai-gpu` | `needs-energy-policy` | `needs-service-plan` | volumen local del nodo | cache/transcode local | `nas:/srv/media` | `parcial` | `media-final` | `optional` | política de energía/media futura | GPU + librería final remota |
| Navidrome | `services` | `needs-energy-policy` | `needs-service-plan` | `/storage/apps/navidrome` | cache local | `nas:/srv/media` | `parcial` | `media-final` | `optional` | política de energía/media futura | DB local, biblioteca remota |
| ListenBrainz | externo | `defer` | `defer` | externo | none | none | `sí` | `none` | `none` | none | fuera de `Colibrí` |
| Explo | `services` | `ready` | `needs-service-plan` | `/storage/apps/explo` | cache local | none o indirecto a `nas:/srv/media` | `sí` | `config-export` | `none` | none | depende de Navidrome/servicio upstream |
| Arr stack | `services` | `needs-sync-plan` | `needs-service-plan` | `/storage/apps/arr-stack` | `/storage/media-staging` | `nas:/srv/media` | `sí` | `archive` | `optional` | none | falta plan de naming, import y sync |
| Jellyseerr | `services` | `ready` | `simple-deploy` | `/storage/apps/jellyseerr` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | útil cuando Arr/Jellyfin existan |
| Audiobookshelf | `services` | `needs-energy-policy` | `needs-service-plan` | `/storage/apps/audiobookshelf` | cache local | `nas:/srv/media` | `parcial` | `media-final` | `optional` | política de energía/media futura | librería final remota |
| Kavita | `services` | `needs-energy-policy` | `needs-service-plan` | `/storage/apps/kavita` | cache local | `nas:/srv/media` | `parcial` | `media-final` | `optional` | política de energía/media futura | librería final remota |
| Tube Archivist | `services` | `needs-energy-policy` | `needs-service-plan` | `/storage/apps/tube-archivist` | `/storage/media-staging` | `nas:/srv/media` opcional | `parcial` | `media-final` | `optional` | política de energía/media futura | consumo local alto + librería final |

## IA y agentes

| Servicio | target_node | storage_readiness | operational_readiness | runtime path local | cache/staging path local | backup/archive path | nas dormido | tipo de sync | redundancy_required | blocking_microplan | notes/risk |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hermes Agent | `services` | `ready` | `needs-service-plan` | `/storage/apps/hermes-agent` | `/storage/cache` | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | none | requiere plan de servicio/seguridad |
| Open WebUI | `services` | `ready` | `needs-service-plan` | `/storage/apps/open-webui` | `/storage/cache` | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | none | requiere plan de servicio/seguridad, no simple-deploy |
| Ollama liviano | `services` | `ready` | `needs-service-plan` | `/storage/apps/ollama` | `/storage/cache` | none | `sí` | `none` | `none` | none | requiere plan de servicio/seguridad y modelos |
| Ollama/vLLM pesado | `ai-gpu` | `defer` | `defer` | local al nodo | local cache | none | `sí` | `none` | `optional` | none | fuera de fase de storage simple |
| Qdrant | `services` | `ready` | `needs-service-plan` | `/storage/apps/qdrant` | none | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | none | vector DB requiere plan específico |
| SearXNG | `services` | `ready` | `simple-deploy` | `/storage/apps/searxng` | `/storage/cache` | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | cache local controlable |
| Whisper | `ai-gpu` | `defer` | `defer` | local al nodo | local tmp/cache | none | `sí` | `none` | `none` | none | job puntual, no despliegue de esta fase |
| OCR pesado | `ai-gpu` | `defer` | `defer` | local al nodo | local tmp/cache | opcional `nas:/srv/docs` | `sí` | `archive` | `none` | none | batch, no despliegue de esta fase |
| changedetection.io | `services` | `ready` | `simple-deploy` | `/storage/apps/changedetection` | `/storage/cache` | `nas:/srv/docs/backups` | `sí` | `backup` | `none` | none | estado local sencillo |

## Storage y archivo

| Servicio | target_node | storage_readiness | operational_readiness | runtime path local | cache/staging path local | backup/archive path | nas dormido | tipo de sync | redundancy_required | blocking_microplan | notes/risk |
|---|---|---|---|---|---|---|---|---|---|---|---|
| NAS / NFS | `nas` | `defer` | `defer` | discos locales del `nas` | none | `nas:/srv/media`, `nas:/srv/docs` | `no` | `none` | `required` | none | archivo final, no candidato de despliegue app |
| Backups finales | `nas` | `defer` | `defer` | storage del `nas` | none | `nas:/srv/docs` y/o backend final | `no` | `backup` | `required` | none | función archivística |
| Media final | `nas` | `defer` | `defer` | storage del `nas` | none | `nas:/srv/media` | `no` | `media-final` | `required` | none | biblioteca final |
| Docs finales | `nas` | `defer` | `defer` | storage del `nas` | none | `nas:/srv/docs` | `no` | `archive` | `required` | none | archivo final documental |
| Sync jobs | `services` | `needs-energy-policy` | `needs-service-plan` | `/storage/sync-out` | `/storage/sync-out` | `nas:/srv/media`, `nas:/srv/docs` | `parcial` | `archive` | `optional` | política de energía futura | necesitan ventanas, locks y wake policy |

## Matrix

| Servicio | target_node | storage_readiness | operational_readiness | runtime path local | cache/staging path local | backup/archive path | nas dormido | tipo de sync | redundancy_required | blocking_microplan | notes/risk |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Matrix Synapse Colibrí | `services` | `ready` | `needs-service-plan` | `/storage/apps/matrix-synapse` | local tmp/cache | `nas:/srv/docs/backups` | `sí` | `backup` | `optional` | none | DB + media store + single-writer |
| Matrix bots Colibrí | `services` o `management` | `ready` | `defer-until-implemented` | volumen local del nodo | `/storage/cache` si viven en `services` | `nas:/srv/docs/backups` | `sí` | `config-export` | `optional` | `13-matrix` o implementación futura | no implementados aún; dependen de Matrix |
