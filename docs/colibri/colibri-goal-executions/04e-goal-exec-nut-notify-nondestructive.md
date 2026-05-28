# Goal Execution 04E — Controlled NUT Notifications, Non-Destructive

Fecha de ejecucion: `2026-05-28`  
Modo: `synthetic notify validation`

## Objetivo

Validar la cadena completa de notificacion no destructiva:

`upsmon -> NOTIFYCMD -> logger -> journal/syslog`

sin provocar eventos reales de bateria ni cambiar `SHUTDOWNCMD`.

## Restricciones respetadas

- no se probo blackout fisico
- no se desconecto la UPS
- no se uso `upsmon -c fsd`
- no se genero `FSD` real
- no se enviaron magic packets
- no se hizo wake/sleep
- no se apagaron servicios ni nodos
- no se toco:
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

## Nodos validados

- `management`
- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

## Comandos ejecutados

```bash
systemctl status nut-server nut-monitor
upsc linkedpro@localhost
upsc linkedpro@192.168.0.10
journalctl -t nut-event -n 8 --no-pager
NOTIFYTYPE=ONBATT  UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic on battery validation"
NOTIFYTYPE=LOWBATT UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic low battery validation"
NOTIFYTYPE=COMMOK  UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic comm restored validation"
NOTIFYTYPE=ONLINE  UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic online validation"
```

## Resultado de la cadena de notificacion

La cadena funciono correctamente en todos los nodos validados.

### `management`

Entradas generadas:

```text
host=management role=master type=ONBATT ups=linkedpro msg=synthetic on battery validation
host=management role=master type=LOWBATT ups=linkedpro msg=synthetic low battery validation
host=management role=master type=COMMOK ups=linkedpro msg=synthetic comm restored validation
host=management role=master type=ONLINE ups=linkedpro msg=synthetic online validation
```

### `services`

Entradas generadas:

```text
host=services role=client type=ONBATT ups=linkedpro msg=synthetic on battery validation
host=services role=client type=LOWBATT ups=linkedpro msg=synthetic low battery validation
host=services role=client type=COMMOK ups=linkedpro msg=synthetic comm restored validation
host=services role=client type=ONLINE ups=linkedpro msg=synthetic online validation
```

### `nas`

Entradas generadas:

```text
host=nas role=client type=ONBATT ups=linkedpro msg=synthetic on battery validation
host=nas role=client type=LOWBATT ups=linkedpro msg=synthetic low battery validation
host=nas role=client type=COMMOK ups=linkedpro msg=synthetic comm restored validation
host=nas role=client type=ONLINE ups=linkedpro msg=synthetic online validation
```

### `ai-gpu`

Entradas generadas:

```text
host=ai-gpu role=client type=ONBATT ups=linkedpro msg=synthetic on battery validation
host=ai-gpu role=client type=LOWBATT ups=linkedpro msg=synthetic low battery validation
host=ai-gpu role=client type=COMMOK ups=linkedpro msg=synthetic comm restored validation
host=ai-gpu role=client type=ONLINE ups=linkedpro msg=synthetic online validation
```

### `orangepi5-ultra`

Entradas generadas:

```text
host=orangepi5-ultra role=client type=ONBATT ups=linkedpro msg=synthetic on battery validation
host=orangepi5-ultra role=client type=LOWBATT ups=linkedpro msg=synthetic low battery validation
host=orangepi5-ultra role=client type=COMMOK ups=linkedpro msg=synthetic comm restored validation
host=orangepi5-ultra role=client type=ONLINE ups=linkedpro msg=synthetic online validation
```

## Estado final de `NUT`

### `management`

- `nut-server`: `active`
- `nut-monitor`: `active`

`upsc linkedpro@localhost`:

```text
battery.charge: 100
battery.runtime: 6060
input.voltage: 117.7
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

### Clientes

Todos siguen en observacion y `active`:

- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

Lectura remota consistente:

```text
battery.charge: 100
input.voltage: 117.7
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

## Anomalias

- no hubo eventos reales, asi que la validacion fue sintetica/manual
- eso es aceptable para esta fase porque el objetivo era validar la tuberia de notificacion, no el comportamiento electrico real
- `Init SSL without certificate database` sigue apareciendo en `upsc`, pero no afecto la lectura

## Configs tocadas

- ninguna configuracion adicional

Lectura:

- `04E` se cerro sin cambiar `SHUTDOWNCMD`
- no se modifico el script de logger en esta fase
- solo se invoco manualmente con entorno controlado

## Estado de Epcom

- se mantiene manual/no instrumentada
- no participa en esta validacion

## Conclusion

La cadena:

`upsmon -> NOTIFYCMD -> logger -> journal`

quedo validada en `management` y en los 4 clientes remotos, sin acciones destructivas.

## Recomendacion

Go/no-go para `04F`:

- `go` para integrar notificaciones externas o bot en modo observacion
