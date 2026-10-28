SET SERVEROUTPUT ON;

-- ================================================================================
-- SCRIPT PL/SQL: PACKAGE PKG_MONITOREO_AGUA (SIGMA-Aqua)
-- Esquema objetivo : DataModeler_monitoreo.sql (modulo de monitoreo de agua)
-- Asignatura       : BDY1103 - Taller de Base de Datos (Duoc UC)
-- Motor BD         : Oracle Database 21c
-- --------------------------------------------------------------------------------
-- Descripcion      : Encapsula la logica de negocio del monitoreo de calidad de
--                    agua en un solo objeto reutilizable:
--                      * Procesamiento masivo (bulk) de lecturas de sensores.
--                      * Actualizacion del ultimo estado conocido por tanque.
--                      * Calculo del Indice de Calidad de Agua (ICA).
--                    Distingue elementos PUBLICOS (especificacion) y PRIVADOS
--                    (cuerpo).
-- Version corregida: ver Correcciones_SIGMA-Aqua.txt
-- ================================================================================

-- ================================================================================
-- 1. ESPECIFICACION DEL PACKAGE (PARTE PUBLICA)
-- ================================================================================
CREATE OR REPLACE PACKAGE PKG_MONITOREO_AGUA AS

    -- ----------------------------------------------------------------------------
    -- CONSTANTES PUBLICAS: valores de dominio reutilizables por la aplicacion
    -- ----------------------------------------------------------------------------
    gc_estado_pendiente CONSTANT VARCHAR2(20) := 'PENDIENTE';
    gc_estado_procesado CONSTANT VARCHAR2(20) := 'PROCESADO';
    gc_estado_normal    CONSTANT VARCHAR2(20) := 'NORMAL';
    gc_estado_alerta    CONSTANT VARCHAR2(20) := 'ALERTA';

    -- ----------------------------------------------------------------------------
    -- PROCEDIMIENTOS PUBLICOS
    -- ----------------------------------------------------------------------------
    -- CON parametros (IN y OUT): procesa en bloque las lecturas de staging de un
    -- centro en una fecha determinada, moviendolas al historico, refrescando el
    -- ultimo estado de los tanques y purgando el buffer.
    PROCEDURE sp_procesar_lecturas_masivas(
        p_id_centro        IN  NUMBER,
        p_fecha_proceso    IN  DATE,
        p_total_procesados OUT NUMBER,
        p_codigo_error     OUT NUMBER
    );

    -- SIN parametros: procesa todas las lecturas pendientes (todos los centros
    -- y todas las fechas).
    PROCEDURE sp_procesar_todo;

    -- ----------------------------------------------------------------------------
    -- FUNCIONES PUBLICAS (usables directamente en sentencias SQL)
    -- ----------------------------------------------------------------------------
    -- CON parametro: Indice de Calidad de Agua (0-100) de un tanque
    FUNCTION fn_calcular_ica(p_id_tanque NUMBER) RETURN NUMBER;

    -- SIN parametro: total de alertas pendientes de atencion
    FUNCTION fn_total_alertas_pendientes RETURN NUMBER;

    -- CON parametros: promedio de la ultima lectura de cada sensor de un tipo
    -- dentro de un centro de cultivo
    FUNCTION fn_promedio_sensor(p_id_centro NUMBER, p_id_tipo_sensor NUMBER) RETURN NUMBER;

END PKG_MONITOREO_AGUA;
/

