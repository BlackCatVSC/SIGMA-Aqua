# Solicitud de entrada (React) → Backend

El formulario de entrada es la app React `solicitud/` (Vite + TypeScript). Reemplaza a Microsoft Forms (no se dispone de licencia) y envía la solicitud de evaluación psicolaboral al backend Express, que la persiste en SQLite.

## Arquitectura

```
Analista ──► solicitud React (src/App.tsx)
                │  POST multipart/form-data (campos + archivos)
                ▼
   Backend Express  POST /api/solicitud  (multer)
                ▼
   SQLite: candidatos + solicitudes  (CV/descriptor en data/uploads/)
```

## Campos del formulario

| Campo | Tipo | Obligatorio |
|-------|------|-------------|
| Reclutador/a | Texto | Sí |
| Nombre del candidato/a | Texto | Sí |
| Origen (Interno/Externo) | Selección | Sí |
| Familia de cargo | Selección | Sí |
| Nombre del cargo | Texto | Sí |
| Ubicación del cargo | Texto | Sí |
| Unidad | Texto | No |
| CECO (centro de costos) | Texto | No |
| Requiere referencias | Sí/No | Sí |
| Currículum (CV) | Archivo (PDF/DOC/DOCX) | Sí |
| Descriptor del cargo | Archivo | No |
| ¿Es referido? | Sí/No | No |
| Aspectos a indagar / comentarios | Texto largo | No |

## Familias de cargo (catálogo)

Definidas en `src/catalogs.ts`:

`Profesional A`, `Profesional B C`, `Técnico A`, `Técnico B C`, `Operario Calificado`, `Supervisor B`, `Jefatura`.

## Configuración

1. Instalar dependencias: `npm install`.
2. Configurar `.env` (copiar de `.env.example`): `VITE_FLOW_URL=http://localhost:3001/api/solicitud`.
3. Levantar el backend (`npm run dev` en `backend/`, puerto 3001).
4. Desarrollo local: `npm run dev`.
5. Build producción: `npm run build` → carpeta `dist/`.

## Qué hace el backend al recibir la solicitud

`POST /api/solicitud` (implementado en `backend/src/routes/solicitud.js`):

- Crea un registro en `candidatos` (nombre, cargo, familia de cargo).
- Crea una `solicitud` asociada con estado `Pendiente`.
- Guarda el CV y el descriptor en `backend/data/uploads/`.
- Los campos adicionales (reclutador, origen, ubicación, unidad, CECO, referencias, referido, aspectos) se almacenan en `observaciones` de la solicitud.
