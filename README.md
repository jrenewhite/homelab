# Homelab

Base de trabajo para organizar y desplegar el homelab de dos casas.

## Enfoque

Primero se diseña y estabiliza `Colibri` como referencia.
Despues se replica la base en la segunda casa con los ajustes necesarios.
La capa compartida multi-site vive en [white-enciso-multisite.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-multisite.md).

## Objetivos iniciales

- Inventario de hardware y red
- Arquitectura objetivo por roles
- Plan de IPs y acceso remoto
- Orden de despliegue de servicios
- Documentacion operativa

## Estado actual

- `Colibri` documentado de forma inicial en [colibri-plan.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-plan.md)
- marco multi-site en [white-enciso-multisite.md](/home/jrenewhite/Projects/homelab/docs/white-enciso-multisite.md)
- arquitectura maestra en [colibri-master-plan.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-master-plan.md)
- inventario operativo en [colibri-inventory.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-inventory.md)
- baseline del router en [colibri-router-baseline.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-router-baseline.md)
- microplanes por subsistema en [colibri-microplans](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-microplans)
- flujo de versionado y reutilizacion en [08-repository-and-git-workflow.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-microplans/08-repository-and-git-workflow.md)
- estrategia de identidad en [09-identity-and-sso.md](/home/jrenewhite/Projects/homelab/docs/colibri/colibri-microplans/09-identity-and-sso.md)
- base de `Ansible` en [ansible/README.md](/home/jrenewhite/Projects/homelab/docs/colibri/ansible/README.md)
- `NAS` ya reconstruido con namespaces unificados `media` y `docs` exportados por `NFS`
