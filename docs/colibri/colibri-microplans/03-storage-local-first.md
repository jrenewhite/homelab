# Microplan 03 — Storage Local-First y `nas` Despertable

## Propósito

Cerrar la regla arquitectónica más importante: `services` trabaja local y `nas` solo es archivo frío, sync target y librería final despertable.

## Estado actual

- `nas` exporta `/srv/media` y `/srv/docs`
- `services` monta ambos exports por `NFS`
- `services` tiene storage local en `/storage`
- `nas` está operativo hoy como storage activo, pero la arquitectura aprobada lo restringe a comportamiento despertable

## Objetivo final

- `services` opera sin que `nas` esté despierto;
- `nas` se despierta solo por sync, backup, archivo final o consulta explícita;
- ninguna base de datos o estado caliente vive en `nas`.

## Decisiones cerradas

- `services` es local-first;
- `nas` nunca es dependencia runtime obligatoria de apps críticas;
- `/srv/media` y `/srv/docs` son namespaces finales, no working storage permanente;
- `sync` puede ser programado o bajo demanda, pero nunca requisito para que arranque una app.

## Interfaces

### Storage local de `services`

- `/storage/apps`
- `/storage/cache`
- `/storage/inbox`
- `/storage/media-staging`
- `/storage/sync-out`

### Storage final de `nas`

- `/srv/media`
- `/srv/docs`

## Matriz por tipo de servicio

| Tipo | Runtime | Destino final |
|---|---|---|
| DBs, colas, Redis, caches | local | backup a `nas` |
| Arr staging | local | archive a `nas:/srv/media` |
| Paperless ingest | local | archive a `nas:/srv/docs` |
| Immich uploads recientes | local | archive/política posterior |
| Matrix media store | local | backup a `nas` |
| librerías finales | opcional local/hot | `nas` |

## Flujos

### Normal

- la app trabaja local;
- genera output en staging o sync-out;
- una ventana controlada despierta `nas`;
- sincroniza;
- `nas` vuelve a dormirse si no hay actividad.

### Falla

- si `nas` no despierta, la app sigue local;
- si `nas` está despierto pero NFS cae, no se afecta el estado caliente;
- si blackout ocurre, se cancelan wake jobs y syncs no esenciales.

## Aceptación

- ninguna app crítica depende de que `/srv/media` o `/srv/docs` estén montados para arrancar;
- la arquitectura por servicio declara claramente local, sync y archivo final;
- wake/sync/sleep queda documentado antes de implementación.

## Dependencias previas

- identidades compartidas
- permisos y `NFS`

## Fuera de fase

- implementación de jobs de sync
- auto-sleep real de `nas`
- auditoría completa del contenido heredado de `media`
