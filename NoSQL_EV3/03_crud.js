// CRUD de una medición temporal; no toca datos base ni borra información real.
const database = db.getSiblingDB("sigma_aqua");
const codigo = "EV3-CRUD-DEMO";
database.mediciones.deleteMany({codigoMedicion:codigo}); // limpiar SOLO demo previa
// CREATE
const inserted = database.mediciones.insertOne({
  codigoMedicion:codigo,codigoCentro:"C001",codigoTanque:"T001",
  tipoSensor:"PH",valor:7.2,unidad:"pH",fecha:new Date(),estado:"NORMAL"
});
print("CREATE"); printjson(inserted);
// READ
print("READ"); printjson(database.mediciones.findOne({codigoMedicion:codigo}));
// UPDATE
const updated = database.mediciones.updateOne(
  {codigoMedicion:codigo}, {$set:{valor:7.4,estado:"REVISADO"}}
);
print("UPDATE"); printjson(updated);
printjson(database.mediciones.findOne({codigoMedicion:codigo}));
// DELETE
const deleted = database.mediciones.deleteOne({codigoMedicion:codigo});
print("DELETE"); printjson(deleted);
print("VERIFICACIÓN: registros restantes = "+database.mediciones.countDocuments({codigoMedicion:codigo}));
