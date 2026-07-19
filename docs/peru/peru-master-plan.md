# Perú — Plan Maestro Inicial

Documento maestro inicial para la sede `Perú` dentro de la plataforma multi-site `white-enciso.com`.

Este documento toma a `Colibrí` como referencia operativa principal, pero ajusta:

- la ventana realista de trabajo en sitio;
- el hardware confirmado para `Perú`;
- la prioridad de dejar acceso administrativo por `Tailscale` antes de intentar capas superiores.

Documentos relacionados:

- [white-enciso-multisite.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-multisite.md)
- [white-enciso-sync-policy.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-sync-policy.md)
- [colibri-master-plan.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-master-plan.md)
- [peru-inventory.md](/home/jrenewhite/Projects/homelab/docs/peru/peru-inventory.md)
- [peru-arrival-runbook.md](/home/jrenewhite/Projects/homelab/docs/peru/peru-arrival-runbook.md)

## 1. Objetivo inmediato

La primera ventana de trabajo en `Perú` no busca terminar el sitio.

Busca dejar:

- direccionamiento estable por reserva DHCP en router `ER605`;
- hostnames unicos por sitio;
- acceso `SSH`;
- acceso administrativo por `Tailscale`;
- base minima para clonar despues el resto del modelo de `Colibrí`.

## 2. Principios

- `Colibrí` sigue siendo el sitio de referencia.
- `Perú` debe ser lo mas par posible, con excepciones de hardware documentadas.
- primero estabilidad de red y acceso remoto;
- luego base del sistema;
- luego servicios core privados;
- despues DNS local, proxy y apps.
- no se intentan demasiadas capas criticas en la misma ventana.

## 3. Decision de red

El `ER605` de `Perú` usa `192.168.0.0/24` y se mantiene ese rango para la primera ventana.

Subred efectiva para `Perú`:

```text
LAN: 192.168.0.0/24
router: 192.168.0.1
reservas de infraestructura: 192.168.0.10-29
DHCP dinamico general: se conserva segun configuracion actual del ER605
```

Razon:

- evita cambiar la LAN durante la ventana inicial;
- conserva la semantica de IPs ya documentada, pero dentro del rango real del `ER605`;
- permite cerrar reservas DHCP y `Tailscale` primero, dejando cualquier renumeracion futura como trabajo separado.

Decision operativa:

- no migrar el `ER605` fuera de `192.168.0.0/24` durante la primera ventana;
- importar reservas definitivas en el rango `192.168.0.10-29`;
- si mas adelante se necesita evitar overlap inter-sede, planear esa renumeracion como cambio controlado posterior.

## 4. Roles definitivos por nodo

| Nodo canonico | Rol | Regimen |
|---|---|---|
| `peru-services` | control plane operativo, `Tailscale`, `Ansible`, `NUT` master, apps principales, storage caliente, coordinacion de sync, `Caddy` primario futuro | 24/7 |
| `peru-ai-gpu` | GPU pesada, media pesada, IA, jobs batch | bajo demanda |
| `peru-nas` | archivo frio, `NFS`, backups, libreria final | despertable o diferido |
| `peru-rpi5-a` | `Pi-hole` primario, `Home Assistant`, sentinel secundario, backup proxy/tunnel | 24/7 |
| `peru-rpi5-b` | recuperacion fisica requerida tras intento remoto de migrar rootfs a SSD | 24/7 cuando este sano |
| `peru-rpi4-a` | `Pi-hole` secundario provisional, watchdog, healthchecks, utilidades ligeras | 24/7 |
| `peru-rpi4-b` | watchdog, healthchecks, utilidades ligeras o storage auxiliar | 24/7 |

`peru-management` queda retirado del sitio y su reserva `192.168.0.10` no debe importarse como nodo activo.

## 5. Hardware confirmado

- `peru-services`: `Minisforum UM870 Slim`, misma RAM y SSDs que el equivalente en `Colibrí`
- `peru-ai-gpu`: `Minisforum 790S7`, misma RAM, SSDs y `RTX 5060`
- `peru-nas`: gabinete armado; puede quedar fuera de la primera ventana
- `2 x Raspberry Pi 5 8 GB` con `SSD USB 240 GB`
- `2 x Raspberry Pi 4B 8 GB` con `SSD USB 1 TB`
- `peru-services` tiene ambos `UPS` conectados por `USB` y sera el `NUT` master del sitio.

## 6. Supuestos y pendientes aun no cerrados

- `peru-management` fue retirado del sitio; no se considera parte del estado objetivo activo;
- se confirmaron `4 SBCs`: `2 x Raspberry Pi 5` y `2 x Raspberry Pi 4`, todas de `8 GB`;
- la politica electrica local parte de `peru-services` como `NUT` master por conexion USB directa a ambos `UPS`;
- `nas` puede quedar fuera del primer dia;
- no esta aprobada aun ninguna exposicion publica por `cloudflared` desde `Perú`;
- `authentik`, `Vaultwarden`, `Matrix` y demas estado delicado no se promueven en la primera ventana.

## 7. Prioridad operacional inicial

Orden real de prioridad para el primer dia:

1. `peru-services`
2. `peru-rpi5-a`
3. `peru-rpi4-a`
4. `peru-ai-gpu`
5. `peru-rpi4-b`
6. `peru-nas`
7. `peru-rpi5-b`

Interpretacion:

- `peru-services`, `peru-rpi5-a` y `peru-rpi4-a` forman la base minima de control local;
- el resto puede quedar por lotes, pero con hostname e IP reservada definidos;
- `nas` solo entra si sobra tiempo o ya esta fisicamente listo.

## 8. DNS, Proxy y Control Plane

Decision:

- `Pi-hole` primario en `peru-rpi5-a`;
- `Pi-hole` secundario en `peru-rpi4-a` mientras `peru-rpi5-b` requiere recuperacion fisica;
- `peru-rpi5-b` no debe alojar DNS ni servicios criticos hasta recuperar el boot tras la migracion remota incompleta a SSD;
- `Caddy` primario en `peru-services`, porque las apps principales y el storage caliente viviran ahi;
- `peru-rpi5-a` puede alojar un `Caddy` standby o proxy minimo solo si se necesita continuidad durante mantenimiento de `peru-services`.

Razon:

- DNS debe sobrevivir reinicios de apps, `Docker` pesado o mantenimiento del nodo `services`;
- Caddy se beneficia de estar cerca de los backends principales;
- el control plane queda repartido: energia y apps en `peru-services`, DNS/sentinel en las `RPi`.

## 9. Tailscale-first

La prioridad inmediata no es desplegar servicios.

La prioridad es que cada nodo importante quede:

- identificable por hostname unico;
- alcanzable por IP local;
- alcanzable por `Tailscale`;
- listo para administracion posterior sin volver a tocar consola local.

Politica inicial:

- `Tailscale` en todos los nodos criticos
- `SSH` con llave administrativa
- sin exposicion publica
- sin subnet routers ni exit nodes el primer dia, salvo necesidad clara

## 10. Criterios de exito de la primera ventana

La primera visita a `Perú` se considera exitosa si al terminar:

- el router tiene reservas DHCP para todos los nodos previstos;
- `peru-services`, `peru-ai-gpu`, `peru-rpi5-a` y `peru-rpi4-a` responden por `ping` y `SSH`;
- esos mismos nodos aparecen en `Tailscale`;
- existe evidencia escrita de que subred, hostnames y roles quedaron cerrados;
- no se hicieron cambios de riesgo alto innecesarios en DNS, proxy publico o storage.
