# Microplan 05B — Canary DNS por Cliente Manual

## Resumen

`Microplan 05B` se ejecuto sobre un unico cliente canary, sin tocar router, DHCP ni otros clientes.

Cliente canary usado:

- `bd795m`
- `CachyOS`
- IP `192.168.0.18`
- interfaz activa `enp6s0`
- conexion `NetworkManager`: `Wired connection 1`

## Prechecks

Comandos:

```bash
dig +short @192.168.0.10 cloudflare.com
dig +short @192.168.0.10 google.com
dig +short @1.1.1.1 cloudflare.com
resolvectl status
nmcli connection show 'Wired connection 1'
```

Resultado:

- `Pi-hole` primario responde por IP directa
- fallback publico `1.1.1.1` responde
- DNS anterior del cliente:
  - `192.168.0.1`
- rollback identificado:
  - restaurar `ipv4.ignore-auto-dns=no`
  - limpiar `ipv4.dns`
  - reaplicar la conexion

## DNS anterior

- `resolvectl` en `enp6s0`:
  - `Current DNS Server: 192.168.0.1`
  - `DNS Servers: 192.168.0.1`
- perfil `NetworkManager`:
  - `ipv4.ignore-auto-dns: no`
  - `ipv4.dns: --`

## DNS canary aplicado

Cambio temporal del perfil:

```bash
nmcli connection modify 'Wired connection 1' ipv4.ignore-auto-dns yes ipv4.dns '192.168.0.10 1.1.1.1'
nmcli device reapply enp6s0
resolvectl flush-caches
```

Estado canary activo:

- `Current DNS Server: 192.168.0.10`
- `DNS Servers: 192.168.0.10 1.1.1.1`

## Comandos ejecutados

Validacion del canary:

```bash
resolvectl status enp6s0
dig +short cloudflare.com
dig +short google.com
dig +short pi-hole.net
dig +short home.white-enciso.com
dig +short auth.white-enciso.com
dig +short jellyfin.white-enciso.com
dig +short paperless.white-enciso.com
curl -I --max-time 8 https://cloudflare.com
```

Evidencia en `Pi-hole`:

```bash
ssh jrenewhite@192.168.0.10 "docker exec pihole tail -n 60 /var/log/pihole/pihole.log"
```

Rollback:

```bash
nmcli connection modify 'Wired connection 1' ipv4.ignore-auto-dns no ipv4.dns ''
nmcli device reapply enp6s0
resolvectl flush-caches
```

## Resultados de resolucion

Con canary activo:

- `cloudflare.com`: resuelve
- `google.com`: resuelve
- `pi-hole.net`: resuelve

Resolucion interna staged:

- `home.white-enciso.com`: sin respuesta local staged
- `auth.white-enciso.com`: sin respuesta local staged
- `jellyfin.white-enciso.com`: sin respuesta local staged
- `paperless.white-enciso.com`: sin respuesta local staged

Lectura:

- `split-horizon DNS` sigue `pending`
- esto no se toma como fallo de `05B`

## Evidencia de queries en `Pi-hole`

`Pi-hole` primario registro consultas desde `192.168.0.18` para:

- `cloudflare.com`
- `google.com`
- `pi-hole.net`
- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`

Tambien registro respuestas `NXDOMAIN` cacheadas para los nombres internos pendientes.

## Resultado de navegacion

Prueba basica:

- `curl -I https://cloudflare.com`
- resultado: `HTTP/2 301`

Lectura:

- el cliente mantuvo salida a Internet
- navegacion basica `ok`

## Rollback

Rollback probado:

- `si`

Estado final despues del rollback:

- `Current DNS Server: 192.168.0.1`
- `DNS Servers: 192.168.0.1`
- el perfil volvio a:
  - `ipv4.ignore-auto-dns: no`
  - `ipv4.dns: --`
- resolucion externa y navegacion basica siguen `ok`

## Anomalias

- ninguna funcional para el canary DNS
- el unico pendiente relevante sigue siendo `split-horizon`

## Veredicto

- canary DNS por cliente manual: `pass`
- `05C` cutover DNS del router con:
  - `DNS1 = 192.168.0.10`
  - `DNS2 = 1.1.1.1`
  - `go`
