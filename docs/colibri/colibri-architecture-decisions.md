# Colibrí Homelab — Arquitectura objetivo y decisiones

> Estado documental:
> Este documento conserva decisiones y contexto útil, pero la fuente de verdad aprobada para el diseño pasa a ser [colibri-master-plan.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-master-plan.md) y los anexos en [colibri-microplans](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-microplans).

Documento de arquitectura para el homelab de la casa `Colibri`.

Este documento consolida las decisiones tomadas para servicios, energía, failover, almacenamiento, IA/LLMs, Matrix, Home Assistant, Pi-hole, reverse proxy, Cloudflare Tunnel, Arr stack y bot de resiliencia.

---

## 1. Principio rector

Colibrí se diseñará como un homelab por capas de energía y responsabilidad:

```text
management = red, control básico, DNS primario, cloudflared/Caddy principal
services   = vida digital principal, Matrix, Hermes, LLM liviana, apps y Arr stack
ai-gpu     = músculo pesado: LLM grande, Jellyfin GPU, Immich ML, OCR, batch
opi-ultra  = supervivencia/domótica: Home Assistant, DNS secundario, sentinel
opi-max    = sentinela secundaria y worker ARM
opi-a/b    = watchdogs, DNS extra opcional y workers stateless
nas        = bóveda fría despertable, backups y archivo final
```

La meta es que el sistema sea útil y resiliente sin depender de que todos los nodos estén encendidos todo el tiempo.

---

## 2. Nodos y roles

| Nodo | Rol principal | Estado esperado |
|---|---|---|
| `management` / HP EliteDesk | Control plane, DNS primario, reverse proxy principal, cloudflared principal, WOL, Ansible | 24/7 |
| `services` / UM890 | Matrix, Hermes Agent, LLM diaria, apps principales, Arr stack, staging/cache local | 24/7-ish |
| `ai-gpu` / 790S7 | GPU pesada, LLM grande, Jellyfin con GPU, Immich ML, Whisper/OCR/batch | Bajo demanda |
| `nas` / WTR Pro | NFS, backups, archivo frío, snapshots, almacenamiento maestro | Despertable |
| `orangepi5-ultra` | Home Assistant, MQTT, Pi-hole secundario, Caddy/cloudflared backup, sentinel | 24/7 |
| `orangepi5-max` | Sentinel secundario, worker ARM, backup ligero | 24/7 |
| `orangepi5-a` | DNS terciario opcional, watchdog, worker stateless | 24/7 |
| `orangepi5-b` | Healthcheck, watchdog, worker stateless | 24/7 |

---

## 3. Direccionamiento objetivo

Según baseline del router:

| Host | IP objetivo |
|---|---|
| Router | `192.168.0.1` |
| `management` | `192.168.0.10` |
| `nas` | `192.168.0.20` |
| `services` | `192.168.0.30` |
| `ai-gpu` | `192.168.0.40` |
| `orangepi5-ultra` | `192.168.0.51` |
| `orangepi5-max` | `192.168.0.52` |
| `orangepi5-a` | `192.168.0.53` |
| `orangepi5-b` | `192.168.0.54` |

Reservas DHCP pendientes de aplicar en el `TP-Link ER707-M2`.

---

## 4. Energía y UPS

### Distribución física actual

```text
UPS continuo / smart / NUT:
  - ai-gpu
  - services
  - 4 Orange Pi
  - nas

UPS interactivo / sin NUT real en Linux:
  - Starlink
  - management
  - router
  - switches
```

### Implicación principal

El nodo que debe actuar como `NUT master` no debería ser `management`, porque `management` está en el UPS que no reporta bien por Linux.

Recomendación:

```text
NUT master:
  services

NUT observer / sentinel:
  orangepi5-ultra

NUT clients:
  ai-gpu
  nas
  orangepi5-max
  orangepi5-a
  orangepi5-b

management:
  observador remoto / control plane
```

### Reglas ante corte eléctrico

```text
T+0:
  services detecta UPS en batería
  manda evento a management y orangepi5-ultra
  alerta por Matrix si Matrix está disponible
  alerta por vía alterna si Matrix no está disponible

T+1-2 min:
  bloquear WOL de ai-gpu y nas
  pausar jobs pesados
  pausar descargas Arr
  apagar ai-gpu si está encendido y no hay tarea crítica

T+5 min:
  si nas está despierto, sync mínimo y shutdown

Batería baja:
  apagar ordenadamente services/nas/ai-gpu
  mantener Orange Pi el mayor tiempo posible
  management conserva red/control hasta donde aguante su UPS
```

