(() => {
const coleccion = db.getSiblingDB("sigma_aqua").getCollection("reportes_jaula");
// ===================== DELETE =====================

printjson(coleccion.deleteOne({ "codigo_reporte": "TEST-J99-20261101", "estado": "PRUEBA", "peces_vivos": 0 }));


printjson(coleccion.deleteMany({ "codigo_reporte": { $in: ["TEST-J98-20261101", "TEST-J99-20261101"] }, "estado": "PRUEBA", "peces_vivos": 0 }));
})();
