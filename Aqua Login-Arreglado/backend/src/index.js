import express from 'express'
import cors from 'cors'
import { initDb } from './db.js'
import authRoutes from './routes/auth.js'
import candidatosRoutes from './routes/candidatos.js'
import solicitudesRoutes from './routes/solicitudes.js'
import dashboardRoutes from './routes/dashboard.js'
import solicitudRoutes from './routes/solicitud.js'

initDb()

const app = express()
app.use(cors())
app.use(express.json())

app.use('/api/auth', authRoutes)
app.use('/api/candidatos', candidatosRoutes)
app.use('/api/solicitudes', solicitudesRoutes)
app.use('/api/dashboard', dashboardRoutes)
app.use('/api/solicitud', solicitudRoutes)

app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' })
})

app.use((err, req, res, next) => {
  console.error(err)
  res.status(err.status || 500).json({ error: err.message || 'Error interno' })
})

const PORT = process.env.PORT || 3001
app.listen(PORT, () => {
  console.log(`API AquaChile escuchando en http://localhost:${PORT}`)
})
