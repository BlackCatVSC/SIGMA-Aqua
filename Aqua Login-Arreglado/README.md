# Automatización del Proceso de Evaluación Psicolaboral

## Avances

El proyecto parte de una plantilla base entregada por el docente. Sobre ese esqueleto, hasta ahora el equipo ha avanzado principalmente en el frontend.

El FrontEnd contiene:

- **Diseño visual del panel** con React y Bootstrap: menú lateral, topbar, modo oscuro y estilos de las pantallas (Dashboard, Candidatos, Solicitudes).
- **Pantalla de Login** rediseñada visualmente desde cero (imagen de fondo, logo, campos de usuario/contraseña, mostrar contraseña, "recordarme", olvide contraseña, boton ingresar).
- **Login funcional (hardcodeado):** Al presionar "Ingresar" se guarda un usuario fijo y se navega al Dashboard. Sin validacion por el momento.

### Tecnologías usadas

| Herramienta | Uso |
|---|---|
| **React 19** + **React DOM** | Construcción de la interfaz por componentes |
| **Bootstrap 5.3.3** | Estilos visuales del panel |
| **React Router DOM 7** | Navegación entre pantallas |
| **Vite 8** | Servidor de desarrollo y empaquetado |

## Estructura de artefactos

- `solicitud/` — Formulario web React (Vite + TypeScript) que envía la solicitud al backend.
- `backend/` — API Express + SQLite (candidatos, solicitudes, evaluaciones, usuarios (hardcodeados)).
- `frontend/` — Panel web (dashboard, candidatos, solicitudes) y Login (imagen de fondo, logo, campos de usuario/contraseña, mostrar contraseña, "recordarme", olvide contraseña, boton ingresar).
- `docs/` — Documentación técnica y de implementación.
- `plantillas/` — Plantillas base (informe Excel y pauta de entrevista Word) por familia de cargo.

## Stack

- Backend: Node.js + Express + SQLite (`node:sqlite`, `multer`)
- Frontend: React + TypeScript (Vite)

