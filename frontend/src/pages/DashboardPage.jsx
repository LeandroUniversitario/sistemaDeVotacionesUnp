import { lazy, Suspense, useEffect, useRef, useState } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';
import ProcessTable from '../components/ProcessTable';
import ErrorBoundary from '../components/ErrorBoundary';
const DocentesPage = lazy(() => import('./DocentesPage'));
const CuentaPage = lazy(() => import('./CuentaPage'));
const PantallaVerificacion = lazy(() => import('./votacion/PantallaVerificacion'));
const TerminalVotacion = lazy(() => import('./votacion/TerminalVotacion'));
const CargosExcluidosPage = lazy(() => import('./CargosExcluidosPage'));
const ConvocatoriaPage = lazy(() => import('./convocatoria/ConvocatoriaPage'));
const PadronPage = lazy(() => import('./padron/PadronPage'));
const InscripcionPage = lazy(() => import('./inscripcion/InscripcionPage'));
const TachasGestionPage = lazy(() => import('./tachas/TachasGestionPage'));
const PersonerosPage = lazy(() => import('./personeros/PersonerosPage'));
const SorteoMesaPage = lazy(() => import('./sorteo/SorteoMesaPage'));
const CredencialesPage = lazy(() => import('./credenciales/CredencialesPage'));
const MisCredencialesPage = lazy(() => import('./credenciales/MisCredencialesPage'));
const VerificarCredencialPanel = lazy(() => import('./credenciales/VerificarCredencialPanel'));
const MiPaseQRPage = lazy(() => import('./MiPaseQRPage'));
const ListasDocentePage = lazy(() => import('./ListasDocentePage'));
const InstalacionMesaPage = lazy(() => import('./instalacion/InstalacionMesaPage'));
const PantallaCierreSufragio = lazy(() => import('./cierre/PantallaCierreSufragio'));
const PantallaImpugnaciones = lazy(() => import('./impugnaciones/PantallaImpugnaciones'));
const PantallaComputo = lazy(() => import('./computo/PantallaComputo'));
const PantallaNulidades = lazy(() => import('./nulidades/PantallaNulidades'));
const PantallaMultas = lazy(() => import('./multas/PantallaMultas'));
const MisMultas = lazy(() => import('./multas/MisMultas'));
const PantallaEscrutinio = lazy(() => import('./escrutinio/PantallaEscrutinio'));
const PantallaResultados = lazy(() => import('./resultados/PantallaResultados'));
const PantallaAdministrador = lazy(() => import('./administracion/PantallaAdministrador'));
import './administracion/administracion.css';
const PantallaBitacora = lazy(() => import('./bitacora/PantallaBitacora'));

// ─── Mapas de iconos por sección ─────────────────────────────────────────
const MENU_ICONS = {
  resumen: 'dashboard', procesos: 'calendar', docentes: 'users',
  candidaturas: 'list', tachas: 'shield', administracion: 'users',
  nuevo: 'plus', configuracion: 'settings', cuenta: 'user',
  mesa: 'shield', terminal: 'person', sorteos: 'list',
  bitacora: 'shield',
};

// ─── Menú por rol con categorías estilo CampaignHub ───────────────────────
const MENU_POR_ROL = {
  ADMIN: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'cuentas', label: 'Cuentas y roles', icon: 'users', color: '#ef4444' },
    { key: 'parametros', label: 'Parámetros del sistema', icon: 'settings', color: '#7c3aed' },
    { key: 'respaldo', label: 'Respaldo de la base', icon: 'download', color: '#0891b2' },
    { key: 'padron', label: 'Padrón e importación', icon: 'list', color: '#0ea5e9' },
    { key: 'cargos-excluidos', label: 'Excepciones Sorteo', icon: 'shield', color: '#f43f5e' },
    { key: 'bitacora', label: 'Bitácora', icon: 'eye', color: '#14b8a6' },
    { key: 'resultados', label: 'Resultados y actas', icon: 'trophy', color: '#059669' },
  ],
  CEUNP: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'convocatoria', label: 'Convocatoria y cronograma', icon: 'calendar', color: '#10b981' },
    { key: 'padron', label: 'Padrón electoral', icon: 'list', color: '#0ea5e9' },
    { key: 'docentes', label: 'Docentes', icon: 'users', color: '#8b5cf6' },
    { group: 'Operaciones' },
    { key: 'candidaturas', label: 'Inscripción de listas', icon: 'ballot', color: '#06b6d4' },
    { key: 'tachas', label: 'Tachas', icon: 'scale', color: '#f97316' },
    { key: 'sorteos', label: 'Sorteos', icon: 'sorteo', color: '#eab308' },
    { key: 'personeros', label: 'Personeros', icon: 'person', color: '#8b5cf6' },
    { key: 'credenciales', label: 'Credenciales y QR', icon: 'qr', color: '#10b981' },
    // M4: el CEUNP supervisa la jornada y puede cerrar el sufragio (CUS08, CUS11, CUS12)
    { group: 'Jornada electoral' },
    { key: 'instalacion', label: 'Instalación de mesas', icon: 'shield', color: '#0ea5e9' },
    { key: 'cierre', label: 'Cierre del sufragio', icon: 'lock', color: '#f43f5e' },
    { key: 'escrutinio', label: 'Escrutinio de mesas', icon: 'table', color: '#2563eb' },
    { group: 'Resultados' },
    { key: 'impugnaciones', label: 'Impugnaciones y apelaciones', icon: 'scale', color: '#ef4444' },
    { key: 'computo', label: 'Cómputo y proclamación', icon: 'trophy', color: '#6366f1' },
    { key: 'nulidades', label: 'Nulidades y segunda vuelta', icon: 'scale', color: '#e11d48' },
    { key: 'multas', label: 'Omisos y multas', icon: 'coins', color: '#f97316' },
    { key: 'resultados', label: 'Resultados y verificación de actas', icon: 'qr', color: '#059669' },
  ],
  MIEMBRO_MESA: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'listas', label: 'Listas postulantes', icon: 'ballot', color: '#06b6d4' },
    { key: 'pase', label: 'Mi pase de votación QR', icon: 'qr', color: '#8b5cf6' },
    { key: 'fotocheck', label: 'Mi fotocheck de miembro (RF56)', icon: 'qr', color: '#f59e0b' },
    { key: 'tachas', label: 'Presentar tacha', icon: 'scale', color: '#f97316' },
    { group: 'Jornada electoral' },
    { key: 'instalacion', label: 'Instalar mesa', icon: 'shield', color: '#0ea5e9' },
    { key: 'verificar-elector', label: 'Verificar elector', icon: 'scan', color: '#0ea5e9' },
    { key: 'terminal', label: 'Terminal de votación', icon: 'vote', color: '#6366f1' },
    { key: 'cierre', label: 'Cerrar sufragio', icon: 'lock', color: '#f43f5e' },
    { key: 'escrutinio', label: 'Realizar escrutinio', icon: 'table', color: '#2563eb' },
    // A1 · CUS13: la mesa decide sobre las impugnaciones de sus votos
    { key: 'impugnaciones', label: 'Impugnaciones de la mesa', icon: 'scale', color: '#ef4444' },
    { key: 'verificar-qr', label: 'Verificar credencial QR', icon: 'scan', color: '#10b981' },
    { group: 'Resultados' },
    { key: 'mis-multas', label: 'Mis multas', icon: 'coins', color: '#d97706' },
    { key: 'resultados', label: 'Resultados y actas', icon: 'trophy', color: '#059669' },
  ],
  PERSONERO: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'listas', label: 'Listas postulantes', icon: 'ballot', color: '#06b6d4' },
    { key: 'pase', label: 'Mi pase de votación QR', icon: 'qr', color: '#8b5cf6' },
    { key: 'credencial', label: 'Mi credencial de personero', icon: 'shield', color: '#10b981' },
    { key: 'tachas', label: 'Presentar tacha', icon: 'scale', color: '#f97316' },
    { key: 'impugnaciones', label: 'Impugnar votos y apelar', icon: 'scale', color: '#ef4444' },
    { key: 'mis-multas', label: 'Mis multas', icon: 'coins', color: '#d97706' },
    { key: 'resultados', label: 'Resultados y actas', icon: 'trophy', color: '#059669' },
  ],
  DOCENTE: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'listas', label: 'Listas postulantes', icon: 'ballot', color: '#06b6d4' },
    { key: 'pase', label: 'Mi pase de votación QR', icon: 'qr', color: '#8b5cf6' },
    { key: 'tachas', label: 'Presentar tacha', icon: 'scale', color: '#f97316' },
    { key: 'mis-multas', label: 'Mis multas', icon: 'coins', color: '#d97706' },
    { key: 'resultados', label: 'Resultados y actas', icon: 'trophy', color: '#059669' },
  ],
};

const SECTION_TITLES = {
  resumen: 'Resumen general',
  convocatoria: 'Convocatoria y cronograma',
  padron: 'Padrón electoral',
  docentes: 'Gestión de docentes',
  candidaturas: 'Inscripción de listas',
  tachas: 'Tachas electorales',
  personeros: 'Personeros y Acreditaciones',
  credenciales: 'Credenciales y códigos QR',
  computo: 'Computar y proclamar resultados',
  nulidades: 'Gestionar nulidades y segunda vuelta',
  impugnaciones: 'Impugnaciones y apelaciones',
  administracion: 'Administrar usuarios y parámetros',
  cuentas: 'Cuentas y roles',
  parametros: 'Parámetros del sistema',
  respaldo: 'Respaldo de la base de datos',
  cuenta: 'Configuración de mi cuenta',
  mesa: 'Mi Mesa de Sufragio',
  terminal: 'Terminal de votación ',
  sorteos: 'Sorteos: miembros de mesa y cédula',
  'cargos-excluidos': 'Excepciones de Sorteo',
  bitacora: 'Consultar bitácora ',
  multas: 'Reportar omisos y multas ',
  resultados: 'Consultar resultados y verificar actas',
  'mis-multas': 'Mis multas electorales',
  fotocheck: 'Mi fotocheck digital',
  'verificar-qr': 'Verificar credenciales QR',
  credencial: 'Mi credencial de personero',
  listas: 'Listas postulantes',
  pase: 'Mi pase de votación QR',
  instalacion: 'Instalación de mesa de sufragio',
  'verificar-elector': 'Verificar elector',
  cierre: 'Cerrar sufragio',
  escrutinio: 'Realizar escrutinio y conciliar ',
};

const SECTION_DESCRIPTIONS = {
  cuentas: 'Gestión y administración de cuentas de usuario, asignación de roles del sistema, restablecimiento de contraseñas y control de estados.',
  parametros: 'Configuración de parámetros globales del sistema, multas, UIT, plazos de votación y auditoría de cambios.',
  respaldo: 'Generación, descarga y verificación de integridad de copias de seguridad de la base de datos electoral.',
  'cargos-excluidos': 'Gestión de cargos excluidos del sorteo de miembros de mesa.',
  padron: 'Gestione el padrón electoral: aplique reglas de depuración y apruebe el padrón definitivo para el proceso electoral.',
  convocatoria: 'Registre el proceso electoral con su cronograma, configure los cargos a elegir y publique la convocatoria oficial.',
  docentes: 'Administración y mantenimiento del padrón de docentes: consulta de datos académicos, edición de facultades, departamentos y estados de habilitación.',
  listas: 'Consulte las listas y fórmulas inscritas en el proceso electoral, sus candidatos y plan de gobierno.',
};

