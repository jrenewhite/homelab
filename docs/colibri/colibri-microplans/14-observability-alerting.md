# Microplan 14 — Observabilidad y Alertas

## Propósito

Definir cómo `Colibrí` sabe que está sano, degradado o caído, y cómo avisa.

## Estado actual

- no existe observabilidad mínima cerrada
- el bot está solo definido conceptualmente

## Objetivo final

- checks mínimos por nodo y por servicio crítico;
- Matrix como canal normal;
- Telegram, `ntfy` o email como canal alterno final;
- eventos locales persistibles si no hay Internet.

## Decisiones cerradas

- canal normal: Matrix
- canal alterno: se documentará uno final antes de implementación, pero el diseño debe asumir fallback obligatorio
- `management` y `ultra` observan estado de:
  - Internet
  - DNS
  - `services`
  - `nas`
  - `ai-gpu`
  - túnel/proxy

## Interfaces

### Señales mínimas

- ping o reachability
- `HTTP /health`
- estado `NUT`
- estado de wake/sleep
- estado de mantenimiento

### Eventos críticos

- `management_down`
- `services_down`
- `nas_unavailable`
- `gpu_offline_unexpected`
- `internet_down`
- `matrix_down`
- `power_on_battery`

## Flujos

### Normal

- publicar a Matrix

### Matrix caído

- usar canal alterno

### Internet caído

- registrar localmente y reintentar

## Aceptación

- cada evento crítico tiene comportamiento documentado;
- existe camino de alerta si `services` cae;
- la observabilidad mínima no depende de `nas`.

## Dependencias previas

- bot
- blackout
- DNS
- proxy

## Fuera de fase

- stack completa Prometheus/Grafana
- retención avanzada de métricas
