# Etapa 2 — Automatización del traspaso de información al informe

**Objetivo:** evitar el copiado manual. El análisis generado por Copilot debe integrarse automáticamente en el Excel del informe psicolaboral, ubicando cada sección en su celda correspondiente.

## Resultado esperado

Informe psicolaboral completado automáticamente, listo para revisión.

## Arquitectura lógica

1. El psicólogo termina la entrevista y dispone de **dos insumos**:
   - `PautaEntrevista_<Nombre>.docx` (apuntes + transcripción automática).
   - CV del candidato.
2. Ambos se envían a un **agente Copilot** con instrucciones de generar el análisis del informe seccion por sección.
3. La salida de Copilot se estructura en un **JSON esquema fio** (o tabla) con pares `sección → contenido`.
4. Un flujo (Power Automate / Copilot action / Graph API) escribe cada contenido en la **celda correspondiente** del `Informe_<Nombre>.xlsx`.

## Diseño del informe (Excel) — mapeo sección → celda

Ejemplo de hoja `Informe`:

| Celda | Sección del informe |
|-------|---------------------|
| A1 | Título del informe |
| A2 | Nombre del candidato |
| A3 | Cargo / Familia de cargo |
| B5 | Antecedentes del candidato |
| B6 | Motivos de postulación |
| B7 | Fortalezas |
| B8 | Oportunidades de mejora |
| B9 | Conclusiones |
| B10 | Recomendación / dictamen |

> El informe real debe definirse con el equipo. Lo importante es que **cada sección tenga una celda unívoca** para automatizar la escritura.

## Contrato de salida de Copilot (JSON)

Prompt de sistema (agente) que obliga a responder en este formato:

```json
{
  "nombre_candidato": "...",
  "cargo": "...",
  "secciones": {
    "antecedentes": "...",
    "motivos_postulacion": "...",
    "fortalezas": "...",
    "oportunidades_mejora": "...",
    "conclusiones": "...",
    "recomendacion": "..."
  }
}
```

## Flujo de escritura al Excel

Opción recomendada: **Power Automate con `Excel Online (Business)`** sobre el archivo alojado en SharePoint.

1. Trigger: agente Copilot entrega el JSON (vía `Copilot` / `HTTP` / `Teams`).
2. `Parse JSON` para descomponer el payload.
3. Acciones `Update a row` (o `Update a cell`) dirigidas a `Informe_<Nombre>.xlsx`:
   - `antecedentes` → celda B5
   - `motivos_postulacion` → B6
   - `fortalezas` → B7
   - etc.
4. Marcar `Estado = Completado` en la tabla `Respuestas`.
5. Notificar al analista solicitante con el informe adjunto.

## Alternativas de integración

| Mecanismo | Cuándo usarlo |
|-----------|---------------|
| Copilot Studio + conector Excel | Si el agente vive en Copilot Studio y usa conectores estándar |
| Power Automate cloud flow | Orquestación central y escritura confiable en Excel |
| Microsoft Graph API (tablas) | Casos avanzados / alta escala |

## Consideraciones técnicas

- El archivo Excel debe estar en SharePoint (no OneDrive personal) para que el conector `Excel Online (Business)` lo manipule.
- Definir/validar el esquemas del informe y bloquear celdas no editables por el flujo.
- Manejar errores: si una sección llega vacía, no sobrescribir y registrar advertencia.
- Conserva un registro histórico/versiones antes de cerrar.

## Checklist de validación (Etapa 2)

- [ ] El agente Copilot responde siempre en el JSON definido (sin texto adicional).
- [ ] El flujo escribe cada sección en la celda correcta del informe.
- [ ] Se respeta el formateo existente del Excel.
- [ ] Un informe completo se marca `Completado` y notifica al analista.
- [ ] Una sección vacía no bloquea el flujo y se registra advertencia.
