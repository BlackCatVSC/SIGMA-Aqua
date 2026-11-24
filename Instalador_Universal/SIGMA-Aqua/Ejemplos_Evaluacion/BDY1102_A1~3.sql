-- ==========================================
-- SCRIPT PL/SQL: TRIGGER ALERTA SANITARIA
-- Esquema objetivo: DataModeler.sql (SIGMA-Aqua)
-- ==========================================

CREATE OR REPLACE TRIGGER trg_alerta_sanitaria_cuarentena
AFTER INSERT ON REGISTRO_SANITARIO
FOR EACH ROW
WHEN (UPPER(NEW.GRAVEDAD_REG_SANIT) = 'CRITICA')
DECLARE
    v_id_zona NUMBER;
BEGIN
    SELECT c.ID_ZONA
    INTO v_id_zona
    FROM LOTE l
    JOIN CENTRO_CULTIVO c ON l.ID_CENTRO = c.ID_CENTRO
    WHERE l.ID_LOTE = :NEW.ID_LOTE
      AND c.ID_ZONA IS NOT NULL;

    UPDATE ZONA_SANITARIA
    SET ESTADO_ZONA = 'CUARENTENA'
    WHERE ID_ZONA = v_id_zona;

    DBMS_OUTPUT.PUT_LINE('Alerta sanitaria: Zona ' || v_id_zona || ' puesta en CUARENTENA por registro sanitario crítico.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'El lote ingresado no está asociado a un centro o zona válida.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error en Trigger sanitario: ' || SQLERRM);
END;
/
