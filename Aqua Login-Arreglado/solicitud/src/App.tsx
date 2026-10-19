import { useState, type FormEvent } from 'react'
import { FAMILIAS, ORIGENES, SI_NO, UBICACIONES, UNIDADES } from './catalogs'

const FLOW_URL =
  (import.meta.env.VITE_FLOW_URL as string | undefined) ??
  'http://localhost:3001/api/solicitud'

type FormState = {
  reclutador: string
  nombreCandidato: string
  origen: string
  familiaCargo: string
  nombreCargo: string
  ubicacion: string
  unidad: string
  requiereReferencias: string
  ceco: string
  esReferido: string
  aspectos: string
}

const initialForm: FormState = {
  reclutador: '',
  nombreCandidato: '',
  origen: '',
  familiaCargo: '',
  nombreCargo: '',
  ubicacion: '',
  unidad: '',
  requiereReferencias: 'No',
  ceco: '',
  esReferido: 'No',
  aspectos: '',
}

type Status = 'idle' | 'sending' | 'ok' | 'error'

export default function App() {
  const [form, setForm] = useState<FormState>(initialForm)
  const [cvFile, setCvFile] = useState<File | null>(null)
  const [descFile, setDescFile] = useState<File | null>(null)
  const [status, setStatus] = useState<Status>('idle')
  const [errorMsg, setErrorMsg] = useState('')

  function update<K extends keyof FormState>(key: K, value: string) {
    setForm((f) => ({ ...f, [key]: value }))
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setErrorMsg('')

    if (!cvFile) {
      setErrorMsg('Debes adjuntar el CV del candidato (PDF o DOCX).')
      return
    }

    setStatus('sending')

    try {
      if (FLOW_URL) {
        const data = new FormData()
        data.append('reclutador', form.reclutador.trim())
        data.append('nombreCandidato', form.nombreCandidato.trim())
        data.append('origen', form.origen)
        data.append('familiaCargo', form.familiaCargo)
        data.append('nombreCargo', form.nombreCargo.trim())
        data.append('ubicacion', form.ubicacion.trim())
        data.append('unidad', form.unidad.trim())
        data.append('requiereReferencias', form.requiereReferencias)
        data.append('ceco', form.ceco.trim())
        data.append('esReferido', form.esReferido)
        data.append('aspectos', form.aspectos.trim())
        data.append('cv', cvFile)
        if (descFile) data.append('descriptor', descFile)

        const res = await fetch(FLOW_URL, { method: 'POST', body: data })
        if (!res.ok) throw new Error(`El flujo respondió con estado ${res.status}.`)
      } else {
        await new Promise((r) => setTimeout(r, 600))
      }

      setStatus('ok')
    } catch (err) {
      setStatus('error')
      setErrorMsg(err instanceof Error ? err.message : 'No se pudo enviar la solicitud.')
    }
  }

  function reset() {
    setForm(initialForm)
    setCvFile(null)
    setDescFile(null)
    setStatus('idle')
    setErrorMsg('')
  }

  if (status === 'ok') {
    return (
      <div className="screen">
        <div className="card card--center">
          <span className="check" aria-hidden="true">
            ✓
          </span>
          <h1>Solicitud enviada</h1>
          <p>La solicitud de evaluación psicolaboral fue registrada correctamente.</p>

          <dl className="summary">
            <dt>Candidato/a</dt>
            <dd>{form.nombreCandidato}</dd>
            <dt>Origen</dt>
            <dd>{form.origen}</dd>
            <dt>Cargo</dt>
            <dd>{form.nombreCargo}</dd>
            <dt>Familia de cargo</dt>
            <dd>{form.familiaCargo}</dd>
            <dt>Ubicación</dt>
            <dd>{form.ubicacion}</dd>
            <dt>CV adjunto</dt>
            <dd>{cvFile?.name}</dd>
          </dl>

          <button className="btn" onClick={reset}>
            Nueva solicitud
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="screen">
      <form className="card card--wide" onSubmit={onSubmit}>
        <h1>Solicitud de Evaluación Psicolaboral</h1>
        <p className="subtitle">Reclutamiento y Selección · AquaChile</p>

        <section>
          <h2>Solicitante</h2>
          <label>
            Reclutador/a <span className="req">*</span>
            <input
              required
              value={form.reclutador}
              onChange={(e) => update('reclutador', e.target.value)}
              placeholder="Nombre del analista que solicita"
            />
          </label>
        </section>

        <section>
          <h2>Candidato/a</h2>
          <div className="grid">
            <label>
              Nombre del candidato/a <span className="req">*</span>
              <input
                required
                value={form.nombreCandidato}
                onChange={(e) => update('nombreCandidato', e.target.value)}
                placeholder="Nombre y apellido"
              />
            </label>
            <fieldset>
              <legend>
                Origen del candidato/a <span className="req">*</span>
              </legend>
              <div className="radio-row">
                {ORIGENES.map((o) => (
                  <label key={o} className="radio">
                    <input
                      type="radio"
                      name="origen"
                      required
                      checked={form.origen === o}
                      onChange={() => update('origen', o)}
                    />
                    {o}
                  </label>
                ))}
              </div>
            </fieldset>
          </div>
        </section>

        <section>
          <h2>Cargo</h2>
          <div className="grid">
            <label>
              Familia de cargo <span className="req">*</span>
              <select
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
            </label>
            <label>
              Nombre del cargo <span className="req">*</span>
              <input
                required
                value={form.nombreCargo}
                onChange={(e) => update('nombreCargo', e.target.value)}
                placeholder="Ej. Operador de Máquina"
              />
            </label>
            <label>
              Ubicación del cargo <span className="req">*</span>
              <input
                required
                list="ubicaciones"
                value={form.ubicacion}
                onChange={(e) => update('ubicacion', e.target.value)}
                placeholder="Planta, oficina o centro"
              />
              <datalist id="ubicaciones">
                {UBICACIONES.map((u) => (
                  <option key={u} value={u} />
                ))}
              </datalist>
            </label>
            <label>
              Unidad
              <input
                list="unidades"
                value={form.unidad}
                onChange={(e) => update('unidad', e.target.value)}
                placeholder="Ej. Industrial"
              />
              <datalist id="unidades">
                {UNIDADES.map((u) => (
                  <option key={u} value={u} />
                ))}
              </datalist>
            </label>
            <label>
              CECO (centro de costos)
              <input
                value={form.ceco}
                onChange={(e) => update('ceco', e.target.value)}
                placeholder="Ej. A170010301"
              />
            </label>
            <fieldset>
              <legend>
                Requiere referencias <span className="req">*</span>
              </legend>
              <div className="radio-row">
                {SI_NO.map((s) => (
                  <label key={s} className="radio">
                    <input
                      type="radio"
                      name="requiereReferencias"
                      checked={form.requiereReferencias === s}
                      onChange={() => update('requiereReferencias', s)}
                    />
                    {s}
                  </label>
                ))}
              </div>
            </fieldset>
          </div>
        </section>

        <section>
          <h2>Documentos</h2>
          <div className="grid">
            <label>
              Currículum (CV) <span className="req">*</span>
              <input
                type="file"
                required
                accept=".pdf,.doc,.docx"
                onChange={(e) => setCvFile(e.target.files?.[0] ?? null)}
              />
              <small>{cvFile ? `Adjunto: ${cvFile.name}` : 'PDF o DOCX'}</small>
            </label>
            <label>
              Descriptor del cargo
              <input
                type="file"
                accept=".pdf,.doc,.docx"
                onChange={(e) => setDescFile(e.target.files?.[0] ?? null)}
              />
              <small>{descFile ? `Adjunto: ${descFile.name}` : 'Opcional'}</small>
            </label>
          </div>
        </section>

        <section>
          <h2>Información adicional</h2>
          <fieldset>
            <legend>¿El candidato es referido?</legend>
            <div className="radio-row">
              {SI_NO.map((s) => (
                <label key={s} className="radio">
                  <input
                    type="radio"
                    name="esReferido"
                    checked={form.esReferido === s}
                    onChange={() => update('esReferido', s)}
                  />
                  {s}
                </label>
              ))}
            </div>
          </fieldset>
          <label>
            Aspectos a indagar / comentarios
            <textarea
              rows={3}
              value={form.aspectos}
              onChange={(e) => update('aspectos', e.target.value)}
              placeholder="Competencias o puntos a profundizar (opcional)"
            />
          </label>
        </section>

        {errorMsg && <p className="error">{errorMsg}</p>}

        <button className="btn" type="submit" disabled={status === 'sending'}>
          {status === 'sending' ? 'Enviando…' : 'Enviar solicitud'}
        </button>
      </form>
    </div>
  )
}
