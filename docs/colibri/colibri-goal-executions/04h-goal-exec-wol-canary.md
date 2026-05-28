# Microplan 04H — WOL Canary en Energia Normal

## Resumen

`Microplan 04H` se ejecuto como prueba real de `WOL` con un solo canary y en energia normal.

El canary elegido fue `orangepi5-b` (`192.168.0.17`) porque:

- no tiene contenedores activos
- no se observaron servicios criticos productivos corriendo
- existe recuperacion manual disponible si `WOL` falla

Durante esta fase se ajusto la politica:

- `SBC ARM` (`Orange Pi 5`, `Raspberry Pi 5B/4B`) se prueban solo con:
  - `poweroff -> magic packet -> boot`
- `x86_64` puede probarse despues con:
  - `suspend -> magic packet -> resume`
  - `poweroff -> magic packet -> boot`

La prueba real de este microplan se hizo entonces con `orangepi5-b` bajo politica `poweroff-only`.

## Prechecks

### `management`

- `upsc linkedpro@localhost`
  - `ups.status: OL`
  - `battery.charge: 100`
  - `input.voltage: 118.9`
- `systemctl is-active nut-server nut-monitor`
  - `active`
  - `active`
- `journalctl -t nut-event -n 3 --no-pager`
  - eventos sinteticos presentes
- `curl -fsS http://192.168.0.14:8080/v1/health`
  - `{\"healthy\":true}`
- `command -v wakeonlan`
  - `/usr/bin/wakeonlan`

### `orangepi5-b`

- hostname:
  - `orangepi5-b`
- interfaz principal:
  - `end1`
- ruta por defecto:
  - `default via 192.168.0.1 dev end1`
- `MAC`:
  - `c6:87:b3:c0:55:95`
- `ethtool` con privilegios:
  - `Supports Wake-on: ug`
  - `Wake-on: g`
- `cat /sys/power/state`
  - `freeze mem`
- `cat /sys/class/net/end1/device/power/wakeup`
  - `enabled`
- `docker ps`
  - sin contenedores activos

## Intento inicial descartado

Se verifico que `suspend` esta deshabilitado:

```text
Call to Suspend failed: Sleep verb 'suspend' is disabled by config
```

Configuracion causal:

```text
/etc/systemd/sleep.conf.d/00-disable.conf
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
```

Esto ya no se trato como bloqueo, sino como comportamiento esperado bajo politica `poweroff-only` para `SBC ARM`.

## Ejecucion real

Comando usado para programar el `poweroff`:

```bash
sudo bash -lc 'nohup sh -c "sleep 2; systemctl poweroff" >/tmp/wol-canary-poweroff.log 2>&1 &'
```

Comando `WOL` usado desde `management`:

```bash
wakeonlan -i 192.168.0.255 c6:87:b3:c0:55:95
```

Resultado observado:

- `orangepi5-b` salio de red a los `5s`
- se envio **un unico** magic packet a los `5s`
- el nodo no regreso por `ping`
- el nodo no regreso por `SSH`
- no se hizo segundo intento
- no se probo otro nodo

## Estado final

- `linkedpro` siguio en `OL`
- `battery.charge` siguio en `100`
- `input.voltage` siguio disponible
- `nut-server` y `nut-monitor` en `management` quedaron `active`
- `ntfy-local` siguio sano
- `orangepi5-b` quedo apagado y pendiente de recuperacion manual
- si el usuario ya lo recupero despues, esa recuperacion no formo parte automatizada de esta fase

## Conclusiones

- `04H` queda ejecutado con resultado:
  - `WOL-from-poweroff-failed-manual-recovery`
- el fallo no apunta a `NUT`, `ntfy` ni a la salud de `LinkedPro`
- el fallo observado es especifico del camino `poweroff -> magic packet -> boot` en `orangepi5-b`
- `suspend` deshabilitado ya no se considera problema para `SBC ARM`; simplemente no es la ruta de prueba relevante

