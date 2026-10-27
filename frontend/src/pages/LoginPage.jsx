import { useState } from 'react';
import MenuIcon from '../components/MenuIcon';

/**
 * Página de inicio de sesión.
 * Maneja el formulario de login y llama a onLogin con los datos del token.
 *
 * @param {{ onLogin: function }} props
 */
export default function LoginPage({ onLogin }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setError('');
    setLoading(true);
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });
      if (!response.ok) {
        let message = 'No se pudo iniciar sesión.';
        try {
          const errData = await response.json();
          if (errData.detail) {
            message = errData.detail;
          } else if (response.status === 401) {
            message = 'Credenciales incorrectas. Por favor, verifique su usuario y contraseña';
          }
        } catch (e) {
          if (response.status === 401) {
            message = 'Credenciales incorrectas. Por favor, verifique su usuario y contraseña';
          }
        }
        throw new Error(message);
      }
      onLogin(await response.json());
    } catch (loginError) {
      setError(loginError.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="auth-shell">
      <section className="auth-card">
        <div className="auth-icon-circle">
          <img
            src="/escudo-unp.png"
            alt="Escudo Universidad Nacional de Piura"
            className="auth-icon-logo"
          />
        </div>
        <h1 className="auth-system-code">SICEUNP</h1>
        <p className="auth-title">Sistema de Control de Elecciones Docentes</p>
        <p className="auth-university">Universidad Nacional de Piura</p>
        <form className="login-form" onSubmit={handleSubmit}>
          <div className="login-field">
            <label htmlFor="login-username">Usuario</label>
            <span className="input-with-icon">
              <MenuIcon name="person" />
              <input
                id="login-username"
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                autoComplete="username"
                required
              />
            </span>
          </div>
          <div className="login-field">
            <label htmlFor="login-password">Contraseña</label>
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                id="login-password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                autoComplete="current-password"
                required
                className={error && error.includes('Credenciales') ? 'error-input' : ''}
              />
              <button
                type="button"
                className="toggle-password-btn"
                onMouseDown={e => e.preventDefault()}
                onClick={() => setShowPassword(s => !s)}
                title={showPassword ? 'Ocultar contraseña' : 'Ver contraseña'}
                aria-label={showPassword ? 'Ocultar contraseña' : 'Ver contraseña'}
              >
                <MenuIcon name={showPassword ? 'eye' : 'eye_off'} size={18} />
              </button>
            </span>
          </div>
          {error && <p className="error" role="alert">{error}</p>}
          <button type="submit" disabled={loading}>
            <MenuIcon name="login" />
            {loading ? 'Validando...' : 'Ingresar al Sistema'}
          </button>
        </form>
        {/* CUS17 · Consultar resultados y verificar actas sin iniciar sesión */}
        <button type="button" className="auth-portal-link" onClick={() => { window.location.href = '/resultados'; }}>
          <MenuIcon name="qr" size={16} /> Consultar resultados y verificar actas
        </button>
      </section>
    </main>
  );
}
