# Goal Execution 04A — Energy, UPS and Blackout Observation

Fecha de ejecucion: `2026-05-27`  
Modo: `observation-only`

## Objetivo

Cerrar el inventario factual de UPS, `WOL`, topologia electrica y candidatos `NUT` sin editar configuracion, sin reiniciar servicios y sin probar apagados o wake reales.

## Restricciones respetadas

- no se editaron:
  - `nut.conf`
  - `ups.conf`
  - `upsd.users`
  - `upsmon.conf`
- no se habilitaron ni reiniciaron servicios `NUT`
- no se tocaron:
  - router
  - DNS
  - `Pi-hole`
  - `Caddy`
  - `cloudflared`
  - `Tailscale`
  - `SSO`
  - `NFS`
  - mounts
  - apps productivas
- no se enviaron magic packets
- no se probaron shutdowns ni blackout reales

## Nodos observados

- `management` `192.168.0.10`
- `services` `192.168.0.12`
- `nas` `192.168.0.11`
- `ai-gpu` `192.168.0.13`
- `orangepi5-ultra` `192.168.0.14`

## Comandos ejecutados

### Conectividad

```bash
ping -c 1 -W 1 192.168.0.10
ping -c 1 -W 1 192.168.0.12
ping -c 1 -W 1 192.168.0.14
ping -c 1 -W 1 192.168.0.11
ping -c 1 -W 1 192.168.0.13

ssh ... jrenewhite@192.168.0.10 hostname
ssh ... jrenewhite@192.168.0.12 hostname
ssh ... root@192.168.0.11 hostname
ssh ... jrenewhite@192.168.0.13 hostname
ssh ... jrenewhite@192.168.0.14 hostname
```

### Inventario read-only por nodo

```bash
ip -br link
ethtool <iface>
systemctl status nut-server nut-client nut-monitor --no-pager --lines=0
upsc -l
lsusb
upower -d
dmesg | grep -Ei "ups|eaton|mge|apc|hid|usb"
```

## Resultado de conectividad

| Nodo | ping | SSH | Lectura |
|---|---|---|---|
| `management` | ok | ok | operativo |
| `services` | ok | ok | operativo |
| `nas` | ok | ok | operativo |
| `ai-gpu` | ok | ok | operativo |
| `orangepi5-ultra` | fail inicial, recuperado despues | ok al cierre | operativo al cierre, pero con acceso inestable durante la ventana |

## UPS detectadas por nodo

| Nodo | UPS detectada | Evidencia | Observacion |
|---|---|---|---|
| `management` | si, sobre una de dos UPS | `lsusb`: `0463:0001 MGE UPS Systems UPS`; `upower -d`: `vendor Eaton`, `ups_hiddev0`, `100%`, `on-battery: no` | la visibilidad Linux corresponde a la `LinkedPro LP1KRT`; `management` se alimenta de la `Epcom EPU1500LCD`, que no reporta por Linux |
| `services` | no | sin UPS en `lsusb`; `upower` solo `DisplayDevice` sin supply | no debe ser `NUT master` |
| `nas` | no | sin UPS en `lsusb`; sin `upower` util para UPS | no hay visibilidad local de UPS |
| `ai-gpu` | no | sin UPS en `lsusb`; `upower` sin supply | no hay visibilidad local de UPS |
| `orangepi5-ultra` | no | sin UPS en `lsusb`; sin `upower` util para UPS | no hay visibilidad local de UPS |

## Estado `NUT` observado

| Nodo | Paquetes/servicios | Estado |
|---|---|---|
| `management` | `nut-server` y `nut-monitor` presentes | ambos fallando y deshabilitados; `upsc -l` responde `connection refused` |
| `services` | no encontrados | `NUT` no instalado/configurado |
| `nas` | no encontrados | `NUT` no instalado/configurado |
| `ai-gpu` | no encontrados | `NUT` no instalado/configurado |
| `orangepi5-ultra` | no encontrados | `NUT` no instalado/configurado |

## Inventario `WOL` read-only

| Nodo | Interfaz principal | `MAC` | `WOL` soportado | `WOL` habilitado | Accion permitida en energia normal | Accion prohibida en bateria |
|---|---|---|---|---|---|---|
| `management` | `eno1` | `C4:65:16:AC:AB:37` | no confirmado | no confirmado | observacion y futura coordinacion | despertar `nas` o `ai-gpu` |
| `services` | `enp2s0` | `58:47:CA:79:08:69` | no confirmado | no confirmado | seguir operativo como nodo de servicios | asumir rol `master` o despertar nodos pesados |
| `nas` | `eno1` | `C8:FF:BF:05:F4:46` | si | si, `Wake-on: g` | capacidad tecnica presente solo en energia normal | despertar `nas` en bateria |
| `ai-gpu` | `enp4s0` | `58:47:CA:7F:84:B5` | no confirmado | no confirmado | seguir inventariado/encendido si ya estaba arriba | despertar `ai-gpu` en bateria |
| `orangepi5-ultra` | `enP3p49s0` | `C0:74:2B:FC:59:86` | no confirmado | no confirmado | seguir como nodo auxiliar ligero en energia normal | usarlo como pivot de wake o blackout sin UPS local confirmada |

