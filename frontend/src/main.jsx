import { StrictMode, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { apiRequest } from './api/apiClient';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import CambiarPasswordObligatorioPage from './pages/CambiarPasswordObligatorioPage';
import PortalResultados from './pages/resultados/PortalResultados';
import CredencialPublica from './pages/credenciales/CredencialPublica';
import TerminalVotacion from './pages/votacion/TerminalVotacion';
import ErrorBoundary from './components/ErrorBoundary';
import './styles.css';
import './theme/ejecutivo.css'; // capa de diseño ejecutivo: va al final para prevalecer

/**
 * Componente raiz de la aplicacion.
 * Gestiona el estado de sesion y decide que vista renderizar:
 *
 *   1. LoginPage            - sin sesion activa
 *   2. CambiarPasswordObligatorioPage - sesion iniciada PERO debeCambiarPassword=true
 *      (cuenta con clave provisional aleatoria; el backend tambien bloquea el resto de la API)
 *   3. DashboardPage        - sesion normal, password ya elegida por el usuario
 */
/**
 * Quita la sección (#/...) de la URL. Al iniciar o cerrar sesión cada cuenta debe entrar a la pantalla
 * inicial de SU rol, no a la que dejó abierta la sesión anterior (que puede ni existir para el nuevo rol
 * y dejaba la pantalla en blanco).
 */
function limpiarRuta() {
  if (window.location.hash) window.history.replaceState(null, '', window.location.pathname + window.location.search);
}

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
    limpiarRuta();
    setSession({
      token:               data.token,
      username:            data.username,
      rol:                 data.rol,
      debeCambiarPassword: data.debeCambiarPassword ?? false,
    });
    // El login no devuelve idDocente: se completa con /me (lo usan instalación, cierre y escrutinio)
    apiRequest('/api/auth/me')
      .then((user) => setSession((prev) => (prev && prev.username === user.username
        ? { ...prev, idDocente: user.idDocente }
        : prev)))
      .catch(() => { });
  }

  function handleLogout() {
    sessionStorage.removeItem('accessToken');
    limpiarRuta();
    setSession(null);
  }

  /** El docente cambio su clave exitosamente -> entrar al dashboard (con el token nuevo) */
  function handlePasswordCambiada(nuevoToken) {
    setSession(prev => ({ ...prev, token: nuevoToken ?? prev.token, debeCambiarPassword: false }));
  }

  // A4: renovación de la sesión mientras la aplicación está abierta (la jornada dura más que el token)
  useEffect(() => {
    if (!session) return undefined;
    const timer = setInterval(async () => {
      try {
        const r = await apiRequest('/api/auth/renovar', { method: 'POST' });
        if (r?.token) sessionStorage.setItem('accessToken', r.token);
      } catch (e) {
        if (e.message === 'SESSION_EXPIRED') handleLogout();
      }
    }, 20 * 60 * 1000);
    return () => clearInterval(timer);
  }, [session?.username]);

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
  // key: cada cuenta monta un panel nuevo, sin el estado (sección, filtros, datos) de la anterior
  return <DashboardPage key={session.username} session={session} onLogout={handleLogout} />;
}

// CUS17 · Portal público (sin sesión): destino de los QR (/verificar/{token}) y resultados publicados (/resultados)
const portalPublico = /^\/(verificar|resultados)(\/|$)/.test(window.location.pathname);
// CUS07 · Destino del QR de una credencial (/credencial/{código}): datos del titular, sin sesión
const credencialPublica = window.location.pathname.startsWith('/credencial/');
// CUS10 · Cabina de votación: pantalla completa, sin menú ni sesión de persona (secreto del equipo)
const cabina = /^\/cabina\/?$/.test(window.location.pathname);

function Cabina() {
  return <main className="cabina-kiosco"><TerminalVotacion modo="cabina" /></main>;
}

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <ErrorBoundary>
    {cabina ? <Cabina /> : credencialPublica ? <CredencialPublica /> : portalPublico ? <PortalResultados /> : <App />}
    </ErrorBoundary>
  </StrictMode>,
);