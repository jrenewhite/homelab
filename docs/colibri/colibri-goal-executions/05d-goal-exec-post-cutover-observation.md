# Microplan 05D — Post-cutover observation and DNS2 propagation investigation

## Resumen

`05D` se ejecuto en modo observacional puro, sin cambiar router, listas, clientes globales ni servicios.

Objetivo:

- confirmar estabilidad despues del cutover de `05C`
- determinar si `DNS2 = 1.1.1.1` realmente se propaga por `DHCP`

## Estado general post-cutover

- `Pi-hole` primario en `management` sigue sano
- `bd795m` sigue con Internet
- `orangepi5-max` sigue con Internet
- `Pi-hole` sigue recibiendo queries reales
- `split-horizon` sigue `pending`

## Router en modo read-only

Validaciones:

- `ER707-M2` accesible por `SSH`
- `DHCP` sigue habilitado en el pool `LAN`
- el router conserva la configuracion pretendida del cutover:
  - `DNS1 = 192.168.0.10`
  - `DNS2 = 1.1.1.1`

Observacion:

- la `CLI` del router no fue una fuente comoda/fiable para demostrar que ambos valores se entregan a clientes
- la evidencia decisiva vino de los leases efectivos en cliente

## Cliente canary 1 — `bd795m`

IP:

- `192.168.0.18`

Evidencia:

```bash
resolvectl status enp6s0
nmcli device show enp6s0
dig +short cloudflare.com
dig +short google.com
dig +short pi-hole.net
curl -I --max-time 5 https://cloudflare.com
```

Resultado:

- `Current DNS Server: 192.168.0.10`
- `DNS Servers: 192.168.0.10`
- `IP4.DNS[1]: 192.168.0.10`
- resolucion externa: `ok`
- navegacion basica: `ok`

Lectura:

- no hay evidencia de `1.1.1.1` en el `DNS` activo/recibido de este cliente

## Cliente canary 2 — `orangepi5-max`

IP:

- `192.168.0.15`

Evidencia:

```bash
resolvectl status enP3p49s0
sudo cat /run/systemd/netif/leases/2
curl -I --max-time 5 https://cloudflare.com
```

Resultado:

- `Current DNS Server: 192.168.0.10`
- `DNS Servers: 192.168.0.10`
- lease efectivo:
  - `DNS=192.168.0.10`
- resolucion/navegacion: `ok`

Lectura:

- aqui tampoco aparece `1.1.1.1`
- en un cliente `systemd-networkd`, el lease efectivo solo trae un `DNS`

## Evidencia de queries en Pi-hole

`Pi-hole` primario siguio registrando queries desde:

- `192.168.0.18`
- `192.168.0.15`

Ejemplos:

- `cloudflare.com`
- `google.com`
- `pi-hole.net`
- trafico normal de fondo y web

## Split-horizon

Sigue pendiente:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`

Esto no se considera fallo de `05D`.

## Conclusión sobre DNS2

Conclusión seleccionada:

- `B. DNS2 no se entrega por DHCP`

Base de la conclusión:

- dos clientes distintos muestran solo `192.168.0.10`
- uno de esos clientes expone ademas el lease efectivo, donde solo aparece:
  - `DNS=192.168.0.10`
- por eso no parece ser simplemente que el cliente “oculte el secundario” mientras use el primario

## Anomalías

- el router parece aceptar/configurar `DNS2 = 1.1.1.1`
- pero la propagacion efectiva a clientes no se observo
- no hubo perdida de Internet ni degradacion visible del hogar

## Veredicto

- estabilidad post-cutover: `pass`
- `Pi-hole` primario sigue en uso real
- `DNS2` como fallback distribuido por `DHCP`: no validado; conclusion actual `no se entrega`
- `05E` split-horizon local records: `go`
