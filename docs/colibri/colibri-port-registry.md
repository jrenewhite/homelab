# Colibri Port Registry

## Politica por rangos

| Rango | Familia |
|---|---|
| `80/443` | `Caddy/reverse proxy` |
| `8080` | `Homepage` principal |
| `8081` | `Emergency Homepage` |
| `8100-8199` | `core infra UIs` |
| `8200-8299` | `DNS/Pi-hole/red` |
| `8300-8399` | `observability/alerting` |
| `8400-8499` | `identity/security` |
| `8500-8599` | `user apps` |
| `8600-8699` | `media apps` |
| `8700-8799` | `AI/agents` |
| `8800-8899` | `admin tools/Docker` |

## Docker Governance

- `Git + Docker Compose` es la fuente de verdad para stacks.
- la configuracion de `Caddy` tambien queda versionada en `git`, con fuente de verdad en `infra/colibri/caddy`
- `Portainer` y `Dockge` son herramientas de operacion y visibilidad, no el mecanismo primario para definir configuracion.
- los secretos permanecen fuera de `git`
- los nodos deben seguir siendo operables en modo `headless`
- `Portainer Server` vivira en `management`
- `Portainer Agent` inicial solo se considera en nodos con Docker gestionado:
  - `services`
  - `orangepi5-ultra`
  - `orangepi5-max`
  - `ai-gpu` cuando tenga workloads GPU reales
- `nas` queda opcional y solo si corre contenedores
- `orangepi5-a` y `orangepi5-b` quedan deferidos hasta definir si seran workers
- no se instala `Portainer` dentro de `05A.0`

## Registro

| Servicio | Nodo | Puerto actual | Puerto objetivo | Exposicion | Estado |
|---|---|---|---|---|---|
| `Pi-hole` primario DNS | `management` | `192.168.0.10:53 tcp/udp` | `192.168.0.10:53 tcp/udp` | LAN | `active` |
| `Pi-hole` primario UI | `management` | `192.168.0.10:8200` | `192.168.0.10:8200` | LAN/Tailscale | `active` |
| `Pi-hole` secundario DNS | `orangepi5-ultra` | none visible en `05A` | `192.168.0.14:53 tcp/udp` | LAN | `future` |
| `Pi-hole` secundario DNS | `orangepi5-ultra` | `192.168.0.14:53 tcp/udp` | `192.168.0.14:53 tcp/udp` | LAN | `active` |
| `Pi-hole` secundario UI | `orangepi5-ultra` | `192.168.0.14:8201` | `192.168.0.14:8201` | LAN/Tailscale | `active` |
| `Pi-hole` terciario DNS | `orangepi5-max` | none visible en `05A` | `192.168.0.15:53 tcp/udp` | LAN | `future` |
| `Pi-hole` terciario UI | `orangepi5-max` | none visible en `05A` | `192.168.0.15:8202` | LAN/Tailscale | `future` |
| `Caddy` principal | `management` | `80/tcp` local-only placeholder activo; `443` libre/no usado | `80/443` | LAN ahora; publica en fase futura | `active` |
| `Caddy` backup | `orangepi5-ultra` | reservado | `80/443` | LAN/publica segun fase | `reserved` |
| `Homepage` | `management` | `127.0.0.1:8080` backend local; expuesto por `Caddy` en `home.white-enciso.com` | `8080` | LAN/Tailscale | `active` |
| `Emergency Homepage` | `orangepi5-ultra` | reservado | `8081` | LAN/Tailscale | `reserved` |
| `ntfy-local` | `orangepi5-ultra` | `192.168.0.14:8300` | `192.168.0.14:8300` | LAN/Tailscale | `active` |
| `Uptime Kuma` | `management` | none | `8300-8399` | LAN/Tailscale | `future` |
| `Diun` | `management` | none | `8300-8399` | LAN/Tailscale | `future` |
| `authentik` | `services` | none | `8400-8499` | LAN/Tailscale o reverse proxy | `future` |
| `Vaultwarden` | `services` | none | `8400-8499` | LAN/Tailscale o reverse proxy | `future` |
| `Paperless-ngx` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `SFTPGo` | `services` | none | puerto especifico por servicio | LAN/Tailscale | `future` |
| `Immich core` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `Mealie` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `Homebox` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `BookStack` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `Memos` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `Actual Budget` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `Wallos` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `Stirling PDF` | `services` | none | `8500-8599` | reverse proxy | `future` |
| `IT-Tools` | `management` o `services` | none | `8500-8599` | LAN/Tailscale o reverse proxy | `future` |
| `Jellyfin` | `ai-gpu` | none | `8600-8699` | reverse proxy/LAN | `future` |
| `Navidrome` | `services` | none | `8600-8699` | reverse proxy/LAN | `future` |
| `Arr stack` | `services` | none | `8600-8699` | LAN/Tailscale | `future` |
| `Jellyseerr` | `services` | none | `8600-8699` | reverse proxy/LAN | `future` |
| `Audiobookshelf` | `services` | none | `8600-8699` | reverse proxy/LAN | `future` |
| `Kavita` | `services` | none | `8600-8699` | reverse proxy/LAN | `future` |
| `Tube Archivist` | `services` | none | `8600-8699` | LAN/Tailscale | `future` |
| `Hermes Agent` | `services` | none | `8700-8799` | LAN/Tailscale | `future` |
| `Open WebUI` | `services` | none | `8700-8799` | LAN/Tailscale or reverse proxy | `future` |
| `Ollama` liviano | `services` | none | `8700-8799` | LAN/Tailscale | `future` |
| `Ollama/vLLM` pesado | `ai-gpu` | none | `8700-8799` | LAN/Tailscale | `future` |
| `Qdrant` | `services` | none | `8700-8799` | LAN/Tailscale | `future` |
| `SearXNG` | `services` | none | `8700-8799` | reverse proxy/LAN | `future` |
| `changedetection.io` | `services` | none | `8700-8799` | LAN/Tailscale | `future` |
| `Portainer Server` | `management` | none | `8800` preferido, `8843` alterno | LAN/Tailscale privado; no publico | `reserved` |
| `Portainer Agent` `services` | `services` | none | por definir; solo red privada | LAN/Tailscale privado; no publico | `future` |
| `Portainer Agent` `orangepi5-ultra` | `orangepi5-ultra` | none | por definir; solo red privada | LAN/Tailscale privado; no publico | `future` |
| `Portainer Agent` `orangepi5-max` | `orangepi5-max` | none | por definir; solo red privada | LAN/Tailscale privado; no publico | `future` |
| `Portainer Agent` `ai-gpu` | `ai-gpu` | none | por definir; solo red privada | LAN/Tailscale privado; no publico | `future` |
| `Portainer Agent` `nas` | `nas` | none | por definir; solo red privada | LAN/Tailscale privado; no publico | `optional` |
| `Portainer Agent` `orangepi5-a` | `orangepi5-a` | none | n/a | no aplica por ahora | `defer` |
| `Portainer Agent` `orangepi5-b` | `orangepi5-b` | none | n/a | no aplica por ahora | `defer` |
| `Dockge` | `management` preferido, o `services` | none | `8800-8899` | LAN/Tailscale privado; no publico | `future` |

