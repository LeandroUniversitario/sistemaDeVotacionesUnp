import { useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';
import './cuenta/cuenta.css';

const fmtFechaHora = new Intl.DateTimeFormat('es-PE', {
  day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
});
const fmtFecha = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'long', year: 'numeric' });
const fmtHora = new Intl.DateTimeFormat('es-PE', { hour: '2-digit', minute: '2-digit' });

function formatFecha(value, formato = fmtFechaHora) {
  if (!value) return '—';
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? String(value) : formato.format(d);
}

const si = (v) => v === true || v === 1 || v === '1';

/** Texto legible para valores de enumeraciones del backend (TIEMPO_COMPLETO → Tiempo completo). */
function legible(valor) {
  if (!valor) return '—';
  const t = String(valor).replace(/_/g, ' ').toLowerCase();
  return t.charAt(0).toUpperCase() + t.slice(1);
}

function situacionCuenta(u) {
  if (!u) return { tono: 'neutro', texto: '—' };
  if (!si(u.activo)) return { tono: 'peligro', texto: 'Inactiva' };
  if (si(u.bloqueada)) return { tono: 'peligro', texto: 'Bloqueada' };
  if (si(u.debeCambiarPassword)) return { tono: 'aviso', texto: 'Clave provisional' };
  return { tono: 'ok', texto: 'Activa' };
}

/** Qué hace cada rol dentro del proceso electoral (Reglamento de Elecciones UNP). */
const INFO_ROL = {
  ADMIN: {
    tono: 'rojo',
    resumen: 'Administra la plataforma: cuentas y roles, parámetros globales, respaldos de la base y la bitácora de auditoría.',
    alcance: ['Crear, bloquear y restablecer cuentas', 'Configurar parámetros (UIT, multas, plazos)', 'Generar y verificar respaldos', 'Auditar la bitácora del sistema'],
  },
  CEUNP: {
    tono: 'azul',
    resumen: 'Comité Electoral: conduce el proceso desde la convocatoria hasta la proclamación de resultados.',
    alcance: ['Convocar y publicar el cronograma', 'Aprobar el padrón e inscribir listas', 'Resolver tachas, impugnaciones y nulidades', 'Computar y proclamar resultados'],
  },
  MIEMBRO_MESA: {
    tono: 'morado',
    resumen: 'Integra una mesa de sufragio: la instala, verifica a los electores, cierra el sufragio y realiza el escrutinio.',
    alcance: ['Instalar la mesa con su fotocheck QR', 'Verificar electores y habilitar la cabina', 'Cerrar el sufragio y levantar actas', 'Votar como docente elector'],
  },
  PERSONERO: {
    tono: 'ambar',
    resumen: 'Fiscaliza el proceso en representación de una lista: observa la mesa, impugna votos y apela decisiones.',
    alcance: ['Acreditarse con su credencial QR', 'Impugnar votos y apelar ante el CEUNP', 'Verificar actas y resultados', 'Votar como docente elector'],
  },
  DOCENTE: {
    tono: 'verde',
    resumen: 'Docente ordinario del padrón: consulta las listas, descarga su pase QR y emite su voto en la cabina.',
    alcance: ['Consultar listas y planes de gobierno', 'Descargar su pase de votación QR', 'Presentar tachas contra candidatos', 'Consultar multas y resultados'],
  },
};

/** Fechas de emisión y vencimiento de la sesión, leídas del token (sin validarlo: eso lo hace el backend). */
function datosToken() {
  try {
    const token = sessionStorage.getItem('accessToken');
    const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
    return {
      emitido: payload.iat ? new Date(payload.iat * 1000) : null,
      vence: payload.exp ? new Date(payload.exp * 1000) : null,
    };
  } catch {
    return { emitido: null, vence: null };
  }
}

function iniciales(perfil, username) {
  if (perfil?.nombres || perfil?.apellidos) {
    return `${(perfil.nombres ?? '').trim().charAt(0)}${(perfil.apellidos ?? '').trim().charAt(0)}`.toUpperCase();
  }
  return (username ?? '?').slice(0, 2).toUpperCase();
}

