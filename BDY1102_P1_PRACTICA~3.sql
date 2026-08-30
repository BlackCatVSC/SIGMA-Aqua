SELECT 
    l.id_lote,
    c.nombre AS centro,
    e.nombre_comun AS especie,
    l.cantidad_inicial,
    l.cantidad_actual,
    a.cantidad_alimento AS kg_alimento_ayer,
    ta.nombre AS tipo_alimento,
    m.cantidad AS peces_muertos_hoy,
    cm.nombre_causa AS causa_mortalidad
FROM lote l
JOIN centro_cultivo c ON l.id_centro = c.id_centro
JOIN especie e ON l.id_especie = e.id_especie
LEFT JOIN alimentacion a ON l.id_lote = a.id_lote
LEFT JOIN tipo_alimento ta ON a.id_tipo_alimento = ta.id_tipo_alimento
LEFT JOIN mortalidad m ON l.id_lote = m.id_lote
LEFT JOIN causa_mortalidad cm ON m.id_causa = cm.id_causa;