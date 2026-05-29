# Microplan 04 — Energia, UPS y Blackout

## Proposito

Cerrar primero la verdad factual de energia, UPS, `WOL` y topologia electrica de `Colibri` antes de configurar `NUT`, automatismos de apagado o politicas de wake.

## Estado actual observado

- `management` recibe energia solo de la `Epcom EPU1500LCD`
- `management` esta conectado por USB a dos UPS distintas:
  - `LinkedPro LP1KRT` `1000VA/900W` online, visible en Linux y candidata para `NUT`
  - `Epcom EPU1500LCD` linea interactiva, visible solo como HID generico `0001:0000` sin telemetria util para `NUT`
- `management` si ve una UPS compatible en Linux:
  - `lsusb`: `MGE UPS Systems UPS`
  - `upower -d`: `Eaton`, `ups_hiddev0`, `fully-charged`, `on-battery: no`
- `management` tiene `NUT` instalado, pero `nut-server` y `nut-monitor` estan fallando y no operan todavia
- `services` no ve UPS local por `lsusb`, `upower` ni `NUT`
- `nas` no ve UPS local por `lsusb`, `upower` ni `NUT`
- `ai-gpu` no ve UPS local por `lsusb`, `upower` ni `NUT`
- `orangepi5-ultra` no ve UPS local por `lsusb`, `upower` ni `NUT`
- `nas` soporta `WOL` y actualmente muestra `Wake-on: g`
- `nas` y `ai-gpu` no deben despertarse si el sistema esta en bateria, independientemente de su soporte tecnico de `WOL`

## Objetivo final

- `management` actua como `NUT master` solo si mantiene visibilidad real de la `LinkedPro LP1KRT`, aunque su alimentacion local venga de la `Epcom`
- `services`, `nas`, `ai-gpu` y `orangepi5-ultra` quedan clasificados como clientes observados o nodos gestionados externamente
- blackout no despierta nodos pesados ni storage frio durante eventos en bateria
- los cambios de energia pasan por `observation mode` antes de cualquier accion
- la UPS no instrumentada se trata por runbook manual, no por telemetria `NUT`

## Decisiones cerradas

- la fuente de verdad de esta fase es la observacion real en Linux, no la topologia asumida en docs viejos
- `management` es el unico candidato real a `NUT master` en el estado observado
- `management` observa por Linux solo la `LinkedPro LP1KRT`; la `Epcom EPU1500LCD` no es instrumentable desde Linux en esta fase
- `Microplan 04A.2` confirma que la `Epcom EPU1500LCD` si aparece por USB, pero no entrega variables utiles con `usbhid-ups`, `nutdrv_qx` ni `blazer_usb`
- `management` no comparte rama electrica con la `LinkedPro`; por eso su liveness local no representa la salud electrica de esa UPS
- `services` no sera `NUT master` en esta fase
- `nas` y `ai-gpu` no pueden despertarse si el sistema esta en bateria
- `orangepi5-ultra` no puede recibir rol activo mas alla de cliente/auxiliar mientras siga sin UPS local visible
- `Microplan 04A` termina con inventario, runbook y brechas; no con configuracion
- no se usaran canaries activos ni heartbeats entre nodos para inferir el estado de `LinkedPro`
- `Microplan 04A.1` cierra solo inventario `WOL` y readiness de tooling; no incluye pruebas reales de wake
- `Microplan 04B` configura `NUT` solo en `management` y solo para la `LinkedPro`, en modo observacion local
- `Microplan 04C` habilita clientes `NUT` remotos en modo observacion para `services`, `nas`, `ai-gpu` y `orangepi5-ultra`
- `Microplan 04D` define politica de eventos y notificaciones locales no destructivas, sin shutdown real
- `Microplan 04E` valida la cadena `upsmon -> NOTIFYCMD -> logger -> journal` con eventos sinteticos no destructivos
- `Microplan 04F` prepara notificacion externa `best-effort` compatible con `ntfy`, sin secretos en git y sin romper el logger local
- `Microplan 04F.1` despliega `ntfy` local en `orangepi5-ultra`, solo LAN, como receptor no destructivo de alertas
- `Microplan 04G` fija la politica futura de acciones ante eventos de energia, sin ejecucion real
- `Microplan 04H` fija politica diferenciada de prueba `WOL`:
  - `SBC ARM` (`Orange Pi 5`, `Raspberry Pi 5B/4B`) -> `poweroff-only`
  - `x86_64` -> se permite `suspend -> wake` y `poweroff -> wake`, siempre por nodo y con confirmacion explicita
