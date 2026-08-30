SELECT c.nombre AS centro, e.nombre AS empresa, z.nombre_zona
FROM centro_cultivo c
JOIN empresa e ON c.id_empresa = e.id_empresa
JOIN zona_sanitaria z ON c.id_zona = z.id_zona;

COMMIT;