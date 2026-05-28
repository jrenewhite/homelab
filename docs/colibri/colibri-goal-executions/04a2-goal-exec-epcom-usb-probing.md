# Goal Execution 04A.2 — Epcom EPU1500LCD USB Protocol Probing

Fecha de ejecucion: `2026-05-27`  
Modo: `usb inventory + foreground NUT probing`

## Objetivo

Determinar si la `Epcom EPU1500LCD` puede ser monitoreada por Linux/NUT desde `management` usando probing controlado, sin tocar configuracion persistente ni reiniciar servicios.

## Restricciones respetadas

- no se editaron:
  - `nut.conf`
  - `ups.conf`
  - `upsd.users`
  - `upsmon.conf`
- no se habilitaron ni reiniciaron servicios `NUT`
- no se ejecuto:
  - `shutdown`
  - battery test
  - load test
- no se tocaron:
  - DNS
  - router
  - `Pi-hole`
  - `Caddy`
  - `cloudflared`
  - `Tailscale`
  - `SSO`
  - `NFS`
  - apps productivas

## Nodo tocado

- `management` `192.168.0.10`

## Comandos ejecutados

```bash
lsusb
lsusb -v -d 0463:0001
lsusb -v -d 0001:0000
upower -d
dmesg | egrep -i 'usb|hid|ups|eaton|mge|cyber|blazer|qx|epcom'
udevadm info -q property -n /dev/bus/usb/001/002
udevadm info -q property -n /dev/bus/usb/001/003
systemctl status nut-server nut-monitor
upsc -l
/usr/libexec/nut/usbhid-ups -h
/usr/libexec/nut/nutdrv_qx -h
/usr/libexec/nut/blazer_usb -h
timeout 20s /usr/libexec/nut/usbhid-ups -DD -d 1 -s linkedpro-test -u root -x port=auto -x vendorid=0463 -x productid=0001 -x explore
timeout 20s /usr/libexec/nut/usbhid-ups -DD -d 1 -s epcom-test -u root -x port=auto -x vendorid=0001 -x productid=0000 -x explore
timeout 20s /usr/libexec/nut/nutdrv_qx -DD -d 1 -s epcom-qx -u root -x port=auto -x vendorid=0001 -x productid=0000
timeout 20s /usr/libexec/nut/blazer_usb -DD -d 1 -s epcom-blazer -u root -x port=auto -x vendorid=0001 -x productid=0000
```

## Inventario USB observado

### LinkedPro LP1KRT

- `vendorid`: `0463`
- `productid`: `0001`
- `lsusb`:
  - `idVendor 0x0463 MGE UPS Systems`
  - `idProduct 0x0001 UPS`
  - `iManufacturer 1 KSTAR`
  - `iProduct 2 UPS HID`
  - `iSerial 3 HID-C01`
- `udev`:
  - `ID_VENDOR=KSTAR`
  - `ID_MODEL=UPS_HID`
  - `ID_SERIAL=KSTAR_UPS_HID_HID-C01`
- `upower -d`:
  - `vendor: Eaton`
  - `native-path: .../hiddev0`
  - `percentage: 100%`
  - `time to empty: 1.7 hours`

### Epcom EPU1500LCD

- `vendorid`: `0001`
- `productid`: `0000`
- `lsusb`:
  - `idVendor 0x0001 Fry's Electronics`
  - `idProduct 0x0000`
  - `iManufacturer 0`
  - `iProduct 1`
  - `iSerial 0`
- `udev`:
  - `ID_VENDOR=0001`
  - `ID_MODEL=0000`
  - `ID_SERIAL=0001_0000`
- `dmesg`:
  - `hid-generic ... [HID 0001:0000] on usb-...-5/input0`
- `usb strings` observadas por probing:
  - `Manufacturer: unknown`
  - `Product: MEC0003`
  - `Serial Number: unknown`

## Probing `NUT`

### `usbhid-ups` contra LinkedPro

Resultado: `success`

Salida util observada:

```text
Detected a UPS: KSTAR/UPS HID
device.mfr: KSTAR
device.model: UPS HID
device.serial: HID-C01
ups.mfr: KSTAR
ups.model: UPS HID
ups.productid: 0001
ups.serial: HID-C01
ups.status: OB
ups.vendorid: 0463
```

Lectura:

- la `LinkedPro` sigue siendo la unica UPS claramente monitorizable por Linux/NUT
- el stack `usbhid-ups` encuentra objetos HID utiles y devuelve variables legibles

### `usbhid-ups` contra Epcom

Resultado: `partial HID detection only`

Salida util observada:

```text
Detected a UPS: unknown/MEC0003
device.model: MEC0003
ups.model: MEC0003
ups.productid: 0000
ups.vendorid: 0001
nut_libusb_get_interrupt: Input/Output Error
```

Lectura:

- la `Epcom` si aparece como dispositivo USB/HID identificable
- `usbhid-ups` puede leer el descriptor y reconocer un candidato UPS
- pero no devuelve variables utiles de estado como:
  - `battery.charge`
  - `input.voltage`
  - `ups.status`
- por tanto no alcanza el umbral de monitorizacion util

### `nutdrv_qx` contra Epcom

Resultado: `no useful variables`

Salida relevante:

```text
Product: MEC0003
qx_process_answer: short reply
Device not supported!
```

Lectura:

- el dispositivo responde lo suficiente para ser seleccionado por `vendorid/productid`
- pero el driver no logra decodificar un protocolo Q* valido

### `blazer_usb` contra Epcom

Resultado: `no useful variables`

Salida relevante:

```text
Product: MEC0003
blazer_status: short reply
Trying mustek protocol...
Trying megatec/old protocol...
Trying zinto protocol...
No supported UPS detected
```

Lectura:

- el dispositivo no ofrece una conversacion compatible con `blazer_usb`
- no aparecieron variables exportables

## Conclusión

La `Epcom EPU1500LCD`:

- si aparece en USB y puede distinguirse de la `LinkedPro`
- si expone un descriptor HID de longitud significativa (`624`)
- pero no entrega telemetria util por los drivers `NUT` probados en esta fase

Veredicto actual:

- `monitorizable por Linux/NUT`: `no`, en esta fase
- `clasificacion operativa`: `runbook manual`

## Anomalias y notas

- `upower` solo refleja la `LinkedPro`; no crea un device separado para la `Epcom`
- `NUT` esta instalado en `management`, pero `nut-server` y `nut-monitor` siguen fallando; no se tocaron por alcance
- la `Epcom` usa una identidad USB muy generica:
  - `0001:0000`
  - sin manufacturer/serial utiles en `lsusb`
- el nombre `MEC0003` aparece solo durante probing y no fue suficiente para obtener variables reales

## Recomendación

- `Epcom EPU1500LCD` se mantiene como UPS de `runbook manual`
- `04B` no debe rediseñarse para intentar telemetria dual completa
- el diseño mas sano sigue siendo:
  - `LinkedPro LP1KRT` monitorizada por `NUT`
  - `Epcom EPU1500LCD` tratada como rama no instrumentada

Go/no-go para rediseñar `04B`:

- `no-go` para un rediseño basado en telemetria Linux de la `Epcom`
- `go` para continuar un `04B` centrado solo en la `LinkedPro` y en politicas manuales para la `Epcom`
