# Microplan 04 — Energía, UPS y Blackout

## Propósito

Definir la política eléctrica y de degradación ordenada de `Colibrí`.

## Estado actual

- `management` está en UPS sin integración útil en Linux
- `services`, `nas`, `ai-gpu` y Orange Pi relevantes están en UPS compatible con estrategia `NUT`
- `NUT` está instalado en `management` pero no configurado ni operativo

## Objetivo final

- `services` actúa como `NUT master`
- `orangepi5-ultra` observa y puede tomar acciones limitadas
- blackout no despierta nodos pesados ni storage frío

## Decisiones cerradas

- `management` no es `NUT master`
- `services` sí es `NUT master`
- `orangepi5-ultra` es observador y takeover limitado
- `nas` y `ai-gpu` no pueden despertarse si el sistema está en batería
- los cambios de energía y blackout se validan primero en modo observación, luego en modo acción

## Interfaces

### Roles `NUT`

- `services`: master
- `orangepi5-ultra`: observer/sentinel
- `ai-gpu`: client
- `nas`: client
- `orangepi5-max/a/b`: clients opcionales según utilidad real

## Flujos

### Normal

- energía comercial estable;
- jobs pesados permitidos;
- wake de `ai-gpu` y `nas` permitido según reglas.

### En batería

- `services` detecta;
- genera evento a `management` y `ultra`;
- bloquea wake de `nas` y `ai-gpu`;
- pausa jobs pesados;
- si `nas` ya está despierto, sync mínimo y shutdown controlado.

### Batería baja

- apagar ordenadamente `ai-gpu`, `nas`, `services`;
- mantener `Orange Pi` el mayor tiempo posible;
- `management` conserva control de red hasta donde soporte su UPS.

## Aceptación

- existe runbook exacto por evento de energía;
- roles `NUT` no se contradicen con la topología real de UPS;
- ninguna automatización crítica depende de `management` como master de blackout.
- existe una secuencia de prueba segura que no apaga nodos útiles en la primera validación

## Prechecks mínimos

- topología UPS confirmada físicamente
- mapa de nodos por UPS y compatibilidad Linux confirmados
- `NUT` primero en modo observación
- blackout test plan aprobado y con ventana controlada
- reglas explícitas que impidan wake de `nas` y `ai-gpu` en batería

## Rollback

- volver `NUT` y el bot a modo observación
- desactivar automatismos de apagado o wake
- si una prueba genera comportamiento inesperado, abortar y restaurar operación manual

## Dependencias previas

- red estable
- bot definido a nivel de contrato

## Fuera de fase

- implementación final de `NUT`
- integración de métricas eléctricas
