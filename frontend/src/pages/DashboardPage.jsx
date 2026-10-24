import { useEffect, useState } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';
import ProcessTable from '../components/ProcessTable';
import DocentesPage from './DocentesPage';
import UsuariosPage from './UsuariosPage';
import CuentaPage from './CuentaPage';
import MiembroMesaPage from './MiembroMesaPage';
import PantallaVerificacion from './votacion/PantallaVerificacion';
import TerminalVotacion from './votacion/TerminalVotacion';
import ImportarDocentesPage from './ImportarDocentesPage';
import ParametrosPage from './ParametrosPage';
import BitacoraPage from './BitacoraPage';
import CargosExcluidosPage from './CargosExcluidosPage';
import ConvocatoriaPage from './convocatoria/ConvocatoriaPage';
import PadronPage from './padron/PadronPage';
import InscripcionPage from './inscripcion/InscripcionPage';
import TachasGestionPage from './tachas/TachasGestionPage';
import PersonerosPage from './personeros/PersonerosPage';
import SorteoMesaPage from './sorteo/SorteoMesaPage';
import CredencialesPage from './credenciales/CredencialesPage';
import MisCredencialesPage from './credenciales/MisCredencialesPage';
import VerificarCredencialPanel from './credenciales/VerificarCredencialPanel';
import MiPaseQRPage from './MiPaseQRPage';
import InstalacionMesaPage from './instalacion/InstalacionMesaPage';
import PantallaCierreSufragio from './cierre/PantallaCierreSufragio';
import PantallaEscrutinio from './escrutinio/PantallaEscrutinio';

// ─── Mapas de iconos por sección ─────────────────────────────────────────
const MENU_ICONS = {
  resumen: 'dashboard', procesos: 'calendar', docentes: 'users',
  candidaturas: 'list', tachas: 'shield', usuarios: 'user',
  nuevo: 'plus', configuracion: 'settings', cuenta: 'user',
  mesa: 'shield', terminal: 'person', sorteos: 'list',
  parametros: 'settings', bitacora: 'shield',
};

// ─── Menú por rol con categorías estilo CampaignHub ───────────────────────
const MENU_POR_ROL = {
  ADMIN: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'usuarios', label: 'Usuarios', icon: 'users', color: '#ef4444' },
    { key: 'parametros', label: 'Parámetros', icon: 'settings', color: '#6366f1' },
    { key: 'cargos-excluidos', label: 'Excepciones Sorteo', icon: 'shield', color: '#f43f5e' },
    { key: 'bitacora', label: 'Bitácora', icon: 'eye', color: '#14b8a6' },
  ],
  CEUNP: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'convocatoria', label: 'Convocatoria y cronograma', icon: 'calendar', color: '#10b981' },
    { key: 'padron', label: 'Padrón electoral', icon: 'list', color: '#0ea5e9' },
    { key: 'docentes', label: 'Docentes', icon: 'users', color: '#8b5cf6' },
    { group: 'OPERACIONES' },
    { key: 'candidaturas', label: 'Inscripción de listas', icon: 'ballot', color: '#06b6d4' },
    { key: 'tachas', label: 'Tachas', icon: 'scale', color: '#f97316' },
    { key: 'cargos-excluidos', label: 'Excepciones Sorteo', icon: 'shield', color: '#f43f5e' },
    { key: 'personeros', label: 'Personeros', icon: 'person', color: '#8b5cf6' },
    { key: 'credenciales', label: 'Credenciales y QR', icon: 'qr', color: '#10b981' },
    { key: 'sorteos', label: 'Sorteos', icon: 'sorteo', color: '#eab308' },
    { group: 'JORNADA ELECTORAL' },
    { key: 'instalacion', label: 'Instalación de mesas', icon: 'shield', color: '#14b8a6' },
    { key: 'verificar-elector', label: 'Verificación de electores', icon: 'scan', color: '#14b8a6' },
    { key: 'cierre', label: 'Cierre del sufragio', icon: 'lock', color: '#f43f5e' },
    { key: 'escrutinio', label: 'Escrutinio y conciliación', icon: 'table', color: '#2563eb' },
    { group: 'RESULTADOS' },
    { key: 'computo', label: 'Cómputo y Proclamación', icon: 'trophy', color: '#6366f1' },
    { key: 'impugnaciones', label: 'Impugnaciones y Nulidades', icon: 'alert', color: '#ef4444' },
    { key: 'multas', label: 'Gestión Multas', icon: 'coins', color: '#f97316' },
  ],
  MIEMBRO_MESA: [
    { group: 'WORKSPACE' },
    { key: 'instalacion', label: 'Instalar mesa', icon: 'shield', color: '#0ea5e9' },
    { key: 'mesa', label: 'Mi Mesa de Sufragio', icon: 'table', color: '#14b8a6' },
    { key: 'verificar-elector', label: 'Verificar elector', icon: 'scan', color: '#0ea5e9' },
    { key: 'terminal', label: 'Terminal de votación', icon: 'vote', color: '#6366f1' },
    { key: 'cierre', label: 'Cerrar sufragio', icon: 'lock', color: '#f43f5e' },
    { key: 'escrutinio', label: 'Realizar escrutinio', icon: 'table', color: '#2563eb' },
    { key: 'fotocheck', label: 'Fotocheck QR (RF56)', icon: 'qr', color: '#f59e0b' },
    { key: 'verificar-qr', label: 'Verificar credencial QR', icon: 'scan', color: '#10b981' },
  ],
  PERSONERO: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'credencial', label: 'Credencial QR (RF51)', icon: 'qr', color: '#10b981' },
    { key: 'tachas', label: 'Tachas e Impugnaciones', icon: 'scale', color: '#f97316' },
  ],
  DOCENTE: [
    { group: 'WORKSPACE' },
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6' },
    { key: 'pase', label: 'Mi pase de votación QR', icon: 'qr', color: '#8b5cf6' },
    { key: 'tachas', label: 'Presentar tacha', icon: 'scale', color: '#f97316' },
  ],
};