- `Microplan 04H` ejecuto una prueba real de `WOL` con `orangepi5-b` como canary ARM bajo politica `poweroff-only`
- `Microplan 04H.2` ejecuto una prueba real de `WOL` con `services` como primer canary `x86_64`
- `Microplan 04H.3` valida `ai-gpu` como segundo canary `x86_64`, tambien con exito en `suspend` y `poweroff`
- `Microplan 04H.3` valida `nas` como tercer nodo `x86_64`, tras un primer intento fallido y un reintento exitoso
- `Microplan 04H.3` valida `management` como cuarto nodo `x86_64`, usando `orangepi5-ultra` como emisor real del magic packet
- `Microplan 04H` queda cerrado con una matriz final `WOL` por nodo y una politica final de uso manual solo en `OL`

## Interfaces

### Roles `NUT` propuestos

- `management`: `master` candidato, condicionado a seguir viendo la `LinkedPro LP1KRT` compatible; observador de una UPS distinta a su propia alimentacion
- `management`: ya configurado en `NUT` observation mode local para `linkedpro@localhost`
- `services`: `client` propuesto; nunca `master` en esta fase
- `nas`: `client` propuesto o nodo gestionado externamente
- `ai-gpu`: `client` propuesto o nodo gestionado externamente
- `orangepi5-ultra`: `client` propuesto o nodo auxiliar de observacion; no `master`
- `services`, `nas`, `ai-gpu` y `orangepi5-ultra`: ya configurados como `upsmon secondary` en modo observacion, con `SHUTDOWNCMD \"/bin/true\"`

### Topologia fisica por UPS

- `Epcom EPU1500LCD` no instrumentada:
  - `management`
  - `Starlink` actuated `v3`
  - `Omada ER707-M2`
  - `TP-Link TL-SG108`
  - `DS105G-M2`
  - ventiladores USB asociados, hasta `~5W`
- `LinkedPro LP1KRT` instrumentada en Linux:
  - `ai-gpu`
  - `nas`
  - `services`
  - `orangepi5-ultra`
  - `orangepi5-max`
  - `orangepi5-a`
  - `orangepi5-b`
  - ventiladores USB asociados, hasta `~5W`

Nota:

- `management` no esta alimentado por la `LinkedPro`, aunque la observe por USB
- la `Epcom` debe seguir tratandose como rama no instrumentada y de runbook manual
- la configuracion actual de `NUT` en `management` usa solo:
  - `driver = usbhid-ups`
  - `vendorid = 0463`
  - `productid = 0001`
  - `linkedpro@localhost`

### Inventario `WOL` read-only

Por nodo se debe registrar:

- hostname
- IP final
- interfaz principal y `MAC`
- si `ethtool` expone `Supports Wake-on` y `Wake-on`
- si `WOL` queda:
  - confirmado soportado
  - no expuesto por el driver/herramienta
  - no confirmado por falta de acceso
- accion permitida en energia normal
- accion prohibida en bateria

### Resultado `04A.1`

