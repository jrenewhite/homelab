# White-Enciso — Plataforma Multi-Site

Documento marco para la plataforma multi-site de `white-enciso.com`.

La política de sincronización inter-sede vive en:

- [white-enciso-sync-policy.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-sync-policy.md)

En la fase actual:

- `Colibrí` = sitio principal
- `Perú` = segundo sitio planeado

Los documentos por sitio deben alinearse a este marco y no contradecirlo.

## 1. Regla general

La experiencia normal de usuario usa las mismas URLs globales:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `jellyfin.white-enciso.com`
- `navidrome.white-enciso.com`

La resolución concreta depende del lugar donde esté el cliente.

## 2. Split-horizon DNS

Cada sitio tendrá `split-horizon DNS local`.

```text
Dentro de Colibrí:
  jellyfin.white-enciso.com -> proxy local de Colibrí

Dentro de Perú:
  jellyfin.white-enciso.com -> proxy local de Perú

Desde Internet:
  jellyfin.white-enciso.com -> Cloudflare / cloudflared / balanceo hacia sitio sano o preferido
```

## 3. Backbone privado

- `Tailscale` conserva el rol de acceso administrativo humano
- `WireGuard site-to-site` será el backbone para:
  - sincronización
  - healthchecks inter-sede
  - backups
  - replicación controlada
  - tráfico privado entre sedes

## 4. Modelo operativo

```text
Activo-local por sitio + ventanas de sincronización
```

Eso implica:

- cada sitio sirve su instancia local cuando el cliente está dentro de esa sede
- no se busca `active-active` fuerte para servicios con estado delicado
- la sincronización ocurre en horarios de bajo tráfico sostenido
- la UX usa la misma URL aunque la operación sea local por sede

## 5. Reglas duras

- no se hará `active-active` fuerte para bases de datos delicadas
- cada sitio debe poder operar localmente en servicios aprobados sin dependencia runtime del otro
- la replicación entre sedes será por ventanas
- `SSO` es útil, pero no será el único camino de recuperación
- los servicios críticos conservarán cuentas break-glass locales

## 6. Excepción: Matrix

`Matrix` no seguirá la regla de “misma URL global para ambos sitios” si existe en ambas sedes.

Si se despliega en ambas, serán homeservers federados distintos:

```text
@jrenewhite:colibri.white-enciso.com
@jrenewhite:peru.white-enciso.com
```

Esto evita `split-brain`.

## 7. Servicios core por sede

| Servicio | Nodo Colibrí | Nodo Perú | Nota |
|---|---|---|---|
| Pi-hole primario | `management` | nodo equivalente local | DNS primario por sitio |
| Pi-hole secundario | `orangepi5-ultra` | nodo equivalente local | DNS resiliente |
| Pi-hole terciario opcional | `orangepi5-max` | nodo equivalente local | fallback local adicional |
| Caddy principal | `management` | nodo proxy local | reverse proxy local |
| Caddy backup | `orangepi5-ultra` | nodo backup local | failover local |
| cloudflared principal | `management` | nodo proxy local | conector Cloudflare |
| cloudflared backup | `orangepi5-ultra` | nodo backup local | redundancia |
| Tailscale | todos los nodos clave | todos los nodos clave | acceso admin |
| WireGuard site-to-site | `management` o gateway dedicado | gateway local | backbone privado |
| `colibri-sentinel-bot` | `management` + `orangepi5-ultra` | equivalente local | alertas y takeover limitado |
| Uptime Kuma | `management` | opcional local | healthchecks |
| `ntfy` | `orangepi5-ultra` o `management` | local | canal alterno |
| Diun | `management` | opcional local | aviso de updates |
| Restic/Kopia | `services` | nodo apps local | backups |
| Homepage | `management` | nodo local | dashboard local |
| Emergency Homepage | `orangepi5-ultra` | nodo resiliente local | vista mínima |

## 8. Identidad y seguridad

| Servicio | Nodo Colibrí | Nodo Perú | Nota |
|---|---|---|---|
| `authentik` | `services` | futuro nodo local si aplica | IdP principal inicialmente en Colibrí |
| Vaultwarden | `services` | opcional local/fallback | cuenta local al inicio |
| Portainer | `services` o `management` | local | solo privado/Tailscale |
| Dockge | `management` o `services` | local | gestión Compose |
| CrowdSec | `management` | local | cuando haya más exposición |