## Recomendacion

- `orangepi5-b` no debe reclasificarse todavia como `unsupported`
- pero si como:
  - `WOL runtime visible`
  - `WOL-from-poweroff-failed-manual-recovery`
- para la siguiente fase, conviene mover el siguiente canary real a un nodo `x86_64` en `AC`
- una revision futura de `Orange Pi` puede incluir:
  - firmware/bootloader
  - comportamiento real de `WOL` desde apagado completo
  - diferencias entre apagado logico y estados de energia del carrier

## Go / No-Go

- repetir `WOL` real inmediato en `Orange Pi` despues de este intento: `no-go`
- prueba posterior en un canary `x86_64` y solo en `AC`: `go`, si se mantiene recuperacion manual clara

---

## `04H.2` — Canary `x86_64` con `services`

### Resumen

Despues del fallo ARM en `orangepi5-b`, `04H` continuo como `04H.2` con `services` como primer canary `x86_64`.

Politica aplicada:

1. `suspend -> magic packet -> resume`
2. `poweroff -> magic packet -> boot`

Siempre:

- un solo nodo
- `linkedpro` en `OL`
- recuperacion manual disponible
- sin cambios a `NUT`
- sin automatizacion

### Prechecks

En `management`:

- `ups.status: OL`
- `battery.charge: 100`
- `input.voltage: 118.9`
- `nut-server`: `active`
- `nut-monitor`: `active`
- `ntfy-local`: `{\"healthy\":true}`

En `services`:

- IP: `192.168.0.12`
- interfaz: `enp2s0`
- `MAC`: `58:47:CA:79:08:69`
- driver: `r8169`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- `docker ps`: sin contenedores activos
- `nut-monitor`: `active`
- `cat /sys/power/state`: `freeze mem`
- `cat /sys/class/net/enp2s0/device/power/wakeup`: `enabled`

### Comandos usados

`suspend` programado:

```bash
sudo bash -lc 'nohup sh -c "sleep 2; systemctl suspend" >/tmp/wol-suspend.log 2>&1 &'
```

`poweroff` programado:

```bash
sudo bash -lc 'nohup sh -c "sleep 2; systemctl poweroff" >/tmp/wol-poweroff.log 2>&1 &'
```

Magic packet desde `management`:

```bash
wakeonlan -i 192.168.0.255 58:47:ca:79:08:69
```

### Resultado `suspend -> magic packet -> resume`

- el nodo salio de red a los `4s`
- se envio un solo magic packet a los `4s`
- retorno por `ping`: `10s` despues del packet
- retorno por `SSH`: `11s` despues del packet

Clasificacion:

- `WOL-from-suspend-supported`

### Resultado `poweroff -> magic packet -> boot`

- el nodo salio de red a los `5s`
- se envio un solo magic packet a los `5s`
- retorno por `ping`: `16s` despues del packet
- retorno por `SSH`: `159s` despues del packet

Clasificacion:

- `WOL-from-poweroff-supported`

### Recuperacion manual

- no fue necesaria

### Estado final

- `services` regreso por `ping` y `SSH`
- `nut-monitor` en `services` quedo `active`
- `management` quedo con:
  - `ups.status: OL`
  - `battery.charge: 100`
  - `input.voltage` disponible
  - `nut-server` `active`
  - `nut-monitor` `active`
- `ntfy-local` siguio sano

### Lectura operativa

- `services` es el primer nodo `x86_64` con `WOL` real validado en ambos caminos
- el camino `poweroff -> WOL` funciona, pero el retorno completo de `SSH` puede tardar mucho mas que el retorno de red
- esto favorece usar ventanas controladas y timeouts generosos en cualquier fase futura

### Recomendacion

- `nas` como siguiente prueba posterior: `go`, pero en fase separada y con ventana controlada
- `ai-gpu` como siguiente prueba posterior: `go`, pero despues de `nas` y con cautela extra por superficie GPU/driver

---