- los 8 nodos principales quedaron con `WOL` expuesto por `ethtool` y habilitado en runtime con `Wake-on: g`
- `management`, `services`, `nas` y `ai-gpu` quedan como nodos con soporte `WOL` confirmado
- `orangepi5-ultra`, `orangepi5-max`, `orangepi5-a` y `orangepi5-b` tambien exponen soporte `WOL`, aunque su politica de uso sigue siendo conservadora
- el cambio aplicado en esta fase es solo runtime; la persistencia despues de reboot o power cycle sigue pendiente de verificacion explicita
- `wakeonlan` queda instalado solo en `management` como tooling futuro minimo
- cualquier fase posterior de prueba real debe:
  - ocurrir en energia normal
  - excluir `nas` y `ai-gpu` cuando el sistema este en bateria
  - decidir primero la persistencia del OS para no depender solo del estado runtime actual

### Resultado `04H`

- canary elegido: `orangepi5-b`
- prechecks cumplidos antes del intento:
  - `linkedpro` en `ups.status: OL`
  - `battery.charge` disponible
  - `ntfy-local` sano en `http://192.168.0.14:8080/v1/health`
  - `WOL` expuesto en `end1` con `Supports Wake-on: ug` y `Wake-on: g`
- politica ARM aplicada:
  - `suspend` deshabilitado se documenta como esperado y **no** se considera bloqueo
  - la unica prueba relevante en `SBC ARM` es `poweroff -> magic packet -> boot`
- ejecucion real observada:
  - `orangepi5-b` apago correctamente y salio de red
  - se envio un unico magic packet desde `management`
  - el nodo no volvio por `ping` ni `SSH` dentro de la ventana de observacion
- clasificacion del resultado:
  - `WOL-from-poweroff-failed-manual-recovery`
- implicaciones:
  - no se hizo segundo intento
  - no se probo otro nodo
  - cualquier siguiente prueba debe esperar recuperacion manual del canary actual

### Resultado `04H.2`

- canary elegido: `services`
- interfaz principal: `enp2s0`
- `MAC`: `58:47:CA:79:08:69`
- driver: `r8169`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- prechecks cumplidos:
  - `linkedpro` en `ups.status: OL`
  - `battery.charge` disponible
  - `nut-server` y `nut-monitor` sanos en `management`
  - `ntfy-local` sano
  - `services` sin contenedores activos en la ventana de prueba
- resultado `suspend -> magic packet -> resume`:
  - `ping` de regreso a los `10s`
  - `SSH` de regreso a los `11s`
- resultado `poweroff -> magic packet -> boot`:
  - `ping` de regreso a los `16s`
  - `SSH` de regreso a los `159s`
- clasificacion del resultado:
  - `WOL-from-suspend-supported`
  - `WOL-from-poweroff-supported`
- implicaciones:
  - el primer canary `x86_64` valida ambos caminos en energia normal
  - el retorno desde `poweroff` puede ser sustancialmente mas lento para `SSH` que para `ping`
  - cualquier fase posterior con `nas` o `ai-gpu` debe seguir siendo una prueba individual, con ventana controlada y recuperacion manual disponible

### Resultado `04H.3`

- nodo probado: `ai-gpu`
- interfaz principal: `enp4s0`
- `MAC`: `58:47:CA:7F:84:B5`
- driver: `r8169`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- prechecks cumplidos:
  - `linkedpro` en `ups.status: OL`
  - `battery.charge` disponible
  - `nut-server` y `nut-monitor` sanos en `management`
  - `ntfy-local` sano
  - `ai-gpu` con `nut-monitor` activo
  - `/storage` montado
  - GPU NVIDIA visible por `lspci` y modulos `nvidia*` cargados
- resultado `suspend -> magic packet -> resume`:
  - `ping` de regreso a los `11s`
  - `SSH` de regreso a los `11s`
  - health minimo de regreso a los `11s`
- resultado `poweroff -> magic packet -> boot`:
  - `ping` de regreso a los `20s`
  - `SSH` de regreso a los `21s`
  - health minimo de regreso a los `21s`
- clasificacion del resultado:
  - `WOL-from-suspend-supported`
  - `WOL-from-poweroff-supported`
