# SIGMA-Aqua — Guía técnica y correspondencia con EV3

## Alcance
Este módulo es una **demostración NoSQL complementaria** al esquema Oracle del repositorio.
No es una migración integral ni reemplaza las reglas PL/SQL del proyecto original.
Se usan datos sintéticos de ejemplo; no se declaran mediciones reales.

## Contexto y datos
SIGMA-Aqua gestiona monitoreo de agua en centros acuícolas. Interesa consultar
centros, tanques, sensores, mediciones temporales y alertas.

## Diseño y justificación
- MongoDB es una base NoSQL **documental** (documentos BSON).
- `centros`: tanques y sensores embebidos; se consultan habitualmente juntos y cambian poco.
- `mediciones`: colección independiente por volumen y consulta temporal.
- `alertas`: colección independiente para seguimiento y estados.
- Se usan códigos de referencia, índices y validación JSON Schema.
- No hay claves foráneas automáticas: `06_validaciones_negocio.js` revisa integridad lógica
  de los datos existentes. Una aplicación real debe validar estas relaciones al escribir.
- Los umbrales del ejemplo NO sustituyen valores técnicos o regulatorios del caso.

## SQL frente a NoSQL
| Tema | Oracle relacional | MongoDB documental |
| --- | --- | --- |
| Estructura | Tablas, relaciones, claves foráneas | Colecciones y documentos anidados |
| Esquema | Declarado en tablas | Flexible, con validadores opcionales |
| Consultas | SQL y JOIN | Consultas de documentos y agregaciones |
| Integridad | Restricciones relacionales | Validación y lógica de aplicación |
| Adecuado para | Operaciones con relaciones y consistencia compleja | Documentos variables y registros de eventos |

Otros tipos NoSQL: clave-valor (Redis), columnas anchas (Cassandra), grafos (Neo4j).
MongoDB se eligió para demostrar documentos de mediciones y tanques sin reescribir Oracle.

## Evidencia real que falta generar
- Capturas de las colecciones en MongoDB Compass.
- Capturas de salida de scripts 03, 04, 06 y 07 ejecutados en el equipo.
- Confirmación de la versión de MongoDB y de los resultados.
- Informe EV3 y presentación ejecutiva, con resultados verificados.

## Guion de presentación
1. Problema: monitoreo de calidad de agua.
2. Datos: centros, tanques, sensores, mediciones y alertas.
3. Diferencias Oracle SQL / MongoDB NoSQL.
4. Diagrama y razones para embebidos/referencias.
5. Demostración CREATE, READ, UPDATE y DELETE.
6. Pruebas, limitaciones y conclusión.

## Precaución
No ejecutar en producción. Scripts de pruebas usan códigos temporales reservados.
Los scripts 01 y 02 crean/actualizan objetos de ejemplo; 01 puede actualizar validadores.
