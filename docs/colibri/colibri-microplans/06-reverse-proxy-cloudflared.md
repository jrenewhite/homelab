# Microplan 06 — Reverse Proxy y `cloudflared`

## Propósito

Definir exposición externa e interna de servicios con `Caddy` y `cloudflared`.

## Estado actual

- dominio y túnel existentes en Cloudflare
- no hay despliegue final aprobado de `Caddy`/`cloudflared`

## Objetivo final

- `management` como proxy principal y conector principal del túnel
- `orangepi5-ultra` como backup proxy/conector
- servicios administrativos sensibles solo por red privada
- mismas URLs globales para la experiencia normal de usuario

## Decisiones cerradas

- proxy interno principal: `Caddy`
- túnel externo: `cloudflared`
- ambos nodos pueden participar en el mismo túnel para redundancia
- `SSO` no reemplaza al proxy; se integra detrás de `Caddy` o a través del proxy cuando aplique
- internamente, cada sitio resuelve las mismas URLs globales hacia su proxy local
- externamente, `Cloudflare` es la entrada y decide hacia sitio sano o preferido
- primero se valida cada backend por IP o URL privada antes de publicarlo por proxy o túnel
- no se publica un servicio por Cloudflare en la misma ventana que cambios de DNS local o IP del host
- no se expone:
  - Portainer
  - admin NAS
  - Grafana/Prometheus
  - SSH
  - APIs internas de WOL/shutdown

## Interfaces

### Exposición candidata

- `home.white-enciso.com` -> dashboard local por sitio
- `auth.white-enciso.com` -> `authentik` en `Colibrí` al inicio
- `hermes.white-enciso.com` -> `services`
- `paperless.white-enciso.com` -> `services`
- `immich.white-enciso.com` -> `services`
- `jellyfin.white-enciso.com` -> `ai-gpu`
- `navidrome.white-enciso.com` -> `services`
- `ha.white-enciso.com` -> `orangepi5-ultra`
- `matrix` queda fuera de la regla general si se despliega por sede como homeserver federado distinto

## Flujos

### Normal

- Internet -> Cloudflare -> `cloudflared` -> `Caddy` -> backend interno
- LAN local -> DNS local -> `Caddy` local -> backend local
- cada hostname nuevo entra primero en validación privada, luego en exposición externa controlada

### Falla

- si cae `management`, `ultra` asume conector/proxy backup para servicios compatibles;
- si cae `services`, los hostnames de apps que viven ahí deben marcarse unhealthy.
- si cae `Colibrí` completo, la capa externa puede preferir `Perú` para los servicios que tengan réplica aprobada.

## Aceptación

- tabla de hostnames a backend aprobada;
- lista explícita de servicios solo por Tailscale aprobada;
- takeover limitado entre `management` y `ultra` documentado.

## Prechecks mínimos

- backend funcional por IP privada o URL interna
- DNS local coherente para el hostname a publicar
- secreto de Cloudflare disponible y con permisos mínimos
- servicio aún no expuesto al público general
- no mezclar el publish con cambio de DNS local o renumeración del host

## Rollback

- retirar el hostname del proxy o del túnel
- dejar el servicio solo por acceso privado
- si falla una publicación, no se toca el resto de hostnames en la misma ventana

## Dependencias previas

- DNS
- direccionamiento
- estrategia de `SSO` aprobada

## Fuera de fase

- VIP futura
- balanceo L7 complejo

## `06A` — Caddy local-only placeholder

Resultado factual de `06A`:

- `Caddy` ya quedo instalado en `management` como proxy local-only
- puertos observados antes del cambio:
  - `80`, `443` y `8080` libres en `management`
- en esta fase solo se activo:
  - `80/tcp`
- no se activo:
  - `cloudflared`
  - `TLS` publico
  - backends reales

Hostnames staged servidos por placeholder:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Implementacion:

- `Caddy` instalado por paquete del sistema en `management`
- `Caddyfile` local-only en `/etc/caddy/Caddyfile`
- `auto_https off`
- `admin off`
- respuesta `HTTP 200` controlada para cada hostname staged

Validacion:

- `curl http://home.white-enciso.com`: `200 OK`
- `curl http://auth.white-enciso.com`: `200 OK`
- `curl http://jellyfin.white-enciso.com`: `200 OK`
- `curl http://paperless.white-enciso.com`: `200 OK`
- `curl http://immich.white-enciso.com`: `200 OK`
- `curl http://navidrome.white-enciso.com`: `200 OK`
- `Caddy` queda `active (running)`
- `ss -lntup` muestra `*:80`

Lectura operativa:

- `06A` valida la capa de proxy local minimo
- los hostnames staged ya no solo resuelven; ahora tambien responden localmente en `HTTP`
- esto sigue siendo placeholder controlado:
  - no conecta apps reales
  - no publica nada a Internet
  - no implica `SSO`

Caveats:

- el placeholder actual responde texto simple, no backend real
- no se habilito `443`
- no se emitieron certificados
- `cloudflared` sigue fuera de fase

Veredicto:

- `06A`: `pass`
- `06B` conectar primer backend real local: `go`

## `06A.1` — Migracion de `ntfy-local` al rango de alerting

Resultado factual de `06A.1`:

- `ntfy-local` ya no usa `192.168.0.14:8080`
- `ntfy-local` ahora queda expuesto en:
  - `http://192.168.0.14:8300`
- `8080` vuelve a quedar limpio para el `Homepage` principal segun la politica de puertos

Implementacion observada:

- `ntfy-local` sigue corriendo en `orangepi5-ultra` como contenedor Docker directo/manual
- no se migro aun a `Docker Compose` versionado
- se actualizo `server.yml` persistido para usar:
  - `base-url: http://192.168.0.14:8300`
- el contenedor se recreo solo con cambio de publicacion de puerto:
  - `192.168.0.14:8300 -> 80/tcp`

Integracion `NUT`:

- se actualizo `/opt/colibri-secrets/ntfy.env` en:
  - `management`
  - `services`
  - `nas`
  - `ai-gpu`
  - `orangepi5-ultra`
- el endpoint efectivo pasa a ser:
  - `NTFY_URL=http://192.168.0.14:8300/colibri-ups-33883960f764a3bf`

Validacion:

- `curl http://192.168.0.14:8300/`: `200 OK`
- `curl http://192.168.0.14:8080/`: sin respuesta de `ntfy-local`
- `nut-server` y `nut-monitor` siguen sanos en `management`
- `nut-monitor` sigue sano en `services`
- pruebas sinteticas no destructivas desde `management` y `services` siguieron generando `nut-event`
- `docker logs` de `ntfy-local` mostro incremento de `messages_published` tras la migracion

Caveats:

- la deuda tecnica de `ntfy-local` como contenedor directo/manual sigue vigente hasta migrarlo a stack versionado
- la invocacion manual del hook como usuario no privilegiado no puede leer `/opt/colibri-secrets/ntfy.env`; la validacion real de entrega se hizo con ejecucion privilegiada y el logger local siguio funcionando incluso al forzar fallo de `ntfy`

Lectura operativa:

- `06A.1` cierra el conflicto de puerto con `Homepage`
- no toca `Caddy`, `Pi-hole`, `router` ni politicas de energia
- deja la capa de alerting en el rango reservado `8300-8399`

## `06A.2` — Caddy config governance

Resultado factual de `06A.2`:

- la configuracion de `Caddy` ya tiene fuente de verdad versionada en el repo
- `management` queda como runtime, no como origen de edicion
- la estructura modular creada es:
  - `infra/colibri/caddy/Caddyfile`
  - `infra/colibri/caddy/snippets/`
  - `infra/colibri/caddy/sites/`
  - `infra/colibri/caddy/README.md`

Implementacion:

- `Caddyfile` principal con:
  - `auto_https off`
  - `admin off`
  - `import snippets/*.caddy`
  - `import sites/*.caddy`
- snippets comunes iniciales:
  - `common_headers`
  - `placeholder_response`
- sitios actuales movidos a archivos separados en `sites/`:
  - `home.white-enciso.com`
  - `auth.white-enciso.com`
  - `jellyfin.white-enciso.com`
  - `paperless.white-enciso.com`
  - `immich.white-enciso.com`
  - `navidrome.white-enciso.com`

Runtime en `management`:

- `/etc/caddy/Caddyfile`
- `/etc/caddy/snippets/*.caddy`
- `/etc/caddy/sites/*.caddy`