- implicaciones:
  - `ai-gpu` queda validado como nodo `x86_64` apto para wake controlado en `AC`
  - el health minimo no depende de `nvidia-smi`; se valido con `SSH`, `nut-monitor`, `/storage`, `lspci` y modulos `nvidia`
  - el siguiente candidato natural sigue siendo `nas`, pero debe probarse en ventana separada y con reconfirmacion explicita

### Resultado inicial `04H.3` en `nas` sobre `eno1`

- nodo probado: `nas`
- interfaz principal: `eno1`
- `MAC`: `C8:FF:BF:05:F4:46`
- driver: `igc`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- prechecks cumplidos:
  - `linkedpro` en `ups.status: OL`
  - `battery.charge` disponible
  - `nut-server` y `nut-monitor` sanos en `management`
  - `ntfy-local` sano
  - `md0` y `md1` en estado `[UU]`
  - `/srv/media` y `/srv/docs` montados por `mergerfs`
  - exports `NFS` visibles
- primer intento `suspend -> magic packet -> resume`:
  - fallo
  - el nodo no regreso dentro de la ventana de observacion
- reintento `suspend -> magic packet -> resume`:
  - `ping` de regreso a los `37s`
  - `SSH` de regreso a los `37s`
  - health minimo de regreso a los `37s`
- resultado `poweroff -> magic packet -> boot`:
  - usando `eno1`: `ping`, `SSH` y health minimo de regreso a los `95s`
  - usando `enp3s0` en prueba inicial: no regreso por `ping` ni `SSH` dentro de una ventana razonable
  - usando `enp3s0` en prueba estricta con espera extra antes del packet: `ping`, `SSH` y health minimo de regreso a los `33s`
- clasificacion del resultado:
  - `WOL-from-suspend-supported-with-retry`
  - `WOL-from-poweroff-supported` en `eno1`
  - `WOL-from-poweroff-supported-with-delay` en `enp3s0`
- implicaciones:
  - `nas` queda parcialmente validado, pero con fuerte dependencia del NIC
  - cualquier fase futura sobre `nas` debe asumir ventanas mas generosas
  - para `enp3s0`, conviene dejar unos segundos extra entre `poweroff` y el envio del primer magic packet
  - `management` solo debe probarse con reconfirmacion explicita del usuario

### Resultado `04H.3` en `management`

- nodo probado: `management`
- interfaz principal: `eno1`
- `MAC`: `C4:65:16:AC:AB:37`
- driver: `e1000e`
- `Supports Wake-on: pumbg`
- `Wake-on: g`
- emisor del magic packet:
  - `orangepi5-ultra`
  - `wakeonlan` instalado localmente para esta prueba
- prechecks cumplidos:
  - `linkedpro` en `ups.status: OL`
  - `battery.charge` disponible
  - `nut-server` y `nut-monitor` sanos en `management`
  - `ntfy-local` sano
- resultado `suspend -> magic packet -> resume`:
  - `ping` de regreso a los `13s`
  - `SSH` de regreso a los `14s`
  - health minimo de regreso a los `14s`
- resultado `poweroff -> magic packet -> boot`:
  - se dejo una espera extra antes del packet
  - `ping` de regreso a los `23s`
  - `SSH` de regreso a los `24s`
  - health minimo de regreso a los `27s`
- clasificacion del resultado:
  - `WOL-from-suspend-supported`
  - `WOL-from-poweroff-supported-with-delay`
- implicaciones:
  - el control plane local puede recuperarse desde un `SBC` siempre encendido
  - la cadena `ultra -> wakeonlan -> management` queda validada en `AC`

### Matriz final `WOL`

