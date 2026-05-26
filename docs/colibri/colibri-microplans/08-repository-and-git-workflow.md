# Microplan 08 — Repositorio y Flujo de `git`

## Propósito

Definir cómo se versiona la arquitectura de `Colibrí`, cómo se trazan decisiones y cómo se reutiliza el trabajo más adelante para la segunda casa o futuras reconstrucciones.

## Estado actual

- el árbol de trabajo contiene documentación y `Ansible`
- el contenido se está tratando como fuente local viva
- el directorio actual todavía no está inicializado como repositorio `git`

## Objetivo final

- existe un repositorio `git` local para el proyecto `homelab`
- `Docs` y `Ansible` evolucionan con historial explícito
- cada decisión importante queda trazada por commit
- la segunda casa podrá reutilizar plantillas, playbooks y documentos sin copiar estados ambiguos

## Decisiones cerradas

- `git` será obligatorio como bitácora de evolución del proyecto
- la unidad de cambio principal será documental, no operativa
- no se harán commits mezclados que combinen rediseño arquitectónico con cambios de ejecución sin contexto
- cada cambio que altere arquitectura, permisos, storage, energía o exposición debe reflejarse primero en `docs/`
- `Ansible` se versiona como implementación derivada, pero dentro del mismo repositorio
- no se asume remoto obligatorio; el remoto es deseable pero no requisito de fase

## Interfaces

### Ramas

- `main`: estado aprobado y coherente
- ramas de trabajo temáticas opcionales para rediseños amplios

### Áreas versionadas

- `docs/`: fuente de verdad
- `ansible/`: implementación derivada reutilizable
- `README.md`: índice de orientación

### Convenciones de commit

- `docs:` cambios de arquitectura o documentación
- `ansible:` cambios en automatización derivada
- `inventory:` refrescos factuales
- `ops:` cambios operativos ya ejecutados y documentados

## Flujos

### Diseño normal

1. se actualiza `docs/`
2. se revisa coherencia con inventario
3. se ajusta `Ansible` si aplica
4. se registra commit con mensaje explícito

### Implementación futura

1. se aprueba el microplan correspondiente
2. se ejecuta el cambio real
3. se actualiza inventario factual
4. se actualiza `Ansible` o runbook derivado
5. se registra commit con impacto y alcance

### Reutilización para otra casa

1. se identifica qué parte es plantilla reutilizable
2. se separan variables por sitio
3. se evita clonar decisiones acopladas a `Colibrí`
4. se reaprovecha estructura, no estados accidentales

## Aceptación

- existe política explícita para versionar diseño y automatización
- los commits dejan clara la intención del cambio
- es posible reconstruir la evolución del homelab leyendo historial y documentos
- la segunda casa puede reutilizar la base sin reinterpretar decisiones

## Dependencias previas

- estructura documental ya definida

## Fuera de fase

- GitHub obligatorio
- CI/CD
- hooks automáticos
