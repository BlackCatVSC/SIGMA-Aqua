SET SERVEROUTPUT ON;

-- ================================================================================
-- SCRIPT PL/SQL: PACKAGE SIGMA-AQUA (CON CONSTRUCTORES PUBLICOS Y PRIVADOS)
-- Esquema objetivo : DataModeler.sql (SIGMA-Aqua)
-- Asignatura       : BDY1103 - Taller de Base de Datos (Duoc UC)
-- Motor BD         : Oracle Database 21c
-- --------------------------------------------------------------------------------
-- Descripcion      : Encapsula la logica de negocio de auditoria de biomasa y
--                    normativa sanitaria (RN-001 y RN-002) en un solo objeto,
--                    reutilizable desde otros programas PL/SQL y sentencias SQL.
-- Version corregida: ver Correcciones_SIGMA-Aqua.txt
-- ================================================================================

-- ================================================================================
-- 1. ESPECIFICACION DEL PACKAGE (PARTE PUBLICA)
--    Todo lo declarado aqui es visible y usable desde fuera del package.
-- ================================================================================
CREATE OR REPLACE PACKAGE PKG_SIGMA_AQUA AS

    -- ----------------------------------------------------------------------------
    -- CONSTANTES PUBLICAS: valores de dominio reutilizables por la aplicacion
    -- ----------------------------------------------------------------------------
    gc_peso_defecto_gr CONSTANT NUMBER       := 1500;      -- peso promedio por defecto (gramos)
    gc_estado_activo   CONSTANT VARCHAR2(10) := 'ACTIVO';  -- estado vigente de centro/lote

    -- ----------------------------------------------------------------------------
    -- EXCEPCIONES PUBLICAS: reglas de negocio enlazadas a codigos Oracle.
    -- sp_auditar_centro las PROPAGA, por lo que otros programas pueden capturarlas.
    -- ----------------------------------------------------------------------------
    e_exceso_biomasa   EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_exceso_biomasa, -20001);       -- RN-001: supera capacidad

    e_zona_restringida EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_zona_restringida, -20002);     -- RN-002: zona en cuarentena

    -- ----------------------------------------------------------------------------
    -- FUNCIONES PUBLICAS (usables directamente en sentencias SQL)
    -- ----------------------------------------------------------------------------
    -- CON parametro: calcula la biomasa (kg) de un lote dado
    FUNCTION fn_biomasa_lote(p_id_lote NUMBER) RETURN NUMBER;

    -- CON parametro: calcula la densidad (kg/m3) de un centro de cultivo
    FUNCTION fn_densidad_centro(p_id_centro NUMBER) RETURN NUMBER;

    -- SIN parametro: cantidad de centros de cultivo en estado ACTIVO
    FUNCTION fn_total_centros_activos RETURN NUMBER;

    -- CON parametro: biomasa total (kg) de todos los lotes de una empresa
    FUNCTION fn_biomasa_total_empresa(p_id_empresa NUMBER) RETURN NUMBER;

    -- ----------------------------------------------------------------------------
    -- PROCEDIMIENTOS PUBLICOS (invocables desde otros programas PL/SQL)
    -- ----------------------------------------------------------------------------
    -- CON parametro: audita un centro de cultivo especifico.
    -- Si el centro no cumple, informa por pantalla y LANZA la excepcion
    -- (e_exceso_biomasa / e_zona_restringida) para que el llamador decida.
    PROCEDURE sp_auditar_centro(p_id_centro NUMBER);

    -- SIN parametro: audita todos los centros de cultivo activos (informacion masiva)
    PROCEDURE sp_auditar_todos;

END PKG_SIGMA_AQUA;
/