| Nodo | Arquitectura | Interfaz | MAC | `suspend -> WOL` | `poweroff -> WOL` | Emisor usado | Tiempo a ping | Tiempo a SSH | Estado operativo mínimo | Caveats | Clasificación final |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `orangepi5-b` | `aarch64` | `end1` | `C6:87:B3:C0:55:95` | n/a | fallo | `management` | none | none | none | `SBC ARM`; recuperación manual | `always-on/manual-recovery/no-WOL-automation` |
| `orangepi5-a` | `aarch64` | `end1` | `C6:CC:84:3D:E2:67` | no probado | no probado | n/a | n/a | n/a | n/a | `SBC ARM` | `always-on/manual-recovery/no-WOL-automation` |
| `orangepi5-max` | `aarch64` | `enP3p49s0` | `C0:74:2B:FD:71:43` | no probado | no probado | n/a | n/a | n/a | n/a | `SBC ARM` | `always-on/manual-recovery/no-WOL-automation` |
| `orangepi5-ultra` | `aarch64` | `enP3p49s0` | `C0:74:2B:FC:59:86` | no probado | no probado | n/a | n/a | n/a | n/a | emisor validado de `wakeonlan`; no target recomendado | `wake-emitter-supported` |
| `services` | `x86_64` | `enp2s0` | `58:47:CA:79:08:69` | pass | pass | `management` | `10s / 16s` | `11s / 159s` | `SSH + nut-monitor` | boot/readiness retrasado por `systemd-networkd-wait-online` | `WOL-supported with boot-readiness caveat` |
| `ai-gpu` | `x86_64` | `enp4s0` | `58:47:CA:7F:84:B5` | pass | pass | `management` | `11s / 20s` | `11s / 21s` | `SSH + nut-monitor + /storage + GPU por driver` | `nvidia-smi` ausente | `WOL-supported` |
| `nas` | `x86_64` | `enp3s0` preferido | `C8:FF:BF:05:F4:47` | pass con retry | pass con delay | `management` | `37s / 33s` | `37s / 33s` | `SSH + nut-monitor + md + mergerfs + exports NFS` | fuerte caveat de NIC/timing | `WOL-supported with NIC/timing caveat` |
| `management` | `x86_64` | `eno1` | `C4:65:16:AC:AB:37` | pass | pass con delay | `orangepi5-ultra` | `13s / 23s` | `14s / 24s` | `SSH + nut-server/nut-monitor + upsc + ntfy-local` | nodo de control plane | `WOL-supported/control-plane-recoverable` |

### Política final

- no usar `WOL` en batería
- prohibido despertar `nas` y `ai-gpu` en batería
- `WOL` automático sigue prohibido por ahora
- `WOL` manual permitido solo si `NUT` reporta `OL`
- cualquier automatismo futuro debe esperar health checks por capas:
  - `ping`
  - `SSH`
  - `hostname`
  - servicios base
  - health específico de la app o rol
- las `SBC ARM` deben permanecer encendidas mientras el `UPS` lo permita; si se apagan, la recuperación es manual

### Cierre de `04H`

- `04H` queda `closed`
- el bloque `x86_64` ya quedó suficientemente caracterizado
- el siguiente trabajo recomendado dentro de `Microplan 04` ya no es seguir probando wake, sino convertir esta matriz en política operativa y guardrails para acciones futuras

## `04I` — Guardrails operativos y runbook manual de energia

`04I` cierra `Microplan 04` como fase de observacion y recuperacion manual:

- `NUT` sigue en observacion para `LinkedPro`
- `Epcom` sigue como rama manual/no instrumentada
- `ntfy-local` queda como receptor local de alertas no destructivas
- puerto actual de `ntfy-local` tras `06A.1`:
  - `http://192.168.0.14:8300`
- `WOL` manual queda permitido solo en `OL` y solo para nodos ya validados
- `WOL` automatico y `shutdown` automatico siguen prohibidos

Resultado esperado de `04I`:

- runbook manual consolidado por evento:
  - `ONLINE/OL`
  - `ONBATT/OB`
  - `LOWBATT/LB`
  - `COMMBAD/COMMOK`
