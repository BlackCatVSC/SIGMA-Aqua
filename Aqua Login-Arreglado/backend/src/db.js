import { DatabaseSync } from 'node:sqlite'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { mkdirSync } from 'node:fs'

const __dirname = dirname(fileURLToPath(import.meta.url))
const dataDir = join(__dirname, '..', 'data')
mkdirSync(dataDir, { recursive: true })

export const DB_PATH = join(dataDir, 'aqua.db')
export const db = new DatabaseSync(DB_PATH)

export const ESTADOS = ['Pendiente', 'En proceso', 'Finalizada']
export const ROLES = ['Administrador', 'Analista', 'Evaluador', 'Jefatura']

export function initDb() {
  db.exec(`
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS usuarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      correo TEXT NOT NULL UNIQUE,
      rol TEXT NOT NULL CHECK (rol IN ('Administrador','Analista','Evaluador','Jefatura'))
    );

    CREATE TABLE IF NOT EXISTS candidatos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      correo TEXT NOT NULL,
      telefono TEXT,
      cargo TEXT NOT NULL,
      familia_cargo TEXT NOT NULL,
      creado_en TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS solicitudes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      candidato_id INTEGER NOT NULL REFERENCES candidatos(id) ON DELETE CASCADE,
      cargo TEXT NOT NULL,
      familia_cargo TEXT NOT NULL,
      fecha_solicitud TEXT NOT NULL,
      estado TEXT NOT NULL CHECK (estado IN ('Pendiente','En proceso','Finalizada')),
      responsable_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
      observaciones TEXT,
      creado_en TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS evaluaciones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      solicitud_id INTEGER NOT NULL UNIQUE REFERENCES solicitudes(id) ON DELETE CASCADE,
      fecha_evaluacion TEXT,
      resultado TEXT,
      observaciones TEXT,
      estado TEXT NOT NULL CHECK (estado IN ('Pendiente','En proceso','Finalizada')),
      creado_en TEXT NOT NULL
    );
  `)

  seed()
}

function seed() {
  const usuarios = db.prepare('SELECT COUNT(*) AS n FROM usuarios').get()
  if (usuarios.n > 0) return

  const now = new Date().toISOString()

  const insertUsuario = db.prepare(
    'INSERT INTO usuarios (nombre, correo, rol) VALUES (?, ?, ?)'
  )
  const insertCandidato = db.prepare(
    'INSERT INTO candidatos (nombre, correo, telefono, cargo, familia_cargo, creado_en) VALUES (?, ?, ?, ?, ?, ?)'
  )
  const insertSolicitud = db.prepare(
    'INSERT INTO solicitudes (candidato_id, cargo, familia_cargo, fecha_solicitud, estado, responsable_id, observaciones, creado_en) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  )
  const insertEvaluacion = db.prepare(
    'INSERT INTO evaluaciones (solicitud_id, fecha_evaluacion, resultado, observaciones, estado, creado_en) VALUES (?, ?, ?, ?, ?, ?)'
  )

  insertUsuario.run('Sistema Admin', 'admin@aqua.test', 'Administrador')
  insertUsuario.run('Camila Muñoz', 'camila@aqua.test', 'Analista')
  insertUsuario.run('María Victoria', 'maria.victoria@aqua.test', 'Evaluador')
  insertUsuario.run('Jefatura RRHH', 'jefatura@aqua.test', 'Jefatura')

  const cands = [
    ['Juan Pérez', 'juan.perez@mail.com', '+56 9 1111 2222', 'Operador de Máquina', 'Operario Calificado'],
    ['María González', 'maria.gonzalez@mail.com', '+56 9 2222 3333', 'Analista de Sistemas', 'Profesional B C'],
    ['Pedro Soto', 'pedro.soto@mail.com', '+56 9 3333 4444', 'Gruero', 'Operario Calificado'],
    ['Ana Torres', 'ana.torres@mail.com', '+56 9 4444 5555', 'Jefa de SSO', 'Jefatura'],
    ['Luis Rojas', 'luis.rojas@mail.com', '+56 9 5555 6666', 'Supervisor de Planta', 'Supervisor B'],
  ]
  for (const c of cands) {
    insertCandidato.run(c[0], c[1], c[2], c[3], c[4], now)
  }

  const sols = [
    [1, 'Operador de Máquina', 'Operario Calificado', '2026-09-15', 'Finalizada', 3, 'Evaluación completada', now],
    [2, 'Analista de Sistemas', 'Profesional B C', '2026-09-18', 'En proceso', 3, '', now],
    [3, 'Gruero', 'Operario Calificado', '2026-09-20', 'Pendiente', null, '', now],
    [4, 'Jefa de SSO', 'Jefatura', '2026-09-22', 'Pendiente', 3, 'Requiere referencias', now],
    [5, 'Supervisor de Planta', 'Supervisor B', '2026-09-24', 'En proceso', 3, '', now],
  ]
  for (const s of sols) {
    insertSolicitud.run(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7])
  }

  insertEvaluacion.run(1, '2026-09-17', 'Recomendado', 'Candidato con buen desempeño conductual', 'Finalizada', now)
  insertEvaluacion.run(2, '2026-09-20', '', 'Entrevista agendada', 'En proceso', now)
}