-- ================================================================================
-- 2. CUERPO DEL PACKAGE (PARTE PRIVADA + IMPLEMENTACION)
--    Todo lo declarado aqui y NO expuesto en la especificacion es PRIVADO.
--    IMPORTANTE: las funciones privadas solo se pueden llamar desde codigo
--    PL/SQL, NUNCA dentro de una sentencia SQL (error PLS-00231).
-- ================================================================================
CREATE OR REPLACE PACKAGE BODY PKG_SIGMA_AQUA AS

    -- ============================================================================
    -- SECCION PRIVADA: funciones/procedimientos auxiliares NO visibles desde fuera
    -- ============================================================================

    -------------------------------------------------------------------------------
    -- (PRIVADA) Obtiene el ultimo peso promedio (g) muestreado de un lote,
    -- ignorando muestreos sin peso registrado.
    -- Si el lote no tiene muestreos con peso, retorna el peso por defecto.
    -------------------------------------------------------------------------------
    FUNCTION f_peso_promedio(p_id_lote NUMBER) RETURN NUMBER IS
        v_peso NUMBER;
    BEGIN
        SELECT m.PESO_PROMEDIO_MUES
          INTO v_peso
          FROM MUESTREO m
         WHERE m.ID_LOTE = p_id_lote
           AND m.PESO_PROMEDIO_MUES IS NOT NULL
         ORDER BY m.FECHA_MUES DESC
         FETCH FIRST 1 ROW ONLY;
        RETURN v_peso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN gc_peso_defecto_gr;
    END f_peso_promedio;

    -------------------------------------------------------------------------------
    -- (PRIVADA) Mortalidad acumulada (numero de peces) de un lote.
    -------------------------------------------------------------------------------
    FUNCTION f_mortalidad_acum(p_id_lote NUMBER) RETURN NUMBER IS
        v_mort NUMBER;
    BEGIN
        SELECT NVL(SUM(mort.CANTIDAD_MORT), 0)
          INTO v_mort
          FROM MORTALIDAD mort
         WHERE mort.ID_LOTE = p_id_lote;
        RETURN v_mort;
    END f_mortalidad_acum;

    -------------------------------------------------------------------------------
    -- (PRIVADA) Capacidad maxima (kg) de un centro segun volumen y densidad.
    -------------------------------------------------------------------------------
    FUNCTION f_capacidad_max(p_volumen NUMBER, p_densidad NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN p_volumen * p_densidad;
    END f_capacidad_max;

    -------------------------------------------------------------------------------
    -- (PRIVADA) Emisor de mensajes por pantalla (centraliza DBMS_OUTPUT).
    -------------------------------------------------------------------------------
    PROCEDURE p_log(p_mensaje VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_mensaje);
    END p_log;

    -------------------------------------------------------------------------------
    -- (PRIVADA) Obtiene el estado de la zona sanitaria asociada a un centro.
    -------------------------------------------------------------------------------
    FUNCTION f_estado_zona(p_id_centro NUMBER) RETURN VARCHAR2 IS
        v_estado VARCHAR2(30);
    BEGIN
        SELECT UPPER(NVL(z.ESTADO_ZONA, 'OPERATIVA'))
          INTO v_estado
          FROM CENTRO_CULTIVO c
          JOIN ZONA_SANITARIA z ON c.ID_ZONA = z.ID_ZONA
         WHERE c.ID_CENTRO = p_id_centro;
        RETURN v_estado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'OPERATIVA';
    END f_estado_zona;

    -- ============================================================================
    -- SECCION PUBLICA: implementacion de lo declarado en la especificacion
    -- ============================================================================

    -------------------------------------------------------------------------------
    -- (PUBLICA) Biomasa en kg de un lote = (peces actuales * peso promedio g) / 1000
    -- Si la cantidad actual es NULL se considera 0 (evita que un NULL "contamine"
    -- la suma del centro y la auditoria diga que cumple sin haber calculado).
    -------------------------------------------------------------------------------
    FUNCTION fn_biomasa_lote(p_id_lote NUMBER) RETURN NUMBER IS
        v_cantidad NUMBER;
    BEGIN
        SELECT NVL(l.CANTIDAD_ACTUAL_LOTE, 0)
          INTO v_cantidad
          FROM LOTE l
         WHERE l.ID_LOTE = p_id_lote;

        RETURN (v_cantidad * f_peso_promedio(p_id_lote)) / 1000;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_biomasa_lote;

    -------------------------------------------------------------------------------
    -- (PUBLICA) Densidad en kg/m3 de un centro = biomasa total / volumen
    -- La biomasa se acumula en PL/SQL (no dentro del SELECT) porque usa la
    -- funcion privada f_peso_promedio a traves de fn_biomasa_lote.
    -------------------------------------------------------------------------------
    FUNCTION fn_densidad_centro(p_id_centro NUMBER) RETURN NUMBER IS
        v_volumen NUMBER;
        v_biomasa NUMBER := 0;
    BEGIN
        SELECT c.VOLUMEN_CENTRO_M3
          INTO v_volumen
          FROM CENTRO_CULTIVO c
         WHERE c.ID_CENTRO = p_id_centro;

        IF v_volumen = 0 THEN
            RETURN NULL; -- evita division por cero
        END IF;

        FOR r IN (SELECT l.ID_LOTE
                    FROM LOTE l
                   WHERE l.ID_CENTRO = p_id_centro
                     AND UPPER(NVL(l.ESTADO_LOTE, 'ACTIVO')) = gc_estado_activo) LOOP
            v_biomasa := v_biomasa + NVL(fn_biomasa_lote(r.ID_LOTE), 0);
        END LOOP;

        RETURN v_biomasa / v_volumen;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_densidad_centro;

    -------------------------------------------------------------------------------
    -- (PUBLICA, sin parametro) Total de centros activos
    -------------------------------------------------------------------------------
    FUNCTION fn_total_centros_activos RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_total
          FROM CENTRO_CULTIVO
         WHERE UPPER(NVL(ESTADO_CENTRO, 'ACTIVO')) = gc_estado_activo;
        RETURN v_total;
    END fn_total_centros_activos;

    -------------------------------------------------------------------------------
    -- (PUBLICA) Biomasa total (kg) de todos los lotes activos de una empresa
    -- Igual que fn_densidad_centro: se acumula en PL/SQL, no dentro del SELECT.
    -------------------------------------------------------------------------------
    FUNCTION fn_biomasa_total_empresa(p_id_empresa NUMBER) RETURN NUMBER IS
        v_total NUMBER := 0;
    BEGIN
        FOR r IN (SELECT l.ID_LOTE
                    FROM LOTE l
                    JOIN CENTRO_CULTIVO c ON l.ID_CENTRO = c.ID_CENTRO
                   WHERE c.ID_EMPRESA = p_id_empresa
                     AND UPPER(NVL(l.ESTADO_LOTE, 'ACTIVO')) = gc_estado_activo) LOOP
            v_total := v_total + NVL(fn_biomasa_lote(r.ID_LOTE), 0);
        END LOOP;
        RETURN v_total;
    END fn_biomasa_total_empresa;

    -------------------------------------------------------------------------------
    -- (PUBLICA, con parametro) Auditoria completa de un centro de cultivo
    --   1) Valida RN-002 (zona restringida)
    --   2) Acumula biomasa por lote
    --   3) Valida RN-001 (exceso de biomasa)
    -- Si hay un problema, lo informa por pantalla y lo PROPAGA (RAISE) para que
    -- el programa que lo llamo pueda reaccionar.
    -------------------------------------------------------------------------------
    PROCEDURE sp_auditar_centro(p_id_centro NUMBER) IS
        v_nombre_centro  VARCHAR2(100);
        v_volumen        NUMBER;
        v_densidad_max   NUMBER;
        v_estado_zona    VARCHAR2(30);
        v_bio_centro     NUMBER(12, 2) := 0;
        v_bio_lote       NUMBER(12, 2);
        v_densidad       NUMBER(10, 2);
        v_msg_error      VARCHAR2(500);

        CURSOR c_lotes IS
            SELECT l.ID_LOTE,
                   e.NOMBRE_COMUN_ESPECIE,
                   l.CANTIDAD_ACTUAL_LOTE
              FROM LOTE l
              JOIN ESPECIE e ON l.ID_ESPECIE = e.ID_ESPECIE
             WHERE l.ID_CENTRO = p_id_centro
               AND UPPER(NVL(l.ESTADO_LOTE, 'ACTIVO')) = gc_estado_activo
             ORDER BY l.ID_LOTE;
    BEGIN
        SELECT c.NOMBRE_CENTRO, c.VOLUMEN_CENTRO_M3, c.DENSIDAD_MAXIMA_KG_M3
          INTO v_nombre_centro, v_volumen, v_densidad_max
          FROM CENTRO_CULTIVO c
         WHERE c.ID_CENTRO = p_id_centro;

        v_estado_zona := f_estado_zona(p_id_centro);

        p_log(CHR(10) || '>>> AUDITANDO CENTRO: ' || v_nombre_centro ||
              ' | ZONA [' || v_estado_zona || ']');
        p_log('    Capacidad Permitida: ' ||
              TO_CHAR(f_capacidad_max(v_volumen, v_densidad_max), '999,999,990') || ' kg');

        -- RN-002: bloqueo sanitario por zona en cuarentena/descanso
        IF v_estado_zona IN ('CUARENTENA', 'DESCANSO SANITARIO') THEN
            v_msg_error := 'Centro ' || v_nombre_centro || ' opera en zona restringida (' || v_estado_zona || ')';
            RAISE_APPLICATION_ERROR(-20002, v_msg_error);
        END IF;

        -- Evita division por cero
        IF v_volumen = 0 THEN
            RAISE ZERO_DIVIDE;
        END IF;

        -- Acumula biomasa por cada lote del centro
        FOR r_lote IN c_lotes LOOP
            v_bio_lote   := NVL(fn_biomasa_lote(r_lote.ID_LOTE), 0);
            v_bio_centro := v_bio_centro + v_bio_lote;
            p_log('    - Lote #' || r_lote.ID_LOTE || ' (' || r_lote.NOMBRE_COMUN_ESPECIE ||
                  '): ' || TO_CHAR(NVL(r_lote.CANTIDAD_ACTUAL_LOTE, 0), '999,999') || ' peces | Biomasa: ' ||
                  TO_CHAR(v_bio_lote, '999,999.00') || ' kg | Mortalidad Acum: ' ||
                  f_mortalidad_acum(r_lote.ID_LOTE));
        END LOOP;

        v_densidad := v_bio_centro / v_volumen;

        -- RN-001: exceso de biomasa
        IF v_bio_centro > f_capacidad_max(v_volumen, v_densidad_max) THEN
            v_msg_error := 'El centro ' || v_nombre_centro || ' excedio su capacidad permitida (' ||
                           TO_CHAR(v_bio_centro, '999,999,990.00') || ' kg vs max ' ||
                           TO_CHAR(f_capacidad_max(v_volumen, v_densidad_max), '999,999,990.00') || ' kg).';
            RAISE_APPLICATION_ERROR(-20001, v_msg_error);
        END IF;

        p_log('    ------------------------------------------------------------');
        p_log('    RESULTADO : Biomasa Total = ' || TO_CHAR(v_bio_centro, '999,999,990.00') || ' kg');
        p_log('    DENSIDAD  : ' || TO_CHAR(v_densidad, '999,990.00') ||
              ' kg/m3 (Permitido maximo: ' || v_densidad_max || ' kg/m3)');
        p_log('    ESTADO    : CUMPLE NORMATIVA SANITARIA Y DE BIOMASA (OK)');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_log('    >>> ERROR: no existe el centro #' || p_id_centro);
            RAISE;
        WHEN ZERO_DIVIDE THEN
            p_log('    >>> ERROR TECNICO: Se detecto un centro con volumen 0 m3.');
            RAISE;
        WHEN e_exceso_biomasa THEN
            p_log('    >>> BLOQUEO RN-001: ' || SQLERRM);
            RAISE;
        WHEN e_zona_restringida THEN
            p_log('    >>> BLOQUEO RN-002: ' || SQLERRM);
            RAISE;
        WHEN OTHERS THEN
            p_log('    >>> ERROR INESPERADO [' || SQLCODE || ']: ' || SQLERRM);
            RAISE;
    END sp_auditar_centro;

    -------------------------------------------------------------------------------
    -- (PUBLICA, sin parametro) Auditoria masiva: recorre TODOS los centros activos.
    -- Cada centro se procesa de forma aislada (un error no detiene la auditoria).
    -- Al final informa cuantos centros cumplen y cuantos tienen observaciones.
    -------------------------------------------------------------------------------
    PROCEDURE sp_auditar_todos IS
        v_ok          NUMBER := 0;
        v_observados  NUMBER := 0;

        CURSOR c_centros IS
            SELECT ID_CENTRO
              FROM CENTRO_CULTIVO
             WHERE UPPER(NVL(ESTADO_CENTRO, 'ACTIVO')) = gc_estado_activo
             ORDER BY ID_CENTRO;
    BEGIN
        p_log('=== SIGMA-AQUA: AUDITORIA MASIVA DE BIOMASA Y NORMATIVA SANITARIA ===');
        p_log('    Centros activos detectados: ' || fn_total_centros_activos);
        FOR r_centro IN c_centros LOOP
            BEGIN
                sp_auditar_centro(r_centro.ID_CENTRO);
                v_ok := v_ok + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    -- el detalle ya fue informado por sp_auditar_centro
                    v_observados := v_observados + 1;
            END;
        END LOOP;
        p_log(CHR(10) || '    Centros que cumplen       : ' || v_ok);
        p_log('    Centros con observaciones : ' || v_observados);
        p_log('=== FIN DE LA AUDITORIA ===');
    END sp_auditar_todos;