---

## 5. Reverse proxy y Cloudflare Tunnel

### Decisión

Usar **Caddy** como reverse proxy interno principal.

Razones:

- configuración simple y declarativa;
- buena ergonomía para homelab;
- reverse proxy y health checks;
- fácil replicar configuración entre `management` y `orangepi5-ultra`;
- menos complejidad inicial que Traefik, HAProxy o Nginx puro.

### Arquitectura

```text
Internet
  ↓
Cloudflare
  ↓
cloudflared tunnel
  ↓
Caddy interno
  ↓
servicios internos
```

### Nodos

```text
management:
  - Caddy principal
  - cloudflared connector principal

orangepi5-ultra:
  - Caddy backup
  - cloudflared connector secundario
```

Ambos pueden correr conectores del mismo túnel para redundancia.

### Servicios expuestos candidatos

| Hostname | Backend |
|---|---|
| `matrix.white-enciso.com` | `services:8008` |
| `hermes.white-enciso.com` | `services:<puerto>` |
| `paperless.white-enciso.com` | `services:<puerto>` |
| `immich.white-enciso.com` | `services:<puerto>` |
| `ha.white-enciso.com` | `orangepi5-ultra:8123` |

### Servicios que deberían quedarse por Tailscale

- Portainer.
- OMV/NAS admin.
- Uptime Kuma admin.
- Grafana/Prometheus.
- SSH.
- Paneles administrativos sensibles.
- APIs internas de WOL/shutdown.

---

## 6. Pi-hole y DNS resiliente

### Decisión inicial

```text
Pi-hole primario:
  management / 192.168.0.10

Pi-hole secundario:
  orangepi5-ultra / 192.168.0.51

Pi-hole terciario opcional:
  orangepi5-a / 192.168.0.53
```

### DHCP del router

```text
DNS 1 = 192.168.0.10
DNS 2 = 192.168.0.51
```

Esto no es un failover perfecto porque muchos clientes no tratan el DNS secundario como respaldo estricto, pero sí ofrece redundancia práctica para la casa.

### Fase posterior opcional

Implementar VIP con `keepalived`:

```text
192.168.0.5 = dns.colibri.lan
```

Pero no se recomienda empezar con VIP hasta estabilizar la red y los servicios.

---

## 7. Matrix y comunicación

### Decisión

Matrix vivirá en `services`.

```text
services:
  - Synapse
  - PostgreSQL
  - media store local
  - backups hacia nas
```

Cliente:

```text
Android:
  - Element X
```

Se descarta hospedar Element Web por ahora.

### Flujo

```text
Element X en Android
  ↓
matrix.white-enciso.com
  ↓
Cloudflare Tunnel
  ↓
Caddy
  ↓
Synapse en services
```

### Failover

Si cae `management`:

```text
orangepi5-ultra:
  - mantiene DNS secundario
  - mantiene Caddy/cloudflared backup
  - Matrix sigue operando porque vive en services
  - manda alerta vía Matrix
```

Si cae `services`:

```text
Matrix cae.
management/ultra deben usar vía alterna.
ultra intenta despertar/reiniciar services.
```

Conclusión importante:

```text
Si cae management, Colibrí debe seguir hablando por Matrix.
Si cae services, Colibrí debe poder avisar por una vía alterna.
```

---

## 8. Vía alterna de alertas

La vía principal será Matrix.

La vía alterna recomendada será Telegram, email o ntfy. La opción inicial preferida es:

```text
Matrix = canal normal
Telegram = canal de emergencia
```

Reglas:

```text
Si Matrix responde:
  alertar por Matrix

Si Matrix no responde:
  alertar por Telegram

Si Internet no responde:
  guardar evento local y reintentar
```

---

## 9. Bot `colibri-sentinel-bot`

### Decisión

Crear un bot propio, versionado y empaquetado como imagen Docker.

```text
colibri-sentinel-bot:v0.1.0
  ├── corre en management como primary
  └── corre en orangepi5-ultra como secondary/standby
```

### Responsabilidades de `management`

```text
ROLE=primary
NODE_NAME=management
```