## `04H.3` — Canary `x86_64` con `ai-gpu`

### Resumen

`04H` continuo con `ai-gpu` como segundo canary `x86_64`.

Politica aplicada:

1. `suspend -> magic packet -> resume`
2. `poweroff -> magic packet -> boot`

Siempre:

- un solo nodo
- `linkedpro` en `OL`
- recuperacion manual disponible
- sin cambios a `NUT`
- sin automatizacion

### Prechecks

En `management`:

- `ups.status: OL`
- `battery.charge: 100`
- `input.voltage: 119.6`
- `nut-server`: `active`
- `nut-monitor`: `active`
- `ntfy-local`: `{\"healthy\":true}`

En `ai-gpu`:

- IP: `192.168.0.13`
- interfaz: `enp4s0`
- `MAC`: `58:47:CA:7F:84:B5`
- driver: `r8169`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- `nut-monitor`: `active`
- `/storage`: montado
- `lspci` confirma `NVIDIA GeForce RTX 5060`
- modulos `nvidia*` cargados
- `nvidia-smi` no esta disponible en este sistema actual, por lo que el health minimo se ajusto a:
  - `SSH`
  - `nut-monitor`
  - `/storage`
  - GPU visible por `lspci`
  - modulos `nvidia*` cargados

### Comandos usados

`suspend` programado:

```bash
sudo bash -lc 'nohup sh -c "sleep 2; systemctl suspend" >/tmp/wol-ai-gpu-suspend.log 2>&1 &'
```

`poweroff` programado:

```bash
sudo bash -lc 'nohup sh -c "sleep 2; systemctl poweroff" >/tmp/wol-ai-gpu-poweroff.log 2>&1 &'
```

Magic packet desde `management`:

```bash
wakeonlan -i 192.168.0.255 58:47:ca:7f:84:b5
```

### Resultado `suspend -> magic packet -> resume`

- el nodo salio de red a los `4s`
- se envio un solo magic packet a los `4s`
- retorno por `ping`: `11s` despues del packet
- retorno por `SSH`: `11s` despues del packet
- health minimo operativo: `11s` despues del packet

Clasificacion:

- `WOL-from-suspend-supported`

### Resultado `poweroff -> magic packet -> boot`

- el nodo salio de red a los `4s`
- se envio un solo magic packet a los `4s`
- retorno por `ping`: `20s` despues del packet
- retorno por `SSH`: `21s` despues del packet
- health minimo operativo: `21s` despues del packet

Clasificacion:

- `WOL-from-poweroff-supported`

### Recuperacion manual

- no fue necesaria

### Estado final

- `ai-gpu` regreso por `ping` y `SSH`
- `nut-monitor` en `ai-gpu` quedo `active`
- `/storage` siguio montado
- GPU NVIDIA siguio visible por `lspci`
- modulos `nvidia*` siguieron cargados
- `management` quedo con:
  - `ups.status: OL`
  - `battery.charge: 100`
  - `nut-server` `active`
  - `nut-monitor` `active`
- `ntfy-local` siguio sano

### Lectura operativa

- `ai-gpu` queda validado como segundo nodo `x86_64` con `WOL` real funcional en ambos caminos
- su retorno fue mas rapido que `services`, tanto a `ping` como a `SSH`
- el caveat actual no es `WOL`, sino la ausencia de `nvidia-smi` como binario utilitario en este estado del sistema

### Recomendacion

- `nas` como siguiente prueba posterior: `go`, en fase separada y con reconfirmacion explicita
- `management` sigue reservado para una fase posterior, solo si `nas` pasa y se acepta el riesgo sobre el control plane

---

## `04H.3` — intento en `nas`

### Resumen

Despues del exito en `ai-gpu`, `04H.3` continuo con `nas` como siguiente nodo `x86_64`.

La secuencia se detuvo en la primera mitad:

- `suspend -> magic packet -> resume`

porque el nodo no regreso por `ping` ni por `SSH` dentro de la ventana de observacion.

