SET SERVEROUTPUT ON;

-- ==========================================
-- SCRIPT PL/SQL: CURSORES EXPLÍCITOS COMPLEJOS CON PARÁMETROS
-- Esquema objetivo: DataModeler.sql (SIGMA-Aqua)
-- Técnica: cursores anidados maestro-detalle con bucles anidados
-- ==========================================

DECLARE
    -- Excepciones definidas por el usuario (reglas de negocio)
    e_exceso_biomasa   EXCEPTION;
    e_zona_restringida EXCEPTION;
    v_msg_error        VARCHAR2(500);

    -- CURSOR MAESTRO (sin parámetros): recorre los centros de cultivo activos
    CURSOR c_centros IS
        SELECT c.ID_CENTRO,
               c.NOMBRE_CENTRO,
               c.VOLUMEN_CENTRO_M3,
               c.DENSIDAD_MAXIMA_KG_M3,
               (c.VOLUMEN_CENTRO_M3 * c.DENSIDAD_MAXIMA_KG_M3) AS CAPACIDAD_MAX_KG,
               z.NOMBRE_ZONA,
               UPPER(NVL(z.ESTADO_ZONA, 'OPERATIVA')) AS ESTADO_ZONA
          FROM CENTRO_CULTIVO c
          JOIN ZONA_SANITARIA z ON c.ID_ZONA = z.ID_ZONA
         WHERE UPPER(c.ESTADO_CENTRO) = 'ACTIVO'
         ORDER BY c.ID_CENTRO;

    -- CURSOR DETALLE (con parámetro): recorre los lotes del centro inyectado
    CURSOR c_lotes (p_id_centro NUMBER) IS
        SELECT l.ID_LOTE,
               e.NOMBRE_COMUN_ESPECIE,
               l.CANTIDAD_ACTUAL_LOTE,
               NVL((SELECT m.PESO_PROMEDIO_MUES
                      FROM MUESTREO m
                     WHERE m.ID_LOTE = l.ID_LOTE
                     ORDER BY m.FECHA_MUES DESC
                     FETCH FIRST 1 ROW ONLY), 1500) AS PESO_PROM_GR,
               NVL((SELECT SUM(mort.CANTIDAD_MORT)
                      FROM MORTALIDAD mort
                     WHERE mort.ID_LOTE = l.ID_LOTE), 0) AS MORT_TOT
          FROM LOTE l
          JOIN ESPECIE e ON l.ID_ESPECIE = e.ID_ESPECIE
         WHERE l.ID_CENTRO = p_id_centro
           AND UPPER(l.ESTADO_LOTE) = 'ACTIVO'
         ORDER BY l.ID_LOTE;

    -- Variables acumuladoras y de cálculo
    v_bio_lote   NUMBER(12, 2);
    v_bio_centro NUMBER(12, 2);
    v_densidad   NUMBER(8, 2);

BEGIN
    -- BUCLE MAESTRO (LOOP 1): procesa cada centro de cultivo
    FOR r_centro IN c_centros LOOP
        v_bio_centro := 0;  -- reinicia acumulador por centro

        DBMS_OUTPUT.PUT_LINE(CHR(10) || '>>> AUDITANDO CENTRO: ' || r_centro.NOMBRE_CENTRO ||
                             ' | ZONA: ' || r_centro.NOMBRE_ZONA || ' [' || r_centro.ESTADO_ZONA || ']');
        DBMS_OUTPUT.PUT_LINE('    Capacidad Permitida: ' || TO_CHAR(r_centro.CAPACIDAD_MAX_KG, '999,999,990') || ' kg');

        -- RN-002: Bloqueo Sanitario por Zona en Cuarentena/Descanso
        IF r_centro.ESTADO_ZONA IN ('CUARENTENA', 'DESCANSO SANITARIO') THEN
            v_msg_error := 'Centro ' || r_centro.NOMBRE_CENTRO || ' opera en zona bajo ' || r_centro.ESTADO_ZONA;
            RAISE e_zona_restringida;
        END IF;

        -- BUCLE DETALLE (LOOP 2 ANIDADO): recorre los lotes inyectando el ID del centro
        FOR r_lote IN c_lotes(r_centro.ID_CENTRO) LOOP
            v_bio_lote   := (r_lote.CANTIDAD_ACTUAL_LOTE * r_lote.PESO_PROM_GR) / 1000;
            v_bio_centro := v_bio_centro + v_bio_lote;

            DBMS_OUTPUT.PUT_LINE('    - Lote #' || r_lote.ID_LOTE || ' (' || r_lote.NOMBRE_COMUN_ESPECIE || '): ' ||
                                 TO_CHAR(r_lote.CANTIDAD_ACTUAL_LOTE, '999,999') || ' peces | ' ||
                                 'Biomasa: ' || TO_CHAR(v_bio_lote, '999,999.00') || ' kg | ' ||
                                 'Mortalidad Acum: ' || r_lote.MORT_TOT);
        END LOOP;

        -- Evita división por cero (excepción predefinida)
        IF r_centro.VOLUMEN_CENTRO_M3 = 0 THEN
            RAISE ZERO_DIVIDE;
        END IF;

        v_densidad := v_bio_centro / r_centro.VOLUMEN_CENTRO_M3;

        -- RN-001: Exceso de Biomasa
        IF v_bio_centro > r_centro.CAPACIDAD_MAX_KG THEN
            v_msg_error := 'El centro ' || r_centro.NOMBRE_CENTRO || ' excedió su capacidad permitida (' ||
                           TO_CHAR(v_bio_centro, '999,999,990.00') || ' kg vs max ' ||
                           TO_CHAR(r_centro.CAPACIDAD_MAX_KG, '999,999,990.00') || ' kg).';
            RAISE e_exceso_biomasa;
        END IF;

        DBMS_OUTPUT.PUT_LINE('    ------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('    RESULTADO : Biomasa Total = ' || TO_CHAR(v_bio_centro, '999,999,990.00') || ' kg');
        DBMS_OUTPUT.PUT_LINE('    DENSIDAD  : ' || TO_CHAR(v_densidad, '990.00') ||
                             ' kg/m3 (Permitido máximo: ' || r_centro.DENSIDAD_MAXIMA_KG_M3 || ' kg/m3)');
        DBMS_OUTPUT.PUT_LINE('    ESTADO    : CUMPLE NORMATIVA SANITARIA Y DE BIOMASA (OK)');
    END LOOP;

EXCEPTION
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('ERROR TECNICO: Se detectó un centro con volumen 0 m3.');
    WHEN e_exceso_biomasa THEN
        DBMS_OUTPUT.PUT_LINE('BLOQUEO RN-001: ' || v_msg_error);
    WHEN e_zona_restringida THEN
        DBMS_OUTPUT.PUT_LINE('BLOQUEO RN-002: ' || v_msg_error);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO [' || SQLCODE || ']: ' || SQLERRM);
END;
/
