# Colibri Homepage

Fuente de verdad versionada para `Homepage` en `management`.

## Runtime esperado

- stack runtime: `/opt/stacks/homepage`
- backend local: `127.0.0.1:8080`
- exposicion por proxy: `home.white-enciso.com`

## Estado actual

- contenedor `homepage` en `management`
- backend activo en `127.0.0.1:8080`
- proxyeado por `Caddy` en `home.white-enciso.com`

## Flujo

1. editar en este repo
2. sincronizar a `management`
3. `docker compose up -d`
4. validar backend con `curl http://127.0.0.1:8080`
5. validar `Caddy`
6. `caddy validate`
7. `systemctl restart caddy`
8. validar `curl http://home.white-enciso.com`
