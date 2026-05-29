# Microplan 05 — DNS y Pi-hole

## Propósito

Definir resolución DNS resiliente para la casa y administración segura de Pi-hole.

## Estado actual

- la arquitectura staged de `Pi-hole` queda fijada en:
  - `management` `192.168.0.10:53`, UI `192.168.0.10:8200`
  - `orangepi5-ultra` `192.168.0.14:53`, UI `192.168.0.14:8201`
  - `orangepi5-max` `192.168.0.15:53`, UI `192.168.0.15:8202`
- las tres instancias usan `OISD small` como baseline conservador
- el `ER707-M2` sigue siendo la única autoridad DHCP de la red
- tras importar reservas DHCP, varios nodos del homelab siguen temporalmente en leases previos; no se asume todavía que ya respondan en sus IP finales
- `management` ya tiene el helper y script de rollback automático en dry-run lógico validado
- el aprendizaje operativo más importante fue:
  - no volver a mezclar cambio de DNS del router con cambios de IP o reservas DHCP
  - no usar dos `Pi-hole` internos como DNS primario/secundario del router en la primera etapa
  - mantener un resolvedor público de emergencia como respaldo inmediato

## Objetivo final

- `Pi-hole` primario en `management`
- `Pi-hole` secundario en `orangepi5-ultra`
- `orangepi5-max` como terciario opcional, no obligatorio
- `split-horizon DNS` local para que las mismas URLs globales resuelvan al proxy local de la sede

## Decisiones cerradas

- el router mantiene siempre el servicio DHCP; `Pi-hole` no reemplaza DHCP en ninguna fase
- el router entrega DNS por DHCP así:
  - `DNS1` = `Pi-hole` primario cuando esté validado
  - `DNS2` = `1.1.1.1` como fallback de emergencia
- `orangepi5-ultra` sigue siendo `Pi-hole` secundario de la arquitectura, pero no será `DNS2` del router en la primera etapa
- no se introduce VIP `keepalived` en la primera fase
- paneles de Pi-hole se gestionan por red privada/Tailscale
- `80/443` quedan reservados para `Caddy/reverse proxy`
- `8080` queda reservado para `Homepage` principal
- `8081` queda reservado para `Emergency Homepage`
- `Colibrí` y `Perú` usarán las mismas URLs globales bajo `white-enciso.com`
- la respuesta DNS local por sede debe priorizar el proxy local
- el cutover DNS del router ocurre solo después de validar respuestas por IP directa
- no se cambia DNS del router en la misma ventana que reservas DHCP o cambios de IP finales
- la primera etapa segura prioriza continuidad de Internet doméstico sobre filtrado perfecto

## Interfaces

- primario: `management`
- secundario: `orangepi5-ultra`
- controlador de cutover DNS: `management`
- canary principal de rollback: `orangepi5-ultra`
- canary secundario opcional: `orangepi5-max`
- secreto local esperado en `management`: `/opt/colibri-secrets/router.env`
- script operativo esperado en `management`: `/opt/colibri/bin/router-dns-cutover-with-rollback.sh`
- sincronización futura de listas y configuración: herramienta por definir en fase posterior, no bloquea el diseño

## Flujos

### Normal

- primero se valida `Pi-hole` por IP directa en modo staged, sin tocar router;
- el router conserva DHCP y solo reparte servidores DNS a clientes;
- clientes consultan `DNS1` en `management`;
- si `DNS1` falla o tarda demasiado, el cliente puede caer a `DNS2 = 1.1.1.1`;
- `orangepi5-ultra` queda como secundario arquitectónico para pruebas, validación y futura sincronización, no como dependencia del primer cutover del router;
- DNS local resuelve `paperless`, `immich`, `jellyfin`, `navidrome`, `home` y `auth` hacia el proxy local.

### Falla

- si cae `management`, los clientes siguen navegando por `DNS2 = 1.1.1.1`, aunque pierdan filtrado y split-horizon local;
- si cae `ultra`, la etapa 1 sigue operable porque no depende de él como `DNS2` del router;
- si ambos `Pi-hole` caen, la red mantiene salida a Internet por el fallback público mientras se restaura el filtrado;
- si cae el enlace inter-sede, la resolución local sigue funcionando sin depender del otro sitio.
- si el cambio de DNS del router genera problema, rollback inmediato al DNS anterior del router

