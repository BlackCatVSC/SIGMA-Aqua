(() => {
const coleccion = db.getSiblingDB("sigma_aqua").getCollection("reportes_jaula");
// ===================== READ =====================
// $in + proyección: jaulas en alerta o críticas

printjson(coleccion.find({ "estado": { $in: ["ALERTA", "CRITICO"] } }, { "_id": 0, "codigo_reporte": 1, "estado": 1 }).toArray());

// $gte/$lte + sort + limit: top 3 biomasa entre 45 y 70 t

printjson(coleccion.find({ "biomasa_kg": { $gte: 45000, $lte: 70000 } }, { "_id": 0, "codigo_reporte": 1, "biomasa_kg": 1 })
  .sort({ "biomasa_kg": -1 }).limit(3).toArray());

// $elemMatch: oxígeno bajo 6 mg/L

printjson(coleccion.find({ "lecturas": { $elemMatch: { "parametro": "oxigeno", "valor": { $lt: 6 } } } }, { "_id": 0, "codigo_reporte": 1 }).toArray());

// subdocumento: reportes de un centro

printjson(coleccion.find({ "centro.nombre": "Centro Los Lagos" }, { "_id": 0, "codigo_reporte": 1, "estado": 1 }).toArray());

// $all: oxígeno bajo Y revisión urgente

printjson(coleccion.find({ "etiquetas": { $all: ["oxigeno_bajo", "revision_urgente"] } }, { "_id": 0, "codigo_reporte": 1 }).toArray());

// $or + $nin: alerta activa o biomasa > 70 t, sin reportes de prueba

printjson(coleccion.find({ $or: [{ "alerta_activa": true }, { "biomasa_kg": { $gt: 70000 } }], "estado": { $nin: ["PRUEBA"] } },
  { "_id": 0, "codigo_reporte": 1 }).toArray());

// distinct: especies cultivadas

printjson(coleccion.distinct("jaula.especie", {estado: {$ne: "PRUEBA"}}));
})();
