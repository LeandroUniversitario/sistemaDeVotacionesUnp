import { useEffect, useState } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';
import ProcessTable from '../components/ProcessTable';
import DocentesPage from './DocentesPage';
import CandidaturasPage from './CandidaturasPage';
import TachasPage from './TachasPage';
import UsuariosPage from './UsuariosPage';
import CuentaPage from './CuentaPage';
import MiembroMesaPage from './MiembroMesaPage';
import TerminalVotacionPage from './TerminalVotacionPage';
import SorteosPage from './SorteosPage';
import ImportarDocentesPage from './ImportarDocentesPage';
import ParametrosPage from './ParametrosPage';
import BitacoraPage from './BitacoraPage';
import CargosExcluidosPage from './CargosExcluidosPage';

const EMPTY_PROCESS = {
  nombre: '',
  fechaConvocatoria: '',
  fechaInicio: '',
  fechaFin: '',
  tipo: 'PRIMERA_VUELTA',
  quorumMinimo: '60',
};

// ─── Mapas de iconos por sección ─────────────────────────────────────────
const MENU_ICONS = {
  resumen: 'dashboard', procesos: 'calendar', docentes: 'users',
  candidaturas: 'list', tachas: 'shield', usuarios: 'user',
  nuevo: 'plus', configuracion: 'settings', cuenta: 'user',
  mesa: 'shield', terminal: 'person', sorteos: 'list',
  parametros: 'settings', bitacora: 'shield',
};

// ─── Menú por rol (orden, visibilidad y color de ícono) ──────────────────
const MENU_POR_ROL = {
  ADMIN: [
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6', bg: '#dbeafe' },
    { key: 'usuarios', label: 'Usuarios', icon: 'user', color: '#ef4444', bg: '#fee2e2' },
    { key: 'parametros', label: 'Parámetros', icon: 'settings', color: '#6366f1', bg: '#e0e7ff' },
    { key: 'cargos-excluidos', label: 'Excepciones Sorteo', icon: 'shield', color: '#f43f5e', bg: '#ffe4e6' },
    { key: 'bitacora', label: 'Bitácora', icon: 'shield', color: '#14b8a6', bg: '#ccfbf1' },
  ],
  CEUNP: [
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6', bg: '#dbeafe' },
    { key: 'procesos', label: 'Procesos electorales', icon: 'calendar', color: '#10b981', bg: '#d1fae5' },
    { key: 'docentes', label: 'Padrón y docentes', icon: 'users', color: '#8b5cf6', bg: '#ede9fe' },
    { key: 'nuevo', label: 'Crear proceso', icon: 'plus', color: '#f59e0b', bg: '#fef3c7' },
    { key: 'candidaturas', label: 'Candidaturas', icon: 'list', color: '#06b6d4', bg: '#cffafe' },
    { key: 'tachas', label: 'Tachas', icon: 'shield', color: '#f97316', bg: '#ffedd5' },
    { key: 'cargos-excluidos', label: 'Excepciones Sorteo', icon: 'shield', color: '#f43f5e', bg: '#ffe4e6' },
    { key: 'personeros', label: 'Personeros y Acreditaciones', icon: 'users', color: '#8b5cf6', bg: '#ede9fe' },
    { key: 'credenciales', label: 'Credenciales y QR', icon: 'user', color: '#10b981', bg: '#d1fae5' },
    { key: 'sorteos', label: 'Sorteo de Mesas', icon: 'list', color: '#eab308', bg: '#fef9c3' },
    { key: 'computo', label: 'Cómputo y Proclamación', icon: 'dashboard', color: '#6366f1', bg: '#e0e7ff' },
    { key: 'impugnaciones', label: 'Impugnaciones y Nulidades', icon: 'shield', color: '#ef4444', bg: '#fee2e2' },
    { key: 'multas', label: 'Gestión Multas (RN35)', icon: 'list', color: '#f97316', bg: '#ffedd5' },
  ],
  MIEMBRO_MESA: [
    { key: 'mesa', label: 'Mi Mesa de Sufragio', icon: 'shield', color: '#14b8a6', bg: '#ccfbf1' },
    { key: 'terminal', label: 'Terminal de Votación', icon: 'person', color: '#6366f1', bg: '#e0e7ff' },
    { key: 'fotocheck', label: 'Fotocheck QR (RF56)', icon: 'user', color: '#f59e0b', bg: '#fef3c7' },
  ],
  PERSONERO: [
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6', bg: '#dbeafe' },
    { key: 'credencial', label: 'Credencial QR (RF51)', icon: 'user', color: '#10b981', bg: '#d1fae5' },
    { key: 'tachas', label: 'Tachas e Impugnaciones', icon: 'shield', color: '#f97316', bg: '#ffedd5' },
  ],
  DOCENTE: [
    { key: 'resumen', label: 'Resumen', icon: 'dashboard', color: '#3b82f6', bg: '#dbeafe' },
    { key: 'pase', label: 'Descargar Pase QR', icon: 'user', color: '#8b5cf6', bg: '#ede9fe' },
  ],
};

