import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../../api'
import type { Candidato } from '../../types'
import './candidatos.css'

function initials(nombre: string) {
  return nombre
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0])
    .join('')
    .toUpperCase()
}

export default function Candidatos() {
  const [candidatos, setCandidatos] = useState<Candidato[]>([])
  const [q, setQ] = useState('')
  const [error, setError] = useState('')

  async function load() {
    try {
      setError('')
      setCandidatos(await api.listCandidatos(q))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error al cargar')
    }
  }

  useEffect(() => {
    const t = setTimeout(load, 250)
    return () => clearTimeout(t)
  }, [q])

  async function onDelete(c: Candidato) {
    if (!confirm(`¿Eliminar al candidato ${c.nombre}?`)) return
    try {
      await api.deleteCandidato(c.id)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error al eliminar')
    }
  }

  const familias = useMemo(() => new Set(candidatos.map((c) => c.familia_cargo)).size, [candidatos])

  return (
    <section className="management-page">
      <div className="management-header">
        <div>
          <span className="management-eyebrow">TALENTO Y SELECCIÓN</span>
          <h1>Candidatos</h1>
          <p>Administra y consulta las personas registradas en el proceso de selección.</p>
        </div>
        <Link className="management-primary-btn" to="/candidatos/nuevo">
          <span>＋</span> Nuevo candidato
        </Link>
      </div>

      <div className="management-stats three">
        <div className="management-stat">
          <span className="management-stat-icon blue">◎</span>
          <div><small>Candidatos visibles</small><strong>{candidatos.length}</strong></div>
        </div>
        <div className="management-stat">
          <span className="management-stat-icon cyan">⌘</span>
          <div><small>Familias de cargo</small><strong>{familias}</strong></div>
        </div>
        <div className="management-stat">
          <span className="management-stat-icon green">✓</span>
          <div><small>Información registrada</small><strong>{candidatos.length ? 'Completa' : '—'}</strong></div>
        </div>
      </div>

      <div className="management-panel">
        <div className="management-toolbar">
          <div className="management-search">
            <span>⌕</span>
            <input
              aria-label="Buscar candidatos"
              placeholder="Buscar por nombre, correo, cargo o familia..."
              value={q}
              onChange={(e) => setQ(e.target.value)}
            />
            {q && <button type="button" onClick={() => setQ('')} aria-label="Limpiar búsqueda">×</button>}
          </div>
          <span className="management-result-count">{candidatos.length} resultado{candidatos.length === 1 ? '' : 's'}</span>
        </div>

        {error && <div className="management-alert danger">{error}</div>}

        <div className="management-table-wrap">
          <table className="management-table candidates-table">
            <thead>
              <tr>
                <th>Candidato</th>
                <th>Contacto</th>
                <th>Cargo</th>
                <th>Familia de cargo</th>
                <th className="actions-head">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {candidatos.map((c) => (
                <tr key={c.id}>
                  <td>
                    <div className="person-cell">
                      <span className="person-avatar">{initials(c.nombre)}</span>
                      <div><strong>{c.nombre}</strong><small>ID #{c.id}</small></div>
                    </div>
                  </td>
                  <td>
                    <div className="contact-cell"><strong>{c.correo}</strong><span>{c.telefono}</span></div>
                  </td>
                  <td><span className="role-chip">{c.cargo}</span></td>
                  <td><span className="family-chip">{c.familia_cargo}</span></td>
                  <td>
                    <div className="row-actions">
                      <Link className="row-action edit" to={`/candidatos/${c.id}/editar`}>Editar</Link>
                      <button className="row-action delete" onClick={() => onDelete(c)}>Eliminar</button>
                    </div>
                  </td>
                </tr>
              ))}
              {candidatos.length === 0 && (
                <tr><td colSpan={5} className="management-empty"><span>⌕</span><strong>No se encontraron candidatos</strong><small>Prueba con otro término de búsqueda.</small></td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
