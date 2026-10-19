import { Router } from 'express'
import { db } from '../db.js'

const router = Router()

router.get('/', (req, res) => {
  const q = (req.query.q || '').toString().trim()
  let rows
  if (q) {
    rows = db
      .prepare(
        `SELECT * FROM candidatos
         WHERE nombre LIKE ? OR correo LIKE ? OR cargo LIKE ? OR familia_cargo LIKE ?
         ORDER BY id DESC`
      )
      .all(`%${q}%`, `%${q}%`, `%${q}%`, `%${q}%`)
  } else {
    rows = db.prepare('SELECT * FROM candidatos ORDER BY id DESC').all()
  }
  res.json(rows)
})

router.get('/:id', (req, res) => {
  const row = db.prepare('SELECT * FROM candidatos WHERE id = ?').get(req.params.id)
  if (!row) return res.status(404).json({ error: 'Candidato no encontrado' })
  res.json(row)
})

router.post('/', (req, res) => {
  const { nombre, correo, telefono, cargo, familiaCargo } = req.body || {}
  if (!nombre || !correo || !cargo || !familiaCargo) {
    return res.status(400).json({ error: 'Nombre, correo, cargo y familia de cargo son obligatorios' })
  }
  const creadoEn = new Date().toISOString()
  const info = db
    .prepare(
      'INSERT INTO candidatos (nombre, correo, telefono, cargo, familia_cargo, creado_en) VALUES (?, ?, ?, ?, ?, ?)'
    )
    .run(nombre, correo, telefono || '', cargo, familiaCargo, creadoEn)
  const row = db.prepare('SELECT * FROM candidatos WHERE id = ?').get(info.lastInsertRowid)
  res.status(201).json(row)
})

router.put('/:id', (req, res) => {
  const existing = db.prepare('SELECT * FROM candidatos WHERE id = ?').get(req.params.id)
  if (!existing) return res.status(404).json({ error: 'Candidato no encontrado' })
  const { nombre, correo, telefono, cargo, familiaCargo } = req.body || {}
  db.prepare(
    'UPDATE candidatos SET nombre = ?, correo = ?, telefono = ?, cargo = ?, familia_cargo = ? WHERE id = ?'
  ).run(
    nombre ?? existing.nombre,
    correo ?? existing.correo,
    telefono ?? existing.telefono,
    cargo ?? existing.cargo,
    familiaCargo ?? existing.familia_cargo,
    req.params.id
  )
  const row = db.prepare('SELECT * FROM candidatos WHERE id = ?').get(req.params.id)
  res.json(row)
})

router.delete('/:id', (req, res) => {
  const info = db.prepare('DELETE FROM candidatos WHERE id = ?').run(req.params.id)
  if (info.changes === 0) return res.status(404).json({ error: 'Candidato no encontrado' })
  res.status(204).end()
})

export default router
