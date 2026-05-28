# Goal Execution 04D — NUT Event Policy, Observation Only

Fecha de ejecucion: `2026-05-28`  
Modo: `event policy + local logger only`

## Objetivo

Definir y dejar preparada la politica de eventos `NUT` sin acciones destructivas, manteniendo toda la fase en modo observacion.

## Restricciones respetadas

- no se habilito shutdown real
- no se ejecuto `upsmon -c fsd`
- no se probo blackout
- no se desconecto ninguna UPS
- no se enviaron magic packets
- no se hizo wake/sleep de nodos
- `SHUTDOWNCMD "/bin/true"` se mantuvo intacto
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

- `management`
- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

## Configs tocadas

Solo se tocaron `upsmon.conf` en los nodos con `upsmon`, y se agrego un helper local:

- `/etc/nut/upsmon.conf`
- `/usr/local/sbin/nut-notify-log.sh`

No se tocaron:

- `ups.conf`
- `upsd.conf`
- `upsd.users`
- `nut.conf`

## Logger local agregado

Se agrego en cada nodo:

- `/usr/local/sbin/nut-notify-log.sh`

Contenido funcional:

```sh
#!/bin/sh
MSG="$*"
/usr/bin/logger -t nut-event "host=$(hostname) role=<master|client> type=${NOTIFYTYPE:-unknown} ups=${UPSNAME:-unknown} msg=${MSG}"
exit 0
```

Lectura:

- solo registra localmente en syslog/journal
- no ejecuta shutdown
- no envia wake
- no apaga servicios

## Politica por evento

### `ONLINE` / `OL`

- registrar recuperacion local
- documentar retorno a operacion estable
- no despertar nodos automaticamente
- no reactivar jobs pesados de forma automatica todavia

### `ONBATT` / `OB`

- registrar evento
- congelar automatismos futuros pesados
- prohibir wake de `nas` y `ai-gpu`
- no apagar nada en esta fase

### `LOWBATT` / `LB`

- registrar evento
- documentar orden futuro de apagado
- mantener bloqueo de wake para `nas` y `ai-gpu`
- no apagar nada en esta fase

### `COMMBAD`

- registrar perdida de comunicacion
- congelar automatismos
- pasar a operacion manual
- no inferir nada sobre la `Epcom`

### `COMMOK`

- registrar recuperacion de comunicacion
- mantener politica conservadora
- no despertar nodos automaticamente

### `FSD`

- solo como evento futuro
- registrar si alguna vez apareciera
- no usarlo en esta fase
- no provocar `FSD` manualmente

## `NOTIFYFLAG` / `NOTIFYMSG`

Se agrego en todos los nodos con `upsmon`:

```ini
NOTIFYCMD "/usr/local/sbin/nut-notify-log.sh"
NOTIFYFLAG ONLINE SYSLOG+EXEC
NOTIFYFLAG ONBATT SYSLOG+EXEC
NOTIFYFLAG LOWBATT SYSLOG+EXEC
NOTIFYFLAG COMMBAD SYSLOG+EXEC
NOTIFYFLAG COMMOK SYSLOG+EXEC
NOTIFYFLAG FSD SYSLOG+EXEC
NOTIFYMSG ONLINE "NUT event: UPS %s online; no auto-wake"
NOTIFYMSG ONBATT "NUT event: UPS %s on battery; freeze heavy jobs; no wake nas/ai-gpu"
NOTIFYMSG LOWBATT "NUT event: UPS %s low battery; future ordered shutdown only"
NOTIFYMSG COMMBAD "NUT event: UPS %s comm lost; freeze automations; manual operation"
NOTIFYMSG COMMOK "NUT event: UPS %s comm restored; record recovery; no auto-wake"
NOTIFYMSG FSD "NUT event: UPS %s future forced shutdown state; disabled in this phase"
```

## Estado final de servicios

### `management`

- `nut-server`: `active`
- `nut-monitor`: `active`

### Clientes

- `services` `nut-monitor`: `active`
- `nas` `nut-monitor`: `active`
- `ai-gpu` `nut-monitor`: `active`
- `orangepi5-ultra` `nut-monitor`: `active`

## `upsc` observado al cierre

### `management`

```text
battery.charge: 100
battery.runtime: 6060
input.voltage: 117.1
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

### Clientes

`services`, `nas`, `ai-gpu` y `orangepi5-ultra` devolvieron lectura consistente:

```text
battery.charge: 100
input.voltage: 117.1
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

## Anomalias

- al principio hubo un intento fallido de insertar el `NOTIFYCMD` por un problema de quoting del wrapper, no por `NUT`
- se corrigio enviando script remoto literal y `upsmon` quedo estable en todos
- no se generaron eventos reales durante esta fase, asi que no hubo validacion por ocurrencia real; solo por sintaxis, carga del servicio y politica documentada

## Estado de Epcom

- sigue manual/no instrumentada
- no participa en la politica automatizada
- no se toma ninguna decision de wake/shutdown basandose en su estado

## Conclusion

`04D` queda cerrado como politica de eventos no destructiva:

- eventos definidos
- mensajes definidos
- logger local agregado
- `upsmon` sano
- sin shutdown real
- sin wake automatico

## Recomendacion

Go/no-go para `04E`:

- `go` para `04E` como prueba controlada de notificaciones/eventos no destructivos
