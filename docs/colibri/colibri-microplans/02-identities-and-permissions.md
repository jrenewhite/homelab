# Microplan 02 — Identidades y Permisos

## Propósito

Definir el modelo único de identidad, permisos y acceso compartido entre nodos, apps y humanos.

## Estado actual

- identidades compartidas ya propagadas operativamente:
  - `apps` `UID/GID 3000`
  - `media_rw` `3100`
  - `media_ro` `3101`
  - `docs_rw` `3200`
  - `docs_ro` `3201`
- `jrenewhite` ya pertenece a `media_rw` y `docs_rw`
- `nas` ya aplica `ACLs` y `setgid` sobre `media/docs`

## Objetivo final

- todos los nodos relevantes comparten el mismo mapa `UID/GID`;
- apps escriben como `apps` o como una identidad explícitamente compatible;
- humanos acceden por grupos, no por ownership directo;
- alta de usuarios nuevos sin `chmod/chown` retroactivos.

## Decisiones cerradas

- `root_squash` se mantiene;
- no se usan permisos por usuario individual como estrategia principal;
- todo acceso compartido se basa en grupos funcionales;
- `jrenewhite` es admin humano con acceso de escritura a `media/docs`;
- `apps` es la identidad estándar para escritura de contenedores.

## Interfaces

### Grupos

- `apps`
- `media_rw`
- `media_ro`
- `docs_rw`
- `docs_ro`

### Política de apps

- contenedores que escriban a media deben usar `apps` o `PUID/PGID` compatibles con `apps` + grupo `media_rw`
- contenedores que escriban a docs deben usar `apps` o `PUID/PGID` compatibles con `apps` + grupo `docs_rw`

## Flujos

### Alta de usuario humano

- crear usuario;
- agregarlo al grupo funcional correcto;
- no tocar ownership histórico.

### Alta de app nueva

- decidir si escribe en `media`, `docs`, o solo local;
- si escribe a `NFS`, usar identidad compatible con `apps`.

## Aceptación

- escritura y lectura correctas desde `services` en `/srv/media` y `/srv/docs`;
- ningún servicio necesita desactivar `root_squash`;
- agregar un usuario nuevo solo requiere membresía de grupo.

## Dependencias previas

- direccionamiento y acceso `SSH`

## Fuera de fase

- integración LDAP
- SSO
- ACLs por persona en bibliotecas de aplicación
