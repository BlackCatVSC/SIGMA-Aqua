
const database = db.getSiblingDB("sigma_aqua");

const umbralesEjemplo = {
  PH: { min: 6.5, max: 8.5, unidad: "pH" },
  OXIGENO: { min: 5.0, max: 14.0, unidad: "mg/L" },
  TEMPERATURA: { min: 8.0, max: 20.0, unidad: "C" }
};

let referenciasInvalidas = 0;
let fueraDeRango = 0;

for (const m of database.mediciones.find({})) {
  const centro = database.centros.findOne({
    codigoCentro: m.codigoCentro
  });

  let tanqueExiste = false;

  if (centro && Array.isArray(centro.tanques)) {
    for (const tanque of centro.tanques) {
      if (
        tanque.codigoTanque === m.codigoTanque &&
        Array.isArray(tanque.sensores) &&
        tanque.sensores.includes(m.tipoSensor)
      ) {
        tanqueExiste = true;
        break;
      }
    }
  }

  if (!centro || !tanqueExiste) {
    referenciasInvalidas++;
    print("[REFERENCIA INVALIDA] " + m.codigoMedicion);
  }

  const u = umbralesEjemplo[m.tipoSensor];

  if (u && (m.valor < u.min || m.valor > u.max)) {
    fueraDeRango++;

    print(
      "[FUERA DE RANGO ILUSTRATIVO] " +
      m.codigoMedicion + " " +
      m.valor + " " +
      m.unidad +
      " (esperado " + u.min + "-" + u.max + ")"
    );
  }
}

printjson({
  referenciasInvalidas,
  fueraDeRango,
  aviso: "Umbrales demostrativos; validar con requisitos reales."
});

if (referenciasInvalidas > 0) {
  quit(1);
}
