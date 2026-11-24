SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

DECLARE
    v_ph NUMBER;
    v_ox NUMBER;
    v_temp NUMBER;
    v_count NUMBER;

    PROCEDURE comprobar(p_ok BOOLEAN, p_msg VARCHAR2) IS
    BEGIN
        IF p_ok THEN
            DBMS_OUTPUT.PUT_LINE('[OK] ' || p_msg);
        ELSE
            RAISE_APPLICATION_ERROR(-20091, p_msg);
        END IF;
    END;
BEGIN
    SAVEPOINT prueba_trigger;

    v_ph := seq_medicion.NEXTVAL;
    v_ox := seq_medicion.NEXTVAL;
    v_temp := seq_medicion.NEXTVAL;

    INSERT INTO HISTORIAL_MEDICIONES
    VALUES (v_ph, 1, 9, SYSDATE, 'NORMAL');

    INSERT INTO HISTORIAL_MEDICIONES
    VALUES (v_ox, 2, 21, SYSDATE, 'ALTA');

    INSERT INTO HISTORIAL_MEDICIONES
    VALUES (v_temp, 3, 10, SYSDATE, 'NORMAL');

    SELECT COUNT(*) INTO v_count
    FROM HISTORIAL_MEDICIONES
    WHERE ID_MEDICION IN (v_ph, v_ox, v_temp);

    comprobar(v_count = 3, 'Tres mediciones registradas');

    SELECT COUNT(*) INTO v_count
    FROM ALERTA
    WHERE ID_MEDICION = v_ph;

    comprobar(v_count = 1, 'Alerta de pH generada');

    SELECT COUNT(*) INTO v_count
    FROM ALERTA
    WHERE ID_MEDICION = v_ox;

    comprobar(v_count = 1, 'Alerta de oxigeno generada');

    SELECT COUNT(*) INTO v_count
    FROM ALERTA
    WHERE ID_MEDICION = v_temp;

    comprobar(v_count = 0, 'Temperatura normal sin alerta');

    SELECT COUNT(*) INTO v_count
    FROM ACCION_CORRECTIVA
    WHERE ID_ALERTA IN (
        SELECT ID_ALERTA FROM ALERTA
        WHERE ID_MEDICION IN (v_ph, v_ox, v_temp)
    );

    comprobar(v_count = 2, 'Dos acciones correctivas');

    ROLLBACK TO prueba_trigger;

    SELECT COUNT(*) INTO v_count
    FROM HISTORIAL_MEDICIONES
    WHERE ID_MEDICION IN (v_ph, v_ox, v_temp);

    comprobar(v_count = 0, 'Rollback sin registros residuales');

    DBMS_OUTPUT.PUT_LINE('=== 6/6 PRUEBAS SUPERADAS ===');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO prueba_trigger;
        RAISE;
END;
/
