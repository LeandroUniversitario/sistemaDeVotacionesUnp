import { useEffect, useState } from 'react';
import { apiRequest } from '../api/apiClient';

const FORM_INIT = {
  nombreCargo: '',
  nivel: 'UNIVERSIDAD',
  activo: true
};

export default function CargosExcluidosPage({ canManage, onSessionExpired }) {
  const [cargos, setCargos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState(null);
  const [saving, setSaving] = useState(false);

  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState(FORM_INIT);

  const [editCargo, setEditCargo] = useState(null);
  const [editForm, setEditForm] = useState(FORM_INIT);
  const [deleteCargo, setDeleteCargo] = useState(null);

  async function loadCargos() {
    setLoading(true);
    try {
      const data = await apiRequest('/api/cargos-excluidos');
      setCargos(data);
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadCargos(); }, []);

  async function handleCreate(e) {
    e.preventDefault();
    setSaving(true); setFeedback(null);
    try {
      await apiRequest('/api/cargos-excluidos', {
        method: 'POST',
        body: JSON.stringify(form)
      });
      setShowCreate(false);
      setForm(FORM_INIT);
      setFeedback({ type: 'success', text: `✅ Cargo excluido agregado correctamente.` });
      loadCargos();
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  function openEdit(cargo) {
    setEditCargo(cargo);
    setEditForm({
      nombreCargo: cargo.nombreCargo,
      nivel: cargo.nivel,
      activo: cargo.activo
    });
  }

  async function handleEdit(e) {
    e.preventDefault();
    setSaving(true); setFeedback(null);
    try {
      await apiRequest(`/api/cargos-excluidos/${editCargo.id}`, {
        method: 'PUT',
        body: JSON.stringify(editForm)
      });
      setEditCargo(null);
      setFeedback({ type: 'success', text: `✅ Cargo actualizado correctamente.` });
      loadCargos();
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    setSaving(true); setFeedback(null);
    try {
      await apiRequest(`/api/cargos-excluidos/${deleteCargo.id}`, { method: 'DELETE' });
      setDeleteCargo(null);
      setFeedback({ type: 'success', text: `✅ Cargo eliminado correctamente.` });
      loadCargos();
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="page-container">
      {feedback && (
        <div className={`alert ${feedback.type}`} onClick={() => setFeedback(null)}>
          {feedback.text}
        </div>
      )}

      <div className="page-header">
        <p className="page-subtitle">Gestión de cargos excluidos del sorteo de miembros de mesa</p>
        {canManage && (
          <button className="btn-primary" onClick={() => { setShowCreate(true); setFeedback(null); }}>
            ＋ Agregar cargo
          </button>
        )}
      </div>

      <div className="panel">
        {loading ? (
          <p className="empty-state">Cargando cargos excluidos…</p>
        ) : cargos.length === 0 ? (
          <p className="empty-state">No hay cargos excluidos configurados.</p>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Nombre del Cargo</th>
                  <th>Nivel</th>
                  <th>Estado</th>
                  {canManage && <th>Acciones</th>}
                </tr>
              </thead>
              <tbody>
                {cargos.map(c => (
                  <tr key={c.id}>
                    <td>#{c.id}</td>
                    <td><strong>{c.nombreCargo}</strong></td>
                    <td><span className="badge">{c.nivel}</span></td>
                    <td>
                      <span className={`badge ${c.activo ? 'creado' : 'anulado'}`}>
                        {c.activo ? 'ACTIVO' : 'INACTIVO'}
                      </span>
                    </td>
                    {canManage && (
                      <td>
                        <div className="action-cell">
                          <button className="icon-btn" title="Editar" onClick={() => openEdit(c)}>✏️</button>
                          <button className="icon-btn danger" title="Eliminar" onClick={() => setDeleteCargo(c)}>🗑️</button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showCreate && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setShowCreate(false)}>
          <div className="modal-card">
            <div className="modal-header">
              <h2>Agregar cargo excluido</h2>
              <button className="modal-close" onClick={() => setShowCreate(false)}>✕</button>
            </div>
            <form className="modal-form" onSubmit={handleCreate}>
              <div className="form-row">
                <label>Nombre del cargo (Ej: Rector, Decano) <span className="required-mark">*</span>
                  <input value={form.nombreCargo} onChange={e => setForm(f => ({ ...f, nombreCargo: e.target.value }))} required />
                </label>
              </div>
              <div className="form-row">
                <label>Nivel <span className="required-mark">*</span>
                  <select value={form.nivel} onChange={e => setForm(f => ({ ...f, nivel: e.target.value }))}>
                    <option value="UNIVERSIDAD">Universidad</option>
                    <option value="FACULTAD">Facultad</option>
                  </select>
                </label>
                <label>Estado <span className="required-mark">*</span>
                  <select value={form.activo ? 'ACTIVO' : 'INACTIVO'} onChange={e => setForm(f => ({ ...f, activo: e.target.value === 'ACTIVO' }))}>
                    <option value="ACTIVO">Activo</option>
                    <option value="INACTIVO">Inactivo</option>
                  </select>
                </label>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-ghost" onClick={() => setShowCreate(false)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={saving}>
                  {saving ? 'Guardando…' : '✅ Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {editCargo && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setEditCargo(null)}>
          <div className="modal-card">
            <div className="modal-header">
              <h2>Editar cargo excluido</h2>
              <button className="modal-close" onClick={() => setEditCargo(null)}>✕</button>
            </div>
            <form className="modal-form" onSubmit={handleEdit}>
              <div className="form-row">
                <label>Nombre del cargo <span className="required-mark">*</span>
                  <input value={editForm.nombreCargo} onChange={e => setEditForm(f => ({ ...f, nombreCargo: e.target.value }))} required />
                </label>
              </div>
              <div className="form-row">
                <label>Nivel <span className="required-mark">*</span>
                  <select value={editForm.nivel} onChange={e => setEditForm(f => ({ ...f, nivel: e.target.value }))}>
                    <option value="UNIVERSIDAD">Universidad</option>
                    <option value="FACULTAD">Facultad</option>
                  </select>
                </label>
                <label>Estado <span className="required-mark">*</span>
                  <select value={editForm.activo ? 'ACTIVO' : 'INACTIVO'} onChange={e => setEditForm(f => ({ ...f, activo: e.target.value === 'ACTIVO' }))}>
                    <option value="ACTIVO">Activo</option>
                    <option value="INACTIVO">Inactivo</option>
                  </select>
                </label>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-ghost" onClick={() => setEditCargo(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={saving}>
                  {saving ? 'Guardando…' : '💾 Guardar cambios'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {deleteCargo && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setDeleteCargo(null)}>
          <div className="modal-card small">
            <div className="modal-header">
              <h2>Eliminar cargo</h2>
              <button className="modal-close" onClick={() => setDeleteCargo(null)}>✕</button>
            </div>
            <div className="modal-form">
              <p>¿Estás seguro de que deseas eliminar el cargo <strong>{deleteCargo.nombreCargo}</strong> de las exclusiones?</p>
              <div className="modal-actions" style={{ marginTop: '20px' }}>
                <button className="btn-ghost" onClick={() => setDeleteCargo(null)}>Cancelar</button>
                <button className="btn-primary" style={{ background: '#dc2626' }} disabled={saving} onClick={handleDelete}>
                  {saving ? 'Eliminando…' : '🗑️ Eliminar'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
