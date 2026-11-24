-- Ejecutar como administrador en la PDB de desarrollo, no en CDB$ROOT.
SET VERIFY OFF
ACCEPT clave CHAR PROMPT 'Clave nueva del usuario (sin comillas): ' HIDE
CREATE USER usuario_desarrollador IDENTIFIED BY "&clave" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
ALTER USER usuario_desarrollador QUOTA 100M ON USERS;
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER, CREATE VIEW TO usuario_desarrollador;
UNDEFINE clave
