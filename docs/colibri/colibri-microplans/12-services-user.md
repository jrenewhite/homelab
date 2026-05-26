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
5. `SFTPGo`
6. `BookStack`
7. `Memos`
8. `Mealie`
9. `Homebox`
10. `Actual Budget`
11. `Wallos`
12. `Stirling PDF`
13. `IT-Tools`
14. `Matrix`
15. `Hermes`
16. `n8n`

## Decisiones cerradas

- `Vaultwarden`, `Paperless`, `Matrix`, `Hermes`, `n8n` viven en `services`
- `Home Assistant` vive en `orangepi5-ultra`
- ninguna de estas apps puede depender runtime de `nas`
- toda app compatible debe evaluar `SSO` antes de aprobar cuenta local permanente
- las URLs de experiencia normal serán globales bajo `white-enciso.com`
- si un servicio existe en ambas sedes, se prefiere activo-local por sitio
- ninguna app de usuario se publica a clientes hasta haber sido validada por IP privada o acceso administrativo

## Matriz resumida

| Servicio | Nodo | Runtime storage | Archivo/backup | Identidad |
|---|---|---|---|---|
| Vaultwarden | `services` | local | backup a `nas` | local al inicio, revisar excepción permanente |
| Paperless | `services` | local | archive a `nas:/srv/docs` | preferir `OIDC` |
| file sharing ligero | `services` | local | sync a `nas` según política | definir según producto final |
| SFTPGo | `services` | local | sync o archive según política | preferir `OIDC` o auth por proxy |
| Home Assistant | `ultra` | local | backup/export a `nas` | evaluar si `OIDC` aporta |
| BookStack | `services` | local | backup a `nas` | preferir `OIDC` |
| Memos | `services` | local | backup a `nas` | preferir `OIDC` |
| Mealie | `services` | local | backup a `nas` | preferir `OIDC` |
| Homebox | `services` | local | backup a `nas` | preferir `OIDC` |
| Actual Budget | `services` | local | backup a `nas` | probablemente solo primario |
| Wallos | `services` | local | backup a `nas` | preferir `OIDC` si aporta |
| Stirling PDF | `services` | local | no crítico | auth por proxy o privada |
| IT-Tools | `management` o `services` | local | no crítico | auth por proxy o privada |
| Matrix | `services` | local | backup a `nas` | depende del stack final |
| Hermes | `services` | local | opcional | debe delegar a `SSO` si tiene UI humana |
| `n8n` | `services` | local | backup a `nas` | preferir `OIDC` o auth por proxy |

## Flujos de fallo

- si `nas` cae, siguen operando;
- si `services` cae, se afecta vida digital central;
- si `ultra` cae, Home Assistant cae pero no el resto de apps de `services`.
- si `Perú` está aislado, `Colibrí` sigue operando localmente sin esperar consistencia fuerte.

## Aceptación

- cada app tiene nodo, storage, dependencia de `nas` y backup definidos;
- ningún servicio de usuario tiene storage ambiguo.
- cada app tiene ruta de despliegue staged y criterio claro para volverse visible a usuarios

## Dependencias previas

- storage local-first
- permisos
- proxy
- estrategia de `SSO`

## Fuera de fase

- GPU pesada
- media masiva
