# Plan de Implementación

## 1. Objetivo general

Automatizar el flujo completo de la evaluación psicolaboral, desde la solicitud hasta la generación del informe, optimizando tiempos y mejorando la eficiencia del proceso.

## 2. Situación actual (línea base)

1. El analista solicita evaluación vía Forms (nombre, familia de cargo, cargo, CV).
2. La información cae en Excel y se integra a Planner vía Power Automate.
3. El psicólogo, de forma manual:
   - Descarga el CV.
   - Crea carpeta en OneDrive y sube archivos base según familia de cargo (informe Excel + pauta Word).
   - Toma apuntes y genera transcripción en Word.
   - Sube ambos archivos a un agente Copilot que genera el contenido.
   - Copia/pega manualmente la información al Excel del informe.
   - Revisa y envía por correo al analista.

**Problema principal:** múltiples tareas manuales repetitivas que consumen tiempo y son automatizables.

## 3. Etapas y alcance

| Etapa | Objetivo | Resultado esperado | Dependencias |
|-------|----------|-------------------|--------------|
| Etapa 1 | Eliminar la gestión manual inicial (carpeta + documentos) | Carpeta del candidato creada automáticamente con CV y plantillas correctas | Forms, Power Automate, SharePoint |
| Etapa 2 | Evitar el copiado manual de información al informe | Informe Excel completado automáticamente, listo para revisión | Copilot Studio, Excel/Graph API |
| Etapa 3 | Mejorar la calidad de entrevistas | Asistente que acompaña, sugiere preguntas y orienta en tiempo real | Copilot Studio, base de conocimiento |

## 4. Hitos propuestos

### M0 — Preparación y habilitación
- Confirmar licencias (Power Automate Premium, Copilot Studio).
- Crear sitio/librería SharePoint destino: `Evaluación Psicolaboral`.
- Definir catálogo de "familias de cargo" y sus plantillas asociadas.
- Definir convención de nombres de carpetas y archivos.

### M1 — Etapa 1 en producción
- Formulario Forms publicado.
- Flujo Power Automate que: crea carpeta → guarda CV → copia plantillas según familia.
- Prueba piloto con 5 solicitudes.

### M2 — Etapa 2 en producción
- Agente Copilot con plantilla de informe y prompt de extracción seccionado.
- Integración automática al Excel (celdas por sección).
- Validación con 5 informes reales.

### M3 — Etapa 3 en producción
- Agente de entrevista con base de conocimiento (pautas por familia).
- Sesión de acompañamiento en tiempo real.
- Medición de consistencia/calidad de entrevistas.

## 5. Criterios de aceptación generales

- El psicólogo ya **no** crea carpetas ni descarga CV manualmente (Etapa 1).
- El psicólogo ya **no** copia/pega contenido al informe (Etapa 2).
- Todo cambio queda auditado (fecha, usuario, estado en Planner) .
- Se reduce el tiempo por solicitud de forma medible.

## 6. Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|-----------|
| Variedad de formatos de CV / archivos adjuntos | Validar extensiones y límite de tamaño en Forms; renombrar normalizado |
| Múltiples "familias de cargo" sin plantilla | Catálogo cerrado en Forms (lista desplegable) y validación de fallback |
| Copilot no respeta estructura del informe | Prompt con formato fijo + validación de celdas requeridas |
| Accesos/permisos SharePoint | Definir grupo de seguridad y permisos mínimos de escritura |
