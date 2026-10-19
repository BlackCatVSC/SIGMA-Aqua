# Etapa 1 â€” AutomatizaciÃ³n de creaciÃ³n de carpeta y documentos

**Objetivo:** eliminar la gestiÃ³n manual inicial. Al recibir una solicitud vÃ­a Forms, el sistema crea la carpeta del candidato, guarda el CV y copia las plantillas correctas segÃºn la familia de cargo.

## Resultado esperado

Carpeta del candidato creada automÃ¡ticamente con CV + plantillas (informe Excel y pauta Word) listas para iniciar.

## Precondiciones

- Formulario Forms "Solicitud de EvaluaciÃ³n Psicolaboral" publicado (campos segÃºn `solicitud-y-datos.md`).
- Excel "Registro de Solicitudes" en SharePoint con tabla `Respuestas` (columnas en `solicitud-y-datos.md`).
- LibrerÃ­a `EvaluaciÃ³n Psicolaboral` en `/sites/RRHH` con `_Plantillas/Informes`, `_Plantillas/Pautas`, `Solicitudes` e `InformesFinalizados`.
- Plan Planner "EvaluaciÃ³n Psicolaboral" con buckets: "Pendiente", "En proceso", "Completado", "Enviado".
- Licencia Power Automate Premium (necesaria para el conector robusto de SharePoint / HTTP versiÃ³n avanzada).
- Permisos del autor del flujo sobre la carpeta de adjuntos de Forms (OneDrive).

## Flujo Power Automate â€” secuencia de acciones

| # | AcciÃ³n | Conector | Detalle |
|---|--------|----------|---------|
| 1 | When a new response is submitted | Microsoft Forms | Form: "Solicitud de EvaluaciÃ³n Psicolaboral" |
| 2 | Get response details | Microsoft Forms | Response Id = `List of response notifications Response Id` |
| 3 | Compose â€” Normalizar nombre | Data Operation | Ver expresiÃ³n **Eâ€‘1** usando la respuesta `Nombre del candidato` |
| 4 | Initialize â€” CÃ³digo familia | Data Operation | String, vacÃ­o (se llena en el Switch) |
| 5 | Compose â€” Ruta informe | Data Operation | Ver **Eâ€‘2** |
| 6 | Compose â€” Ruta pauta | Data Operation | Ver **Eâ€‘3** |
| 7 | Create new folder | SharePoint | Site: `/sites/RRHH`, List: `EvaluaciÃ³n Psicolaboral`, Path `/Solicitudes`, Name = salida paso 3 |
| 8a | HTTP â€” Descargar CV | HTTP (Premium) | MÃ©todo GET, Uri = `File url` de la pregunta CV, AutenticaciÃ³n personalizada (token Graph) â€” ver **Consideraciones** |
| 8b | Create file | SharePoint | Folder = carpeta reciÃ©n creada, Name = `CV_<Normalizado>` + extensiÃ³n original, Content = body de 8a |
| 9 | Copy file | SharePoint | Source = salida paso 5, Destination = carpeta candidato, Dest. name = `Informe_<Normalizado>.xlsx` |
| 10 | Copy file | SharePoint | Source = salida paso 6, Destination = carpeta candidato, Dest. name = `PautaEntrevista_<Normalizado>.docx` |
| 11 | Update a row (o Add row) | Excel Online (Business) | `Estado = En proceso`, `CarpetaCandidato = <URL carpeta>` â€” ver **Eâ€‘4** |
| 12 | Create a task | Planner | TÃ­tulo = `<Nombre> â€” <Cargo>`, Bucket "En proceso", DescripciÃ³n con links â€” ver **Eâ€‘5** |
| 13 | Send an email (V2) | Office 365 Outlook | A psicÃ³logo/correo analista, con links a carpeta y CV |

