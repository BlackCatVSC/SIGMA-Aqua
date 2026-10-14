1.- Procedimiento de carga y procesamiento masivo de mediciones:



Nombre: sp_procesar_lecturas_masivas
Entradas: p_id_instalacion IN NUMBER, p_fecha_proceso IN DATE
Salidas: p_total_procesados OUT NUMBER, p_codigo_error OUT NUMBER


Propósito: Procesar en bloque (bulk/batch) las lecturas temporales de sensores, insertándose en la tabla histórica, actualizando el último estado conocido del tanque y calculando promedios.




- Pseudocódigo / Esquema Lógico:



PROCEDURE sp_procesar_lecturas_masivas(

    p_id_instalacion IN NUMBER,

    p_fecha_proceso IN DATE,

    p_total_procesados OUT NUMBER,

    p_codigo_error OUT NUMBER

) IS



BEGIN

    -- Carga masiva desde tabla de staging/buffer a tabla histórica

    INSERT INTO historial_mediciones (id_medicion, id_sensor, valor, fecha_hora)

    SELECT seq_medicion.NEXTVAL, id_sensor, valor, fecha_hora

    FROM mediciones_staging

    WHERE id_instalacion = p_id_instalacion

      AND TRUNC(fecha_hora) = TRUNC(p_fecha_proceso);





    p_total_procesados := SQL%ROWCOUNT;

    -- Limpieza del buffer procesado

    DELETE FROM mediciones_staging

    WHERE id_instalacion = p_id_instalacion

      AND TRUNC(fecha_hora) = TRUNC(p_fecha_proceso);

    p_codigo_error := 0;



EXCEPTION

    WHEN OTHERS THEN

        p_codigo_error := SQLCODE;



END sp_procesar_lecturas_masivas;









2.- Funcion de Calculo de Indice de Calidad de Agua (ICA):



Nombre: fn_calcular_ica
Entradas: p_id_tanque IN NUMBER
Salida: NUMBER (Valor del ICA)
Propósito: Calcular un valor numérico estandarizado (0-100) del estado del agua de un tanque basándose en las últimas lecturas de pH, oxígeno y temperatura


- Pseudicódigo / Esquema Lógico:



FUNCTION fn_calcular_ica(p_id_tanque IN NUMBER) RETURN NUMBER IS

    v_ph NUMBER;

    v_oxigeno NUMBER;

    v_ica NUMBER := 100;



BEGIN

    -- Obtener última lectura del tanque

    SELECT valor_ph, valor_oxigeno

    INTO v_ph, v_oxigeno

    FROM ultimas_mediciones

    WHERE id_tanque = p_id_tanque;



    -- Lógica de ponderación

    IF v_ph < 6.5 OR v_ph > 8.5 THEN

        v_ica := v_ica - 25;

    END IF;



    IF v_oxigeno < 5.0 THEN

        v_ica := v_ica - 40;

    END IF;



    RETURN GREATEST(v_ica, 0);

EXCEPTION

    WHEN NO_DATA_FOUND THEN

        RETURN NULL;

        

END fn_calcular_ica;









Paso 3: Diseño de Triggers:



Trigger1: Detección y generación automática de alertas por fuera de rango (Nivel de Fila)



Nombre: trg_evaluar_lectura_sensor
Tabla asociada: historial_mediciones
Evento disparador: AFTER INSERT FOR EACH ROW
Propósito: Analizar la lectura insertada en tiempo real. Si el valor sobrepasa los umbrales configurados para el sensor (temperatura, pH, oxígeno, salinidad, turbidez), inserta automáticamente un registro en la tabla de alertas/eventos y evalúa la activación de acciones correctivas.