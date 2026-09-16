================================================================================
          SIGMA-AQUA: DATOS DE PRUEBA (BDY1103)
================================================================================
Proyecto   : SIGMA-Aqua (Sistema Integrado de Gestion y Monitorizacion Acuicola)
Asignatura : BDY1103 - Taller de Base de Datos (Duoc UC)
Integrantes: Matias Jeldres, Ignacio Salazar, Luciano Garrido
Motor BD   : Oracle Database 21c
================================================================================

INSTRUCCIONES DE USO:
1. Ejecuta primero 'DataModeler.sql' (crea las 31 tablas del esquema).
2. Ejecuta este archivo para cargar los datos de prueba minimos.
3. Luego puedes ejecutar los scripts PL/SQL:
   - Cursor_Explicito.sql  : cursores anidados con parametros y bucles anidados
   - BDY1102_A1~2.sql      : tipos compuestos (RECORD y VARRAY)
   - BDY1102_A1~3.sql      : trigger de alerta sanitaria
   - BDY1102_A1~5..sql     : registro de traslado (dinamico)
   - BDY1102_A1~6.sql      : registro de traslado

================================================================================
DATOS DE PRUEBA MINIMOS
================================================================================

SET DEFINE OFF;

-- 1. Empresa y Especies
INSERT INTO EMPRESA (NOMBRE_EMPRESA, RUT_EMPRESA, DIRECCION_EMPRESA, TELEFONO_EMPRESA, EMAIL_EMPRESA)
VALUES ('AquaChile S.A.', '76.123.456-7', 'Av. del Mar 1020, Puerto Montt', '+5665223344', 'contacto@aquachile.cl');

INSERT INTO ESPECIE (NOMBRE_COMUN_ESPECIE, NOMBRE_CIENTIFICO_ESPECIE)
VALUES ('Salmon del Atlantico', 'Salmo salar');

INSERT INTO ESPECIE (NOMBRE_COMUN_ESPECIE, NOMBRE_CIENTIFICO_ESPECIE)
VALUES ('Trucha Arcoiris', 'Oncorhynchus mykiss');

-- 2. Zonas Sanitarias (Una Operativa y Otra en Cuarentena para pruebas)
INSERT INTO ZONA_SANITARIA (CODIGO_OFICIAL_ZONA, NOMBRE_ZONA, REGION_ZONA, PROVINCIA_ZONA, ESTADO_ZONA)
VALUES ('ZS-101', 'Canal de Chacao', 'Los Lagos', 'Llanquihue', 'OPERATIVA');

INSERT INTO ZONA_SANITARIA (CODIGO_OFICIAL_ZONA, NOMBRE_ZONA, REGION_ZONA, PROVINCIA_ZONA, ESTADO_ZONA)
VALUES ('ZS-102', 'Fiordo Reloncavi', 'Los Lagos', 'Reloncavi', 'CUARENTENA');

-- 3. Centros de Cultivo
-- Centro 1: Centro Normal (Capacidad: 10.000 m3 * 15 kg/m3 = 150.000 kg maximo)
INSERT INTO CENTRO_CULTIVO (NOMBRE_CENTRO, UBICACION_CENTRO, VOLUMEN_CENTRO_M3, DENSIDAD_MAXIMA_KG_M3, CAPACIDAD_MAX_CENTRO, ESTADO_CENTRO, ID_EMPRESA, ID_ZONA)
VALUES ('Centro Calbuco 1', 'Seno de Reloncavi', 10000, 15, 150000, 'ACTIVO', 1, 1);

-- Centro 2: Centro en Zona de Cuarentena (Para probar la Excepcion RN-002)
INSERT INTO CENTRO_CULTIVO (NOMBRE_CENTRO, UBICACION_CENTRO, VOLUMEN_CENTRO_M3, DENSIDAD_MAXIMA_KG_M3, CAPACIDAD_MAX_CENTRO, ESTADO_CENTRO, ID_EMPRESA, ID_ZONA)
VALUES ('Centro Fiordo 2', 'Boca Fiordo', 12000, 14, 168000, 'ACTIVO', 1, 2);

