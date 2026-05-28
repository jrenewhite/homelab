# Goal Execution 04A.1 — WOL Inventory and Tooling Readiness

Fecha de ejecucion: `2026-05-27`  
Modo: `inventory + minimal tooling + runtime WOL enable`

## Objetivo

Completar el inventario `WOL` de los 8 nodos principales, dejar el tooling minimo listo para una futura fase de prueba real y, despues de confirmar soporte, habilitar `WOL` en runtime sin enviar magic packets ni modificar configuracion persistente.

## Restricciones respetadas

- no se ejecutaron:
  - `wakeonlan`
  - `etherwake`
- no se enviaron magic packets
- no se modifico configuracion persistente de red o `WOL`
- no se tocaron:
  - `NUT`
  - router
  - DNS
  - `Pi-hole`
  - `Caddy`
  - `cloudflared`
  - `Tailscale`
  - `SSO`
  - mounts
  - `NFS`
  - apps productivas

## Nodos tocados

- `management` `192.168.0.10`
- `nas` `192.168.0.11`
- `services` `192.168.0.12`
- `ai-gpu` `192.168.0.13`
- `orangepi5-ultra` `192.168.0.14`
- `orangepi5-max` `192.168.0.15`
- `orangepi5-a` `192.168.0.16`
- `orangepi5-b` `192.168.0.17`

## Comandos ejecutados

```bash
git status --short
hostname
ip -br link
ip route
ethtool -i <iface>
ethtool <iface>
nmcli connection show
networkctl status <iface>
apt-get -s install wakeonlan
apt-get install -y wakeonlan
ethtool -s <iface> wol g
```

## Acceso operativo

- `SSH` por llave ya funciona en todos los nodos principales usados en esta fase
- el password queda reservado a `sudo` cuando aplica

## Matriz `WOL`

| Nodo | Interfaz principal | `MAC` | Driver | `Supports Wake-on` | `Wake-on` actual | Estado | Accion futura | Politica |
|---|---|---|---|---|---|---|---|---|
| `management` | `eno1` | `C4:65:16:AC:AB:37` | `e1000e` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | deseable para recuperacion; no usar para inferir estado de UPS |
| `services` | `enp2s0` | `58:47:CA:79:08:69` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | deseable para recuperacion; no usar para inferir estado de UPS |
| `nas` | `eno1` | `C8:FF:BF:05:F4:46` | `igc` | `pumbg` | `g` | `confirmed` | `none` | permitido solo en energia normal; prohibido en bateria |
| `ai-gpu` | `enp4s0` | `58:47:CA:7F:84:B5` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | permitido solo en energia normal; prohibido en bateria |
| `orangepi5-ultra` | `enP3p49s0` | `C0:74:2B:FC:59:86` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |
| `orangepi5-max` | `enP3p49s0` | `C0:74:2B:FD:71:43` | `r8169` | `pumbg` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |
| `orangepi5-a` | `end1` | `C6:CC:84:3D:E2:67` | `st_gmac` | `ug` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |
| `orangepi5-b` | `end1` | `C6:87:B3:C0:55:95` | `st_gmac` | `ug` | `g` | `confirmed` | `needs OS persistence plan` | tratar como `always-on` hasta definir si realmente se aprovechara el wake |

## Tooling

### Estado factual

- `ethtool` ya estaba presente en todos los nodos
- en las `Orange Pi`, `ethtool` no aparecia en el `PATH` del usuario, pero si estaba disponible en `/usr/sbin/ethtool`
- `wakeonlan` faltaba en `management`

### Paquetes instalados

| Nodo | Paquete | Resultado |
|---|---|---|
| `management` | `wakeonlan` | instalado correctamente |

No se instalaron otros paquetes porque:

- `ethtool` ya estaba presente en todos los nodos
- no hacia falta una herramienta de wake fuera de `management` en esta fase

## Hallazgos

- la primera lectura habia sido demasiado conservadora: `ethtool` si expone `WOL` en todos los nodos principales cuando se consulta con la interfaz correcta y privilegios suficientes
- `management`, `services`, `ai-gpu` y `nas` quedaron con `Supports Wake-on: pumbg` y `Wake-on: g`
- `orangepi5-ultra` y `orangepi5-max` tambien quedaron con `Supports Wake-on: pumbg` y `Wake-on: g`
- `orangepi5-a` y `orangepi5-b` exponen `Supports Wake-on: ug` y quedaron en `Wake-on: g`
- el siguiente riesgo ya no es ausencia de soporte, sino falta de persistencia documentada despues de reboot o power cycle

## Anomalias

- `orangepi5-ultra` tuvo conectividad inestable al inicio de la ventana, aunque quedo inventariado
- en las `Orange Pi`, `ethtool` estaba instalado pero fuera del `PATH` del usuario
- `WOL` quedo habilitado en runtime, pero esta fase no verifico persistencia despues de reboot

## Recomendacion

- fase posterior de prueba real `WOL`: `no-go` para despliegue amplio

Motivos:

- aunque todos los nodos quedaron `confirmed`, falta probar persistencia y comportamiento real por tandas
- `nas` y `ai-gpu` siguen prohibidos para wake cuando el sistema este en bateria
- primero conviene separar una fase de prueba real `WOL` controlada y con gating de energia

## Siguiente paso sugerido

Antes de cualquier prueba real de `WOL`:

1. validar BIOS/firmware de `management`, `services` y `ai-gpu`
2. confirmar si el OS mantiene `Wake-on: g` despues de reboot o power cycle
3. mantener la regla:
   - `nas` y `ai-gpu` nunca se despiertan en bateria