## Hostname Exposure Policy

| Hostname | Clase | Backend actual o futuro | Exposure actual | Exposure futura maxima | Estado |
|---|---|---|---|---|---|
| `home.white-enciso.com` | `local-family` | `management:127.0.0.1:8080` | LAN local por `Caddy` | por decidir en fase publica | `active` |
| `ntfy.white-enciso.com` | `local-ops` | `orangepi5-ultra:8300` via `Caddy` | LAN/Tailscale | privado; no publico por ahora | `active` |
| `pihole.white-enciso.com` | `admin-local-only` | admin DNS futuro | no expuesto por hostname aun | `admin-local-only` o `tailscale-only` | `planned` |
| `portainer.white-enciso.com` | `tailscale-only` | `Portainer Server` futuro en `management` | no expuesto por hostname aun | `tailscale-only` | `planned` |
| `auth.white-enciso.com` | `staged-placeholder` | `services` futuro | placeholder local | por decidir despues de `SSO` | `staged` |
| `paperless.white-enciso.com` | `staged-placeholder` | `services` futuro | placeholder local | por decidir despues de backend + auth | `staged` |
| `immich.white-enciso.com` | `staged-placeholder` | `services` futuro | placeholder local | por decidir despues de backend + auth | `staged` |
| `jellyfin.white-enciso.com` | `future-public` | `ai-gpu` futuro | placeholder local | candidato futuro a exposicion publica controlada | `staged` |
| `navidrome.white-enciso.com` | `staged-placeholder` | `services` futuro | placeholder local | por decidir despues de backend + auth | `staged` |

Reglas:

- `pihole.white-enciso.com` nunca se considera publico
- `Portainer` nunca se considera publico
- `home.white-enciso.com` puede priorizar experiencia local familiar
- `ntfy.white-enciso.com` queda orientado a operaciones
- `auth` bloquea su exposure final hasta el microplan de identidad

## Cloudflared Exposure Policy

| Hostname | Clase cloudflared | Permitido hoy | Condicion para allowlist futura |
|---|---|---|---|
| `home.white-enciso.com` | `public-candidate` | no | decision explicita de exposure publica |
| `ntfy.white-enciso.com` | `private-only` | no | solo si cambia politica de ops |
| `pihole.white-enciso.com` | `never-public` | no | ninguna |
| `portainer.white-enciso.com` | `tailscale-only` | no | ninguna exposure publica; solo privado |
| `auth.white-enciso.com` | `blocked-until-auth` | no | backend real + microplan `SSO` |
| `paperless.white-enciso.com` | `blocked-until-auth` | no | backend real + auth + backup policy |
| `immich.white-enciso.com` | `blocked-until-auth` | no | backend real + auth + backup policy |
| `jellyfin.white-enciso.com` | `public-candidate` | no | backend real + politica de media/energia |
| `navidrome.white-enciso.com` | `blocked-until-auth` | no | backend real + auth/media policy |

Guardrails:

- `default deny`
- solo `allowlist` explicita
- admin tools: `never-public`
- `cloudflared` sigue fuera de runtime en esta fase

## Cloudflared Runtime Policy

| Nodo | Rol futuro | Estado actual | Runtime futuro | Secretos |
|---|---|---|---|---|
| `management` | principal | `active via Docker Compose` | `/opt/stacks/cloudflared` | `/opt/colibri-secrets/cloudflared/` |
| `orangepi5-ultra` | backup | `not installed` | `/etc/cloudflared/config.yml` | `/opt/colibri-secrets/cloudflared/` |

Notas factuales:

- `management` corre el canary `cloudflared` como stack `colibri-cloudflared`
- `home.white-enciso.com` es la unica allowlist publica activa en esta fase
- `orangepi5-ultra` sigue sin despliegue `cloudflared`