## Aceptación

- primario y secundario responden consultas locales por IP directa;
- la migración del router tiene un orden seguro documentado y rollback simple;
- configuración del router refleja `DNS1 = Pi-hole` y `DNS2 = 1.1.1.1` solo después de la validación staged;
- el router sigue siendo autoridad DHCP durante toda la etapa;
- el diseño no depende de VIP desde el día uno.

## Prechecks mínimos

- `Pi-hole` primario responde por IP directa
- `Pi-hole` secundario responde por IP directa
- router conserva DHCP habilitado
- `DNS2` público de emergencia definido
- canary real disponible
- script de cutover y rollback probado al menos en dry-run lógico
- no mezclar el cambio con reservas DHCP o renumeración de IPs

## Rollback

- restaurar inmediatamente el DNS previo del router
- no tocar contenedores `Pi-hole` durante el rollback
- si el cutover falla, mantener `Pi-hole` staged y depurar fuera de la ruta crítica

## Dependencias previas

- red y direccionamiento final
- blackout y nodo `ultra` definidos

## Fuera de fase

- VIP `keepalived`
- anycast DNS

## Politica de puertos

- `80/443`: `Caddy/reverse proxy`
- `8080`: `Homepage` principal
- `8081`: `Emergency Homepage`
- `8100-8199`: `core infra UIs`
- `8200-8299`: `DNS/Pi-hole/red`
- `8300-8399`: `observability/alerting`
- `8400-8499`: `identity/security`
- `8500-8599`: `user apps`
- `8600-8699`: `media apps`
- `8700-8799`: `AI/agents`
- `8800-8899`: `admin tools/Docker`

## `05A` — Pi-hole staged validation, sin tocar router

Resultado factual de `05A`:

- `management` si tiene un contenedor `Pi-hole` sano, con persistencia en `/opt/stacks/pihole-primary`
- el baseline real en `management` ya contiene:
  - `StevenBlack` deshabilitada
  - `OISD small` habilitada
- el `Pi-hole` de `management` no esta publicado al host:
  - `192.168.0.10:53` responde `connection refused`
  - `192.168.0.10:8080` no responde
- `orangepi5-ultra` no quedo validado como `Pi-hole` secundario en esta fase:
  - `192.168.0.14:53` responde `connection refused`
  - `192.168.0.14:8080` actualmente responde `ntfy`, no `Pi-hole`
- `orangepi5-max` queda solo como terciario objetivo, no validado:
  - `192.168.0.15:53` responde `connection refused`
  - `192.168.0.15:8080` no responde
  - no quedo validacion por `SSH` en esta fase

Conclusion de `05A`:

- `prep-needed / no-go` para `05B`
- no hace falta tocar router para verlo
- primero hay que reconciliar el staged real con el playbook aprobado:
  - exponer `management` en `192.168.0.10:53` y `:8080`
  - resolver el conflicto de `orangepi5-ultra:8080` con `ntfy`
  - validar acceso y staged de `orangepi5-max`

Guardrail de salida:

- no cambiar `DNS` del router
- no usar `orangepi5-ultra` como `DNS2` del router en este estado

## `05A.0` — Port registry y service exposure policy

Resultado factual de `05A.0`:

- politica de puertos definida por familias
- `80/443` reservados para `Caddy/reverse proxy`
- `8080` reservado para `Homepage` principal
- `8081` reservado para `Emergency Homepage`
- `ntfy-local` en `orangepi5-ultra:8080` queda como `active debt`; no se mueve en esta fase
- `Pi-hole` staged cambia su UI objetivo a:
  - `management` `192.168.0.10:8200`
  - `orangepi5-ultra` `192.168.0.14:8201`
  - `orangepi5-max` `192.168.0.15:8202`

Reconciliacion del primario:

- `management` ahora si expone:
  - `192.168.0.10:53/tcp`
  - `192.168.0.10:53/udp`
  - `192.168.0.10:8200 -> :80` del contenedor
- validacion directa:
  - `dig @192.168.0.10 cloudflare.com`: `ok`
  - `dig @192.168.0.10 google.com`: `ok`
  - `curl http://192.168.0.10:8200/admin`: `308` hacia `/admin/`