### Prechecks

En `management`:

- `ups.status: OL`
- `battery.charge: 100`
- `input.voltage: 119.1`
- `nut-server`: `active`
- `nut-monitor`: `active`
- `ntfy-local`: `{\"healthy\":true}`

En `nas`:

- IP: `192.168.0.11`
- interfaz: `eno1`
- `MAC`: `C8:FF:BF:05:F4:46`
- driver: `igc`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- `nut-monitor`: `active`
- `md0` y `md1` en `[UU]`
- `/srv/media` y `/srv/docs` montados por `mergerfs`
- exports `NFS` visibles
- timers de tiering presentes pero no ejecutandose en la ventana

### Comandos usados

`suspend` programado:

```bash
nohup sh -c 'sleep 2; systemctl suspend' >/tmp/wol-nas-suspend.log 2>&1 &
```

Magic packet desde `management`:

```bash
wakeonlan -i 192.168.0.255 c8:ff:bf:05:f4:46
```

### Resultado `suspend -> magic packet -> resume`

- el nodo salio de red a los `5s`
- se envio un unico magic packet a los `5s`
- no hubo retorno por `ping`
- no hubo retorno por `SSH`
- no se pudo validar health minimo de almacenamiento

Clasificacion:

- `WOL-from-suspend-failed-manual-recovery`

### Reintento `suspend -> magic packet -> resume`

Despues de recuperar `nas`, se repitio la misma mitad con el mismo metodo.

- el nodo salio de red a los `4s`
- se envio un unico magic packet a los `4s`
- retorno por `ping`: `37s` despues del packet
- retorno por `SSH`: `37s` despues del packet
- health minimo operativo: `37s` despues del packet

Clasificacion actualizada:

- `WOL-from-suspend-supported-with-retry`

### Resultado `poweroff -> magic packet -> boot` usando `eno1`

- el nodo salio de red a los `7s`
- se envio un unico magic packet a los `7s`
- retorno por `ping`: `95s` despues del packet
- retorno por `SSH`: `95s` despues del packet
- health minimo operativo: `95s` despues del packet

Clasificacion:

- `WOL-from-poweroff-supported`

### Cambio de NIC y prueba sobre `enp3s0`

Despues de revisar el cableado y la configuracion local del `nas`, se cambio el NIC activo a:

- `enp3s0`
- `MAC` `C8:FF:BF:05:F4:47`

Observacion previa:

- `eno1` quedo `DOWN` y sin link
- `enp3s0` quedo `UP`, `192.168.0.11/24`
- ambos NICs siguen usando driver `igc`
- ambos exponen `Wake-on: g`

#### Resultado `suspend -> magic packet -> resume` usando `enp3s0`

- el nodo salio de red a los `4s`
- se envio un unico magic packet a los `4s`
- retorno por `ping`: `9s` despues del packet
- retorno por `SSH`: `9s` despues del packet
- health minimo operativo: `9s` despues del packet

Clasificacion:

- `WOL-from-suspend-supported`

#### Resultado `poweroff -> magic packet -> boot` usando `enp3s0`

- el nodo salio de red a los `17s`
- se envio un unico magic packet a los `17s`
- no hubo retorno por `ping` dentro de una ventana razonable
- no hubo retorno por `SSH`

Clasificacion:

- `WOL-from-poweroff-failed-manual-recovery`

#### Reprueba estricta `poweroff -> magic packet -> boot` usando `enp3s0`

Se repitio la prueba con dos diferencias:

- ventana maxima estricta de `3 min`
- espera extra de `8s` entre la caida de red y el envio del magic packet

Resultado:

- el nodo salio de red a los `5s`
- el magic packet se envio a los `13s`
- retorno por `ping`: `33s` despues del packet
- retorno por `SSH`: `33s` despues del packet
- health minimo operativo: `33s` despues del packet

Clasificacion actualizada:

- `WOL-from-poweroff-supported-with-delay`

