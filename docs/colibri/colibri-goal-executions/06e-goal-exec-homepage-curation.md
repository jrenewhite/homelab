# Microplan 06E — Curacion inicial de `Homepage`

## Resumen

`06E` organiza una vista inicial util de `Homepage` para el homelab `Colibri`, sin usar secretos ni integraciones sensibles.

## Secciones creadas

- `Core / Operations`
- `Network / DNS`
- `Alerts / Energy`
- `Apps staged`
- `Media staged`
- `Admin / Future`

## Servicios activos vs staged

### Activos

- `home.white-enciso.com`
- `ntfy.white-enciso.com`
- `Pi-hole Primary`
- `Pi-hole Secondary`

### Staged

- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `jellyfin.white-enciso.com`
- `navidrome.white-enciso.com`

## Archivos de config modificados

- `infra/colibri/homepage/config/settings.yaml`
- `infra/colibri/homepage/config/services.yaml`
- `infra/colibri/homepage/config/bookmarks.yaml`
- `infra/colibri/homepage/config/widgets.yaml`

## Aplicacion a runtime

Runtime sincronizado a:

- `/opt/stacks/homepage/config/`

Se recreo el stack de `Homepage` para asegurar que la configuracion montada quedara activa.

## Validacion

### Backend

```bash
curl http://127.0.0.1:8080/
```

Resultado:

- `HTTP 200`

### Hostname

```bash
curl http://home.white-enciso.com/
```

Resultado:

- `HTTP 200`

### `ntfy`

```bash
curl http://ntfy.white-enciso.com/
```

Resultado:

- `HTTP 200`

### Placeholders restantes

Validados:

- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Resultado:

- todos siguen `HTTP 200`

## Caveat

- la configuracion versionada si quedo montada en runtime
- `curl` confirma reachability y parte del contenido, pero la revision visual en navegador sigue siendo recomendable para validar la presentacion final del dashboard y el orden visual de grupos

## Estado final

- `Homepage` sigue sano por backend y por hostname
- `ntfy` sigue sano
- los placeholders staged no sufrieron regresion

## Recomendacion

- conectar el siguiente backend real local: `go`