## 9. Servicios de usuario

| Servicio | Nodo Colibrí | Nodo Perú | Nota |
|---|---|---|---|
| Paperless-ngx | `services` | instancia local si se replica | local-first, sync por ventana |
| SFTPGo | `services` | instancia local | archivos compartidos |
| Immich core | `services` | instancia local si aplica | fotos local-first |
| Immich ML | `ai-gpu` | nodo GPU/local si existe | procesamiento pesado |
| Mealie | `services` | local si se desea | recetas |
| Homebox | `services` | local | inventario |
| BookStack | `services` | local o Colibrí principal | wiki |
| Memos | `services` | opcional local | notas |
| Actual Budget | `services` | probablemente solo primario | finanzas |
| Wallos | `services` | opcional | suscripciones |
| Stirling PDF | `services` | local | herramientas PDF |
| IT-Tools | `management` o `services` | local | utilidades técnicas |

## 10. Media

| Servicio | Nodo Colibrí | Nodo Perú | Nota |
|---|---|---|---|
| Jellyfin | `ai-gpu` | nodo media local si existe | principal con GPU |
| Navidrome | `services` | local si hay música local | multi-library |
| ListenBrainz | externo / por usuario | externo / por usuario | por persona |
| Explo | `services` | local si hay Navidrome local | perfil por persona |
| Arr stack | `services` | local si aplica | staging local |
| Jellyseerr | `services` | local/opcional | solicitudes |
| Audiobookshelf | `services` | local/opcional | audiolibros/podcasts |
| Kavita | `services` | local/opcional | manga/cómics/libros |
| Tube Archivist | `services` | opcional | vigilar storage |

## 11. IA y agentes

| Servicio | Nodo Colibrí | Nodo Perú | Nota |
|---|---|---|---|
| Hermes Agent | `services` | local si Perú tendrá agente | agente principal |
| Open WebUI | `services` | local/opcional | UI para LLMs/Hermes |
| Ollama liviano | `services` | nodo local | LLM casi 24/7 |
| Ollama/vLLM pesado | `ai-gpu` | GPU local si existe | bajo demanda |
| Qdrant | `services` | local si hay RAG local | vector DB |
| SearXNG | `services` | local/opcional | búsqueda para agentes |
| Whisper | `ai-gpu` | GPU local si existe | transcripción |
| OCR pesado | `ai-gpu` | GPU local si existe | jobs batch |
| changedetection.io | `services` | opcional | monitoreo web |

## 12. Storage y archivo

| Servicio / función | Nodo Colibrí | Nodo Perú | Nota |
|---|---|---|---|
| NAS / NFS | `nas` | storage local si existe | archivo frío |
| Backups finales | `nas` | storage local o remoto | sync por ventana |
| Media final | `nas:/srv/media` | storage local | no runtime crítico |
| Docs finales | `nas:/srv/docs` | storage local | Paperless/archive |
| Sync jobs | `services` | nodo local | ventanas sin tráfico sostenido |

## 13. Matrix

| Servicio | Nodo Colibrí | Nodo Perú | Nota |
|---|---|---|---|
| Matrix Synapse Colibrí | `services` | — | `@jrenewhite:colibri.white-enciso.com` |
| Matrix Synapse Perú | — | nodo local | `@jrenewhite:peru.white-enciso.com` |
| Matrix bots Colibrí | `services` o `management` | — | bot local |
| Matrix bots Perú | — | nodo local | bot local |
| Salas federadas | ambos | ambos | operación multi-site |

## 14. Candidatos no aprobados aún

| Servicio | Lectura actual |
|---|---|
| Wazuh | probablemente sobredimensionado para la fase actual |
| New Relic | SaaS externo, complemento posible, no base del homelab |
| Gitea | candidato razonable para `services` como forja privada local-first |

## 15. Regla resumida

```text
Misma URL para experiencia de usuario.
Resolución local por sitio.
Sincronización por ventanas.
SSO útil, pero no único camino de recuperación.
Cuentas break-glass locales para servicios críticos.
```
