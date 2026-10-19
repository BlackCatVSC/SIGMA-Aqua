import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../../api'
import type { Candidato, Dashboard as DashboardData, Solicitud } from '../../types'
import './dashboard.css'

type Activity = {
  type: 'solicitud' | 'candidato'
  title: string
  detail: string
  date: string
  id: number
}

function formatDate(value: string) {
  if (!value) return 'Sin fecha'
  const date = new Date(`${value}T12:00:00`)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('es-CL', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(date)
}

function formatRelativeDate(value: string) {
  if (!value) return 'Sin fecha'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return formatDate(value)

  const diff = Date.now() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)

  if (minutes >= 0 && minutes < 60) return `Hace ${Math.max(1, minutes)} min.`
  if (hours >= 0 && hours < 24) return `Hace ${Math.max(1, hours)} h.`
  if (days >= 0 && days < 7) return `Hace ${Math.max(1, days)} día${days === 1 ? '' : 's'}`
  return formatDate(value)
}

export default function Dashboard() {
  const [data, setData] = useState<DashboardData | null>(null)
  const [solicitudes, setSolicitudes] = useState<Solicitud[]>([])
  const [candidatos, setCandidatos] = useState<Candidato[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    Promise.all([api.getDashboard(), api.listSolicitudes(), api.listCandidatos()])
      .then(([dashboard, solicitudesData, candidatosData]) => {
        setData(dashboard)
        setSolicitudes(solicitudesData)
        setCandidatos(candidatosData)
      })
      .catch((e) => setError(e.message || 'No se pudieron cargar los indicadores'))
  }, [])

  const activities = useMemo<Activity[]>(() => {
    const solicitudActivities: Activity[] = solicitudes.map((solicitud) => ({
      type: 'solicitud',
      title: `Solicitud #${solicitud.id}`,
      detail: `${solicitud.candidato_nombre} · ${solicitud.cargo}`,
      date: solicitud.creado_en || solicitud.fecha_solicitud,
      id: solicitud.id,
    }))

    const candidatoActivities: Activity[] = candidatos.map((candidato) => ({
      type: 'candidato',
      title: 'Candidato registrado',
      detail: `${candidato.nombre} · ${candidato.cargo}`,
      date: candidato.creado_en,
      id: candidato.id,
    }))

    return [...solicitudActivities, ...candidatoActivities]
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 6)
  }, [solicitudes, candidatos])

  const chartData = useMemo(() => {
    const grouped = new Map<string, number>()
    solicitudes.forEach((solicitud) => {
      const key = solicitud.fecha_solicitud || solicitud.creado_en.slice(0, 10)
      grouped.set(key, (grouped.get(key) || 0) + 1)
    })

    const rows = [...grouped.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .slice(-7)
      .map(([date, count]) => ({ date, count }))

    const max = Math.max(...rows.map((row) => row.count), 1)
    return rows.map((row) => ({ ...row, height: Math.max(16, Math.round((row.count / max) * 100)) }))
  }, [solicitudes])

  const unassignedPending = solicitudes.filter(
    (solicitud) => solicitud.estado === 'Pendiente' && !solicitud.responsable_id,
  ).length

  if (error) return <div className="alert alert-danger">{error}</div>
  if (!data) {
    return (
      <div className="dashboard-loading">
        <div className="dashboard-loading-spinner" />
        <span>Cargando información del dashboard…</span>
      </div>
    )
  }

  const cards = [
    { label: 'Candidatos', value: data.totalCandidatos, icon: '◉', tone: 'blue', note: 'Registrados' },
    { label: 'Solicitudes', value: data.totalSolicitudes, icon: '☷', tone: 'slate', note: 'En el sistema' },
    { label: 'Pendientes', value: data.pendientes, icon: '◷', tone: 'amber', note: 'Requieren atención' },
    { label: 'En proceso', value: data.enProceso, icon: '↗', tone: 'cyan', note: 'En evaluación' },
    { label: 'Finalizadas', value: data.finalizadas, icon: '✓', tone: 'green', note: 'Completadas' },
  ]

  const total = Math.max(data.totalSolicitudes, 1)
  const percentages = {
    finalizadas: Math.round((data.finalizadas / total) * 100),
    enProceso: Math.round((data.enProceso / total) * 100),
    pendientes: Math.round((data.pendientes / total) * 100),
  }

  return (
    <div className="dashboard-page">
      <section className="dashboard-hero">
        <div>
          <span className="dashboard-eyebrow">RESUMEN GENERAL</span>
          <h1>Dashboard</h1>
          <p>Vista general del proceso de evaluación psicolaboral.</p>
        </div>
        <div className="dashboard-system-status">
          <span className="status-dot" />
          <div>
            <strong>Sistema operativo</strong>
            <small>Datos sincronizados con la API</small>
          </div>
        </div>
      </section>

      <section className="dashboard-stat-grid" aria-label="Indicadores principales">
        {cards.map((card) => (
          <article className={`dashboard-stat-card ${card.tone}`} key={card.label}>
            <div className="dashboard-stat-icon">{card.icon}</div>
            <div className="dashboard-stat-content">
              <span>{card.label}</span>
              <strong>{card.value}</strong>
              <small>{card.note}</small>
            </div>
          </article>
        ))}
      </section>

      <section className="dashboard-grid dashboard-grid-main">
        <article className="dashboard-panel dashboard-chart-panel">
          <div className="dashboard-panel-header">
            <div>
              <span className="dashboard-section-label">EVOLUCIÓN</span>
              <h2>Solicitudes por fecha</h2>
            </div>
            <span className="dashboard-panel-badge">{data.totalSolicitudes} total</span>
          </div>

          {chartData.length ? (
            <div className="dashboard-chart" aria-label="Solicitudes agrupadas por fecha">
              {chartData.map((item) => (
                <div className="dashboard-chart-column" key={item.date}>
                  <span className="dashboard-chart-value">{item.count}</span>
                  <div className="dashboard-chart-track">
                    <div className="dashboard-chart-bar" style={{ height: `${item.height}%` }} />
                  </div>
                  <span className="dashboard-chart-label">{formatDate(item.date).split(' ')[0]}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="dashboard-empty">Todavía no hay solicitudes para mostrar.</div>
          )}
        </article>

        <article className="dashboard-panel">
          <div className="dashboard-panel-header">
            <div>
              <span className="dashboard-section-label">SEGUIMIENTO</span>
              <h2>Estado de solicitudes</h2>
            </div>
          </div>

          <div className="dashboard-progress-list">
            <div className="dashboard-progress-row">
              <div><span>Finalizadas</span><strong>{data.finalizadas}</strong></div>
              <div className="dashboard-progress-track"><span className="green" style={{ width: `${percentages.finalizadas}%` }} /></div>
              <small>{percentages.finalizadas}%</small>
            </div>
            <div className="dashboard-progress-row">
              <div><span>En proceso</span><strong>{data.enProceso}</strong></div>
              <div className="dashboard-progress-track"><span className="cyan" style={{ width: `${percentages.enProceso}%` }} /></div>
              <small>{percentages.enProceso}%</small>
            </div>
            <div className="dashboard-progress-row">
              <div><span>Pendientes</span><strong>{data.pendientes}</strong></div>
              <div className="dashboard-progress-track"><span className="amber" style={{ width: `${percentages.pendientes}%` }} /></div>
              <small>{percentages.pendientes}%</small>
            </div>
          </div>
        </article>
      </section>

      <section className="dashboard-grid dashboard-grid-bottom">
        <article className="dashboard-panel">
          <div className="dashboard-panel-header">
            <div>
              <span className="dashboard-section-label">ACTIVIDAD</span>
              <h2>Actividad reciente</h2>
            </div>
            <Link to="/solicitudes" className="dashboard-panel-link">Ver solicitudes →</Link>
          </div>

          {activities.length ? (
            <div className="dashboard-activity-list">
              {activities.map((activity) => (
                <div className="dashboard-activity" key={`${activity.type}-${activity.id}`}>
                  <div className={`dashboard-activity-icon ${activity.type}`}>
                    {activity.type === 'solicitud' ? '☷' : '◉'}
                  </div>
                  <div className="dashboard-activity-content">
                    <strong>{activity.title}</strong>
                    <span>{activity.detail}</span>
                  </div>
                  <time>{formatRelativeDate(activity.date)}</time>
                </div>
              ))}
            </div>
          ) : (
            <div className="dashboard-empty">No hay actividad reciente.</div>
          )}
        </article>

        <article className="dashboard-panel dashboard-alert-panel">
          <div className="dashboard-panel-header">
            <div>
              <span className="dashboard-section-label">ATENCIÓN</span>
              <h2>Requiere revisión</h2>
            </div>
          </div>

          <div className="dashboard-alert-list">
            <div className="dashboard-alert-item warning">
              <div className="dashboard-alert-icon">!</div>
              <div>
                <strong>{data.pendientes} solicitudes pendientes</strong>
                <span>{unassignedPending} sin responsable asignado.</span>
              </div>
            </div>
            <div className="dashboard-alert-item info">
              <div className="dashboard-alert-icon">↗</div>
              <div>
                <strong>{data.enProceso} evaluaciones en proceso</strong>
                <span>Revisa su avance desde Solicitudes.</span>
              </div>
            </div>
          </div>

          <div className="dashboard-actions">
            <Link to="/candidatos/nuevo" className="dashboard-action primary">+ Nuevo candidato</Link>
            <Link to="/solicitudes/nueva" className="dashboard-action secondary">+ Nueva solicitud</Link>
          </div>
        </article>
      </section>

      <section className="dashboard-panel dashboard-info-panel">
        <div>
          <span className="dashboard-section-label">INFORMACIÓN</span>
          <h2>Proceso de evaluación psicolaboral</h2>
          <p>Este panel resume los candidatos y solicitudes registrados actualmente en el sistema.</p>
        </div>
        <div className="dashboard-info-metrics">
          <div><strong>{candidatos.length}</strong><span>candidatos cargados</span></div>
          <div><strong>{solicitudes.length}</strong><span>solicitudes cargadas</span></div>
        </div>
      </section>
    </div>
  )
}
