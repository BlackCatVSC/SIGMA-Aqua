import { useEffect, useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../AuthContext'

const navLinkClass = ({ isActive }: { isActive: boolean }) =>
  `side-nav-link${isActive ? ' active' : ''}`

function Icon({ name }: { name: 'dashboard' | 'users' | 'requests' | 'logout' }) {
  const common = { width: 20, height: 20, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 1.9, strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const }

  if (name === 'dashboard') return <svg {...common}><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></svg>
  if (name === 'users') return <svg {...common}><path d="M16 21v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2" /><circle cx="9.5" cy="7" r="4" /><path d="M17 11a4 4 0 0 0 0-8" /><path d="M21 21v-2a4 4 0 0 0-3-3.87" /></svg>
  if (name === 'requests') return <svg {...common}><path d="M8 6h13" /><path d="M8 12h13" /><path d="M8 18h13" /><path d="M3 6h.01" /><path d="M3 12h.01" /><path d="M3 18h.01" /></svg>
  return <svg {...common}><path d="M10 17l5-5-5-5" /><path d="M15 12H3" /><path d="M21 3v18" /></svg>
}

export default function Layout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [menuOpen, setMenuOpen] = useState(false)
  const [expanded, setExpanded] = useState(false)
  const [darkMode, setDarkMode] = useState(() => localStorage.getItem('aqua-theme') === 'dark')

  useEffect(() => {
    document.documentElement.dataset.theme = darkMode ? 'dark' : 'light'
    localStorage.setItem('aqua-theme', darkMode ? 'dark' : 'light')
  }, [darkMode])

  function onLogout() {
    logout()
    navigate('/login')
  }

  function closeMenu() {
    setMenuOpen(false)
  }

  return (
    <div className={`app-shell${expanded ? '' : ' sidebar-collapsed'}`}>
      <aside
        className={`app-sidebar${menuOpen ? ' mobile-open' : ''}${expanded ? '' : ' collapsed'}`}
        onMouseEnter={() => setExpanded(true)}
        onMouseLeave={() => setExpanded(false)}
      >
        <div className="sidebar-top">
          <Link className="sidebar-brand" to="/" onClick={closeMenu}>
            <span className="sidebar-brand-mark">EP</span>
            <span>
              <strong>Evaluaciones</strong>
              <small>Psicolaborales</small>
            </span>
          </Link>
        </div>

        <div className="sidebar-section-title">MENÚ PRINCIPAL</div>

        <nav className="sidebar-nav" aria-label="Navegación principal">
          <NavLink className={navLinkClass} to="/" end onClick={closeMenu}>
            <Icon name="dashboard" />
            <span>Dashboard</span>
          </NavLink>
          <NavLink className={navLinkClass} to="/candidatos" onClick={closeMenu}>
            <Icon name="users" />
            <span>Candidatos</span>
          </NavLink>
          <NavLink className={navLinkClass} to="/solicitudes" onClick={closeMenu}>
            <Icon name="requests" />
            <span>Solicitudes</span>
          </NavLink>
        </nav>

        <div className="sidebar-bottom">
          <div className="sidebar-user">
            <div className="sidebar-avatar">
              {user?.nombre?.charAt(0).toUpperCase() ?? 'U'}
            </div>
            <div className="sidebar-user-text">
              <strong>{user?.nombre}</strong>
              <span>{user?.rol}</span>
            </div>
          </div>

          <button className="sidebar-logout" type="button" onClick={onLogout}>
            <Icon name="logout" />
            <span>Salir</span>
          </button>
        </div>
      </aside>

      {menuOpen && <button className="sidebar-overlay" aria-label="Cerrar menú" onClick={closeMenu} />}

      <div className="app-content">
        <header className="app-topbar">
          <button
            className="mobile-menu-button"
            type="button"
            aria-label="Abrir menú"
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen((open) => !open)}
          >
            <span /><span /><span />
          </button>
          <div className="topbar-title">
            <span>Panel de gestión</span>
          </div>
          <div className="topbar-actions">
            <button
              className="theme-toggle"
              type="button"
              aria-label={darkMode ? 'Activar modo claro' : 'Activar modo oscuro'}
              title={darkMode ? 'Modo claro' : 'Modo oscuro'}
              onClick={() => setDarkMode((enabled) => !enabled)}
            >
              {darkMode ? (
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round">
                  <circle cx="12" cy="12" r="4" />
                  <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
                </svg>
              ) : (
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21 12.8A8.5 8.5 0 1 1 11.2 3a6.6 6.6 0 0 0 9.8 9.8Z" />
                </svg>
              )}
            </button>
            <div className="topbar-user">
            <div className="topbar-avatar">{user?.nombre?.charAt(0).toUpperCase() ?? 'U'}</div>
            <div>
              <strong>{user?.nombre}</strong>
              <span>{user?.rol}</span>
            </div>
          </div>
          </div>
        </header>

        <main className="app-main">
          <div className="app-container">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  )
}
