import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { api } from '../../api'
import { FAMILIAS } from '../../catalogs'

const empty = {
  nombre: '',
  correo: '',
  telefono: '',
  cargo: '',
  familiaCargo: '',
}

export default function CandidatoForm() {
  const { id } = useParams()
  const navigate = useNavigate()
  const isEdit = Boolean(id)

  const [form, setForm] = useState(empty)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!id) return
    api.getCandidato(Number(id)).then((c) =>
      setForm({
        nombre: c.nombre,
        correo: c.correo,
        telefono: c.telefono,
        cargo: c.cargo,
        familiaCargo: c.familia_cargo,
      }),
    )
  }, [id])

  function update<K extends keyof typeof empty>(key: K, value: string) {
    setForm((f) => ({ ...f, [key]: value }))
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setSaving(true)
    setError('')
    try {
      if (isEdit) {
        await api.updateCandidato(Number(id), form)
      } else {
        await api.createCandidato(form)
      }
      navigate('/candidatos')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al guardar')
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <div className="page-header">
        <h1>{isEdit ? 'Editar candidato' : 'Nuevo candidato'}</h1>
      </div>

      <form className="card shadow-sm" style={{ maxWidth: 640 }} onSubmit={onSubmit}>
        <div className="card-body p-4">
          {error && <div className="alert alert-danger">{error}</div>}

          <div className="mb-3">
            <label className="form-label">Nombre *</label>
            <input
              className="form-control"
              required
              value={form.nombre}
              onChange={(e) => update('nombre', e.target.value)}
            />
          </div>
          <div className="mb-3">
            <label className="form-label">Correo *</label>
            <input
              className="form-control"
              type="email"
              required
              value={form.correo}
              onChange={(e) => update('correo', e.target.value)}
            />
          </div>
          <div className="mb-3">
            <label className="form-label">Teléfono</label>
            <input
              className="form-control"
              value={form.telefono}
              onChange={(e) => update('telefono', e.target.value)}
            />
          </div>
          <div className="mb-3">
            <label className="form-label">Cargo al que postula *</label>
            <input
              className="form-control"
              required
              value={form.cargo}
              onChange={(e) => update('cargo', e.target.value)}
            />
          </div>
          <div className="mb-4">
            <label className="form-label">Familia de cargo *</label>
            <select
              className="form-select"
              required
              value={form.familiaCargo}
              onChange={(e) => update('familiaCargo', e.target.value)}
            >
              <option value="" disabled>
                Selecciona una familia
              </option>
              {FAMILIAS.map((f) => (
                <option key={f} value={f}>
                  {f}
                </option>
              ))}
            </select>
          </div>

          <div className="d-flex gap-2">
            <button className="btn btn-primary" type="submit" disabled={saving}>
              {saving ? 'Guardando…' : 'Guardar'}
            </button>
            <button className="btn btn-outline-secondary" type="button" onClick={() => navigate('/candidatos')}>
              Cancelar
            </button>
          </div>
        </div>
      </form>
    </>
  )
}
