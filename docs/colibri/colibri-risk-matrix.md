# Colibrí — Matriz de Riesgo y Rollback

Matriz operativa para clasificar cada microplan según su riesgo, el tipo de rollback esperado y los prechecks mínimos antes de ejecutar cambios reales.

## Reglas globales

- `safe`: cambio staged o privado, con rollback trivial y sin impacto esperado a clientes.
- `guarded`: cambio visible o semivisible con rollback claro, pero con riesgo acotado.
- `high-risk`: cambio sobre gateway, energía, identidad o estado crítico; requiere ventana, canary y rollback documentado.
- Ningún cambio avanza sin:
  - prechecks explícitos
  - cambio de una sola capa crítica
  - observación posterior
  - rollback manual o automático definido

## Matriz

| Microplan | Riesgo | Rollback | Prechecks mínimos |
|---|---|---|---|
| `01-network-and-addressing` | `high-risk` | manual desde router; por host; nunca masivo | export o captura del estado del router, CSV de reservas validado, `SSH` a nodos clave, pool DHCP libre, no mezclar con DNS |
| `02-identities-and-permissions` | `guarded` | manual o por playbook; revertir grupos/ACLs | UID/GID mapeados, prueba de escritura en staging, mounts activos, snapshot lógico de ACLs/comandos de reversión |
| `03-storage-local-first` | `high-risk` | manual por servicio o por mount; nunca simultáneo | inventario de mounts, ruta local validada, app detenible, datos de prueba, no mezclar con DNS/IP |
| `04-energy-ups-blackout` | `high-risk` | manual; primero modo observación | topología UPS confirmada, rol `NUT` claro, shutdown test plan, exclusión de wake de `nas`/`ai-gpu` |
| `05-dns-pihole` | `guarded` en staged, `high-risk` al cutover | automático o manual desde router | `Pi-hole` validado por IP, fallback público configurado, canary real, script probado, no mezclar con DHCP reservations |
| `06-reverse-proxy-cloudflared` | `guarded` | manual por hostname o túnel | backend validado por IP privada, DNS local coherente, secreto Cloudflare listo, servicio aún no expuesto |
| `07-ansible-transition` | `guarded` | volver a ejecución local | llaves y dependencias en `management`, inventario neutral al host, pruebas de `ansible -m ping` |
| `08-repository-and-git-workflow` | `safe` | trivial por `git revert` o nueva edición | secretos ignorados, docs coherentes, commit scope claro |
| `09-identity-and-sso` | `high-risk` | cuenta break-glass local y despublicación del proxy auth | cuenta local de emergencia, app soporta bypass o cuenta local, no mezclar con cambio de DNS/proxy el mismo día |
| `10-sentinel-bot` | `guarded` al inicio, `high-risk` con acciones | desactivar automatismos y volver a modo observación | endpoints de salud definidos, canal alterno listo, límites de autoridad escritos |
| `11-services-core` | `guarded` | por contenedor o por servicio | servicio validado en privado, storage local, no dependencia de `nas`, monitoreo básico |
| `12-services-user` | `guarded` | por app; rollback a acceso privado o cuenta local | storage local validado, identidad definida, backup mínimo, prueba por IP privada |
| `13-media-ai-jobs` | `guarded` | por job, por servicio o por scheduler | staging local funcionando, política de energía clara, no depender de `nas` para arranque |
| `14-observability-alerting` | `safe` en pasivo, `guarded` con alertas reales | desactivar alertas ruidosas o automatismos | eventos definidos, canal alterno listo, checks pasivos primero |

## Política de promoción de riesgo

- Un microplan puede empezar en `safe` o `guarded` y subir de riesgo cuando:
  - toca clientes reales
  - toca el router
  - toca autenticación obligatoria
  - toca energía o apagados
  - toca storage ya usado por apps

## Regla de aceptación operacional

Un microplan solo puede declararse listo para ejecución cuando tenga, además de diseño:

- `prechecks`
- `canary` si aplica
- `rollback`
- `criterio de abortar`
- `criterio de confirmar`
