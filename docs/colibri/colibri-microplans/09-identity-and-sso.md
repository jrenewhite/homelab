# Microplan 09 — Identidad Federada y `SSO`

## Propósito

Definir una estrategia única de autenticación para `Colibrí`, alineada al marco multi-site, que reduzca cuentas locales dispersas y mantenga una política clara para servicios compatibles y no compatibles.

## Estado actual

- `authentik` ya fue elegido como dirección preferida
- hoy las cuentas siguen siendo por servicio o por nodo
- ya existe base de identidades de sistema Linux, pero no identidad federada de apps

## Objetivo final

- existe un proveedor central de identidad para servicios de usuario y administración compatibles
- los usuarios no necesitan cuentas separadas en cada app cuando la integración lo permita
- los servicios no compatibles quedan clasificados explícitamente como excepciones

## Decisiones cerradas

- sí, `SSO` es viable y deseable para `Colibrí`
- `authentik` es la plataforma aprobada para `SSO`
- `authentik` se prefiere sobre `Keycloak` por ergonomía de homelab y sobre `Authelia` como identidad principal porque `authentik` cubre mejor `OIDC`, `SAML` y auth por proxy dentro de una misma plataforma
- `SSO` no sustituye cuentas locales de emergencia para administración break-glass
- no todos los servicios soportarán integración directa; se usará esta jerarquía:
  1. integración nativa `OIDC`/`SAML`
  2. auth por proxy detrás de `Caddy` si es compatible
  3. cuenta local excepcional documentada
- ningún servicio sensible se expone por Internet solo porque ya tiene `SSO`
- la introducción de `SSO` nunca se hace en la misma ventana que cambios de proxy, DNS o publicación externa del mismo servicio

## Interfaces

### Plataforma elegida

- proveedor de identidad: `authentik`
- despliegue objetivo: contenedores Docker en `services`
- publicación:
  - acceso interno por `Caddy`
  - exposición externa solo si se aprueba explícitamente
- URL canónica: `auth.white-enciso.com`
- inicialmente, `authentik` vive en `Colibrí` y `Perú` lo consume como servicio central hasta que exista réplica aprobada

### Protocolos objetivo

- `OIDC` como opción preferida para nuevas apps
- `SAML` solo donde la app lo requiera
- auth por proxy para apps web que no tengan `OIDC`/`SAML` útil

### Cuentas y excepciones

- cuenta administrativa break-glass local en `authentik`
- cuentas locales solo para:
  - bootstrap inicial
  - recuperación de emergencia
  - apps sin integración viable

## Matriz inicial de estrategia

| Servicio | Estrategia objetivo |
|---|---|
| `Vaultwarden` | cuenta local al inicio; revisar integración posterior si aporta valor |
| `Paperless` | preferir `OIDC` |
| `Immich` | preferir `OIDC` |
| `Matrix` | no forzar `SSO` si complica el modelo federado multi-homeserver; excepción documentada si aplica |
| `Home Assistant` | revisar si conviene `OIDC`; no asumirlo obligatorio |
| `Portainer` | mantener acceso privado; `SSO` opcional |
| paneles administrativos | privados por red/Tailscale primero; `SSO` complementa, no reemplaza |

## Flujos

### Normal

1. usuario entra al servicio
2. el servicio delega autenticación a `authentik` o al proxy autenticado
3. el servicio autoriza según claims, grupos o rol local
4. antes de volver obligatoria la autenticación federada, se prueba con cuentas locales y acceso privado

### Falla

- si cae `authentik`, los servicios con sesión vigente pueden seguir operando según su propio comportamiento
- nuevos logins federados pueden fallar
- servicios con cuenta local de excepción conservan camino de recuperación
- si `Perú` queda aislado de `Colibrí`, los servicios que dependan de `authentik` central deben tener política explícita de degradación o bypass local

## Aceptación

- existe proveedor de identidad aprobado
- cada servicio de usuario y administración tiene estrategia `SSO` explícita
- las excepciones quedan listadas, no implícitas
- la seguridad de red no depende exclusivamente de `SSO`

## Dependencias previas

- DNS
- proxy
- política de exposición

## Fuera de fase

- implementación del contenedor `authentik`
- hardening detallado
- sincronización con directorio externo LDAP
