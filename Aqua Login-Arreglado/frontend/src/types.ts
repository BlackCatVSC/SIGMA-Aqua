export type Rol = 'Administrador' | 'Analista' | 'Evaluador' | 'Jefatura'
export type Estado = 'Pendiente' | 'En proceso' | 'Finalizada'

export interface Usuario {
  id: number
  nombre: string
  correo: string
  rol: Rol
}

export interface Candidato {
  id: number
  nombre: string
  correo: string
  telefono: string
  cargo: string
  familia_cargo: string
  creado_en: string
}

export interface Evaluacion {
  id: number
  solicitud_id: number
  fecha_evaluacion: string
  resultado: string
  observaciones: string
  estado: string
  creado_en: string
}

export interface Solicitud {
  id: number
  candidato_id: number
  candidato_nombre: string
  cargo: string
  familia_cargo: string
  fecha_solicitud: string
  estado: Estado
  responsable_id: number | null
  responsable_nombre: string | null
  observaciones: string
  creado_en: string
  evaluacion?: Evaluacion | null
}

export interface Dashboard {
  totalCandidatos: number
  totalSolicitudes: number
  pendientes: number
  enProceso: number
  finalizadas: number
}
