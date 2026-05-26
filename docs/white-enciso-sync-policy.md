# White-Enciso — Política de Sincronización

Documento de política para sincronización entre sedes bajo `white-enciso.com`.

Este documento complementa:

- [white-enciso-multisite.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-multisite.md)
- [colibri-master-plan.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-master-plan.md)

Su propósito es cerrar qué se sincroniza, qué no se sincroniza, bajo qué dirección de verdad y con qué reglas de conflicto, para que el modelo multi-site no derive en `split-brain`.

## 1. Principio rector

La política general es:

```text
activo-local por sitio + ventanas de sincronización + single-writer por dominio de datos
```

Eso significa:

- cada sede opera localmente para la experiencia normal de usuario
- no se busca consistencia fuerte multi-master para datos delicados
- la sincronización ocurre por ventanas y con reglas explícitas
- cada dominio de datos tiene una fuente de verdad clara

## 2. Reglas duras

- no se sincronizan bases de datos activas en modo multi-writer
- no se replica runtime state caliente entre sedes como si fuera HA fuerte
- todo servicio con estado delicado debe ser `single-writer`
- toda sincronización debe poder pausarse sin romper la operación local del sitio
- toda sincronización inter-sede viaja por `WireGuard`
- ninguna política de sync puede volver a `nas` dependencia runtime

## 3. Clases de sincronización

### 3.1 Single-writer con backup/replicación

Aplica cuando un servicio tiene una sola sede escritora y la otra solo recibe copia o respaldo.

Ejemplos típicos:

- `Actual Budget`
- `Vaultwarden` al inicio
- `authentik`
- `Matrix` por homeserver
- bases de datos de servicios críticos

Regla:

- una sede escribe
- la otra no modifica ese mismo dataset
- la copia remota es para backup, DR o lectura limitada, no para escritura concurrente

### 3.2 Activo-local con consistencia relajada

Aplica cuando cada sitio sirve su experiencia local y luego sincroniza artefactos aprobados.

Ejemplos:

- librerías media finales
- documentos archivados
- exports de ingestión ya cerrados
- staging aprobado para replicación diferida

Regla:

- cada sitio atiende a sus usuarios locales
- se sincronizan outputs o archivos finales
- no se asume convergencia instantánea

### 3.3 Réplica fría o archivística

Aplica a backups, snapshots lógicos, exports y archivo final.

Ejemplos:

- backups de bases de datos
- exports de Paperless
- bibliotecas finales de `media`
- documentos finales de `docs`

Regla:

- puede haber mayor latencia
- la prioridad es integridad y recuperabilidad, no frescura

## 4. Dirección de verdad por dominio

| Dominio | Fuente de verdad | Tipo |
|---|---|---|
| DNS local por sitio | cada sede local | activo-local |
| reservas DHCP | router local de cada sede | single-writer local |
| `authentik` | inicialmente `Colibrí` | single-writer |
| `Vaultwarden` | inicialmente `Colibrí` | single-writer |
| `Matrix colibri.*` | `Colibrí` | single-writer |
| `Matrix peru.*` | `Perú` | single-writer |
| `Paperless` documentos finales | sitio originador hasta archive; luego replicable | activo-local + archive |
| `Immich` uploads y DB | sitio local | single-writer por instancia |
| media final | sitio local + sync a biblioteca remota | activo-local + archive |
| `nas:/srv/docs` | archivo final por sede | archivístico |
| `nas:/srv/media` | biblioteca final por sede | archivístico |
| backups de apps | sitio de origen | archivístico |

## 5. Lo que sí se sincroniza

- backups lógicos de bases de datos
- exports aprobados de aplicaciones
- bibliotecas finales de `media`
- documentos finales de `docs`
- archivos compartidos diseñados para sync diferido
- configuraciones exportables de servicios cuando tenga sentido
- artefactos cerrados de automatización o jobs batch

## 6. Lo que no se sincroniza directamente

