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

    -- SIN parametros: procesa todos los centros con lecturas pendientes.
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
    --   1) INSERT ... SELECT desde MEDICIONES_STAGING
    --   2) Refresca ULTIMAS_MEDICIONES de los tanques afectados
    --   3) Purgado (DELETE) del buffer ya procesado
    --   4) Devuelve total procesado y codigo de error (0 = OK)
    -------------------------------------------------------------------------------
    PROCEDURE sp_procesar_lecturas_masivas(
        p_id_centro        IN  NUMBER,
        p_fecha_proceso    IN  DATE,
        p_total_procesados OUT NUMBER,
        p_codigo_error     OUT NUMBER
    ) IS
        v_total NUMBER := 0;
    BEGIN
        -- 1) Carga masiva (bulk) desde staging a historico
        INSERT INTO HISTORIAL_MEDICIONES (ID_MEDICION, ID_SENSOR, VALOR, FECHA_HORA, ESTADO_MEDICION)
        SELECT seq_medicion.NEXTVAL, st.ID_SENSOR, st.VALOR, st.FECHA_HORA, gc_estado_normal
          FROM MEDICIONES_STAGING st
         WHERE st.ID_CENTRO = p_id_centro
           AND TRUNC(st.FECHA_HORA) = TRUNC(p_fecha_proceso)
           AND NVL(st.ESTADO_PROCESO, gc_estado_pendiente) <> gc_estado_procesado;

        v_total := SQL%ROWCOUNT;

        -- 2) Refresca el ultimo estado conocido de los tanques afectados
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

        -- 3) Purgado del buffer ya procesado
        DELETE FROM MEDICIONES_STAGING
         WHERE ID_CENTRO = p_id_centro
           AND TRUNC(FECHA_HORA) = TRUNC(p_fecha_proceso);

        p_total_procesados := v_total;
        p_codigo_error     := 0;

    EXCEPTION
        WHEN OTHERS THEN
            p_total_procesados := 0;
            p_codigo_error     := SQLCODE;
    END sp_procesar_lecturas_masivas;

    -------------------------------------------------------------------------------
    -- (PUBLICA, sin parametros) Procesa todos los centros con lecturas pendientes.
    -- Cada centro se procesa de forma aislada (un error no detiene el resto).
    -------------------------------------------------------------------------------
    PROCEDURE sp_procesar_todo IS
        v_total NUMBER;
        v_cod   NUMBER;
    BEGIN
        p_log('=== SIGMA-AQUA: PROCESAMIENTO MASIVO DE LECTURAS ===');
        FOR r_centro IN (
            SELECT DISTINCT ID_CENTRO
              FROM MEDICIONES_STAGING
             WHERE NVL(ESTADO_PROCESO, gc_estado_pendiente) <> gc_estado_procesado
             ORDER BY ID_CENTRO
        ) LOOP
            BEGIN
                sp_procesar_lecturas_masivas(r_centro.ID_CENTRO, SYSDATE, v_total, v_cod);
                p_log('    Centro #' || r_centro.ID_CENTRO || ' -> procesados: ' ||
                      v_total || ' | codigo error: ' || v_cod);
            EXCEPTION
                WHEN OTHERS THEN
                    p_log('    >>> No fue posible procesar el centro #' ||
                          r_centro.ID_CENTRO || ': ' || SQLERRM);
            END;
        END LOOP;
        p_log('=== FIN DEL PROCESAMIENTO ===');
    END sp_procesar_todo;

    -------------------------------------------------------------------------------
    -- (PUBLICA, con parametro) Indice de Calidad de Agua (0-100) de un tanque.
    -- Parte de 100 y descuenta penalizaciones por parametros fuera de rango:
    --   * pH fuera de [6.5, 8.5] -> -25
    --   * Oxigeno disuelto < 5.0  -> -40
    --   * Temperatura fuera de [8, 16] -> -20
    -- Nunca retorna un valor negativo.
    -------------------------------------------------------------------------------
    FUNCTION fn_calcular_ica(p_id_tanque NUMBER) RETURN NUMBER IS
        v_ph    ULTIMAS_MEDICIONES.VALOR_PH%TYPE;
        v_oxig  ULTIMAS_MEDICIONES.VALOR_OXIGENO%TYPE;
        v_temp  ULTIMAS_MEDICIONES.VALOR_TEMPERATURA%TYPE;
        v_ica   NUMBER := 100;
    BEGIN
        SELECT VALOR_PH, VALOR_OXIGENO, VALOR_TEMPERATURA
          INTO v_ph, v_oxig, v_temp
          FROM ULTIMAS_MEDICIONES
         WHERE ID_TANQUE = p_id_tanque;

        IF v_ph IS NOT NULL AND (v_ph < 6.5 OR v_ph > 8.5) THEN
            v_ica := v_ica - 25;
        END IF;

        IF v_oxig IS NOT NULL AND v_oxig < 5.0 THEN
            v_ica := v_ica - 40;
        END IF;

        IF v_temp IS NOT NULL AND (v_temp < 8 OR v_temp > 16) THEN
            v_ica := v_ica - 20;
        END IF;

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
    -- reciente de cada sensor y luego promedia.
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
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_promedio_sensor;

END PKG_MONITOREO_AGUA;
/

-- ================================================================================
-- 3. VISTA: ICA AGREGADO POR CENTRO DE CULTIVO (depende del package)
-- ================================================================================
CREATE OR REPLACE VIEW V_ICA_CENTRO AS
SELECT c.ID_CENTRO,
       c.NOMBRE_CENTRO,
       COUNT(t.ID_TANQUE)                                                  AS TOTAL_TANQUES,
       MIN(PKG_MONITOREO_AGUA.fn_calcular_ica(t.ID_TANQUE))               AS ICA_MIN,
       MAX(PKG_MONITOREO_AGUA.fn_calcular_ica(t.ID_TANQUE))               AS ICA_MAX,
       ROUND(AVG(PKG_MONITOREO_AGUA.fn_calcular_ica(t.ID_TANQUE)), 2)     AS ICA_PROMEDIO
  FROM CENTRO_CULTIVO c
  LEFT JOIN TANQUE t ON t.ID_CENTRO = c.ID_CENTRO
 GROUP BY c.ID_CENTRO, c.NOMBRE_CENTRO;
/

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
-- b) Procesamiento masivo sin parametros (todos los centros):
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