### Recuperacion manual

- si fue necesaria entre el primer intento fallido y el reintento
- no fue necesaria despues del reintento exitoso ni despues de `poweroff`

### Estado final

- `management` siguio sano:
  - `ups.status: OL`
  - `battery.charge: 100`
  - `nut-server` `active`
  - `nut-monitor` `active`
- `ntfy-local` siguio sano
- `nas` regreso por `ping` y `SSH`
- `nut-monitor` en `nas` quedo `active`
- `md0` y `md1` quedaron en `[UU]`
- `/srv/media` y `/srv/docs` volvieron con `mergerfs`
- exports `NFS` siguieron visibles

### Lectura operativa

- `nas` no tiene un perfil uniforme de `WOL`
- con `eno1`, ambas rutas llegaron a funcionar, aunque lentas y con variabilidad
- con `enp3s0`, `suspend` funciona muy bien y `poweroff` tambien puede funcionar si se deja una pequena espera antes del primer magic packet
- esto fortalece la hipotesis de dependencia por NIC / firmware / power state, mas que un bug generico del driver en Linux

### Recomendacion

- `management` despues del comportamiento mixto de `nas`: `no-go` por ahora
- `nas` no debe usarse como canary “rápido”
- cualquier siguiente trabajo sobre `nas` debe separar claramente:
  - `eno1`
  - `enp3s0`
  - `suspend`
  - `poweroff`
- para `enp3s0`, el runbook futuro debe contemplar unos segundos de espera antes del primer magic packet

---

## `04H.3` — Canary `x86_64` con `management`

### Resumen

Despues de validar `services`, `ai-gpu` y `nas`, `04H.3` continuo con `management` como ultimo canary `x86_64`.

Se uso `orangepi5-ultra` como emisor real del magic packet para aproximar mejor el modelo futuro de recuperacion desde un `SBC` que permanece prendido.

### Prechecks

En `management`:

- `ups.status: OL`
- `battery.charge: 100`
- `input.voltage: 120.7`
- `nut-server`: `active`
- `nut-monitor`: `active`
- interfaz: `eno1`
- `MAC`: `C4:65:16:AC:AB:37`
- driver: `e1000e`
- `Supports Wake-on: pumbg`
- `Wake-on: g`

En `orangepi5-ultra`:

- `wakeonlan` instalado
- `ntfy-local` activo
- conectividad LAN sana

### Comandos usados

`suspend` programado:

```bash
sudo bash -lc 'nohup sh -c "sleep 2; systemctl suspend" >/tmp/wol-management-suspend.log 2>&1 &'
```

`poweroff` programado:

```bash
sudo bash -lc 'nohup sh -c "sleep 2; systemctl poweroff" >/tmp/wol-management-poweroff.log 2>&1 &'
```

Magic packet desde `orangepi5-ultra`:

```bash
wakeonlan -i 192.168.0.255 c4:65:16:ac:ab:37
```

### Resultado `suspend -> magic packet -> resume`

- el nodo salio de red a los `5s`
- se envio un unico magic packet a los `5s`
- retorno por `ping`: `13s` despues del packet
- retorno por `SSH`: `14s` despues del packet
- health minimo operativo: `14s` despues del packet

Clasificacion:

- `WOL-from-suspend-supported`

### Resultado `poweroff -> magic packet -> boot`

- el nodo salio de red a los `4s`
- se dejo una espera extra antes del packet
- el magic packet se envio a los `12s`
- retorno por `ping`: `23s` despues del packet
- retorno por `SSH`: `24s` despues del packet
- health minimo operativo: `27s` despues del packet

Clasificacion:

- `WOL-from-poweroff-supported-with-delay`

### Recuperacion manual

- no fue necesaria

### Estado final

- `management` regreso por `ping` y `SSH`
- `nut-server` y `nut-monitor` quedaron `active`
- `upsc linkedpro@localhost` siguio respondiendo
- `ntfy-local` siguio accesible desde `management`
- el control plane local quedo operativo despues de ambas rutas