- Monitorear red, router, Starlink y switches.
- Revisar Caddy/cloudflared local.
- Revisar Pi-hole primario.
- Mandar alertas por Matrix.
- Ejecutar WOL/shutdown.
- Coordinar acciones sobre `services`, `nas`, `ai-gpu`.

### Responsabilidades de `orangepi5-ultra`

```text
ROLE=secondary
NODE_NAME=orangepi5-ultra
```

- Detectar si `management` cayó.
- Mantener Pi-hole secundario.
- Revisar Home Assistant/MQTT.
- Revisar si Matrix sigue vivo en `services`.
- Alertar por Matrix si `services` vive.
- Usar vía alterna si Matrix no vive.
- Intentar despertar/reiniciar `management` o `services`.

### Reglas de liderazgo

```text
management activo:
  management ejecuta acciones
  ultra observa

management caído:
  ultra entra en modo takeover limitado

management regresa:
  ultra vuelve a standby
```

### Health endpoint

Cada instancia debe exponer:

```text
GET /health
GET /status
GET /metrics
```

Ejemplo:

```json
{
  "node": "management",
  "role": "primary",
  "mode": "active",
  "matrix": "ok",
  "internet": "ok",
  "last_check": "2026-05-25T01:20:00-06:00"
}
```

### Comandos deseables

```text
!status
!status full
!wake services
!wake nas
!wake gpu
!sleep nas
!sleep gpu
!check matrix
!check dns
!blackout status
!maintenance on
!maintenance off
```

### Roadmap del bot

```text
v0.1.0:
  - healthchecks ping/http
  - alertas Matrix
  - alertas Telegram fallback
  - WOL para services/nas/ai-gpu
  - roles primary/secondary
  - /health y /status

v0.2.0:
  - integración NUT
  - reglas blackout
  - locks de acciones
  - comandos Matrix

v0.3.0:
  - integración Home Assistant
  - integración n8n/Hermes
  - reportes diarios
  - métricas Prometheus
```

---

## 10. Hermes Agent y LLMs

### Decisión

Hermes Agent de Nous Research vivirá en `services`.

```text
services:
  - Hermes Agent
  - Matrix bot principal
  - Ollama/LLM liviana
  - n8n
```

### Arquitectura

```text
Element X
  ↓
Matrix Synapse
  ↓
Bot Colibrí
  ↓
Hermes Agent
  ├── LLM liviana en services
  ├── LLM pesada en ai-gpu
  ├── n8n workflows
  ├── Home Assistant en opi-ultra
  ├── WOL/shutdown vía management
  └── estado eléctrico vía NUT/services
```

### Separación por tipo de carga

```text
services:
  - modelo pequeño/mediano siempre disponible
  - RAG ligero
  - tools internos
  - respuestas cotidianas

ai-gpu:
  - modelos grandes
  - visión
  - OCR
  - audio/transcripción
  - embeddings pesados
  - batch jobs
```

### Reglas de routing

```text
Prompt simple:
  responder con LLM de services

Prompt pesado:
  despertar ai-gpu
  enrutar a modelo pesado
  apagar ai-gpu tras inactividad

Imagen/audio/OCR:
  despertar ai-gpu si no hay corte eléctrico

Corte eléctrico:
  no despertar ai-gpu ni nas
  responder en modo emergencia

NAS dormido:
  usar cache local
  ofrecer despertar NAS solo si hace falta
```

---

## 11. n8n

n8n vivirá en `services`.

Uso recomendado:

- workflows programados;
- webhooks;
- reportes diarios;
- integración con Matrix;
- integración con Home Assistant;
- tareas de sync;
- avisos de estado;
- disparar scripts de mantenimiento;
- apoyo a Hermes como backend de automatizaciones.

Relación:

```text
Hermes = agente razonador y operador
n8n    = automatización repetible y flujos programados
```

---

## 12. Home Assistant

### Decisión

Home Assistant vivirá en `orangepi5-ultra`.

Servicios relacionados:

```text
orangepi5-ultra:
  - Home Assistant
  - MQTT / Mosquitto
  - Zigbee2MQTT si después aplica
  - Pi-hole secundario
  - Caddy/cloudflared backup
  - colibri-sentinel-bot secondary
```

Razón:

- domótica no debe depender de `services`;
- `orangepi5-ultra` está siempre encendida;
- tiene mejor perfil para supervivencia;
- permite que la casa siga funcionando aunque `services` se reinicie o duerma.

---

## 13. Almacenamiento, cache y NAS

### Decisión

El NAS no será dependencia runtime de todos los servicios.

El NAS será:

```text
nas:
  - archivo frío
  - NFS
  - backups
  - snapshots
  - biblioteca final
```

`services` usará almacenamiento local para trabajo caliente:

```text
/storage/apps
/storage/cache
/storage/inbox
/storage/sync-out
/storage/media-staging
```

NFS desde NAS cuando esté despierto:

```text
/srv/media
/srv/docs
```

### Regla central

```text
services trabaja local.
nas despierta para sincronizar, archivar, respaldar o servir librerías grandes.
```

### Ventana programada sugerida

```text
01:00 despertar nas
01:05 validar NFS
01:10 sync services:/storage/sync-out -> nas:/srv/docs o /srv/media
01:30 backups DBs -> nas
02:00 snapshots/verificación
02:30 apagar nas si no hay actividad
```

---

## 14. Arr stack

### Decisión

El Arr stack vivirá en `services`.

Razón:

- `services` estará casi 24/7;
- tiene almacenamiento local de 1 TB en `/storage`;
- evita despertar el NAS por operaciones pequeñas;
- permite staging, descarga, unpack, renombrado y procesamiento local;
- después mueve biblioteca final al NAS durante ventanas controladas.

### Servicios candidatos

```text
services:
  - Prowlarr
  - Sonarr
  - Radarr
  - Bazarr
  - Recyclarr
  - Cliente de descarga
  - Unpackerr opcional
  - Arr scripts
```

### Flujo recomendado

```text
Descarga/procesamiento:
  services:/storage/media-staging

Cuando NAS despierta:
  mover a nas:/srv/media

Después:
  actualizar índices
  opcionalmente refrescar Jellyfin
  apagar NAS si no hay más actividad
```

### Jellyfin

Jellyfin no vivirá necesariamente junto al Arr stack.

Recomendación:

```text
Arr stack:
  services

Jellyfin:
  ai-gpu, por aceleración GPU

Biblioteca final:
  nas:/srv/media

Cache/contenido frecuente:
  services:/storage/media-hot o ai-gpu local
```

Si se quiere Jellyfin siempre disponible con contenido limitado, se puede añadir una instancia ligera o biblioteca parcial en `services`, pero el Jellyfin principal con transcodificación debería vivir en `ai-gpu`.

---

## 15. Paperless, Immich, Navidrome y archivos

### Paperless

```text
services:
  - Paperless-ngx
  - PostgreSQL/Redis si aplica
  - consume local
  - archivo/sync final hacia NAS
```

### Immich

```text
services:
  - Immich core
  - base de datos
  - uploads recientes/cache local

ai-gpu:
  - ML pesado
  - jobs de visión/embeddings

nas:
  - biblioteca/archivo maestro
```

### Navidrome

```text
services:
  - Navidrome
  - música frecuente cacheada local

nas:
  - biblioteca completa
```

### Compartición de archivos

Candidatos:

```text
services:
  - SFTPGo
  - copyparty
  - File Browser
```

Regla:

```text
Archivos activos en services.
Archivo maestro y backups en nas.
```

---

## 16. Fases de implementación

### Fase 0 — Red estable

- Aplicar reservas DHCP.
- Validar SSH por hostname/IP final.
- Validar Tailscale.
- Validar DNS local.
- Validar WOL en nodos que lo soporten.

### Fase 1 — Supervivencia

- Pi-hole en `management`.
- Pi-hole secundario en `orangepi5-ultra`.
- Caddy en `management`.
- Caddy backup en `orangepi5-ultra`.
- cloudflared en ambos.
- Home Assistant en `orangepi5-ultra`.
- `colibri-sentinel-bot` v0.1.0.

### Fase 2 — Comunicación

- Matrix Synapse en `services`.
- PostgreSQL para Matrix.
- Bot Matrix principal.
- Vía alterna Telegram/ntfy/email.
- Healthchecks de Matrix.

### Fase 3 — IA y automatización

- Hermes Agent en `services`.
- Ollama/LLM liviana en `services`.
- n8n en `services`.
- Integración Matrix → Hermes → herramientas.
- WOL controlado para `ai-gpu`.

