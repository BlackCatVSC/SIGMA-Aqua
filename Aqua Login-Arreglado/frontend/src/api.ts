import type { Candidato, Dashboard, Evaluacion, Solicitud, Usuario } from './types'

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })
  if (res.status === 204) return undefined as T
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(data.error || `Error ${res.status}`)
  return data as T
}

export interface CandidatoInput {
  nombre: string
  correo: string
  telefono: string
  cargo: string
  familiaCargo: string
}

export interface SolicitudInput {
  candidatoId: number
  cargo: string
  familiaCargo: string
  fechaSolicitud: string
  estado: string
  responsableId: number | null
  observaciones: string
}

export interface EvaluacionInput {
  fechaEvaluacion: string
  resultado: string
  observaciones: string
  estado: string
}

export const api = {
  getUsuarios: () => request<Usuario[]>('/api/auth/usuarios'),
  login: (correo: string) =>
    request<Usuario>('/api/auth/login', { method: 'POST', body: JSON.stringify({ correo }) }),

  getDashboard: () => request<Dashboard>('/api/dashboard'),

  listCandidatos: (q = '') =>
    request<Candidato[]>(`/api/candidatos${q ? `?q=${encodeURIComponent(q)}` : ''}`),
  getCandidato: (id: number) => request<Candidato>(`/api/candidatos/${id}`),
  createCandidato: (body: CandidatoInput) =>
    request<Candidato>('/api/candidatos', { method: 'POST', body: JSON.stringify(body) }),
  updateCandidato: (id: number, body: CandidatoInput) =>
    request<Candidato>(`/api/candidatos/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  deleteCandidato: (id: number) =>
    request<void>(`/api/candidatos/${id}`, { method: 'DELETE' }),

  listSolicitudes: (opts: { estado?: string; q?: string } = {}) => {
    const params = new URLSearchParams()
    if (opts.estado) params.set('estado', opts.estado)
    if (opts.q) params.set('q', opts.q)
    const qs = params.toString()
    return request<Solicitud[]>(`/api/solicitudes${qs ? `?${qs}` : ''}`)
  },
  getSolicitud: (id: number) => request<Solicitud>(`/api/solicitudes/${id}`),
  createSolicitud: (body: SolicitudInput) =>
    request<Solicitud>('/api/solicitudes', { method: 'POST', body: JSON.stringify(body) }),
  updateSolicitud: (id: number, body: Partial<SolicitudInput>) =>
    request<Solicitud>(`/api/solicitudes/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  getEvaluacion: (id: number) => request<Evaluacion | null>(`/api/solicitudes/${id}/evaluacion`),
  saveEvaluacion: (id: number, body: EvaluacionInput) =>
    request<Evaluacion>(`/api/solicitudes/${id}/evaluacion`, {
      method: 'POST',
      body: JSON.stringify(body),
    }),
}