### Lectura operativa

- `management` queda validado para `WOL` real en ambos caminos
- la cadena `orangepi5-ultra -> wakeonlan -> management` queda probada con exito
- para `poweroff`, conviene conservar una pequena espera antes del primer packet

### Recomendacion

- `04H.3` puede cerrarse como suficiente para `x86_64`
- ya no hace falta seguir expandiendo pruebas de wake en esta fase

## Cierre `04H`

### Matriz final WOL

| Nodo | Arq | Interfaz | MAC | `suspend -> WOL` | `poweroff -> WOL` | Emisor usado | Tiempo a ping | Tiempo a SSH | Estado operativo minimo | Caveats | Clasificacion final |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `orangepi5-ultra` | `aarch64` | `enP3p49s0` | `C0:74:2B:FC:59:86` | no probado | no probado | n/a | n/a | n/a | n/a | usar como emisor, no como target | `wake-emitter-supported, not wake target` |
| `orangepi5-max` | `aarch64` | `enP3p49s0` | `C0:74:2B:FD:71:43` | no probado | no probado | n/a | n/a | n/a | n/a | SBC ARM | `always-on/manual-recovery/no-WOL-automation` |
| `orangepi5-a` | `aarch64` | `end1` | `C6:CC:84:3D:E2:67` | no probado | no probado | n/a | n/a | n/a | n/a | SBC ARM | `always-on/manual-recovery/no-WOL-automation` |
| `orangepi5-b` | `aarch64` | `end1` | `C6:87:B3:C0:55:95` | no aplica | fallo | `management` | none | none | none | requirio recuperacion manual | `always-on/manual-recovery/no-WOL-automation` |
| `services` | `x86_64` | `enp2s0` | `58:47:CA:79:08:69` | pass | pass | `management` | `10s / 16s` | `11s / 159s` | `SSH + nut-monitor` | `systemd-networkd-wait-online` retrasa readiness tras cold boot | `WOL-supported with boot-readiness caveat` |
| `ai-gpu` | `x86_64` | `enp4s0` | `58:47:CA:7F:84:B5` | pass | pass | `management` | `11s / 20s` | `11s / 21s` | `SSH + nut-monitor + /storage + GPU por driver` | `nvidia-smi` ausente | `WOL-supported` |
| `nas` | `x86_64` | `enp3s0` preferido | `C8:FF:BF:05:F4:47` | pass con retry | pass con delay | `management` | `37s / 33s` | `37s / 33s` | `SSH + nut-monitor + md + mergerfs + NFS exports` | depende del NIC; `enp3s0` preferido; esperar unos segundos antes del packet en `poweroff` | `WOL-supported with NIC/timing caveat` |
| `management` | `x86_64` | `eno1` | `C4:65:16:AC:AB:37` | pass | pass con delay | `orangepi5-ultra` | `13s / 23s` | `14s / 24s` | `SSH + nut-server/nut-monitor + upsc + ntfy-local` | control plane; mejor emisor futuro desde `SBC` | `WOL-supported/control-plane-recoverable` |

### Politica final WOL

- No usar `WOL` en bateria.
- Prohibido despertar `nas` y `ai-gpu` en bateria.
- `WOL` automatico sigue prohibido por ahora.
- `WOL` manual solo esta permitido si `NUT` reporta `OL`.
- Todo automatismo futuro debe esperar healthchecks por capas:
  - `ping`
  - `SSH`
  - `hostname`
  - servicios base
  - health especifico de app o rol
- Las `SBC ARM` permanecen encendidas mientras el `UPS` lo permita; si se apagan, la recuperacion es manual.

### Estado final

- `04H` queda `closed`
- `services`, `ai-gpu`, `nas` y `management` ya tienen clasificacion operativa de `WOL`
- las `SBC ARM` quedan fuera de cualquier estrategia de `WOL` automatizado 24/7
