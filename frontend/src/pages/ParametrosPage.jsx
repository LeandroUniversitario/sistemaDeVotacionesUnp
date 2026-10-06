import { useEffect, useState } from 'react';
import { apiRequest } from '../api/apiClient';

const LABELS = {
  UIT: { label: 'Valor de la UIT vigente (S/.)', icon: '💵', desc: 'Unidad Impositiva Tributaria vigente' },
  MULTA_ELECTOR_OMISO_PCT: { label: 'Multa elector omiso (%)', icon: '📋', desc: 'Porcentaje de la UIT para electores que no voten' },
  MULTA_MIEMBRO_MESA_OMISO_PCT: { label: 'Multa miembro de mesa omiso (%)', icon: '⚖️', desc: 'Porcentaje de la UIT para miembros que no asistan' },
};

/**
 * Página de configuración de Parámetros Globales — ETAPA 2.
 * Solo accesible para el rol ADMIN.
 */
export default function ParametrosPage({ onSessionExpired }) {
  const [params, setParams]   = useState({});
  const [form, setForm]       = useState({});
  const [feedback, setFeedback] = useState(null);
  const [saving, setSaving]   = useState(false);
  const [changed, setChanged] = useState(false);

  async function loadParams() {
    try {
      const data = await apiRequest('/api/parametros');
      const map = {};
      data.forEach(p => { map[p.clave] = p.valor; });
      setParams(map);
      setForm(map);
      setChanged(false);
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    }
  }

  useEffect(() => { loadParams(); }, []);

  function handleChange(clave, valor) {
    const next = { ...form, [clave]: valor };
    setForm(next);
    setChanged(JSON.stringify(next) !== JSON.stringify(params));
  }

  function validate() {
    for (const clave of Object.keys(form)) {
      const val = parseFloat(form[clave]);
      if (isNaN(val) || val < 0) {
        return `El valor de ${LABELS[clave]?.label || clave} debe ser un número positivo`;
      }
      if ((clave.includes('_PCT')) && val > 100) {
        return `El porcentaje de ${LABELS[clave]?.label || clave} no puede superar 100%`;
      }
    }
    return null;
  }

  async function guardar(e) {
    e.preventDefault();
    const error = validate();
    if (error) { setFeedback({ type: 'error', text: error }); return; }
    setSaving(true);
    setFeedback(null);
    try {
      await apiRequest('/api/parametros', {
        method: 'PUT',
        body: JSON.stringify(form),
      });
      setFeedback({ type: 'success', text: '✅ Parámetros guardados. El cambio ha sido registrado en la bitácora.' });
      await loadParams();
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  // Calcular multas en soles a modo de preview
  const uit = parseFloat(form['UIT']) || 0;
  const pctElector = parseFloat(form['MULTA_ELECTOR_OMISO_PCT']) || 0;
  const pctMiembro = parseFloat(form['MULTA_MIEMBRO_MESA_OMISO_PCT']) || 0;

  return (
    <div className="page-container">
      {feedback && (
        <div className={`alert ${feedback.type}`} onClick={() => setFeedback(null)}>
          {feedback.text}
        </div>
      )}

      <div className="params-grid">
        {/* ── Formulario ── */}
        <form className="panel params-form" onSubmit={guardar}>
          <div className="panel-heading">
            <div>
              <h2>Valores vigentes</h2>
              <p className="muted">Los cambios quedan registrados automáticamente en la bitácora de auditoría.</p>
            </div>
          </div>

          {Object.keys(LABELS).map(clave => (
            <div className="param-field" key={clave}>
              <div className="param-icon">{LABELS[clave].icon}</div>
              <div className="param-info">
                <label htmlFor={clave}>{LABELS[clave].label}</label>
                <span className="param-desc">{LABELS[clave].desc}</span>
              </div>
              <input
                id={clave}
                type="number"
                step="0.01"
                min="0"
                max={clave.includes('_PCT') ? 100 : undefined}
                value={form[clave] ?? ''}
                onChange={e => handleChange(clave, e.target.value)}
                className="param-input"
                required
              />
            </div>
          ))}

          <div className="form-actions">
            <button
              type="button" className="btn-ghost"
              onClick={() => { setForm(params); setChanged(false); }}
              disabled={!changed}
            >
              Descartar cambios
            </button>
            <button type="submit" className="btn-primary" disabled={saving || !changed}>
              {saving ? 'Guardando...' : '💾 Guardar parámetros'}
            </button>
          </div>
        </form>

        {/* ── Panel de preview ── */}
        <div className="panel params-preview">
          <div className="panel-heading">
            <div>
              <h2>Vista previa de multas</h2>
              <p className="muted">Cálculo en tiempo real según los valores configurados.</p>
            </div>
          </div>
          <div className="preview-card">
            <span className="preview-label">UIT vigente</span>
            <span className="preview-value">S/. {uit.toFixed(2)}</span>
          </div>
          <div className="preview-card warn">
            <span className="preview-label">📋 Multa elector omiso</span>
            <span className="preview-value">
              S/. {(uit * pctElector / 100).toFixed(2)}
              <small> ({pctElector}% de la UIT)</small>
            </span>
          </div>
          <div className="preview-card danger">
            <span className="preview-label">⚖️ Multa miembro de mesa omiso</span>
            <span className="preview-value">
              S/. {(uit * pctMiembro / 100).toFixed(2)}
              <small> ({pctMiembro}% de la UIT)</small>
            </span>
          </div>
          <div className="preview-note">
            <strong>Nota normativa:</strong> Las multas se calculan como porcentaje de la UIT
            conforme al Estatuto Electoral UNP. Solo el ADMIN puede modificar estos valores.
          </div>
        </div>
      </div>
    </div>
  );
}
