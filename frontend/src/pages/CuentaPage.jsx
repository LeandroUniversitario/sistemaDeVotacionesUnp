import { useState, useEffect } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';

const fmtFechaHora = new Intl.DateTimeFormat('es-PE', {
  day: '2-digit', month: 'short', year: 'numeric',
  hour: '2-digit', minute: '2-digit'
});

function formatFecha(value) {
  if (!value) return '—';
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? String(value) : fmtFechaHora.format(d);
}

const si = (v) => v === true || v === 1 || v === '1';

function situacionUsuario(u) {
  if (!u) return { clase: 'anulado', texto: '—', bg: '#f1f5f9', color: '#475569' };
  if (!si(u.activo)) return { clase: 'anulado', texto: 'Inactiva', bg: '#fee2e2', color: '#991b1b' };
  if (si(u.bloqueada)) return { clase: 'anulado', texto: 'Bloqueada', bg: '#fee2e2', color: '#991b1b' };
  if (si(u.debeCambiarPassword)) return { clase: 'creado', texto: 'Clave provisional', bg: '#fef3c7', color: '#92400e' };
  return { clase: 'votacion', texto: 'Activa', bg: '#dcfce7', color: '#166534' };
}

const COLOR_ROL = {
  ADMIN: { bg: '#ffe4e6', color: '#e11d48' },
  CEUNP: { bg: '#dbeafe', color: '#1d4ed8' },
  DOCENTE: { bg: '#dcfce7', color: '#15803d' },
  PERSONERO: { bg: '#fef3c7', color: '#b45309' },
  MIEMBRO_MESA: { bg: '#f3e8ff', color: '#7e22ce' },
};

/**
 * Página de visualización de datos de perfil y cambio de contraseña.
 *
 * @param {{ onSessionExpired: function }} props
 */
