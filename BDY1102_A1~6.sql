SET SERVEROUTPUT ON;

-- ==========================================
-- SCRIPT PL/SQL: REGISTRO DE TRASLADO
-- Esquema objetivo: DataModeler.sql (SIGMA-Aqua)
-- ==========================================

DECLARE
    v_id_embarcacion    NUMBER;
    v_id_centro_origen  NUMBER;
    v_id_centro_destino NUMBER;
    v_id_lote           NUMBER;
    v_id_trabajador     NUMBER;
BEGIN
    -- Obtener IDs reales creados en la BD (origen y destino distintos)
    SELECT MIN(ID_CENTRO) INTO v_id_centro_origen FROM CENTRO_CULTIVO;
    SELECT MIN(ID_CENTRO) INTO v_id_centro_destino
      FROM CENTRO_CULTIVO
     WHERE ID_CENTRO <> v_id_centro_origen;

    SELECT MIN(ID_LOTE) INTO v_id_lote FROM LOTE;
    SELECT MIN(ID_TRABAJADOR) INTO v_id_trabajador FROM TRABAJADOR;

    -- Insertar Embarcación de forma segura
    BEGIN
        INSERT INTO EMBARCACION (NOMBRE_EMB, MATRICULA_EMB, TIPO_EMB, CAPACIDAD_EMB, ESTADO_EMB, ID_CENTRO)
        VALUES ('Naviera Chiloé I', 'VAL-4413', 'Wellboat', 1200.00, 'OPERATIVO', v_id_centro_origen)
        RETURNING ID_EMBARCACION INTO v_id_embarcacion;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            SELECT ID_EMBARCACION INTO v_id_embarcacion
            FROM EMBARCACION
            WHERE MATRICULA_EMB = 'VAL-4413';
    END;

    -- Insertar Traslado (origen y destino distintos)
    INSERT INTO TRASLADO (ID_LOTE, ID_CENTRO_ORIGEN, ID_CENTRO_DESTINO, FECHA_SALIDA_TRAS, FECHA_LLEGADA_TRAS, CANTIDAD_TRAS, ID_EMBARCACION, ID_TRABAJADOR, ESTADO_TRAS)
    VALUES (v_id_lote, v_id_centro_origen, v_id_centro_destino, SYSDATE + 2, NULL, 20000, v_id_embarcacion, v_id_trabajador, 'PENDIENTE');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Éxito: Traslado registrado desde Centro ' || v_id_centro_origen || ' hacia Centro ' || v_id_centro_destino || '.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error al registrar traslado: ' || SQLERRM);
END;
/