// ─── Agrupa el menú plano en secciones desplegables ───────────────────────
function formatFechaAcceso(fecha) {
  if (!fecha) return 'Nunca';
  try {
    const d = new Date(fecha);
    if (isNaN(d.getTime())) return String(fecha);
    return new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }).format(d);
  } catch {
    return String(fecha);
  }
}

function agruparMenu(items) {
  const grupos = [];
  for (const item of items) {
    if (item.group) grupos.push({ nombre: item.group, items: [] });
    else if (grupos.length) grupos[grupos.length - 1].items.push(item);
    else grupos.push({ nombre: 'WORKSPACE', items: [item] });
  }
  return grupos;
}

const COLOR_ROL = {
  ADMIN: '#e11d48',
  CEUNP: '#2563eb',
  MIEMBRO_MESA: '#7c3aed',
  PERSONERO: '#d97706',
  DOCENTE: '#059669',
};

const ROL_LEGIBLE = {
  ADMIN: 'Administrador del sistema',
  CEUNP: 'Comité Electoral (CEUNP)',
  MIEMBRO_MESA: 'Miembro de mesa',
  PERSONERO: 'Personero',
  DOCENTE: 'Docente elector',
};

// Pantalla con la que abre cada rol al iniciar sesión
const SECCION_INICIAL_ROL = {
  CEUNP: 'candidaturas',
  MIEMBRO_MESA: 'resumen',
  DOCENTE: 'pase',
};
const seccionPorDefecto = (rol) => SECCION_INICIAL_ROL[rol] ?? 'resumen';

// Secciones que el rol puede abrir aunque no estén en su menú (accesos desde otras pantallas)
const SECCIONES_EXTRA_ROL = {
  ADMIN: ['administracion', 'instalacion', 'cierre', 'escrutinio', 'computo', 'nulidades', 'impugnaciones', 'multas', 'pase', 'verificar-qr'],
  CEUNP: ['terminal', 'verificar-elector', 'verificar-qr', 'pase'],
  MIEMBRO_MESA: [],
  PERSONERO: ['verificar-qr'],
  DOCENTE: [],
};

/** true si la sección existe para el rol: evita abrir (en blanco) una sección de otra cuenta */
function seccionPermitida(rol, seccion) {
  if (!seccion) return false;
  if (seccion === 'cuenta') return true;
  return (MENU_POR_ROL[rol] ?? []).some((i) => i.key === seccion)
    || (SECCIONES_EXTRA_ROL[rol] ?? []).includes(seccion);
}

const CLAVE_GRUPOS = 'siceunp.menu.cerrados';
function leerGruposCerrados() {
  try { return new Set(JSON.parse(localStorage.getItem(CLAVE_GRUPOS) ?? '[]')); }
  catch { return new Set(); }
}

/**
 * Layout principal de la aplicación.
 * Contiene el sidebar, el header y renderiza la página activa según la sección.
 *
 * @param {{ session: object, onLogout: function }} props
 */
