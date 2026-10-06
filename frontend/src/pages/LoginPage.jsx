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
        throw new Error(response.status === 401
          ? 'Usuario o contraseña inválidos.'
          : 'No se pudo iniciar sesión.');
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
          <MenuIcon name="account_balance" />
        </div>
        <h1 className="auth-system-code">SICEUNP</h1>
        <p className="auth-title">Sistema de Control de Elecciones Docentes</p>
        <p className="auth-university">Universidad Nacional de Piura</p>
        <form className="login-form" onSubmit={handleSubmit}>
          <label>Usuario
            <span className="input-with-icon">
              <MenuIcon name="person" />
              <input
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                autoComplete="username"
                required
              />
            </span>
          </label>
          <label>Contraseña
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                autoComplete="current-password"
                required
              />
            </span>
          </label>
          {error && <p className="error" role="alert">{error}</p>}
          <button type="submit" disabled={loading}>
            <MenuIcon name="login" />
            {loading ? 'Validando...' : 'Ingresar al Sistema'}
          </button>
        </form>
      </section>
    </main>
  );
}
