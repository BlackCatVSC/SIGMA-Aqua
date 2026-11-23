// Pruebas adicionales seguras sobre documentos temporales; requieren 01 y 02.
const database = db.getSiblingDB("sigma_aqua");
const codigo = "EV3-TEST-EXTRA";
let ok = 0, errores = 0;
function test(cond, titulo) {
  print((cond ? "[OK] " : "[ERROR] ") + titulo);
  if (cond) ok++; else errores++;
}
function baseDoc(code) {
  return {codigoMedicion:code,codigoCentro:"C001",codigoTanque:"T001",
    tipoSensor:"PH",valor:7.1,unidad:"pH",fecha:new Date(),estado:"NORMAL"};
}
try {
  database.mediciones.deleteMany({codigoMedicion:codigo});
  database.mediciones.insertOne(baseDoc(codigo));
  let duplicadoRechazado = false;
  try { database.mediciones.insertOne(baseDoc(codigo)); }
  catch(e) { duplicadoRechazado = e.code === 11000; }
  test(duplicadoRechazado,"Índice único rechaza código duplicado");
  let estadoInvalidoRechazado = false;
  try { database.mediciones.updateOne({codigoMedicion:codigo},{$set:{estado:"DESCONOCIDO"}}); }
  catch(e) { estadoInvalidoRechazado = true; }
  test(estadoInvalidoRechazado,"Validador rechaza estado desconocido");
  const c=database.centros.findOne({codigoCentro:"C001"});
  test(!!c && c.tanques.some(t=>t.codigoTanque==="T001" && t.sensores.includes("PH")),
       "Referencia lógica centro/tanque/sensor válida");
  const alertas=database.alertas.find({codigoAlerta:{$in:["A001","A002","A003"]}}).toArray();
  test(alertas.length===3 && alertas.every(a=>!!database.mediciones.findOne({codigoMedicion:a.codigoMedicion})),
       "Las tres alertas de ejemplo referencian mediciones existentes");
  test(database.mediciones.countDocuments({codigoMedicion:codigo})===1,
       "Documento temporal no se duplicó");
} catch(e) {
  errores++; print("[ERROR] Excepción: "+e.message);
} finally {
  database.mediciones.deleteMany({codigoMedicion:codigo});
}
print(`PRUEBAS AMPLIADAS: ${ok} correctas, ${errores} fallidas`);
if (errores) quit(1);
