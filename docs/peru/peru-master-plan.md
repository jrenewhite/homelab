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

## 3. Decision de red propuesta

`Perú` no debe reutilizar `192.168.0.0/24` si despues existira `WireGuard site-to-site`.

Subred propuesta para `Perú`:

```text
LAN: 192.168.10.0/24
router: 192.168.10.1
reservas de infraestructura: 192.168.10.10-29
DHCP dinamico general: 192.168.10.100-199
```

Razon:

- evita overlap futuro con `Colibrí` `192.168.0.0/24`;
- simplifica rutas inter-sede;
- permite clonar la semantica de IPs por rol:
  - `.10` management
  - `.11` nas
  - `.12` services
  - `.13` ai-gpu
  - `.14+` ARM/SBC

Si el `ER605` en `Perú` ya usa otra subred y cambiarla en sitio es riesgoso, se conserva la subred existente y se documenta como excepcion.

## 4. Roles definitivos por nodo

| Nodo canonico | Rol | Regimen |
|---|---|---|
| `peru-management` | control plane, `Tailscale`, `Ansible`, DNS primario futuro, proxy principal futuro | 24/7 |
| `peru-services` | apps principales, storage caliente, coordinacion de sync | 24/7 |
| `peru-ai-gpu` | GPU pesada, media pesada, IA, jobs batch | bajo demanda |
| `peru-nas` | archivo frio, `NFS`, backups, libreria final | despertable o diferido |
| `peru-rpi5-ultra` | DNS secundario, `Home Assistant`, sentinel secundario, backup proxy/tunnel | 24/7 |
| `peru-rpi5-max` | sentinel auxiliar, DNS terciario opcional, worker ARM | 24/7 |
| `peru-rpi5-a` | worker ARM stateless o utilitario persistente | 24/7 |
| `peru-rpi4-a` | watchdog, healthchecks, utilidades ligeras | 24/7 |
| `peru-rpi4-b` | watchdog, healthchecks, utilidades ligeras o storage auxiliar | 24/7 |

## 5. Hardware confirmado

- `peru-services`: `Minisforum UM870 Slim`, misma RAM y SSDs que el equivalente en `Colibrí`
- `peru-ai-gpu`: `Minisforum 790S7`, misma RAM, SSDs y `RTX 5060`
- `peru-nas`: gabinete armado; puede quedar fuera de la primera ventana
- `3 x Raspberry Pi 5 8 GB` con `SSD USB 240 GB`
- `2 x Raspberry Pi 4B 8 GB` con `SSD USB 1 TB`

## 6. Supuestos y pendientes aun no cerrados

- se asume que `management` existe como nodo separado, pero su hardware aun no esta documentado aqui;
- se asume que los `5 SBCs` mencionados son el dato correcto;
- no esta cerrada aun la politica electrica local de `Perú`;
- `nas` puede quedar fuera del primer dia;
- no esta aprobada aun ninguna exposicion publica por `cloudflared` desde `Perú`;
- `authentik`, `Vaultwarden`, `Matrix` y demas estado delicado no se promueven en la primera ventana.

## 7. Prioridad operacional inicial

Orden real de prioridad para el primer dia:

1. `peru-management`
2. `peru-services`
3. `peru-ai-gpu`
4. `peru-rpi5-ultra`
5. `peru-rpi5-max`
6. `peru-rpi5-a`
7. `peru-rpi4-a`
8. `peru-rpi4-b`
9. `peru-nas`

Interpretacion:

- todo nodo por encima de `peru-rpi5-ultra` debe salir con `Tailscale` el mismo dia si arranca;
- el resto puede quedar por lotes, pero con hostname e IP reservada definidos;
- `nas` solo entra si sobra tiempo o ya esta fisicamente listo.

## 8. Tailscale-first

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

## 9. Criterios de exito de la primera ventana

La primera visita a `Perú` se considera exitosa si al terminar:

- el router tiene reservas DHCP para todos los nodos previstos;
- `peru-management`, `peru-services`, `peru-ai-gpu` y `peru-rpi5-ultra` responden por `ping` y `SSH`;
- esos mismos nodos aparecen en `Tailscale`;
- existe evidencia escrita de que subred, hostnames y roles quedaron cerrados;
- no se hicieron cambios de riesgo alto innecesarios en DNS, proxy publico o storage.
