// ===================== READ =====================
// $in + proyección: jaulas en alerta o críticas
use('sigma_aqua');
db.reportes_jaula.find({ "estado": { $in: ["ALERTA", "CRITICO"] } }, { "_id": 0, "codigo_reporte": 1, "estado": 1 });

// $gte/$lte + sort + limit: top 3 biomasa entre 45 y 70 t
use('sigma_aqua');
db.reportes_jaula.find({ "biomasa_kg": { $gte: 45000, $lte: 70000 } }, { "_id": 0, "codigo_reporte": 1, "biomasa_kg": 1 })
  .sort({ "biomasa_kg": -1 }).limit(3);

// $elemMatch: oxígeno bajo 6 mg/L
use('sigma_aqua');
db.reportes_jaula.find({ "lecturas": { $elemMatch: { "parametro": "oxigeno", "valor": { $lt: 6 } } } }, { "_id": 0, "codigo_reporte": 1 });

// subdocumento: reportes de un centro
use('sigma_aqua');
db.reportes_jaula.find({ "centro.nombre": "Centro Los Lagos" }, { "_id": 0, "codigo_reporte": 1, "estado": 1 });

// $all: oxígeno bajo Y revisión urgente
use('sigma_aqua');
db.reportes_jaula.find({ "etiquetas": { $all: ["oxigeno_bajo", "revision_urgente"] } }, { "_id": 0, "codigo_reporte": 1 });

// $or + $nin: alerta activa o biomasa > 70 t, sin reportes de prueba
use('sigma_aqua');
db.reportes_jaula.find({ $or: [{ "alerta_activa": true }, { "biomasa_kg": { $gt: 70000 } }], "estado": { $nin: ["PRUEBA"] } },
  { "_id": 0, "codigo_reporte": 1 });

// distinct: especies cultivadas
use('sigma_aqua');
db.reportes_jaula.distinct("jaula.especie");