function fuerzaClave(clave) {
  if (!clave) return { nivel: 0, texto: '' };
  let p = 0;
  if (clave.length >= 8) p++;
  if (clave.length >= 12) p++;
  if (/[a-z]/.test(clave) && /[A-Z]/.test(clave)) p++;
  if (/[0-9]/.test(clave)) p++;
  if (/[^A-Za-z0-9]/.test(clave)) p++;
  const nivel = Math.min(4, Math.max(1, p - 1));
  return { nivel, texto: ['', 'Débil', 'Aceptable', 'Buena', 'Fuerte'][nivel] };
}

function Dato({ etiqueta, children, ancho }) {
  return (
    <div className={`cu-dato${ancho ? ' ancho' : ''}`}>
      <dt>{etiqueta}</dt>
      <dd>{children}</dd>
    </div>
  );
}

function CampoClave({ id, etiqueta, valor, onChange, autoComplete, minLength }) {
  const [ver, setVer] = useState(false);
  return (
    <div className="login-field">
      <label htmlFor={id}>{etiqueta}</label>
      <span className="input-with-icon">
        <MenuIcon name="lock" />
        <input
          id={id}
          type={ver ? 'text' : 'password'}
          autoComplete={autoComplete}
          minLength={minLength}
          value={valor}
          onChange={(e) => onChange(e.target.value)}
          required
        />
        <button
          type="button"
          className="toggle-password-btn"
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => setVer((s) => !s)}
          title={ver ? 'Ocultar contraseña' : 'Ver contraseña'}
          aria-label={ver ? 'Ocultar contraseña' : 'Ver contraseña'}
        >
          <MenuIcon name={ver ? 'eye' : 'eye_off'} size={18} />
        </button>
      </span>
    </div>
  );
}

/**
 * Configuración de la cuenta: perfil del usuario y de su rol, módulos a los que tiene acceso,
 * seguridad (cambio de contraseña) y la sesión actual con el botón para cerrarla.
 *
 * @param {{ session: object, menu: object[], rolLegible: string, onIrA: function,
 *           onLogout: function, onSessionExpired: function }} props
 */
