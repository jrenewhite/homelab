# Microplan 07 — `Ansible` y Transición a `management`

## Propósito

Definir cómo `Ansible` pasa de borrador técnico local a sistema de control ejecutado desde `management`.

## Estado actual

- inventario y playbooks existen localmente en esta máquina `CachyOS`
- `management` ya tiene `Ansible` instalado
- `Docs` son la fuente de verdad y `Ansible` aún no
- el árbol actual debe tratarse como librería de automatización reutilizable, aunque todavía no sea el punto de control final

## Objetivo final

- documentación manda;
- `Ansible` replica decisiones aprobadas;
- los playbooks son reutilizables, host-neutral y orientados por capas;
- `management` se convierte en nodo de control cuando red, identidades, blackout y proxy ya estén cerrados.

## Decisiones cerradas

- fase de diseño:
  - `Docs` = truth
  - `Ansible` = borrador
- `Ansible` debe crecer como librería reutilizable:
  - variables por sitio y por host
  - tareas idempotentes
  - playbooks pequeños por intención
  - sin acoplarse a esta estación `CachyOS`
- fase de transición:
  - `Ansible` se replica a `management`
  - se validan llaves, inventario y dependencias
- fase de control:
  - `management` ejecuta `Ansible`
  - la máquina local queda como estación de edición/documentación y backup operacional
- los playbooks con impacto de red, DNS, storage o energía deben soportar ejecución staged y validación entre pasos

## Interfaces

### Artefactos fuente

- `docs/colibri/colibri-master-plan.md`
- `docs/colibri/colibri-microplans/*`
- `docs/colibri/colibri-inventory.md`

### Artefactos derivados

- `ansible/inventory/hosts.yml`
- `ansible/group_vars/*`
- `ansible/host_vars/*`
- `ansible/playbooks/*`

### Reglas de reutilización

- toda lógica común debe vivir en `group_vars`, roles o playbooks compartidos
- los valores específicos de `Colibrí` deben poder separarse después en variables por sitio
- el host que ejecuta `Ansible` no debe definir rutas, usuarios o secretos de forma implícita
- una futura `Casa 2` debe poder reutilizar la misma estructura cambiando inventario y variables

## Flujos

### Gradual staged

1. diseño en local
2. aprobación documental
3. alineación de `Ansible`
4. validación de reutilización y neutralidad
5. copia a `management`
6. validación desde `management`
7. cutover de control
8. ejecución por capas con pausas de validación

## Aceptación

- la transición tiene punto de corte explícito;
- no hay dos fuentes de verdad compitiendo;
- la base de `Ansible` es reutilizable para otra casa o reconstrucción futura;
- `management` puede ejecutar la misma base aprobada sin reinterpretación.

## Dependencias previas

- red final
- identidades
- política de blackout

## Fuera de fase

- CI/CD de `Ansible`
- Git remoto obligatorio
