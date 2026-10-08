import { useState, useMemo, useCallback } from 'react';
import { apiRequest } from '../api/apiClient';

const CATEGORIAS = ['PRINCIPAL', 'ASOCIADO', 'AUXILIAR'];
const DEDICACIONES = ['DE', 'TC', 'TP'];
const ESTADOS = ['ACTIVO', 'LICENCIA', 'SUSPENDIDO', 'INACTIVO'];

const FORM_INIT = {
  dni: '', nombres: '', apellidos: '',
  categoria: 'PRINCIPAL', dedicacion: 'DE',
  idFacultad: '1', idDepartamento: '1',
};

const EDIT_INIT = {
  nombres: '', apellidos: '',
  categoria: 'PRINCIPAL', dedicacion: 'DE',
  estado: 'ACTIVO', idFacultad: '1', idDepartamento: '1',
};

/**
 * Página CRUD completa del Padrón de Docentes.
 * Registro manual, edición y eliminación con validaciones.
 */
export default function DocentesPage({ teachers, loading, onRefresh, canManage, onImport, onSessionExpired }) {
  const [search, setSearch]             = useState('');
  const [catFilter, setCatFilter]       = useState('TODAS');
  const [estFilter, setEstFilter]       = useState('TODOS');
  const [page, setPage]                 = useState(1);
  const PAGE_SIZE = 15;

  const [feedback, setFeedback]         = useState(null);
  const [saving, setSaving]             = useState(false);

  // ── Modal crear ──────────────────────────────────────────────────────────
  const [showCreate, setShowCreate]     = useState(false);
  const [form, setForm]                 = useState(FORM_INIT);
  const [dniWarning, setDniWarning]     = useState('');

  // ── Modal editar ─────────────────────────────────────────────────────────
  const [editDocente, setEditDocente]   = useState(null);   // docente en edición
  const [editForm, setEditForm]         = useState(EDIT_INIT);

  // ── Confirmación eliminar ────────────────────────────────────────────────
  const [deleteDocente, setDeleteDocente] = useState(null);

  // ── Modal Ver detalle ────────────────────────────────────────────────────
  const [viewDocente, setViewDocente]     = useState(null);

  // ── Filtrado ─────────────────────────────────────────────────────────────
  const filtered = useMemo(() => {
    const q = search.toLowerCase().trim();
    return teachers.filter(t => {
      const text = `${t.apellidos || ''} ${t.nombres || ''} ${t.dni || ''}`.toLowerCase();
      return (!q || text.includes(q))
        && (catFilter === 'TODAS' || t.categoria === catFilter)
        && (estFilter === 'TODOS' || t.estado === estFilter);
    });
  }, [teachers, search, catFilter, estFilter]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const currPage   = Math.min(page, totalPages);
  const paginated  = filtered.slice((currPage - 1) * PAGE_SIZE, currPage * PAGE_SIZE);

  // ── Validación DNI duplicado ──────────────────────────────────────────────
  function handleDniChange(val) {
    setForm(f => ({ ...f, dni: val }));
    if (val.length === 8) {
      const exists = teachers.some(t => t.dni === val);
      setDniWarning(exists ? 'Ya existe un docente con ese DNI.' : '');
    } else {
      setDniWarning(val.length > 0 && !/^\d*$/.test(val) ? 'El DNI solo debe contener números.' : '');
    }
  }

  // ── Crear docente ─────────────────────────────────────────────────────────
  async function handleCreate(e) {
    e.preventDefault();
    if (dniWarning) return;
    setSaving(true); setFeedback(null);
    try {
      await apiRequest('/api/docentes', {
        method: 'POST',
        body: JSON.stringify({
          ...form,
          idFacultad: Number(form.idFacultad),
          idDepartamento: Number(form.idDepartamento),
        }),
      });
      setShowCreate(false);
      setForm(FORM_INIT);
      setDniWarning('');
      setFeedback({ type: 'success', text: `✅ Docente ${form.apellidos}, ${form.nombres} registrado correctamente.` });
      onRefresh();
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  // ── Abrir modal editar ────────────────────────────────────────────────────
  function openEdit(docente) {
    setEditDocente(docente);
    setEditForm({
      nombres:       docente.nombres       || '',
      apellidos:     docente.apellidos     || '',
      categoria:     docente.categoria     || 'PRINCIPAL',
      dedicacion:    docente.dedicacion    || 'DE',
      estado:        docente.estado        || 'ACTIVO',
      idFacultad:    String(docente.idFacultad    ?? 1),
      idDepartamento: String(docente.idDepartamento ?? 1),
    });
  }

  // ── Guardar edición ───────────────────────────────────────────────────────
  async function handleEdit(e) {
    e.preventDefault();
    setSaving(true); setFeedback(null);
    try {
      await apiRequest(`/api/docentes/${editDocente.id}`, {
        method: 'PUT',
        body: JSON.stringify({
          ...editForm,
          idFacultad: Number(editForm.idFacultad),
          idDepartamento: Number(editForm.idDepartamento),
        }),
      });
      setEditDocente(null);
      setFeedback({ type: 'success', text: `✅ Docente actualizado correctamente.` });
      onRefresh();
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  // ── Eliminar docente ──────────────────────────────────────────────────────
  async function handleDelete() {
    setSaving(true); setFeedback(null);
    try {
      await apiRequest(`/api/docentes/${deleteDocente.id}`, { method: 'DELETE' });
      setDeleteDocente(null);
      setFeedback({ type: 'success', text: `✅ Docente eliminado del padrón.` });
      onRefresh();
    } catch (err) {
      setDeleteDocente(null);
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  // ── Padrón Definitivo (RF12 / Art. 18 & 27b) ─────────────────────────────
  const [padronAprobado, setPadronAprobado] = useState(() => localStorage.getItem('siceunp_padron_aprobado') === 'true');
  const [showApproveModal, setShowApproveModal] = useState(false);

  // Desglose de habilitados vs excluidos por Art. 27b
  const habilitados = useMemo(() => teachers.filter(t => t.estado === 'ACTIVO'), [teachers]);
  const excluidos   = useMemo(() => teachers.filter(t => t.estado !== 'ACTIVO'), [teachers]);

  function handleConfirmarAprobacion() {
    setPadronAprobado(true);
    localStorage.setItem('siceunp_padron_aprobado', 'true');
    setShowApproveModal(false);
    setFeedback({
      type: 'success',
      text: '🔒 Padrón Definitivo Aprobado y Publicado Oficialmente. Las modificaciones y altas de docentes han sido congeladas (RF12 / Art. 18).',
    });
  }

  function handleReabrirPadron() {
    setPadronAprobado(false);
    localStorage.removeItem('siceunp_padron_aprobado');
    setFeedback({
      type: 'success',
      text: '🔓 Padrón reabierto para ajustes por el CEUNP.',
    });
  }

  const badgeEst = { ACTIVO: 'activo', LICENCIA: 'creado', SUSPENDIDO: 'cerrado', INACTIVO: 'anulado' };

  return (
    <div className="page-container">
      {feedback && (
        <div className={`alert ${feedback.type}`} onClick={() => setFeedback(null)}>
          {feedback.text}
        </div>
      )}

      {/* ── Banner Padrón Aprobado RF12 ── */}
      {padronAprobado && (
        <div style={{
          background: 'linear-gradient(135deg, #065f46 0%, #047857 100%)',
          color: '#ffffff',
          padding: '12px 20px',
          borderRadius: '10px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '15px',
          boxShadow: '0 4px 12px rgba(4, 120, 87, 0.25)',
        }}>
          <div>
            <strong>🔒 Padrón Definitivo Aprobado y Congelado (RF12)</strong>
            <p style={{ margin: 0, fontSize: '0.85rem', opacity: 0.9 }}>
              {habilitados.length} Docentes Habilitados con derecho a voto · {excluidos.length} Excluidos por Art. 27b (Licencias / Inactivos)
            </p>
          </div>
          {canManage && (
            <button
              onClick={handleReabrirPadron}
              style={{
                background: 'rgba(255,255,255,0.2)',
                border: '1px solid rgba(255,255,255,0.4)',
                color: '#fff',
                padding: '6px 14px',
                borderRadius: '6px',
                cursor: 'pointer',
                fontWeight: 600,
                fontSize: '0.8rem',
              }}
            >
              🔓 Reabrir Padrón
            </button>
          )}
        </div>
      )}

      {/* ── Cabecera con acciones ── */}
      <div className="page-header">
        <p className="page-subtitle">
          {filtered.length} de {teachers.length} docentes · Padrón electoral
        </p>
        {canManage && (
          <div style={{ display: 'flex', gap: '10px' }}>
            {!padronAprobado ? (
              <>
                <button className="btn-ghost" onClick={onImport}>
                  ⬆ Importar Excel/CSV
                </button>
                <button className="btn-primary" onClick={() => { setShowCreate(true); setFeedback(null); }}>
                  ＋ Nuevo docente
                </button>
                <button
                  style={{
                    background: '#10b981',
                    color: '#fff',
                    border: 'none',
                    padding: '8px 16px',
                    borderRadius: '8px',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                  onClick={() => setShowApproveModal(true)}
                >
                  ✔ Aprobar Padrón Definitivo
                </button>
              </>
            ) : (
              <span style={{
                background: '#ecfdf5',
                color: '#047857',
                border: '1px solid #a7f3d0',
                padding: '6px 14px',
                borderRadius: '8px',
                fontWeight: 600,
                fontSize: '0.85rem',
              }}>
                ✓ Padrón Definitivo Vigente
              </span>
            )}
          </div>
        )}
      </div>

      {/* ── Barra de filtros ── */}
      <div className="filter-bar">
        <div className="search-box">
          <span className="search-icon">🔍</span>
          <input
            type="text"
            placeholder="Buscar por DNI, nombres o apellidos..."
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
          />
          {search && <button className="clear-btn" onClick={() => { setSearch(''); setPage(1); }}>✕</button>}
        </div>
        <select value={catFilter} onChange={e => { setCatFilter(e.target.value); setPage(1); }} className="filter-select">
          <option value="TODAS">Todas las categ.</option>
          {CATEGORIAS.map(c => <option key={c}>{c}</option>)}
        </select>
        <select value={estFilter} onChange={e => { setEstFilter(e.target.value); setPage(1); }} className="filter-select">
          <option value="TODOS">Todos los estados</option>
          {ESTADOS.map(e => <option key={e}>{e}</option>)}
        </select>
        {totalPages > 1 && (
          <span className="result-count">Pág. {currPage}/{totalPages}</span>
        )}
      </div>

      {/* ── Tabla ── */}
      <div className="panel">
        {loading ? (
          <p className="empty-state">Cargando padrón…</p>
        ) : !paginated.length ? (
          <p className="empty-state">No se encontraron docentes con los criterios aplicados.</p>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Docente</th>
                  <th>DNI</th>
                  <th>Categoría</th>
                  <th>Dedicación</th>
                  <th>Estado</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {paginated.map(t => (
                  <tr key={t.id || t.dni} style={{ cursor: 'pointer' }} onClick={() => setViewDocente(t)}>
                    <td><strong>{t.apellidos}, {t.nombres}</strong></td>
                    <td><code style={{ background: '#f1f5f9', padding: '2px 6px', borderRadius: 5 }}>{t.dni}</code></td>
                    <td>
                      <span className={`badge ${{ PRINCIPAL: 'creado', ASOCIADO: 'votacion', AUXILIAR: 'cerrado' }[t.categoria] || ''}`}>
                        {t.categoria}
                      </span>
                    </td>
                    <td><span className="badge">{t.dedicacion}</span></td>
                    <td>
                      <span className={`badge ${badgeEst[t.estado] || ''}`}>{t.estado}</span>
                      {padronAprobado && (
                        t.estado === 'ACTIVO' ? (
                          <span style={{ background: '#dcfce7', color: '#15803d', fontSize: '0.72rem', fontWeight: 700, padding: '2px 8px', borderRadius: 4, marginLeft: 6 }}>
                            ✓ HABILITADO
                          </span>
                        ) : (
                          <span style={{ background: '#fee2e2', color: '#b91c1c', fontSize: '0.72rem', fontWeight: 700, padding: '2px 8px', borderRadius: 4, marginLeft: 6 }}>
                            ⚠ EXCLUIDO (Art. 27b)
                          </span>
                        )
                      )}
                    </td>
                    <td onClick={e => e.stopPropagation()}>
                      <div className="action-cell">
                        <button
                          className="icon-btn"
                          title="Ver detalles"
                          onClick={() => setViewDocente(t)}
                        >👁️</button>
                        {canManage && !padronAprobado && (
                          <>
                            <button
                              className="icon-btn"
                              title="Editar docente"
                              onClick={() => openEdit(t)}
                            >✏️</button>
                            <button
                              className="icon-btn danger"
                              title="Eliminar docente"
                              onClick={() => setDeleteDocente(t)}
                            >🗑️</button>
                          </>
                        )}
                        {canManage && padronAprobado && (
                          <span title="Bloqueado por Padrón Definitivo (RF12)" style={{ opacity: 0.6, fontSize: '0.8rem', fontStyle: 'italic', color: '#64748b' }}>
                            🔒 Edición bloqueada (RF12)
                          </span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Paginación */}
        {totalPages > 1 && (
          <div className="pagination">
            <button className="page-btn" disabled={currPage === 1} onClick={() => setPage(p => p - 1)}>◀ Ant.</button>
            <span>{currPage} de {totalPages}</span>
            <button className="page-btn" disabled={currPage === totalPages} onClick={() => setPage(p => p + 1)}>Sig. ▶</button>
          </div>
        )}
      </div>

      {/* ═══════════ MODAL CREAR DOCENTE ═══════════ */}
      {showCreate && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setShowCreate(false)}>
          <div className="modal-card">
            <div className="modal-header">
              <h2>Registrar nuevo docente</h2>
              <button className="modal-close" onClick={() => setShowCreate(false)}>✕</button>
            </div>
            <form className="modal-form" onSubmit={handleCreate}>
              <div className="form-row">
                <label>DNI <span className="required-mark">*</span>
                  <input
                    maxLength={8} placeholder="12345678"
                    value={form.dni}
                    onChange={e => handleDniChange(e.target.value)}
                    required
                  />
                  {dniWarning && <span className="field-warning">{dniWarning}</span>}
                </label>
              </div>
              <div className="form-row">
                <label>Nombres <span className="required-mark">*</span>
                  <input value={form.nombres} onChange={e => setForm(f => ({ ...f, nombres: e.target.value }))} required />
                </label>
                <label>Apellidos <span className="required-mark">*</span>
                  <input value={form.apellidos} onChange={e => setForm(f => ({ ...f, apellidos: e.target.value }))} required />
                </label>
              </div>
              <div className="form-row">
                <label>Categoría <span className="required-mark">*</span>
                  <select value={form.categoria} onChange={e => setForm(f => ({ ...f, categoria: e.target.value }))}>
                    {CATEGORIAS.map(c => <option key={c}>{c}</option>)}
                  </select>
                </label>
                <label>Dedicación <span className="required-mark">*</span>
                  <select value={form.dedicacion} onChange={e => setForm(f => ({ ...f, dedicacion: e.target.value }))}>
                    {DEDICACIONES.map(d => <option key={d}>{d}</option>)}
                  </select>
                </label>
              </div>
              <div className="form-row">
                <label>ID Facultad
                  <input type="number" min="1" value={form.idFacultad}
                    onChange={e => setForm(f => ({ ...f, idFacultad: e.target.value }))} required />
                </label>
                <label>ID Departamento
                  <input type="number" min="1" value={form.idDepartamento}
                    onChange={e => setForm(f => ({ ...f, idDepartamento: e.target.value }))} required />
                </label>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-ghost" onClick={() => setShowCreate(false)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={saving || !!dniWarning}>
                  {saving ? 'Guardando…' : '✅ Registrar docente'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ═══════════ MODAL EDITAR DOCENTE ═══════════ */}
      {editDocente && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setEditDocente(null)}>
          <div className="modal-card">
            <div className="modal-header">
              <h2>Editar docente — DNI {editDocente.dni}</h2>
              <button className="modal-close" onClick={() => setEditDocente(null)}>✕</button>
            </div>
            <form className="modal-form" onSubmit={handleEdit}>
              <div className="form-row">
                <label>Nombres
                  <input value={editForm.nombres} onChange={e => setEditForm(f => ({ ...f, nombres: e.target.value }))} required />
                </label>
                <label>Apellidos
                  <input value={editForm.apellidos} onChange={e => setEditForm(f => ({ ...f, apellidos: e.target.value }))} required />
                </label>
              </div>
              <div className="form-row">
                <label>Categoría
                  <select value={editForm.categoria} onChange={e => setEditForm(f => ({ ...f, categoria: e.target.value }))}>
                    {CATEGORIAS.map(c => <option key={c}>{c}</option>)}
                  </select>
                </label>
                <label>Dedicación
                  <select value={editForm.dedicacion} onChange={e => setEditForm(f => ({ ...f, dedicacion: e.target.value }))}>
                    {DEDICACIONES.map(d => <option key={d}>{d}</option>)}
                  </select>
                </label>
              </div>
              <div className="form-row">
                <label>Estado
                  <select value={editForm.estado} onChange={e => setEditForm(f => ({ ...f, estado: e.target.value }))}>
                    {ESTADOS.map(e => <option key={e}>{e}</option>)}
                  </select>
                </label>
                <label>ID Facultad
                  <input type="number" min="1" value={editForm.idFacultad}
                    onChange={e => setEditForm(f => ({ ...f, idFacultad: e.target.value }))} required />
                </label>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-ghost" onClick={() => setEditDocente(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={saving}>
                  {saving ? 'Guardando…' : '💾 Guardar cambios'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ═══════════ MODAL CONFIRMAR ELIMINACIÓN ═══════════ */}
      {deleteDocente && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setDeleteDocente(null)}>
          <div className="modal-card small">
            <div className="modal-header">
              <h2>Confirmar eliminación</h2>
              <button className="modal-close" onClick={() => setDeleteDocente(null)}>✕</button>
            </div>
            <div className="modal-form">
              <p style={{ margin: '0 0 8px', color: '#364358' }}>
                ¿Estás seguro de que deseas eliminar al docente:
              </p>
              <p style={{ margin: '0 0 16px', fontWeight: 800, color: '#172033', fontSize: '1rem' }}>
                {deleteDocente.apellidos}, {deleteDocente.nombres}
              </p>
              <div className="immutable-notice" style={{ marginBottom: '16px' }}>
                <span>⚠️</span>
                <span>Esta acción no se puede deshacer. Si el docente tiene candidaturas asociadas, la eliminación será rechazada.</span>
              </div>
              <div className="modal-actions">
                <button className="btn-ghost" onClick={() => setDeleteDocente(null)}>Cancelar</button>
                <button
                  className="btn-primary"
                  style={{ background: '#dc2626' }}
                  disabled={saving}
                  onClick={handleDelete}
                >
                  {saving ? 'Eliminando…' : '🗑️ Sí, eliminar'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ═════════ MODAL VER DETALLE ═════════ */}
      {viewDocente && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setViewDocente(null)}>
          <div className="modal-card" style={{ maxWidth: 520 }}>
            <div className="modal-header">
              <h2 style={{ fontSize: '1rem' }}>Ficha del docente</h2>
              <button className="modal-close" onClick={() => setViewDocente(null)}>✕</button>
            </div>
            <div className="modal-form" style={{ paddingTop: 8 }}>
              {/* Cabecera del perfil */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '12px 0 20px', borderBottom: '1px solid #e3e9f1', marginBottom: 16 }}>
                <div style={{
                  width: 58, height: 58, borderRadius: 14,
                  background: 'linear-gradient(135deg, #1e5590, #073d70)',
                  display: 'grid', placeItems: 'center',
                  color: '#fff', fontSize: '1.4rem', fontWeight: 800, flexShrink: 0
                }}>
                  {(viewDocente.apellidos || '?')[0]}
                </div>
                <div>
                  <p style={{ margin: 0, fontWeight: 800, fontSize: '1.05rem', color: '#172033' }}>
                    {viewDocente.apellidos}, {viewDocente.nombres}
                  </p>
                  <p style={{ margin: '4px 0 0', color: '#6c788b', fontSize: '.88rem' }}>
                    DNI: <strong style={{ color: '#172033', fontFamily: 'monospace' }}>{viewDocente.dni}</strong>
                  </p>
                </div>
                <div style={{ marginLeft: 'auto' }}>
                  <span className={`badge ${badgeEst[viewDocente.estado] || ''}`} style={{ fontSize: '.78rem', padding: '5px 12px' }}>
                    {viewDocente.estado}
                  </span>
                </div>
              </div>

              {/* Grid de datos */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 20px' }}>
                {[
                  { label: 'Categoría', value: viewDocente.categoria },
                  { label: 'Dedicación', value: viewDocente.dedicacion },
                  { label: 'ID Facultad', value: viewDocente.idFacultad ?? '—' },
                  { label: 'ID Departamento', value: viewDocente.idDepartamento ?? '—' },
                  { label: 'Habilitado para votar', value: viewDocente.habilitadoParaVotar ? '✅ Sí' : '❌ No' },
                  { label: 'ID interno', value: `#${viewDocente.id}` },
                ].map(({ label, value }) => (
                  <div key={label} style={{ background: '#f8fafc', borderRadius: 10, padding: '10px 14px', border: '1px solid #e3e9f1' }}>
                    <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#8995a6', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                      {label}
                    </span>
                    <span style={{ display: 'block', fontWeight: 700, color: '#172033', marginTop: 3, fontSize: '.95rem' }}>
                      {value}
                    </span>
                  </div>
                ))}
              </div>

              <div className="modal-actions" style={{ marginTop: 20 }}>
                {canManage && !padronAprobado && (
                  <button className="btn-ghost" onClick={() => { setViewDocente(null); openEdit(viewDocente); }}>
                    ✏️ Editar
                  </button>
                )}
                <button className="btn-primary" onClick={() => setViewDocente(null)}>Cerrar</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ═══════════ MODAL APROBAR PADRÓN DEFINITIVO (RF12 / Art. 18 & 27b) ═══════════ */}
      {showApproveModal && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setShowApproveModal(false)}>
          <div className="modal-card" style={{ maxWidth: 560 }}>
            <div className="modal-header">
              <h2>Aprobar Padrón Definitivo (Art. 18 / RF12)</h2>
              <button className="modal-close" onClick={() => setShowApproveModal(false)}>✕</button>
            </div>
            <div className="modal-form">
              <p style={{ color: '#475569', fontSize: '0.92rem', marginBottom: 16 }}>
                Se procederá a la publicación formal del padrón electoral definitivo para el proceso activo. Por normativa, este acto realiza la depuración de la lista de votantes:
              </p>

              {/* Resumen Habilitados vs Excluidos */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
                <div style={{ background: '#f0fdf4', border: '1px solid #bbf7d0', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: '0.75rem', fontWeight: 700, color: '#166534', textTransform: 'uppercase' }}>
                    ✓ Habilitados (Art. 12d)
                  </div>
                  <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#15803d', marginTop: 4 }}>
                    {habilitados.length}
                  </div>
                  <span style={{ fontSize: '0.78rem', color: '#166534' }}>Docentes Activos con derecho a voto</span>
                </div>

                <div style={{ background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 10, padding: 14 }}>
                  <div style={{ fontSize: '0.75rem', fontWeight: 700, color: '#991b1b', textTransform: 'uppercase' }}>
                    ⚠ Excluidos (Art. 27b)
                  </div>
                  <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#b91c1c', marginTop: 4 }}>
                    {excluidos.length}
                  </div>
                  <span style={{ fontSize: '0.78rem', color: '#991b1b' }}>Docentes con Licencia / Inactivos</span>
                </div>
              </div>

              {/* Advertencia RF12 */}
              <div style={{ background: '#fffbeb', border: '1px solid #fef3c7', borderRadius: 10, padding: 12, fontSize: '0.85rem', color: '#92400e', marginBottom: 20 }}>
                <strong>⚠️ Regla RF12 (Congelamiento de Padrón):</strong>
                <p style={{ margin: '4px 0 0', lineHeight: 1.4 }}>
                  Una vez confirmado, el padrón definitivo quedará oficialmente cerrado. <strong>No se permitirán más ediciones, altas ni bajas de docentes</strong> para garantizar la seguridad y transparencia del sufragio.
                </p>
              </div>

              <div className="modal-actions">
                <button type="button" className="btn-ghost" onClick={() => setShowApproveModal(false)}>
                  Cancelar
                </button>
                <button
                  type="button"
                  style={{
                    background: '#10b981',
                    color: '#fff',
                    border: 'none',
                    padding: '10px 20px',
                    borderRadius: '8px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                  onClick={handleConfirmarAprobacion}
                >
                  🔒 Confirmar y Aprobar Padrón
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