> **El Switch** (resoluciÃ³n de familia â†’ cÃ³digo) se implementa como variable `CÃ³digo familia` asignada con un `Switch` o con `if()` encadenados, antes del paso 5-6. Cada rama: `Administrativa â†’ ADM`, `Operativa â†’ OPE`, etc. (tabla en `solicitud-y-datos.md`). Rama por defecto: enviar alerta y terminar e el flujo.

## Expresiones (Power Automate)

**Eâ€‘1 â€” Normalizar nombre** (minÃºsculas, sin tildes, espacios â†’ `_`):

```
replace(replace(replace(replace(replace(
  toLower(trim(items('Apply_to_each')?['NombreCandidato'])),
  'Ã¡','a'),'Ã©','e'),'Ã­','i'),'Ã³','o'),'Ãº','u')
```

> Simplificado: aplicar los `replace` de acentos y luego `replace(..,' ','_')` y los nueve `replace` de caracteres invÃ¡lidos de SharePoint (`" * : < > ? / \ |`), encadenados.

**Eâ€‘2 â€” Ruta plantilla informe:**

```
concat('/_Plantillas/Informes/', variables('CodigoFamilia'), '-informe.xlsx')
```

**Eâ€‘3 â€” Ruta plantilla pauta:**

```
concat('/_Plantillas/Pautas/', variables('CodigoFamilia'), '-pauta.docx')
```

**Eâ€‘4 â€” URL de la carpeta creada:**

```
concat('https://[tenant].sharepoint.com/sites/RRHH/Evaluacion%20Psicolaboral/Solicitudes/',
       uriComponent(outputs('Crear_carpeta')))
```

**Eâ€‘5 â€” TÃ­tulo y descripciÃ³n de la tarea Planner:**

```
TÃ­tulo:   concat(outputs('Get_response_details')?['NombreCandidato'], ' â€” ', outputs('Get_response_details')?['NombreCargo'])
DescripciÃ³n: carpeta: <Eâ€‘4> / CV: <File url> / familia: <CÃ³digo>
```

## ConfiguraciÃ³n previa en SharePoint

- Crear librerÃ­a `EvaluaciÃ³n Psicolaboral` en `/sites/RRHH` con `_Plantillas/Informes`, `_Plantillas/Pautas`, `Solicitudes` e `InformesFinalizados`.
- Subir una plantilla por familia usando la convenciÃ³n `COD-informe.xlsx` y `COD-pauta.docx` (ver `solicitud-y-datos.md`).

## Consideraciones tÃ©cnicas

- **Descarga del CV:** los adjuntos de Forms se guardan en OneDrive del autor del Forms y el `File url` requiere autenticaciÃ³n. Opciones:
  1. Conector `SharePoint` si el autor mueve el adjunto a la librerÃ­a (menos directo).
  2. Conector `HTTP` Premium con autenticaciÃ³n Graph (`GET /me/...` o el link recibido) y luego `Create file`.
  3. Guardar el `File url` en Excel y dejar descarga manual solo como respaldo.
- Conservar la **extensiÃ³n original** del CV (pdf/docx) al crear el archivo: `CV_<Normalizado>.pdf`, etc.
- **HTTP Premium** requiere licencia Power Automate Premium en la conexiÃ³n.
- AÃ±adir **control de errores** (Scope + Configure run after) en los pasos de copia para que un fallo no deje carpetas a medias.

## Checklist de validaciÃ³n (Etapa 1)

- [ ] Carpeta creada con nombre normalizado, sin caracteres invÃ¡lidos.
- [ ] CV guardado dentro de la carpeta con extensiÃ³n correcta.
- [ ] Se copiaron informe y pauta correctos segÃºn `CÃ³digo` de familia.
- [ ] Estado actualizado en Excel y tarea creada en Planner con bucket "En proceso".
- [ ] Familia sin cÃ³digo/con plantilla faltante genera alerta y no rompe el flujo.
- [ ] Nombre duplicado no pisa una carpeta existente (manejo de colisiÃ³n).
