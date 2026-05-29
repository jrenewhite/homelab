# Microplan 06D — Homepage como segundo backend real local

## Resumen

`06D` despliega `Homepage` en `management` y reemplaza el placeholder de `home.white-enciso.com` por un `reverse_proxy` real via `Caddy`.

## Implementacion elegida

- servicio: `gethomepage/homepage`
- nodo: `management`
- patron: `Docker Compose`
- backend local:
  - `127.0.0.1:8080`

## Ubicacion versionada

- stack:
  - `infra/colibri/homepage/docker-compose.yml`
- config:
  - `infra/colibri/homepage/config/settings.yaml`
  - `infra/colibri/homepage/config/services.yaml`
  - `infra/colibri/homepage/config/bookmarks.yaml`
  - `infra/colibri/homepage/config/widgets.yaml`

## Runtime en management

- stack runtime:
  - `/opt/stacks/homepage`
- contenedor:
  - `homepage`
- publicacion:
  - `127.0.0.1:8080->3000/tcp`

## Caddy site aplicado

Archivo versionado:

- `infra/colibri/caddy/sites/home.caddy`

Contenido efectivo:

```caddyfile
http://home.white-enciso.com {
	import local_only
	reverse_proxy 127.0.0.1:8080 {
		import proxy_headers
	}
}
```

Se retiro el placeholder previo de runtime:

- `/etc/caddy/sites/home.white-enciso.com.caddy`

## Validate / restart

Comandos efectivos:

```bash
caddy validate --config /etc/caddy/Caddyfile
systemctl restart caddy
```

Resultado:

- `Valid configuration`
- `caddy` queda `active`

## Validacion

### Backend directo

```bash
curl http://127.0.0.1:8080/
```

Resultado:

- `HTTP 200`

### Hostname por proxy

```bash
curl http://home.white-enciso.com/
```

Resultado:

- `HTTP 200`
- `Homepage` servido por `Caddy`

### `ntfy`

```bash
curl http://ntfy.white-enciso.com/
```

Resultado:

- `HTTP 200`
- sin regresion sobre el primer backend real

### Placeholders restantes

Validados:

- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Resultado:

- todos siguen `HTTP 200`

## Anomalias

- `curl` sobre `Homepage` devuelve el HTML base del frontend y no alcanza a reflejar por si solo el contenido ya hidratado del dashboard
- la configuracion versionada si quedo montada en runtime bajo `/opt/stacks/homepage/config`
- esto no bloquea `06D`, pero deja pendiente validar/curar el contenido visual del dashboard en navegador y ajustar la experiencia final en una fase posterior

## Veredicto

- implementacion elegida: `Docker Compose` versionado
- puerto backend: `127.0.0.1:8080`
- `Caddy` aplicado: `ok`
- backend y hostname: `ok`
- `ntfy`: `ok`
- placeholders restantes: `ok`

## Recomendacion

- `06E`: `go`