Bloqueos restantes:

- `orangepi5-ultra` sigue con conflicto de puerto:
  - `192.168.0.14:8080` hoy es `ntfy-local`
  - `Pi-hole` secundario debe ir a `8201`
- `orangepi5-max` sigue libre para `8202`, pero no despliega `Pi-hole` todavia

Conclusion de `05A.0`:

- `management` primario staged: `ready`
- `05A` completo primario+secundario+terciario: todavia `no-go`
- el siguiente paso sano es reconciliar `orangepi5-ultra` a `8201` sin mover `ntfy` fuera de una fase dedicada

## `05A.1` — Reconciliar Pi-hole primary en `management`

Resultado factual de `05A.1`:

- `Pi-hole` primario en `management` ya responde por IP directa:
  - `192.168.0.10:53/tcp`
  - `192.168.0.10:53/udp`
  - `192.168.0.10:8200/admin`

Causa raiz del `connection refused` observado en `05A`:

- el `docker-compose.yml` ya declaraba puertos hacia el host
- pero el contenedor `pihole` en ejecucion no habia sido recreado con esos bindings
- por eso `docker-compose.yml` y `ss -lntup` no reflejaban el mismo estado operativo

Correccion aplicada:

- backup local del compose en `/opt/stacks/pihole-primary`
- cambio de UI de `8080` a `8200`
- `docker compose up -d --force-recreate pihole`

Estado final:

- `docker ps` muestra:
  - `192.168.0.10:53->53/tcp`
  - `192.168.0.10:53->53/udp`
  - `192.168.0.10:8200->80/tcp`
- `ss -lntup` confirma `192.168.0.10:53` y `192.168.0.10:8200`
- baseline conservadora mantenida:
  - `StevenBlack` deshabilitada
  - `OISD small` habilitada
- validacion:
  - `dig @192.168.0.10 cloudflare.com`: `ok`
  - `dig @192.168.0.10 google.com`: `ok`
  - `curl http://192.168.0.10:8200/admin`: `308` a `/admin/`

Conclusion de `05A.1`:

- primario `management`: `ready`
- repetir `05A` staged validation completa: `no-go` todavia, hasta reconciliar `orangepi5-ultra`

## `05A.2` — Reconciliar Pi-hole secondary en `orangepi5-ultra`

Resultado factual de `05A.2`:

- `Pi-hole` secundario en `orangepi5-ultra` ya responde por IP directa:
  - `192.168.0.14:53/tcp`
  - `192.168.0.14:53/udp`
  - `192.168.0.14:8201/admin`
- `ntfy-local` permanece intacto en `192.168.0.14:8080`

Causa raiz del bloqueo anterior:

- si existia stack versionado aprobado en `/srv/storage/appdata/pihole-secondary`
- pero el compose apuntaba a una IP vieja:
  - `192.168.0.51:53`
  - `192.168.0.51:8080`
- ademas la UI chocaba con la politica nueva, porque `8080` ya queda reservado para `Homepage`

Correccion aplicada:

- backup local del compose
- cambio de bindings a:
  - `192.168.0.14:53/tcp`
  - `192.168.0.14:53/udp`

## `05B` — Canary DNS por cliente manual

Resultado factual de `05B`:

- el cliente canary `bd795m` (`192.168.0.18`) valido `Pi-hole` primario como `DNS` real sin tocar router
- DNS anterior del canary:
  - `192.168.0.1`
- DNS temporal aplicado manualmente:
  - `192.168.0.10`
  - `1.1.1.1`
- el canary mantuvo Internet y `Pi-hole` registro queries reales desde `192.168.0.18`
- `split-horizon` sigue `pending`; los nombres internos staged devolvieron `NXDOMAIN` o ausencia de entrada local

Conclusiones de `05B`:

- `Pi-hole` primario puede usarse como `DNS1` real de clientes
- el fallback publico `1.1.1.1` es razonable para el cutover del router
- `05C` queda `go`

## `05C` — Router DNS cutover con rollback

Resultado factual de `05C`:

- el `ER707-M2` conserva `DHCP` habilitado en el pool `LAN`
- el DNS del router se cambio de forma controlada a:
  - `DNS1 = 192.168.0.10`
  - `DNS2 = 1.1.1.1`