### Fase 4 — Apps principales

- Paperless.
- Navidrome.
- File sharing.
- Immich core.
- Arr stack.

### Fase 5 — GPU y multimedia

- Jellyfin en `ai-gpu`.
- Immich ML en `ai-gpu`.
- LLM pesada en `ai-gpu`.
- Reglas de apagado por inactividad.

### Fase 6 — NAS frío

- Wake/sync/sleep.
- Backups.
- Snapshots.
- Validación de restauración.
- Ventanas programadas.

---

## 17. Decisiones pendientes

- Elegir vía alterna final: Telegram, ntfy o email.
- Elegir herramienta de sync Pi-hole.
- Definir si se usará VIP con keepalived en fase posterior.
- Definir si Jellyfin tendrá instancia ligera en `services` o solo instancia GPU en `ai-gpu`.
- Definir política exacta de backups.
- Resolver NVMe no detectado en `orangepi5-a` y `orangepi5-b`.
- Medir consumo real de `services` para decidir si alguna vez conviene dormirlo.
- Definir modelos LLM para `services` y `ai-gpu`.
- Definir si `cloudflared` apuntará a Caddy local en ambos nodos o a una VIP futura.

---

## 18. Resumen ejecutivo

La arquitectura recomendada queda:

```text
services = nodo principal de vida digital e interacción
management = nodo de red/control
opi-ultra = nodo de supervivencia/domótica/failover
ai-gpu = nodo de potencia pesada
nas = bóveda fría
opi-max/a/b = redundancia ligera y workers
```

El objetivo no es que todo esté en alta disponibilidad perfecta desde el día uno, sino tener una base robusta:

```text
Si cae management:
  Matrix debe seguir funcionando vía services + opi-ultra.

Si cae services:
  Colibrí debe avisar por vía alterna.

Si cae NAS:
  Las apps deben seguir usando cache/staging local.

Si cae ai-gpu:
  Las funciones ligeras siguen en services.

Si hay corte eléctrico:
  services/NUT detecta, avisa, bloquea cargas pesadas y apaga ordenadamente.
```

---

## 19. Bibliotecas de medios por usuario y grupo

### Decisión general

Se usará separación lógica de bibliotecas por persona/grupo, evitando duplicar archivos físicos salvo que sea necesario.

Principio:

```text
No duplicar archivos físicos salvo que haya versiones diferentes.
Crear bibliotecas lógicas por usuario/grupo.
Usar permisos de Jellyfin/Navidrome para controlar visibilidad.
```

Personas principales:

```text
José René = usuario principal
René      = papá de José René
Guadalupe = mamá de José René
```

### Nombres recomendados

Para evitar ambigüedad porque José René y su papá comparten el nombre René:

```text
Usuarios:
  jose-rene
  rene
  guadalupe
  familia

Bibliotecas:
  music-jose-rene
  music-rene
  music-guadalupe
  music-jose-rene-rene
  music-familia
```

Nombres visibles más humanos:

```text
Música José René
Música René
Música Guadalupe
José René + René
Música familiar
```

---

## 20. Jellyfin: bibliotecas de video

### Decisión

Jellyfin manejará separación por bibliotecas y permisos de usuario.

No se recomienda empezar con permisos Linux complejos. Linux solo debe permitir que el contenedor de Jellyfin lea las carpetas necesarias.

### Bibliotecas sugeridas

```text
Video:
  Anime
  Documentales
  Series José René
  Series René y Guadalupe
  José René + René
  Familiar
```

### Accesos sugeridos

```text
José René:
  - Anime
  - Documentales
  - Series José René
  - José René + René
  - Familiar

René:
  - Documentales
  - Series René y Guadalupe
  - José René + René
  - Familiar

Guadalupe:
  - Documentales
  - Series René y Guadalupe
  - Familiar
```

### Estructura física sugerida

```text
/srv/media/video/
  movies/
    anime/
    documentaries/
    jose-rene/
    rene-guadalupe/
    jose-rene-rene/
    family/

  series/
    anime/
    documentaries/
    jose-rene/
    rene-guadalupe/
    jose-rene-rene/
    family/
```

### Symlinks/hardlinks

Primera etapa:

```text
Usar bibliotecas temáticas y de grupo.
Evitar symlinks/hardlinks hasta que sea necesario.
```

