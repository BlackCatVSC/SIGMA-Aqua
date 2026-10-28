CREATE USER SIGMA_TEST IDENTIFIED BY "Sigma2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

-- Privilegios minimos para todo el proyecto
GRANT CREATE SESSION   TO SIGMA_TEST;  -- conectarse
GRANT CREATE TABLE     TO SIGMA_TEST;  -- tablas
GRANT CREATE SEQUENCE  TO SIGMA_TEST;  -- seq_medicion, seq_alerta
GRANT CREATE VIEW      TO SIGMA_TEST;  -- V_ICA_CENTRO (evita ORA-01031)
GRANT CREATE PROCEDURE TO SIGMA_TEST;  -- packages, procedimientos, funciones
GRANT CREATE TRIGGER   TO SIGMA_TEST;  -- triggers

--SQL/01_Estructura_Tablas/DataModeler.sql
--SQL/03_Poblado_y_Consultas/scripts_plsql_sigma_aqua.sql
--SQL/01_Estructura_Tablas/DataModeler_monitoreo.sql
--SQL/02_Triggers_y_Funciones/PKG_MONITOREO_AGUA.sql
--SQL/02_Triggers_y_Funciones/triggers_monitoreo.sql
--SQL/02_Triggers_y_Funciones/PKG_SIGMA_AQUA.sql
--SQL/03_Poblado_y_Consultas/test_monitoreo.sql: todas las líneas deberían salir [OK].
--BEGIN PKG_SIGMA_AQUA.sp_auditar_todos; END;: el resultado esperado es 1 centro que cumple y 3 con observaciones.

--scripts_plsql_sigma_aqua.sql este tiene un error al inicio la primera parte esta sin comentario por lo que al ejecutar el script se produce un error de sintaxis. Se debe comentar la primera línea para que el script funcione correctamente.