END PKG_SIGMA_AQUA;
/

-- ================================================================================
-- 3. EJEMPLOS DE USO (descomentar para probar)
-- ================================================================================
-- a) Ejecutar auditoria masiva (procedimiento sin parametros):
--    BEGIN PKG_SIGMA_AQUA.sp_auditar_todos; END;
--    /
--
-- b) Auditar un centro especifico capturando las excepciones publicas
--    (procedimiento con parametro usado desde otro programa PL/SQL):
--    BEGIN
--        PKG_SIGMA_AQUA.sp_auditar_centro(1);
--    EXCEPTION
--        WHEN PKG_SIGMA_AQUA.e_exceso_biomasa THEN
--            DBMS_OUTPUT.PUT_LINE('Accion: programar cosecha o traslado de peces.');
--        WHEN PKG_SIGMA_AQUA.e_zona_restringida THEN
--            DBMS_OUTPUT.PUT_LINE('Accion: suspender operaciones del centro.');
--    END;
--    /
--
-- c) Usar funciones publicas directamente en SQL:
--    SELECT l.ID_LOTE,
--           PKG_SIGMA_AQUA.fn_biomasa_lote(l.ID_LOTE) AS BIOMASA_KG
--      FROM LOTE l;
--
--    SELECT PKG_SIGMA_AQUA.fn_total_centros_activos AS CENTROS_ACTIVOS FROM DUAL;
--
--    SELECT PKG_SIGMA_AQUA.fn_densidad_centro(c.ID_CENTRO) AS DENSIDAD_KG_M3,
--           c.NOMBRE_CENTRO
--      FROM CENTRO_CULTIVO c;
-- ================================================================================
