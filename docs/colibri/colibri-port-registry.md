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
| `Caddy` principal | `management` | reservado | `80/443` | LAN/publica segun fase | `reserved` |
| `Caddy` backup | `orangepi5-ultra` | reservado | `80/443` | LAN/publica segun fase | `reserved` |
| `Homepage` | `management` | reservado | `8080` | LAN/Tailscale | `reserved` |
| `Emergency Homepage` | `orangepi5-ultra` | reservado | `8081` | LAN/Tailscale | `reserved` |
| `ntfy-local` | `orangepi5-ultra` | `8080` | migrar a `8300-8399` en fase futura | LAN/Tailscale | `active debt` |
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