-- ================================================================================
-- 2. CUERPO DEL PACKAGE (PARTE PRIVADA + IMPLEMENTACION)
-- ================================================================================
CREATE OR REPLACE PACKAGE BODY PKG_MONITOREO_AGUA AS

    -- ============================================================================
    -- SECCION PRIVADA: funciones/procedimientos auxiliares NO visibles desde fuera
    -- ============================================================================

    -------------------------------------------------------------------------------
    -- (PRIVADA) Emisor de mensajes por pantalla (centraliza DBMS_OUTPUT).
    -------------------------------------------------------------------------------
    PROCEDURE p_log(p_mensaje VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_mensaje);
    END p_log;

    -------------------------------------------------------------------------------
    -- (PRIVADA) Ultima medicion registrada de un tipo de sensor para un tanque.
    -- Retorna NULL si no existen lecturas de ese tipo para el tanque.
    -------------------------------------------------------------------------------
    FUNCTION f_ultima_medicion(p_id_tanque NUMBER, p_tipo VARCHAR2) RETURN NUMBER IS
        v_valor NUMBER;
    BEGIN
        SELECT m.VALOR
          INTO v_valor
          FROM HISTORIAL_MEDICIONES m
          JOIN SENSOR s        ON m.ID_SENSOR = s.ID_SENSOR
          JOIN TIPO_SENSOR ts  ON s.ID_TIPO_SENSOR = ts.ID_TIPO_SENSOR
         WHERE s.ID_TANQUE = p_id_tanque
           AND UPPER(ts.NOMBRE_TIPO_SENSOR) = UPPER(p_tipo)
         ORDER BY m.FECHA_HORA DESC, m.ID_MEDICION DESC
         FETCH FIRST 1 ROW ONLY;
        RETURN v_valor;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_ultima_medicion;

    -------------------------------------------------------------------------------
    -- (PRIVADA) Indica si un valor esta fuera del umbral configurado en la tabla
    -- UMBRAL para un tipo de sensor. Usa el umbral del centro si existe; si no,
    -- el general. Es la MISMA regla que usa el trigger trg_evaluar_lectura_sensor,
    -- asi alertas e ICA siempre coinciden.
    -- Retorna FALSE si no hay valor o no hay umbral configurado.
    -------------------------------------------------------------------------------
    FUNCTION f_fuera_rango(p_valor NUMBER, p_tipo VARCHAR2, p_id_centro NUMBER) RETURN BOOLEAN IS
        v_min UMBRAL.VALOR_MIN%TYPE;
        v_max UMBRAL.VALOR_MAX%TYPE;
    BEGIN
        IF p_valor IS NULL THEN
            RETURN FALSE;
        END IF;

        SELECT u.VALOR_MIN, u.VALOR_MAX
          INTO v_min, v_max
          FROM UMBRAL u
          JOIN TIPO_SENSOR ts ON u.ID_TIPO_SENSOR = ts.ID_TIPO_SENSOR
         WHERE UPPER(ts.NOMBRE_TIPO_SENSOR) = UPPER(p_tipo)
           AND (u.ID_CENTRO IS NULL OR u.ID_CENTRO = p_id_centro)
         ORDER BY CASE WHEN u.ID_CENTRO = p_id_centro THEN 1 ELSE 0 END DESC
         FETCH FIRST 1 ROW ONLY;

        RETURN (v_min IS NOT NULL AND p_valor < v_min)
            OR (v_max IS NOT NULL AND p_valor > v_max);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_fuera_rango;

    -------------------------------------------------------------------------------
    -- (PRIVADA) Refresca la tabla ULTIMAS_MEDICIONES de un tanque a partir del
    -- historico. Se implementa con MERGE (UPSERT): inserta si el tanque no tiene
    -- fila o actualiza los cinco parametros con su ultima lectura.
    -------------------------------------------------------------------------------
    PROCEDURE p_refrescar_ultimo(p_id_tanque NUMBER) IS
        v_ph    ULTIMAS_MEDICIONES.VALOR_PH%TYPE;
        v_oxig  ULTIMAS_MEDICIONES.VALOR_OXIGENO%TYPE;
        v_temp  ULTIMAS_MEDICIONES.VALOR_TEMPERATURA%TYPE;
        v_sal   ULTIMAS_MEDICIONES.VALOR_SALINIDAD%TYPE;
        v_turb  ULTIMAS_MEDICIONES.VALOR_TURBIDEZ%TYPE;
    BEGIN
        -- Se obtienen primero los valores en PL/SQL (las funciones privadas NO
        -- pueden invocarse dentro de SQL). Luego se aplican con MERGE.
        v_ph   := f_ultima_medicion(p_id_tanque, 'PH');
        v_oxig := f_ultima_medicion(p_id_tanque, 'OXIGENO');
        v_temp := f_ultima_medicion(p_id_tanque, 'TEMPERATURA');
        v_sal  := f_ultima_medicion(p_id_tanque, 'SALINIDAD');
        v_turb := f_ultima_medicion(p_id_tanque, 'TURBIDEZ');

        MERGE INTO ULTIMAS_MEDICIONES u
        USING (SELECT p_id_tanque AS id_tanque FROM DUAL) s
        ON (u.ID_TANQUE = s.id_tanque)
        WHEN MATCHED THEN UPDATE SET
            VALOR_PH            = NVL(v_ph,   u.VALOR_PH),
            VALOR_OXIGENO       = NVL(v_oxig, u.VALOR_OXIGENO),
            VALOR_TEMPERATURA   = NVL(v_temp, u.VALOR_TEMPERATURA),
            VALOR_SALINIDAD     = NVL(v_sal,  u.VALOR_SALINIDAD),
            VALOR_TURBIDEZ      = NVL(v_turb, u.VALOR_TURBIDEZ),
            FECHA_ACTUALIZACION = SYSDATE
        WHEN NOT MATCHED THEN INSERT
            (ID_TANQUE, VALOR_PH, VALOR_OXIGENO, VALOR_TEMPERATURA,
             VALOR_SALINIDAD, VALOR_TURBIDEZ, FECHA_ACTUALIZACION)
        VALUES
            (p_id_tanque, v_ph, v_oxig, v_temp, v_sal, v_turb, SYSDATE);
    END p_refrescar_ultimo;

    -- ============================================================================
    -- SECCION PUBLICA: implementacion de lo declarado en la especificacion
    -- ============================================================================

    -------------------------------------------------------------------------------
    -- (PUBLICA, con parametros) Carga masiva de lecturas desde staging al historico
    --   1) INSERT ... SELECT desde MEDICIONES_STAGING (el trigger de fila genera
    --      las alertas de las lecturas fuera de rango)
    --   2) Marca como ALERTA las mediciones que generaron alerta
    --   3) Refresca ULTIMAS_MEDICIONES de los tanques afectados
    --   4) Purgado (DELETE) del buffer procesado, con el MISMO filtro del paso 1
    --   5) Devuelve total procesado y codigo de error (0 = OK)
    -- Si algo falla, se deshace TODO lo hecho por este procedimiento (SAVEPOINT),
    -- asi nunca quedan lecturas duplicadas entre staging e historico.
    -------------------------------------------------------------------------------
    PROCEDURE sp_procesar_lecturas_masivas(
        p_id_centro        IN  NUMBER,
        p_fecha_proceso    IN  DATE,
        p_total_procesados OUT NUMBER,
        p_codigo_error     OUT NUMBER
    ) IS
        v_total NUMBER := 0;
    BEGIN
        SAVEPOINT sp_ini_proceso;

        -- 1) Carga masiva (bulk) desde staging a historico
        INSERT INTO HISTORIAL_MEDICIONES (ID_MEDICION, ID_SENSOR, VALOR, FECHA_HORA, ESTADO_MEDICION)
        SELECT seq_medicion.NEXTVAL, st.ID_SENSOR, st.VALOR, st.FECHA_HORA, gc_estado_normal
          FROM MEDICIONES_STAGING st
         WHERE st.ID_CENTRO = p_id_centro
           AND TRUNC(st.FECHA_HORA) = TRUNC(p_fecha_proceso)
           AND NVL(st.ESTADO_PROCESO, gc_estado_pendiente) <> gc_estado_procesado;

        v_total := SQL%ROWCOUNT;

        -- 2) Las mediciones que generaron alerta quedan con estado ALERTA
        UPDATE HISTORIAL_MEDICIONES h
           SET h.ESTADO_MEDICION = gc_estado_alerta
         WHERE h.ESTADO_MEDICION = gc_estado_normal
           AND EXISTS (SELECT 1 FROM ALERTA a WHERE a.ID_MEDICION = h.ID_MEDICION);

        -- 3) Refresca el ultimo estado conocido de los tanques afectados
        FOR r_tanque IN (
            SELECT DISTINCT s.ID_TANQUE
              FROM MEDICIONES_STAGING st
              JOIN SENSOR s ON st.ID_SENSOR = s.ID_SENSOR
             WHERE st.ID_CENTRO = p_id_centro
               AND TRUNC(st.FECHA_HORA) = TRUNC(p_fecha_proceso)
               AND NVL(st.ESTADO_PROCESO, gc_estado_pendiente) <> gc_estado_procesado
        ) LOOP
            p_refrescar_ultimo(r_tanque.ID_TANQUE);
        END LOOP;

        -- 4) Purgado del buffer: mismo filtro que el INSERT del paso 1
        DELETE FROM MEDICIONES_STAGING
         WHERE ID_CENTRO = p_id_centro
           AND TRUNC(FECHA_HORA) = TRUNC(p_fecha_proceso)
           AND NVL(ESTADO_PROCESO, gc_estado_pendiente) <> gc_estado_procesado;

        p_total_procesados := v_total;
        p_codigo_error     := 0;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_ini_proceso;   -- deshace todo lo hecho en esta llamada
            p_total_procesados := 0;
            p_codigo_error     := SQLCODE;
    END sp_procesar_lecturas_masivas;

    -------------------------------------------------------------------------------
    -- (PUBLICA, sin parametros) Procesa TODAS las lecturas pendientes: recorre
    -- cada combinacion centro + fecha, no solo la fecha de hoy.
    -------------------------------------------------------------------------------
    PROCEDURE sp_procesar_todo IS
        v_total NUMBER;
        v_cod   NUMBER;
    BEGIN
        p_log('=== SIGMA-AQUA: PROCESAMIENTO MASIVO DE LECTURAS ===');
        FOR r IN (
            SELECT DISTINCT ID_CENTRO, TRUNC(FECHA_HORA) AS FECHA
              FROM MEDICIONES_STAGING
             WHERE NVL(ESTADO_PROCESO, gc_estado_pendiente) <> gc_estado_procesado
             ORDER BY ID_CENTRO, FECHA
        ) LOOP
            sp_procesar_lecturas_masivas(r.ID_CENTRO, r.FECHA, v_total, v_cod);
            p_log('    Centro #' || r.ID_CENTRO || ' | Fecha ' || TO_CHAR(r.FECHA, 'DD-MM-YYYY') ||
                  ' -> procesados: ' || v_total || ' | codigo error: ' || v_cod);
        END LOOP;
        p_log('=== FIN DEL PROCESAMIENTO ===');
    END sp_procesar_todo;

    -------------------------------------------------------------------------------
    -- (PUBLICA, con parametro) Indice de Calidad de Agua (0-100) de un tanque.
    -- Parte de 100 y descuenta si un parametro esta fuera del umbral configurado
    -- en la tabla UMBRAL (misma regla que el trigger de alertas):
    --   * pH fuera de rango          -> -25
    --   * Oxigeno fuera de rango     -> -40
    --   * Temperatura fuera de rango -> -20
    -- Nunca retorna un valor negativo. NULL si el tanque no tiene mediciones.
    -------------------------------------------------------------------------------
    FUNCTION fn_calcular_ica(p_id_tanque NUMBER) RETURN NUMBER IS
        v_ph     ULTIMAS_MEDICIONES.VALOR_PH%TYPE;
        v_oxig   ULTIMAS_MEDICIONES.VALOR_OXIGENO%TYPE;
        v_temp   ULTIMAS_MEDICIONES.VALOR_TEMPERATURA%TYPE;
        v_centro TANQUE.ID_CENTRO%TYPE;
        v_ica    NUMBER := 100;
    BEGIN
        SELECT u.VALOR_PH, u.VALOR_OXIGENO, u.VALOR_TEMPERATURA, t.ID_CENTRO
          INTO v_ph, v_oxig, v_temp, v_centro
          FROM ULTIMAS_MEDICIONES u
          JOIN TANQUE t ON u.ID_TANQUE = t.ID_TANQUE
         WHERE u.ID_TANQUE = p_id_tanque;

        IF f_fuera_rango(v_ph,   'PH',          v_centro) THEN v_ica := v_ica - 25; END IF;
        IF f_fuera_rango(v_oxig, 'OXIGENO',     v_centro) THEN v_ica := v_ica - 40; END IF;
        IF f_fuera_rango(v_temp, 'TEMPERATURA', v_centro) THEN v_ica := v_ica - 20; END IF;

        RETURN GREATEST(v_ica, 0);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_calcular_ica;

    -------------------------------------------------------------------------------
    -- (PUBLICA, sin parametro) Total de alertas pendientes de atencion.
    -------------------------------------------------------------------------------
    FUNCTION fn_total_alertas_pendientes RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_total
          FROM ALERTA
         WHERE UPPER(NVL(ESTADO_ALERTA, gc_estado_pendiente)) = gc_estado_pendiente;
        RETURN v_total;
    END fn_total_alertas_pendientes;

    -------------------------------------------------------------------------------
    -- (PUBLICA, con parametros) Promedio de la ultima lectura de cada sensor de un
    -- tipo dentro de un centro. Usa ROW_NUMBER para quedarse con la lectura mas
    -- reciente de cada sensor y luego promedia. NULL si no hay lecturas.
    -------------------------------------------------------------------------------
    FUNCTION fn_promedio_sensor(p_id_centro NUMBER, p_id_tipo_sensor NUMBER) RETURN NUMBER IS
        v_prom NUMBER;
    BEGIN
        SELECT AVG(valor)
          INTO v_prom
          FROM (SELECT m.VALOR AS valor,
                       ROW_NUMBER() OVER (PARTITION BY m.ID_SENSOR
                                          ORDER BY m.FECHA_HORA DESC, m.ID_MEDICION DESC) AS rn
                  FROM HISTORIAL_MEDICIONES m
                  JOIN SENSOR s ON m.ID_SENSOR = s.ID_SENSOR
                  JOIN TANQUE t ON s.ID_TANQUE = t.ID_TANQUE
                 WHERE t.ID_CENTRO = p_id_centro
                   AND s.ID_TIPO_SENSOR = p_id_tipo_sensor)
         WHERE rn = 1;
        RETURN v_prom;
    END fn_promedio_sensor;

