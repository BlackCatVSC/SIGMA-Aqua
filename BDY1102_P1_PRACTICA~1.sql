-- Insertar la embarcación usando una matrícula alternativa para evitar el duplicado
INSERT INTO embarcacion (nombre, matricula, tipo, capacidad, estado, id_centro)
VALUES ('Naviera Chiloé I', 'VAL-4413', 'Wellboat', 1200.00, 'operativo', 1);

-- Insertar el traslado pendiente amarrado a la nueva embarcación (id_embarcacion o matrícula según corresponda)
INSERT INTO traslado (id_lote, id_centro_origen, id_centro_destino, fecha_salida, fecha_llegada, cantidad_trasladada, id_embarcacion, id_trabajador, estado)
VALUES (1, 1, 2, SYSDATE + 2, NULL, 20000, (SELECT MAX(id_embarcacion) FROM embarcacion), 1, 'pendiente');

COMMIT;