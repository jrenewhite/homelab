# Microplan 13 — Media, IA y Jobs Pesados

## Propósito

Definir el reparto de media, IA, indexing, OCR y procesamiento pesado.

## Estado actual

- `services` tiene buen NVMe local
- `ai-gpu` está listo como nodo GPU
- `nas` ya exporta `media/docs`, pero la arquitectura aprobada exige local-first

## Objetivo final

- `Arr` y media-staging en `services`
- `Jellyfin` principal en `ai-gpu`
- `Immich core` en `services`
- `Immich ML` en `ai-gpu`
- `Hermes` liviano en `services`
- LLM grande y OCR/transcripción en `ai-gpu`

## Decisiones cerradas

- `Arr stack` vive en `services`
- `Jellyfin` principal vive en `ai-gpu`
- biblioteca final vive en `nas:/srv/media`
- staging y trabajo caliente viven en `services`
- `ai-gpu` no se despierta en blackout

## Matriz resumida

| Servicio | Nodo | Runtime storage | `nas` |
|---|---|---|---|
| Arr stack | `services` | local | archive final |
| Jellyfin | `ai-gpu` | local/hot + biblioteca final | sí, no runtime obligatoria para arranque |
| Immich core | `services` | local | archive/política posterior |
| Immich ML | `ai-gpu` | local | no directa |
| LLM grande | `ai-gpu` | local | no |
| OCR/Whisper/batch | `ai-gpu` | local | outputs opcionales a `nas` |

## Aceptación

- ningún job pesado contradice política de energía;
- la relación `services` -> staging -> `nas` -> librería final queda clara.

## Dependencias previas

- storage local-first
- blackout
- bot y wake policies

## Fuera de fase

- tuning de modelos
- cachés de contenido final