export default function CuentaPage({ session, menu = [], rolLegible, onIrA, onLogout, onSessionExpired }) {
  const [perfil, setPerfil] = useState(null);
  const [cargandoPerfil, setCargandoPerfil] = useState(true);
  const [form, setForm] = useState({ passwordActual: '', passwordNueva: '', confirmar: '' });
  const [feedback, setFeedback] = useState(null);
  const [saving, setSaving] = useState(false);
  const [confirmarSalida, setConfirmarSalida] = useState(false);
  const [token, setToken] = useState(datosToken);

  useEffect(() => {
    let vigente = true;
    apiRequest('/api/auth/me')
      .then((data) => { if (vigente) setPerfil(data); })
      .catch((error) => { if (error.message === 'SESSION_EXPIRED') onSessionExpired?.(); })
      .finally(() => { if (vigente) setCargandoPerfil(false); });
    return () => { vigente = false; };
  }, [onSessionExpired]);

  useEffect(() => {
    if (!confirmarSalida) return undefined;
    const esc = (e) => { if (e.key === 'Escape') setConfirmarSalida(false); };
    document.addEventListener('keydown', esc);
    return () => document.removeEventListener('keydown', esc);
  }, [confirmarSalida]);

  async function submit(event) {
    event.preventDefault();
    setFeedback(null);
    if (form.passwordNueva !== form.confirmar) {
      setFeedback({ type: 'error', text: 'La confirmación no coincide con la nueva contraseña.' });
      return;
    }
    if (form.passwordNueva === form.passwordActual) {
      setFeedback({ type: 'error', text: 'La nueva contraseña debe ser distinta de la actual.' });
      return;
    }
    setSaving(true);
    try {
      const r = await apiRequest('/api/auth/password', {
        method: 'PATCH',
        body: JSON.stringify({ passwordActual: form.passwordActual, passwordNueva: form.passwordNueva }),
      });
      // A4: el cambio de clave revoca los tokens anteriores; esta sesión sigue con el nuevo
      if (r?.token) { sessionStorage.setItem('accessToken', r.token); setToken(datosToken()); }
      setForm({ passwordActual: '', passwordNueva: '', confirmar: '' });
      setFeedback({ type: 'success', text: 'Contraseña actualizada correctamente. Las demás sesiones abiertas se cerraron.' });
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  const rol = perfil?.rol ?? session?.rol;
  const infoRol = INFO_ROL[rol] ?? { tono: 'azul', resumen: '', alcance: [] };
  const estado = situacionCuenta(perfil);
  const esDocente = Boolean(perfil?.dni);
  const nombre = perfil?.nombreCompleto || [perfil?.nombres, perfil?.apellidos].filter(Boolean).join(' ') || session?.username;
  const modulos = useMemo(() => menu.filter((i) => i.key && i.key !== 'resumen'), [menu]);
  const fuerza = fuerzaClave(form.passwordNueva);
  const reglas = [
    { ok: form.passwordNueva.length >= 8, texto: 'Al menos 8 caracteres' },
    { ok: /\p{L}/u.test(form.passwordNueva), texto: 'Contiene letras' },
    { ok: /[0-9]/.test(form.passwordNueva), texto: 'Contiene números' },
    { ok: form.passwordNueva.length > 0 && form.passwordNueva === form.confirmar, texto: 'La confirmación coincide' },
  ];

  return (
    <div className="cu">
      {/* ── Cabecera de perfil ─────────────────────────────────────── */}
      <section className={`cu-hero tono-${infoRol.tono}`}>
        <div className="cu-hero-id">
          <div className="cu-avatar" aria-hidden="true">{iniciales(perfil, session?.username)}</div>
          <div className="cu-hero-texto">
            <span className="cu-hero-eyebrow">{rolLegible}</span>
            <h2>{cargandoPerfil ? 'Cargando…' : nombre}</h2>
            <div className="cu-hero-meta">
              <span><MenuIcon name="user" size={14} /> {session?.username}</span>
              {perfil?.email && <span><MenuIcon name="file" size={14} /> {perfil.email}</span>}
              <span><MenuIcon name="calendar" size={14} /> Último acceso: {formatFecha(perfil?.ultimoAcceso)}</span>
            </div>
          </div>
        </div>
        <div className="cu-hero-acciones">
          <span className={`cu-chip ${estado.tono}`}><span className="cu-punto" /> Cuenta {estado.texto.toLowerCase()}</span>
          <button type="button" className="cu-btn-salir" onClick={() => setConfirmarSalida(true)}>
            <MenuIcon name="logout" size={16} /> Cerrar sesión
          </button>
        </div>
      </section>

      <div className="cu-grid">
        <div className="cu-col">
          {/* ── Datos de la cuenta ─────────────────────────────── */}
          <section className="cu-card">
            <header className="cu-card-head">
              <span className="cu-card-icono azul"><MenuIcon name="user" size={18} /></span>
              <div>
                <h3>Datos de la cuenta</h3>
                <p>Información de acceso del usuario autenticado.</p>
              </div>
            </header>
            {cargandoPerfil ? (
              <div className="cu-esqueleto" aria-label="Cargando datos"><span /><span /><span /><span /></div>
            ) : !perfil ? (
              <p className="muted">No se pudieron recuperar los datos de la cuenta.</p>
            ) : (
              <dl className="cu-datos">
                <Dato etiqueta="Usuario">{perfil.username}</Dato>
                <Dato etiqueta="Rol del sistema"><span className={`cu-rol tono-${infoRol.tono}`}>{rolLegible}</span></Dato>
                <Dato etiqueta="Estado"><span className={`cu-chip ${estado.tono}`}><span className="cu-punto" /> {estado.texto}</span></Dato>
                <Dato etiqueta="Tipo de cuenta">{esDocente ? 'Vinculada a un docente del padrón' : 'Cuenta institucional'}</Dato>
                <Dato etiqueta="Código de usuario">#{String(perfil.id ?? '—').padStart(4, '0')}</Dato>
                <Dato etiqueta="Último acceso">{formatFecha(perfil.ultimoAcceso)}</Dato>
              </dl>
            )}
          </section>

          {/* ── Datos institucionales (solo cuentas vinculadas a un docente) ── */}
          {esDocente && (
            <section className="cu-card">
              <header className="cu-card-head">
                <span className="cu-card-icono verde"><MenuIcon name="account_balance" size={18} /></span>
                <div>
                  <h3>Datos institucionales</h3>
                  <p>Registro del docente en el padrón de la Universidad Nacional de Piura.</p>
                </div>
                <span className={`cu-chip ${si(perfil.habilitadoParaVotar) ? 'ok' : 'peligro'}`}>
                  <span className="cu-punto" /> {si(perfil.habilitadoParaVotar) ? 'Habilitado para votar' : 'No habilitado para votar'}
                </span>
              </header>
              <dl className="cu-datos">
                <Dato etiqueta="DNI">{perfil.dni}</Dato>
                <Dato etiqueta="Apellidos y nombres" ancho>{[perfil.apellidos, perfil.nombres].filter(Boolean).join(', ') || nombre}</Dato>
                <Dato etiqueta="Facultad" ancho>{perfil.facultad || '—'}</Dato>
                <Dato etiqueta="Departamento académico">{perfil.departamento || '—'}</Dato>
                <Dato etiqueta="Categoría">{legible(perfil.categoria)}</Dato>
                <Dato etiqueta="Dedicación">{legible(perfil.dedicacion)}</Dato>
                <Dato etiqueta="Grado académico">{perfil.gradoAcademico || '—'}</Dato>
                <Dato etiqueta="Condición">{legible(perfil.estadoDocente)}</Dato>
                <Dato etiqueta="Fecha de ingreso">{formatFecha(perfil.fechaIngreso, fmtFecha)}</Dato>
                <Dato etiqueta="Correo institucional" ancho>{perfil.email || '—'}</Dato>
              </dl>
            </section>
          )}

          {/* ── Seguridad ──────────────────────────────────────── */}
          <section className="cu-card">
            <header className="cu-card-head">
              <span className="cu-card-icono ambar"><MenuIcon name="key" size={18} /></span>
              <div>
                <h3>Seguridad y contraseña</h3>
                <p>Confirme su contraseña actual antes de establecer una nueva.</p>
              </div>
            </header>
            {feedback && <div className={`alert ${feedback.type}`}>{feedback.text}</div>}
            <form className="cu-form" onSubmit={submit}>
              <div className="cu-form-campos">
                <CampoClave id="pwd-actual" etiqueta="Contraseña actual" autoComplete="current-password"
                  valor={form.passwordActual} onChange={(v) => setForm({ ...form, passwordActual: v })} />
                <CampoClave id="pwd-nueva" etiqueta="Nueva contraseña" autoComplete="new-password" minLength="8"
                  valor={form.passwordNueva} onChange={(v) => setForm({ ...form, passwordNueva: v })} />
                <CampoClave id="pwd-confirmar" etiqueta="Confirmar nueva contraseña" autoComplete="new-password" minLength="8"
                  valor={form.confirmar} onChange={(v) => setForm({ ...form, confirmar: v })} />
              </div>
              <aside className="cu-reglas">
                <div className="cu-fuerza" data-nivel={fuerza.nivel}>
                  <div className="cu-fuerza-barras"><span /><span /><span /><span /></div>
                  <small>{fuerza.texto ? `Seguridad: ${fuerza.texto}` : 'Escriba la nueva contraseña'}</small>
                </div>
                <ul>
                  {reglas.map((r) => (
                    <li key={r.texto} className={r.ok ? 'ok' : ''}>
                      <MenuIcon name={r.ok ? 'check' : 'lock'} size={14} /> {r.texto}
                    </li>
                  ))}
                </ul>
                <button type="submit" className="btn-primary" disabled={saving}>
                  {saving ? 'Actualizando…' : 'Cambiar contraseña'}
                </button>
              </aside>
            </form>
          </section>
        </div>

        <aside className="cu-col">
          {/* ── Rol y permisos ─────────────────────────────────── */}
          <section className="cu-card">
            <header className="cu-card-head">
              <span className={`cu-card-icono ${infoRol.tono}`}><MenuIcon name="shield" size={18} /></span>
              <div>
                <h3>Mi rol</h3>
                <p>{rolLegible}</p>
              </div>
            </header>
            <p className="cu-rol-resumen">{infoRol.resumen}</p>
            <ul className="cu-alcance">
              {infoRol.alcance.map((a) => <li key={a}><MenuIcon name="check" size={14} /> {a}</li>)}
            </ul>
            {modulos.length > 0 && (
              <>
                <h4 className="cu-subtitulo">Módulos disponibles <span>{modulos.length}</span></h4>
                <div className="cu-modulos">
                  {modulos.map((m) => (
                    <button key={m.key} type="button" className="cu-modulo" onClick={() => onIrA?.(m.key)} style={{ '--cu-color': m.color }}>
                      <span className="cu-modulo-icono"><MenuIcon name={m.icon} size={15} /></span>
                      <span>{m.label}</span>
                    </button>
                  ))}
                </div>
              </>
            )}
          </section>

          {/* ── Sesión actual ──────────────────────────────────── */}
          <section className="cu-card">
            <header className="cu-card-head">
              <span className="cu-card-icono tinta"><MenuIcon name="lock" size={18} /></span>
              <div>
                <h3>Sesión actual</h3>
                <p>Se renueva sola mientras la aplicación siga abierta.</p>
              </div>
            </header>
            <dl className="cu-datos una">
              <Dato etiqueta="Inicio de sesión">{token.emitido ? `${fmtFecha.format(token.emitido)}, ${fmtHora.format(token.emitido)}` : '—'}</Dato>
              <Dato etiqueta="Vence sin actividad">{token.vence ? fmtHora.format(token.vence) : '—'}</Dato>
              <Dato etiqueta="Dispositivo">{navigator.userAgent.includes('Mobile') ? 'Navegador móvil' : 'Navegador de escritorio'}</Dato>
            </dl>
            <p className="cu-nota">
              <MenuIcon name="alert" size={14} /> Si usa un equipo compartido, cierre sesión al terminar. Al volver a entrar se abrirá la pantalla inicial de su rol.
            </p>
            <button type="button" className="cu-btn-salir bloque" onClick={() => setConfirmarSalida(true)}>
              <MenuIcon name="logout" size={16} /> Cerrar sesión
            </button>
          </section>
        </aside>
      </div>

      {confirmarSalida && (
        <div className="cu-modal-fondo" role="presentation" onMouseDown={(e) => { if (e.target === e.currentTarget) setConfirmarSalida(false); }}>
          <div className="cu-modal" role="dialog" aria-modal="true" aria-labelledby="cu-modal-titulo">
            <span className="cu-modal-icono"><MenuIcon name="logout" size={22} /></span>
            <h3 id="cu-modal-titulo">¿Cerrar sesión?</h3>
            <p>Se cerrará la sesión de <strong>{session?.username}</strong> en este navegador. Para volver a entrar necesitará su usuario y contraseña.</p>
            <div className="cu-modal-acciones">
              <button type="button" className="btn-ghost" onClick={() => setConfirmarSalida(false)} autoFocus>Cancelar</button>
              <button type="button" className="cu-btn-salir" onClick={onLogout}>Cerrar sesión</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
