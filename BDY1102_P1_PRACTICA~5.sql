SELECT 
    c.nombre AS centro_cultivo,
    eq.nombre AS equipo,
    te.nombre_tipo AS categoria_equipo,
    eq.marca,
    eq.modelo,
    eq.cantidad,
    eq.estado
FROM equipamiento eq
JOIN centro_cultivo c ON eq.id_centro = c.id_centro
JOIN tipo_equipamiento te ON eq.id_tipo_equipamiento = te.id_tipo_equipamiento;