- runbook manual por nodo:
  - `management`
  - `services`
  - `nas`
  - `ai-gpu`
  - `SBC ARM`
- guardrails finales de energia y recuperacion
- criterio explicito para declarar `Microplan 04` como `observation/manual-recovery ready`

Guardrails obligatorios al cierre:

- `WOL` manual solo si `NUT` reporta `OL`
- prohibido despertar `nas` y `ai-gpu` en bateria
- `ping` no implica readiness
- toda recuperacion debe validar:
  - `ping`
  - `SSH`
  - `hostname`
  - servicios base
  - health especifico del rol
- `Epcom` requiere verificacion manual
- `SBC ARM` permanecen encendidas mientras el `UPS` lo permita; si se apagan, la recuperacion es manual

## Flujos

### Normal

- utility estable y UPS online
- sin acciones automaticas
- solo registrar:
  - nodos arriba
  - nodos que ven UPS local
  - que cargas dependen de la `LinkedPro` y cuales de la `Epcom`
  - servicios que dependen de `nas`

### On Battery

- registrar el evento
- confirmar que `management` sigue viendo la `LinkedPro`
- asumir que el estado de la `Epcom` no instrumentada requiere verificacion manual
- no usar canaries activos ni heartbeats para inferir el estado de la `LinkedPro`
- `04B` ya deja a `management` observando la `LinkedPro` con `ups.status`, `battery.charge`, `battery.runtime`, `input.voltage` y `output.voltage`
- `04C` ya deja a los clientes remotos leyendo `ups.status`, `battery.charge`, `input.voltage` y `output.voltage` desde `linkedpro@192.168.0.10`
- `04D` ya deja `NOTIFYFLAG`, `NOTIFYMSG` y `NOTIFYCMD` locales para `ONLINE`, `ONBATT`, `LOWBATT`, `COMMBAD`, `COMMOK` y `FSD`, con solo `logger`
- `04E` ya confirma que esas notificaciones llegan al journal local con `nut-event` en `management` y clientes remotos
- `04F` ya deja el wrapper listo para publicar a `ntfy` si existe `/opt/colibri-secrets/ntfy.env`; sin ese archivo, opera como `no-op` externo y mantiene journal local
- `04F.1` ya crea `ntfy.env` fuera de git y confirma recepcion local en `ntfy` para eventos sinteticos
- `04G` ya separa de forma explicita:
  - accion actual
  - notificacion actual
  - accion futura permitida
  - accion futura prohibida
  - precondiciones y rollback

### Politica futura de acciones

- `ONLINE` / `OL`
  - hoy: registrar recuperacion
  - futuro permitido: reabrir operacion y eventualmente reactivar cargas ligeras con gating
  - prohibido: auto-wake de `nas` o `ai-gpu`
- `ONBATT` / `OB`
  - hoy: registrar y congelar automatismos pesados
  - futuro permitido: preparar decision manual y congelar cargas no criticas
  - prohibido: wake de `nas` y `ai-gpu`; shutdown automatico
- `LOWBATT` / `LB`
  - hoy: registrar alerta critica
  - futuro permitido: seguir un orden de apagado ya aprobado
  - prohibido: apagado automatico antes de validar runbook y rollback
- `COMMBAD`
  - hoy: operar manualmente
  - futuro permitido: congelar automatismos y revisar fisicamente la rama
  - prohibido: inferir automaticamente el estado de la `Epcom`
- `COMMOK`
  - hoy: registrar recuperacion
  - futuro permitido: volver a observacion normal
  - prohibido: auto-wake o reactivacion pesada por defecto
- `FSD`
  - solo futuro, no usado en esta etapa

### Orden futuro de apagado, solo documental

1. `ai-gpu`
2. `nas`
3. `services`
4. `Orange Pi` auxiliares si aplica
5. `management` al final si aplica

### Bloqueos antes de shutdown real

- backup/restore probado
- servicios criticos clasificados
- `WOL` probado en AC
- runbook manual
- ventana controlada
- rollback

