# Microplan 06 — Reverse Proxy y `cloudflared`

## Propósito

Definir exposición externa e interna de servicios con `Caddy` y `cloudflared`.

## Estado actual

- dominio y túnel existentes en Cloudflare
- no hay despliegue final aprobado de `Caddy`/`cloudflared`

## Objetivo final

- `management` como proxy principal y conector principal del túnel
- `orangepi5-ultra` como backup proxy/conector
- servicios administrativos sensibles solo por red privada
- mismas URLs globales para la experiencia normal de usuario

## Decisiones cerradas

- proxy interno principal: `Caddy`
- túnel externo: `cloudflared`
- ambos nodos pueden participar en el mismo túnel para redundancia
- `SSO` no reemplaza al proxy; se integra detrás de `Caddy` o a través del proxy cuando aplique
- internamente, cada sitio resuelve las mismas URLs globales hacia su proxy local
- externamente, `Cloudflare` es la entrada y decide hacia sitio sano o preferido
- no se expone:
  - Portainer
  - admin NAS
  - Grafana/Prometheus
  - SSH
  - APIs internas de WOL/shutdown

## Interfaces

### Exposición candidata

- `home.white-enciso.com` -> dashboard local por sitio
- `auth.white-enciso.com` -> `authentik` en `Colibrí` al inicio
- `hermes.white-enciso.com` -> `services`
- `paperless.white-enciso.com` -> `services`
- `immich.white-enciso.com` -> `services`
- `jellyfin.white-enciso.com` -> `ai-gpu`
- `navidrome.white-enciso.com` -> `services`
- `ha.white-enciso.com` -> `orangepi5-ultra`
- `matrix` queda fuera de la regla general si se despliega por sede como homeserver federado distinto

## Flujos

### Normal

- Internet -> Cloudflare -> `cloudflared` -> `Caddy` -> backend interno
- LAN local -> DNS local -> `Caddy` local -> backend local

### Falla

- si cae `management`, `ultra` asume conector/proxy backup para servicios compatibles;
- si cae `services`, los hostnames de apps que viven ahí deben marcarse unhealthy.
- si cae `Colibrí` completo, la capa externa puede preferir `Perú` para los servicios que tengan réplica aprobada.

## Aceptación

- tabla de hostnames a backend aprobada;
- lista explícita de servicios solo por Tailscale aprobada;
- takeover limitado entre `management` y `ultra` documentado.

## Dependencias previas

- DNS
- direccionamiento
- estrategia de `SSO` aprobada

## Fuera de fase

- VIP futura
- balanceo L7 complejo
