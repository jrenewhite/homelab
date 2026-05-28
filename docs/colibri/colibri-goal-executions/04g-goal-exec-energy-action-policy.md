# Goal Execution 04G — Future Energy Action Policy, No Real Execution

Fecha de ejecucion: `2026-05-28`  
Modo: `policy only`

## Objetivo

Definir la politica futura de acciones ante eventos de energia observados por `NUT`, sin apagar, despertar, suspender ni modificar servicios productivos.

## Restricciones respetadas

- no se ejecuto shutdown real
- no se uso `upsmon -c fsd`
- no se desconecto ninguna UPS
- no se enviaron magic packets
- no se hizo wake/sleep
- no se pausaron servicios reales
- no se tocaron:
  - DNS
  - router
  - `Pi-hole`
  - `Caddy`
  - `cloudflared`
  - `Tailscale`
  - `SSO`
  - `NFS`
  - mounts
  - apps productivas
  - `ntfy`

## Matriz de eventos

| Evento | Accion actual | Notificacion actual | Accion futura permitida | Accion futura prohibida | Nodos afectados | Precondiciones antes de activar accion real | Rollback esperado |
|---|---|---|---|---|---|---|---|
| `ONLINE` / `OL` | solo observacion | `journal` + `ntfy-local` si aplica | registrar recuperacion; reabrir ventana de operacion manual; eventualmente reactivar jobs ligeros con gating | auto-wake de `nas`/`ai-gpu`; reactivar cargas pesadas sin verificacion | `management`, clientes `NUT`, rama `LinkedPro` | `NUT` estable; runbook claro; criterio de recuperacion definido; ventana controlada | congelar reactivaciones; volver a modo observacion |
| `ONBATT` / `OB` | solo observacion | `journal` + `ntfy-local` si aplica | registrar evento; congelar jobs pesados; preparar decision manual; eventualmente frenar tareas no criticas | wake de `nas`; wake de `ai-gpu`; shutdown automatico en esta etapa | `management`, `services`, `nas`, `ai-gpu`, `orangepi5-*` sobre `LinkedPro` | clasificacion de servicios critica/no critica; backups verificados; runbook manual; testing previo en AC | deshacer solo flags/logica de congelamiento; volver a observacion |
| `LOWBATT` / `LB` | solo observacion | `journal` + `ntfy-local` si aplica | registrar alerta critica; usar orden documental futuro de apagado; preparar accion manual asistida | apagado automatico real antes de validar runbook; wake de ningun nodo | toda la rama `LinkedPro`; dependencia indirecta de `management` como observador | backup/restore probado; orden de apagado aprobado; ventana controlada; rollback documentado; WOL probado en AC | detener automatismo; volver a manual; restaurar solo banderas/temporizadores de politica |
| `COMMBAD` | solo observacion | `journal` + `ntfy-local` si aplica | congelar automatismos; operar manualmente; verificar fisicamente `LinkedPro` y rama `Epcom` | inferir que la `Epcom` cayo; despertar nodos; apagar por suposicion | `management` y cualquier cliente que pierda la fuente remota | runbook manual; topologia fisica confirmada; canal alterno de acceso local | desactivar solo integraciones automáticas; volver a modo manual |
| `COMMOK` | solo observacion | `journal` + `ntfy-local` si aplica | registrar recuperacion; reanudar observacion normal; evaluar si se libera congelamiento manual | auto-wake; reactivar jobs pesados por defecto | `management` y clientes `NUT` | confirmacion de estabilidad; no estar en `LB`; operador disponible | reimponer congelamiento si vuelve a fallar la comunicacion |
| `FSD` | no usado | solo documentado; no probado | evento reservado para fase futura con shutdown real controlado | uso en esta etapa; ejecucion manual o automatica | solo futuro; potencialmente toda la rama `LinkedPro` | runbook probado; backup/restore probado; WOL probado en AC; ventana controlada; rollback y criterio de abortar cerrados | volver a `SHUTDOWNCMD \"/bin/true\"`; desactivar politica real; restaurar configuracion previa |

## Reglas obligatorias

- en bateria, esta prohibido despertar:
  - `nas`
  - `ai-gpu`
- `ntfy` y el logging no deben bloquear `NUT`
- la `Epcom` requiere verificacion manual
- `management` observa la `LinkedPro`, pero se alimenta de la `Epcom`
- ninguna notificacion puede convertirse en accion real sin una fase explicita posterior

## Orden futuro de apagado, solo documental

Orden propuesto para una fase futura con ejecucion real:

1. `ai-gpu`
2. `nas`
3. `services`
4. `Orange Pi` auxiliares si aplica
5. `management` al final, solo si el runbook futuro realmente lo requiere

Razonamiento:

- primero se recorta carga alta y menos critica para continuidad de control
- `nas` va temprano por consumo y porque su despertar en bateria esta prohibido
- `services` puede sostenerse un poco mas mientras el control plane sigue observando
- `management` debe vivir lo suficiente para registrar, notificar y coordinar

## Bloqueos antes de activar acciones reales

Antes de cualquier fase con shutdown o wake real debe existir:

- backup/restore probado
- servicios criticos clasificados
- `WOL` probado en AC
- runbook manual validado
- ventana controlada
- rollback explicito

Bloqueos adicionales:

- `Epcom` sigue no instrumentada
- `management` no comparte rama electrica con la `LinkedPro`
- `ntfy-local` sigue como deuda tecnica controlada hasta migrar a stack versionado

## Acciones prohibidas por ahora

- shutdown real por `NUT`
- wake automatico de cualquier nodo
- wake de `nas` o `ai-gpu` en bateria
- pausado real de servicios productivos
- decisiones automaticas basadas en la `Epcom`

## Conclusion

`04G` deja cerrada la politica futura de acciones como marco documental:

- acciones actuales: solo observacion, logging y notificacion
- acciones futuras: condicionadas a prechecks fuertes
- acciones prohibidas: explicitadas
- rollback: definido a nivel de politica, no de ejecucion real

## Recomendacion

Go/no-go para `04H`:

- `go` para `04H` como prueba real de `WOL` con canary solo en energia normal
