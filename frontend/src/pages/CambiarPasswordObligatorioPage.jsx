import { useState } from 'react';
import MenuIcon from '../components/MenuIcon';

/**
 * Pantalla de cambio de contraseña OBLIGATORIO para docentes importados masivamente y para las
 * cuentas que el Admin crea o restablece con una contraseña provisional (CUS18).
 *
 * Se muestra ANTES del dashboard cuando debeCambiarPassword === true.
 * El docente no puede saltarse esta pantalla: el backend limpia el flag
 * al cambiar la clave (cambiarPassword() en Usuario.java).
 *
 * @param {{ token: string, username: string, onCambiado: function, onLogout: function }} props
 */
export default function CambiarPasswordObligatorioPage({ token, username, onCambiado, onLogout }) {
  const [form, setForm] = useState({ passwordActual: '', passwordNueva: '', confirmar: '' });
  const [showActual, setShowActual]     = useState(false);
  const [showNueva, setShowNueva]       = useState(false);
  const [showConfirmar, setShowConfirmar] = useState(false);
  const [error, setError]   = useState('');
  const [saving, setSaving] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');

    if (form.passwordNueva.length < 8) {
      setError('La nueva contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (form.passwordNueva !== form.confirmar) {
      setError('La confirmación no coincide con la nueva contraseña.');
      return;
    }
    if (form.passwordActual === form.passwordNueva) {
      setError('La nueva contraseña no puede ser igual a la provisional.');
      return;
    }

    setSaving(true);
    try {
      const resp = await fetch('/api/auth/password', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          passwordActual: form.passwordActual,
          passwordNueva:  form.passwordNueva,
        }),
      });

      if (!resp.ok) {
        let msg = 'Error al cambiar la contraseña.';
        try { const d = await resp.json(); msg = d.detail || d.message || msg; } catch(_) {}
        throw new Error(msg);
      }

      onCambiado(); // avisa al componente padre que ya puede entrar al dashboard
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="auth-shell">
      <section className="auth-card" style={{ maxWidth: 480 }}>
        <div className="auth-icon-circle" style={{ background: 'linear-gradient(135deg, #7c3aed, #a855f7)' }}>
          <MenuIcon name="lock" size={32} />
        </div>

        <h1 className="auth-system-code" style={{ fontSize: 22 }}>Cambio de contraseña requerido</h1>
        <p className="auth-title" style={{ marginBottom: 4 }}>
          Bienvenido/a, <strong>{username}</strong>
        </p>
        <p className="auth-university" style={{ fontSize: 13, marginBottom: 20 }}>
          Tu contraseña actual es provisional. Por seguridad, debes
          establecer una contraseña personal antes de continuar.
          <br />
          <em>Es la que te entregó el administrador o, si tu cuenta se creó al importar el padrón, tu DNI.</em>
        </p>

        {error && (
          <div className="alert error" role="alert" style={{ marginBottom: 16 }}>
            {error}
          </div>
        )}

        <form className="login-form" onSubmit={handleSubmit}>
          {/* Contraseña actual (DNI) */}
          <div className="login-field">
            <label htmlFor="ocp-actual">Contraseña provisional</label>
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                id="ocp-actual"
                type={showActual ? 'text' : 'password'}
                value={form.passwordActual}
                onChange={e => setForm({ ...form, passwordActual: e.target.value })}
                autoComplete="current-password"
                required
              />
              <button
                type="button"
                className="toggle-password-btn"
                onMouseDown={e => e.preventDefault()}
                onClick={() => setShowActual(s => !s)}
                title={showActual ? 'Ocultar' : 'Ver'}
              >
                <MenuIcon name={showActual ? 'eye' : 'eye_off'} size={18} />
              </button>
            </span>
          </div>

          {/* Nueva contraseña */}
          <div className="login-field">
            <label htmlFor="ocp-nueva">Nueva contraseña (mín. 8 caracteres, letras y números)</label>
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                id="ocp-nueva"
                type={showNueva ? 'text' : 'password'}
                value={form.passwordNueva}
                onChange={e => setForm({ ...form, passwordNueva: e.target.value })}
                minLength={8}
                autoComplete="new-password"
                required
              />
              <button
                type="button"
                className="toggle-password-btn"
                onMouseDown={e => e.preventDefault()}
                onClick={() => setShowNueva(s => !s)}
                title={showNueva ? 'Ocultar' : 'Ver'}
              >
                <MenuIcon name={showNueva ? 'eye' : 'eye_off'} size={18} />
              </button>
            </span>
          </div>

          {/* Confirmar */}
          <div className="login-field">
            <label htmlFor="ocp-confirmar">Confirmar nueva contraseña</label>
            <span className="input-with-icon">
              <MenuIcon name="lock" />
              <input
                id="ocp-confirmar"
                type={showConfirmar ? 'text' : 'password'}
                value={form.confirmar}
                onChange={e => setForm({ ...form, confirmar: e.target.value })}
                minLength={8}
                autoComplete="new-password"
                required
              />
              <button
                type="button"
                className="toggle-password-btn"
                onMouseDown={e => e.preventDefault()}
                onClick={() => setShowConfirmar(s => !s)}
                title={showConfirmar ? 'Ocultar' : 'Ver'}
              >
                <MenuIcon name={showConfirmar ? 'eye' : 'eye_off'} size={18} />
              </button>
            </span>
          </div>

          <button type="submit" disabled={saving}>
            <MenuIcon name="lock" />
            {saving ? 'Guardando...' : 'Establecer mi contraseña y continuar'}
          </button>
        </form>

        <button
          className="text-button"
          style={{ marginTop: 16, width: '100%', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}
          onClick={onLogout}
        >
          Cerrar sesión
        </button>
      </section>
    </main>
  );
}