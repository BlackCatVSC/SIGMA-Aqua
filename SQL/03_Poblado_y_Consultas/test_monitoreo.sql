SET SERVEROUTPUT ON;
SET DEFINE OFF;

-- ================================================================================
-- SCRIPT DE PRUEBA: PKG_MONITOREO_AGUA (SIGMA-Aqua)
-- Motor BD: Oracle Database 21c
-- --------------------------------------------------------------------------------
-- Que hace: reinicia el estado del modulo de monitoreo, ejecuta el procesamiento
-- masivo y verifica cada resultado esperado mostrando [OK] o [ERROR].
-- IMPORTANTE: borra y reinserta los datos de prueba de monitoreo (es idempotente).
-- Nota: si se ejecuta entre 04:00 y 05:59, el trigger trg_ventana_mantenimiento
--       bloqueara las operaciones sobre HISTORIAL_MEDICIONES (ORA-20010).
-- ================================================================================

DECLARE
    v_count  NUMBER;
    v_ica    NUMBER;
    v_prom   NUMBER;
    v_total  NUMBER;
    v_cod    NUMBER;

    PROCEDURE assert(p_ok BOOLEAN, p_desc VARCHAR2) IS
    BEGIN
        IF p_ok THEN
            DBMS_OUTPUT.PUT_LINE('[OK]    ' || p_desc);
        ELSE
            DBMS_OUTPUT.PUT_LINE('[ERROR] ' || p_desc);
        END IF;
    END assert;

BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE(' TEST PKG_MONITOREO_AGUA');
    DBMS_OUTPUT.PUT_LINE('====================================================');

    -- 1) LIMPIEZA (respetando orden de FKs)
    DELETE FROM ACCION_CORRECTIVA;
    DELETE FROM ALERTA;
    DELETE FROM HISTORIAL_MEDICIONES;
    DELETE FROM MEDICIONES_STAGING;
    DELETE FROM ULTIMAS_MEDICIONES;
    COMMIT;

    -- 2) REINSERCION DEL ESTADO INICIAL
    INSERT INTO ULTIMAS_MEDICIONES (ID_TANQUE, VALOR_PH, VALOR_OXIGENO, VALOR_TEMPERATURA, VALOR_SALINIDAD, VALOR_TURBIDEZ, FECHA_ACTUALIZACION)
    VALUES (1, 7.2, 6.5, 11, 30, 5, SYSDATE);
    INSERT INTO ULTIMAS_MEDICIONES (ID_TANQUE, VALOR_PH, VALOR_OXIGENO, VALOR_TEMPERATURA, VALOR_SALINIDAD, VALOR_TURBIDEZ, FECHA_ACTUALIZACION)
    VALUES (2, 9.0, 4.2, 12, 30, 5, SYSDATE);
    INSERT INTO ULTIMAS_MEDICIONES (ID_TANQUE, VALOR_PH, VALOR_OXIGENO, VALOR_TEMPERATURA, VALOR_SALINIDAD, VALOR_TURBIDEZ, FECHA_ACTUALIZACION)
    VALUES (3, 7.0, 7.0, 18, 30, 5, SYSDATE);

    INSERT INTO MEDICIONES_STAGING (ID_SENSOR, ID_CENTRO, VALOR, FECHA_HORA, ESTADO_PROCESO)
    VALUES (1, 1, 8.8, SYSDATE, 'PENDIENTE');
    INSERT INTO MEDICIONES_STAGING (ID_SENSOR, ID_CENTRO, VALOR, FECHA_HORA, ESTADO_PROCESO)
    VALUES (2, 1, 4.0, SYSDATE, 'PENDIENTE');
    INSERT INTO MEDICIONES_STAGING (ID_SENSOR, ID_CENTRO, VALOR, FECHA_HORA, ESTADO_PROCESO)
    VALUES (3, 1, 10,  SYSDATE, 'PENDIENTE');
    INSERT INTO MEDICIONES_STAGING (ID_SENSOR, ID_CENTRO, VALOR, FECHA_HORA, ESTADO_PROCESO)
    VALUES (7, 3, 7.5, SYSDATE, 'PENDIENTE');
    INSERT INTO MEDICIONES_STAGING (ID_SENSOR, ID_CENTRO, VALOR, FECHA_HORA, ESTADO_PROCESO)
    VALUES (8, 3, 3.5, SYSDATE, 'PENDIENTE');
    COMMIT;

    -- 3) EJECUTAR EL PROCESAMIENTO MASIVO (procedimiento SIN parametros)
    PKG_MONITOREO_AGUA.sp_procesar_todo;

    -- 4) VERIFICACIONES
    DBMS_OUTPUT.PUT_LINE('---- Verificaciones tras sp_procesar_todo ----');

    SELECT COUNT(*) INTO v_count FROM MEDICIONES_STAGING;
    assert(v_count = 0, 'MEDICIONES_STAGING vacio (esperado 0, obtenido ' || v_count || ')');

    SELECT COUNT(*) INTO v_count FROM HISTORIAL_MEDICIONES;
    assert(v_count = 5, 'HISTORIAL_MEDICIONES = 5 (obtenido ' || v_count || ')');

    SELECT COUNT(*) INTO v_count FROM ALERTA;
    assert(v_count = 3, 'ALERTA = 3 (obtenido ' || v_count || ')');

    SELECT COUNT(*) INTO v_count FROM ACCION_CORRECTIVA;
    assert(v_count = 3, 'ACCION_CORRECTIVA = 3 (obtenido ' || v_count || ')');

    v_ica := PKG_MONITOREO_AGUA.fn_calcular_ica(1);
    assert(v_ica = 35, 'ICA tanque 1 = 35 (obtenido ' || v_ica || ')');

    v_ica := PKG_MONITOREO_AGUA.fn_calcular_ica(2);
    assert(v_ica = 35, 'ICA tanque 2 = 35 (obtenido ' || v_ica || ')');

    v_ica := PKG_MONITOREO_AGUA.fn_calcular_ica(3);
    assert(v_ica = 40, 'ICA tanque 3 = 40 (obtenido ' || v_ica || ')');

    v_total := PKG_MONITOREO_AGUA.fn_total_alertas_pendientes;
    assert(v_total = 3, 'fn_total_alertas_pendientes = 3 (obtenido ' || v_total || ')');

    v_prom := PKG_MONITOREO_AGUA.fn_promedio_sensor(1, 2);
    assert(v_prom = 4.0, 'fn_promedio_sensor(1,2) = 4.0 (obtenido ' || v_prom || ')');

    -- 5) PROCEDIMIENTO CON PARAMETROS (IN/OUT): insertar 1 lectura y procesarla
    DBMS_OUTPUT.PUT_LINE('---- Procedimiento con parametros (IN/OUT) ----');
    INSERT INTO MEDICIONES_STAGING (ID_SENSOR, ID_CENTRO, VALOR, FECHA_HORA, ESTADO_PROCESO)
    VALUES (3, 1, 12, SYSDATE, 'PENDIENTE');  -- temperatura 12 (dentro de rango)
    PKG_MONITOREO_AGUA.sp_procesar_lecturas_masivas(1, SYSDATE, v_total, v_cod);
    assert(v_total = 1 AND v_cod = 0,
           'sp_procesar_lecturas_masivas procesa 1 fila, codigo 0 (obtenido total=' || v_total || ', cod=' || v_cod || ')');
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE(' FIN DEL TEST');
    DBMS_OUTPUT.PUT_LINE('====================================================');
END;
/
