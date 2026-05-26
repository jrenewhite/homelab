# Environment Secrets

Este directorio es para secretos locales y credenciales de operador.

Reglas:
- Los archivos `*.env` de aquí no se versionan.
- La documentación puede referenciar rutas y nombres de variables, pero no valores.
- Si hace falta compartir estructura, se crean archivos `*.example.env` sin secretos.

Archivos actuales esperados:
- `cloudflare_account_id.env`
- `cloudflare_api_token.env`
- `router.env`
- `tailscale_account_auth_key.env`
- `tailscale_api_access_token.env`

Plantillas versionables:
- `router.example.env`

Convención sugerida:
- Un archivo por proveedor o secreto lógico.
- Variables en formato shell simple, por ejemplo:

```bash
CLOUDFLARE_ACCOUNT_ID=...
```

Uso local típico:

```bash
set -a
source environment/cloudflare_account_id.env
source environment/cloudflare_api_token.env
set +a
```

Verificación rápida sin imprimir secretos:

```bash
env | grep '^CLOUDFLARE_'
```
