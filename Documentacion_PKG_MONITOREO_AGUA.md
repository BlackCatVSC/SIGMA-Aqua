# Documentación técnica: `PKG_MONITOREO_AGUA`

## 1. Contexto dentro de SIGMA-Aqua

SIGMA-Aqua contempla el monitoreo de la calidad del agua en centros de cultivo acuícola mediante sensores instalados en los tanques. El paquete `PKG_MONITOREO_AGUA` concentra operaciones reutilizables para procesar lecturas, mantener una referencia de las últimas mediciones y calcular indicadores de calidad.

**Archivo de implementación:** `SQL/02_Triggers_y_Funciones/PKG_MONITOREO_AGUA.sql`  
**Archivo complementario de triggers:** `SQL/02_Triggers_y_Funciones/triggers_monitoreo.sql`  
**Motor previsto:** Oracle Database 21c / PL/SQL.

El paquete se divide en dos partes:

- **Especificación (`PACKAGE`)**: Este declara constantes, procedimientos y funciones que otros scripts pueden invocar.

- **Cuerpo (`PACKAGE BODY`)**: Este contiene las consultas y operaciones que implementan esa lógica, además de funciones y procedimientos auxiliares privados.

## 2. ¿Qué problema resuelve?

Sin centralizar esta lógica, distintos procesos tendrían que repetir consultas y actualizaciones para procesar mediciones, actualizar los valores más recientes y obtener indicadores. El paquete permite reutilizar esas reglas desde otros bloques PL/SQL y mantiene un flujo común de procesamiento.

Sus responsabilidades principales son:

1. Cargar lecturas pendientes desde `MEDICIONES_STAGING` al histórico `HISTORIAL_MEDICIONES`.
2. Actualizar o insertar el resumen de últimas mediciones por tanque en `ULTIMAS_MEDICIONES`.
3. Calcular el Índice de Calidad de Agua (ICA).
4. Contar alertas pendientes y calcular promedios de lecturas recientes por tipo de sensor.

## 3. Elementos públicos

| Elemento                       | Tipo                         | Función                                                                                 |
|--------------------------------|------------------------------|-----------------------------------------------------------------------------------------| 
| `sp_procesar_lecturas_masivas` | Procedimiento con parámetros | Procesa lecturas de un centro y fecha; informa cantidad procesada y código de error.    |
| `sp_procesar_todo`             | Procedimiento sin parámetros | Recorre los centros que tienen lecturas pendientes e intenta procesarlos.               |
| `fn_calcular_ica`              | Función                      | Calcula un índice entre 0 y 100 a partir de las últimas mediciones de un tanque.        |
| `fn_total_alertas_pendientes`  | Función                      | Devuelve cuántas alertas están pendientes de atención.                                  |
| `fn_promedio_sensor`           | Función con parámetros       | Calcula el promedio de la última lectura de cada sensor de un tipo dentro de un centro. |
|--------------------------------|------------------------------|-----------------------------------------------------------------------------------------|

El paquete también define constantes públicas para estados como `PENDIENTE`, `PROCESADO`, `NORMAL` y `ALERTA`. Entre los auxiliares privados se encuentran la obtención de la última medición por tipo y el procedimiento que refresca `ULTIMAS_MEDICIONES` mediante `MERGE`.

## 4. Flujo de procesamiento de lecturas

Cuando se ejecuta `sp_procesar_lecturas_masivas`, el procedimiento:

1. Selecciona desde `MEDICIONES_STAGING` las lecturas del centro y día indicados cuyo estado aún no sea `PROCESADO`.
2. Inserta esas lecturas en `HISTORIAL_MEDICIONES`, asignando identificadores mediante `seq_medicion.NEXTVAL`.
3. Identifica los tanques afectados y actualiza sus últimas mediciones con `p_refrescar_ultimo`. El `MERGE` inserta una fila si no existe o actualiza la que ya existe.
4. Elimina del staging las filas del centro y fecha procesados.
5. Devuelve en `p_total_procesados` el número de filas insertadas y en `p_codigo_error` el código `0` si terminó correctamente.

`sp_procesar_todo` automatiza el recorrido de los centros que tienen lecturas pendientes y muestra un resumen con `DBMS_OUTPUT`.

**Importante:** el código actual filtra las lecturas por fecha y centro, pero al eliminar del staging borra todas las filas de ese centro y día, no solamente las que fueron insertadas. Antes de usarlo en producción, conviene revisar si las filas que ya estaban marcadas como procesadas deben conservarse o eliminarse. Además, la rutina captura errores y devuelve `SQLCODE`; el proceso que la llama debe comprobar ese código y definir cómo manejar los casos fallidos.

## 5. Cálculo del Índice de Calidad de Agua (ICA)

`fn_calcular_ica(p_id_tanque)` parte de un valor de **100 puntos** y aplica estas penalizaciones cuando existen valores registrados:

| Parámetro        | Condición fuera de rango      | Penalización |
|------------------|-------------------------------|--------------|
| pH               | Menor que 6,5 o mayor que 8,5 | 25 puntos    |
| Oxígeno disuelto | Menor que 5,0                 | 40 puntos    |
| Temperatura      | Menor que 8 o mayor que 16    | 20 puntos    |
|------------------|-------------------------------|--------------|

El resultado no puede ser menor que cero. Si el tanque no tiene una fila en `ULTIMAS_MEDICIONES`, la función devuelve `NULL`. Estos límites y penalizaciones corresponden a las reglas codificadas en este paquete; deben validarse con los criterios técnicos definidos por el proyecto antes de considerarlos parámetros productivos.

## 6. Relación con los triggers del módulo

El archivo `triggers_monitoreo.sql` complementa el paquete con dos triggers:

### `trg_evaluar_lectura_sensor`

Se ejecuta después de insertar cada fila en `HISTORIAL_MEDICIONES`. Busca el tipo de sensor y el centro asociado, obtiene el umbral aplicable (prioriza uno específico del centro frente a uno general) y compara el valor insertado con los límites. Si la lectura está fuera de rango, crea una fila en `ALERTA` y una acción sugerida en `ACCION_CORRECTIVA`.

Por ello, cuando el paquete inserta lecturas en el histórico, este trigger puede generar alertas automáticamente para cada lectura que incumpla los umbrales configurados.

### `trg_ventana_mantenimiento`

Se ejecuta antes de insertar, actualizar o eliminar filas de `HISTORIAL_MEDICIONES`. Bloquea esas operaciones entre las **04:00 y las 05:59**, mediante el error Oracle `-20010`. Como es un trigger a nivel de sentencia, se ejecuta una vez por sentencia, no una vez por fila.

## 7. Cómo ejecutar y probar en Oracle SQL Developer

Ejecutar los scripts en este orden, usando el esquema correcto y verificando que las tablas, secuencias y dependencias existan:

1. Crear las tablas del módulo de monitoreo (`SQL/01_Estructura_Tablas/DataModeler_monitoreo.sql`).
2. Compilar el paquete (`SQL/02_Triggers_y_Funciones/PKG_MONITOREO_AGUA.sql`).
3. Compilar los triggers (`SQL/02_Triggers_y_Funciones/triggers_monitoreo.sql`).
4. Cargar datos de prueba compatibles con las claves foráneas y umbrales configurados.

* Para procesar todas las lecturas pendientes:

```sql
SET SERVEROUTPUT ON;

BEGIN
    PKG_MONITOREO_AGUA.sp_procesar_todo;
END;
/
```

* Para consultar alertas y acciones generadas:

```sql
SELECT * FROM ALERTA ORDER BY FECHA_ALERTA DESC;
SELECT * FROM ACCION_CORRECTIVA ORDER BY FECHA_ACCION DESC;
```

* Para consultar el ICA de un tanque (reemplazar `101` por un `ID_TANQUE` existente):

```sql
SELECT PKG_MONITOREO_AGUA.fn_calcular_ica(101) AS ICA
FROM DUAL;
```

* Para contar alertas pendientes:

```sql
SELECT PKG_MONITOREO_AGUA.fn_total_alertas_pendientes AS ALERTAS_PENDIENTES
FROM DUAL;
```

* Para calcular el promedio de las últimas lecturas de un tipo de sensor en un centro (reemplazar ambos identificadores por valores existentes):

```sql
SELECT PKG_MONITOREO_AGUA.fn_promedio_sensor(1, 2) AS PROMEDIO
FROM DUAL;
```

* Los valores `101`, `1` y `2` son ejemplos, no identificadores garantizados en los datos del proyecto.

## 8. Consideraciones y validaciones

- Revisar en SQL Developer que el paquete y los triggers hayan compilado sin errores. Consultar los errores con:

  ```sql
  SELECT NAME, TYPE, LINE, POSITION, TEXT
  FROM USER_ERRORS
  WHERE NAME IN ('PKG_MONITOREO_AGUA', 'TRG_EVALUAR_LECTURA_SENSOR', 'TRG_VENTANA_MANTENIMIENTO')
  ORDER BY NAME, SEQUENCE;
  ```

- Cosas a confirmar: Que `MEDICIONES_STAGING`, `HISTORIAL_MEDICIONES`, `ULTIMAS_MEDICIONES`, `SENSOR`, `TANQUE`, `TIPO_SENSOR`, `UMBRAL`, `ALERTA` y `ACCION_CORRECTIVA`  tengan las columnas que utiliza el código.
- Verificar que existan y estén correctamente configuradas las secuencias `SEQ_MEDICION` y `SEQ_ALERTA`.
- Probar tanto lecturas dentro de rango como fuera de rango y comprobar la creación automática de alertas.
- Probar el bloqueo de mantenimiento únicamente en el horario configurado o en un entorno de pruebas controlado.
- Confirmar el comportamiento transaccional y la política de conservación/eliminación de registros del staging antes de utilizar datos reales.