Etapa posterior:

```text
Usar hardlinks si varios grupos necesitan ver el mismo archivo desde vistas distintas y el filesystem lo permite.
Usar symlinks solo si Jellyfin dentro de Docker puede resolver correctamente las rutas destino.
```

Ejemplo donde sí se aceptan duplicados reales:

```text
Película A 4K HDR para José René.
Película A 1080p ligera para René y Guadalupe.
```

Ejemplo donde no se debe duplicar:

```text
Documental X visto por todos.
```

---

## 21. Navidrome: bibliotecas musicales

### Decisión

Navidrome usará Multi-Library y usuarios separados.

Se evitará que los gustos de una persona contaminen los de otra.

### Bibliotecas sugeridas

```text
music-jose-rene:
  música de José René
  OST de videojuegos
  anime
  jpop
  rock/metal/etc.

music-rene:
  música de René

music-guadalupe:
  música de Guadalupe

music-jose-rene-rene:
  música compartida por José René y René

music-familia:
  música neutral/familiar
  fiestas
  navidad
  música para reuniones
```

### Accesos sugeridos

```text
José René:
  - music-jose-rene
  - music-jose-rene-rene
  - music-familia

René:
  - music-rene
  - music-jose-rene-rene
  - music-familia

Guadalupe:
  - music-guadalupe
  - music-familia

Familia / sala:
  - music-familia
```

### Estructura física sugerida

```text
/srv/media/music/
  libraries/
    jose-rene/
      _discovery/
      videogame-ost/
      anime/
      jpop/
      rock/
      metal/

    rene/
      _discovery/
      rock-clasico/
      baladas/
      favoritas/

    guadalupe/
      _discovery/
      cumbia/
      angeles-azules/
      romanticas/
      favoritas/

    jose-rene-rene/
      _discovery/
      rock-compartido/
      soundtracks-compartidos/

    familia/
      fiestas/
      navidad/
      reuniones/
```

### Regla de scrobbling

Cada persona debe usar su propio usuario de Navidrome.

```text
Celular de José René -> usuario jose-rene
Celular de René      -> usuario rene
Celular de Guadalupe -> usuario guadalupe
Sala/bocina familiar -> usuario familia
```

No se debe usar una sola cuenta compartida para todos, porque contaminaría recomendaciones y scrobbling.

---

## 22. ListenBrainz y Explo

### Decisión

ListenBrainz y Explo deben operar por persona/perfil, no como un perfil global familiar.

Objetivo:

```text
José René escucha OST de videojuegos -> recomendaciones de José René
Guadalupe escucha Ángeles Azules     -> recomendaciones de Guadalupe
René escucha su música                -> recomendaciones de René
```

Esto evita mezclar gustos incompatibles.

### ListenBrainz

Cada usuario debería tener su propia cuenta/token:

```text
jose-rene  -> ListenBrainz José René
rene       -> ListenBrainz René
guadalupe  -> ListenBrainz Guadalupe
familia    -> ListenBrainz familiar opcional
```

### Explo

No usar una sola instancia global.

Usar instancias o perfiles separados:

```text
explo-jose-rene:
  ListenBrainz token: José René
  destino: Navidrome / playlists José René
  carpeta destino: /srv/media/music/libraries/jose-rene/_discovery

explo-rene:
  ListenBrainz token: René
  destino: Navidrome / playlists René
  carpeta destino: /srv/media/music/libraries/rene/_discovery

explo-guadalupe:
  ListenBrainz token: Guadalupe
  destino: Navidrome / playlists Guadalupe
  carpeta destino: /srv/media/music/libraries/guadalupe/_discovery

explo-familia:
  ListenBrainz token: familia, opcional
  destino: Navidrome / playlists familiares
  carpeta destino: /srv/media/music/libraries/familia/_discovery
```

### Playlists recomendadas

```text
José René - Weekly Jams
René - Weekly Jams
Guadalupe - Weekly Jams
Familia - Weekly Jams
```

### Reglas

```text
Navidrome separa acceso a bibliotecas.
ListenBrainz separa historial por persona.
Explo genera descubrimiento por persona.
```

No hacer:

```text
Una sola cuenta ListenBrainz familiar.
Un solo Explo global.
Un solo usuario Navidrome para todos.
```

---

