// Pruebas de integración: ejecutar DESPUÉS de 01 y 02.
// Solo escribe y elimina documentos con códigos exclusivos EV3-TEST.
const database = db.getSiblingDB("sigma_aqua");
let passed = 0, failed = 0;
function check(ok, label) {
  if (ok) {passed++; print("[OK] "+label);}
  else {failed++; print("[ERROR] "+label);}
}
const code = "EV3-TEST-001";
try {
  check(database.centros.countDocuments({codigoCentro:"C001"})===1,"Centro base existe");
  check(database.mediciones.countDocuments({codigoMedicion:{$in:["M001","M002","M003","M004","M005"]}})===5,"Cinco mediciones base");
  check(database.alertas.countDocuments({codigoAlerta:{$in:["A001","A002","A003"]}})===3,"Tres alertas base");
  database.mediciones.deleteMany({codigoMedicion:code});
  const inserted=database.mediciones.insertOne({
    codigoMedicion:code,codigoCentro:"C001",codigoTanque:"T001",
    tipoSensor:"PH",valor:7.1,unidad:"pH",fecha:new Date(),estado:"NORMAL"
  });
  check(inserted.acknowledged,"CREATE insertOne");
  check(database.mediciones.findOne({codigoMedicion:code})?.valor===7.1,"READ findOne");
  const updated=database.mediciones.updateOne({codigoMedicion:code},{$set:{valor:7.6,estado:"REVISADO"}});
  check(updated.modifiedCount===1 && database.mediciones.findOne({codigoMedicion:code})?.estado==="REVISADO","UPDATE updateOne");
  const removed=database.mediciones.deleteOne({codigoMedicion:code});
  check(removed.deletedCount===1 && database.mediciones.countDocuments({codigoMedicion:code})===0,"DELETE deleteOne");
  let rejected=false;
  try {
    database.mediciones.insertOne({codigoMedicion:code,codigoCentro:"C001",codigoTanque:"T001",tipoSensor:"PH",valor:"no-es-numero",unidad:"pH",fecha:new Date(),estado:"NORMAL"});
  } catch(e) {rejected=true;}
  check(rejected,"Validación rechaza valor no numérico");
} catch(e) {
  failed++; print("[ERROR] Excepción: "+e.message);
} finally {
  database.mediciones.deleteMany({codigoMedicion:code});
}
print(`RESULTADO: ${passed} correctas, ${failed} fallidas`);
if (failed) quit(1);
