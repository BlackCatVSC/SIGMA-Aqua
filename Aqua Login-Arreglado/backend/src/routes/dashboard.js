import { Router } from 'express'
import { db } from '../db.js'

const router = Router()

router.get('/', (req, res) => {
  const totalCandidatos = db.prepare('SELECT COUNT(*) AS n FROM candidatos').get().n
  const totalSolicitudes = db.prepare('SELECT COUNT(*) AS n FROM solicitudes').get().n
  const pendientes = db.prepare("SELECT COUNT(*) AS n FROM solicitudes WHERE estado = 'Pendiente'").get().n
  const enProceso = db.prepare("SELECT COUNT(*) AS n FROM solicitudes WHERE estado = 'En proceso'").get().n
  const finalizadas = db.prepare("SELECT COUNT(*) AS n FROM solicitudes WHERE estado = 'Finalizada'").get().n

  res.json({ totalCandidatos, totalSolicitudes, pendientes, enProceso, finalizadas })
})

export default router
