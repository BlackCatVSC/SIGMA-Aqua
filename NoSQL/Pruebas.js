// Ejecutar después de Insert.js e InsertMany.js, antes de Update.js y Delete.js.
(() => {
 const c = db.getSiblingDB('sigma_aqua').getCollection('reportes_jaula');
 const check = (ok, msg) => { if (!ok) throw new Error(msg); print('[OK] ' + msg); };
 const ids = ['REP-J12-20261118','REP-J01-20261118','REP-J02-20261118','REP-J03-20261118','REP-J05-20261118','REP-J07-20261118','REP-J08-20261118','TEST-J99-20261101','TEST-J98-20261101'];
 check(c.countDocuments({codigo_reporte: {$in: ids}}) === 9, 'Nueve reportes de ejemplo sin duplicados');
 check(c.countDocuments({codigo_reporte: ids[2], lecturas: {$elemMatch: {parametro:'oxigeno', valor:{$lt:6}}}}) === 1, 'Oxígeno bajo');
 check(c.countDocuments({codigo_reporte: ids[2], etiquetas: {$all:['oxigeno_bajo','revision_urgente']}}) === 1, 'Etiquetas combinadas');
 check(c.countDocuments({codigo_reporte: {$in: ids.slice(-2)}, estado:'PRUEBA', peces_vivos:0}) === 2, 'Registros de prueba identificados');
})();
