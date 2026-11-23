// Reejecutable: actualiza solo registros identificados de la demostración.
const database = db.getSiblingDB("sigma_aqua");
const centros = [
  {codigoCentro:"C001",nombre:"Centro Calbuco (demostración)",estado:"ACTIVO",
   tanques:[{codigoTanque:"T001",nombre:"Jaula Norte 1",sensores:["PH","OXIGENO","TEMPERATURA"]},
           {codigoTanque:"T002",nombre:"Jaula Norte 2",sensores:["PH","OXIGENO","TEMPERATURA"]}]},
  {codigoCentro:"C003",nombre:"Centro Sur (demostración)",estado:"ACTIVO",
   tanques:[{codigoTanque:"T003",nombre:"Jaula Sur",sensores:["PH","OXIGENO","TEMPERATURA"]}]}
];
for (const doc of centros) database.centros.updateOne(
  {codigoCentro:doc.codigoCentro}, {$set:doc}, {upsert:true}
);
const mediciones = [
  {codigoMedicion:"M001",codigoCentro:"C001",codigoTanque:"T001",tipoSensor:"PH",valor:8.8,unidad:"pH",fecha:ISODate("2026-11-20T12:00:00Z"),estado:"ALERTA"},
  {codigoMedicion:"M002",codigoCentro:"C001",codigoTanque:"T001",tipoSensor:"OXIGENO",valor:4.0,unidad:"mg/L",fecha:ISODate("2026-11-20T12:01:00Z"),estado:"ALERTA"},
  {codigoMedicion:"M003",codigoCentro:"C001",codigoTanque:"T001",tipoSensor:"TEMPERATURA",valor:10,unidad:"°C",fecha:ISODate("2026-11-20T12:02:00Z"),estado:"NORMAL"},
  {codigoMedicion:"M004",codigoCentro:"C003",codigoTanque:"T003",tipoSensor:"PH",valor:7.5,unidad:"pH",fecha:ISODate("2026-11-20T12:03:00Z"),estado:"NORMAL"},
  {codigoMedicion:"M005",codigoCentro:"C003",codigoTanque:"T003",tipoSensor:"OXIGENO",valor:3.5,unidad:"mg/L",fecha:ISODate("2026-11-20T12:04:00Z"),estado:"ALERTA"}
];
for (const doc of mediciones) database.mediciones.updateOne(
  {codigoMedicion:doc.codigoMedicion}, {$set:doc}, {upsert:true}
);
const alertas = [
  {codigoAlerta:"A001",codigoMedicion:"M001",codigoCentro:"C001",severidad:"MEDIA",mensaje:"pH superior al umbral 8.5",estado:"PENDIENTE",fecha:ISODate("2026-11-20T12:00:00Z")},
  {codigoAlerta:"A002",codigoMedicion:"M002",codigoCentro:"C001",severidad:"ALTA",mensaje:"Oxígeno inferior al umbral 5.0 mg/L",estado:"PENDIENTE",fecha:ISODate("2026-11-20T12:01:00Z")},
  {codigoAlerta:"A003",codigoMedicion:"M005",codigoCentro:"C003",severidad:"ALTA",mensaje:"Oxígeno inferior al umbral 5.0 mg/L",estado:"PENDIENTE",fecha:ISODate("2026-11-20T12:04:00Z")}
];
for (const doc of alertas) database.alertas.updateOne(
  {codigoAlerta:doc.codigoAlerta}, {$set:doc}, {upsert:true}
);
printjson({centros:database.centros.countDocuments({}),mediciones:database.mediciones.countDocuments({}),alertas:database.alertas.countDocuments({})});