- bases de datos activas en multi-writer
- colas, cachés, Redis o estado caliente
- volúmenes Docker activos como estrategia de “HA”
- sesiones efímeras
- directorios temporales de procesamiento
- mounts vivos de `NFS` entre sedes como dependencia de apps

## 7. Política por servicio

### 7.1 `Paperless`

- runtime y DB: locales a la sede
- ingestión: local
- archivo final: local primero
- replicación: por ventana, sobre documentos finales o export aprobado
- no multi-writer entre sedes

### 7.2 `Immich`

- core y DB: locales a la sede
- ML: local al sitio o a su nodo GPU
- replicación: opcional y posterior, nunca como runtime dependency
- no multi-writer de la misma biblioteca sin diseño específico posterior

### 7.3 `Jellyfin`

- cada sede sirve su librería local o su hot set local
- la biblioteca final puede replicarse por ventana
- la experiencia global usa la misma URL, pero la resolución local manda

### 7.4 `Navidrome`, `Audiobookshelf`, `Kavita`, `Tube Archivist`

- runtime local por sede
- sync posterior de bibliotecas o exports aprobados
- no depender de un share remoto vivo del otro sitio

### 7.5 `Vaultwarden`

- inicialmente single-writer en `Colibrí`
- `Perú` consume por acceso normal o por recuperación definida
- réplica futura solo como DR, no multi-master

### 7.6 `authentik`

- inicialmente single-writer en `Colibrí`
- `Perú` lo consume como IdP central
- cualquier réplica futura requiere diseño específico; no asumir active-active

### 7.7 `Matrix`

- excepción formal
- no comparte un mismo homeserver activo-local en dos sedes
- si existe en ambas, son homeservers distintos y federados:
  - `colibri.white-enciso.com`
  - `peru.white-enciso.com`

## 8. Ventanas de sincronización

Reglas base:

- se ejecutan en horarios de bajo tráfico sostenido
- no coinciden con cambios de red, DNS, blackout o proxy
- no coinciden con tareas pesadas de IA/GPU si compiten por recursos
- si el sitio remoto está degradado, la sincronización se difiere

Orden recomendado:

1. validar salud local
2. validar enlace `WireGuard`
3. validar espacio disponible remoto
4. sincronizar artefactos o datasets aprobados
5. verificar integridad básica
6. registrar resultado

## 9. Resolución de conflictos

Regla general:

- evitar conflictos por diseño, no resolverlos a posteriori

Política:

- si un dominio es `single-writer`, cualquier escritura remota paralela es error de proceso
- si un dominio es `activo-local`, cada sede conserva su working set local y solo sincroniza outputs o datasets aprobados
- ante conflicto no previsto:
  - se detiene la sincronización
  - no se fuerza merge automático
  - se analiza dominio por dominio

## 10. Comportamiento ante fallas

### Sitio remoto caído

- el sitio local sigue operando
- se acumula trabajo pendiente de sync
- no se bloquean apps por esperar consistencia remota

### `WireGuard` caído

- no hay sync inter-sede
- los servicios locales siguen vivos
- se difiere replicación

### `nas` dormido o no disponible

- las apps locales siguen en modo local-first
- el sync a archivo final se reintenta después

### Blackout

- se cancelan syncs no esenciales
- no se despiertan nodos pesados ni storage frío

## 11. Requisitos de implementación futura

Toda implementación real de sync debe incluir:

- prechecks
- lock o control de concurrencia si aplica
- logging local
- criterio de abortar
- criterio de reintento
- rollback o compensación cuando aplique

## 12. Aceptación

La política se considera cerrada cuando:

- cada servicio relevante está clasificado como `single-writer`, `activo-local` o `archivístico`
- no quedan ambigüedades sobre quién escribe qué
- `WireGuard` queda reconocido como transporte privado inter-sede
- `Matrix` queda formalmente fuera de multi-site activo-local compartido
- ningún microplan contradice esta política
