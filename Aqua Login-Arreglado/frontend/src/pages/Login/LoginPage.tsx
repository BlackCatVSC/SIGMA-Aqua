import { useState, type CSSProperties, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../AuthContext'
import logoVentisqueros from '../../assets/chile_ventisqueros.jpg'
import logoPagInicio from '../../assets/logo_pag_inicio.png'

export default function Login() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [usuario, setUsuario] = useState('')
  const [contrasena, setContrasena] = useState('')
  const [mostrarContrasena, setMostrarContrasena] = useState(false)
  const [recordarme, setRecordarme] = useState(false)
  const [errorLogin, setErrorLogin] = useState('')

  const pageStyle: CSSProperties = {
    height: '100vh',
    overflow: 'hidden',
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
  }

  const leftStyle: CSSProperties = {
    background: '#ffffff',
    overflow: 'hidden',
    position: 'relative',
  }

  const imgStyle: CSSProperties = {
    width: '100%',
    height: '100%',
    objectFit: 'cover',
    display: 'block',
  }

  const overlayStyle: CSSProperties = {
    position: 'absolute',
    inset: 0,
    background: 'linear-gradient(180deg, rgba(6, 24, 40, 0.45), rgba(6, 24, 40, 0.28))',
  }

  const logoStyle: CSSProperties = {
    position: 'absolute',
    top: 32,
    left: 32,
    width: 'min(260px, 32%)',
    height: 'auto',
    filter: 'brightness(0) invert(1) drop-shadow(0 2px 8px rgba(0, 0, 0, 0.45))',
  }

  const rightStyle: CSSProperties = {
    background: '#344451',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
  }

  const cardStyle: CSSProperties = {
    width: 'min(500px, 100%)',
    padding: 40,
    background: '#ffffff',
    borderRadius: 10,
    boxShadow: '0 22px 50px rgba(0, 0, 0, 0.28)',
    transform: 'scale(0.65)',
    transformOrigin: 'center center',
  }

  const titleStyle: CSSProperties = {
    margin: 0,
    color: '#344451',
    fontFamily: 'Calibri, sans-serif',
    fontSize: 34,
    fontWeight: 800,
    textAlign: 'center',
  }

  const subtitleStyle: CSSProperties = {
    margin: '6px 0 0',
    color: '#344451',
    fontSize: 17,
    textAlign: 'center',
  }

  const fieldStyle: CSSProperties = {
    marginTop: 24,
  }

  const labelStyle: CSSProperties = {
    display: 'block',
    marginBottom: 7,
    color: '#344451',
    fontSize: 18,
    fontWeight: 600,
  }

  const inputCss = `
    .login-input {
      width: 100%;
      padding: 12px 14px;
      border: 1px solid #D1D5DB;
      border-radius: 10px;
      background: #F8FAFC;
      color: #1a2530;
      font-size: 14px;
      outline: none;
      transition: border-color .18s ease, box-shadow .18s ease, background-color .18s ease;
    }
    .login-input:hover { border-color: #9CA3AF; }
    .login-input:focus {
      border-color: #344451;
      background: #ffffff;
      box-shadow: 0 0 0 3px rgba(52, 68, 81, 0.2);
    }
  `

  const passwordWrapStyle: CSSProperties = {
    position: 'relative',
  }

  const eyeButtonStyle: CSSProperties = {
    position: 'absolute',
    top: '50%',
    right: 6,
    transform: 'translateY(-50%)',
    display: 'grid',
    placeItems: 'center',
    width: 34,
    height: 34,
    border: 'none',
    background: 'transparent',
    color: '#85919c',
    cursor: 'pointer',
  }

  const forgotStyle: CSSProperties = {
    marginTop: 18,
    textAlign: 'center',
    color: '#344451',
    fontSize: 16,
    cursor: 'pointer',
    textDecoration: 'underline',
  }

  const rememberStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    marginTop: 22,
    color: '#344451',
    fontSize: 16,
  }

  const checkboxStyle: CSSProperties = {
    width: 16,
    height: 16,
    accentColor: '#344451',
    cursor: 'pointer',
  }

  const buttonStyle: CSSProperties = {
    display: 'block',
    margin: '28px auto 0',
    padding: '12px 34px',
    border: 'none',
    borderRadius: 6,
    background: '#344451',
    color: '#ffffff',
    fontSize: 15,
    fontWeight: 700,
    cursor: 'pointer',
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault()

    if (!usuario.trim() || !contrasena.trim()) {
      setErrorLogin('Por favor, completa el usuario y la contraseña para continuar.')
      return
    }

    setErrorLogin('')
    login({
      id: 1,
      nombre: 'Usuario temporal',
      correo: 'temporal@aquachile.cl',
      rol: 'Administrador',
    })
    navigate('/')
  }

  return (
    <main style={pageStyle}>
      <style>{inputCss}</style>
      <section style={leftStyle} aria-hidden="true">
        <img src={logoVentisqueros} alt="Chile Ventisqueros" style={imgStyle} />
        <div style={overlayStyle} />
        <img src={logoPagInicio} alt="Logo" style={logoStyle} />
      </section>

      <section style={rightStyle}>
        <div style={cardStyle}>
          <h1 style={titleStyle}>¡Bienvenido!</h1>
          <p style={subtitleStyle}>Ingresa tus credenciales</p>

          <form onSubmit={handleSubmit}>
            <div style={fieldStyle}>
              <label style={labelStyle} htmlFor="usuario">
                Usuario
              </label>
              <input
                id="usuario"
                type="text"
                className="login-input"
                value={usuario}
                onChange={(e) => {
                  setUsuario(e.target.value)
                  if (errorLogin) setErrorLogin('')
                }}
                autoComplete="username"
                required
              />
            </div>

            <div style={fieldStyle}>
              <label style={labelStyle} htmlFor="contrasena">
                Contraseña
              </label>
              <div style={passwordWrapStyle}>
                <input
                  id="contrasena"
                  type={mostrarContrasena ? 'text' : 'password'}
                  className="login-input"
                  style={{ paddingRight: 46 }}
                  value={contrasena}
                  onChange={(e) => {
                    setContrasena(e.target.value)
                    if (errorLogin) setErrorLogin('')
                  }}
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  style={eyeButtonStyle}
                  aria-label={mostrarContrasena ? 'Ocultar contraseña' : 'Mostrar contraseña'}
                  onClick={() => setMostrarContrasena((v) => !v)}
                >
                  {mostrarContrasena ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19M14.12 14.12a3 3 0 1 1-4.24-4.24" />
                      <path d="M1 1l22 22" />
                    </svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  )}
                </button>
              </div>
            </div>

            {errorLogin && (
              <p
                role="alert"
                style={{
                  margin: '16px 0 0',
                  color: '#B91C1C',
                  fontSize: 14,
                  textAlign: 'center',
                }}
              >
                {errorLogin}
              </p>
            )}

            <div style={forgotStyle}>¿Olvidaste tu contraseña?</div>

            <label style={rememberStyle}>
              <input
                type="checkbox"
                style={checkboxStyle}
                checked={recordarme}
                onChange={(e) => setRecordarme(e.target.checked)}
              />
              Recordarme
            </label>

            <button type="submit" style={buttonStyle}>
              Ingresar
            </button>
          </form>
        </div>
      </section>
    </main>
  )
}
