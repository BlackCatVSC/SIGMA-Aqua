SET DEFINE OFF;

-- ================================================================================
-- SCRIPT PL/SQL: TRIGGERS DEL MODULO DE MONITOREO (SIGMA-Aqua)
-- Esquema objetivo : DataModeler_monitoreo.sql + PKG_MONITOREO_AGUA.sql
-- Asignatura       : BDY1103 - Taller de Base de Datos (Duoc UC)
-- Motor BD         : Oracle Database 21c
-- --------------------------------------------------------------------------------
-- Descripcion      : Triggers que controlan operaciones sobre el modulo de
--                    monitoreo de calidad de agua:
--                      * A NIVEL DE FILA      : alerta automatica por lectura
--                                               fuera de rango.
--                      * A NIVEL DE SENTENCIA : bloqueo de operaciones durante
--                                               la ventana de mantenimiento.
-- Version corregida: ver Correcciones_SIGMA-Aqua.txt
-- ================================================================================

-- ================================================================================
-- 1. TRIGGER A NIVEL DE FILA (AFTER INSERT FOR EACH ROW)
--    Analiza cada lectura insertada en el historico. Si el valor sobrepasa los
--    umbrales configurados para el tipo de sensor, genera automaticamente una
--    alerta y sugiere una accion correctiva.
-- ================================================================================
CREATE OR REPLACE TRIGGER trg_evaluar_lectura_sensor
AFTER INSERT ON HISTORIAL_MEDICIONES
FOR EACH ROW
DECLARE
    v_id_tipo   SENSOR.ID_TIPO_SENSOR%TYPE;
    v_nombre    TIPO_SENSOR.NOMBRE_TIPO_SENSOR%TYPE;
    v_unidad    TIPO_SENSOR.UNIDAD_MEDIDA%TYPE;
    v_tanque    TANQUE.NOMBRE_TANQUE%TYPE;
    v_id_centro CENTRO_CULTIVO.ID_CENTRO%TYPE;
    v_min       UMBRAL.VALOR_MIN%TYPE;
    v_max       UMBRAL.VALOR_MAX%TYPE;
    v_severidad UMBRAL.SEVERIDAD%TYPE;
    v_id_alerta ALERTA.ID_ALERTA%TYPE;
BEGIN
    -- 1) Identifica tipo de sensor, unidad, tanque y centro del sensor
    SELECT s.ID_TIPO_SENSOR, ts.NOMBRE_TIPO_SENSOR, ts.UNIDAD_MEDIDA,
           t.NOMBRE_TANQUE, t.ID_CENTRO
      INTO v_id_tipo, v_nombre, v_unidad, v_tanque, v_id_centro
      FROM SENSOR s
      JOIN TIPO_SENSOR ts ON s.ID_TIPO_SENSOR = ts.ID_TIPO_SENSOR
      JOIN TANQUE t       ON s.ID_TANQUE = t.ID_TANQUE
     WHERE s.ID_SENSOR = :NEW.ID_SENSOR;

    -- 2) Obtiene el umbral (especifico del centro si existe, si no el general)
    BEGIN
        SELECT VALOR_MIN, VALOR_MAX, SEVERIDAD
          INTO v_min, v_max, v_severidad
          FROM UMBRAL
         WHERE ID_TIPO_SENSOR = v_id_tipo
           AND (ID_CENTRO IS NULL OR ID_CENTRO = v_id_centro)
         ORDER BY CASE WHEN ID_CENTRO = v_id_centro THEN 1 ELSE 0 END DESC
         FETCH FIRST 1 ROW ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN; -- sin umbral configurado: no corresponde evaluar
    END;

    -- 3) Evaluacion de fuera de rango (un limite NULL no se evalua)
    IF (v_min IS NOT NULL AND :NEW.VALOR < v_min)
       OR (v_max IS NOT NULL AND :NEW.VALOR > v_max) THEN

        INSERT INTO ALERTA (ID_ALERTA, ID_SENSOR, ID_MEDICION, ID_TIPO_SENSOR,
                            VALOR, VALOR_MIN, VALOR_MAX, SEVERIDAD,
                            MENSAJE, FECHA_ALERTA, ESTADO_ALERTA)
        VALUES (seq_alerta.NEXTVAL, :NEW.ID_SENSOR, :NEW.ID_MEDICION, v_id_tipo,
                :NEW.VALOR, v_min, v_max, v_severidad,
                'Valor ' || v_nombre || ' (' || :NEW.VALOR || ' ' || v_unidad ||
                ') fuera de rango [' || v_min || ' - ' || v_max || '] en ' || v_tanque,
                SYSDATE, 'PENDIENTE')
        RETURNING ID_ALERTA INTO v_id_alerta;

        INSERT INTO ACCION_CORRECTIVA (DESCRIPCION_ACCION, ESTADO_ACCION, FECHA_ACCION, ID_ALERTA)
        VALUES ('Revisar sensor ' || v_nombre || ' de ' || v_tanque ||
                ' y evaluar parametros del agua',
                'PENDIENTE', SYSDATE, v_id_alerta);
    END IF;
END trg_evaluar_lectura_sensor;
/

-- ================================================================================
-- 2. TRIGGER A NIVEL DE SENTENCIA (sin FOR EACH ROW)
--    Impide insertar/actualizar/borrar lecturas durante la ventana de
--    mantenimiento diaria (04:00 a 05:59, HORA DE CHILE). Se dispara UNA VEZ
--    por sentencia, independiente del numero de filas afectadas.
--    Se usa la zona America/Santiago para no depender de la hora del servidor.
-- ================================================================================
CREATE OR REPLACE TRIGGER trg_ventana_mantenimiento
BEFORE INSERT OR UPDATE OR DELETE ON HISTORIAL_MEDICIONES
DECLARE
    v_hora NUMBER;
BEGIN
    v_hora := TO_NUMBER(TO_CHAR(SYSTIMESTAMP AT TIME ZONE 'America/Santiago', 'HH24'));
    IF v_hora BETWEEN 4 AND 5 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Ventana de mantenimiento: no se permiten operaciones sobre mediciones entre 04:00 y 05:59.');
    END IF;
END trg_ventana_mantenimiento;
/

-- ================================================================================
-- 3. PRUEBAS SUGERIDAS
-- ================================================================================
-- a) Procesar lecturas y verificar alertas generadas:
--    BEGIN PKG_MONITOREO_AGUA.sp_procesar_todo; END;
--    /
--    SELECT * FROM ALERTA;
--    SELECT * FROM ACCION_CORRECTIVA;
--
-- b) Verificar que el trigger de sentencia bloquea en la ventana (solo si son
--    las 04:00 - 05:59 hora de Chile); fuera de ella las operaciones pasan
--    normalmente.
-- ================================================================================
