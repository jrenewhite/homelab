# Microplan 06G — Cloudflared Exposure Policy

Fecha de ejecucion:

- `2026-05-29`

## Objetivo

Definir politica futura de exposure con `cloudflared` sin activar tuneles ni exposure publica.

## Alcance ejecutado

- revision de `06F`
- clasificacion de hostnames para la capa futura `cloudflared`
- definicion de guardrails `default deny`

## Tabla de exposure futura

| Hostname | Clasificacion cloudflared | Estado actual | Nota |
|---|---|---|---|
| `home.white-enciso.com` | `public-candidate` | backend real local | solo si luego se decide exposure publica |
| `ntfy.white-enciso.com` | `private-only` | backend real local | ops local; no publico por ahora |
| `pihole.white-enciso.com` | `never-public` | planned | admin local/private solamente |
| `portainer.white-enciso.com` | `tailscale-only` | planned | privado por `Tailscale`; no publico |
| `auth.white-enciso.com` | `blocked-until-auth` | placeholder local | no antes de `authentik`/`SSO` |
| `paperless.white-enciso.com` | `blocked-until-auth` | placeholder local | requiere auth y politica de backup |
| `immich.white-enciso.com` | `blocked-until-auth` | placeholder local | requiere auth y politica de backup |
| `jellyfin.white-enciso.com` | `public-candidate` | placeholder local | requiere politica de media/energia antes de exposure |
| `navidrome.white-enciso.com` | `blocked-until-auth` | placeholder local | requiere politica de media/auth |

## Guardrails cerrados

- `default deny`
- solo `allowlist` explicita
- herramientas admin: `never-public`
- servicios personales requieren `auth/SSO` antes de exposure mayor
- servicios de media requieren politica separada
- `cloudflared` no se activa en esta fase

## Hostnames never-public

- `pihole.white-enciso.com`
- cualquier futura URL de `Portainer`

## Hostnames blocked-until-auth

- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

## Hostnames future-public

- `home.white-enciso.com`
- `jellyfin.white-enciso.com`

## Cadena futura aprobada

- Internet -> `cloudflared` -> `Caddy` local -> backend

## Resultado

- no se activan tuneles
- no se toca runtime
- la politica queda lista para guiar `06H`

## Veredicto

- `06G`: `pass`
- `06H`: `go`
