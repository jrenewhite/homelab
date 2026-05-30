# Microplan 06F — Local Hostname Exposure Policy

Fecha de ejecucion:

- `2026-05-29`

## Objetivo

Definir politica local de exposicion por hostname antes de conectar mas backends reales o preparar exposicion publica futura.

## Alcance ejecutado

- revision documental de `Caddy`, `port registry` y matriz local-first
- clasificacion de hostnames actuales y futuros sin tocar runtime
- definicion de guardrails para fases posteriores

## Tabla de hostnames

| Hostname | Clasificacion | Estado actual | Exposure actual | Nota |
|---|---|---|---|---|
| `home.white-enciso.com` | `local-family` | backend real local | LAN local por `Caddy` | candidato natural a experiencia local familiar |
| `ntfy.white-enciso.com` | `local-ops` | backend real local | LAN/Tailscale | operaciones y alerting; no publico por ahora |
| `pihole.white-enciso.com` | `admin-local-only` | planned | admin local | no publico |
| `portainer.white-enciso.com` | `tailscale-only` | planned | privado | no publico |
| `auth.white-enciso.com` | `staged-placeholder` | placeholder local | placeholder | bloqueado hasta microplan de `SSO` |
| `paperless.white-enciso.com` | `staged-placeholder` | placeholder local | placeholder | pendiente backend + politica de acceso |
| `immich.white-enciso.com` | `staged-placeholder` | placeholder local | placeholder | pendiente backend + politica de acceso |
| `jellyfin.white-enciso.com` | `future-public` | placeholder local | placeholder | candidato futuro a exposure mas amplia controlada |
| `navidrome.white-enciso.com` | `staged-placeholder` | placeholder local | placeholder | pendiente backend + politica de acceso |

## Guardrails cerrados

- `home.white-enciso.com` puede operar como `local-family`
- `ntfy.white-enciso.com` queda `local-ops`
- `pihole.white-enciso.com` queda `admin-local-only`
- `portainer.white-enciso.com` queda `tailscale-only`
- `auth.white-enciso.com` no avanza hasta microplan de identidad/`SSO`
- `paperless`, `immich`, `jellyfin` y `navidrome` no cambian de exposure solo por existir en DNS local
- `never-public` aplica desde ahora a:
  - `pihole.white-enciso.com`
  - cualquier futura URL de `Portainer`

## Hostnames que pueden conectarse localmente pronto

- `home.white-enciso.com`
- `ntfy.white-enciso.com`

## Hostnames bloqueados por `SSO/auth`

- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

## Hostnames `never-public`

- `pihole.white-enciso.com`
- `portainer.white-enciso.com`

## Resultado

- no se cambian servicios ni `DNS`
- la politica de exposure queda cerrada para guiar `06G` y microplanes posteriores

## Veredicto

- `06F`: `pass`
- `06G`: `go`