END PKG_MONITOREO_AGUA;
/

-- ================================================================================
-- 3. VISTA: ICA AGREGADO POR CENTRO DE CULTIVO (depende del package)
--    El ICA se calcula UNA vez por tanque (subconsulta) y luego se agrega.
-- ================================================================================
CREATE OR REPLACE VIEW V_ICA_CENTRO AS
SELECT ID_CENTRO,
       NOMBRE_CENTRO,
       COUNT(ID_TANQUE)     AS TOTAL_TANQUES,
       MIN(ICA)             AS ICA_MIN,
       MAX(ICA)             AS ICA_MAX,
       ROUND(AVG(ICA), 2)   AS ICA_PROMEDIO
  FROM (SELECT c.ID_CENTRO,
               c.NOMBRE_CENTRO,
               t.ID_TANQUE,
               PKG_MONITOREO_AGUA.fn_calcular_ica(t.ID_TANQUE) AS ICA
          FROM CENTRO_CULTIVO c
          LEFT JOIN TANQUE t ON t.ID_CENTRO = c.ID_CENTRO)
 GROUP BY ID_CENTRO, NOMBRE_CENTRO;

-- ================================================================================
-- 4. EJEMPLOS DE USO (descomentar para probar)
-- ================================================================================
-- a) Procesamiento masivo con parametros (centro 1, hoy):
--    DECLARE
--        v_total NUMBER;
--        v_cod   NUMBER;
--    BEGIN
--        PKG_MONITOREO_AGUA.sp_procesar_lecturas_masivas(1, SYSDATE, v_total, v_cod);
--        DBMS_OUTPUT.PUT_LINE('Procesados: ' || v_total || ' | Codigo: ' || v_cod);
--    END;
--    /
--
-- b) Procesamiento masivo sin parametros (todos los centros y fechas):
--    BEGIN PKG_MONITOREO_AGUA.sp_procesar_todo; END;
--    /
--
-- c) Calcular ICA de un tanque:
--    SELECT PKG_MONITOREO_AGUA.fn_calcular_ica(1) AS ICA FROM DUAL;
--
-- d) Total de alertas pendientes:
--    SELECT PKG_MONITOREO_AGUA.fn_total_alertas_pendientes AS ALERTAS FROM DUAL;
--
-- e) Promedio de oxigeno (tipo sensor 2) en el centro 1:
--    SELECT PKG_MONITOREO_AGUA.fn_promedio_sensor(1, 2) AS PROM_OXIGENO FROM DUAL;
--
-- f) Consultar el ICA agregado por centro (vista):
--    SELECT * FROM V_ICA_CENTRO;
-- ================================================================================
