// ===================== UPDATE =====================
use('sigma_aqua');
db.reportes_jaula.updateOne({ "codigo_reporte": "REP-J12-20261118" }, { $set: { "estado": "REVISADO", "alerta_activa": false } });
db.reportes_jaula.updateOne({ "codigo_reporte": "REP-J02-20261118" }, { $inc: { "peces_vivos": -35 } });
db.reportes_jaula.updateOne({ "codigo_reporte": "REP-J12-20261118" }, { $unset: { "nota_temporal": "" } });
db.reportes_jaula.updateMany({ "estado": "CRITICO" }, { $addToSet: { "etiquetas": "inspeccion_sernapesca" } });
