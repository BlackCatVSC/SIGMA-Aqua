// ===================== DELETE =====================
use('sigma_aqua');
db.reportes_jaula.deleteOne({ "codigo_reporte": "TEST-J99-20261101" });

('sigma_aqua');
db.reportes_jaula.deleteMany({ "estado": "PRUEBA", "peces_vivos": 0 });