-- Centro 3: Centro Pequeno con Limite Estricto (Para probar Exceso Biomasa RN-001)
-- Capacidad: 2.000 m3 * 10 kg/m3 = 20.000 kg maximo
INSERT INTO CENTRO_CULTIVO (NOMBRE_CENTRO, UBICACION_CENTRO, VOLUMEN_CENTRO_M3, DENSIDAD_MAXIMA_KG_M3, CAPACIDAD_MAX_CENTRO, ESTADO_CENTRO, ID_EMPRESA, ID_ZONA)
VALUES ('Centro Quellon Sur', 'Bahia Quellon', 2000, 10, 20000, 'ACTIVO', 1, 1);

-- Centro 4: Centro con Volumen Cero (Para probar Excepcion Predefinida ZERO_DIVIDE)
INSERT INTO CENTRO_CULTIVO (NOMBRE_CENTRO, UBICACION_CENTRO, VOLUMEN_CENTRO_M3, DENSIDAD_MAXIMA_KG_M3, CAPACIDAD_MAX_CENTRO, ESTADO_CENTRO, ID_EMPRESA, ID_ZONA)
VALUES ('Centro Experimental 0', 'Canal San Antonio', 0, 12, 0, 'ACTIVO', 1, 1);

-- 4. Lotes de Peces
-- Lote A: En Centro Calbuco 1 (Normal: 15.000 peces)
INSERT INTO LOTE (FECHA_INGRESO_LOTE, CANTIDAD_INICIAL_LOTE, CANTIDAD_ACTUAL_LOTE, ESTADO_LOTE, ID_CENTRO, ID_ESPECIE)
VALUES (TO_DATE('2026-01-15', 'YYYY-MM-DD'), 16000, 15000, 'ACTIVO', 1, 1);

-- Lote B: En Centro Fiordo 2 (En zona de Cuarentena: 8.000 peces)
INSERT INTO LOTE (FECHA_INGRESO_LOTE, CANTIDAD_INICIAL_LOTE, CANTIDAD_ACTUAL_LOTE, ESTADO_LOTE, ID_CENTRO, ID_ESPECIE)
VALUES (TO_DATE('2026-02-10', 'YYYY-MM-DD'), 8500, 8000, 'ACTIVO', 2, 1);

-- Lote C: En Centro Quellon Sur (Sobrepoblado: 25.000 peces a 1.800g = 45.000 kg > 20.000 kg maximo)
INSERT INTO LOTE (FECHA_INGRESO_LOTE, CANTIDAD_INICIAL_LOTE, CANTIDAD_ACTUAL_LOTE, ESTADO_LOTE, ID_CENTRO, ID_ESPECIE)
VALUES (TO_DATE('2026-03-01', 'YYYY-MM-DD'), 25000, 25000, 'ACTIVO', 3, 2);

-- Lote D: En Centro Experimental 0 (5.000 peces)
INSERT INTO LOTE (FECHA_INGRESO_LOTE, CANTIDAD_INICIAL_LOTE, CANTIDAD_ACTUAL_LOTE, ESTADO_LOTE, ID_CENTRO, ID_ESPECIE)
VALUES (TO_DATE('2026-04-01', 'YYYY-MM-DD'), 5000, 5000, 'ACTIVO', 4, 1);

-- 5. Muestreos Biometricos (Pesos promedio en gramos)
INSERT INTO MUESTREO (FECHA_MUES, PESO_PROMEDIO_MUES, CANTIDAD_MUESTRA_MUES, ID_LOTE)
VALUES (TO_DATE('2026-08-20', 'YYYY-MM-DD'), 1850.50, 100, 1); -- Para Lote A

