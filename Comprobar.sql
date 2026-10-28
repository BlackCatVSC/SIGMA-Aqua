-- 1.- Comprobar el estado de los objetos de la base de datos

SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME IN (
    'PKG_MONITOREO_AGUA',
    'PKG_SIGMA_AQUA',
    'V_ICA_CENTRO',
    'TRG_EVALUAR_LECTURA_SENSOR',
    'TRG_VENTANA_MANTENIMIENTO'
)
ORDER BY OBJECT_TYPE, OBJECT_NAME;

-- 2.- Comprobar el estado y los eventos de los triggers

SELECT TRIGGER_NAME, STATUS, TRIGGERING_EVENT, TABLE_NAME
FROM USER_TRIGGERS
WHERE TRIGGER_NAME IN (
    'TRG_EVALUAR_LECTURA_SENSOR',
    'TRG_VENTANA_MANTENIMIENTO'
);

-- 3.- Contar los registros de las tablas principales

SELECT 'CENTRO_CULTIVO' AS TABLA, COUNT(*) AS TOTAL
FROM CENTRO_CULTIVO
UNION ALL
SELECT 'TANQUE', COUNT(*)
FROM TANQUE
UNION ALL
SELECT 'MEDICIONES_STAGING', COUNT(*)
FROM MEDICIONES_STAGING
UNION ALL
SELECT 'HISTORIAL_MEDICIONES', COUNT(*)
FROM HISTORIAL_MEDICIONES
UNION ALL
SELECT 'ALERTA', COUNT(*)
FROM ALERTA
UNION ALL
SELECT 'ACCION_CORRECTIVA', COUNT(*)
FROM ACCION_CORRECTIVA;

-- 4.- Consultar las mediciones de entrada

SELECT *
FROM MEDICIONES_STAGING;

-- 5.- Ejecutar el procesamiento masivo de mediciones


SET SERVEROUTPUT ON;

BEGIN
    PKG_MONITOREO_AGUA.sp_procesar_todo;
END;
/

-- 6.- Revisar el historial de mediciones

SELECT *
FROM HISTORIAL_MEDICIONES
ORDER BY FECHA_HORA DESC;

-- 7.- Consultar las últimas mediciones

SELECT *
FROM ULTIMAS_MEDICIONES;

-- 8.- Revisar las alertas generadas

SELECT *
FROM ALERTA
ORDER BY FECHA_ALERTA DESC;

-- 9.- Consultar las acciones correctivas

SELECT *
FROM ACCION_CORRECTIVA;

-- 10.- Consultar la vista del ICA por centro

SELECT *
FROM V_ICA_CENTRO;

-- 11.- Comprobar los triggers

SELECT
    TRIGGER_NAME,
    STATUS,
    TRIGGERING_EVENT,
    TABLE_NAME
FROM USER_TRIGGERS
WHERE TRIGGER_NAME IN (
    'TRG_EVALUAR_LECTURA_SENSOR',
    'TRG_VENTANA_MANTENIMIENTO'
);

-- 12.- Comprobar específicamente el paquete de auditoría

SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME = 'PKG_SIGMA_AQUA';

-- 13.- Buscar todos los objetos cuyo nombre contenga SIGMA y AQUA


SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE UPPER(OBJECT_NAME) LIKE '%SIGMA%AQUA%';

-- 14.- Revisar el código fuente entre las líneas 100 y 150

SELECT LINE, TEXT
FROM USER_SOURCE
WHERE NAME = 'PKG_SIGMA_AQUA'
  AND TYPE = 'PACKAGE BODY'
  AND LINE BETWEEN 100 AND 150
ORDER BY LINE;

-- 15.- Buscar las referencias a la función privada f_peso_promedio

SELECT LINE, TEXT
FROM USER_SOURCE
WHERE NAME = 'PKG_SIGMA_AQUA'
  AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
  AND UPPER(TEXT) LIKE '%F_PESO_PROMEDIO%'
ORDER BY TYPE, LINE;

--16.- Revisar las líneas cercanas al error de compilación

SELECT LINE, TEXT
FROM USER_SOURCE
WHERE NAME = 'PKG_SIGMA_AQUA'
  AND TYPE = 'PACKAGE BODY'
  AND LINE BETWEEN 140 AND 165
ORDER BY LINE;

-- 17.- Comprobar el estado de compilación del paquete

SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME = 'PKG_SIGMA_AQUA'
ORDER BY OBJECT_TYPE;

-- 18.- Ejecutar la auditoría masiva de biomasa y normativa sanitaria

SET SERVEROUTPUT ON;

BEGIN
    PKG_SIGMA_AQUA.sp_auditar_todos;
END;
/

-- 19.- Comprobación final de los dos paquetes principales

SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME IN (
    'PKG_SIGMA_AQUA',
    'PKG_MONITOREO_AGUA'
)
ORDER BY OBJECT_NAME, OBJECT_TYPE;

-- 20.- A. Comprobar la biomasa de un lote

SELECT
    ID_LOTE,
    PKG_SIGMA_AQUA.fn_biomasa_lote(ID_LOTE) AS BIOMASA_KG
FROM LOTE
ORDER BY ID_LOTE;

-- 21.- B. Comprobar la densidad de cada centro

SELECT
    ID_CENTRO,
    NOMBRE_CENTRO,
    VOLUMEN_CENTRO_M3,
    PKG_SIGMA_AQUA.fn_densidad_centro(ID_CENTRO)
        AS DENSIDAD_KG_M3
FROM CENTRO_CULTIVO
ORDER BY ID_CENTRO;

--22.- C. Comprobar cuántos centros están activos

SELECT
    PKG_SIGMA_AQUA.fn_total_centros_activos
        AS TOTAL_CENTROS_ACTIVOS
FROM DUAL;

--23.- D. Comprobar la biomasa total de una empresa

SELECT DISTINCT ID_EMPRESA
FROM CENTRO_CULTIVO
ORDER BY ID_EMPRESA;

SELECT
    PKG_SIGMA_AQUA.fn_biomasa_total_empresa(
        ID_EMPRESA
    ) AS BIOMASA_TOTAL_KG
FROM (
    SELECT DISTINCT ID_EMPRESA
    FROM CENTRO_CULTIVO
);

-- “En SIGMA-Aqua realizamos una serie de comprobaciones para verificar el funcionamiento de la base de datos. Primero revisamos que los paquetes, 
-- la vista del ICA y los triggers estuvieran creados y válidos. Después contamos los registros de las tablas principales 
--y revisamos las mediciones que ingresan al sistema.

--A continuación, ejecutamos el procesamiento masivo del paquete de monitoreo, 
--que procesó cinco lecturas sin errores reportados. Revisamos el historial, las últimas mediciones, 
--las alertas y las acciones correctivas para comprobar los resultados almacenados.

--También depuramos el paquete de auditoría de biomasa, utilizando el código fuente almacenado en Oracle para encontrar y 
--corregir un error relacionado con una función privada. Finalmente, 
--ejecutamos la auditoría de todos los centros activos y comprobamos que el sistema detectara correctamente el exceso de biomasa, las zonas en cuarentena 
--y el volumen cero. Terminamos verificando que los cuatro objetos de los dos paquetes principales estuvieran en estado VALID”