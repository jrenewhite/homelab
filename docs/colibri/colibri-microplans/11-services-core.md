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
6. healthchecks y observabilidad mínima

## Decisiones cerradas

- `Pi-hole` primario en `management`
- `Pi-hole` secundario en `ultra`
- `Caddy` principal en `management`
- `Caddy` backup en `ultra`
- `cloudflared` principal en `management`
- `cloudflared` backup en `ultra`

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

## Aceptación

- cada servicio tiene nodo, storage y dependencia cerrados;
- ningún servicio core depende de `nas`.

## Dependencias previas

- red
- DNS
- blackout

## Fuera de fase

- apps personales
- media
