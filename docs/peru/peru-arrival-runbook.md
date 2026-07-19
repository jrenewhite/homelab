# Perú — Arrival Runbook

Runbook corto para la primera ventana operativa en la sede `Perú`.

Objetivo:

- llegar;
- dejar IPs fijas por reserva DHCP en el `ER605`;
- dejar `SSH` y `Tailscale` funcionando al menos en los nodos `P0`;
- salir con base suficiente para continuar remoto despues.

## 1. Regla de oro

No mezclar demasiadas capas.

Orden:

1. energia y cableado
2. router y reservas DHCP
3. conectividad local
4. hostname y `SSH`
5. `Tailscale`
6. paquetes base y `Docker`
7. solo si sobra tiempo: `Pi-hole`

## 2. Preparacion previa

Llevar listos:

- llave `SSH` administrativa
- cuenta de `Tailscale`
- lista de hostnames objetivo
- tabla de IPs objetivo
- credenciales del `ER605`
- adaptador HDMI/teclado si alguna `Raspberry Pi` no toma red

## 3. Tabla de IPs objetivo

| Nodo | IP objetivo | Prioridad |
|---|---|---|
| `peru-nas` | `192.168.0.11` | `P2` |
| `peru-services` | `192.168.0.12` | `P0` |
| `peru-ai-gpu` | `192.168.0.13` | `P0` |
| `peru-rpi5-a` | `192.168.0.14` | `P0` |
| `peru-rpi5-b` | `192.168.0.15` | `P2` |
| `peru-rpi4-a` | `192.168.0.17` | `P0` |
| `peru-rpi4-b` | `192.168.0.18` | `P1` |

## 4. Secuencia recomendada de 2 horas

### 0-20 min

- entrar al `ER605`
- confirmar subred real
- conservar LAN del router en `192.168.0.1/24`
- reservar infraestructura en `192.168.0.10-29`
- crear reservas DHCP para todos los nodos previstos
- importar `Address_Reservation_Proposed.csv` con la LAN en `192.168.0.0/24`
- conectar primero solo los nodos `P0`

### 20-50 min

- validar lease e IP tomada por:
  - `peru-services`
  - `peru-ai-gpu`
  - `peru-rpi5-a`
  - `peru-rpi4-a`
- validar `ping`
- validar `SSH`
- fijar hostname final si todavia no coincide

### 50-90 min

- instalar o validar `Tailscale` en cada nodo `P0`
- confirmar que cada nodo aparece en el tailnet
- probar acceso administrativo remoto por nombre `Tailscale` o IP `100.x`
- instalar llave `SSH` administrativa si falta

### 90-120 min

- instalar base minima:
  - `curl`
  - `git`
  - `vim`
  - `tmux`
  - `sudo`
  - `htop`
  - `jq`
  - `rsync`
- instalar `Docker` donde aplique:
  - `peru-services`
  - `peru-rpi5-a` si alcanza
- si todo va bien, dejar listo `Pi-hole` primario staged en `peru-rpi5-a`
- dejar `peru-services` como candidato a `NUT` master por tener ambos `UPS` conectados por USB

## 5. Orden exacto de prioridad Tailscale

### P0

- `peru-services`
- `peru-ai-gpu`
- `peru-rpi5-a`
- `peru-rpi4-a`

### P1

- `peru-rpi4-b`

### P2

- `peru-nas`
- `peru-rpi5-b` hasta recuperar boot/storage en sitio

## 6. Criterio de exito por nodo

Un nodo cuenta como "listo para continuar remoto" si cumple:

- lease correcto en router
- responde por `ping`
- acepta `SSH`
- tiene hostname final
- aparece en `Tailscale`

`Docker` es deseable, pero no obligatorio para considerar exitosa la primera visita.

## 7. Lo que no conviene hacer en esta ventana

- montar `NFS` definitivo
- configurar `mergerfs`
- desplegar media pesada
- publicar `cloudflared`
- mover `authentik`
- desplegar `Matrix`
- hacer tuning de blackout/UPS
- cambiar mas de una vez la subred del sitio

## 8. Primer servicio opcional despues de Tailscale

Si sobra tiempo, el primer servicio a dejar staged debe ser:

1. `Pi-hole` primario en `peru-rpi5-a`
2. `Pi-hole` secundario en `peru-rpi4-a`
3. `NUT` master en `peru-services`
4. `Homepage` local privado en `peru-services`

No intentaria exposicion publica el mismo dia si el acceso remoto todavia no quedo impecable. `Caddy` local puede quedar en `peru-services` cuando los backends principales esten definidos.

`peru-rpi5-b` no debe recibir servicios criticos hasta recuperar boot/storage en sitio: se intento migrar rootfs a SSD de forma remota y el nodo no volvio por Tailscale tras reboot.

## 9. Checklist de salida

- reservas DHCP guardadas en el router
- tabla final de `MAC -> IP -> hostname` registrada en docs
- `P0` confirmado por `SSH`
- `P0` confirmado por `Tailscale`
- credenciales locales y llaves administrativas verificadas
- notas escritas de cualquier excepcion rara de boot, NIC o `SSD USB`
