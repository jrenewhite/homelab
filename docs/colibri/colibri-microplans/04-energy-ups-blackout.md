# Microplan 04 — Energia, UPS y Blackout

## Proposito

Cerrar primero la verdad factual de energia, UPS, `WOL` y topologia electrica de `Colibri` antes de configurar `NUT`, automatismos de apagado o politicas de wake.

## Estado actual observado

- `management` recibe energia solo de la `Epcom EPU1500LCD`
- `management` esta conectado por USB a dos UPS distintas:
  - `LinkedPro LP1KRT` `1000VA/900W` online, visible en Linux y candidata para `NUT`
  - `Epcom EPU1500LCD` linea interactiva, no visible en Linux por protocolo privativo
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
- `management` no comparte rama electrica con la `LinkedPro`; por eso su liveness local no representa la salud electrica de esa UPS
- `services` no sera `NUT master` en esta fase
- `nas` y `ai-gpu` no pueden despertarse si el sistema esta en bateria
- `orangepi5-ultra` no puede recibir rol activo mas alla de cliente/auxiliar mientras siga sin UPS local visible
- `Microplan 04A` termina con inventario, runbook y brechas; no con configuracion
- no se usaran canaries activos ni heartbeats entre nodos para inferir el estado de `LinkedPro`

## Interfaces

### Roles `NUT` propuestos

- `management`: `master` candidato, condicionado a seguir viendo la `LinkedPro LP1KRT` compatible; observador de una UPS distinta a su propia alimentacion
- `services`: `client` propuesto; nunca `master` en esta fase
- `nas`: `client` propuesto o nodo gestionado externamente
- `ai-gpu`: `client` propuesto o nodo gestionado externamente
- `orangepi5-ultra`: `client` propuesto o nodo auxiliar de observacion; no `master`

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
