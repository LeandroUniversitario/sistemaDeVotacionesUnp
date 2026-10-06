import { StrictMode, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { apiRequest } from './api/apiClient';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import './styles.css';

/**
 * Componente raíz de la aplicación.
 * Gestiona el estado de sesión y decide qué vista renderizar:
 * - LoginPage si no hay sesión activa.
 * - DashboardPage si el usuario está autenticado.
 */
function App() {
  const [session, setSession] = useState(null);

  useEffect(() => {
    const token = sessionStorage.getItem('accessToken');
    if (!token) return;
    apiRequest('/api/auth/me')
      .then((user) => setSession({ username: user.username, rol: user.rol, token }))
      .catch(() => sessionStorage.removeItem('accessToken'));
  }, []);

  function handleLogin(data) {
    sessionStorage.setItem('accessToken', data.token);
    setSession(data);
  }

  function handleLogout() {
    sessionStorage.removeItem('accessToken');
    setSession(null);
  }

  return session
    ? <DashboardPage session={session} onLogout={handleLogout} />
    : <LoginPage onLogin={handleLogin} />;
}

createRoot(document.getElementById('root')).render(
  <StrictMode><App /></StrictMode>,
);