## 23. Homepage self-hosted

### Decisión

Usar `Homepage` como dashboard principal del homelab.

Ubicación recomendada:

```text
management:
  Homepage principal

orangepi5-ultra:
  Homepage emergency / fallback
```

### Razones

- simple y ligero;
- configuración declarativa;
- buen fit para Docker Compose;
- soporta widgets e integraciones;
- útil como portal visual para familia y administración;
- más adecuado para este setup que dashboards más pesados.

### Estructura sugerida

```text
Dashboard Colibrí
├── Casa
│   ├── Home Assistant
│   ├── Pi-hole Primary
│   ├── Pi-hole Secondary
│   └── Uptime Kuma
├── Familia
│   ├── Jellyfin
│   ├── Navidrome
│   ├── Immich
│   └── Paperless
├── IA
│   ├── Matrix
│   ├── Hermes
│   ├── Ollama services
│   └── Ollama ai-gpu
├── Media Ops
│   ├── Sonarr
│   ├── Radarr
│   ├── Prowlarr
│   ├── Bazarr
│   └── download client
├── Infra
│   ├── Portainer
│   ├── NAS / OMV
│   ├── Caddy
│   ├── Cloudflared
│   └── Grafana
└── Emergencia
    ├── Bot status
    ├── Wake NAS
    ├── Wake GPU
    └── Blackout status
```

### Exposición

```text
home.white-enciso.com:
  Homepage principal

emergency.white-enciso.com:
  Homepage fallback, preferentemente solo por Tailscale o Cloudflare Access
```

---

## 24. Interacción con Hermes desde Homepage

### Decisión

Homepage no será el chat principal de Hermes.

Homepage actuará como portal:

```text
Homepage
  ├── tarjeta de estado de Hermes
  ├── link hacia UI de Hermes
  └── métricas simples
```

La interacción real con Hermes vivirá en una UI dedicada.

Opciones:

```text
hermes.white-enciso.com:
  Open WebUI conectado a Hermes

o

hermes.white-enciso.com:
  mini frontend propio
```

### Estado mostrado en Homepage

Homepage puede consultar una API propia, por ejemplo:

```text
Hermes:
  - status: online/offline
  - provider activo: services/ollama o ai-gpu
  - gpu: asleep/awake
  - queue: 0
  - modo: normal/emergencia
```

### Regla de seguridad

Hermes no debe quedar libre para invitados.

```text
Hermes:
  autenticado
  no expuesto sin control
  sin tools peligrosas para usuarios no confiables
```

---

## 25. Portal local para invitados

### Decisión

Crear una página separada de Homepage para invitados.

No se debe exponer el dashboard real del homelab a invitados.

### Hostname sugerido

```text
guest.white-enciso.com
```

o solo local:

```text
guest.colibri.lan
```

### Contenido permitido

```text
Bienvenido a Colibrí
- Wi-Fi de invitados / QR
- reglas básicas de red
- contacto de José René
- botón para pedir ayuda
- estado básico de internet
- acceso a servicios solo si hay cuenta de invitado
```

### Contenido no permitido

```text
- Pi-hole admin
- Portainer
- NAS
- Home Assistant admin
- Matrix admin
- Hermes completo
- Uptime Kuma interno
- Grafana
- APIs de WOL/shutdown
```

### Implementación recomendada

Opción inicial:

```text
Página estática servida por Caddy.
```

Ejemplo:

```text
management o orangepi5-ultra:
  /srv/www/guest/index.html
```

Caddy:

```caddyfile
guest.white-enciso.com {
    root * /srv/www/guest
    file_server
}
```

### Acciones limitadas

Si se quiere permitir que invitados reporten problemas:

```text
guest page
  ↓
endpoint limitado del colibri-sentinel-bot
  ↓
alerta a Matrix/Telegram
```

Acciones seguras:

```text
- Necesito ayuda con Wi-Fi
- No hay internet
- Jellyfin no funciona
- Solicitar cuenta temporal
```

Acciones prohibidas:

```text
- despertar NAS/GPU
- apagar nodos
- ejecutar Hermes con tools activas
- ver estado interno completo
```

---

## 26. URLs iguales dentro y fuera de casa

### Decisión

Usar las mismas URLs localmente y por internet.

Ejemplo:

```text
jellyfin.white-enciso.com
```

Debe funcionar:

