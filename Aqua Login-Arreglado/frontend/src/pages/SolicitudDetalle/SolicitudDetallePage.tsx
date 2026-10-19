import { useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '../../api'
import { ESTADOS, RESULTADOS } from '../../catalogs'
import type { Solicitud } from '../../types'

function estadoBadge(estado: string) {
  const map: Record<string, string> = {
    Pendiente: 'warning',
    'En proceso': 'info',
    Finalizada: 'success',
  }
  return map[estado] ?? 'secondary'
}

export default function SolicitudDetalle() {
  const { id } = useParams()
  const [solicitud, setSolicitud] = useState<Solicitud | null>(null)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')

  const [evalForm, setEvalForm] = useState({
    fechaEvaluacion: '',
    resultado: '',
    observaciones: '',
    estado: 'En proceso',
  })

  async function load() {
    try {
      const s = await api.getSolicitud(Number(id))
      setSolicitud(s)
      if (s.evaluacion) {
        setEvalForm({
          fechaEvaluacion: s.evaluacion.fecha_evaluacion,
          resultado: s.evaluacion.resultado,
          observaciones: s.evaluacion.observaciones,
          estado: s.evaluacion.estado,
        })
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error al cargar')
    }
  }

  useEffect(() => {
    load()
  }, [id])

  async function onEstadoChange(estado: string) {
    try {
      await api.updateSolicitud(Number(id), { estado })
      setMsg('Estado actualizado')
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error al actualizar')
    }
  }

  async function onEvalSubmit(e: FormEvent) {
    e.preventDefault()
    try {
      await api.saveEvaluacion(Number(id), evalForm)
      setMsg('Evaluación registrada')
      load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al registrar evaluación')
    }
  }

  if (error) return <div className="alert alert-danger">{error}</div>
  if (!solicitud) return <p className="text-muted">Cargando…</p>

  return (
    <>
      <div className="page-header">
        <div>
          <h1>
            Solicitud #{solicitud.id}{' '}
            <span className={`badge text-bg-${estadoBadge(solicitud.estado)} align-middle`}>
              {solicitud.estado}
            </span>
          </h1>
          <p className="text-muted mb-0">
            {solicitud.candidato_nombre} — {solicitud.cargo}
          </p>
        </div>
        <Link className="btn btn-outline-secondary" to="/solicitudes">
          Volver
        </Link>
      </div>

      {msg && <div className="alert alert-success py-2">{msg}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      <div className="row g-3">
        <div className="col-lg-5">
          <div className="card shadow-sm">
            <div className="card-header fw-semibold">Datos de la solicitud</div>
            <div className="card-body">
              <dl className="row mb-0">
                <dt className="col-5">Candidato</dt>
                <dd className="col-7">{solicitud.candidato_nombre}</dd>
                <dt className="col-5">Cargo</dt>
                <dd className="col-7">{solicitud.cargo}</dd>
                <dt className="col-5">Familia de cargo</dt>
                <dd className="col-7">{solicitud.familia_cargo}</dd>
                <dt className="col-5">Fecha solicitud</dt>
                <dd className="col-7">{solicitud.fecha_solicitud}</dd>
                <dt className="col-5">Responsable</dt>
                <dd className="col-7">{solicitud.responsable_nombre ?? 'Sin asignar'}</dd>
                <dt className="col-5">Observaciones</dt>
                <dd className="col-7">{solicitud.observaciones || '—'}</dd>
              </dl>

              <hr />
              <label className="form-label">Actualizar estado</label>
              <select
                className="form-select"
                value={solicitud.estado}
                onChange={(e) => onEstadoChange(e.target.value)}
              >
                {ESTADOS.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="col-lg-7">
          <div className="card shadow-sm">
            <div className="card-header fw-semibold">Evaluación</div>
            <div className="card-body">
              <form onSubmit={onEvalSubmit}>
                <div className="row">
                  <div className="col-md-6 mb-3">
                    <label className="form-label">Fecha de evaluación</label>
                    <input
                      className="form-control"
                      type="date"
                      value={evalForm.fechaEvaluacion}
                      onChange={(e) => setEvalForm((f) => ({ ...f, fechaEvaluacion: e.target.value }))}
                    />
                  </div>
                  <div className="col-md-6 mb-3">
                    <label className="form-label">Resultado general</label>
                    <select
                      className="form-select"
                      value={evalForm.resultado}
                      onChange={(e) => setEvalForm((f) => ({ ...f, resultado: e.target.value }))}
                    >
                      {RESULTADOS.map((r) => (
                        <option key={r} value={r}>
                          {r || '— Sin resultado —'}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
                <div className="mb-3">
                  <label className="form-label">Estado de la evaluación</label>
                  <select
                    className="form-select"
                    value={evalForm.estado}
                    onChange={(e) => setEvalForm((f) => ({ ...f, estado: e.target.value }))}
                  >
                    {ESTADOS.map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="mb-3">
                  <label className="form-label">Observaciones</label>
                  <textarea
                    className="form-control"
                    rows={3}
                    value={evalForm.observaciones}
                    onChange={(e) => setEvalForm((f) => ({ ...f, observaciones: e.target.value }))}
                  />
                </div>
                <button className="btn btn-primary" type="submit">
                  Guardar evaluación
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
