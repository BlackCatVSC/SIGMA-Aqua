# Solicitud y estructura de datos

## 1. Formulario de entrada

La solicitud se recibe a través de la app React `solicitud/` (ver [solicitud-react.md](solicitud-react.md)), que hace `POST multipart/form-data` al backend `POST /api/solicitud`.

## 2. Modelo de datos (SQLite — MVP actual)

El backend (`backend/src/db.js`) usa SQLite. Tablas:

| Tabla | Campos |
|-------|--------|
| `usuarios` | `id`, `nombre`, `correo`, `rol` (Administrador/Analista/Evaluador/Jefatura) |
| `candidatos` | `id`, `nombre`, `correo`, `telefono`, `cargo`, `familia_cargo`, `creado_en` |
| `solicitudes` | `id`, `candidato_id`, `cargo`, `familia_cargo`, `fecha_solicitud`, `estado` (Pendiente/En proceso/Finalizada), `responsable_id`, `observaciones`, `creado_en` |
| `evaluaciones` | `id`, `solicitud_id`, `fecha_evaluacion`, `resultado`, `observaciones`, `estado`, `creado_en` |

El CV y el descriptor se guardan como archivos en `backend/data/uploads/`; la solicitud referencia su nombre en `observaciones`.

## 3. Catálogo de familias de cargo (automatización objetivo)

> Para la automatización con SharePoint/plantillas, cada familia apunta a un par de plantillas. El desplegable debe contener exactamente estos valores (valor visible + valor interno).

| # | Familia de cargo | Código | Plantilla informe Excel | Pauta entrevista Word |
|---|------------------|--------|-------------------------|-----------------------|
| 1 | Administrativa | `ADM` | `ADM-informe.xlsx` | `ADM-pauta.docx` |
| 2 | Operativa | `OPE` | `OPE-informe.xlsx` | `OPE-pauta.docx` |
| 3 | Comercial | `COM` | `COM-informe.xlsx` | `COM-pauta.docx` |
| 4 | Tecnológica | `TEC` | `TEC-informe.xlsx` | `TEC-pauta.docx` |
| 5 | Gerencial | `GER` | `GER-informe.xlsx` | `GER-pauta.docx` |

> **Regla de negocio:** el flujo resuelve las plantillas por `Código`, no por el nombre visible. Esto evita errores por tildes/mayúsculas y facilita agregar familias sin tocar el flujo (solo agregando archivos `COD-informe.xlsx` / `COD-pauta.docx` en `_Plantillas`).

## 4. Estructura de carpetas en SharePoint (objetivo)

Librería destino: `Evaluación Psicolaboral` en el sitio **Recursos Humanos** (`/sites/RRHH`).

```
/sites/RRHH/Evaluación Psicolaboral
├── _Plantillas/
│   ├── Informes/
│   │   ├── ADM-informe.xlsx
│   │   ├── OPE-informe.xlsx
│   │   ├── COM-informe.xlsx
│   │   ├── TEC-informe.xlsx
│   │   └── GER-informe.xlsx
│   └── Pautas/
│       ├── ADM-pauta.docx
│       ├── OPE-pauta.docx
│       ├── COM-pauta.docx
│       ├── TEC-pauta.docx
│       └── GER-pauta.docx
├── Solicitudes/
│   └── <NombreCandidato>/
│       ├── CV_<NombreCandidato>.<ext>
│       ├── Informe_<NombreCandidato>.xlsx
│       └── PautaEntrevista_<NombreCandidato>.docx
└── InformesFinalizados/
    └── <NombreCandidato>/Informe_<NombreCandidato>_FIRMADO.xlsx
```

## 5. Convención de nombres

- Carpetas: `NombreCandidato` normalizado (sin tildes, espacios → `_`).
- Archivos: `Tipo_NombreCandidato.ext`.
- Evitar caracteres inválidos de SharePoint: `" * : < > ? / \ |`.

## 6. Mapeo Forms → resolución de plantillas (Código)

| Respuesta (visible) | Código usado en el flujo |
|---------------------------|--------------------------|
| Administrativa | `ADM` |
| Operativa | `OPE` |
| Comercial | `COM` |
| Tecnológica | `TEC` |
| Gerencial | `GER` |

Rutas resultantes (patrón único):

- `/_Plantillas/Informes/<COD>-informe.xlsx`
- `/_Plantillas/Pautas/<COD>-pauta.docx`
