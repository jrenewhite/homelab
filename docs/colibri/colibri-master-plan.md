# Colibrí — Plan Maestro

Documento maestro de arquitectura aprobada para la casa `Colibrí`, dentro de la plataforma multi-site `white-enciso.com`.

Este documento es la fuente de verdad principal para diseño y decisiones del sitio `Colibrí`. Los demás documentos se usan así:

- [white-enciso-multisite.md](../white-enciso-multisite.md): marco compartido multi-site
- [colibri-inventory.md](./colibri-inventory.md): estado factual observado
- [colibri-router-baseline.md](./colibri-router-baseline.md): baseline del router
- [colibri-risk-matrix.md](./colibri-risk-matrix.md): riesgo, prechecks y rollback por microplan
- `colibri-microplans/`: anexos `decision complete` por subsistema

## 1. Objetivo

Antes de implementar más cambios, `Colibrí` debe quedar completamente especificado, sin contradicciones ni huecos de diseño, para que la ejecución posterior sea casi mecánica.

## 2. Principios rectores

- `Docs` son la fuente de verdad principal.
- `Colibrí` es el sitio principal; `Perú` es el segundo sitio previsto.
- `Ansible` es implementación derivada y migrará gradualmente a `management`.
- `Ansible` debe construirse como librería reutilizable por capas, no como colección de cambios ad hoc.
- `git` es la bitácora de diseño, decisiones y evolución operacional del homelab.
- `services` es el nodo principal de vida digital y trabajo caliente.
- `management` es el nodo de control 24/7.
- `nas` es una restricción arquitectónica despertable, no una conveniencia.
- Ninguna app crítica puede depender runtime de `nas`.
- el `ER707-M2` conserva DHCP como autoridad única de la LAN; `Pi-hole` solo participa como resolvedor DNS
- `root_squash` se mantiene en `NFS`.
- Permisos y acceso se resuelven con `UID/GID` fijos, grupos compartidos, `setgid` y `ACLs`.
- `SSO` es requisito arquitectónico para servicios de usuario y administración compatibles.
- la experiencia normal de usuario usa las mismas URLs globales bajo `white-enciso.com`
- la resolución local será `split-horizon` por sitio
- el modelo operativo preferido es `activo-local por sitio + ventanas de sincronización`
- `WireGuard` será el backbone privado entre sedes; `Tailscale` conserva el rol de acceso administrativo
- La energía manda la degradación: blackout y UPS tienen prioridad sobre conveniencia de apps.
- Todo cambio operativo debe privilegiar continuidad de servicio, validación previa y rollback simple.
- toda etapa de DNS doméstico debe conservar un fallback público de emergencia en el router hasta que la resiliencia local esté realmente probada
- ningún microplan pasa a ejecución real si no tiene prechecks, criterio de abortar y rollback proporcional a su clase de riesgo
- Nunca se cambia al mismo tiempo más de una capa crítica entre:
  - direccionamiento/IPs
  - DNS del router
  - proxy/túneles
  - identidad/SSO
  - storage compartido
- Primero se despliega en modo `staged`, luego se valida por acceso directo, y solo después se hace el cutover.

## 3. Roles definitivos por nodo

| Nodo | Rol definitivo | Régimen |
|---|---|---|
| `management` | control plane, DNS primario, proxy principal, `cloudflared` principal, `Ansible`, utilidades de operación | 24/7 |
| `services` | apps principales, Matrix, Hermes, `n8n`, Arr stack, staging, sync coordinator, caché caliente | 24/7 |
| `ai-gpu` | GPU pesada, Jellyfin GPU, Immich ML, OCR, Whisper, LLM grande, batch | bajo demanda |
| `nas` | `NFS`, backups, librería final, sync target, archivo frío | despertable |
| `orangepi5-ultra` | Home Assistant, DNS secundario, proxy/tunnel backup, sentinel secundario | 24/7 |
| `orangepi5-max` | sentinel auxiliar, worker ARM, DNS terciario opcional | 24/7 |
| `orangepi5-a` | watchdog, worker stateless, tareas ligeras | 24/7 |
| `orangepi5-b` | watchdog, worker stateless, healthchecks | 24/7 |

## 4. Restricciones duras

