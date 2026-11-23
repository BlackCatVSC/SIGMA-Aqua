// Ejecutar: mongosh "mongodb://127.0.0.1:27017" --file 01_creacion.js
const database = db.getSiblingDB("sigma_aqua");
const schemas = {
  centros: {
    bsonType: "object",
    required: ["codigoCentro", "nombre", "estado", "tanques"],
    properties: {
      codigoCentro: {bsonType: "string"},
      nombre: {bsonType: "string"},
      estado: {enum: ["ACTIVO", "INACTIVO"]},
      tanques: {bsonType: "array", items: {
        bsonType: "object",
        required: ["codigoTanque", "nombre", "sensores"],
        properties: {
          codigoTanque: {bsonType: "string"},
          nombre: {bsonType: "string"},
          sensores: {bsonType: "array", items: {bsonType: "string"}}
        }
      }}
    }
  },
  mediciones: {
    bsonType: "object",
    required: ["codigoMedicion", "codigoCentro", "codigoTanque", "tipoSensor", "valor", "unidad", "fecha", "estado"],
    properties: {
      codigoMedicion: {bsonType: "string"},
      codigoCentro: {bsonType: "string"},
      codigoTanque: {bsonType: "string"},
      tipoSensor: {enum: ["PH", "OXIGENO", "TEMPERATURA", "SALINIDAD", "TURBIDEZ"]},
      valor: {bsonType: ["int", "long", "double", "decimal"]},
      unidad: {bsonType: "string"},
      fecha: {bsonType: "date"},
      estado: {enum: ["NORMAL", "ALERTA", "REVISADO"]}
    }
  },
  alertas: {
    bsonType: "object",
    required: ["codigoAlerta", "codigoMedicion", "codigoCentro", "severidad", "mensaje", "estado", "fecha"],
    properties: {
      codigoAlerta: {bsonType: "string"},
      codigoMedicion: {bsonType: "string"},
      codigoCentro: {bsonType: "string"},
      severidad: {enum: ["BAJA", "MEDIA", "ALTA"]},
      mensaje: {bsonType: "string"},
      estado: {enum: ["PENDIENTE", "EN_PROCESO", "RESUELTA"]},
      fecha: {bsonType: "date"}
    }
  }
};
for (const [name, schema] of Object.entries(schemas)) {
  const validator = {$jsonSchema: schema};
  if (!database.getCollectionNames().includes(name)) {
    database.createCollection(name, {validator, validationAction: "error"});
  } else {
    database.runCommand({collMod: name, validator, validationAction: "error"});
  }
}
database.centros.createIndex({codigoCentro: 1}, {unique: true});
database.mediciones.createIndex({codigoMedicion: 1}, {unique: true});
database.mediciones.createIndex({codigoCentro: 1, fecha: -1});
database.alertas.createIndex({codigoAlerta: 1}, {unique: true});
database.alertas.createIndex({codigoMedicion: 1});
print("OK: colecciones, validadores e índices creados en sigma_aqua");
