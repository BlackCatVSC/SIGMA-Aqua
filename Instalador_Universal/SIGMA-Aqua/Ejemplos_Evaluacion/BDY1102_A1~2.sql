SET SERVEROUTPUT ON;

-- ==========================================
-- SCRIPT PL/SQL: TIPOS COMPUESTOS (RECORD Y VARRAY)
-- Esquema objetivo: DataModeler.sql (SIGMA-Aqua)
-- ==========================================

DECLARE
    -- VARRAY: colección homogénea acotada a 4 turnos diarios fijos
    TYPE t_raciones_diarias IS VARRAY(4) OF NUMBER(8, 2);

    -- RECORD: estructura heterogénea con métricas y el VARRAY integrado
    TYPE r_resumen_lote IS RECORD (
        id_lote            LOTE.ID_LOTE%TYPE,
        nombre_especie     ESPECIE.NOMBRE_COMUN_ESPECIE%TYPE,
        cantidad_peces     LOTE.CANTIDAD_ACTUAL_LOTE%TYPE,
        peso_promedio_gr   NUMBER(8, 2),
        biomasa_kg         NUMBER(10, 2),
        raciones_turno     t_raciones_diarias,
        consumo_total_dia  NUMBER(8, 2)
    );

    v_lote           r_resumen_lote;
    v_total_alimento NUMBER(8, 2) := 0;
BEGIN
    -- Asignación de datos del lote #1
    v_lote.id_lote          := 1;
    v_lote.nombre_especie   := 'Salmón del Atlántico';
    v_lote.cantidad_peces   := 15000;
    v_lote.peso_promedio_gr := 1850.50;

    -- Biomasa (kg) = (Peces * Peso en gramos) / 1000
    v_lote.biomasa_kg := (v_lote.cantidad_peces * v_lote.peso_promedio_gr) / 1000;

    -- Inicialización de las raciones por turno: [Mañana, Mediodía, Tarde, Noche]
    v_lote.raciones_turno := t_raciones_diarias(120.50, 150.00, 135.25, 95.00);

    -- Iteración sobre la colección VARRAY
    FOR i IN 1..v_lote.raciones_turno.COUNT LOOP
        v_total_alimento := v_total_alimento + v_lote.raciones_turno(i);
    END LOOP;
    v_lote.consumo_total_dia := v_total_alimento;

    -- Salida formateada
    DBMS_OUTPUT.PUT_LINE('       SIGMA-AQUA: MONITOREO DE LOTE Y ALIMENTACIÓN');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('Lote ID            : ' || v_lote.id_lote);
    DBMS_OUTPUT.PUT_LINE('Especie            : ' || v_lote.nombre_especie);
    DBMS_OUTPUT.PUT_LINE('Peces Activos      : ' || TO_CHAR(v_lote.cantidad_peces, '999,999'));
    DBMS_OUTPUT.PUT_LINE('Peso Promedio (g)  : ' || TO_CHAR(v_lote.peso_promedio_gr, '999,990.00'));
    DBMS_OUTPUT.PUT_LINE('Biomasa Total (kg) : ' || TO_CHAR(v_lote.biomasa_kg, '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('Alimento Diario(kg): ' || TO_CHAR(v_lote.consumo_total_dia, '999,990.00'));
END;
/
