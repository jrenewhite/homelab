# Microplan 06B — Primer backend real local con `Caddy`

## Resumen

`06B` conecta el primer backend real local a traves de `Caddy`:

- hostname: `ntfy.white-enciso.com`
- proxy: `management` `192.168.0.10`
- backend real: `http://192.168.0.14:8300`

No se activo `TLS`, no se activo `cloudflared` y no se conecto ningun otro backend.

## Prechecks

Validaciones previas:

- `curl http://192.168.0.14:8300/`: `200 OK`
- `Caddy` en `management`: `active`
- placeholders previos siguen respondiendo
- `8080` sigue libre para `Homepage`

## DNS local

`ntfy.white-enciso.com` no existia aun en los records staged de `Pi-hole`.

Se agrego manualmente en:

- `Pi-hole` primario `management`
- `Pi-hole` secundario `orangepi5-ultra`

Record efectivo en ambos:

```text
192.168.0.10 ntfy.white-enciso.com
```

Validacion:

```bash
dig +short @192.168.0.10 ntfy.white-enciso.com
dig +short @192.168.0.14 ntfy.white-enciso.com
```

Resultado:

- ambos devuelven `192.168.0.10`

## Config versionada de `Caddy`

Se agrego:

- `infra/colibri/caddy/sites/ntfy.caddy`

Contenido:

```caddyfile
http://ntfy.white-enciso.com {
	reverse_proxy 192.168.0.14:8300
}
```

## Aplicacion a runtime

Se sincronizo a:

- `/etc/caddy/sites/ntfy.caddy`

Flujo aplicado:

```bash
caddy validate --config /etc/caddy/Caddyfile
systemctl restart caddy
```

Resultado:

- `Valid configuration`
- `caddy` queda `active`

Nota operativa:

- se mantiene el patron `validate + restart`
- no se uso `systemctl reload caddy`

## Validacion funcional

### Hostname

```bash
dig +short ntfy.white-enciso.com
curl -I http://ntfy.white-enciso.com/
```

Resultado:

- `dig` devuelve `192.168.0.10`
- `curl` devuelve `HTTP 200`

### Publish minimo por hostname

Comando:

```bash
curl -X POST http://ntfy.white-enciso.com/colibri-ups-33883960f764a3bf \
  -d 'synthetic-06b-via-hostname'
```

Resultado:

- `ntfy` devolvio evento JSON valido con `id`, `time`, `topic` y `message`

### Backend por IP directa

Validacion:

```bash
curl -I http://192.168.0.14:8300/
```

Resultado:

- `HTTP 200`

### Placeholders existentes

Se revalidaron:

- `home.white-enciso.com`
- `auth.white-enciso.com`
- `jellyfin.white-enciso.com`
- `paperless.white-enciso.com`
- `immich.white-enciso.com`
- `navidrome.white-enciso.com`

Resultado:

- todos siguen `HTTP 200`
- sin cambios de comportamiento

## Anomalias

- `docker logs` de `ntfy-local` no reflejo inmediatamente el publish por hostname en la muestra observada
- esto no invalida la prueba porque el `POST` devolvio respuesta JSON valida del propio servicio

## Veredicto

- backend conectado: `ntfy`
- DNS local: `ok`
- config versionada aplicada: `ok`
- `caddy validate`: `ok`
- `systemctl restart caddy`: `ok`
- `ntfy` por hostname: `ok`
- `ntfy` por IP directa: `ok`
- placeholders existentes: `ok`

## Recomendacion

- `06C`: `go`