export default function CuentaPage({ onSessionExpired }) {
  const [perfil, setPerfil] = useState(null);
  const [cargandoPerfil, setCargandoPerfil] = useState(true);

  const [form, setForm] = useState({ passwordActual: '', passwordNueva: '', confirmar: '' });
  const [showActual, setShowActual] = useState(false);
  const [showNueva, setShowNueva] = useState(false);
  const [showConfirmar, setShowConfirmar] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function cargarPerfil() {
      try {
        const data = await apiRequest('/api/auth/me');
        setPerfil(data);
      } catch (error) {
        if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
      } finally {
        setCargandoPerfil(false);
      }
    }
    cargarPerfil();
  }, [onSessionExpired]);

  async function submit(event) {
    event.preventDefault();
    setFeedback(null);
    if (form.passwordNueva !== form.confirmar) {
      setFeedback({ type: 'error', text: 'La confirmación no coincide con la nueva contraseña.' });
      return;
    }
    setSaving(true);
    try {
      await apiRequest('/api/auth/password', {
        method: 'PATCH',
        body: JSON.stringify({
          passwordActual: form.passwordActual,
          passwordNueva: form.passwordNueva,
        }),
      });
      setForm({ passwordActual: '', passwordNueva: '', confirmar: '' });
      setFeedback({ type: 'success', text: 'Contraseña actualizada correctamente.' });
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  const estadoBadge = situacionUsuario(perfil);
  const rolStyle = COLOR_ROL[perfil?.rol] ?? { bg: '#e2e8f0', color: '#334155' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', maxWidth: 1050 }}>
      {/* ── Panel de Información de la Cuenta ── */}
      <section className="panel" style={{ padding: '1.5rem', background: '#fff', borderRadius: '14px', border: '1px solid var(--border, #e2e8f0)', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
        <div style={{ borderBottom: '1px solid var(--border, #f1f5f9)', paddingBottom: '1rem', marginBottom: '1.25rem' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0, color: 'var(--text, #0f172a)' }}>Información de la cuenta</h2>
          <p className="muted" style={{ margin: '4px 0 0 0', fontSize: '0.875rem' }}>
            Datos del usuario autenticado en el sistema y su vinculación con el padrón electoral.
          </p>
        </div>

        {cargandoPerfil ? (
          <p className="muted" style={{ padding: '1rem' }}>Cargando datos de la cuenta...</p>
        ) : perfil ? (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: '1.5rem 1.25rem' }}>
            {/* Fila 1: Cuenta */}
            <div>
              <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Usuario</span>
              <strong style={{ display: 'block', fontSize: '1.05rem', color: '#0f172a', marginTop: 5 }}>{perfil.username}</strong>
            </div>

            <div>
              <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Rol del sistema</span>
              <div style={{ marginTop: 5 }}>
                <span style={{ background: rolStyle.bg, color: rolStyle.color, padding: '3px 10px', borderRadius: '6px', fontWeight: 700, fontSize: '0.8rem', display: 'inline-block' }}>
                  {perfil.rol}
                </span>
              </div>
            </div>

            <div>
              <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Estado de la cuenta</span>
              <div style={{ marginTop: 5 }}>
                <span style={{ background: estadoBadge.bg, color: estadoBadge.color, padding: '3px 10px', borderRadius: '6px', fontWeight: 700, fontSize: '0.8rem', display: 'inline-block' }}>
                  {estadoBadge.texto}
                </span>
              </div>
            </div>

            <div>
              <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Último acceso</span>
              <span style={{ display: 'block', fontSize: '0.95rem', color: '#334155', marginTop: 5 }}>{formatFecha(perfil.ultimoAcceso)}</span>
            </div>

            {/* Datos adicionales si es Docente / Personero / Miembro de mesa vinculado */}
            {perfil.dni ? (
              <>
                <div style={{ gridColumn: 'span 4', borderTop: '1px solid #f1f5f9', paddingTop: '1rem', marginTop: '0.5rem' }}>
                  <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#334155', margin: 0 }}>Datos Institucionales del Docente</h3>
                </div>

                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>DNI</span>
                  <strong style={{ display: 'block', fontSize: '1rem', color: '#0f172a', marginTop: 5 }}>{perfil.dni}</strong>
                </div>

                <div style={{ gridColumn: 'span 2' }}>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Docente</span>
                  <strong style={{ display: 'block', fontSize: '1rem', color: '#0f172a', marginTop: 5 }}>{perfil.nombreCompleto || `${perfil.nombres} ${perfil.apellidos}`}</strong>
                </div>

                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Categoría / Dedicación</span>
                  <span style={{ display: 'block', fontSize: '0.95rem', color: '#334155', marginTop: 5 }}>
                    {perfil.categoria || '—'} {perfil.dedicacion ? `· ${perfil.dedicacion}` : ''}
                  </span>
                </div>

                <div style={{ gridColumn: 'span 2' }}>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Facultad</span>
                  <span style={{ display: 'block', fontSize: '0.95rem', color: '#334155', marginTop: 5 }}>{perfil.facultad || '—'}</span>
                </div>

                <div style={{ gridColumn: 'span 2' }}>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Departamento</span>
                  <span style={{ display: 'block', fontSize: '0.95rem', color: '#334155', marginTop: 5 }}>{perfil.departamento || '—'}</span>
                </div>

                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Grado Académico</span>
                  <span style={{ display: 'block', fontSize: '0.95rem', color: '#334155', marginTop: 5 }}>{perfil.gradoAcademico || '—'}</span>
                </div>

                <div style={{ gridColumn: 'span 2' }}>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Correo institucional</span>
                  <span style={{ display: 'block', fontSize: '0.95rem', color: '#334155', marginTop: 5 }}>{perfil.email || '—'}</span>
                </div>

                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.04em' }}>Padrón electoral</span>
                  <div style={{ marginTop: 5 }}>
                    <span style={{ background: perfil.habilitadoParaVotar ? '#dcfce7' : '#fee2e2', color: perfil.habilitadoParaVotar ? '#15803d' : '#991b1b', padding: '2px 8px', borderRadius: '4px', fontWeight: 600, fontSize: '0.8rem' }}>
                      {perfil.habilitadoParaVotar ? 'Habilitado' : 'Inhabilitado'}
                    </span>
                  </div>
                </div>
              </>
            ) : null}
          </div>
        ) : (
          <p className="muted">No se pudieron recuperar los datos de la cuenta.</p>
        )}
      </section>

      {/* ── Panel de Actualización de Contraseña ── */}
      <section className="panel form-panel password-panel" style={{ padding: '1.5rem', background: '#fff', borderRadius: '14px', border: '1px solid var(--border, #e2e8f0)', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
        <div className="panel-heading" style={{ borderBottom: '1px solid var(--border, #f1f5f9)', paddingBottom: '1rem', marginBottom: '1.25rem' }}>
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0, color: 'var(--text, #0f172a)' }}>Actualizar contraseña</h2>
            <p className="muted" style={{ margin: '4px 0 0 0', fontSize: '0.875rem' }}>Confirma tu contraseña actual antes de establecer una nueva.</p>
          </div>
        </div>
        {feedback && <div className={`alert ${feedback.type}`}>{feedback.text}</div>}
        <form className="password-form" onSubmit={submit}>
          <div className="login-field">
            <label htmlFor="pwd-actual">Contraseña actual</label>
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                id="pwd-actual"
                type={showActual ? 'text' : 'password'}
                autoComplete="current-password"
                value={form.passwordActual}
                onChange={(event) => setForm({ ...form, passwordActual: event.target.value })}
                required
              />
              <button
                type="button"
                className="toggle-password-btn"
                onMouseDown={e => e.preventDefault()}
                onClick={() => setShowActual(s => !s)}
                title={showActual ? 'Ocultar contraseña' : 'Ver contraseña'}
                aria-label={showActual ? 'Ocultar contraseña' : 'Ver contraseña'}
              >
                <MenuIcon name={showActual ? 'eye' : 'eye_off'} size={18} />
              </button>
            </span>
          </div>
          <div className="login-field">
            <label htmlFor="pwd-nueva">Nueva contraseña</label>
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                id="pwd-nueva"
                type={showNueva ? 'text' : 'password'}
                minLength="8"
                autoComplete="new-password"
                value={form.passwordNueva}
                onChange={(event) => setForm({ ...form, passwordNueva: event.target.value })}
                required
              />
              <button
                type="button"
                className="toggle-password-btn"
                onMouseDown={e => e.preventDefault()}
                onClick={() => setShowNueva(s => !s)}
                title={showNueva ? 'Ocultar contraseña' : 'Ver contraseña'}
                aria-label={showNueva ? 'Ocultar contraseña' : 'Ver contraseña'}
              >
                <MenuIcon name={showNueva ? 'eye' : 'eye_off'} size={18} />
              </button>
            </span>
          </div>
          <div className="login-field">
            <label htmlFor="pwd-confirmar">Confirmar nueva contraseña</label>
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                id="pwd-confirmar"
                type={showConfirmar ? 'text' : 'password'}
                minLength="8"
                autoComplete="new-password"
                value={form.confirmar}
                onChange={(event) => setForm({ ...form, confirmar: event.target.value })}
                required
              />
              <button
                type="button"
                className="toggle-password-btn"
                onMouseDown={e => e.preventDefault()}
                onClick={() => setShowConfirmar(s => !s)}
                title={showConfirmar ? 'Ocultar contraseña' : 'Ver contraseña'}
                aria-label={showConfirmar ? 'Ocultar contraseña' : 'Ver contraseña'}
              >
                <MenuIcon name={showConfirmar ? 'eye' : 'eye_off'} size={18} />
              </button>
            </span>
          </div>
          <button type="submit" disabled={saving}>{saving ? 'Actualizando...' : 'Cambiar contraseña'}</button>
        </form>
      </section>
    </div>
  );
}