Validacion:

- `caddy validate --config /etc/caddy/Caddyfile`: `Valid configuration`
- placeholders siguen respondiendo `HTTP 200`
- headers observados:
  - `X-Colibri-Proxy: caddy-local-only`
  - `X-Colibri-Phase: 06A.2`

Caveat operativo:

- con `admin off`, `systemctl reload caddy` falla porque el paquete intenta usar el admin API interno
- el patron sano para esta fase queda:
  - `caddy validate`
  - `systemctl restart caddy`

Lectura operativa:

- `06A.2` deja a `git` como fuente de verdad para la capa local de proxy
- no activa `TLS`
- no activa `cloudflared`
- no conecta aun backends reales

Veredicto:

- `06A.2`: `pass`
- `06B` conectar primer backend real local: `go`

## `06B` — Primer backend real local con `Caddy`

Resultado factual de `06B`:

- primer backend real conectado:
  - `ntfy.white-enciso.com`
- proxy local:
  - `management` `192.168.0.10`
- backend real:
  - `http://192.168.0.14:8300`

Prechecks cumplidos:

- `ntfy-local` respondia por IP directa en `192.168.0.14:8300`
- `Caddy` seguia `active`
- los placeholders existentes seguian respondiendo
- `8080` seguia libre para `Homepage`

DNS local:

- `ntfy.white-enciso.com` se agrego en `Pi-hole` primario y secundario
- ambos devuelven:
  - `192.168.0.10`

Configuracion versionada:

- se agrego:
  - `infra/colibri/caddy/sites/ntfy.caddy`
- contenido efectivo:
  - `http://ntfy.white-enciso.com { reverse_proxy 192.168.0.14:8300 }`

Aplicacion a runtime:

- el site versionado se sincronizo a:
  - `/etc/caddy/sites/ntfy.caddy`
- validacion:
  - `caddy validate --config /etc/caddy/Caddyfile`: `Valid configuration`
- reinicio efectivo:
  - `systemctl restart caddy`
  - `caddy` quedo `active`

Validacion funcional:

- `dig ntfy.white-enciso.com`: `192.168.0.10`
- `curl http://ntfy.white-enciso.com/`: `HTTP 200`
- `POST` sintetico por hostname:
  - `http://ntfy.white-enciso.com/colibri-ups-33883960f764a3bf`
  - devolvio evento JSON valido de `ntfy`
- `ntfy-local` siguio respondiendo por IP directa:
  - `http://192.168.0.14:8300/`
- los placeholders `home`, `auth`, `jellyfin`, `paperless`, `immich` y `navidrome` siguieron respondiendo sin cambios

Lectura operativa:

- `06B` conecta el primer backend real local sin activar `TLS`, `cloudflared` ni exposicion publica
- `ntfy.white-enciso.com` ya no es solo placeholder DNS; ahora es un servicio local funcional a traves de `Caddy`

Veredicto:

- `06B`: `pass`
- `06C`: `go`

## `06C` — Caddy service pattern and reverse proxy conventions

Resultado factual de `06C`:

- el patron de configuracion `Caddy` queda estandarizado antes de conectar mas backends
- la fuente de verdad sigue en:
  - `infra/colibri/caddy`
- `management` sigue siendo solo runtime

Convenciones cerradas:

- un archivo por hostname o servicio en `sites/`
- comentarios cortos por archivo con:
  - `hostname`
  - `pattern`
  - `backend`
  - `nodo`
  - `puerto`
- snippets reutilizables base:
  - `common_headers`
  - `local_only`
  - `proxy_headers`
  - `placeholder_response`
- flujo oficial:
  - editar en repo
  - sincronizar a `/etc/caddy`
  - `caddy validate`
  - `systemctl restart caddy`
  - probar con `curl`

Cambios funcionales no disruptivos:

- placeholders siguen igual, pero ahora responden con:
  - `X-Colibri-Phase: 06C`
- `ntfy.white-enciso.com` sigue operativo por hostname
- `proxy_headers` se redujo a lo minimo util para evitar warnings redundantes de `Caddy`

Validacion:

- `caddy validate --config /etc/caddy/Caddyfile`: `Valid configuration`
- `systemctl restart caddy`: `active`
- `curl http://ntfy.white-enciso.com/`: `200 OK`
- `POST` sintetico por hostname a `ntfy`: `ok`
- placeholders `home`, `auth`, `jellyfin`, `paperless`, `immich`, `navidrome`: `HTTP 200`

Lectura operativa:

- `06C` no conecta backends nuevos
- `06C` no activa `TLS`
- `06C` no activa `cloudflared`
- deja lista una base repetible para `Colibri` y luego para `Peru`

Veredicto:

- `06C`: `pass`
- `06D` conectar `Homepage` o segundo backend real: `go`

## `06D` — Homepage como segundo backend real local

Resultado factual de `06D`:

- `Homepage` ya queda desplegado en `management`
- backend local:
  - `http://127.0.0.1:8080`
- hostname real por `Caddy`:
  - `home.white-enciso.com`

Implementacion elegida:

- `Homepage` desplegado con Docker Compose
- fuente de verdad versionada en:
  - `infra/colibri/homepage`
- runtime desplegado en:
  - `/opt/stacks/homepage`

Configuracion `Caddy`:

- el placeholder previo de `home.white-enciso.com` se reemplaza por backend real
- site versionado:
  - `infra/colibri/caddy/sites/home.caddy`
- backend efectivo:
  - `reverse_proxy 127.0.0.1:8080`

Validacion:

- `curl http://127.0.0.1:8080/`: `200 OK`
- `curl http://home.white-enciso.com/`: `200 OK`
- `curl http://ntfy.white-enciso.com/`: `200 OK`
- placeholders restantes:
  - `auth`
  - `jellyfin`
  - `paperless`
  - `immich`
  - `navidrome`
  - siguen `HTTP 200`
- `caddy validate --config /etc/caddy/Caddyfile`: `Valid configuration`
- `systemctl restart caddy`: `active`

Lectura operativa:

- `home.white-enciso.com` ya no es placeholder
- `Homepage` queda como segundo backend real local
- no se activa `TLS`
- no se activa `cloudflared`
- no se conecta ningun backend adicional en esta fase

Veredicto:

- `06D`: `pass`
- `06E`: `go`

## `06E` — Curacion inicial de `Homepage`

Resultado factual de `06E`:

- la configuracion versionada de `Homepage` queda curada con una vista inicial util para `Colibri`
- no se agregan secretos
- no se conectan nuevos backends reales

Secciones creadas:

- `Core / Operations`
- `Network / DNS`
- `Alerts / Energy`
- `Apps staged`
- `Media staged`
- `Admin / Future`

Estado reflejado en la vista:

- activos:
  - `home.white-enciso.com`
  - `ntfy.white-enciso.com`
  - `Pi-hole Primary`
  - `Pi-hole Secondary`
- staged:
  - `auth.white-enciso.com`
  - `paperless.white-enciso.com`
  - `immich.white-enciso.com`
  - `jellyfin.white-enciso.com`
  - `navidrome.white-enciso.com`

Archivos modificados:

- `infra/colibri/homepage/config/settings.yaml`
- `infra/colibri/homepage/config/services.yaml`
- `infra/colibri/homepage/config/bookmarks.yaml`
- `infra/colibri/homepage/config/widgets.yaml`

Validacion:

- `curl http://127.0.0.1:8080/`: `200 OK`
- `curl http://home.white-enciso.com/`: `200 OK`
- `curl http://ntfy.white-enciso.com/`: `200 OK`
- placeholders restantes siguen `HTTP 200`

Caveat:

- `curl` permite confirmar reachability y parte del contenido renderizado, pero la revision visual en navegador sigue siendo recomendable para validar la presentacion final del dashboard

Veredicto:

- `06E`: `pass`
- siguiente backend real local: `go`

## `06F` — Local hostname exposure policy

Resultado factual de `06F`:

- no se conectan backends nuevos
- no se cambian registros DNS ni comportamiento de `Caddy`
- queda definida la politica local de exposicion por hostname antes de abrir mas servicios o preparar exposicion publica futura

Clasificacion cerrada:

| Hostname | Clasificacion | Estado actual | Politica actual |
|---|---|---|---|
| `home.white-enciso.com` | `local-family` | backend real local | accesible en LAN local; candidato natural a experiencia familiar local |
| `ntfy.white-enciso.com` | `local-ops` | backend real local | solo operaciones y alerting local; no publico por ahora |
| `pihole.white-enciso.com` | `admin-local-only` | DNS staged opcional / admin future | no publico; solo admin local o eventual `Tailscale` |
| `portainer.white-enciso.com` | `tailscale-only` | futuro | no publico; solo privado por `LAN/Tailscale` |
| `auth.white-enciso.com` | `staged-placeholder` | placeholder local | bloqueado hasta microplan de `SSO/auth` |
| `paperless.white-enciso.com` | `staged-placeholder` | placeholder local | bloqueado hasta microplan propio y decision de auth/exposure |
| `immich.white-enciso.com` | `staged-placeholder` | placeholder local | bloqueado hasta microplan propio y decision de auth/exposure |
| `jellyfin.white-enciso.com` | `future-public` | placeholder local | candidato futuro a exposicion mas amplia, pero no en esta fase |
| `navidrome.white-enciso.com` | `staged-placeholder` | placeholder local | bloqueado hasta microplan propio y decision de auth/exposure |

Reglas cerradas:

- `home.white-enciso.com` puede operar como `local-family`
- `ntfy.white-enciso.com` queda `local-ops`
- `pihole.white-enciso.com` queda `admin-local-only`
- `portainer.white-enciso.com` queda `tailscale-only`
- `auth.white-enciso.com` no se expone ni se conecta como backend real antes del microplan de `SSO`
- `paperless`, `immich`, `jellyfin` y `navidrome` no avanzan a exposicion mas amplia sin backend validado y politica de acceso decidida
- `never-public` se aplica desde ahora a:
  - `pihole.white-enciso.com`
  - cualquier futura URL de `Portainer`
- `local-only` y `tailscale-only` siguen siendo el default mas seguro

Lectura operativa:

- `06F` no cambia infraestructura
- `06F` solo fija el marco para decidir que hostnames pueden avanzar pronto y cuales deben quedarse frenados
- la siguiente fase puede concentrarse en conectar un backend real adicional sin reabrir la discusion de exposure policy

Veredicto:

- `06F`: `pass`
- `06G`: `go`

## `06G` — Cloudflared exposure policy

Resultado factual de `06G`:

- no se activa `cloudflared`
- no se activa `TLS` publico
- no se expone ningun servicio a Internet
- queda definida la politica de exposure futura para la capa:
  - Internet -> `cloudflared` -> `Caddy` local -> backend

Clasificacion futura para `cloudflared`:

| Hostname | Clase cloudflared | Estado actual | Guardrail principal |
|---|---|---|---|
| `home.white-enciso.com` | `public-candidate` | backend real local | solo si se decide exposure publica en fase posterior |
| `ntfy.white-enciso.com` | `private-only` | backend real local | no publico por ahora; ops local primero |
| `pihole.white-enciso.com` | `never-public` | admin future | nunca publicar |
| `portainer.white-enciso.com` | `tailscale-only` | futuro | privado por `Tailscale`; no publico |
| `auth.white-enciso.com` | `blocked-until-auth` | placeholder local | no publicar antes de `authentik`/`SSO` |
| `paperless.white-enciso.com` | `blocked-until-auth` | placeholder local | requiere auth y politica de backup/restore |
| `immich.white-enciso.com` | `blocked-until-auth` | placeholder local | requiere auth y politica de backup/restore |
| `jellyfin.white-enciso.com` | `public-candidate` | placeholder local | bloqueado hasta politica de media/energia |
| `navidrome.white-enciso.com` | `blocked-until-auth` | placeholder local | bloqueado hasta politica de media/auth |

Reglas cerradas:

- `default deny`
- solo entra a `cloudflared` una `allowlist` explicita por hostname
- herramientas administrativas quedan fuera de exposure publica
- servicios personales requieren `auth/SSO` antes de cualquier exposure mayor
- servicios de media requieren politica separada de media/energia antes de exposure mayor
- `cloudflared` no se activa en esta fase

Never-public:

- `pihole.white-enciso.com`
- cualquier futura URL de `Portainer`

Blocked-until-auth:

- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Future-public candidates:

- `home.white-enciso.com`
- `jellyfin.white-enciso.com`

Lectura operativa:

