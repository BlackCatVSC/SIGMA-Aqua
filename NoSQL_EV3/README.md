# SIGMA-Aqua — Evaluación 3: MongoDB

Este módulo incorpora una base de datos documental en MongoDB para registrar centros de cultivo, mediciones de calidad del agua y alertas. Complementa el trabajo del proyecto SIGMA-Aqua; no sustituye los archivos SQL de Oracle.

## Requisitos

- Windows 10 u 11 con PowerShell.
- MongoDB Community Server y MongoDB Shell (`mongosh`).
- Node.js para revisar la sintaxis de los scripts.
- MongoDB Compass (opcional, para visualizar documentos e índices).

La instalación de las herramientas se explica en `../Guia_Instalacion_y_Ejecucion_SIGMA_Aqua_EV3.txt`.

## Archivos del módulo

| Archivo | Función |
| --- | --- |
| `01_creacion.js` | Crea las colecciones, validadores e índices. |
| `02_datos_iniciales.js` | Carga los datos de ejemplo. |
| `03_crud.js` | Demuestra creación, lectura, actualización y eliminación. |
| `04_pruebas.js` | Ejecuta ocho pruebas básicas. |
| `05_consultas_avanzadas.js` | Consulta mediciones, agrupa alertas y calcula promedios. |
| `06_validaciones_negocio.js` | Comprueba referencias y rangos ilustrativos. |
| `07_pruebas_ampliadas.js` | Ejecuta cinco pruebas adicionales. |
| `verificar_archivos.ps1` | Comprueba los archivos y la sintaxis JavaScript. |
| `MODELO_NoSQL.svg` | Diagrama del modelo documental. |
| `GUIA_EV3.md` | Relación de la implementación con los requisitos de la evaluación. |

## Puesta en marcha

Abrir PowerShell en la carpeta `NoSQL_EV3` y comprobar los archivos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verificar_archivos.ps1
```

Verificar que MongoDB esté iniciado y responda:

```powershell
Get-Service MongoDB
mongosh "mongodb://127.0.0.1:27017" --eval "db.runCommand({ping:1})"
```

La respuesta esperada de la conexión es `{ ok: 1 }`.

### Primera ejecución

En una base de datos nueva, ejecutar los scripts en este orden:

```powershell
mongosh "mongodb://127.0.0.1:27017" --file .\01_creacion.js
mongosh "mongodb://127.0.0.1:27017" --file .\02_datos_iniciales.js
mongosh "mongodb://127.0.0.1:27017" --file .\03_crud.js
mongosh "mongodb://127.0.0.1:27017" --file .\04_pruebas.js
mongosh "mongodb://127.0.0.1:27017" --file .\05_consultas_avanzadas.js
mongosh "mongodb://127.0.0.1:27017" --file .\06_validaciones_negocio.js
mongosh "mongodb://127.0.0.1:27017" --file .\07_pruebas_ampliadas.js
```

Para revisar una instalación que ya contiene datos, no es necesario volver a ejecutar la carga inicial. Antes de repetir scripts que escriben documentos, revisar su efecto sobre la base existente.

## Resultados de la verificación

En la ejecución local del 23 de noviembre de 2026 se obtuvieron los siguientes resultados:

| Comprobación | Resultado |
| --- | --- |
| Conexión MongoDB | Correcta (`ok: 1`) |
| Colecciones | `centros`, `mediciones`, `alertas` |
| Datos de ejemplo | 2 centros, 5 mediciones, 3 alertas |
| Pruebas básicas | 8 correctas, 0 fallidas |
| Pruebas ampliadas | 5 correctas, 0 fallidas |
| Referencias inválidas | 0 |
| Valores fuera de rangos ilustrativos | 3 |

Los tres valores fuera de rango corresponden a los datos de demostración y no indican un error de ejecución. Los umbrales son ejemplos académicos, no límites normativos.

## Visualización en MongoDB Compass

Conectarse a `mongodb://127.0.0.1:27017` y abrir la base de datos `sigma_aqua`. En la colección `mediciones`, la pestaña **Indexes** permite revisar los índices `_id_`, `codigoMedicion_1` y `codigoCentro_1_fecha_-1`.

## Informe y documentación

- Informe EV3 en PDF: `../Documentacion_y_Recursos/Informe_SIGMA_Aqua_EV3.pdf`.
- Informe EV3 editable: `../Documentacion_y_Recursos/Informe_SIGMA_Aqua_EV3_Version_Final.docx`.
- Guía de instalación para otros equipos: `../Guia_Instalacion_y_Ejecucion_SIGMA_Aqua_EV3.txt`.

El informe documenta el modelo NoSQL, las operaciones CRUD, las consultas, los índices, las validaciones y los resultados obtenidos. No se requiere una presentación PowerPoint específica para esta entrega.
