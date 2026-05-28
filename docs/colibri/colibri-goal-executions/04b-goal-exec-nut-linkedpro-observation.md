# Goal Execution 04B — NUT Observation Config for LinkedPro Only

Fecha de ejecucion: `2026-05-28`  
Modo: `local observation only`

## Objetivo

Configurar `NUT` en `management` para observar solo la `LinkedPro LP1KRT`, sin clientes remotos, sin acciones reales de shutdown y sin tocar la `Epcom`.

## Restricciones respetadas

- no se configuraron clientes `NUT` remotos
- no se configuraron acciones automaticas para:
  - `services`
  - `nas`
  - `ai-gpu`
- no se ejecuto:
  - blackout test
  - battery test
  - magic packets
  - wake/sleep de nodos
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

## Nodo tocado

- `management` `192.168.0.10`

## Backups

Se creo backup de configuracion previa en:

- `/etc/nut/backups/20260528-054319`

Archivos respaldados:

- `/etc/nut/nut.conf`
- `/etc/nut/ups.conf`
- `/etc/nut/upsd.conf`
- `/etc/nut/upsd.users`
- `/etc/nut/upsmon.conf`

## Configs modificadas

### `/etc/nut/nut.conf`

```ini
MODE=standalone
```

### `/etc/nut/ups.conf`

```ini
maxretry = 3

[linkedpro]
  driver = usbhid-ups
  port = auto
  vendorid = 0463
  productid = 0001
  desc = "LinkedPro LP1KRT observation-only"
  pollfreq = 30
```

### `/etc/nut/upsd.conf`

```ini
LISTEN 127.0.0.1 3493
LISTEN ::1 3493
```

### `/etc/nut/upsd.users`

Se creo usuario local de `upsmon` para observacion:

- `monuser`

Nota:

- la password quedo solo en el archivo del sistema; no se replica aqui

### `/etc/nut/upsmon.conf`

```ini
MONITOR linkedpro@localhost 1 monuser <redacted> primary
MINSUPPLIES 1
SHUTDOWNCMD "/bin/true"
POWERDOWNFLAG /etc/killpower
```

Lectura:

- `SHUTDOWNCMD` se dejo benigno para evitar accion destructiva durante esta fase
- esto permite validar el stack `NUT` sin introducir apagado real

## Servicios habilitados

- `nut-server.service` -> `enabled`, `active (running)`
- `nut-monitor.service` -> `enabled`, `active (running)`

## Validacion

### `systemctl status`

Resultado relevante:

```text
nut-server.service: active (running)
Connected to UPS [linkedpro]: usbhid-ups-linkedpro

nut-monitor.service: active (running)
UPS: linkedpro@localhost (primary) (power value 1)
```

### `upsc -l`

```text
linkedpro
```

### `upsc linkedpro@localhost`

Variables utiles observadas:

```text
battery.charge: 100
battery.charge.low: 10
battery.runtime: 6060
device.mfr: KSTAR
device.model: UPS HID
input.voltage: 116.3
output.voltage: 119.8
ups.mfr: KSTAR
ups.model: UPS HID
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

## Estado de la Epcom

La `Epcom EPU1500LCD`:

- no fue agregada a `ups.conf`
- no participa en esta configuracion `NUT`
- se mantiene como rama protegida no instrumentada
- sigue tratandose por `runbook manual`

## Rollback preparado

Si se necesitara volver atras:

1. restaurar los archivos desde `/etc/nut/backups/20260528-054319`
2. reiniciar o deshabilitar:
   - `nut-server`
   - `nut-monitor`
3. regresar a operacion manual

## Conclusion

`management` ya quedo configurado correctamente como nodo de observacion local para la `LinkedPro` solamente.

Se cumplio:

- una sola UPS configurada
- sin confusion con la `Epcom`
- variables utiles disponibles por `upsc`
- sin shutdown real

## Recomendacion

Go/no-go para `04C`:

- `go` para `04C` en modo observacion con clientes `NUT` remotos

Condiciones:

- seguir excluyendo la `Epcom` de la telemetria
- mantener `nas` y `ai-gpu` sin wake en bateria
- no introducir shutdown automatico todavia
