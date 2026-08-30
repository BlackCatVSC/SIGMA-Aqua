SELECT 
    u.id_usuario,
    u.correo,
    r.nombre_rol,
    u.estado,
    NVL(t.nombre || ' ' || t.apellido, 'N/A') AS trabajador,
    NVL(v.nombre || ' ' || v.apellido, 'N/A') AS veterinario
FROM usuario u
JOIN rol r ON u.id_rol = r.id_rol
LEFT JOIN trabajador t ON u.id_trabajador = t.id_trabajador
LEFT JOIN veterinario v ON u.id_veterinario = v.id_veterinario;