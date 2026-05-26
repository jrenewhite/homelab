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
- el modelo multi-site es `activo-local por sitio + ventanas de sincronización`
- la sincronización entre `Colibrí` y `Perú` se hace por ventanas de bajo tráfico sostenido
- ningún cambio de storage se hace simultáneamente con cambios de IP, DNS o túneles
- primero se valida escritura local; luego sync; luego consumo opcional de archivo final

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
- si aplica, replica a la otra sede por `WireGuard` en una ventana separada o coordinada;
- `nas` vuelve a dormirse si no hay actividad.
- cualquier cambio de mounts o política de sync se prueba primero con datos no críticos

### Falla

- si `nas` no despierta, la app sigue local;
- si `nas` está despierto pero NFS cae, no se afecta el estado caliente;
- si blackout ocurre, se cancelan wake jobs y syncs no esenciales.
- si `Perú` está caído o aislado, `Colibrí` sigue local y difiere replicación inter-sede.

## Aceptación

- ninguna app crítica depende de que `/srv/media` o `/srv/docs` estén montados para arrancar;
- la arquitectura por servicio declara claramente local, sync y archivo final;
- wake/sync/sleep queda documentado antes de implementación.

## Prechecks mínimos

- mounts y rutas actuales inventariados
- storage local validado con datos de prueba
- servicio afectado identificable y detenible
- no mezclar el cambio con DNS, IPs o túneles
- backup o snapshot lógico del estado de la app antes de mover rutas reales

## Rollback

- volver la app a su ruta local previa
- desmontar o deshabilitar temporalmente el sync nuevo sin tocar datos calientes
- si un mount final falla, la app debe seguir local; si no lo hace, el cambio se revierte y no avanza

## Dependencias previas

- identidades compartidas
- permisos y `NFS`

## Fuera de fase

- implementación de jobs de sync
- auto-sleep real de `nas`
- auditoría completa del contenido heredado de `media`