const SECTION_TITLES = {
  resumen: 'Resumen general',
  procesos: 'Procesos electorales',
  docentes: 'Padrón y docentes',
  candidaturas: 'Candidaturas',
  tachas: 'Tachas electorales',
  personeros: 'Personeros y Acreditaciones',
  credenciales: 'Generación de Credenciales y Códigos QR',
  computo: 'Cómputo General y Proclamación de Resultados',
  impugnaciones: 'Resolución de Impugnaciones y Nulidades',
  usuarios: 'Usuarios del sistema',
  cuenta: 'Configuración de mi cuenta',
  nuevo: 'Crear proceso electoral',
  mesa: 'Mi Mesa de Sufragio',
  terminal: 'Terminal de Votación',
  sorteos: 'Sorteo de Miembros',
  'importar-docentes': 'Importar Padrón de Docentes',
  parametros: 'Parámetros globales',
  'cargos-excluidos': 'Excepciones de Sorteo (RN20)',
  bitacora: 'Bitácora de auditoría',
  multas: 'Gestión de Multas (RN35)',
  fotocheck: 'Mi Fotocheck Digital',
  credencial: 'Credencial de Personero',
  pase: 'Pase de Votación QR',
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
  const [processes, setProcesses] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [selectedProcess, setSelectedProcess] = useState(null);
  const [processForm, setProcessForm] = useState(EMPTY_PROCESS);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  // Estado de métricas reales para el resumen del Admin
  const [adminStats, setAdminStats] = useState({ usuarios: null, parametros: null, bitacora: null });
  const [adminStatsLoading, setAdminStatsLoading] = useState(false);

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

  async function createProcess(event) {
    event.preventDefault();
    setFeedback(null);
    setSaving(true);
    try {
      await apiRequest('/api/procesos', {
        method: 'POST',
        body: JSON.stringify({
          ...processForm,
          fechaConvocatoria: processForm.fechaConvocatoria || null,
          fechaInicio: `${processForm.fechaInicio}:00`,
          fechaFin: `${processForm.fechaFin}:00`,
          quorumMinimo: Number(processForm.quorumMinimo),
        }),
      });
      setProcessForm(EMPTY_PROCESS);
      setFeedback({ type: 'success', text: 'Proceso electoral creado correctamente.' });
      await loadData();
      setSection('procesos');
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onLogout();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  function updateProcessField(field, value) {
    setProcessForm((current) => ({ ...current, [field]: value }));
  }

  return (
    <div className="app-shell">
      {/* ── Sidebar ──────────────────────────────────────────────── */}
      <aside className="sidebar">
        {/* ── Logo + nombre del sistema ── */}
        <div className="sidebar-brand">
          <div className="brand-mark">
            <img
              src="/escudo-unp.png"
              alt="Escudo UNP"
              width="52"
              height="52"
              style={{ display: 'block', width: '100%', height: '100%', objectFit: 'contain' }}
            />
          </div>
          <div className="sidebar-brand-text">
            <p className="sidebar-code">SICEUNP</p>
            <p className="sidebar-title">Sistema de Control de<br />Elecciones Docentes</p>
            <p className="sidebar-subtitle">Universidad Nacional de Piura</p>
          </div>
        </div>

        <nav className="nav-list" aria-label="Navegación principal">
          {/* ── Menú principal según rol ── */}
          {(MENU_POR_ROL[session.rol] ?? []).map(({ key, label, icon }) => (
            <button
              key={key}
              className={`nav-item${section === key ? ' active' : ''}`}
              onClick={() => setSection(key)}
            >
              <MenuIcon name={icon} />
              {label}
            </button>
          ))}

          {/* ── Configuración: solo Mi cuenta ── */}
          <div className="nav-divider" />
          <button
            className="nav-section-label nav-section-button"
            onClick={() => setSettingsOpen(o => !o)}
          >
            <MenuIcon name="settings" />
            Configuración
            <span className={`nav-chevron ${settingsOpen ? 'open' : ''}`} aria-hidden="true" />
          </button>
          {settingsOpen && (
            <button
              className={`nav-item nav-subitem ${section === 'cuenta' ? 'active' : ''}`}
              onClick={() => setSection('cuenta')}
            >
              <MenuIcon name="user" />
              Mi cuenta
            </button>
          )}
        </nav>

        <div className="sidebar-footer">
          <div className="account-summary">
            <div className="account-avatar">{session.username.charAt(0).toUpperCase()}</div>
            <div className="account-details">
              <strong>{session.username}</strong>
              <span>Rol: {session.rol}</span>
            </div>
            <button className="sidebar-logout" onClick={onLogout} aria-label="Cerrar sesión">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M10 17l5-5-5-5M15 12H3M21 3v18" />
              </svg>
            </button>
          </div>
        </div>
      </aside>

      {/* ── Contenido principal ───────────────────────────────────── */}
      <main className="content">
        <header className="topbar">
          <h1>{SECTION_TITLES[section] ?? 'Nuevo proceso electoral'}</h1>
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
                <button className="text-button" onClick={() => setSection('procesos')}>Ver todos</button>
              </div>
              <ProcessTable processes={processes.slice(0, 5)} loading={loading} />
            </section>
          </>
        )}

        {/* Procesos (solo CEUNP) */}
        {section === 'procesos' && canManage && (
          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Procesos electorales</h2>
                <p className="muted">Consulta los procesos y sus fechas principales.</p>
              </div>
              <button className="primary-small" onClick={() => setSection('nuevo')}>+ Nuevo proceso</button>
            </div>
            <ProcessTable processes={processes} loading={loading} />
          </section>
        )}

        {/* Docentes — CRUD completo (solo CEUNP) */}
        {section === 'docentes' && canManage && (
          <DocentesPage
            teachers={teachers}
            loading={loading}
            onRefresh={loadData}
            canManage={canManage}
            onImport={() => setSection('importar-docentes')}
            onSessionExpired={onLogout}
          />
        )}

        {/* Importar Docentes (solo CEUNP) */}
        {section === 'importar-docentes' && canManage && (
          <ImportarDocentesPage onImportSuccess={() => { loadData(); setSection('docentes'); }} />
        )}

        {/* Candidaturas */}
        {section === 'candidaturas' && (
          <CandidaturasPage
            processes={processes}
            teachers={teachers}
            selectedProcess={selectedProcess}
            onProcessChange={setSelectedProcess}
            canManage={canManage}
            onSessionExpired={onLogout}
          />
        )}

        {/* Tachas */}
        {section === 'tachas' && (
          <TachasPage
            processes={processes}
            teachers={teachers}
            canManage={canManage}
            onSessionExpired={onLogout}
          />
        )}

        {/* Sorteos */}
        {section === 'sorteos' && <SorteosPage processes={processes} />}

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
        {section === 'mesa' && <MiembroMesaPage />}

        {/* Terminal de Votación */}
        {section === 'terminal' && <TerminalVotacionPage />}

        {/* Módulos de CEUNP */}
        {section === 'personeros' && (
          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Personeros y Acreditaciones</h2>
                <p className="muted">Gestión de registro y acreditación de personeros generales y de mesa por lista electoral.</p>
              </div>
            </div>
            <div style={{ padding: '1.5rem', color: 'var(--text-main)', fontSize: 14 }}>
              <p>Módulo para la inscripción, validación de requisitos y emisión de constancias de acreditación para personeros designados por las listas candidatas.</p>
            </div>
          </section>
        )}

        {section === 'credenciales' && (
          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Credenciales y Códigos QR</h2>
                <p className="muted">Generación masiva de credenciales de miembros de mesa, personeros y pases QR de electores.</p>
              </div>
            </div>
            <div style={{ padding: '1.5rem', color: 'var(--text-main)', fontSize: 14 }}>
              <p>Emisión y descarga de credenciales digitales con firma y códigos QR para comprobación de identidad el día de la jornada electoral.</p>
            </div>
          </section>
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
        {section === 'fotocheck' && (
          <section className="panel"><div className="panel-heading"><h2>Fotocheck Digital (RF56)</h2></div><p style={{ padding: '1rem' }}>Presente este código QR al momento de instalar la mesa. Es infalsificable y de uso único.</p><div style={{ textAlign: 'center', padding: '2rem' }}><img src={`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=FOTOCHECK-${session.username}`} alt="QR Fotocheck" /></div></section>
        )}
        {section === 'credencial' && (
          <section className="panel"><div className="panel-heading"><h2>Credencial de Personero (RF51)</h2></div><p style={{ padding: '1rem' }}>Presente este código QR al presidente de mesa para acreditarse e iniciar la fiscalización.</p><div style={{ textAlign: 'center', padding: '2rem' }}><img src={`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=PERSONERO-${session.username}`} alt="QR Credencial" /></div></section>
        )}
        {section === 'pase' && (
          <section className="panel"><div className="panel-heading"><h2>Pase de Votación QR (RF62)</h2></div><p style={{ padding: '1rem' }}>Muestre este código al Secretario para habilitar su cabina secreta. Válido para un solo uso.</p><div style={{ textAlign: 'center', padding: '2rem' }}><img src={`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=VOTO-${session.username}`} alt="QR Pase" /></div></section>
        )}

        {/* Nuevo proceso */}
        {section === 'nuevo' && canManage && (
          <section className="panel form-panel">
            <div className="panel-heading">
              <div>
                <h2>Crear proceso electoral</h2>
                <p className="muted">Registra una primera o segunda vuelta para iniciar su configuración.</p>
              </div>
            </div>
            <form className="process-form" onSubmit={createProcess}>
              <label>Nombre del proceso
                <input value={processForm.nombre}
                  onChange={(event) => updateProcessField('nombre', event.target.value)} required />
              </label>
              <div className="form-row">
                <label>Fecha de convocatoria oficial
                  <input
                    type="date"
                    value={processForm.fechaConvocatoria}
                    onChange={(event) => updateProcessField('fechaConvocatoria', event.target.value)}
                  />
                  {processForm.fechaConvocatoria && processForm.fechaInicio && (() => {
                    const fConv = new Date(processForm.fechaConvocatoria + 'T00:00:00');
                    const fInic = new Date(processForm.fechaInicio.split('T')[0] + 'T00:00:00');
                    const dias = Math.round((fInic - fConv) / (1000 * 60 * 60 * 24));
                    const ok = dias >= 30 && dias <= 45;
                    return (
                      <small style={{ color: ok ? '#10b981' : '#ef4444', marginTop: 4 }}>
                        {ok ? `✓ ${dias} días de anticipación (dentro de los 30-45 requeridos)` : `⚠ ${dias} días — la convocatoria debe ser de 30 a 45 días antes del sufragio (RN02)`}
                      </small>
                    );
                  })()}
                </label>
              </div>
              <div className="form-row">
                <label>Fecha y hora de inicio del sufragio
                  <input type="datetime-local" value={processForm.fechaInicio}
                    onChange={(event) => updateProcessField('fechaInicio', event.target.value)} required />
                </label>
                <label>Fecha y hora de fin del sufragio
                  <input type="datetime-local" value={processForm.fechaFin}
                    onChange={(event) => updateProcessField('fechaFin', event.target.value)} required />
                </label>
              </div>
              <div className="form-row">
                <label>Tipo de proceso
                  <select value={processForm.tipo}
                    onChange={(event) => updateProcessField('tipo', event.target.value)}>
                    <option value="PRIMERA_VUELTA">Primera vuelta</option>
                    <option value="SEGUNDA_VUELTA">Segunda vuelta</option>
                  </select>
                </label>
                <label>Quórum mínimo (%)
                  <input type="number" min="0" max="100" step="0.01" value={processForm.quorumMinimo}
                    onChange={(event) => updateProcessField('quorumMinimo', event.target.value)} required />
                </label>
              </div>
              <div className="form-actions">
                <button type="button" className="secondary-button"
                  onClick={() => setSection('resumen')}>Cancelar</button>
                <button type="submit" disabled={saving}>{saving ? 'Guardando...' : 'Crear proceso'}</button>
              </div>
            </form>
          </section>
        )}
      </main>
    </div>
  );
}
