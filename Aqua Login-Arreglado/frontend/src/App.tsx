import type { ReactNode } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider, useAuth } from './AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login/LoginPage'
import Dashboard from './pages/Dashboard/DashboardPage'
import Candidatos from './pages/Candidatos/CandidatosPage'
import CandidatoForm from './pages/CandidatoForm/CandidatoFormPage'
import Solicitudes from './pages/Solicitudes/SolicitudesPage'
import SolicitudForm from './pages/SolicitudForm/SolicitudFormPage'
import SolicitudDetalle from './pages/SolicitudDetalle/SolicitudDetallePage'

function Protected({ children }: { children: ReactNode }) {
  const { user } = useAuth()
  return user ? <>{children}</> : <Navigate to="/login" replace />
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            element={
              <Protected>
                <Layout />
              </Protected>
            }
          >
            <Route path="/" element={<Dashboard />} />
            <Route path="/candidatos" element={<Candidatos />} />
            <Route path="/candidatos/nuevo" element={<CandidatoForm />} />
            <Route path="/candidatos/:id/editar" element={<CandidatoForm />} />
            <Route path="/solicitudes" element={<Solicitudes />} />
            <Route path="/solicitudes/nueva" element={<SolicitudForm />} />
            <Route path="/solicitudes/:id" element={<SolicitudDetalle />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