export default function DashboardPage({ session, onLogout }) {
  // UX: cada sección tiene su URL (#/seccion), así el botón Atrás y los enlaces funcionan sin salir de la app
  const seccionInicial = () => {
    const desdeUrl = window.location.hash.replace(/^#\/?/, '');
    if (desdeUrl === 'mesa' && session.rol === 'MIEMBRO_MESA') {
      window.history.replaceState(null, '', '#/resumen');
      return 'resumen';
    }
    if (seccionPermitida(session.rol, desdeUrl)) return desdeUrl;
    const inicial = seccionPorDefecto(session.rol);
    // La URL traía una sección que este rol no tiene (p. ej. la de otra cuenta): se corrige sin dejar historial
    if (desdeUrl) window.history.replaceState(null, '', `#/${inicial}`);
    return inicial;
  };
  const [section, setSeccion] = useState(seccionInicial);
  const setSection = (nueva) => {
    if (nueva !== section) window.history.pushState(null, '', `#/${nueva}`);
    setSeccion(nueva);
  };
  useEffect(() => {
    const alVolver = () => setSeccion(seccionInicial());
    window.addEventListener('popstate', alVolver);
    return () => window.removeEventListener('popstate', alVolver);
  }, []);
  const [settingsOpen, setSettingsOpen] = useState(false);
  // Rediseño: menú lateral en móvil, grupos desplegables y menú de usuario
  const [navAbierta, setNavAbierta] = useState(false);
  const [gruposCerrados, setGruposCerrados] = useState(leerGruposCerrados);
  const [menuUsuario, setMenuUsuario] = useState(false);
  const menuUsuarioRef = useRef(null);
  // CUS08 · RF60: mesas no instaladas que esperan la evaluación de nulidad del CEUNP
  const [alertasInstalacion, setAlertasInstalacion] = useState(0);
  const [processes, setProcesses] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState(null);

  // Estado de métricas reales para el resumen del Admin
  const [adminStats, setAdminStats] = useState({ usuarios: null, parametros: null, bitacora: null });
  const [adminStatsLoading, setAdminStatsLoading] = useState(false);

  // Estado para el resumen personalizado del Docente elector
  const [docenteData, setDocenteData] = useState(null);
  const [docenteLoading, setDocenteLoading] = useState(false);

  useEffect(() => {
    if (session.rol !== 'CEUNP') return undefined;
    const revisar = () => apiRequest('/api/instalacion/alertas')
      .then((lista) => setAlertasInstalacion(lista.length))
      .catch(() => { });
    revisar();
    const timer = setInterval(revisar, 60000);
    return () => clearInterval(timer);
  }, [session.rol, section]);

  // Cierra el menú de usuario al hacer clic fuera o con Escape
  useEffect(() => {
    if (!menuUsuario) return undefined;
    const fuera = (e) => { if (!menuUsuarioRef.current?.contains(e.target)) setMenuUsuario(false); };
    const esc = (e) => { if (e.key === 'Escape') setMenuUsuario(false); };
    document.addEventListener('mousedown', fuera);
    document.addEventListener('keydown', esc);
    return () => { document.removeEventListener('mousedown', fuera); document.removeEventListener('keydown', esc); };
  }, [menuUsuario]);

  // En móvil, cerrar el menú lateral con Escape
  useEffect(() => {
    if (!navAbierta) return undefined;
    const esc = (e) => { if (e.key === 'Escape') setNavAbierta(false); };
    document.addEventListener('keydown', esc);
    return () => document.removeEventListener('keydown', esc);
  }, [navAbierta]);

  function irA(clave) {
    setSection(clave);
    setNavAbierta(false);
    setMenuUsuario(false);
  }

  function alternarGrupo(nombre) {
    setGruposCerrados((prev) => {
      const sig = new Set(prev);
      if (sig.has(nombre)) sig.delete(nombre); else sig.add(nombre);
      try { localStorage.setItem(CLAVE_GRUPOS, JSON.stringify([...sig])); } catch { /* sin almacenamiento */ }
      return sig;
    });
  }

  // Roles del sistema
  const canManage = session.rol === 'CEUNP';
  const isCeunp = session.rol === 'CEUNP';
  const isAdmin = session.rol === 'ADMIN';
  const isDocente = session.rol === 'DOCENTE';
  const isMiembro = session.rol === 'MIEMBRO_MESA';
  const isPersonero = session.rol === 'PERSONERO';

  // Datos de Miembro de Mesa
  const [miembroData, setMiembroData] = useState(null);
  const [miembroLoading, setMiembroLoading] = useState(false);

  // Datos de Personero
  const [personeroData, setPersoneroData] = useState(null);
  const [personeroLoading, setPersoneroLoading] = useState(false);

  // Estadísticas del CEUNP
  const [ceunpStats, setCeunpStats] = useState({ listas: 0, mesas: 0, solicitudesPendientes: 0 });

  async function loadData() {
    if (!canManage) { setLoading(false); return; }
    setLoading(true);
    try {
      const [processData, teacherData] = await Promise.all([
        apiRequest('/api/procesos'),
        apiRequest('/api/docentes'),
      ]);
      setProcesses(processData);
      setTeachers(teacherData);

      // Cargar estadísticas del proceso activo para el CEUNP
      const procActivo = processData[0];
      if (procActivo) {
        try {
          const [listas, mesas, solicitudes] = await Promise.all([
            apiRequest(`/api/inscripcion/procesos/${procActivo.id}/listas`).catch(() => []),
            apiRequest(`/api/instalacion/mesas?procesoId=${procActivo.id}`).catch(() => []),
            apiRequest(`/api/credenciales/procesos/${procActivo.id}/solicitudes`).catch(() => []),
          ]);
          setCeunpStats({
            listas: Array.isArray(listas) ? listas.length : (listas?.length ?? 0),
            mesas: Array.isArray(mesas) ? mesas.length : (mesas?.length ?? 0),
            solicitudesPendientes: (solicitudes || []).filter((s) => s.estado === 'PENDIENTE').length,
          });
        } catch {
          // Si fallan las métricas auxiliares se mantiene lo principal
        }
      }
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onLogout();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadData(); }, []);

  /** Carga los datos de la mesa asignada al Miembro de Mesa */
  async function loadMiembroData() {
    if (!isMiembro) return;
    setMiembroLoading(true);
    try {
      const [mesas, creds, pase] = await Promise.all([
        apiRequest('/api/instalacion/mesas').catch(() => []),
        apiRequest('/api/credenciales/mias').catch(() => []),
        apiRequest('/api/docente/mi-pase').catch(() => null),
      ]);
      setMiembroData({
        mesas: Array.isArray(mesas) ? mesas : [],
        credenciales: Array.isArray(creds) ? creds : [],
        pase,
      });
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onLogout();
    } finally {
      setMiembroLoading(false);
    }
  }

  useEffect(() => { loadMiembroData(); }, []);

  /** Carga los datos de acreditación de la lista para el Personero */
  async function loadPersoneroData() {
    if (!isPersonero) return;
    setPersoneroLoading(true);
    try {
      const [creds, listas, pase] = await Promise.all([
        apiRequest('/api/credenciales/mias').catch(() => []),
        apiRequest('/api/docente/listas-postulantes').catch(() => []),
        apiRequest('/api/docente/mi-pase').catch(() => null),
      ]);
      setPersoneroData({
        credenciales: Array.isArray(creds) ? creds : [],
        listas: Array.isArray(listas) ? listas : [],
        pase,
      });
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onLogout();
    } finally {
      setPersoneroLoading(false);
    }
  }

  useEffect(() => { loadPersoneroData(); }, []);

  /** Carga los datos del pase electoral del docente autenticado */
  async function loadDocenteData() {
    if (!isDocente) return;
    setDocenteLoading(true);
    try {
      const data = await apiRequest('/api/docente/mi-pase');
      setDocenteData(data);
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onLogout();
    } finally {
      setDocenteLoading(false);
    }
  }

  useEffect(() => { loadDocenteData(); }, []);

  /** Carga métricas completas del panel de administración */
  async function loadAdminStats() {
    if (!isAdmin) return;
    setAdminStatsLoading(true);
    try {
      const [adminData, auditPage] = await Promise.all([
        apiRequest('/api/administracion'),
        apiRequest('/api/auditoria?size=1&page=0'),
      ]);
      setAdminStats({
        detalle: adminData,
        bitacora: auditPage.totalElements ?? 0,
      });
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onLogout();
    } finally {
      setAdminStatsLoading(false);
    }
  }

  useEffect(() => { loadAdminStats(); }, []);

  const grupos = agruparMenu(MENU_POR_ROL[session.rol] ?? []);
  const grupoActual = grupos.find((g) => g.items.some((i) => i.key === section))?.nombre;

  return (
    <div className={`app-shell${navAbierta ? ' nav-abierta' : ''}`}>
      {/* ── Sidebar ──────────────────────────────────────────────── */}
      <aside className="sidebar" id="menu-lateral">
        <div className="sidebar-brand">
          <div className="brand-header-row">
            <div className="brand-logo-wrap">
              <img src="/escudo-unp.png" alt="Escudo UNP" className="brand-logo" />
            </div>
            <div className="brand-info">
              <h2 className="brand-title">SICEUNP</h2>
              <span className="brand-sub">Elecciones docentes · UNP</span>
            </div>
          </div>
        </div>

        <nav className="nav-list" aria-label="Navegación principal">
          {grupos.map((grupo) => {
            const fijo = grupo.nombre === 'WORKSPACE';
            const contieneActiva = grupo.items.some((i) => i.key === section);
            const abierto = fijo || contieneActiva || !gruposCerrados.has(grupo.nombre);
            const idGrupo = `grupo-${grupo.nombre.replace(/\s+/g, '-').toLowerCase()}`;
            return (
              <div key={grupo.nombre} className={`nav-group${abierto ? ' open' : ''}`}>
                {!fijo && (
                  <button
                    type="button"
                    className="nav-section-title"
                    aria-expanded={abierto}
                    aria-controls={idGrupo}
                    onClick={() => !contieneActiva && alternarGrupo(grupo.nombre)}
                  >
                    <span>{grupo.nombre}</span>
                    <MenuIcon name="chevron" size={14} className="nav-chevron" />
                  </button>
                )}
                <div className="nav-group-body" id={idGrupo}>
                  <div className="nav-group-inner">
                    {grupo.items.map((item) => (
                      <button
                        key={item.key}
                        type="button"
                        className={`nav-item${section === item.key ? ' active' : ''}`}
                        aria-current={section === item.key ? 'page' : undefined}
                        tabIndex={abierto ? 0 : -1}
                        onClick={() => irA(item.key)}
                        title={item.label}
                      >
                        <span className="nav-icon"><MenuIcon name={item.icon} size={18} /></span>
                        <span className="nav-label">{item.label}</span>
                        {item.key === 'instalacion' && alertasInstalacion > 0 && (
                          <span className="nav-alerta" title="Mesas no instaladas por evaluar (RF60)">{alertasInstalacion}</span>
                        )}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            );
          })}

          <div className="nav-group open">
            <div className="nav-section-title estatico">General</div>
            <button
              type="button"
              className={`nav-item${section === 'cuenta' ? ' active' : ''}`}
              aria-current={section === 'cuenta' ? 'page' : undefined}
              onClick={() => irA('cuenta')}
              title="Configuración de la cuenta"
            >
              <span className="nav-icon"><MenuIcon name="settings" size={18} /></span>
              <span className="nav-label">Configuración</span>
            </button>
          </div>
        </nav>

        <div className="sidebar-footer">
          <span className="sidebar-footer-rol">{ROL_LEGIBLE[session.rol] ?? session.rol}</span>
          <span className="sidebar-footer-org">Universidad Nacional de Piura</span>
        </div>
      </aside>
      <button
        type="button"
        className="nav-scrim"
        aria-label="Cerrar menú"
        tabIndex={navAbierta ? 0 : -1}
        onClick={() => setNavAbierta(false)}
      />

      {/* ── Contenido principal ───────────────────────────────────── */}
      <main className="content">
        {/* UX: cada pantalla se carga al abrirla (el paquete inicial deja de pesar 1,2 MB) */}
        <header className="topbar">
          <button
            type="button"
            className="nav-toggle"
            aria-label="Abrir menú"
            aria-controls="menu-lateral"
            aria-expanded={navAbierta}
            onClick={() => setNavAbierta(true)}
          >
            <MenuIcon name="menu" size={20} />
          </button>
          <div className="topbar-titulo" key={section}>
            {grupoActual && grupoActual !== 'WORKSPACE' && <span className="topbar-ruta">{grupoActual}</span>}
            <h1>
              {section === 'padron' && isAdmin
                ? 'Importación y creación de usuarios docentes'
                : (SECTION_TITLES[section] ?? 'SICEUNP')}
            </h1>
            {(section === 'padron' && isAdmin
              ? 'Importe el padrón de docentes para crear o actualizar masivamente sus cuentas de usuario en el sistema.'
              : SECTION_DESCRIPTIONS[section]) && (
              <p className="topbar-desc">
                {section === 'padron' && isAdmin
                  ? 'Importe el padrón de docentes para crear o actualizar masivamente sus cuentas de usuario en el sistema.'
                  : SECTION_DESCRIPTIONS[section]}
              </p>
            )}
          </div>

          <div className="user-menu" ref={menuUsuarioRef}>
            <button
              type="button"
              className="user-menu-trigger"
              aria-haspopup="menu"
              aria-expanded={menuUsuario}
              onClick={() => setMenuUsuario((v) => !v)}
            >
              <span className="account-avatar">{session.username.charAt(0).toUpperCase()}</span>
              <span className="user-menu-id">
                <strong>{session.username}</strong>
                <span>{ROL_LEGIBLE[session.rol] ?? session.rol}</span>
              </span>
              <MenuIcon name="chevron" size={16} className="user-menu-chevron" />
            </button>
            {menuUsuario && (
              <div className="user-menu-panel" role="menu">
                <div className="user-menu-head">
                  <strong>{session.username}</strong>
                  <span>{ROL_LEGIBLE[session.rol] ?? session.rol}</span>
                </div>
                <button type="button" role="menuitem" className="user-menu-item" onClick={() => irA('cuenta')}>
                  <MenuIcon name="settings" size={16} /> Configuración de la cuenta
                </button>
                {MENU_POR_ROL[session.rol]?.some((i) => i.key === 'resultados') && (
                  <button type="button" role="menuitem" className="user-menu-item" onClick={() => irA('resultados')}>
                    <MenuIcon name="trophy" size={16} /> Resultados y actas
                  </button>
                )}
                <div className="user-menu-sep" />
                <button type="button" role="menuitem" className="user-menu-item peligro" onClick={onLogout}>
                  <MenuIcon name="logout" size={16} /> Cerrar sesión
                </button>
              </div>
            )}
          </div>
        </header>

        <div className="vista" key={section}>
        {/* Si una pantalla falla, el error queda dentro del panel: menú y barra superior siguen disponibles */}
        <ErrorBoundary compacto onInicio={() => setSection(seccionPorDefecto(session.rol))}>
        <Suspense fallback={<div className="vista-cargando"><div className="spinner" aria-label="Cargando" /></div>}>
        {feedback && <div className={`alert ${feedback.type}`}>{feedback.text}</div>}

        {/* Resumen — varía según el rol */}
        {section === 'resumen' && isAdmin && (() => {
          const det = adminStats?.detalle;
          const res = det?.resumen ?? { total: 0, activos: 0, inactivos: 0, bloqueadas: 0, provisionales: 0, sinAcceso: 0, porRol: {} };
          const porRol = res.porRol ?? {};
          const pol = det?.politica ?? det?.politicaSeguridad ?? { intentosMaximos: 5, bloqueoMinutos: 15, passwordMin: 8 };
          const params = det?.parametros ?? [];
          const paramsCount = params.length || 18;
          const respaldos = det?.respaldos ?? [];
          const resp = respaldos[0];
          const usuarios = det?.usuarios ?? [];

          // Parámetros clave destacados para la supervisión ejecutiva
          const uitParam = params.find((p) => p.clave === 'UIT')?.valor ?? '5,150.00';
          const quorumParam = params.find((p) => p.clave === 'QUORUM_MINIMO_LEGAL_PCT')?.valor ?? '60';
          const multaVotoPct = params.find((p) => p.clave === 'MULTA_ELECTOR_OMISO_PCT')?.valor ?? '2.5';
          const multaMesaPct = params.find((p) => p.clave === 'MULTA_MIEMBRO_MESA_OMISO_PCT')?.valor ?? '3.0';
          const plazoApelacion = params.find((p) => p.clave === 'IMPUGNACION_PLAZO_APELACION_HORAS')?.valor ?? '24';
          const uitNum = parseFloat(String(uitParam).replace(/,/g, '')) || 5150;
          const montoMultaVoto = (uitNum * (parseFloat(multaVotoPct) || 2.5) / 100).toFixed(2);
          const montoMultaMesa = (uitNum * (parseFloat(multaMesaPct) || 3.0) / 100).toFixed(2);

          return (
            <div style={{ display: 'grid', gap: '20px' }}>
              {/* KPIs superiores */}
              <section className="cq-resumen" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
                <div className="cq-kpi" style={{ '--cq-color': '#2563eb', cursor: 'pointer' }} onClick={() => setSection('cuentas')} title="Ir a Cuentas y roles">
                  <span>Cuentas activas</span>
                  <strong>{adminStatsLoading ? '…' : res.activos}<small> / {res.total}</small></strong>
                  <small>{res.inactivos} inactiva(s) · {res.sinAcceso} sin ingresar aún</small>
                </div>
                <div className="cq-kpi" style={{ '--cq-color': res.bloqueadas ? '#e11d48' : '#059669', cursor: 'pointer' }} onClick={() => setSection('cuentas')} title="Ir a Cuentas y roles">
                  <span>Bloqueadas <em>{pol.intentosMaximos} intentos</em></span>
                  <strong>{adminStatsLoading ? '…' : res.bloqueadas}</strong>
                  <small>{res.provisionales} con contraseña provisional</small>
                </div>
                <div className="cq-kpi" style={{ '--cq-color': '#7c3aed', cursor: 'pointer' }} onClick={() => setSection('parametros')} title="Ir a Parámetros del sistema">
                  <span>Parámetros</span>
                  <strong>{adminStatsLoading ? '…' : paramsCount}</strong>
                  <small>{det?.historial?.length ? `${det.historial.length} cambios en historial` : 'Sin cambios registrados'}</small>
                </div>
                <div className="cq-kpi" style={{ '--cq-color': !resp ? '#d97706' : '#059669', cursor: 'pointer' }} onClick={() => setSection('respaldo')} title="Ir a Respaldo de la base">
                  <span>Último respaldo</span>
                  <strong className="cp-etapa">{adminStatsLoading ? '…' : (resp ? 'Respaldado' : 'Sin respaldo')}</strong>
                  <small>{resp ? resp.nombreArchivo : 'Genere uno antes de la jornada'}</small>
                </div>
              </section>

              {/* Panel de administración enriquecido con módulos y métricas */}
              <section className="panel" style={{ padding: '24px' }}>
                <div className="panel-heading" style={{ borderBottom: '1px solid var(--border, #e2e8f0)', paddingBottom: '16px', marginBottom: '22px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px' }}>
                  <div>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0, color: 'var(--text-main, #0f172a)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <MenuIcon name="dashboard" size={20} /> Panel de administración general
                    </h2>
                    <p className="muted" style={{ margin: '4px 0 0', fontSize: '.88rem' }}>
                      Gestión integral de usuarios, roles, parámetros del sistema, respaldos cifrados y auditoría de seguridad.
                    </p>
                  </div>
                  <button
                    className="cv-btn cv-btn-primary"
                    onClick={() => setSection('cuentas')}
                    style={{ display: 'inline-flex', alignItems: 'center', gap: '8px' }}
                  >
                    <MenuIcon name="users" size={16} /> Gestionar cuentas y roles
                  </button>
                </div>

                {/* 4 Módulos de administración rápida con tarjetas ejecutivas */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px', marginBottom: '24px' }}>
                  {/* Módulo 1: Cuentas y roles */}
                  <div
                    onClick={() => setSection('cuentas')}
                    style={{
                      border: '1px solid var(--border, #e2e8f0)',
                      borderTop: '4px solid #2563eb',
                      borderRadius: '12px',
                      padding: '18px',
                      background: 'var(--surface, #fff)',
                      cursor: 'pointer',
                      transition: 'all .2s ease',
                      display: 'flex',
                      flexDirection: 'column',
                      justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))',
                    }}
                    onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 6px 16px rgba(37,99,235,0.12)'; }}
                    onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))'; }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#dbeafe', color: '#2563eb', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="users" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 9px', borderRadius: '999px', background: '#eff6ff', color: '#2563eb' }}>
                          {res.total} cuentas
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main, #0f172a)' }}>Cuentas y roles</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted, #64748b)', margin: '0 0 14px', lineHeight: 1.45 }}>
                        Altas, asignación de roles (ADMIN, CEUNP, Mesas, Personeros), desbloqueo y restablecimiento de claves.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '12px', borderTop: '1px solid var(--border, #f1f5f9)', fontSize: '.82rem', fontWeight: 600, color: '#2563eb' }}>
                      <span>{res.activos} activas · {res.bloqueadas} bloqueadas</span>
                      <span>Ir a Cuentas →</span>
                    </div>
                  </div>

                  {/* Módulo 2: Parámetros del sistema */}
                  <div
                    onClick={() => setSection('parametros')}
                    style={{
                      border: '1px solid var(--border, #e2e8f0)',
                      borderTop: '4px solid #7c3aed',
                      borderRadius: '12px',
                      padding: '18px',
                      background: 'var(--surface, #fff)',
                      cursor: 'pointer',
                      transition: 'all .2s ease',
                      display: 'flex',
                      flexDirection: 'column',
                      justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))',
                    }}
                    onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 6px 16px rgba(124,58,237,0.12)'; }}
                    onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))'; }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#ede9fe', color: '#7c3aed', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="settings" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 9px', borderRadius: '999px', background: '#f5f3ff', color: '#7c3aed' }}>
                          {paramsCount} reglas
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main, #0f172a)' }}>Parámetros del sistema</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted, #64748b)', margin: '0 0 14px', lineHeight: 1.45 }}>
                        UIT anual, multas de sufragio y mesa (CUS16), quórum legal del 60% (RN31) y plazos del proceso.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '12px', borderTop: '1px solid var(--border, #f1f5f9)', fontSize: '.82rem', fontWeight: 600, color: '#7c3aed' }}>
                      <span>UIT S/ {uitParam} · RN31 {quorumParam}%</span>
                      <span>Configurar →</span>
                    </div>
                  </div>

                  {/* Módulo 3: Respaldo de la base */}
                  <div
                    onClick={() => setSection('respaldo')}
                    style={{
                      border: '1px solid var(--border, #e2e8f0)',
                      borderTop: '4px solid #0891b2',
                      borderRadius: '12px',
                      padding: '18px',
                      background: 'var(--surface, #fff)',
                      cursor: 'pointer',
                      transition: 'all .2s ease',
                      display: 'flex',
                      flexDirection: 'column',
                      justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))',
                    }}
                    onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 6px 16px rgba(8,145,178,0.12)'; }}
                    onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))'; }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#cffafe', color: '#0891b2', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="download" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 9px', borderRadius: '999px', background: '#ecfeff', color: '#0891b2' }}>
                          {respaldos.length} copia(s)
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main, #0f172a)' }}>Respaldo de la base</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted, #64748b)', margin: '0 0 14px', lineHeight: 1.45 }}>
                        Copias de seguridad completas cifradas en AES-256-GCM y verificación de huella de integridad SHA-256.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '12px', borderTop: '1px solid var(--border, #f1f5f9)', fontSize: '.82rem', fontWeight: 600, color: '#0891b2' }}>
                      <span>{resp ? 'Respaldo verificado' : 'Generar copia'}</span>
                      <span>Respaldar →</span>
                    </div>
                  </div>

                  {/* Módulo 4: Bitácora y auditoría */}
                  <div
                    onClick={() => setSection('bitacora')}
                    style={{
                      border: '1px solid var(--border, #e2e8f0)',
                      borderTop: '4px solid #14b8a6',
                      borderRadius: '12px',
                      padding: '18px',
                      background: 'var(--surface, #fff)',
                      cursor: 'pointer',
                      transition: 'all .2s ease',
                      display: 'flex',
                      flexDirection: 'column',
                      justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))',
                    }}
                    onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 6px 16px rgba(20,184,166,0.12)'; }}
                    onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = 'var(--shadow-xs, 0 1px 3px rgba(0,0,0,0.04))'; }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#ccfbf1', color: '#14b8a6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="eye" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 9px', borderRadius: '999px', background: '#f0fdfa', color: '#14b8a6' }}>
                          {adminStats.bitacora ?? 0} logs
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main, #0f172a)' }}>Bitácora de auditoría</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted, #64748b)', margin: '0 0 14px', lineHeight: 1.45 }}>
                        Trazabilidad inmutable CUS19 de accesos, intentos fallidos, cambios en datos maestros y firmas de actas.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '12px', borderTop: '1px solid var(--border, #f1f5f9)', fontSize: '.82rem', fontWeight: 600, color: '#14b8a6' }}>
                      <span>Registro inmutable</span>
                      <span>Consultar →</span>
                    </div>
                  </div>
                </div>

                {/* Desglose de usuarios por rol */}
                <div style={{ marginBottom: '24px', background: 'var(--surface-alt, #f8fafc)', padding: '16px 20px', borderRadius: '12px', border: '1px solid var(--border, #e2e8f0)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                    <span style={{ fontSize: '.84rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.04em', color: 'var(--text-muted, #64748b)' }}>
                      Distribución de cuentas por rol en el sistema
                    </span>
                    <button className="text-button" onClick={() => setSection('cuentas')} style={{ fontSize: '.82rem' }}>
                      Administrar roles →
                    </button>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: '10px' }}>
                    {[
                      { rol: 'ADMIN', label: 'Administrador', color: '#e11d48' },
                      { rol: 'CEUNP', label: 'Comité Electoral', color: '#2563eb' },
                      { rol: 'MIEMBRO_MESA', label: 'Miembro de Mesa', color: '#7c3aed' },
                      { rol: 'PERSONERO', label: 'Personero', color: '#d97706' },
                      { rol: 'DOCENTE', label: 'Docente Elector', color: '#059669' },
                    ].map((item) => (
                      <div
                        key={item.rol}
                        onClick={() => setSection('cuentas')}
                        style={{
                          background: '#fff',
                          border: '1px solid var(--border, #e2e8f0)',
                          borderLeft: `4px solid ${item.color}`,
                          borderRadius: '8px',
                          padding: '10px 14px',
                          cursor: 'pointer',
                          display: 'flex',
                          flexDirection: 'column',
                          gap: '2px',
                          transition: 'transform .15s ease',
                        }}
                        onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-1px)'; }}
                        onMouseLeave={(e) => { e.currentTarget.style.transform = 'none'; }}
                      >
                        <span style={{ fontSize: '.72rem', fontWeight: 650, color: 'var(--text-muted, #64748b)' }}>{item.label}</span>
                        <strong style={{ fontSize: '1.25rem', color: 'var(--text-main, #0f172a)' }}>
                          {porRol[item.rol] ?? 0}
                        </strong>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Dos columnas operativas: Cuentas supervisadas & Parámetros y seguridad */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '20px', marginBottom: '20px' }}>
                  {/* Columna Izquierda: Cuentas supervisadas */}
                  <div style={{ border: '1px solid var(--border, #e2e8f0)', borderRadius: '12px', padding: '18px', background: '#fff' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
                      <h3 style={{ fontSize: '.95rem', fontWeight: 700, margin: 0, color: 'var(--text-main, #0f172a)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <MenuIcon name="users" size={16} /> Cuentas registradas ({usuarios.length})
                      </h3>
                      <button className="text-button" onClick={() => setSection('cuentas')} style={{ fontSize: '.82rem' }}>
                        Ver todas
                      </button>
                    </div>

                    {usuarios.length === 0 ? (
                      <p style={{ fontSize: '.85rem', color: 'var(--text-muted, #64748b)', padding: '16px 0', textAlign: 'center' }}>
                        No hay usuarios registrados aún.
                      </p>
                    ) : (
                      <div className="table-wrap" style={{ margin: 0 }}>
                        <table style={{ fontSize: '.82rem' }}>
                          <thead>
                            <tr>
                              <th>Usuario</th>
                              <th>Rol</th>
                              <th>Estado</th>
                              <th>Último acceso</th>
                            </tr>
                          </thead>
                          <tbody>
                            {usuarios.slice(0, 5).map((u) => {
                              const rolColor = COLOR_ROL[u.rol] || '#64748b';
                              return (
                                <tr key={u.idUsuario || u.username}>
                                  <td>
                                    <strong>{u.username}</strong>
                                    {u.docente && (
                                      <div style={{ fontSize: '.75rem', color: 'var(--text-muted, #64748b)' }}>{u.docente}</div>
                                    )}
                                  </td>
                                  <td>
                                    <span style={{
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: '4px',
                                      padding: '2px 8px',
                                      borderRadius: '999px',
                                      fontSize: '.72rem',
                                      fontWeight: 650,
                                      color: rolColor,
                                      background: `${rolColor}15`,
                                    }}>
                                      <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: rolColor }} />
                                      {u.rol}
                                    </span>
                                  </td>
                                  <td>
                                    {u.bloqueada ? (
                                      <span style={{ color: '#e11d48', fontWeight: 600 }}>Bloqueada</span>
                                    ) : u.debeCambiarPassword ? (
                                      <span style={{ color: '#d97706', fontWeight: 600 }}>Provisional</span>
                                    ) : u.activo ? (
                                      <span style={{ color: '#059669', fontWeight: 600 }}>Activa</span>
                                    ) : (
                                      <span style={{ color: '#94a3b8' }}>Inactiva</span>
                                    )}
                                  </td>
                                  <td style={{ color: 'var(--text-muted, #64748b)' }}>
                                    {formatFechaAcceso(u.ultimoAcceso)}
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </div>

                  {/* Columna Derecha: Parámetros del sistema y seguridad */}
                  <div style={{ border: '1px solid var(--border, #e2e8f0)', borderRadius: '12px', padding: '18px', background: '#fff' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
                      <h3 style={{ fontSize: '.95rem', fontWeight: 700, margin: 0, color: 'var(--text-main, #0f172a)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <MenuIcon name="shield" size={16} /> Parámetros y reglas vigentes
                      </h3>
                      <button className="text-button" onClick={() => setSection('parametros')} style={{ fontSize: '.82rem' }}>
                        Modificar reglas
                      </button>
                    </div>

                    <div style={{ display: 'grid', gap: '8px' }}>
                      {[
                        { label: 'Unidad Impositiva Tributaria (UIT)', val: `S/ ${uitParam}`, nota: 'Base de cálculo legal anual' },
                        { label: 'Quórum mínimo legal (RN31)', val: `${quorumParam}%`, nota: 'Participación requerida del padrón' },
                        { label: 'Multa omisión sufragio (RN35)', val: `${multaVotoPct}% (S/ ${montoMultaVoto})`, nota: 'CUS16 reportar multas' },
                        { label: 'Multa inasistencia mesa (RN35)', val: `${multaMesaPct}% (S/ ${montoMultaMesa})`, nota: 'Presidente, secretario o vocal' },
                        { label: 'Plazo para apelar al CEUNP (RF81)', val: `${plazoApelacion} horas`, nota: 'CUS13 impugnaciones' },
                        { label: 'Intentos fallidos antes de bloqueo', val: `${pol.intentosMaximos} intentos`, nota: 'Seguridad de acceso' },
                        { label: 'Duración de bloqueo temporal', val: `${pol.bloqueoMinutos || 15} minutos`, nota: 'Levantamiento automático' },
                      ].map((item, idx) => (
                        <div key={idx} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 10px', borderRadius: '6px', background: idx % 2 === 0 ? 'var(--surface-alt, #f8fafc)' : 'transparent', fontSize: '.82rem' }}>
                          <div>
                            <span style={{ fontWeight: 600, color: 'var(--text-main, #0f172a)' }}>{item.label}</span>
                            <div style={{ fontSize: '.72rem', color: 'var(--text-muted, #64748b)' }}>{item.nota}</div>
                          </div>
                          <span style={{ fontWeight: 700, color: '#0f172a', fontVariantNumeric: 'tabular-nums' }}>{item.val}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Accesos directos complementarios en el pie del panel */}
                <div style={{ borderTop: '1px solid var(--border, #e2e8f0)', paddingTop: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px' }}>
                  <span style={{ fontSize: '.84rem', color: 'var(--text-muted, #64748b)' }}>
                    Otras herramientas de administración del sistema:
                  </span>
                  <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <button
                      className="cv-btn cv-btn-ghost"
                      onClick={() => setSection('padron')}
                      style={{ fontSize: '.82rem', padding: '6px 12px', display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <MenuIcon name="list" size={14} /> Padrón e importación
                    </button>
                    <button
                      className="cv-btn cv-btn-ghost"
                      onClick={() => setSection('cargos-excluidos')}
                      style={{ fontSize: '.82rem', padding: '6px 12px', display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <MenuIcon name="shield" size={14} /> Excepciones Sorteo
                    </button>
                    <button
                      className="cv-btn cv-btn-ghost"
                      onClick={() => setSection('resultados')}
                      style={{ fontSize: '.82rem', padding: '6px 12px', display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <MenuIcon name="trophy" size={14} /> Resultados y actas
                    </button>
                  </div>
                </div>
              </section>
            </div>
          );
        })()}

        {/* Resumen — Docente elector (panel personalizado con su estado electoral) */}
        {section === 'resumen' && isDocente && (() => {
          // Helpers de estado del proceso
          const ESTADO_PROCESO_LABEL = {
            CONVOCATORIA: 'Convocatoria',
            INSCRIPCION: 'Inscripción',
            TACHAS: 'Tachas',
            CAMPANA: 'Campaña',
            VOTACION: 'Votación',
            ESCRUTINIO: 'Escrutinio',
            COMPUTO: 'Cómputo',
            CERRADO: 'Cerrado',
          };
          const ESTADO_PROCESO_COLOR = {
            VOTACION: '#059669',
            CERRADO: '#6b7280',
            ESCRUTINIO: '#2563eb',
            COMPUTO: '#2563eb',
          };
          const colorEstado = (e) => ESTADO_PROCESO_COLOR[e] ?? '#d97706';

          if (docenteLoading) {
            return (
              <section className="panel" style={{ textAlign: 'center', padding: '3rem' }}>
                <span className="muted">Cargando tu información electoral…</span>
              </section>
            );
          }

          if (!docenteData) {
            return (
              <section className="panel" style={{ textAlign: 'center', padding: '3rem' }}>
                <p style={{ marginBottom: '1rem', color: '#6b7280' }}>No se pudo cargar tu información. Intenta de nuevo.</p>
                <button className="primary-button" onClick={loadDocenteData}>Reintentar</button>
              </section>
            );
          }

          const procesos = docenteData.procesos ?? [];
          const habilitado = docenteData.habilitadoParaVotar === 1 || docenteData.habilitadoParaVotar === true;
          const procesosActivos = procesos.filter((p) => p.estadoProceso === 'VOTACION').length;
          const conCredencial = procesos.filter((p) => p.tieneCredencialVigente).length;

          return (
            <>
              {/* KPIs */}
              <section className="stats-grid">
                {/* Habilitación para votar */}
                <article className="stat-card">
                  <div className="stat-card-icon" style={{ background: habilitado ? '#d1fae5' : '#fee2e2', color: habilitado ? '#059669' : '#e11d48' }}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      {habilitado
                        ? <><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></>
                        : <><circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></>}
                    </svg>
                  </div>
                  <div className="stat-card-body">
                    <span className="stat-card-label">Habilitación para votar</span>
                    <strong className="stat-card-value" style={{ color: habilitado ? '#059669' : '#e11d48', fontSize: '1.1rem' }}>
                      {habilitado ? 'Habilitado' : 'No habilitado'}
                    </strong>
                    <span className="stat-card-sub" style={{ color: habilitado ? '#6b7280' : '#e11d48' }}>
                      {habilitado ? 'Puedes participar en las elecciones' : (docenteData.motivoInhabilitacion ?? 'Consulta con el CEUNP')}
                    </span>
                  </div>
                </article>

                {/* Procesos en que figura */}
                <article className="stat-card">
                  <div className="stat-card-icon blue">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
                    </svg>
                  </div>
                  <div className="stat-card-body">
                    <span className="stat-card-label">Procesos electorales</span>
                    <strong className="stat-card-value">{procesos.length}</strong>
                    <span className="stat-card-sub">en que figuras como elector</span>
                  </div>
                </article>

                {/* Proceso en votación ahora */}
                <article className="stat-card">
                  <div className="stat-card-icon amber">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                    </svg>
                  </div>
                  <div className="stat-card-body">
                    <span className="stat-card-label">En votación activa</span>
                    <strong className="stat-card-value">{procesosActivos}</strong>
                    <span className="stat-card-sub">proceso{procesosActivos !== 1 ? 's' : ''} en curso ahora</span>
                  </div>
                </article>

                {/* Credencial QR vigente */}
                <article className="stat-card">
                  <div className="stat-card-icon green">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
                      <line x1="14" y1="14" x2="14" y2="14" /><line x1="17" y1="14" x2="20" y2="14" /><line x1="14" y1="17" x2="14" y2="20" /><line x1="17" y1="20" x2="20" y2="20" />
                    </svg>
                  </div>
                  <div className="stat-card-body">
                    <span className="stat-card-label">Credencial QR vigente</span>
                    <strong className="stat-card-value">{conCredencial}</strong>
                    <span className="stat-card-sub">pase{conCredencial !== 1 ? 's' : ''} activo{conCredencial !== 1 ? 's' : ''}</span>
                  </div>
                </article>
              </section>

              {/* Datos personales del docente */}
              <section className="panel" style={{ marginBottom: '1rem' }}>
                <div className="panel-heading">
                  <div>
                    <h2>Mis datos en el padrón</h2>
                    <p className="muted">Información registrada en el sistema electoral.</p>
                  </div>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '0.75rem', padding: '0.25rem 0' }}>
                  {[
                    { label: 'Nombre completo', value: `${docenteData.nombres ?? ''} ${docenteData.apellidos ?? ''}`.trim() || '—' },
                    { label: 'DNI', value: docenteData.dni ?? '—' },
                    { label: 'Facultad', value: docenteData.facultad ?? '—' },
                    { label: 'Departamento', value: docenteData.departamento ?? '—' },
                    { label: 'Categoría', value: docenteData.categoria ?? '—' },
                    { label: 'Dedicación', value: docenteData.dedicacion ?? '—' },
                  ].map(({ label, value }) => (
                    <div key={label} style={{ background: '#f9fafb', borderRadius: '8px', padding: '0.75rem 1rem', border: '1px solid #e5e7eb' }}>
                      <span style={{ display: 'block', fontSize: '0.7rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#6b7280', marginBottom: '0.25rem' }}>{label}</span>
                      <span style={{ fontWeight: 500, color: '#111827' }}>{value}</span>
                    </div>
                  ))}
                </div>
              </section>

              {/* Lista de procesos en que figura */}
              <section className="panel">
                <div className="panel-heading">
                  <div>
                    <h2>Mis procesos electorales</h2>
                    <p className="muted">Procesos en los que figuras como elector habilitado.</p>
                  </div>
                  <button className="text-button" onClick={() => setSection('pase')}>Ver mi pase QR</button>
                </div>

                {procesos.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '2.5rem 1rem', color: '#6b7280' }}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" style={{ width: 40, height: 40, margin: '0 auto 0.75rem', display: 'block', opacity: 0.4 }}>
                      <rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
                    </svg>
                    <p style={{ marginBottom: '0.5rem', fontWeight: 500 }}>Todavía no figuras en ningún padrón electoral.</p>
                    <p style={{ fontSize: '0.875rem' }}>Cuando el CEUNP publique un proceso y te incluya, aparecerá aquí.</p>
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                    {procesos.map((p) => (
                      <div key={p.idProceso} style={{ display: 'flex', alignItems: 'flex-start', gap: '1rem', background: '#f9fafb', borderRadius: '10px', padding: '1rem 1.25rem', border: '1px solid #e5e7eb' }}>
                        {/* Info del proceso */}
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', flexWrap: 'wrap', marginBottom: '0.4rem' }}>
                            <span style={{ fontWeight: 600, color: '#111827' }}>{p.proceso ?? `Proceso #${p.idProceso}`}</span>
                            <span style={{
                              fontSize: '0.72rem', fontWeight: 700, padding: '0.15rem 0.6rem', borderRadius: '999px',
                              background: `${colorEstado(p.estadoProceso)}18`, color: colorEstado(p.estadoProceso), letterSpacing: '0.03em',
                            }}>
                              {ESTADO_PROCESO_LABEL[p.estadoProceso] ?? p.estadoProceso}
                            </span>
                            {p.esMiembroMesa && (
                              <span style={{ fontSize: '0.72rem', fontWeight: 700, padding: '0.15rem 0.6rem', borderRadius: '999px', background: '#ede9fe', color: '#7c3aed' }}>
                                Miembro de mesa
                              </span>
                            )}
                          </div>
                          <div style={{ fontSize: '0.85rem', color: '#6b7280', display: 'flex', flexWrap: 'wrap', gap: '1.2rem' }}>
                            {p.numeroMesa && (
                              <span>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ width: 13, height: 13, marginRight: 4, verticalAlign: 'middle' }}><rect x="3" y="3" width="18" height="18" rx="2" /></svg>
                                Mesa {p.numeroMesa}
                                {p.localVotacion ? ` · ${p.localVotacion}` : ''}
                              </span>
                            )}
                            {p.fechaInicio && (
                              <span>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ width: 13, height: 13, marginRight: 4, verticalAlign: 'middle' }}><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="3" y1="10" x2="21" y2="10" /></svg>
                                {new Date(p.fechaInicio).toLocaleDateString('es-PE', { day: '2-digit', month: 'short', year: 'numeric' })}
                              </span>
                            )}
                          </div>
                        </div>
                        {/* Credencial */}
                        <div style={{ textAlign: 'right', flexShrink: 0 }}>
                          {p.tieneCredencialVigente ? (
                            <button className="text-button" style={{ fontSize: '0.82rem' }} onClick={() => setSection('pase')}>
                              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ width: 14, height: 14, marginRight: 4, verticalAlign: 'middle' }}>
                                <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
                              </svg>
                              Ver QR
                            </button>
                          ) : (
                            <span style={{ fontSize: '0.78rem', color: '#9ca3af' }}>Sin credencial</span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </section>
            </>
          );
        })()}

        {/* Resumen — CEUNP (Panel de Control Electoral Ejecutivo) */}
        {section === 'resumen' && isCeunp && (() => {
          const procActivo = processes[0];
          const habilitados = teachers.filter((t) => t.habilitadoParaVotar).length;
          const totalDocentes = teachers.length;
          const enVotacion = processes.filter((p) => p.estado === 'VOTACION').length;

          return (
            <div style={{ display: 'grid', gap: '20px' }}>
              {/* KPIs superiores */}
              <section className="cq-resumen" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', gap: '16px' }}>
                <div className="cq-kpi" style={{ '--cq-color': '#2563eb', cursor: 'pointer' }} onClick={() => setSection('padron')} title="Ir a Padrón Electoral">
                  <span>Padrón definitivo</span>
                  <strong>{loading ? '…' : habilitados}<small> / {totalDocentes} docentes</small></strong>
                  <small>{totalDocentes - habilitados} inhabilitados o en depuración</small>
                </div>
                <div className="cq-kpi" style={{ '--cq-color': '#10b981', cursor: 'pointer' }} onClick={() => setSection('convocatoria')} title="Ir a Convocatoria">
                  <span>Proceso electoral</span>
                  <strong style={{ fontSize: '1.05rem', textTransform: 'capitalize' }}>
                    {loading ? '…' : (procActivo?.estado ?? 'Sin proceso')}
                  </strong>
                  <small>{procActivo ? procActivo.nombre : 'Configure la convocatoria'}</small>
                </div>
                <div className="cq-kpi" style={{ '--cq-color': '#06b6d4', cursor: 'pointer' }} onClick={() => setSection('candidaturas')} title="Ir a Inscripción de Listas">
                  <span>Listas y fórmulas</span>
                  <strong>{ceunpStats.listas}</strong>
                  <small>Fórmulas inscritas en carrera</small>
                </div>
                <div className="cq-kpi" style={{ '--cq-color': '#7c3aed', cursor: 'pointer' }} onClick={() => setSection('instalacion')} title="Ir a Instalación de Mesas">
                  <span>Mesas de sufragio</span>
                  <strong>{ceunpStats.mesas}</strong>
                  <small>Mesas conformadas (6 miembros c/u)</small>
                </div>
                <div className="cq-kpi" style={{ '--cq-color': ceunpStats.solicitudesPendientes > 0 ? '#ef4444' : '#059669', cursor: 'pointer' }} onClick={() => setSection('credenciales')} title="Ir a Credenciales">
                  <span>Solicitudes de nuevo QR</span>
                  <strong>{ceunpStats.solicitudesPendientes}</strong>
                  <small>{ceunpStats.solicitudesPendientes > 0 ? 'Requieren atención del CEUNP' : 'Todas las solicitudes atendidas'}</small>
                </div>
              </section>

              {/* Panel de administración rápida con módulos operativos */}
              <section className="panel" style={{ padding: '24px' }}>
                <div className="panel-heading" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '16px', marginBottom: '22px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px' }}>
                  <div>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0, color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <MenuIcon name="dashboard" size={20} /> Panel de Control Electoral del CEUNP
                    </h2>
                    <p className="muted" style={{ margin: '4px 0 0', fontSize: '.88rem' }}>
                      Supervisión integral de las etapas electorales, padrón, candidaturas, mesas y escrutinio oficial.
                    </p>
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button className="cv-btn cv-btn-primary" onClick={() => setSection('convocatoria')} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                      <MenuIcon name="calendar" size={15} /> Convocatoria
                    </button>
                    <button className="cv-btn cv-btn-ghost" onClick={() => setSection('instalacion')} style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                      <MenuIcon name="shield" size={15} /> Supervisar mesas
                    </button>
                  </div>
                </div>

                {/* 4 Módulos ejecutivos por etapas */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px', marginBottom: '24px' }}>
                  {/* Módulo 1: Padrón y Sorteos */}
                  <div
                    onClick={() => setSection('sorteos')}
                    style={{
                      border: '1px solid var(--border)', borderTop: '4px solid #10b981',
                      borderRadius: '12px', padding: '18px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs)',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                        <div style={{ width: '38px', height: '38px', borderRadius: '10px', background: '#d1fae5', color: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="sorteo" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 8px', borderRadius: '999px', background: '#ecfdf5', color: '#059669' }}>
                          Sorteos RN19/RN18
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main)' }}>Sorteos y Cédula</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.45 }}>
                        Sorteo de miembros de mesa (titulares y suplentes) y sorteo de ubicación en la cédula de votación.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '10px', borderTop: '1px solid var(--border)', fontSize: '.82rem', fontWeight: 600, color: '#10b981' }}>
                      <span>Ir a Sorteos →</span>
                    </div>
                  </div>

                  {/* Módulo 2: Inscripción de Listas y Tachas */}
                  <div
                    onClick={() => setSection('candidaturas')}
                    style={{
                      border: '1px solid var(--border)', borderTop: '4px solid #06b6d4',
                      borderRadius: '12px', padding: '18px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs)',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                        <div style={{ width: '38px', height: '38px', borderRadius: '10px', background: '#cffafe', color: '#0891b2', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="ballot" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 8px', borderRadius: '999px', background: '#ecfeff', color: '#0891b2' }}>
                          {ceunpStats.listas} listas
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main)' }}>Candidaturas y Tachas</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.45 }}>
                        Revisión de fórmulas de Rector y Vicerrectores, resolución de tachas y acreditación de personeros.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '10px', borderTop: '1px solid var(--border)', fontSize: '.82rem', fontWeight: 600, color: '#0891b2' }}>
                      <span>Gestionar listas →</span>
                    </div>
                  </div>

                  {/* Módulo 3: Jornada e Instalación */}
                  <div
                    onClick={() => setSection('instalacion')}
                    style={{
                      border: '1px solid var(--border)', borderTop: '4px solid #0ea5e9',
                      borderRadius: '12px', padding: '18px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs)',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                        <div style={{ width: '38px', height: '38px', borderRadius: '10px', background: '#e0f2fe', color: '#0ea5e9', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="shield" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 8px', borderRadius: '999px', background: '#f0f9ff', color: '#0284c7' }}>
                          {ceunpStats.mesas} mesas
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main)' }}>Jornada Electoral</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.45 }}>
                        Supervisión de apertura de mesas, verificación de miembros, cierre a las 15:00 h y contingencias.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '10px', borderTop: '1px solid var(--border)', fontSize: '.82rem', fontWeight: 600, color: '#0ea5e9' }}>
                      <span>Supervisar jornada →</span>
                    </div>
                  </div>

                  {/* Módulo 4: Cómputo y Resultados */}
                  <div
                    onClick={() => setSection('computo')}
                    style={{
                      border: '1px solid var(--border)', borderTop: '4px solid #6366f1',
                      borderRadius: '12px', padding: '18px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                      boxShadow: 'var(--shadow-xs)',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                        <div style={{ width: '38px', height: '38px', borderRadius: '10px', background: '#e0e7ff', color: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <MenuIcon name="trophy" size={20} />
                        </div>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 8px', borderRadius: '999px', background: '#eef2ff', color: '#4f46e5' }}>
                          Cómputo oficial
                        </span>
                      </div>
                      <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 6px', color: 'var(--text-main)' }}>Cómputo y Proclamación</h3>
                      <p style={{ fontSize: '.84rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.45 }}>
                        Consolidación de actas escrutadas, quórum legal (60%), resolución de impugnaciones y proclamación de ganadores.
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '10px', borderTop: '1px solid var(--border)', fontSize: '.82rem', fontWeight: 600, color: '#6366f1' }}>
                      <span>Ir a Cómputo →</span>
                    </div>
                  </div>
                </div>

                {/* Tabla de procesos electorales */}
                <div style={{ borderTop: '1px solid var(--border)', paddingTop: '16px' }}>
                  <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 12px', color: 'var(--text-main)' }}>Procesos Electorales Registrados</h3>
                  <ProcessTable processes={processes.slice(0, 5)} loading={loading} />
                </div>
              </section>
            </div>
          );
        })()}

        {/* Resumen — MIEMBRO DE MESA (Dashboard personalizado de Mesa) */}
        {section === 'resumen' && isMiembro && (() => {
          if (miembroLoading) {
            return (
              <section className="panel" style={{ textAlign: 'center', padding: '3rem' }}>
                <span className="muted">Cargando la información de su mesa de sufragio…</span>
              </section>
            );
          }

          const mesas = miembroData?.mesas ?? [];
          const mesa = mesas[0];
          const pase = miembroData?.pase;
          const creds = miembroData?.credenciales ?? [];
          const miFotocheck = creds.flatMap((p) => p.credenciales || []).find((c) => c.tipo === 'MIEMBRO_MESA');

          return (
            <div style={{ display: 'grid', gap: '20px' }}>
              {/* Tarjeta de Identidad y Rol del Miembro de Mesa */}
              <section className="panel" style={{ padding: '24px', background: 'linear-gradient(135deg, rgba(124,58,237,0.06), rgba(99,102,241,0.03))', border: '1.5px solid rgba(124,58,237,0.25)', borderRadius: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px', marginBottom: '16px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{ width: '56px', height: '56px', borderRadius: '14px', background: 'linear-gradient(135deg, #7c3aed, #6366f1)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <MenuIcon name="shield" size={28} />
                    </div>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                        <h2 style={{ fontSize: '1.3rem', fontWeight: 800, margin: 0, color: 'var(--text-main)' }}>
                          {session.username} · {pase?.nombreCompleto || 'Miembro de Mesa'}
                        </h2>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 10px', borderRadius: '999px', background: '#ede9fe', color: '#7c3aed', textTransform: 'uppercase' }}>
                          {mesa?.rol || 'Miembro Titular'}
                        </span>
                      </div>
                      <p style={{ margin: '4px 0 0', fontSize: '.88rem', color: 'var(--text-muted)' }}>
                        DNI: <strong>{pase?.dni ?? '—'}</strong> · {pase?.facultad ?? 'Universidad Nacional de Piura'}
                      </p>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      className="cv-btn cv-btn-primary"
                      onClick={() => setSection('fotocheck')}
                      style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <MenuIcon name="qr" size={15} /> Mi Fotocheck QR
                    </button>
                    <button
                      className="cv-btn cv-btn-ghost"
                      onClick={() => setSection('pase')}
                      style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <MenuIcon name="vote" size={15} /> Mi Pase de Votación
                    </button>
                  </div>
                </div>

                {/* Datos de la mesa asignada */}
                {mesa ? (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px', padding: '14px', borderRadius: '10px', background: '#fff', border: '1px solid var(--border)' }}>
                    <div>
                      <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>MESA ASIGNADA</span>
                      <p style={{ fontSize: '1.1rem', fontWeight: 700, margin: '2px 0 0', color: '#7c3aed' }}>Mesa Nº {mesa.numero || '001'}</p>
                    </div>
                    <div>
                      <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>UBICACIÓN / LOCAL</span>
                      <p style={{ fontSize: '.95rem', fontWeight: 600, margin: '2px 0 0', color: 'var(--text-main)' }}>📍 {mesa.ubicacion || 'Biblioteca Central'}</p>
                    </div>
                    <div>
                      <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>TOTAL ELECTORES</span>
                      <p style={{ fontSize: '1.1rem', fontWeight: 700, margin: '2px 0 0', color: '#2563eb' }}>{mesa.total_electores || mesa.totalElectores || '85'} docentes</p>
                    </div>
                    <div>
                      <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>ESTADO DE LA MESA</span>
                      <p style={{ margin: '4px 0 0' }}>
                        <span className={`cv-estado ${mesa.estado === 'INSTALADA' ? 'votacion' : mesa.estado === 'CERRADA' ? 'inscripcion' : 'creado'}`}>
                          {mesa.estado || 'PENDIENTE'}
                        </span>
                      </p>
                    </div>
                  </div>
                ) : (
                  <div style={{ padding: '12px', background: '#fef3c7', borderRadius: '8px', color: '#92400e', fontSize: '.88rem' }}>
                    No se encontró mesa asignada directamente a esta cuenta. Consulte al CEUNP.
                  </div>
                )}
              </section>

              {/* Guía Operativa de la Jornada Electoral con accesos directos */}
              <section className="panel" style={{ padding: '24px' }}>
                <div className="panel-heading" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '14px', marginBottom: '18px' }}>
                  <div>
                    <h3 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--text-main)' }}>
                      Flujo Operativo de la Jornada de Sufragio
                    </h3>
                    <p className="muted" style={{ margin: '3px 0 0', fontSize: '.84rem' }}>
                      Acciones requeridas para los miembros de mesa durante la jornada electoral oficial (08:00 a 15:00 horas).
                    </p>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
                  {/* Paso 1: Instalación de mesa */}
                  <div
                    onClick={() => setSection('instalacion')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #0ea5e9',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                        <span style={{ width: '26px', height: '26px', borderRadius: '50%', background: '#e0f2fe', color: '#0284c7', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.82rem', fontWeight: 700 }}>1</span>
                        <h4 style={{ margin: 0, fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>Instalar Mesa (CUS08)</h4>
                      </div>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.4 }}>
                        Llegada de miembros (min. 3 presentes), acreditación de personeros, verificación de material y firma del acta.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#0ea5e9' }}>Ir a Instalación →</span>
                  </div>

                  {/* Paso 2: Verificar Elector */}
                  <div
                    onClick={() => setSection('verificar-elector')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #10b981',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                        <span style={{ width: '26px', height: '26px', borderRadius: '50%', background: '#d1fae5', color: '#059669', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.82rem', fontWeight: 700 }}>2</span>
                        <h4 style={{ margin: 0, fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>Verificar Elector (CUS09)</h4>
                      </div>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.4 }}>
                        Escanear el código QR del docente o buscar por DNI para comprobar habilitación en el padrón y dar paso al sufragio.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#10b981' }}>Verificar electores →</span>
                  </div>

                  {/* Paso 3: Cerrar Sufragio */}
                  <div
                    onClick={() => setSection('cierre')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #f43f5e',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                        <span style={{ width: '26px', height: '26px', borderRadius: '50%', background: '#ffe4e6', color: '#e11d48', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.82rem', fontWeight: 700 }}>3</span>
                        <h4 style={{ margin: 0, fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>Cerrar Sufragio (CUS11)</h4>
                      </div>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.4 }}>
                        A las 15:00 horas, cerrar la recepción de votantes, marcar docentes ausentes y generar acta de sufragio oficial.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#f43f5e' }}>Cerrar sufragio →</span>
                  </div>

                  {/* Paso 4: Escrutinio y Conciliación */}
                  <div
                    onClick={() => setSection('escrutinio')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #2563eb',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                        <span style={{ width: '26px', height: '26px', borderRadius: '50%', background: '#dbeafe', color: '#2563eb', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '.82rem', fontWeight: 700 }}>4</span>
                        <h4 style={{ margin: 0, fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>Escrutinio (CUS12)</h4>
                      </div>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: '0 0 12px', lineHeight: 1.4 }}>
                        Conteo de votos, conciliación de cédulas, resolución de impugnaciones de mesa y generación del acta escrutada.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#2563eb' }}>Realizar escrutinio →</span>
                  </div>
                </div>
              </section>
            </div>
          );
        })()}

        {/* Resumen — PERSONERO (Dashboard de Fiscalización) */}
        {section === 'resumen' && isPersonero && (() => {
          if (personeroLoading) {
            return (
              <section className="panel" style={{ textAlign: 'center', padding: '3rem' }}>
                <span className="muted">Cargando datos de acreditación de personero…</span>
              </section>
            );
          }

          const creds = personeroData?.credenciales ?? [];
          const listas = personeroData?.listas ?? [];
          const pase = personeroData?.pase;
          const miCredencial = creds.flatMap((p) => p.credenciales || []).find((c) => c.tipo === 'PERSONERO');

          return (
            <div style={{ display: 'grid', gap: '20px' }}>
              {/* Tarjeta de Acreditación de Personero */}
              <section className="panel" style={{ padding: '24px', background: 'linear-gradient(135deg, rgba(217,119,6,0.06), rgba(245,158,11,0.03))', border: '1.5px solid rgba(217,119,6,0.25)', borderRadius: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px', marginBottom: '16px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{ width: '56px', height: '56px', borderRadius: '14px', background: 'linear-gradient(135deg, #d97706, #f59e0b)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <MenuIcon name="scale" size={28} />
                    </div>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                        <h2 style={{ fontSize: '1.3rem', fontWeight: 800, margin: 0, color: 'var(--text-main)' }}>
                          {session.username} · {pase?.nombreCompleto || 'Personero Acreditado'}
                        </h2>
                        <span style={{ fontSize: '.75rem', fontWeight: 700, padding: '3px 10px', borderRadius: '999px', background: '#fef3c7', color: '#b45309', textTransform: 'uppercase' }}>
                          {miCredencial ? miCredencial.funcion : 'Personero Oficial'}
                        </span>
                      </div>
                      <p style={{ margin: '4px 0 0', fontSize: '.88rem', color: 'var(--text-muted)' }}>
                        DNI: <strong>{pase?.dni ?? '—'}</strong> · {pase?.facultad ?? 'Universidad Nacional de Piura'}
                      </p>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      className="cv-btn cv-btn-primary"
                      onClick={() => setSection('credencial')}
                      style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <MenuIcon name="qr" size={15} /> Mi Credencial QR
                    </button>
                    <button
                      className="cv-btn cv-btn-ghost"
                      onClick={() => setSection('pase')}
                      style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <MenuIcon name="vote" size={15} /> Mi Pase de Votación
                    </button>
                  </div>
                </div>

                {/* Datos de la Lista que representa */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px', padding: '14px', borderRadius: '10px', background: '#fff', border: '1px solid var(--border)' }}>
                  <div>
                    <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>LISTA QUE REPRESENTA</span>
                    <p style={{ fontSize: '1rem', fontWeight: 700, margin: '2px 0 0', color: '#d97706' }}>
                      {miCredencial?.lista || 'Lista Electoral Acreditada'}
                    </p>
                  </div>
                  <div>
                    <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>ÁMBITO DE FISCALIZACIÓN</span>
                    <p style={{ fontSize: '.95rem', fontWeight: 600, margin: '2px 0 0', color: 'var(--text-main)' }}>
                      📍 {miCredencial?.ubicacion || (miCredencial?.numeroMesa ? `Mesa Nº ${miCredencial.numeroMesa}` : 'Todas las mesas')}
                    </p>
                  </div>
                  <div>
                    <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>CREDENCIAL OFICIAL</span>
                    <p style={{ margin: '4px 0 0' }}>
                      <span className={`cv-estado ${miCredencial?.credencial ? 'votacion' : 'creado'}`}>
                        {miCredencial?.credencial ? 'ACREDITADO' : 'PENDIENTE'}
                      </span>
                    </p>
                  </div>
                  <div>
                    <span style={{ fontSize: '.76rem', color: 'var(--text-muted)', fontWeight: 600 }}>DERECHO AL VOTO</span>
                    <p style={{ fontSize: '.95rem', fontWeight: 600, margin: '2px 0 0', color: '#059669' }}>
                      ✓ Docente Habilitado
                    </p>
                  </div>
                </div>
              </section>

              {/* Acciones de fiscalización */}
              <section className="panel" style={{ padding: '24px' }}>
                <div className="panel-heading" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '14px', marginBottom: '18px' }}>
                  <div>
                    <h3 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0, color: 'var(--text-main)' }}>
                      Herramientas de Fiscalización Electoral
                    </h3>
                    <p className="muted" style={{ margin: '3px 0 0', fontSize: '.84rem' }}>
                      Acceso rápido a las opciones de supervisión, impugnación y consulta de resultados.
                    </p>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
                  <div
                    onClick={() => setSection('listas')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #06b6d4',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <h4 style={{ margin: '0 0 6px', fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>
                        Listas y Fórmulas
                      </h4>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.4 }}>
                        Consultar las candidaturas admitidas, candidatos de las fórmulas y planes de gobierno.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#0891b2', marginTop: 12 }}>Ver listas →</span>
                  </div>

                  <div
                    onClick={() => setSection('tachas')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #f97316',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <h4 style={{ margin: '0 0 6px', fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>
                        Presentar Tachas
                      </h4>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.4 }}>
                        Formular tachas fundamentadas contra candidatos que incumplan los requisitos de ley.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#ea580c', marginTop: 12 }}>Presentar tacha →</span>
                  </div>

                  <div
                    onClick={() => setSection('impugnaciones')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #ef4444',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <h4 style={{ margin: '0 0 6px', fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>
                        Impugnar Votos / Apelar
                      </h4>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.4 }}>
                        Impugnar votos durante el escrutinio de mesa y formular apelaciones ante el CEUNP.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#dc2626', marginTop: 12 }}>Ver impugnaciones →</span>
                  </div>

                  <div
                    onClick={() => setSection('resultados')}
                    style={{
                      border: '1.5px solid var(--border)', borderTop: '4px solid #059669',
                      borderRadius: '12px', padding: '16px', background: 'var(--surface, #fff)',
                      cursor: 'pointer', transition: 'all .2s ease', display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <h4 style={{ margin: '0 0 6px', fontSize: '.95rem', fontWeight: 700, color: 'var(--text-main)' }}>
                        Resultados y Actas
                      </h4>
                      <p style={{ fontSize: '.82rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.4 }}>
                        Auditar las actas de escrutinio firmadas y verificar los cómputos preliminares y oficiales.
                      </p>
                    </div>
                    <span style={{ fontSize: '.82rem', fontWeight: 600, color: '#059669', marginTop: 12 }}>Ver resultados →</span>
                  </div>
                </div>
              </section>
            </div>
          );
        })()}

        {/* CUS01 · Gestionar convocatoria y cronograma (CEUNP) */}
        {section === 'convocatoria' && canManage && (
          <ConvocatoriaPage onChange={loadData} onSessionExpired={onLogout} />
        )}

        {/* CUS02 · Gestionar padrón electoral (CEUNP) */}
        {section === 'padron' && (canManage || isAdmin) && (
          <PadronPage session={session} onChange={loadData} onSessionExpired={onLogout} />
        )}

        {/* Docentes — CRUD completo (solo CEUNP) */}
        {section === 'docentes' && canManage && (
          <DocentesPage
            teachers={teachers}
            loading={loading}
            onRefresh={loadData}
            canManage={canManage}
            onGestionarPadron={() => setSection('padron')}
            onSessionExpired={onLogout}
          />
        )}

        {/* Importar Docentes (solo CEUNP) */}
        

        {/* CUS03 · Gestionar inscripción de listas (CEUNP) */}
        {section === 'candidaturas' && canManage && (
          <InscripcionPage onSessionExpired={onLogout} />
        )}

        {/* Tachas */}
        {/* CUS04 · Gestionar tachas (docente elector presenta, CEUNP resuelve) */}
        {section === 'tachas' && (
          <TachasGestionPage session={session} onSessionExpired={onLogout} />
        )}

        {/* Sorteos */}
        {/* CUS06 · Realizar sorteos (CEUNP) */}
        {section === 'sorteos' && canManage && <SorteoMesaPage onSessionExpired={onLogout} />}

        {/* CUS18 · Cuentas y roles (Admin) */}
        {section === 'cuentas' && isAdmin && (
          <PantallaAdministrador session={session} onSessionExpired={onLogout} seccionInicial="USUARIOS" ocultarTabs />
        )}

        {/* CUS18 · Parámetros del sistema (Admin) */}
        {section === 'parametros' && isAdmin && (
          <PantallaAdministrador session={session} onSessionExpired={onLogout} seccionInicial="PARAMETROS" ocultarTabs />
        )}

        {/* CUS18 · Respaldo de la base (Admin) */}
        {section === 'respaldo' && isAdmin && (
          <PantallaAdministrador session={session} onSessionExpired={onLogout} seccionInicial="RESPALDO" ocultarTabs />
        )}

        {/* CUS18 · Administrar usuarios y parámetros (Admin) — acceso directo legacy */}
        {section === 'administracion' && isAdmin && (
          <PantallaAdministrador session={session} onSessionExpired={onLogout} />
        )}

        {/* Cuenta */}
        {section === 'cuenta' && (
          <CuentaPage
            session={session}
            menu={MENU_POR_ROL[session.rol] ?? []}
            rolLegible={ROL_LEGIBLE[session.rol] ?? session.rol}
            onIrA={irA}
            onLogout={onLogout}
            onSessionExpired={onLogout}
          />
        )}

        {/* Cargos excluidos (Exclusivo Administrador) */}
        {section === 'cargos-excluidos' && isAdmin && (
          <CargosExcluidosPage canManage={isAdmin} onSessionExpired={onLogout} />
        )}

        {/* CUS19 · Consultar bitácora (Admin) */}
        {section === 'bitacora' && isAdmin && (
          <PantallaBitacora session={session} onSessionExpired={onLogout} />
        )}

        {/* CUS08 · Instalar mesa (miembros de mesa y CEUNP; ADMIN solo consulta) */}
        {section === 'instalacion' && ['MIEMBRO_MESA', 'CEUNP', 'ADMIN'].includes(session.rol) && (
          <InstalacionMesaPage session={session} onSessionExpired={onLogout} />
        )}

        {/* CUS10 · Registrar voto en el terminal de la cabina (el docente no inicia sesión) */}
        {section === 'terminal' && (session.rol === 'MIEMBRO_MESA' || canManage) && <TerminalVotacion onSessionExpired={onLogout} />}

        {/* CUS11 · Cerrar sufragio (Presidente de mesa; el CEUNP supervisa y el ADMIN consulta) */}
        {section === 'cierre' && ['MIEMBRO_MESA', 'CEUNP', 'ADMIN'].includes(session.rol) && (
          <PantallaCierreSufragio session={session} onSessionExpired={onLogout} onIrEscrutinio={() => setSection('escrutinio')} />
        )}

        {/* CUS12 · Realizar escrutinio y conciliar (Presidente y secretario de mesa; el CEUNP supervisa y el ADMIN consulta) */}
        {section === 'escrutinio' && ['MIEMBRO_MESA', 'CEUNP', 'ADMIN'].includes(session.rol) && (
          <PantallaEscrutinio session={session} onSessionExpired={onLogout} onIrImpugnaciones={() => setSection('impugnaciones')} />
        )}

        {/* CUS09 · Verificar elector con QR (Secretario de mesa; CEUNP supervisa) */}
        {section === 'verificar-elector' && (session.rol === 'MIEMBRO_MESA' || canManage) && (
          <PantallaVerificacion onSessionExpired={onLogout} />
        )}

        {/* Módulos de CEUNP */}
        {/* CUS05 · Acreditar personeros (CEUNP) */}
        {section === 'personeros' && canManage && (
          <PersonerosPage onSessionExpired={onLogout} />
        )}

        {/* CUS07 · Emitir credenciales y QR (CEUNP) */}
        {section === 'credenciales' && canManage && (
          <CredencialesPage onSessionExpired={onLogout} />
        )}

        {/* CUS14 · Computar y proclamar resultados (verificación previa, sesión, cómputo, proclamación y publicación) */}
        {section === 'computo' && ['CEUNP', 'ADMIN'].includes(session.rol) && (
          <PantallaComputo session={session} onSessionExpired={onLogout} />
        )}

        {/* CUS15 · Gestionar nulidades y segunda vuelta (nulidad parcial y total, resolución del Pleno, comunicación, sorteo y segunda vuelta) */}
        {section === 'nulidades' && ['CEUNP', 'ADMIN'].includes(session.rol) && (
          <PantallaNulidades session={session} onSessionExpired={onLogout} />
        )}

        {/* CUS13 · Gestionar impugnaciones y apelaciones (personero de mesa impugna, el CEUNP falla) */}
        {section === 'impugnaciones' && ['PERSONERO', 'MIEMBRO_MESA', 'CEUNP', 'ADMIN'].includes(session.rol) && (
          <PantallaImpugnaciones session={session} onSessionExpired={onLogout} />
        )}

        {/* CUS16 · Reportar omisos y multas (el CEUNP genera, determina y resuelve descargos; el docente consulta) */}
        {section === 'multas' && ['CEUNP', 'ADMIN'].includes(session.rol) && (
          <PantallaMultas session={session} onSessionExpired={onLogout} />
        )}
        {section === 'mis-multas' && ['DOCENTE', 'PERSONERO', 'MIEMBRO_MESA'].includes(session.rol) && <MisMultas onSessionExpired={onLogout} />}
        {/* CUS17 · Consultar resultados y verificar actas (docente y personero; también mesa, CEUNP y ADMIN) */}
        {section === 'resultados' && <PantallaResultados session={session} onSessionExpired={onLogout} />}
        {/* CUS07 · Credenciales propias (QR generado en el navegador, sin servicios externos) */}
        {section === 'fotocheck' && <MisCredencialesPage foco="MIEMBRO_MESA" onSessionExpired={onLogout} />}
        {section === 'credencial' && <MisCredencialesPage foco="PERSONERO" onSessionExpired={onLogout} />}
        {/* CUS-DOCENTE — Consultar listas postulantes */}
        {section === 'listas' && ['DOCENTE', 'PERSONERO', 'MIEMBRO_MESA'].includes(session.rol) && (
          <ListasDocentePage onSessionExpired={onLogout} />
        )}
        {section === 'pase' && ['DOCENTE', 'PERSONERO', 'MIEMBRO_MESA'].includes(session.rol) && (
          <MiPaseQRPage onSessionExpired={onLogout} />
        )}
        {section === 'pase' && !['DOCENTE', 'PERSONERO', 'MIEMBRO_MESA'].includes(session.rol) && <MisCredencialesPage foco="ELECTOR" onSessionExpired={onLogout} />}
        {section === 'verificar-qr' && <VerificarCredencialPanel onSessionExpired={onLogout} />}

        </Suspense>
        </ErrorBoundary>
        </div>
      </main>
    </div>
  );
}
