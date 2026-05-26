# Microplan 12 — Servicios de Usuario

## Propósito

Definir las apps personales y productivas de `Colibrí` sin mezclar media pesada ni IA.

## Estado actual

- no hay despliegue final aprobado aún

## Objetivo final

Orden de prioridad:

1. `Vaultwarden`
2. `Paperless`
3. file sharing ligero
4. `Home Assistant`
5. `Matrix`
6. `Hermes`
7. `n8n`

## Decisiones cerradas

- `Vaultwarden`, `Paperless`, `Matrix`, `Hermes`, `n8n` viven en `services`
- `Home Assistant` vive en `orangepi5-ultra`
- ninguna de estas apps puede depender runtime de `nas`
- toda app compatible debe evaluar `SSO` antes de aprobar cuenta local permanente

## Matriz resumida

| Servicio | Nodo | Runtime storage | Archivo/backup | Identidad |
|---|---|---|---|---|
| Vaultwarden | `services` | local | backup a `nas` | local al inicio, revisar excepción permanente |
| Paperless | `services` | local | archive a `nas:/srv/docs` | preferir `OIDC` |
| file sharing ligero | `services` | local | sync a `nas` según política | definir según producto final |
| Home Assistant | `ultra` | local | backup/export a `nas` | evaluar si `OIDC` aporta |
| Matrix | `services` | local | backup a `nas` | depende del stack final |
| Hermes | `services` | local | opcional | debe delegar a `SSO` si tiene UI humana |
| `n8n` | `services` | local | backup a `nas` | preferir `OIDC` o auth por proxy |

## Flujos de fallo

- si `nas` cae, siguen operando;
- si `services` cae, se afecta vida digital central;
- si `ultra` cae, Home Assistant cae pero no el resto de apps de `services`.

## Aceptación

- cada app tiene nodo, storage, dependencia de `nas` y backup definidos;
- ningún servicio de usuario tiene storage ambiguo.

## Dependencias previas

- storage local-first
- permisos
- proxy
- estrategia de `SSO`

## Fuera de fase

- GPU pesada
- media masiva
