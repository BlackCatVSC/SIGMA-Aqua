const database=db.getSiblingDB("sigma_aqua");
print("Mediciones recientes por centro:");
printjson(database.mediciones.find({codigoCentro:"C001"}).sort({fecha:-1}).toArray());
print("Alertas pendientes por severidad:");
printjson(database.alertas.aggregate([
  {$match:{estado:"PENDIENTE"}},
  {$group:{_id:"$severidad",total:{$sum:1}}},
  {$sort:{total:-1}}
]).toArray());
print("Promedio de mediciones por tipo de sensor:");
printjson(database.mediciones.aggregate([
  {$group:{_id:"$tipoSensor",promedio:{$avg:"$valor"},cantidad:{$sum:1}}},
  {$sort:{_id:1}}
]).toArray());
