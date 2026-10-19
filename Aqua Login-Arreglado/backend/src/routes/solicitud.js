import { Router } from 'express'
import multer from 'multer'
import { db } from '../db.js'
import { mkdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const uploadDir = join(__dirname, '..', '..', 'data', 'uploads')
mkdirSync(uploadDir, { recursive: true })

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const safe = file.originalname.replace(/[^\w.\-]+/g, '_')
    cb(null, `${Date.now()}_${safe}`)
  },
})

const upload = multer({ storage })

const router = Router()

router.post(
  '/',
  upload.fields([
    { name: 'cv', maxCount: 1 },
    { name: 'descriptor', maxCount: 1 },
  ]),
  (req, res) => {
    const {
      reclutador,
      nombreCandidato,
      origen,
      familiaCargo,
      nombreCargo,
      ubicacion,
      unidad,
      requiereReferencias,
      ceco,
      esReferido,
      aspectos,
    } = req.body || {}

    const cv = req.files?.cv?.[0]
    const descriptor = req.files?.descriptor?.[0]

    if (!nombreCandidato || !familiaCargo || !nombreCargo) {
      return res
        .status(400)
        .json({ error: 'Nombre del candidato, familia de cargo y nombre del cargo son obligatorios' })
    }

    const creadoEn = new Date().toISOString()

    const insertCandidato = db.prepare(
      'INSERT INTO candidatos (nombre, correo, telefono, cargo, familia_cargo, creado_en) VALUES (?, ?, ?, ?, ?, ?)'
    )
    const infoCandidato = insertCandidato.run(
      nombreCandidato.trim(),
      '',
      '',
      nombreCargo.trim(),
      familiaCargo.trim(),
      creadoEn
    )

    const observaciones = [
      reclutador ? `Reclutador: ${reclutador.trim()}` : '',
      origen ? `Origen: ${origen}` : '',
      ubicacion ? `Ubicación: ${ubicacion.trim()}` : '',
      unidad ? `Unidad: ${unidad.trim()}` : '',
      ceco ? `CECO: ${ceco.trim()}` : '',
      requiereReferencias ? `Requiere referencias: ${requiereReferencias}` : '',
      esReferido ? `Referido: ${esReferido}` : '',
      cv ? `CV: ${cv.filename}` : '',
      descriptor ? `Descriptor: ${descriptor.filename}` : '',
      aspectos?.trim(),
    ]
      .filter(Boolean)
      .join('\n')

    const insertSolicitud = db.prepare(
      `INSERT INTO solicitudes
       (candidato_id, cargo, familia_cargo, fecha_solicitud, estado, responsable_id, observaciones, creado_en)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    const infoSolicitud = insertSolicitud.run(
      infoCandidato.lastInsertRowid,
      nombreCargo.trim(),
      familiaCargo.trim(),
      creadoEn.slice(0, 10),
      'Pendiente',
      null,
      observaciones,
      creadoEn
    )

    const solicitud = db
      .prepare(
        `SELECT s.*, c.nombre AS candidato_nombre, u.nombre AS responsable_nombre
         FROM solicitudes s
         JOIN candidatos c ON c.id = s.candidato_id
         LEFT JOIN usuarios u ON u.id = s.responsable_id
         WHERE s.id = ?`
      )
      .get(infoSolicitud.lastInsertRowid)

    res.status(201).json(solicitud)
  }
)

export default router
