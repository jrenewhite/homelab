# Microplan 06H — Cloudflared Preflight y Plantilla

Fecha de ejecucion:

- `2026-05-29`

## Objetivo

Preparar `cloudflared` de forma versionable y segura sin activar tunel publico.

## Preflight factual

### `management`

- `cloudflared`: `not installed`
- servicio `cloudflared`: `not-found`
- estado: `inactive`
- `/etc/cloudflared`: no presente

### `orangepi5-ultra`

- `cloudflared`: `not installed`
- servicio `cloudflared`: `not-found`
- estado: `inactive`
- `/etc/cloudflared`: no presente

## Hallazgos

- no se encontro configuracion previa aprobada
- no se encontro tunel runtime en estos nodos
- la fase correcta es documental/versionada, no operativa

## Estructura creada

- `infra/colibri/cloudflared/README.md`
- `infra/colibri/cloudflared/config.example.yml`

## Runtime futuro definido

- config:
  - `/etc/cloudflared/config.yml`
- secretos:
  - `/opt/colibri-secrets/cloudflared/`

Secretos fuera de `git`:

- `cert.pem`
- credenciales JSON del tunel
- tokens

## Allowlist documental inicial

Public-candidate futuro:

- `home.white-enciso.com`
- `jellyfin.white-enciso.com`

Privado o bloqueado:

- `ntfy.white-enciso.com`
- `pihole.white-enciso.com`
- `portainer.white-enciso.com`
- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

## Hostnames never-public confirmados

- `pihole.white-enciso.com`
- cualquier futura URL de `Portainer`

## Resultado

- no se activa tunel
- no se instala servicio
- no se cambian `DNS` publicos
- queda lista una plantilla segura para una fase posterior

## Veredicto

- `06H`: `pass`
- `06I`: `go`
