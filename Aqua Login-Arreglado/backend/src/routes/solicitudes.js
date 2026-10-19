import { Router } from 'express'
import { db } from '../db.js'

const router = Router()

const SOLICITUD_SELECT = `
  SELECT s.*, c.nombre AS candidato_nombre, u.nombre AS responsable_nombre
  FROM solicitudes s
  JOIN candidatos c ON c.id = s.candidato_id
  LEFT JOIN usuarios u ON u.id = s.responsable_id
`

router.get('/', (req, res) => {
  const estado = (req.query.estado || '').toString().trim()
  const q = (req.query.q || '').toString().trim()
  const conds = []
  const params = []

  if (estado) {
    conds.push('s.estado = ?')
    params.push(estado)
  }
  if (q) {
    conds.push('(c.nombre LIKE ? OR s.cargo LIKE ? OR s.familia_cargo LIKE ?)')
    params.push(`%${q}%`, `%${q}%`, `%${q}%`)
  }

  const where = conds.length ? `WHERE ${conds.join(' AND ')}` : ''
  const rows = db.prepare(`${SOLICITUD_SELECT} ${where} ORDER BY s.id DESC`).all(...params)
  res.json(rows)
})

router.get('/:id', (req, res) => {
  const row = db.prepare(`${SOLICITUD_SELECT} WHERE s.id = ?`).get(req.params.id)
  if (!row) return res.status(404).json({ error: 'Solicitud no encontrada' })
  const evaluacion = db
    .prepare('SELECT * FROM evaluaciones WHERE solicitud_id = ?')
    .get(req.params.id)
  res.json({ ...row, evaluacion: evaluacion || null })
})

router.post('/', (req, res) => {
  const { candidatoId, cargo, familiaCargo, fechaSolicitud, estado, responsableId, observaciones } = req.body || {}
  if (!candidatoId || !cargo || !familiaCargo) {
    return res.status(400).json({ error: 'Candidato, cargo y familia de cargo son obligatorios' })
  }
  const candidato = db.prepare('SELECT id FROM candidatos WHERE id = ?').get(candidatoId)
  if (!candidato) return res.status(400).json({ error: 'Candidato no existe' })

  const creadoEn = new Date().toISOString()
  const info = db
    .prepare(
      `INSERT INTO solicitudes
       (candidato_id, cargo, familia_cargo, fecha_solicitud, estado, responsable_id, observaciones, creado_en)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      candidatoId,
      cargo,
      familiaCargo,
      fechaSolicitud || new Date().toISOString().slice(0, 10),
      estado || 'Pendiente',
      responsableId || null,
      observaciones || '',
      creadoEn
    )
  const row = db.prepare(`${SOLICITUD_SELECT} WHERE s.id = ?`).get(info.lastInsertRowid)
  res.status(201).json(row)
})

router.put('/:id', (req, res) => {
  const existing = db.prepare('SELECT * FROM solicitudes WHERE id = ?').get(req.params.id)
  if (!existing) return res.status(404).json({ error: 'Solicitud no encontrada' })
  const { estado, responsableId, observaciones } = req.body || {}
  db.prepare(
    'UPDATE solicitudes SET estado = ?, responsable_id = ?, observaciones = ? WHERE id = ?'
  ).run(
    estado ?? existing.estado,
    responsableId ?? existing.responsable_id,
    observaciones ?? existing.observaciones,
    req.params.id
  )
  const row = db.prepare(`${SOLICITUD_SELECT} WHERE s.id = ?`).get(req.params.id)
  res.json(row)
})

router.get('/:id/evaluacion', (req, res) => {
  const solicitud = db.prepare('SELECT id FROM solicitudes WHERE id = ?').get(req.params.id)
  if (!solicitud) return res.status(404).json({ error: 'Solicitud no encontrada' })
  const evaluacion = db
    .prepare('SELECT * FROM evaluaciones WHERE solicitud_id = ?')
    .get(req.params.id)
  res.json(evaluacion || null)
})

router.post('/:id/evaluacion', (req, res) => {
  const solicitud = db.prepare('SELECT id FROM solicitudes WHERE id = ?').get(req.params.id)
  if (!solicitud) return res.status(404).json({ error: 'Solicitud no encontrada' })
  const { fechaEvaluacion, resultado, observaciones, estado } = req.body || {}
  const creadoEn = new Date().toISOString()

  const existing = db
    .prepare('SELECT id FROM evaluaciones WHERE solicitud_id = ?')
    .get(req.params.id)

  if (existing) {
    db.prepare(
      'UPDATE evaluaciones SET fecha_evaluacion = ?, resultado = ?, observaciones = ?, estado = ? WHERE id = ?'
    ).run(
      fechaEvaluacion ?? '',
      resultado ?? '',
      observaciones ?? '',
      estado ?? 'En proceso',
      existing.id
    )
  } else {
    db.prepare(
      'INSERT INTO evaluaciones (solicitud_id, fecha_evaluacion, resultado, observaciones, estado, creado_en) VALUES (?, ?, ?, ?, ?, ?)'
    ).run(
      req.params.id,
      fechaEvaluacion || '',
      resultado || '',
      observaciones || '',
      estado || 'En proceso',
      creadoEn
    )
  }

  const evaluacion = db
    .prepare('SELECT * FROM evaluaciones WHERE solicitud_id = ?')
    .get(req.params.id)
  res.status(201).json(evaluacion)
})

export default router
