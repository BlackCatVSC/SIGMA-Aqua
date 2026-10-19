import { Router } from 'express'
import { db } from '../db.js'

const router = Router()

router.get('/usuarios', (req, res) => {
  const usuarios = db.prepare('SELECT id, nombre, correo, rol FROM usuarios ORDER BY id').all()
  res.json(usuarios)
})

router.post('/login', (req, res) => {
  const { correo } = req.body || {}
  const usuario = db.prepare('SELECT id, nombre, correo, rol FROM usuarios WHERE correo = ?').get(correo)
  if (!usuario) {
    return res.status(401).json({ error: 'Usuario no encontrado' })
  }
  res.json(usuario)
})

export default router
