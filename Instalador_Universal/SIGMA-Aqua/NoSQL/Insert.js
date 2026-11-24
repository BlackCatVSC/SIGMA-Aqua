(() => {
const coleccion = db.getSiblingDB("sigma_aqua").getCollection("reportes_jaula");
// ===================== CREATE =====================
const reporte = {
  "codigo_reporte": "REP-J12-20261118",
  "estado": "ALERTA",
  "peces_vivos": 9800,
  "biomasa_kg": 48500,
  "alerta_activa": true,
  "centro": { "nombre": "Centro Chiloé Norte", "zona": "Zona 10A", "comuna": "Ancud" },
  "jaula": { "codigo": "J-12", "especie": "Salmón Atlántico" },
  "etiquetas": ["ph_bajo", "revision_urgente"],
  "lecturas": [
    { "parametro": "pH", "valor": 6.1 },
    { "parametro": "oxigeno", "valor": 6.8 },
    { "parametro": "temp", "valor": 12.4 }
  ],
  "nota_temporal": "Revisar sensor de pH",
  "fecha_reporte": new Date("2026-11-18T08:00:00-03:00")
};
coleccion.createIndex({codigo_reporte: 1}, {unique: true});
printjson(coleccion.updateOne({codigo_reporte: reporte.codigo_reporte}, {$setOnInsert: reporte}, {upsert: true}));
})();
