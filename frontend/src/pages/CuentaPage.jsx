import { useState } from 'react';
import { apiRequest } from '../api/apiClient';

/**
 * Página de cambio de contraseña del usuario autenticado.
 *
 * @param {{ onSessionExpired: function }} props
 */
export default function CuentaPage({ onSessionExpired }) {
  const [form, setForm] = useState({ passwordActual: '', passwordNueva: '', confirmar: '' });
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
        <label>Contraseña actual
          <input type="password" autoComplete="current-password" value={form.passwordActual}
            onChange={(event) => setForm({ ...form, passwordActual: event.target.value })} required />
        </label>
        <label>Nueva contraseña
          <input type="password" minLength="8" autoComplete="new-password" value={form.passwordNueva}
            onChange={(event) => setForm({ ...form, passwordNueva: event.target.value })} required />
        </label>
        <label>Confirmar nueva contraseña
          <input type="password" minLength="8" autoComplete="new-password" value={form.confirmar}
            onChange={(event) => setForm({ ...form, confirmar: event.target.value })} required />
        </label>
        <button type="submit" disabled={saving}>{saving ? 'Actualizando...' : 'Cambiar contraseña'}</button>
      </form>
    </section>
  );
}