INSERT INTO MUESTREO (FECHA_MUES, PESO_PROMEDIO_MUES, CANTIDAD_MUESTRA_MUES, ID_LOTE)
VALUES (TO_DATE('2026-08-22', 'YYYY-MM-DD'), 2100.00, 80, 2);  -- Para Lote B

INSERT INTO MUESTREO (FECHA_MUES, PESO_PROMEDIO_MUES, CANTIDAD_MUESTRA_MUES, ID_LOTE)
VALUES (TO_DATE('2026-08-25', 'YYYY-MM-DD'), 1800.00, 120, 3); -- Para Lote C

INSERT INTO MUESTREO (FECHA_MUES, PESO_PROMEDIO_MUES, CANTIDAD_MUESTRA_MUES, ID_LOTE)
VALUES (TO_DATE('2026-08-25', 'YYYY-MM-DD'), 1200.00, 50, 4);  -- Para Lote D

-- 6. Causas y Registros de Mortalidad
INSERT INTO CAUSA_MORTALIDAD (NOMBRE_CAUSA, DESCRIPCION_CAUSA)
VALUES ('Depredacion por Lobos Marinos', 'Ataques externos a las redes de cultivo');

INSERT INTO MORTALIDAD (FECHA_MORT, CANTIDAD_MORT, OBSERVACIONES_MORT, ID_LOTE, ID_CAUSA)
VALUES (TO_DATE('2026-08-01', 'YYYY-MM-DD'), 120, 'Danos en jaula norte', 1, 1);

-- 7. Trabajador (requerido para traslados y operaciones)
INSERT INTO TRABAJADOR (NOMBRE_TRAB, APELLIDO_TRAB, RUT_TRAB, CARGO_TRAB, TELEFONO_TRAB, EMAIL_TRAB, ESTADO_TRAB, FECHA_CONTRATO_TRAB, ID_CENTRO)
VALUES ('Juan', 'Perez', '11.111.111-1', 'Operario', '+56912345678', 'juan.perez@aquachile.cl', 'ACTIVO', TO_DATE('2025-01-10', 'YYYY-MM-DD'), 1);

-- 8. Veterinario (requerido para registros sanitarios / trigger)
INSERT INTO VETERINARIO (RUT_VET, REGISTRO_PROFESIONAL_VET, NOMBRE_VET, APELLIDO_VET, EMAIL_VET, TELEFONO_VET, TIPO_CONTRATO_VET, ESPECIALIDAD_VET, ESTADO_VET, FECHA_CONTRATO_VET)
VALUES ('22.222.222-2', 'REG-001', 'Maria', 'Gonzalez', 'maria.gonzalez@aquachile.cl', '+56987654321', 'Planta', 'Patologia', 'ACTIVO', TO_DATE('2025-02-01', 'YYYY-MM-DD'));

-- 9. Enfermedad (requerida para registros sanitarios / trigger)
INSERT INTO ENFERMEDAD (NOMBRE_ENFERM, DESCRIPCION_ENFERM, SINTOMAS_ENFERM)
VALUES ('Anemia Infecciosa del Salmon (ISA)', 'Enfermedad viral de alto impacto', 'Letargo, perdida de apetito, anemia');

COMMIT;

-- NOTA: Para probar el trigger 'trg_alerta_sanitaria_cuarentena',
-- inserta manualmente un registro sanitario critico, por ejemplo:
--   INSERT INTO REGISTRO_SANITARIO (FECHA_REG_SANIT, DIAGNOSTICO_REG_SANIT, GRAVEDAD_REG_SANIT, ID_LOTE, ID_ENFERMEDAD, ID_VETERINARIO)
--   VALUES (SYSDATE, 'Brote de ISA confirmado', 'critica', 1, 1, 1);
--   COMMIT;
-- Al hacerlo, la ZONA_SANITARIA del lote pasara a 'CUARENTENA'.
