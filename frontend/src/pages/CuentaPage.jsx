import { useState } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';

/**
 * Página de cambio de contraseña del usuario autenticado.
 *
 * @param {{ onSessionExpired: function }} props
 */
export default function CuentaPage({ onSessionExpired }) {
  const [form, setForm] = useState({ passwordActual: '', passwordNueva: '', confirmar: '' });
  const [showActual, setShowActual] = useState(false);
  const [showNueva, setShowNueva] = useState(false);
  const [showConfirmar, setShowConfirmar] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [saving, setSaving] = useState(false);

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
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="panel form-panel password-panel">
      <div className="panel-heading">
        <div>
          <h2>Actualizar contraseña</h2>
          <p className="muted">Confirma tu contraseña actual antes de establecer una nueva.</p>
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
  );
}
