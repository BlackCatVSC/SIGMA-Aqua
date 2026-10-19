import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { api } from '../../api'
import { ESTADOS } from '../../catalogs'
import type { Solicitud } from '../../types'
import './solicitudes.css'

function initials(nombre: string) {
  return nombre
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0])
    .join('')
    .toUpperCase()
}

function estadoClass(estado: string) {
  if (estado === 'Pendiente') return 'pending'
  if (estado === 'En proceso') return 'progress'
  if (estado === 'Finalizada') return 'done'
  return 'neutral'
}

export default function Solicitudes() {
  const [solicitudes, setSolicitudes] = useState<Solicitud[]>([])
  const [q, setQ] = useState('')
  const [estado, setEstado] = useState('')
  const [error, setError] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    const t = setTimeout(async () => {
      try {
        setError('')
        setSolicitudes(await api.listSolicitudes({ q, estado }))
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Error al cargar')
      }
    }, 250)
    return () => clearTimeout(t)
  }, [q, estado])

  const counts = useMemo(() => ({
    total: solicitudes.length,
    pending: solicitudes.filter((s) => s.estado === 'Pendiente').length,
    progress: solicitudes.filter((s) => s.estado === 'En proceso').length,
    done: solicitudes.filter((s) => s.estado === 'Finalizada').length,
  }), [solicitudes])

  return (
    <section className="management-page">
      <div className="management-header">
        <div>
          <span className="management-eyebrow">GESTIÓN DEL PROCESO</span>
          <h1>Solicitudes</h1>
          <p>Supervisa el estado y avance de las solicitudes de evaluación psicolaboral.</p>
        </div>
        <Link className="management-primary-btn" to="/solicitudes/nueva">
          <span>＋</span> Nueva solicitud
        </Link>
      </div>

      <div className="management-stats four">
        <div className="management-stat"><span className="management-stat-icon blue">☷</span><div><small>Total</small><strong>{counts.total}</strong></div></div>
        <div className="management-stat"><span className="management-stat-icon amber">◷</span><div><small>Pendientes</small><strong>{counts.pending}</strong></div></div>
        <div className="management-stat"><span className="management-stat-icon cyan">↗</span><div><small>En proceso</small><strong>{counts.progress}</strong></div></div>
        <div className="management-stat"><span className="management-stat-icon green">✓</span><div><small>Finalizadas</small><strong>{counts.done}</strong></div></div>
      </div>

      <div className="management-panel">
        <div className="management-toolbar request-toolbar">
          <div className="management-search">
            <span>⌕</span>
            <input
              aria-label="Buscar solicitudes"
              placeholder="Buscar por candidato, cargo o familia..."
              value={q}
              onChange={(e) => setQ(e.target.value)}
            />
            {q && <button type="button" onClick={() => setQ('')} aria-label="Limpiar búsqueda">×</button>}
          </div>
          <select value={estado} onChange={(e) => setEstado(e.target.value)} aria-label="Filtrar por estado">
            <option value="">Todos los estados</option>
            {ESTADOS.map((e) => <option key={e} value={e}>{e}</option>)}
          </select>
          <span className="management-result-count">{solicitudes.length} solicitud{solicitudes.length === 1 ? '' : 'es'}</span>
        </div>

        {error && <div className="management-alert danger">{error}</div>}

        <div className="management-table-wrap">
          <table className="management-table requests-table">
            <thead>
              <tr><th>Solicitud</th><th>Candidato</th><th>Cargo</th><th>Responsable</th><th>Fecha</th><th>Estado</th><th></th></tr>
            </thead>
            <tbody>
              {solicitudes.map((s) => (
                <tr key={s.id} onClick={() => navigate(`/solicitudes/${s.id}`)} tabIndex={0} onKeyDown={(e) => e.key === 'Enter' && navigate(`/solicitudes/${s.id}`)}>
                  <td><span className="request-number">#{s.id}</span></td>
                  <td>
                    <div className="person-cell compact">
                      <span className="person-avatar request-avatar">{initials(s.candidato_nombre)}</span>
                      <div><strong>{s.candidato_nombre}</strong><small>{s.familia_cargo}</small></div>
                    </div>
                  </td>
                  <td><span className="request-role">{s.cargo}</span></td>
                  <td>
                    {s.responsable_nombre ? <div className="responsible"><span>{initials(s.responsable_nombre)}</span>{s.responsable_nombre}</div> : <span className="unassigned">Sin asignar</span>}
                  </td>
                  <td><span className="date-cell">{s.fecha_solicitud}</span></td>
                  <td><span className={`request-status ${estadoClass(s.estado)}`}><i />{s.estado}</span></td>
                  <td><span className="row-open">→</span></td>
                </tr>
              ))}
              {solicitudes.length === 0 && (
                <tr><td colSpan={7} className="management-empty"><span>☷</span><strong>No se encontraron solicitudes</strong><small>Ajusta los filtros para ver otros registros.</small></td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