- el estado previo real del router era:
  - sin `pri_dns/snd_dns` explicitos en `show dhcp server`
  - clientes observados usando `192.168.0.1` como resolvedor efectivo
- el helper existente en `management` se trato como herramienta asistida, no como autoridad de rollback:
  - `/opt/colibri-secrets/router.env` seguia con `TARGET_DNS2=192.168.0.51`
  - `CANARY_HOST=192.168.0.152`
  - `show dhcp server` no permitia capturar automaticamente el DNS previo

Validacion post-cutover:

- canary principal `bd795m`:
  - renovo red por `NetworkManager`
  - quedo usando `192.168.0.10`
  - resolvio `cloudflare.com`, `google.com` y `pi-hole.net`
  - mantuvo navegacion basica
  - `Pi-hole` registro queries reales desde `192.168.0.18`
- segundo cliente controlado `orangepi5-max`:
  - renovo red con `networkctl renew`
  - quedo usando `192.168.0.10`
  - mantuvo salida a Internet
  - `Pi-hole` registro queries reales desde `192.168.0.15`

Caveat operativo importante:

- aunque el router quedo configurado con `DNS2 = 1.1.1.1`, los dos clientes renovados solo mostraron `192.168.0.10` como `DNS` recibido/activo
- por eso el cutover queda validado para `DNS1 = Pi-hole`, pero la propagacion efectiva del fallback `DNS2` a clientes sigue como observacion pendiente
- esto no obliga a rollback mientras los clientes mantengan Internet y `Pi-hole` siga sano, pero si debe vigilarse antes de vender alta disponibilidad de `DNS` al nivel del lease DHCP

Rollback documentado:

- restaurar el router al estado previo:
  - `ip dhcp server pool LAN`
  - `no dns-server`
- renovar red en el canary
- confirmar que el cliente vuelve a usar `192.168.0.1` como resolvedor efectivo
- no tocar contenedores `Pi-hole` durante rollback

Conclusiones de `05C`:

- cutover del router: `pass with DNS2 propagation caveat`
- `DHCP` sigue en el `ER707-M2`
- `Pi-hole` primario ya esta en uso real por clientes LAN
- `split-horizon` sigue `pending`
- `05D` estabilidad post-cutover: `go`, con seguimiento explicito del caveat de `DNS2`

## `05D` — Post-cutover observation and DNS2 propagation investigation

Resultado factual de `05D`:

- el cutover sigue estable despues de la ventana inicial
- `Pi-hole` primario en `management` sigue resolviendo por `192.168.0.10`
- `bd795m` y `orangepi5-max` siguen navegando y generando queries reales en `Pi-hole`
- `split-horizon` sigue `pending`, sin tratarse como fallo

Evidencia observada en clientes:

- `bd795m`:
  - `resolvectl status enp6s0` muestra:
    - `Current DNS Server: 192.168.0.10`
    - `DNS Servers: 192.168.0.10`
  - `nmcli device show enp6s0` muestra:
    - `IP4.DNS[1]: 192.168.0.10`
- `orangepi5-max`:
  - `resolvectl status enP3p49s0` muestra:
    - `Current DNS Server: 192.168.0.10`
    - `DNS Servers: 192.168.0.10`
  - `/run/systemd/netif/leases/2` muestra:
    - `DNS=192.168.0.10`

Evidencia observada del lado del router:

- el `ER707-M2` sigue con `DHCP` habilitado en el pool `LAN`
- el router conserva la intencion configurada de:
  - `DNS1 = 192.168.0.10`
  - `DNS2 = 1.1.1.1`
- pero la evidencia mas fuerte util en esta fase vino de los leases efectivos de cliente, no del parser `CLI` del router

Conclusion de `05D`:

- la conclusion mas probable y operativamente util es:
  - `B. DNS2 no se entrega por DHCP`
- no parece ser solo un tema de “el cliente muestra el DNS activo”
- en al menos dos stacks distintos de cliente:
  - `NetworkManager` en `bd795m`
  - `systemd-networkd` en `orangepi5-max`
  solo se observa `192.168.0.10`
- por ahora, `1.1.1.1` queda confirmado como configuracion del router, pero no como segundo `DNS` efectivamente recibido por clientes

Implicacion operativa:

- `Pi-hole` primario sigue siendo suficientemente estable para continuar
- pero no se debe asumir todavia que el fallback publico ya esta distribuido por `DHCP`
- si se desea alta confianza en fallback DNS por cliente, hara falta una inspeccion posterior mas profunda del `ER707-M2`

Veredicto:

- estabilidad post-cutover: `pass`
- investigacion de `DNS2`: `B. no se entrega por DHCP`
- `05E` preparar `split-horizon` local records: `go`

## `05E` — Split-horizon local records staged

Decision explicita de esta fase:

- el proxy local futuro de Colibri sigue planeado en `management`
- como `Caddy/proxy` aun no esta activo, los hostnames staged se apuntan al placeholder del proxy local futuro
- IP objetivo elegida:
  - `192.168.0.10`

Registros staged creados:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Todos apuntan a:

- `192.168.0.10`

Implementacion real:

- `Pi-hole v6` no estaba respondiendo desde `custom.list`
- la ruta correcta fue poblar `dns.hosts` en `pihole.toml`
- se hicieron backups previos en:
  - `/opt/stacks/pihole-primary/etc-pihole/pihole.toml`
  - `/srv/storage/appdata/pihole-secondary/etc-pihole/pihole.toml`
- se replicaron manualmente los mismos seis registros en:
  - `management`
  - `orangepi5-ultra`

Validacion:

- `dig @192.168.0.10 <hostname>` responde `192.168.0.10`
- `dig @192.168.0.14 <hostname>` responde `192.168.0.10`
- desde el cliente canary `bd795m` usando `Pi-hole` por `DHCP`:
  - `resolvectl query <hostname>` responde `192.168.0.10`
  - `dig <hostname>` responde `192.168.0.10`
- resolucion externa sigue sana:
  - `cloudflare.com` sigue resolviendo
  - navegacion basica sigue `ok`
- `Pi-hole` primario sigue registrando queries reales del canary para los nombres staged

Lectura operativa:

- `split-horizon` local queda `staged-ready`
- esta fase valida la capa `DNS` local, no la capa `proxy` ni la disponibilidad real de cada app por hostname
- los hostnames staged apuntan a `192.168.0.10` solo como placeholder del futuro `Caddy` local en `management`
- esto no implica que las apps vivan en `management`
- los backends reales previstos siguen siendo:
  - `Jellyfin` en `ai-gpu`
  - `Paperless`, `Immich core`, `Navidrome` y `auth/authentik` en `services`
  - `home` en `management` o donde se cierre despues
- hasta `Microplan 06`, estos hostnames pueden resolver localmente pero no necesariamente servir contenido correcto aun

Caveats:

- `192.168.0.10` es placeholder del proxy local futuro, no confirmacion de que las apps ya respondan ahi
- no se agregaron hostnames admin opcionales como:
  - `ntfy.white-enciso.com`
  - `pihole.white-enciso.com`

Nota posterior:

- `Microplan 06B` si agrega `ntfy.white-enciso.com` al `split-horizon` local
- el registro sigue apuntando a `192.168.0.10`, pero ya como entrada real hacia `Caddy` local en `management`

Veredicto:

- `05E`: `pass`
- `split-horizon` local staged: `ready`
- `05F` observacion post split-horizon o cleanup de deuda/helper del router: `go`

## `05F` — Post split-horizon observation and closure

Resultado factual de `05F`:

- el cliente canary sigue resolviendo externos sin degradacion
- los hostnames staged siguen resolviendo localmente a `192.168.0.10`
- `Pi-hole` primario y secundario siguen sanos
- `ntfy-local` sigue intacto en `192.168.0.14:8080`
- no se toco router ni `DHCP` en esta fase

Validacion final:

- desde cliente canary:
  - `cloudflare.com` y `google.com` siguen resolviendo
  - `home`, `auth`, `jellyfin`, `paperless`, `immich` y `navidrome.white-enciso.com` resuelven a `192.168.0.10`
- validacion directa:
  - `dig @192.168.0.10 cloudflare.com`: `ok`
  - `dig @192.168.0.10 home.white-enciso.com`: `192.168.0.10`
  - `dig @192.168.0.14 cloudflare.com`: `ok`
  - `dig @192.168.0.14 home.white-enciso.com`: `192.168.0.10`