```text
Dentro de casa:
  resuelve a IP local del proxy

Fuera de casa:
  resuelve por Cloudflare Tunnel
```

Esto se logra con split-horizon DNS / split DNS.

### Resolución local

Pi-hole responderá localmente:

```text
jellyfin.white-enciso.com   -> 192.168.0.10
matrix.white-enciso.com    -> 192.168.0.10
home.white-enciso.com      -> 192.168.0.10
hermes.white-enciso.com    -> 192.168.0.10
paperless.white-enciso.com -> 192.168.0.10
immich.white-enciso.com    -> 192.168.0.10
navidrome.white-enciso.com -> 192.168.0.10
guest.white-enciso.com     -> 192.168.0.10
ha.white-enciso.com        -> 192.168.0.51
```

Fase posterior con VIP:

```text
*.white-enciso.com -> 192.168.0.6
```

Donde:

```text
192.168.0.6 = proxy.colibri.lan
```

### Resolución externa

Cloudflare DNS apuntará los hostnames al túnel `colibri`.

```text
*.white-enciso.com -> Cloudflare Tunnel
```

### Flujo local

```text
jellyfin.white-enciso.com
  ↓
Pi-hole local responde 192.168.0.10
  ↓
Caddy en management
  ↓
backend correspondiente
```

### Flujo externo

```text
jellyfin.white-enciso.com
  ↓
Cloudflare DNS
  ↓
Cloudflare Tunnel
  ↓
cloudflared en management / orangepi5-ultra
  ↓
Caddy
  ↓
backend correspondiente
```

### Caddy conceptual

```caddyfile
jellyfin.white-enciso.com {
    reverse_proxy 192.168.0.40:8096
}

matrix.white-enciso.com {
    reverse_proxy 192.168.0.30:8008
}

home.white-enciso.com {
    reverse_proxy 192.168.0.10:3000
}

hermes.white-enciso.com {
    reverse_proxy 192.168.0.30:<puerto>
}

navidrome.white-enciso.com {
    reverse_proxy 192.168.0.30:<puerto>
}

ha.white-enciso.com {
    reverse_proxy 192.168.0.51:8123
}
```

### Seguridad

No todo lo que tiene URL debe estar abierto públicamente.

Regla:

```text
Misma URL no significa mismo nivel de acceso.
```

Servicios recomendados para Cloudflare público o Cloudflare Access:

```text
matrix.white-enciso.com
jellyfin.white-enciso.com
navidrome.white-enciso.com
immich.white-enciso.com, con cuidado
paperless.white-enciso.com, preferentemente con Access o solo Tailscale
home.white-enciso.com, preferentemente con Access
```

Servicios solo por Tailscale:

```text
portainer.white-enciso.com
nas.white-enciso.com
grafana.white-enciso.com
uptime.white-enciso.com
admin.white-enciso.com
```

---

## 27. Ajuste del resumen ejecutivo

La arquitectura queda refinada así:

```text
services:
  vida digital, Matrix, Hermes, LLM diaria, n8n, apps, Arr stack, Navidrome, Immich core, Paperless

management:
  control plane, DNS primario, Caddy principal, cloudflared principal, WOL, Ansible, dashboard principal

orangepi5-ultra:
  supervivencia, Home Assistant, MQTT, DNS secundario, Caddy/cloudflared backup, sentinel bot, dashboard emergency

ai-gpu:
  Jellyfin GPU, LLM pesada, Immich ML, OCR/audio/visión/batch

nas:
  bóveda fría, NFS, backups, snapshots, bibliotecas maestras y archivo final

orangepi5-max/a/b:
  redundancia ligera, watchdogs, workers, DNS extra opcional
```

Decisiones nuevas clave:

```text
Jellyfin:
  separar bibliotecas por grupo y asignar permisos por usuario.

Navidrome:
  usar Multi-Library por persona/grupo.

ListenBrainz:
  usar cuenta/token separado por persona.

Explo:
  usar instancia/perfil separado por persona.

Homepage:
  usar como dashboard principal, no como chat de Hermes.

Hermes:
  interacción desde UI dedicada, enlazada desde Homepage.

Invitados:
  portal separado, estático y limitado.

URLs:
  mismas URLs dentro y fuera usando split DNS.
```


---

Última actualización: 2026-05-25 08:36:21.
