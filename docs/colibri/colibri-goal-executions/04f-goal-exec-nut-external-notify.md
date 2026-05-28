# Goal Execution 04F — External NUT Notification, Non-Destructive

Fecha de ejecucion: `2026-05-28`  
Modo: `best-effort external notify preparation`

## Objetivo

Agregar una via de notificacion externa no destructiva para eventos `NUT`, preferentemente compatible con `ntfy`, sin depender todavia de `Matrix` ni de bots, y sin romper el logger local.

## Restricciones respetadas

- no se habilito shutdown real
- no se probo blackout fisico
- no se desconecto la UPS
- no se uso `upsmon -c fsd`
- no se enviaron magic packets
- no se hizo wake/sleep
- no se apagaron servicios ni nodos
- no se guardaron secretos en el repo
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

## Hallazgo previo de entorno

No existe configuracion local de `ntfy` en esta fase:

- `ntfy` binario: ausente
- `/opt/colibri-secrets/ntfy.env`: ausente en todos los nodos validados
- `curl`: presente en `management`, `services`, `ai-gpu`, `orangepi5-ultra`

Lectura:

- no se desplego `ntfy` como servicio
- la integracion queda preparada como `best-effort`
- sin secreto local, la fase cierra como `partial / no-op externo`, conservando logger local

## Archivos modificados

En todos los nodos con `upsmon`:

- `/usr/local/sbin/nut-notify-log.sh`

No se tocaron configs `NUT` adicionales en esta fase.

## Manejo de secretos

La integracion busca secretos solo en:

- `/opt/colibri-secrets/ntfy.env`

Variables esperadas:

- `NTFY_URL`
- `NTFY_TOKEN` opcional

Politica:

- si el archivo no existe, el script hace solo logging local
- si el archivo existe y `curl` esta disponible, intenta envio externo con timeout corto
- si falla el envio externo, registra fallo local y sale con exito

## Script resultante

Comportamiento actual:

1. siempre escribe en `logger -t nut-event`
2. opcionalmente carga `/opt/colibri-secrets/ntfy.env`
3. si `NTFY_URL` existe, intenta `curl` con:
   - `Title`
   - `Priority`
   - `Tags`
   - `Authorization: Bearer ...` solo si hay token
4. si `curl` falla:
   - registra `ntfy=failed`
   - no bloquea `NUT`

Mapeo de prioridad:

- `LOWBATT` -> `urgent`
- `ONBATT`, `COMMBAD` -> `high`
- `ONLINE`, `COMMOK` -> `default`
- `FSD` -> `urgent`

## Eventos sinteticos probados

### `management`

Se ejecuto:

```bash
NOTIFYTYPE=ONBATT UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic external notify validation"
```

Evidencia en journal:

```text
host=management role=master type=ONBATT ups=linkedpro msg=synthetic external notify validation
```

### `services`

Se ejecuto:

```bash
NOTIFYTYPE=COMMOK UPSNAME=linkedpro /usr/local/sbin/nut-notify-log.sh "synthetic external notify validation"
```

Evidencia en journal:

```text
host=services role=client type=COMMOK ups=linkedpro msg=synthetic external notify validation
```

## Evidencia `ntfy`

No aplica en esta fase:

- no habia `NTFY_URL`
- no habia secreto local en `/opt/colibri-secrets/ntfy.env`
- por eso no se intento envio externo real

## Estado final de `NUT`

### `management`

- `nut-server`: `active`
- `nut-monitor`: `active`

`upsc linkedpro@localhost`:

```text
battery.charge: 100
input.voltage: 117.3
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

### Clientes

Siguen en observacion y activos:

- `services`
- `nas`
- `ai-gpu`
- `orangepi5-ultra`

Lectura remota sigue sana:

```text
battery.charge: 100
input.voltage: 117.3
output.voltage: 119.8
ups.productid: 0001
ups.status: OL
ups.vendorid: 0463
```

## Anomalias

- no hubo endpoint `ntfy` configurado, asi que no se pudo demostrar entrega externa real
- eso no bloquea la fase porque el objetivo de seguridad era que la integracion fuera `best-effort` y no rompiera el logger local ni `NUT`

## Conclusion

`04F` queda cerrado como integracion externa preparada:

- logger local intacto
- soporte `ntfy` listo
- secretos fuera de git
- comportamiento externo `best-effort`
- sin endpoint configurado, la fase queda como `partial / no-op externo`

## Recomendacion

Go/no-go para `04G`:

- `go` para politica futura de acciones, todavia sin ejecucion real

Siguiente paso natural:

- crear `/opt/colibri-secrets/ntfy.env` en el nodo o nodos deseados
- volver a probar `04F` para confirmar entrega externa real
