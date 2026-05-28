# Goal Execution 04C — NUT Remote Clients Observation Mode

Fecha de ejecucion: `2026-05-28`  
Modo: `remote observation only`

## Objetivo

Permitir que clientes remotos consulten el estado de `linkedpro` en `management`, sin shutdown real, sin automatismos de energia y sin involucrar a la `Epcom`.

## Restricciones respetadas

- no se configuraron apagados reales
- no se probo blackout
- no se enviaron magic packets
- no se desperto ni suspendio:
  - `nas`
  - `ai-gpu`
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

## Nodos tocados

- `management` `192.168.0.10`
- `services` `192.168.0.12`
- `nas` `192.168.0.11`
- `ai-gpu` `192.168.0.13`
- `orangepi5-ultra` `192.168.0.14`

## Cambios en `management`

### Backups

Backup adicional de `NUT` creado en:

- `/etc/nut/backups/20260528-055305`

### Configuracion remota

Se mantuvo la UPS local:

- `linkedpro`

Y se ajusto `upsd` para observacion remota LAN:

### `/etc/nut/upsd.conf`

Se agrego:

```ini
LISTEN 192.168.0.10 3493
```

Resultado final de escucha:

```text
127.0.0.1:3493
::1:3493
192.168.0.10:3493
```

Lectura:

- el puerto `3493` no quedo abierto globalmente
- quedo limitado a loopback y a la IP LAN del propio `management`

### Usuario remoto

Se creo usuario de monitoreo remoto:

- `monclient`

Permisos:

- `upsmon secondary`
- sin permisos de shutdown ni acciones administrativas

## Clientes configurados

Se configuraron en modo observacion:

- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

### Paquete

Todos quedaron con `nut-client` presente:

- `services` -> `2.8.4+really-2`
- `nas` -> `2.8.1-5`
- `ai-gpu` -> `2.8.4+really-2`
- `orangepi5-ultra` -> `2.8.1-5`

### Configuracion cliente

Cada cliente quedo con:

#### `/etc/nut/nut.conf`

```ini
MODE=netclient
```

#### `/etc/nut/upsmon.conf`

```ini
MONITOR linkedpro@192.168.0.10 1 monclient <redacted> secondary
MINSUPPLIES 1
SHUTDOWNCMD "/bin/true"
POWERDOWNFLAG /etc/killpower
```

Lectura:

- `SHUTDOWNCMD` sigue benigno
- no hay apagado real aunque `upsmon` vea eventos
- los clientes quedan listos solo para observacion remota

## Validacion

### `management`

Estado de servicios:

```text
nut-server  enabled active
nut-monitor enabled active
```

`upsc -l`:

```text
linkedpro
```

`upsc linkedpro@localhost`:

```text
battery.charge: 100
battery.runtime: 6060
input.voltage: 116.9
output.voltage: 119.7
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

### `services`

`upsc linkedpro@192.168.0.10`:

```text
battery.charge: 100
input.voltage: 117.0
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

Estado:

```text
nut-monitor enabled active
```

### `nas`

`upsc linkedpro@192.168.0.10`:

```text
battery.charge: 100
input.voltage: 116.9
output.voltage: 119.7
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

Estado:

```text
nut-monitor enabled active
```

### `ai-gpu`

`upsc linkedpro@192.168.0.10`:

```text
battery.charge: 100
input.voltage: 116.9
output.voltage: 119.7
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

Estado:

```text
nut-monitor enabled active
```

### `orangepi5-ultra`

`upsc linkedpro@192.168.0.10`:

```text
battery.charge: 100
input.voltage: 116.9
output.voltage: 119.7
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

Estado:

```text
nut-monitor enabled active
```

## Anomalias

- el primer intento con `powervalue 0` y `MINSUPPLIES 0` no fue aceptado de forma consistente por `upsmon`
- `services` y `ai-gpu` fallaron con:
  - `Fatal error: insufficient power configured!`
- se corrigio unificando todos los clientes a:
  - `MONITOR ... 1 ... secondary`
  - `MINSUPPLIES 1`
  - `SHUTDOWNCMD "/bin/true"`

## Estado de la Epcom

- la `Epcom EPU1500LCD` sigue fuera de esta configuracion
- no participa en `ups.conf`
- no participa en clientes remotos
- se mantiene como rama manual/no instrumentada

## Conclusion

`04C` queda cerrado en modo observacion:

- `management` exporta `linkedpro`
- 4 clientes remotos ya leen estado util
- no hay shutdown real
- `3493` quedo limitado a loopback + LAN local de `management`

## Recomendacion

Go/no-go para `04D`:

- `go` para `04D` como politica de eventos sin shutdown real

Condiciones:

- mantener `Epcom` fuera de telemetria automatica
- mantener `SHUTDOWNCMD "/bin/true"` hasta cerrar la politica
- no introducir wake/sleep automatico todavia