- `06G` no cambia `Caddy`, `Pi-hole`, `router` ni backends
- `06G` solo fija el marco para decidir que hostnames podrian cruzar al plano `cloudflared`
- cualquier exposure futura debe mantener la cadena:
  - Internet -> `cloudflared` -> `Caddy` -> backend local validado

Veredicto:

- `06G`: `pass`
- `06H`: `go`

## `06H` — Cloudflared preflight y plantilla

Resultado factual de `06H`:

- `cloudflared` no esta instalado en `management`
- `cloudflared` no esta instalado en `orangepi5-ultra`
- no se encuentra runtime previo aprobado en `/etc/cloudflared`
- no se activa tunel, no se crea `DNS` publico y no se inicia servicio

Estructura versionada creada:

- `infra/colibri/cloudflared/README.md`
- `infra/colibri/cloudflared/config.example.yml`

Runtime futuro documentado:

- config:
  - `/etc/cloudflared/config.yml`
- secretos:
  - `/opt/colibri-secrets/cloudflared/`

Credenciales fuera de `git`:

- `cert.pem`
- credenciales JSON del tunel
- tokens

Allowlist documental inicial:

- `public-candidate`:
  - `home.white-enciso.com`
  - `jellyfin.white-enciso.com`
- privados o bloqueados:
  - `ntfy.white-enciso.com`
  - `pihole.white-enciso.com`
  - `portainer.white-enciso.com`
  - `auth.white-enciso.com`
  - `paperless.white-enciso.com`
  - `immich.white-enciso.com`
  - `navidrome.white-enciso.com`

Lectura operativa:

- `06H` deja listo el esqueleto versionado y la separacion limpia entre config y secretos
- la fase no instala ni activa nada
- la cadena futura se mantiene:
  - Internet -> `cloudflared` -> `Caddy` local -> backend

Veredicto:

- `06H`: `pass`
- `06I`: `go`

## `06I` — Cloudflared canary tunnel para `home.white-enciso.com`

Resultado factual de `06I`:

- `cloudflared` canary queda desplegado en `management` por `Docker Compose`
- stack versionado:
  - `infra/colibri/cloudflared/docker-compose.yml`
- runtime:
  - `/opt/stacks/cloudflared`
- nombre de proyecto:
  - `colibri-cloudflared`
- contenedor:
  - `cloudflared`

Version:

- `cloudflared` `2026.5.2`

Secretos:

- ruta:
  - `/opt/colibri-secrets/cloudflared/`
- archivos runtime:
  - `cloudflared.env`
  - `tunnel.token`
  - `cert.pem`
  - `15852846-afc2-41d5-92d9-87b437109528.json`
- nada de esto queda en `git`

Tunnel canary:

- nombre:
  - `colibri-home-canary`
- tunnel id:
  - `15852846-afc2-41d5-92d9-87b437109528`

Ingress efectivo:

- allowlist canary:
  - `home.white-enciso.com` -> `http://host.docker.internal:80`
- catch-all:
  - `http_status:404`

Validacion:

- `docker compose config`: `ok`
- `cloudflared tunnel ingress validate`: `OK`
- `cloudflared tunnel info colibri-home-canary`: con conexiones activas
- validacion publica canary usando edge publico:
  - `curl https://home.white-enciso.com` via IP publica de `Cloudflare`: `HTTP 200`
  - contenido servido: `Homepage`

Hostnames no expuestos por este canary:

- `ntfy.white-enciso.com`
- `pihole.white-enciso.com`
- `portainer.white-enciso.com`
- `auth.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`
- `jellyfin.white-enciso.com`

Caveat importante:

- se observo que `portainer.white-enciso.com` resuelve publicamente a IPs de `Cloudflare`
- pero no sirve app ni cruza por la allowlist del canary; responde error `530`
- esto sugiere `DNS` publico previo o wildcard heredado fuera del alcance de esta fase
- no se corrigio aqui porque `06I` solo debia publicar el canary de `home`

Lectura operativa:

- `home.white-enciso.com` ya tiene canary publico funcional
- el modelo `default deny` y catch-all queda aplicado dentro de este tunel
- antes de `06J` conviene revisar la deuda de `DNS` publico heredado para hostnames que no deben quedar publicables

Veredicto:

- `06I`: `pass with public-dns caveat`
- `06J`: `go`
