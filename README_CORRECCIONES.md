# SIGMA-Aqua — revisión correctiva EP3

## MongoDB
Se eliminó drop(), se sustituyó use() por getSiblingDB para scripts mongosh, se corrigió la expresión suelta en Delete, se limitaron las eliminaciones a los dos códigos de prueba y se imprimen resultados. Las cargas usan upsert con $setOnInsert e índice único para evitar duplicados; el descuento de 35 peces se aplica una sola vez mediante ajuste_demo_aplicado. Las fechas especifican UTC-03:00 y distinct excluye PRUEBA. Se conservan las siete consultas y los cuatro operadores de actualización. Las cargas ahora son upserts, por lo que el informe debe actualizarse para describir este cambio respecto a insertOne/insertMany.

Ejecutar en una base de desarrollo, desde la raíz del proyecto, con mongosh instalado y conectado (no Node.js):

```powershell
mongosh --file NoSQL/Insert.js --file NoSQL/InsertMany.js --file NoSQL/Pruebas.js --file NoSQL/Read.js --file NoSQL/Update.js --file NoSQL/Delete.js
```

Para Atlas, agregar la URI de conexión como argumento de mongosh sin guardarla en el repositorio. Si existen duplicados previos, el índice único fallará: revisar manualmente los registros antes de continuar. No se borran automáticamente. Las pruebas iniciales esperan los datos de ejemplo; las cargas no revierten actualizaciones previas. Usar una instancia de prueba nueva para reproducir todos los resultados originales.

## Oracle
Se eliminó la contraseña fija y el parámetro interno _ORACLE_SCRIPT del script de creación de usuario; ejecutar en una PDB con SQL*Plus/SQLcl. Se limitó la cuota y se concedieron privilegios explícitos. Se serializó el procesamiento del staging para impedir carreras entre carga y purgado (puede bloquear escritores hasta COMMIT/ROLLBACK). Se hizo determinista la selección de umbrales en ambos triggers y el paquete. El test de monitoreo revierte cambios y señala fallos mediante excepción; ejecutar en una sesión dedicada sin transacciones pendientes y fuera de la ventana de mantenimiento. Los scripts de ejemplos históricos se conservan; agregar.sql es pseudocódigo, no un instalador ejecutable.

## Verificación y límites
Se ejecutó node --check sobre los seis scripts JavaScript, sin errores de sintaxis. No hay servidor MongoDB ni Oracle disponible en el entorno de revisión: no se ejecutaron operaciones reales ni se compiló PL/SQL. Las pruebas nuevas deben ejecutarse en el entorno del equipo. No se certifica ausencia total de errores. No se modificó GitHub. El ZIP excluye .git para no distribuir historial o configuración local.
