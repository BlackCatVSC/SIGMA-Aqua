# Proyecto: Automatización del Proceso de Evaluación Psicolaboral

Automatización del flujo completo de evaluación psicolaboral en el área de Reclutamiento y Selección, desde la solicitud hasta la generación del informe, usando Power Automate, SharePoint/OneDrive y Copilot Studio.

> **Nota:** Microsoft Forms fue reemplazado por un formulario web React (`solicitud/`) porque no se dispone de licencia de Forms. La entrada llega al backend Express (`POST /api/solicitud`) y se persiste en SQLite.

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [Plan de Implementación](plan-implementacion.md) | Objetivos, etapas, hitos y criterios de aceptación |
| [Solicitud de entrada (React)](solicitud-react.md) | Formulario web → backend (reemplaza Forms) |
| [Solicitud y estructura de datos](solicitud-y-datos.md) | Campos, catálogo de familias y modelo de datos |
| [Etapa 1](etapas/etapa-1-flujo-carpetas.md) | Automatización de carpeta + plantillas |
| [Etapa 2](etapas/etapa-2-integracion-informe.md) | Copilot → Excel del informe |
| [Etapa 3](etapas/etapa-3-asistente-entrevista.md) | Agente Copilot de entrevista |

## Estructura de artefactos

- `solicitud/` — Formulario web React (Vite + TypeScript) que envía la solicitud al backend.
- `backend/` — API Express + SQLite (candidatos, solicitudes, evaluaciones, usuarios).
- `frontend/` — Panel web (dashboard, candidatos, solicitudes).
- `docs/` — Documentación técnica y de implementación.
- `plantillas/` — Plantillas base (informe Excel y pauta de entrevista Word) por familia de cargo.

## Stack

- Backend: Node.js + Express + SQLite (`node:sqlite`, `multer`)
- Frontend: React + TypeScript (Vite)
- Objetivo de automatización: Power Automate, SharePoint Online / OneDrive for Business, Copilot Studio