### Deuda tecnica controlada de `ntfy`

- `ntfy-local` en `orangepi5-ultra` se acepta como despliegue funcional inicial para desbloquear alertas locales de `NUT`
- en esta fase se tolera como contenedor directo/manual, porque el objetivo es habilitar observabilidad energetica sin esperar toda la gobernanza de stacks
- esto no debe convertirse en el patron de operacion permanente
- antes de escalar servicios, `ntfy` debe migrarse a un stack `Docker Compose` versionado
- los secretos deben seguir fuera de git, por ejemplo en `/opt/colibri-secrets`
- la fuente de verdad de stacks debe ser el repo
- `Portainer` o `Dockge` pueden servir como herramientas de operacion/visibilidad, preferentemente desde `management`, pero no como fuente primaria de configuracion
- `orangepi5-ultra` y los demas nodos deben seguir siendo operables en modo `headless` con stacks versionados
- esta deuda debe cerrarse en `Microplan 07`, `Microplan 08`, `Microplan 11` o en una subfase explicita de `Docker stack governance`
- congelar cualquier automatismo futuro no validado
- confirmar explicitamente que `nas` y `ai-gpu` no deben despertarse
- no apagar, dormir ni despertar nada en `04A`

### Low Battery

- registrar el umbral observado o esperado
- documentar el orden propuesto de apagado para `04B/04C`, sin ejecutarlo
- priorizar permanencia de control plane y telemetria mientras sea seguro

### Recovery

- registrar retorno de utility
- documentar que nodos podrian volver primero en fases futuras
- recordar que la `Epcom` no aportara telemetria automatica para validar recovery
- prohibir wake automatico en `04A`

### Comm Lost

- distinguir entre:
  - perdida de comunicacion con la UPS
  - perdida de `SSH` a un nodo
  - perdida de servicio `NUT`
- decision por defecto:
  - congelar automatismos
  - operar manualmente
  - no promover configuracion adicional hasta cerrar la brecha

## Aceptacion

- existe una tabla factual de UPS detectadas por nodo
- existe la topologia fisica por UPS, incluyendo una UPS instrumentada y una no instrumentada
- queda claro que `management` observa la `LinkedPro` pero se alimenta de la `Epcom`
- existe una matriz `WOL` read-only por nodo critico
- existe una matriz `WOL` completa para los 8 nodos principales
- `management` queda clasificado correctamente como unico `NUT master` candidato observado
- `services` queda explicitamente fuera del rol `master`
- `nas` y `ai-gpu` quedan explicitamente marcados como no-despertables en bateria
- existe runbook exacto por evento de energia
- quedan registradas las brechas que bloquean `04B`

## Prechecks minimos

- `ping` y `SSH` a `management`, `services`, `nas` y `ai-gpu`
- confirmar que `orangepi5-ultra` sigue visible por `SSH`, aunque no vea UPS local
- observacion `read-only` de:
  - `lsusb`
  - `upower -d`
  - `systemctl status` de `NUT`
  - `upsc -l` si aplica
  - `dmesg` filtrado por `ups|usb|hid|eaton|mge|apc`
- ninguna edicion de `nut.conf`, `ups.conf`, `upsd.users` o `upsmon.conf`

## Rollback

- no configurar nada nuevo
- no reiniciar servicios `NUT`
- si la observacion genera confusion o perdida de acceso, detenerse y volver a operacion manual

## Dependencias previas

- `Microplan 01`, `02` y `03` cerrados
- conectividad base estable
- topologia fisica de UPS identificable o, si no lo es, brecha documentada
- claro que `NUT` solo podra observar la `LinkedPro LP1KRT`

## Fuera de fase

- configurar `NUT`
- habilitar `nut-server`, `nut-client` o `nut-monitor`
- probar shutdown
- probar wake real
- automatizar blackout
- wake/sleep de `nas` o `ai-gpu`
