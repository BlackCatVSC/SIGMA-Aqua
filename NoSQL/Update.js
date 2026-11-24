(() => {
const coleccion = db.getSiblingDB("sigma_aqua").getCollection("reportes_jaula");
// ===================== UPDATE =====================

printjson(coleccion.updateOne({ "codigo_reporte": "REP-J12-20261118" }, { $set: { "estado": "REVISADO", "alerta_activa": false } }));
printjson(coleccion.updateOne({ "codigo_reporte": "REP-J02-20261118", "peces_vivos": { $gte: 35 }, "ajuste_demo_aplicado": { $ne: true } }, { $inc: { "peces_vivos": -35 }, $set: { "ajuste_demo_aplicado": true } }));
printjson(coleccion.updateOne({ "codigo_reporte": "REP-J12-20261118" }, { $unset: { "nota_temporal": "" } }));
printjson(coleccion.updateMany({ "estado": "CRITICO" }, { $addToSet: { "etiquetas": "inspeccion_sernapesca" } }));
})();