- `services` debe seguir operando si `nas` está dormido o inaccesible.
- `nas` no puede albergar bases de datos, colas, cachés ni estado caliente de servicios.
- `Jellyfin`, `Immich`, `Paperless`, `Arr`, `Hermes`, `n8n` y `Matrix` trabajan sobre storage local y solo sincronizan o consumen archivo final del `nas`.
- El blackout no puede despertar `nas` ni `ai-gpu`.
- `management` no será `NUT master`.
- Ningún panel administrativo sensible debe exponerse por Internet.
- `Matrix` no usará el mismo homeserver activo-local en ambas sedes; si existe en ambas, serán homeservers federados distintos.

## 5. Orden macro de implementación futura

1. Red y direccionamiento final
2. Identidades compartidas y permisos
3. Storage local-first y política `nas`
4. Energía, UPS y blackout
5. DNS y resolución resiliente
6. Reverse proxy y `cloudflared`
7. Flujo documental y disciplina de `git`
8. Transición de `Ansible` a `management`
9. `SSO` e identidad federada
10. `colibri-sentinel-bot`
11. Servicios core
12. Servicios de usuario
13. Media, IA y jobs pesados
14. Observabilidad y alertas

Cada fase debe ejecutarse así:
1. preparar y desplegar en paralelo sin impacto a clientes;
2. validar por IP/ruta directa o acceso privado;
3. aplicar cambio visible a clientes en una sola capa;
4. observar;
5. solo entonces continuar con la siguiente capa.

## 6. Dependencias entre subsistemas

- DNS depende de red estable y direccionamiento final.
- la capa por sitio depende del marco multi-site y no puede contradecir la política de URLs globales.
- Proxy y túneles dependen de DNS, IPs finales y política de exposición.
- `SSO` depende de DNS, proxy, política de exposición y decisión de almacenamiento local para su propio estado.
- `Ansible` depende de acceso `SSH`, identidades y hostnames estables.
- La disciplina de `git` depende de estructura documental estable, pero debe preceder el despliegue sostenido por `Ansible`.
- `nas` despertable depende de storage local-first ya cerrado por servicio y de ventanas de sync entre sedes.
- Bot de resiliencia depende de blackout, DNS, proxy y canal alterno ya definidos.
- Apps dependen de permisos, storage local-first, política de energía, estrategia de `SSO` y reglas multi-site ya cerradas.

## 7. Criterios de aceptación globales

La fase de diseño solo se considera completa cuando:

- el documento maestro no contradice el inventario factual;
- cada microplan es implementable sin decisiones nuevas;
- la política `nas` despertable está cerrada y coherente con todas las apps;
- la estrategia de `SSO` define qué servicios federan identidad, cuáles usan auth por proxy y cuáles conservan cuenta local de excepción;
- la transición de `Ansible` a `management` está secuenciada y libre de ambigüedad;
- la disciplina de `git` deja trazable cada cambio de diseño y cada hito de implementación;
- el bot tiene contrato completo aunque aún no exista código;
- existe una matriz clara por servicio con nodo, storage, dependencia de red, dependencia de `nas` y dependencia de energía;
- los fallos principales están descritos:
  - cae `management`
  - cae `services`
  - cae `nas`
  - cae `ai-gpu`
  - blackout
  - Internet caído
  - Matrix caído

## 8. Índice de microplanes

- [01-network-and-addressing.md](./colibri-microplans/01-network-and-addressing.md)
- [02-identities-and-permissions.md](./colibri-microplans/02-identities-and-permissions.md)
- [03-storage-local-first.md](./colibri-microplans/03-storage-local-first.md)
- [04-energy-ups-blackout.md](./colibri-microplans/04-energy-ups-blackout.md)
- [05-dns-pihole.md](./colibri-microplans/05-dns-pihole.md)
- [06-reverse-proxy-cloudflared.md](./colibri-microplans/06-reverse-proxy-cloudflared.md)
- [07-ansible-transition.md](./colibri-microplans/07-ansible-transition.md)
- [08-repository-and-git-workflow.md](./colibri-microplans/08-repository-and-git-workflow.md)
- [09-identity-and-sso.md](./colibri-microplans/09-identity-and-sso.md)
- [10-sentinel-bot.md](./colibri-microplans/10-sentinel-bot.md)
- [11-services-core.md](./colibri-microplans/11-services-core.md)
- [12-services-user.md](./colibri-microplans/12-services-user.md)
- [13-media-ai-jobs.md](./colibri-microplans/13-media-ai-jobs.md)
- [14-observability-alerting.md](./colibri-microplans/14-observability-alerting.md)
