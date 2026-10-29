import { StrictMode, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { apiRequest } from './api/apiClient';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import CambiarPasswordObligatorioPage from './pages/CambiarPasswordObligatorioPage';
import PortalResultados from './pages/resultados/PortalResultados';
import CredencialPublica from './pages/credenciales/CredencialPublica';
import './styles.css';

/**
 * Componente raiz de la aplicacion.
 * Gestiona el estado de sesion y decide que vista renderizar:
 *
 *   1. LoginPage            - sin sesion activa
 *   2. CambiarPasswordObligatorioPage - sesion iniciada PERO debeCambiarPassword=true
 *      (docente recien importado que usa su DNI como clave provisional)
 *   3. DashboardPage        - sesion normal, password ya elegida por el usuario
 */
function App() {
  const [session, setSession] = useState(null);
  // true mientras verificamos el token almacenado en sessionStorage
  const [verificando, setVerificando] = useState(true);

  useEffect(() => {
    const token = sessionStorage.getItem('accessToken');
    if (!token) { setVerificando(false); return; }

    apiRequest('/api/auth/me')
      .then((user) => {
        setSession({
          token,
          username:           user.username,
          rol:                user.rol,
          idDocente:          user.idDocente,
          debeCambiarPassword: user.debeCambiarPassword ?? false,
        });
      })
      .catch(() => sessionStorage.removeItem('accessToken'))
      .finally(() => setVerificando(false));
  }, []);

  function handleLogin(data) {
    // data = { token, username, rol, debeCambiarPassword }
    sessionStorage.setItem('accessToken', data.token);
    setSession({
      token:               data.token,
      username:            data.username,
      rol:                 data.rol,
      debeCambiarPassword: data.debeCambiarPassword ?? false,
    });
  }

  function handleLogout() {
    sessionStorage.removeItem('accessToken');
    setSession(null);
  }

  /** El docente cambio su clave exitosamente -> entrar al dashboard */
  function handlePasswordCambiada() {
    setSession(prev => ({ ...prev, debeCambiarPassword: false }));
  }

  if (verificando) {
    // Pantalla de splash minima mientras se verifica el token
    return (
      <main style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh' }}>
        <div className="spinner" />
      </main>
    );
  }

  // 1. Sin sesion -> Login
  if (!session) {
    return <LoginPage onLogin={handleLogin} />;
  }

  // 2. Sesion con cambio de clave obligatorio (docentes importados masivamente)
  if (session.debeCambiarPassword) {
    return (
      <CambiarPasswordObligatorioPage
        token={session.token}
        username={session.username}
        onCambiado={handlePasswordCambiada}
        onLogout={handleLogout}
      />
    );
  }

  // 3. Dashboard normal
  return <DashboardPage session={session} onLogout={handleLogout} />;
}

// CUS17 · Portal público (sin sesión): destino de los QR (/verificar/{token}) y resultados publicados (/resultados)
const portalPublico = /^\/(verificar|resultados)(\/|$)/.test(window.location.pathname);
// CUS07 · Destino del QR de una credencial (/credencial/{código}): datos del titular, sin sesión
const credencialPublica = window.location.pathname.startsWith('/credencial/');

createRoot(document.getElementById('root')).render(
  <StrictMode>{credencialPublica ? <CredencialPublica /> : portalPublico ? <PortalResultados /> : <App />}</StrictMode>,
);