- UIs:
  - `http://192.168.0.10:8200/admin`: `308` a `/admin/`
  - `http://192.168.0.14:8201/admin`: `308` a `/admin/`
  - `http://192.168.0.14:8080`: `200 OK` de `ntfy-local`
- `Pi-hole` primario sigue registrando queries reales del canary para los hostnames staged

Caveats remanentes:

- `DNS2 = 1.1.1.1` sigue como caveat del router:
  - configurado en el `ER707-M2`
  - no observado en leases efectivos de cliente
  - no se asume fallback publico entregado por `DHCP`
  - la continuidad actual se apoya en:
    - `Pi-hole` primario estable
    - `Pi-hole` secundario validado por IP directa
    - rollback manual del router con `no dns-server`
    - configuracion manual de `DNS` secundario en clientes criticos si fuera necesario
  - hipotesis pendiente:
    - comportamiento especifico de `Omada` al mezclar `DNS` local + `DNS` publico
    - la interaccion de clientes Linux/Tailscale puede afectar presentacion u orden, pero no explica por si sola el lease efectivo observado
- `split-horizon` staged sigue apuntando a `192.168.0.10` solo como placeholder del futuro `Caddy` local
- hasta `Microplan 06`, resolver por hostname no implica servir contenido correcto aun

Cierre de `Microplan 05`:

- `Microplan 05` queda `completed / staged-ready`
- `Pi-hole` primario y secundario estan operativos
- `DNS` LAN ya usa `Pi-hole` primario como resolvedor efectivo
- `split-horizon` local staged queda listo para conectar con `Microplan 06`

Recomendacion:

- `Microplan 06` puede arrancar sobre esta base para:
  - activar `Caddy` local
  - enrutar cada hostname al backend real correspondiente
  - `192.168.0.14:8201 -> :80`
- `docker compose up -d --force-recreate pihole`

Estado final:

- `docker ps` muestra:
  - `192.168.0.14:53->53/tcp`
  - `192.168.0.14:53->53/udp`
  - `192.168.0.14:8201->80/tcp`
- `ss -lntup` confirma:
  - `192.168.0.14:53`
  - `192.168.0.14:8201`
  - `192.168.0.14:8080` sigue siendo `ntfy-local`
- baseline conservadora mantenida:
  - `StevenBlack` deshabilitada
  - `OISD small` habilitada
- validacion:
  - `dig @192.168.0.14 cloudflare.com`: `ok`
  - `dig @192.168.0.14 google.com`: `ok`
  - `curl http://192.168.0.14:8201/admin`: `308` a `/admin/`
  - `curl http://192.168.0.14:8080`: `200 OK` de `ntfy`

Conclusion de `05A.2`:

- primario `management`: `ready`
- secundario `orangepi5-ultra`: `ready`
- terciario `orangepi5-max`: sigue opcional y `future`
- repetir `05A` staged validation para primario+secundario: `go`

## Cierre de `05A`

- `05A` queda validado para:
  - `management` como primario
  - `orangepi5-ultra` como secundario
- ambos responden por IP directa en `:53`
- ambas UIs responden en:
  - `8200` para `management`
  - `8201` para `orangepi5-ultra`
- `ntfy-local` sigue intacto en `192.168.0.14:8080`
- `split-horizon DNS` local sigue `pending`; no bloquea el canary manual por cliente

## `05B` — Canary DNS por cliente manual

Resultado factual de `05B`:

- cliente canary usado: `bd795m` (`CachyOS`, `192.168.0.18`)
- DNS anterior del canary:
  - `192.168.0.1`
- DNS canary aplicado temporalmente:
  - `DNS1 = 192.168.0.10`
  - `DNS2 = 1.1.1.1`
- validacion real:
  - resolucion externa `ok`
  - UI de `Pi-hole` primary ya funcional
  - queries visibles en `Pi-hole` desde `192.168.0.18`
- `split-horizon` sigue `pending`:
  - consultas locales devuelven `NXDOMAIN`, documentado como pendiente
- rollback del cliente canary: probado y exitoso

Conclusion de `05B`:

- canary manual por cliente: `pass`
- `05C` cutover DNS del router con `DNS1=192.168.0.10` y `DNS2=1.1.1.1`: `go`
