# Goal Execution — Microplan 01 Red y Direccionamiento

Ejecución real de cierre de `Microplan 01` para `Colibrí`.

## Resultado ejecutivo

`Microplan 01` quedó cerrado en dos partes:

- `01A` core del homelab:
  - router sano en `192.168.0.1/24`
  - DHCP mantenido en el `ER707-M2`
  - core migrado a `.10-.17`
  - `ping` y `SSH` validados en los 8 nodos core
- `01B` clientes e IoT:
  - reservas no-core auditadas por grupos
  - sin tocar DNS
  - sin reinicios masivos
  - sin necesidad de reabrir riesgo de red

## Decisiones que se confirmaron

- DHCP permanece exclusivamente en el `ER707-M2`
- DNS queda fuera de esta ejecución
- las reservas DHCP son la fuente de verdad de direccionamiento
- el bloque core definitivo es:
  - `.10` `management`
  - `.11` `nas`
  - `.12` `services`
  - `.13` `ai-gpu`
  - `.14` `orangepi5-ultra`
  - `.15` `orangepi5-max`
  - `.16` `orangepi5-a`
  - `.17` `orangepi5-b`

## Ejecución real del core

Aunque el plan original contemplaba `renew/reboot` por tandas, la ejecución real encontró que los 8 nodos core ya habían convergido a sus IPs reservadas nuevas.

Validación lograda:

- `management` -> `192.168.0.10`
- `nas` -> `192.168.0.11`
- `services` -> `192.168.0.12`
- `ai-gpu` -> `192.168.0.13`
- `orangepi5-ultra` -> `192.168.0.14`
- `orangepi5-max` -> `192.168.0.15`
- `orangepi5-a` -> `192.168.0.16`
- `orangepi5-b` -> `192.168.0.17`

Cada uno quedó verificado por:

- `ping`
- `ARP/MAC` coherente
- `SSH` con la llave administrativa

No fue necesario reiniciar nodos core adicionales.

## Auditoría no-core

### Grupo 1 — Infra extendida

- `bd795m` `.18`
  - activo y validado
- `moto-one` `.19`
  - reserva presente
  - no respondió en esta auditoría
  - queda configurado, pendiente de observación
- `xvr-dahua` `.30`
  - activo y validado por `ping` + MAC
- `altenergy-ecu` `.31`
  - activo y validado por `ping` + MAC

### Grupo 2 — Red y periféricos

- `deco-*` `.32-.41`
  - reservas presentes
  - activos observados por `ping` y `ARP/MAC`
- `hp-officejet-pro-9020` `.42`
  - activo y validado por `ping` + MAC

Resultado:

- grupo validado

### Grupo 3 — Google Home/Nest

Activos y validados:

- `.50`
- `.51`
- `.53`
- `.54`
- `.55`
- `.56`
- `.57`
- `.58`

Pendiente de observación:

- `.52`

Resultado:

- grupo configurado y mayormente validado
- un dispositivo reservado no respondió en esta auditoría, pero no bloquea el cierre

### Grupo 4 — Wyze principales

Activos y validados por `ping` o `ARP/MAC` razonable:

- `.60`
- `.61`
- `.62`
- `.64`
- `.65`

Pendiente de observación:

- `.63`
- `.66`
- `.67`

Resultado:

- grupo configurado y parcialmente validado

### Grupo 5 — Wyze auxiliares

Activos y validados por `ping` o `ARP/MAC` razonable:

- `.70`
- `.71`
- `.72`
- `.73`
- `.74`
- `.75`
- `.76`
- `.77`

Resultado:

- grupo validado

### Grupo 6 — TP-Link / Govee

Activos y validados:

- `.80`
- `.81`
- `.82`
- `.83`
- `.84`
- `.86`
- `.87`

Pendiente de observación:

- `.85`

Resultado:

- grupo configurado y mayormente validado

## Clasificación final

### Cerrado y validado

- bloque core `.10-.17`
- `bd795m` `.18`
- `xvr` `.30`
- `altenergy-ecu` `.31`
- `deco-*` `.32-.41`
- `hp-officejet` `.42`
- Google activos `.50/.51/.53-.58`
- Wyze activos `.60/.61/.62/.64/.65/.70-.77`
- TP-Link/Govee activos `.80-.84/.86/.87`

### Cerrado por configuración, pendiente de observación

- `moto-one` `.19`
- Google `.52`
- Wyze `.63/.66/.67`
- Govee `.85`

### Abierto

- ninguno detectado en esta auditoría

## Estado del router al cierre

- LAN `192.168.0.1/24`
- DHCP dinámico `192.168.0.100-199`
- DHCP sigue en el router
- reservas core + no-core cargadas
- DNS no se tocó en esta ejecución
- no se observaron conflictos visibles entre reservas y pool dinámico

## Criterio de cierre

`Microplan 01` se considera cerrado porque:

- el bloque core ya opera en `.10-.17`
- las reservas no-core fueron auditadas
- no hay conflicto visible IP/MAC en los rangos auditados
- el router quedó como única fuente de verdad DHCP
- no queda trabajo de direccionamiento que bloquee `Microplan 05`

## Siguiente paso

El siguiente microplan operativo grande ya no es direccionamiento, sino:

- `Microplan 05 — DNS y Pi-hole`

Ese trabajo debe arrancar manteniendo:

- DHCP en el router
- `Pi-hole` solo como DNS
- `DNS2 = 1.1.1.1` como fallback de emergencia
