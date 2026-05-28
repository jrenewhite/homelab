# Microplan 04I — Guardrails Operativos y Runbook Manual de Energia

## Resumen

`Microplan 04I` consolida `Microplan 04` como fase de observacion y recuperacion manual.

No se ejecutaron acciones reales adicionales. No se modificaron `NUT`, `ntfy`, `DNS`, router, `Pi-hole`, `Caddy`, `cloudflared`, `Tailscale`, `SSO`, `NFS`, mounts ni apps productivas.

Estado base heredado:

- `LinkedPro` observado por `NUT` desde `management`
- `Epcom` tratada como rama manual/no instrumentada
- `ntfy-local` operativo para alertas no destructivas
- `WOL` validado en `x86_64`
- `SBC ARM` clasificadas como `always-on/manual-recovery/no-WOL-automation`

## Guardrails Finales

- `WOL` manual solo esta permitido si `NUT` reporta `OL`.
- Prohibido despertar `nas` y `ai-gpu` en bateria.
- `WOL` automatico sigue prohibido por ahora.
- `shutdown` automatico sigue prohibido por ahora.
- `Epcom` requiere verificacion manual.
- `ping` no implica readiness.
- Cualquier recuperacion debe validar por capas:
  - `ping`
  - `SSH`
  - `hostname`
  - servicios base
  - health especifico del rol
- `ntfy` y `logger` son best-effort y no deben bloquear `NUT`.
- Las `SBC ARM` deben permanecer encendidas mientras el `UPS` lo permita; si se apagan, la recuperacion es manual.

## Condiciones que Permiten `WOL` Manual

- `NUT` reporta `OL`.
- `battery.charge` esta disponible.
- `management` sigue operativo o existe emisor alterno ya validado, como `orangepi5-ultra`.
- Hay recuperacion manual disponible.
- El nodo objetivo ya fue validado en `04H`.
- No hay trabajo critico activo en el nodo objetivo.
- Existe un health check minimo definido para el rol del nodo.

## Condiciones que Prohiben `WOL`

- `ups.status != OL`
- evento `ONBATT/OB`
- evento `LOWBATT/LB`
- falta de visibilidad sobre `LinkedPro`
- falta de recuperacion manual
- falta de health check minimo definido
- nodo no validado previamente para `WOL`
- intento de despertar `nas` o `ai-gpu` en bateria

## Runbook Manual por Evento

### `ONLINE/OL`

Accion actual:

- registrar estado estable
- confirmar `upsc linkedpro@localhost`
- confirmar `nut-server` y `nut-monitor`
- confirmar recepcion local de `ntfy`/journal si aplica

Permitido hoy:

- `WOL` manual de nodos ya validados, si hace falta recuperar algo y no hay bateria
- operacion manual normal

Prohibido hoy:

- `WOL` automatico
- `shutdown` automatico

### `ONBATT/OB`

Accion actual:

- registrar evento
- asumir que `Epcom` requiere verificacion manual
- congelar cualquier automatismo futuro pesado
- revisar que nodos siguen arriba

Permitido hoy:

- operacion manual conservadora
- observacion de `battery.charge`, `battery.runtime`, `ups.status`

Prohibido hoy:

- despertar `nas`
- despertar `ai-gpu`
- cualquier `WOL` automatico
- cualquier `shutdown` automatico

### `LOWBATT/LB`

Accion actual:

- registrar alerta critica
- preparar decision manual segun runbook
- verificar que no se dispare ningun flujo destructivo

Permitido hoy:

- solo coordinacion manual

Prohibido hoy:

- apagado automatico
- wake automatico

Orden futuro solo documental:

1. `ai-gpu`
2. `nas`
3. `services`
4. `SBC ARM` auxiliares si aplica
5. `management` al final si aplica

### `COMMBAD`

Accion actual:

- registrar perdida de comunicacion
- congelar automatismos
- operar manualmente

Permitido hoy:

- diagnostico manual
- verificacion de red, UPS visible y estado del control plane

Prohibido hoy:

- inferir bateria solo desde ausencia de red
- ejecutar wake/shutdown automatico

### `COMMOK`

Accion actual:

- registrar recuperacion de comunicacion
- volver a evaluar estado real con `upsc`

Permitido hoy:

- reanudar observacion normal

Prohibido hoy:

- auto-wake por simple recuperacion de comunicacion

### `FSD`

Estado:

- solo futuro
- no se usa en esta fase

Prohibido hoy:

- `upsmon -c fsd`
- cualquier integracion que derive en apagado real

## Runbook Manual por Nodo

### Si `management` cae

- verificar energia de la rama `Epcom`
- verificar `ER707-M2` y switching de control
- si `LinkedPro` esta en `OL` y `management` fue validado, se permite `WOL` manual desde `orangepi5-ultra`
- validar recuperacion por capas:
  - `ping`
  - `SSH`
  - `hostname`
  - `nut-server`
  - `nut-monitor`
  - `upsc linkedpro@localhost`
  - reachability a `ntfy-local`

### Si `services` cae

- confirmar que no hay trabajo critico activo
- si `LinkedPro` esta en `OL`, se permite `WOL` manual
- caveat: esperar `ping`, luego `SSH`, luego readiness real; `systemd-networkd-wait-online` puede retrasar `SSH`
- validar:
  - `hostname`
  - `nut-monitor`
  - mounts esperados
  - servicios base del nodo

### Si `nas` esta apagado

- confirmar `LinkedPro` en `OL`
- usar NIC preferido `enp3s0` y MAC `C8:FF:BF:05:F4:47`
- para `poweroff -> WOL`, dejar unos segundos de espera antes del packet
- validar:
  - `ping`
  - `SSH`
  - `hostname`
  - `nut-monitor`
  - `md0/md1`
  - `mergerfs`
  - exports `NFS`

### Si `ai-gpu` esta apagado

- confirmar `LinkedPro` en `OL`
- confirmar ventana libre y sin trabajo GPU critico
- se permite `WOL` manual
- validar:
  - `ping`
  - `SSH`
  - `hostname`
  - `nut-monitor`
  - `/storage`
  - GPU visible por driver/PCI

### Si una `SBC ARM` se apaga

- no usar `WOL` como estrategia operativa
- recuperar manualmente
- reclasificar solo si en otra fase futura se demuestra comportamiento distinto

## Acciones Permitidas Hoy

- observacion `NUT`
- logging local
- notificacion local `ntfy`
- `WOL` manual en `OL` para nodos `x86_64` ya validados
- recuperacion manual de `SBC ARM`

## Acciones Futuras Bloqueadas

- `WOL` automatico
- `shutdown` automatico
- wake de `nas` o `ai-gpu` en bateria
- uso de `FSD`
- decisiones automaticas basadas en `Epcom`
- reactivacion automatica de workloads por solo volver `ping`

## Criterios Previos a Cualquier Fase Destructiva Futura

- backup/restore probado
- servicios criticos clasificados
- health checks por rol definidos y probados
- ventana controlada
- rollback explicito
- runbook manual vigente

## Veredicto

- `Microplan 04` puede cerrarse como `observation/manual-recovery ready`
- no queda listo para automatizacion destructiva
- el siguiente paso sano seria una fase futura separada de guardrails para automatizacion controlada, no de ejecucion real
