SET SERVEROUTPUT ON;

-- ================================================================================
-- PACKAGE DE EJEMPLO PARA ESTUDIO (USANDO EL ESQUEMA SIGMA-AQUA)
-- ================================================================================
-- Tablas usadas: ESPECIE, LOTE, CENTRO_CULTIVO (del archivo DataModeler.sql).
-- Package minimo para estudiar la diferencia entre parte PUBLICA y PRIVADA,
-- consultando datos reales de la base de datos.
-- NOTA: es material de estudio, no forma parte de la solucion entregada.
-- ================================================================================

-- ================================================================================
-- 1. ESPECIFICACION (parte PUBLICA: solo declara)
-- ================================================================================
CREATE OR REPLACE PACKAGE PKG_EJEMPLO AS

    -- CONSTANTE publica
    gc_estado_activo CONSTANT VARCHAR2(10) := 'ACTIVO';

    -- FUNCIONES (devuelven valor, usables en SQL)
    FUNCTION fn_nombre_especie(p_id_lote NUMBER) RETURN VARCHAR2;
    FUNCTION fn_nombre_centro(p_id_centro NUMBER) RETURN VARCHAR2;
    FUNCTION fn_cantidad_lotes(p_id_centro NUMBER) RETURN NUMBER;
    FUNCTION fn_total_especies RETURN NUMBER;          -- sin parametros
    FUNCTION fn_centros_mostrados RETURN NUMBER;       -- lee el contador privado

    -- PROCEDIMIENTOS (no devuelven valor)
    PROCEDURE sp_mostrar_centro(p_id_centro NUMBER);
    PROCEDURE sp_reset_contador;

END PKG_EJEMPLO;
/

-- ================================================================================
-- 2. CUERPO (implementa lo publico + define lo PRIVADO)
-- ================================================================================
CREATE OR REPLACE PACKAGE BODY PKG_EJEMPLO AS

    -- ============================================================================
    -- SECCION PRIVADA: solo visible DENTRO del package
    -- ============================================================================
    -- VARIABLE GLOBAL PRIVADA (conserva su valor durante la sesion). Al estar en
    -- el cuerpo, nadie fuera del package puede modificarla directamente.
    g_centros_mostrados NUMBER := 0;

    PROCEDURE p_incrementar IS
    BEGIN
        g_centros_mostrados := g_centros_mostrados + 1;
    END p_incrementar;

    -- ============================================================================
    -- SECCION PUBLICA
    -- ============================================================================
    FUNCTION fn_nombre_especie(p_id_lote NUMBER) RETURN VARCHAR2 IS
        v_nombre VARCHAR2(50);
    BEGIN
        SELECT e.NOMBRE_COMUN_ESPECIE
          INTO v_nombre
          FROM LOTE l
          JOIN ESPECIE e ON l.ID_ESPECIE = e.ID_ESPECIE
         WHERE l.ID_LOTE = p_id_lote;
        RETURN v_nombre;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_nombre_especie;

    FUNCTION fn_nombre_centro(p_id_centro NUMBER) RETURN VARCHAR2 IS
        v_nombre VARCHAR2(100);
    BEGIN
        SELECT NOMBRE_CENTRO
          INTO v_nombre
          FROM CENTRO_CULTIVO
         WHERE ID_CENTRO = p_id_centro;
        RETURN v_nombre;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_nombre_centro;

    FUNCTION fn_cantidad_lotes(p_id_centro NUMBER) RETURN NUMBER IS
        v_cantidad NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_cantidad
          FROM LOTE
         WHERE ID_CENTRO = p_id_centro
           AND UPPER(NVL(ESTADO_LOTE, 'ACTIVO')) = gc_estado_activo;
        RETURN v_cantidad;
    END fn_cantidad_lotes;

    FUNCTION fn_total_especies RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_total
          FROM ESPECIE;
        RETURN v_total;
    END fn_total_especies;

    FUNCTION fn_centros_mostrados RETURN NUMBER IS
    BEGIN
        RETURN g_centros_mostrados;
    END fn_centros_mostrados;

    PROCEDURE sp_mostrar_centro(p_id_centro NUMBER) IS
    BEGIN
        p_incrementar;  -- la publica usa la privada
        DBMS_OUTPUT.PUT_LINE('Centro : ' || fn_nombre_centro(p_id_centro));
        DBMS_OUTPUT.PUT_LINE('Lotes activos: ' || fn_cantidad_lotes(p_id_centro));
    END sp_mostrar_centro;

    PROCEDURE sp_reset_contador IS
    BEGIN
        g_centros_mostrados := 0;
    END sp_reset_contador;

END PKG_EJEMPLO;
/

-- ================================================================================
-- 3. COMO SE USA (descomentar para probar)
-- ================================================================================

-- a) Funciones en SQL:
--    SELECT PKG_EJEMPLO.fn_nombre_especie(1) AS ESPECIE FROM DUAL;
--    SELECT PKG_EJEMPLO.fn_nombre_centro(1) AS CENTRO FROM DUAL;
--    SELECT PKG_EJEMPLO.fn_cantidad_lotes(1) AS LOTES FROM DUAL;
--    SELECT PKG_EJEMPLO.fn_total_especies AS ESPECIES FROM DUAL;

-- b) Procedimiento (muestra centro y sus lotes):
--    BEGIN
--        PKG_EJEMPLO.sp_mostrar_centro(1);
--        DBMS_OUTPUT.PUT_LINE('Centros mostrados: ' || PKG_EJEMPLO.fn_centros_mostrados);
--    END;
--    /

-- c) Lo PRIVADO no es accesible desde fuera (da error):
--    BEGIN
--        PKG_EJEMPLO.p_incrementar;               -- ERROR: es privado
--        PKG_EJEMPLO.g_centros_mostrados := 99;   -- ERROR: es privada
--    END;
--    /
