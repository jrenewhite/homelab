# Microplan 11 — Servicios Core

## Propósito

Definir qué servicios base sostienen la operación diaria antes de apps personales y media.

## Estado actual

- `management`, `services` y las 4 Orange Pi ya tienen `Docker`
- `management` tiene `Ansible` y `NUT`

## Objetivo final

Servicios core por prioridad:

1. `Pi-hole`
2. `Caddy`
3. `cloudflared`
4. `Tailscale`
5. `colibri-sentinel-bot`
6. `WireGuard` site-to-site
7. `Uptime Kuma`
8. `ntfy`
9. `Diun`
10. `Homepage`
11. healthchecks y observabilidad mínima

## Decisiones cerradas

- `Pi-hole` primario en `management`
- `Pi-hole` secundario en `ultra`
- `Pi-hole` terciario opcional en `orangepi5-max`
- `Caddy` principal en `management`
- `Caddy` backup en `ultra`
- `cloudflared` principal en `management`
- `cloudflared` backup en `ultra`
- `WireGuard` site-to-site vive en `management` o gateway dedicado
- `Uptime Kuma` vive en `management`
- `ntfy` vive en `management` o `ultra`
- `Diun` vive en `management`
- `Homepage` vive en `management`
- `Emergency Homepage` vive en `ultra`
- los servicios core se despliegan primero en modo privado o staged
- no se introduce un servicio core nuevo el mismo día que un cambio mayor de IP, DNS o blackout

## Matriz por servicio

| Servicio | Nodo | Storage | Internet | `nas` |
|---|---|---|---|---|
| Pi-hole primario | `management` | local | opcional para upstream | no |
| Pi-hole secundario | `ultra` | local | opcional para upstream | no |
| Caddy principal | `management` | local | sí | no |
| cloudflared principal | `management` | local | sí | no |
| Caddy backup | `ultra` | local | sí | no |
| cloudflared backup | `ultra` | local | sí | no |
| sentinel | `management`/`ultra` | local | parcial | no |
| WireGuard | `management` | local | no | no |
| Uptime Kuma | `management` | local | opcional | no |
| `ntfy` | `management` o `ultra` | local | sí/opcional | no |
| Diun | `management` | local | sí | no |
| Homepage | `management` | local | opcional | no |

## Aceptación

- cada servicio tiene nodo, storage y dependencia cerrados;
- ningún servicio core depende de `nas`.
- existe orden de despliegue seguro y validación privada antes de hacerlo visible a clientes o Internet

## Prechecks mínimos

- servicio accesible por IP privada o puerto staged
- storage local validado
- dependencia de DNS o proxy claramente identificada
- no mezclar con cambios de IP, DNS del router o blackout

## Rollback

- detener o retirar el contenedor nuevo
- volver el acceso a privado o staged
- si un servicio core falla en validación, no se promueve el siguiente en la misma ventana

## Dependencias previas

- red
- DNS
- blackout

## Fuera de fase

- apps personales
- media