const SECTION_TITLES = {
  resumen: 'Resumen general',
  convocatoria: 'Convocatoria y cronograma',
  padron: 'Padrón electoral',
  docentes: 'Docentes',
  candidaturas: 'Inscripción de listas',
  tachas: 'Tachas electorales',
  personeros: 'Personeros y Acreditaciones',
  credenciales: 'Credenciales y códigos QR',
  computo: 'Cómputo General y Proclamación de Resultados',
  impugnaciones: 'Resolución de Impugnaciones y Nulidades',
  usuarios: 'Usuarios del sistema',
  cuenta: 'Configuración de mi cuenta',
  mesa: 'Mi Mesa de Sufragio',
  terminal: 'Terminal de votación (CUS10)',
  sorteos: 'Sorteos: miembros de mesa y cédula',
  'importar-docentes': 'Importar Padrón de Docentes',
  parametros: 'Parámetros globales',
  'cargos-excluidos': 'Excepciones de Sorteo (RN20)',
  bitacora: 'Bitácora de auditoría',
  multas: 'Gestión de Multas',
  fotocheck: 'Mi fotocheck digital',
  'verificar-qr': 'Verificar credenciales QR',
  credencial: 'Mi credencial de personero',
  pase: 'Mi pase de votación QR',
  instalacion: 'Instalación de mesa de sufragio',
  'verificar-elector': 'Verificar elector (CUS09)',
  cierre: 'Cerrar sufragio (CUS11)',
  escrutinio: 'Realizar escrutinio y conciliar (CUS12)',
};

/**
 * Layout principal de la aplicación.
 * Contiene el sidebar, el header y renderiza la página activa según la sección.
 *
 * @param {{ session: object, onLogout: function }} props
 */