Nota:

- en `management`, `services` y `ai-gpu`, `ethtool` no expuso lineas `Supports Wake-on`/`Wake-on`; no se puede afirmar soporte o estado actual de `WOL` en esta ventana
- en `nas`, `ethtool` si confirmo `Supports Wake-on: pumbg` y `Wake-on: g`

## Nodos por UPS

### `LinkedPro LP1KRT` online `1000VA/900W` visible en Linux

- `ai-gpu`
- `nas`
- `services`
- `orangepi5-ultra`
- `orangepi5-max`
- `orangepi5-a`
- `orangepi5-b`
- ventiladores USB asociados `~5W`

Observacion:

- la telemetria Linux/NUT observada desde `management` corresponde a esta UPS
- es la unica UPS candidata para `NUT` en esta fase
- `management` la observa por USB, pero no recibe energia de esta UPS

### `Epcom EPU1500LCD` linea interactiva no instrumentada

- `management`
- `Starlink` actuated `v3`
- `Omada ER707-M2`
- `TP-Link TL-SG108`
- `DS105G-M2`
- ventiladores USB asociados `~5W`

Observacion:

- esta UPS no entrega telemetria util a Linux en esta fase
- debe entrar al runbook como infraestructura protegida pero no instrumentada
- autonomia observada por el usuario: cerca de `1 hora` en un corte real con las cargas actuales

## Candidato real a `NUT master`

- `management`

Condicion:

- solo si sigue viendo la `LinkedPro LP1KRT` compatible por Linux en la siguiente ventana, entendiendo que su propia energia depende de la `Epcom`

## Clientes `NUT` propuestos

- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

## Runbook propuesto en modo observacion

### Normal

- registrar que la UPS esta online
- registrar nodos arriba
- registrar servicios que dependen de `nas`
- no ejecutar acciones

### On Battery

- registrar el evento
- confirmar que `management` sigue viendo la `LinkedPro LP1KRT`
- verificar manualmente el estado de la rama protegida por la `Epcom EPU1500LCD`
- no usar canaries activos ni heartbeats energeticos para inferir estado de la `LinkedPro`
- confirmar que `nas` y `ai-gpu` no deben despertarse
- congelar cualquier automatismo futuro
- no apagar ni dormir nada en `04A`

### Low Battery

- registrar umbral y severidad
- documentar el orden propuesto de apagado para `04B/04C`, sin ejecutarlo:
  - `ai-gpu`
  - `nas`
  - `services`
  - nodos auxiliares
  - `management` al final si aplica

### Recovery

- registrar retorno de utility
- registrar que nodos siguen arriba
- recordar que la `Epcom` no aportara señal automatica de recovery
- no ejecutar wake automatico en `04A`

### Comm Lost

- distinguir:
  - perdida de UPS en Linux
  - perdida de `SSH` a un nodo
  - perdida de servicio `NUT`
- decision por defecto:
  - congelar automatismos
  - operar manualmente
  - no avanzar configuracion hasta cerrar la brecha

## Brechas detectadas

| Brecha | Severidad | Efecto |
|---|---|---|
| `orangepi5-ultra` con acceso inestable durante la ventana | media | obliga a tratarlo como nodo auxiliar no critico hasta confirmar estabilidad |
| coexistencia entre `LinkedPro LP1KRT` instrumentada y `Epcom EPU1500LCD` no instrumentada aun no esta aterrizada en politica `NUT` | alta | bloquea promover `04B` con confianza |
| `management` ve UPS, pero `NUT` instalado esta fallando y no se leyo configuracion efectiva con privilegios en esta ventana | media | requiere revisar configuracion en `04B`, no en `04A` |
| `WOL` solo confirmado en `nas` | media | falta confirmar soporte/estado real en otros nodos si la politica futura lo necesitara |
| `services` no ve UPS local y contradice la doc vieja | alta | invalida el modelo anterior donde `services` era `master` |

## Resultado

- `management` si ve una UPS compatible en Linux
- `management` se alimenta de la `Epcom EPU1500LCD`, pero observa por USB la `LinkedPro LP1KRT`
- `services` no ve UPS local y no debe ser `NUT master`
- `nas` y `ai-gpu` quedan explicitamente prohibidos para wake en bateria
- `orangepi5-ultra` no ve UPS local y queda solo como cliente/auxiliar propuesto
- no se justifica usar canaries activos: `NUT` ya aporta la senal primaria de la `LinkedPro`

## Recomendacion

- `Microplan 04B`: `no-go`

Motivos:

- la topologia fisica ya esta clara, pero hay una UPS no instrumentada (`Epcom EPU1500LCD`) que obliga a politica manual complementaria
- la doc vieja de roles `NUT` contradice la realidad observada
- pasar a configuracion `NUT` ahora obligaria a descubrir topologia editando config, que esta fuera de fase
