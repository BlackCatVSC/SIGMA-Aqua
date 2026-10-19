# Etapa 3 — Asistente inteligente para entrevistas

**Objetivo:** mejorar la calidad de las entrevistas. Crear un agente Copilot que acompañe en tiempo real, sugiera preguntas de profundización y oriente según las respuestas del candidato.

## Resultado esperado

Entrevistas más estructuradas, profundas y consistentes.

## Capacidades del agente

- **Acompañar en tiempo real** durante la entrevista (chat lateral / voz).
- **Sugerir preguntas de profundización** según lo que el candidato responde.
- **Orientar** al entrevistador según la respuesta (ej. señalar contradicciones, pedir ejemplos, cubrir competencias faltantes).

## Diseño del agente (Copilot Studio)

### Componentes

1. **Instrucciones (system prompt):** rol de "co-entrevistador psicolaboral", tono profesional, siempre orientado a obtener evidencia conductual (método STAR: Situación, Tarea, Acción, Resultado).
2. **Base de conocimiento (Knowledge):**
   - `pautas de entrevista` (un .docx por familia de cargo).
   - Diccionario de **competencias por cargo**.
   - Guía de preguntas por competencia.
3. **Entidades/entradas:** familia de cargo y cargo del candidato (para cargar la pauta correcta).
4. **Acciones (opcional):** guardar notas de la entrevista, registrar preguntas realizadas.

### Prompt del sistema (borrador)

```
Eres un co-entrevistador experto en evaluación psicolaboral. Tu rol es asistir
al entrevistador en tiempo real, NO al candidato.

- Usa las preguntas y competencias de la pauta de la familia de cargo indicada.
- Ante cada respuesta del candidato, sugiere preguntas de profundización con
  enfoque conductual (STAR): pide ejemplos concretos, contexto, acciones y resultados.
- Señala si queda alguna competencia sin explorar.
- Sé breve y accionable; no hagas juicios sobre el candidato, solo guía la indagación.

Entrada esperada: familia de cargo + cargo + transcripción/resumen de la respuesta.
```

## Flujo de uso

1. El entrevistador abre el agente e indica `familia de cargo` y `cargo`.
2. Mientras conversa con el candidato, pega o dicta la respuesta (o el agente escucha).
3. El agente responde con **sugerencias de preguntas de profundización** y avisos de competencias pendientes.
4. Al cierre, el agente puede resumir la entrevista y los puntos clave para el informe (insumo para la Etapa 2).

## Consideraciones técnicas

- Habilitar **voz / transcripción** (Teams / dictado) si se quiere acompañamiento 100% en vivo.
- Restringir el acceso al agente solo al equipo de psicólogos.
- Mantener una **base de conocimiento actualizada** con las pautas por familia (misma fuente usada en Etapa 1).
- Cumplimiento: asegurar manejo confidencial de datos de candidatos (no persistir más de lo necesario).

## Indicadores de éxito (Etapa 3)

- % de competencias cubiertas por entrevista (antes/después).
- Consistencia entre evaluadores.
- Reducción de tiempo de preparación de entrevista.
- Satisfacción del equipo entrevistador.

## Checklist de validación (Etapa 3)

- [ ] El agente carga la pauta correcta según familia de cargo.
- [ ] Sugiere preguntas de profundización pertinentes y en formato conductual.
- [ ] Detecta competencias faltantes y lo avisa.
- [ ] Acceso restringido al equipo autorizado.
- [ ] Resumen final usable como insumo para el informe (Etapa 2).