export default function DashboardPage({ session, onLogout }) {
  const [section, setSection] = useState(() => {
    if (session.rol === 'CEUNP') return 'candidaturas';
    if (session.rol === 'MIEMBRO_MESA') return 'mesa';
    if (session.rol === 'DOCENTE') return 'pase';
    return 'resumen';
  });
  const [settingsOpen, setSettingsOpen] = useState(false);
  // CUS08 · RF60: mesas no instaladas que esperan la evaluación de nulidad del CEUNP
  const [alertasInstalacion, setAlertasInstalacion] = useState(0);
  const [processes, setProcesses] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState(null);

  // Estado de métricas reales para el resumen del Admin
  const [adminStats, setAdminStats] = useState({ usuarios: null, parametros: null, bitacora: null });
  const [adminStatsLoading, setAdminStatsLoading] = useState(false);

  useEffect(() => {
    if (session.rol !== 'CEUNP') return undefined;
    const revisar = () => apiRequest('/api/instalacion/alertas')
      .then((lista) => setAlertasInstalacion(lista.length))
      .catch(() => {});
    revisar();
    const timer = setInterval(revisar, 60000);
    return () => clearInterval(timer);
  }, [session.rol, section]);

  // CEUNP gestiona el proceso electoral; ADMIN gestiona el sistema
  const canManage = session.rol === 'CEUNP';
  const isAdmin = session.rol === 'ADMIN';

  async function loadData() {
    // Solo CEUNP necesita la lista de procesos y docentes
    if (!canManage) { setLoading(false); return; }
    setLoading(true);
    try {
      const [processData, teacherData] = await Promise.all([
        apiRequest('/api/procesos'),
        apiRequest('/api/docentes'),
      ]);
      setProcesses(processData);
      setTeachers(teacherData);
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onLogout();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadData(); }, []);

  /** Carga métricas reales del panel de administración */
  async function loadAdminStats() {
    if (!isAdmin) return;
    setAdminStatsLoading(true);
    try {
      const [users, params, auditPage] = await Promise.all([
        apiRequest('/api/auth/users'),
        apiRequest('/api/parametros'),
        apiRequest('/api/auditoria?size=1&page=0'),
      ]);
      setAdminStats({
        usuarios: users.length,
        parametros: params.length,
        bitacora: auditPage.totalElements ?? 0,
      });
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onLogout();
      // No mostramos feedback de error en el resumen, los valores quedan en null
    } finally {
      setAdminStatsLoading(false);
    }
  }

  useEffect(() => { loadAdminStats(); }, []);

  return (
    <div className="app-shell">
      {/* ── Sidebar ──────────────────────────────────────────────── */}
      <aside className="sidebar">
        {/* ── Logo + cabecera estilo CampaignHub ── */}
        <div className="sidebar-brand">
          <div className="brand-header-row">
            <div className="brand-logo-wrap">
              <img
                src="/escudo-unp.png"
                alt="Escudo UNP"
                style={{ width: 26, height: 26, objectFit: 'contain', display: 'block' }}
              />
            </div>
            <div className="brand-info">
              <h2 className="brand-title">SICEUNP</h2>
              <span className="brand-badge">{session.rol}</span>
            </div>
          </div>
        </div>

        <nav className="nav-list" aria-label="Navegación principal">
          {/* ── Menú principal según rol con grupos ── */}
          {(MENU_POR_ROL[session.rol] ?? []).map((item, idx) => {
            if (item.group) {
              // Ocultamos la etiqueta del primer grupo (WORKSPACE)
              if (item.group === 'WORKSPACE') return null;
              return (
                <div key={`group-${idx}`} className="nav-section-title">
                  {item.group}
                </div>
              );
            }
            return (
              <button
                key={item.key}
                className={`nav-item${section === item.key ? ' active' : ''}`}
                onClick={() => setSection(item.key)}
                title={item.label}
              >
                <span className="nav-icon" style={{ color: item.color }}>
                  <MenuIcon name={item.icon} size={19} />
                </span>
                <span className="nav-label">{item.label}</span>
                {item.key === 'instalacion' && alertasInstalacion > 0 && (
                  <span className="nav-alerta" title="Mesas no instaladas por evaluar (RF60)">{alertasInstalacion}</span>
                )}
              </button>
            );
          })}

          {/* ── Sección GENERAL estilo CampaignHub ── */}
          <div className="nav-section-title">GENERAL</div>
          <button
            className={`nav-item${section === 'cuenta' ? ' active' : ''}`}
            onClick={() => setSection('cuenta')}
            title="Configuración de la cuenta"
          >
            <span className="nav-icon" style={{ color: '#6366f1' }}>
              <MenuIcon name="settings" size={19} />
            </span>
            <span className="nav-label">Configuración</span>
          </button>
        </nav>

        <div className="sidebar-footer">
          <div className="account-summary">
            <div className="account-avatar">{session.username.charAt(0).toUpperCase()}</div>
            <div className="account-details">
              <strong>{session.username}</strong>
              <span>{session.rol}</span>
            </div>
          </div>
          <button
            className="logout-icon-btn"
            onClick={onLogout}
            title="Cerrar sesión"
          >
            <MenuIcon name="logout" size={17} />
          </button>
        </div>
      </aside>

      {/* ── Contenido principal ───────────────────────────────────── */}
      <main className="content">
        <header className="topbar">
          <h1>{SECTION_TITLES[section] ?? 'SICEUNP'}</h1>
        </header>

        {feedback && <div className={`alert ${feedback.type}`}>{feedback.text}</div>}

        {/* Resumen — varía según el rol */}
        {section === 'resumen' && isAdmin && (
          <>
            <section className="stats-grid">
              <article className="stat-card">
                <div className="stat-card-icon blue">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
                  </svg>
                </div>
                <div className="stat-card-body">
                  <span className="stat-card-label">Usuarios del sistema</span>
                  <strong className="stat-card-value">
                    {adminStatsLoading ? '…' : (adminStats.usuarios ?? '—')}
                  </strong>
                  <span className="stat-card-sub">cuentas registradas</span>
                </div>
              </article>
              <article className="stat-card">
                <div className="stat-card-icon green">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="3" /><path d="M19.07 4.93a10 10 0 0 1 0 14.14M4.93 4.93a10 10 0 0 0 0 14.14" />
                  </svg>
                </div>
                <div className="stat-card-body">
                  <span className="stat-card-label">Parámetros globales</span>
                  <strong className="stat-card-value">
                    {adminStatsLoading ? '…' : (adminStats.parametros ?? '—')}
                  </strong>
                  <span className="stat-card-sub">configuraciones activas</span>
                </div>
              </article>
              <article className="stat-card">
                <div className="stat-card-icon amber">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                  </svg>
                </div>
                <div className="stat-card-body">
                  <span className="stat-card-label">Registros de auditoría</span>
                  <strong className="stat-card-value">
                    {adminStatsLoading ? '…' : (adminStats.bitacora ?? '—')}
                  </strong>
                  <span className="stat-card-sub">eventos en bitácora</span>
                </div>
              </article>
            </section>
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h2>Panel de administración</h2>
                  <p className="muted">Gestión de usuarios, roles, parámetros del sistema y auditoría.</p>
                </div>
                <button className="text-button" onClick={() => setSection('usuarios')}>Gestionar usuarios</button>
              </div>
              <p style={{ padding: '1.5rem', color: 'var(--text-muted)', fontSize: 14 }}>
                Desde este panel puedes administrar las cuentas de acceso al sistema, configurar parámetros globales (multas, UIT, plazos) y revisar la bitácora de auditoría con todas las acciones registradas.
              </p>
            </section>
          </>
        )}

        {/* Resumen — CEUNP */}
        {section === 'resumen' && canManage && (
          <>
            <section className="stats-grid">
              <article className="stat-card">
                <div className="stat-card-icon blue">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
                  </svg>
                </div>
                <div className="stat-card-body">
                  <span className="stat-card-label">Procesos electorales</span>
                  <strong className="stat-card-value">{processes.length}</strong>
                  <span className="stat-card-sub">registrados en el sistema</span>
                </div>
              </article>
              <article className="stat-card">
                <div className="stat-card-icon green">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
                  </svg>
                </div>
                <div className="stat-card-body">
                  <span className="stat-card-label">Docentes en padrón</span>
                  <strong className="stat-card-value">{teachers.length}</strong>
                  <span className="stat-card-sub">habilitados para votar</span>
                </div>
              </article>
              <article className="stat-card">
                <div className="stat-card-icon amber">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                  </svg>
                </div>
                <div className="stat-card-body">
                  <span className="stat-card-label">En votación activa</span>
                  <strong className="stat-card-value">{processes.filter(p => p.estado === 'VOTACION').length}</strong>
                  <span className="stat-card-sub">proceso{processes.filter(p => p.estado === 'VOTACION').length !== 1 ? 's' : ''} en curso</span>
                </div>
              </article>
            </section>
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <h2>Actividad electoral</h2>
                  <p className="muted">Estado actual de los procesos registrados.</p>
                </div>
                <button className="text-button" onClick={() => setSection('convocatoria')}>Ver convocatorias</button>
              </div>
              <ProcessTable processes={processes.slice(0, 5)} loading={loading} />
            </section>
          </>
        )}

        {/* CUS01 · Gestionar convocatoria y cronograma (CEUNP) */}
        {section === 'convocatoria' && canManage && (
          <ConvocatoriaPage onChange={loadData} onSessionExpired={onLogout} />
        )}

        {/* CUS02 · Gestionar padrón electoral (CEUNP) */}
        {section === 'padron' && canManage && (
          <PadronPage onChange={loadData} onSessionExpired={onLogout} />
        )}

        {/* Docentes — CRUD completo (solo CEUNP) */}
        {section === 'docentes' && canManage && (
          <DocentesPage
            teachers={teachers}
            loading={loading}
            onRefresh={loadData}
            canManage={canManage}
            onImport={() => setSection('importar-docentes')}
            onGestionarPadron={() => setSection('padron')}
            onSessionExpired={onLogout}
          />
        )}

        {/* Importar Docentes (solo CEUNP) */}
        {section === 'importar-docentes' && canManage && (
          <ImportarDocentesPage onImportSuccess={() => { loadData(); setSection('docentes'); }} />
        )}

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

        {/* Usuarios */}
        {section === 'usuarios' && session.rol === 'ADMIN' && (
          <UsuariosPage teachers={teachers} onSessionExpired={onLogout} />
        )}

        {/* Cuenta */}
        {section === 'cuenta' && <CuentaPage onSessionExpired={onLogout} />}

        {/* Parámetros globales — ETAPA 2 */}
        {section === 'parametros' && session.rol === 'ADMIN' && (
          <ParametrosPage onSessionExpired={onLogout} />
        )}

        {/* Cargos excluidos */}
        {section === 'cargos-excluidos' && (isAdmin || canManage) && (
          <CargosExcluidosPage canManage={isAdmin || canManage} onSessionExpired={onLogout} />
        )}

        {/* Bitácora / Auditoría */}
        {section === 'bitacora' && session.rol === 'ADMIN' && (
          <BitacoraPage onSessionExpired={onLogout} />
        )}

        {/* Mesa */}
        {section === 'mesa' && (
          <MiembroMesaPage onIrInstalacion={() => setSection('instalacion')} onIrCierre={() => setSection('cierre')} onIrEscrutinio={() => setSection('escrutinio')} />
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
          <PantallaEscrutinio session={session} onSessionExpired={onLogout} />
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

        {section === 'computo' && (
          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Cómputo General y Proclamación</h2>
                <p className="muted">Consolidación de actas escrutadas, cálculo de resultados finales y generación del acta de proclamación.</p>
              </div>
            </div>
            <div style={{ padding: '1.5rem', color: 'var(--text-main)', fontSize: 14 }}>
              <p>Cómputo general al 100% de actas, verificación de quórum y emisión de la resolución formal de proclamación de ganadores o convocatoria a segunda vuelta.</p>
            </div>
          </section>
        )}

        {section === 'impugnaciones' && (
          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Impugnaciones y Nulidades</h2>
                <p className="muted">Registro y resolución de actas observadas, votos impugnados y solicitudes de nulidad.</p>
              </div>
            </div>
            <div style={{ padding: '1.5rem', color: 'var(--text-main)', fontSize: 14 }}>
              <p>Gestión de apelaciones dictaminadas por el Comité Electoral (CEUNP) sobre observaciones hechas durante el escrutinio en mesas de sufragio.</p>
            </div>
          </section>
        )}

        {section === 'multas' && (
          <section className="panel"><div className="panel-heading"><h2>Módulo de Multas (RN35)</h2></div><p style={{ padding: '1rem' }}>Generación y cálculo automático del 2.5% UIT (Omisos a sufragio) y 3% UIT (Omisos a mesa) cruzando la tabla `padron_electoral`.</p></section>
        )}
        {/* CUS07 · Credenciales propias (QR generado en el navegador, sin servicios externos) */}
        {section === 'fotocheck' && <MisCredencialesPage foco="MIEMBRO_MESA" onSessionExpired={onLogout} />}
        {section === 'credencial' && <MisCredencialesPage foco="PERSONERO" onSessionExpired={onLogout} />}
        {section === 'pase' && session.rol === 'DOCENTE' && (
          <MiPaseQRPage onSessionExpired={onLogout} />
        )}
        {section === 'pase' && session.rol !== 'DOCENTE' && <MisCredencialesPage foco="ELECTOR" onSessionExpired={onLogout} />}
        {section === 'verificar-qr' && <VerificarCredencialPanel onSessionExpired={onLogout} />}

      </main>
    </div>
  );
}
