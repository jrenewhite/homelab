# Microplan 10 — `colibri-sentinel-bot`

## Propósito

Definir el contrato completo del bot de resiliencia antes de implementarlo.

## Estado actual

- no hay código ni imagen aún
- la arquitectura ya lo requiere como actor de observación, takeover y acciones limitadas

## Objetivo final

- bot documentado como imagen Docker propia
- contrato HTTP, roles, eventos y acciones cerrados
- límites de autoridad definidos por nodo y contexto eléctrico

## Decisiones cerradas

- despliegue:
  - `management` = `ROLE=primary`
  - `orangepi5-ultra` = `ROLE=secondary`
- implementación futura empaquetada como imagen Docker propia
- takeover solo limitado, no control total simétrico
- el bot entra primero en modo observación y alerta; las acciones automáticas se habilitan después

## Interfaces

### Imagen

- `colibri-sentinel-bot:<version>`

### Variables de entorno mínimas

- `ROLE`
- `NODE_NAME`
- `MATRIX_HOMESERVER`
- `MATRIX_TOKEN`
- `TELEGRAM_TOKEN`
- `TELEGRAM_CHAT_ID`
- `NUT_HOST`
- `NUT_PORT`
- `WOL_TARGETS`
- `SHUTDOWN_TARGETS`
- `HEALTH_TARGETS`
- `MAINTENANCE_FLAG_PATH`

### Endpoints

- `GET /health`
- `GET /status`
- `GET /metrics`

### Formato mínimo `/status`

- `node`
- `role`
- `mode`
- `internet`
- `matrix`
- `dns`
- `power`
- `last_check`

### Acciones permitidas

- `status`
- `wake services`
- `wake nas`
- `wake gpu`
- `sleep nas`
- `sleep gpu`
- `check matrix`
- `check dns`
- `blackout status`
- `maintenance on`
- `maintenance off`

## Flujos

### Normal

- `management` ejecuta acciones
- `ultra` observa y reporta

### Caída de `management`

- `ultra` entra en takeover limitado
- mantiene DNS secundario y proxy backup
- alerta por Matrix si `services` sigue vivo

### Caída de `services`

- Matrix puede caer
- el bot usa canal alterno
- no intenta despertar `nas` ni `ai-gpu` en blackout

## Aceptación

- contrato completo documentado sin escribir código;
- roles primary/secondary cerrados;
- límites de autoridad documentados;
- no hay ambigüedad sobre eventos, acciones ni fallback.
- existe un camino de activación gradual de observación a acción

## Prechecks mínimos

- endpoints de salud definidos
- canal alterno de alertas disponible
- reglas de autoridad por nodo aprobadas
- despliegue inicial en modo observación

## Rollback

- volver el bot a modo observación
- desactivar acciones automáticas
- si un automatismo hace algo inesperado, retirar permisos de acción antes de tocar lógica

## Dependencias previas

- blackout
- DNS
- proxy
- canal alterno definido

## Fuera de fase

- implementación del contenedor
- comandos Matrix reales
- Prometheus exporter completo
