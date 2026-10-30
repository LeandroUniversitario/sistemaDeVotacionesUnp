import { useState, useMemo } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';
import {
  FACULTADES,
  DEPARTAMENTOS,
  getFacultadNombre,
  getDepartamentoNombre,
  getDepartamentosPorFacultad,
} from './facultadesData';

const CATEGORIAS = ['PRINCIPAL', 'ASOCIADO', 'AUXILIAR'];
const DEDICACIONES = [
  { value: 'DE', label: 'Dedicación Exclusiva (DE)' },
  { value: 'TC', label: 'Tiempo Completo (TC)' },
  { value: 'TP', label: 'Tiempo Parcial (TP)' },
];
const ESTADOS = ['ACTIVO', 'LICENCIA', 'SUSPENDIDO', 'INACTIVO'];
const GRADOS = ['DOCTOR', 'MAGISTER', 'LICENCIADO', 'INGENIERO'];

const FORM_INIT = {
  dni: '',
  nombres: '',
  apellidos: '',
  categoria: 'PRINCIPAL',
  dedicacion: 'DE',
  estado: 'ACTIVO',
  idFacultad: 1,
  idDepartamento: 1,
  gradoAcademico: 'DOCTOR',
  email: '',
};

const EDIT_INIT = {
  nombres: '',
  apellidos: '',
  categoria: 'PRINCIPAL',
  dedicacion: 'DE',
  estado: 'ACTIVO',
  idFacultad: 1,
  idDepartamento: 1,
  gradoAcademico: 'DOCTOR',
  email: '',
};

/**
 * Página CRUD completa de Gestión de Docentes.
 * Consulta de ficha académica, edición de facultades y departamentos,
 * y administración de estados electorales.
 */
export default function DocentesPage({
  teachers = [],
  loading,
  onRefresh,
  canManage,
  onGestionarPadron,
  onSessionExpired,
}) {
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
  const [editDocente, setEditDocente]   = useState(null);
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
      return (
        (!q || text.includes(q)) &&
        (catFilter === 'TODAS' || t.categoria === catFilter) &&
        (estFilter === 'TODOS' || t.estado === estFilter)
      );
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

  // ── Manejo de cambio de Facultad en cascada ──────────────────────────────
  function handleCreateFacultadChange(newFacId) {
    const fid = Number(newFacId);
    const deps = getDepartamentosPorFacultad(fid);
    setForm(f => ({
      ...f,
      idFacultad: fid,
      idDepartamento: deps.length > 0 ? deps[0].id : 1,
    }));
  }

  function handleEditFacultadChange(newFacId) {
    const fid = Number(newFacId);
    const deps = getDepartamentosPorFacultad(fid);
    setEditForm(f => ({
      ...f,
      idFacultad: fid,
      idDepartamento: deps.length > 0 ? deps[0].id : 1,
    }));
  }

  // ── Crear docente ─────────────────────────────────────────────────────────
  async function handleCreate(e) {
    e.preventDefault();
    if (dniWarning) return;
    setSaving(true);
    setFeedback(null);
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
      setFeedback({
        type: 'success',
        text: `Docente ${form.apellidos}, ${form.nombres} registrado correctamente.`,
      });
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
    const fid = Number(docente.idFacultad) || 1;
    const deps = getDepartamentosPorFacultad(fid);
    const validDep = deps.some(d => d.id === Number(docente.idDepartamento));
    const did = validDep ? Number(docente.idDepartamento) : (deps[0]?.id ?? 1);

    setEditForm({
      nombres: docente.nombres || '',
      apellidos: docente.apellidos || '',
      categoria: docente.categoria || 'PRINCIPAL',
      dedicacion: docente.dedicacion || 'DE',
      estado: docente.estado || 'ACTIVO',
      idFacultad: fid,
      idDepartamento: did,
      gradoAcademico: docente.gradoAcademico || 'DOCTOR',
      email: docente.email || '',
    });
  }

  // ── Guardar edición ───────────────────────────────────────────────────────
  async function handleEdit(e) {
    e.preventDefault();
    setSaving(true);
    setFeedback(null);
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
      setFeedback({ type: 'success', text: `Docente actualizado correctamente.` });
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
    setSaving(true);
    setFeedback(null);
    try {
      await apiRequest(`/api/docentes/${deleteDocente.id}`, { method: 'DELETE' });
      setDeleteDocente(null);
      setFeedback({ type: 'success', text: `Docente eliminado del padrón.` });
      onRefresh();
    } catch (err) {
      setDeleteDocente(null);
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setSaving(false);
    }
  }

  const badgeEst = {
    ACTIVO: 'activo',
    LICENCIA: 'creado',
    SUSPENDIDO: 'cerrado',
    INACTIVO: 'anulado',
  };

  return (
    <div className="page-container">
      {feedback && (
        <div className={`alert ${feedback.type}`} onClick={() => setFeedback(null)}>
          {feedback.text}
        </div>
      )}

      {/* ── Barra de acciones superior ── */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18, flexWrap: 'wrap', gap: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: '.88rem', color: '#64748b' }}>
            Total registrados: <strong style={{ color: '#0f172a' }}>{teachers.length}</strong>
          </span>
          {filtered.length !== teachers.length && (
            <span style={{ fontSize: '.82rem', background: '#eff6ff', color: '#2563eb', padding: '3px 8px', borderRadius: 6, fontWeight: 600 }}>
              {filtered.length} filtrados
            </span>
          )}
        </div>

        {canManage && (
          <div style={{ display: 'flex', gap: '10px' }}>
            <button
              className="btn-primary"
              style={{ borderRadius: 8, padding: '9px 18px', fontWeight: 600 }}
              onClick={() => {
                setShowCreate(true);
                setFeedback(null);
              }}
            >
              ＋ Nuevo docente
            </button>
            {onGestionarPadron && (
              <button
                style={{
                  background: '#10b981',
                  color: '#fff',
                  border: 'none',
                  padding: '9px 18px',
                  borderRadius: '8px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                }}
                onClick={onGestionarPadron}
              >
                Gestionar padrón electoral →
              </button>
            )}
          </div>
        )}
      </div>

      {/* ── Barra de filtros ── */}
      <div className="filter-bar">
        <div className="search-box">
          <span className="search-icon"><MenuIcon name="search" size={16} /></span>
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
          {CATEGORIAS.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
        <select value={estFilter} onChange={e => { setEstFilter(e.target.value); setPage(1); }} className="filter-select">
          <option value="TODOS">Todos los estados</option>
          {ESTADOS.map(e => <option key={e} value={e}>{e}</option>)}
        </select>
        {totalPages > 1 && (
          <span className="result-count">Pág. {currPage}/{totalPages}</span>
        )}
      </div>

      {/* ── Tabla de Docentes ── */}
      <div className="panel">
        {loading ? (
          <p className="empty-state">Cargando docentes…</p>
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
                    <td>
                      <strong style={{ color: '#0f172a' }}>{t.apellidos}, {t.nombres}</strong>
                      <div style={{ fontSize: '.78rem', color: '#64748b', marginTop: 2 }}>
                        {getFacultadNombre(t.idFacultad)}
                      </div>
                    </td>
                    <td>
                      <code style={{ background: '#f1f5f9', padding: '3px 7px', borderRadius: 6, fontWeight: 700, color: '#0f172a' }}>
                        {t.dni}
                      </code>
                    </td>
                    <td>
                      <span className={`badge ${{ PRINCIPAL: 'creado', ASOCIADO: 'votacion', AUXILIAR: 'cerrado' }[t.categoria] || ''}`}>
                        {t.categoria}
                      </span>
                    </td>
                    <td>
                      <span className="badge" style={{ fontWeight: 600 }}>{t.dedicacion}</span>
                    </td>
                    <td>
                      <span className={`badge ${badgeEst[t.estado] || ''}`}>{t.estado}</span>
                    </td>
                    <td onClick={e => e.stopPropagation()}>
                      <div className="action-cell">
                        <button
                          className="icon-btn"
                          title="Ver ficha completa"
                          onClick={() => setViewDocente(t)}
                        >
                          <MenuIcon name="eye" size={14} />
                        </button>
                        {canManage && (
                          <>
                            <button
                              className="icon-btn"
                              title="Editar docente"
                              onClick={() => openEdit(t)}
                            >
                              <MenuIcon name="edit" size={14} />
                            </button>
                            <button
                              className="icon-btn danger"
                              title="Eliminar docente"
                              onClick={() => setDeleteDocente(t)}
                            >
                              <MenuIcon name="trash" size={14} />
                            </button>
                          </>
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

      {/* ═════════ MODAL NUEVO DOCENTE ═════════ */}
      {showCreate && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setShowCreate(false)}>
          <div className="modal-card" style={{ maxWidth: 620, borderRadius: 16 }}>
            <div className="modal-header">
              <h2 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Registrar nuevo docente</h2>
              <button className="modal-close" onClick={() => setShowCreate(false)}>✕</button>
            </div>
            <form className="modal-form" style={{ padding: '20px 24px 24px', display: 'flex', flexDirection: 'column', gap: 16 }} onSubmit={handleCreate}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    DNI <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <input
                    maxLength={8}
                    placeholder="8 dígitos numéricos"
                    value={form.dni}
                    onChange={e => handleDniChange(e.target.value.replace(/\D/g, ''))}
                    required
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  />
                  {dniWarning && <span style={{ fontSize: '.78rem', color: '#dc2626' }}>{dniWarning}</span>}
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Grado académico
                  </label>
                  <select
                    value={form.gradoAcademico}
                    onChange={e => setForm(f => ({ ...f, gradoAcademico: e.target.value }))}
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  >
                    {GRADOS.map(g => <option key={g} value={g}>{g}</option>)}
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Nombres <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <input
                    value={form.nombres}
                    onChange={e => setForm(f => ({ ...f, nombres: e.target.value }))}
                    required
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  />
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Apellidos <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <input
                    value={form.apellidos}
                    onChange={e => setForm(f => ({ ...f, apellidos: e.target.value }))}
                    required
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Categoría <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <select
                    value={form.categoria}
                    onChange={e => setForm(f => ({ ...f, categoria: e.target.value }))}
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  >
                    {CATEGORIAS.map(c => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Dedicación <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <select
                    value={form.dedicacion}
                    onChange={e => setForm(f => ({ ...f, dedicacion: e.target.value }))}
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  >
                    {DEDICACIONES.map(d => <option key={d.value} value={d.value}>{d.label}</option>)}
                  </select>
                </div>
              </div>

              {/* Facultad */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                  Facultad <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <select
                  value={form.idFacultad}
                  onChange={e => handleCreateFacultadChange(e.target.value)}
                  style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                >
                  {FACULTADES.map(fac => (
                    <option key={fac.id} value={fac.id}>{fac.nombre}</option>
                  ))}
                </select>
              </div>

              {/* Departamento */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                  Departamento Académico <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <select
                  value={form.idDepartamento}
                  onChange={e => setForm(f => ({ ...f, idDepartamento: Number(e.target.value) }))}
                  style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                >
                  {getDepartamentosPorFacultad(form.idFacultad).map(dep => (
                    <option key={dep.id} value={dep.id}>{dep.nombre}</option>
                  ))}
                </select>
              </div>

              <div className="modal-actions" style={{ marginTop: 10, paddingTop: 14, borderTop: '1px solid #e2e8f0' }}>
                <button type="button" className="btn-ghost" style={{ borderRadius: 8 }} onClick={() => setShowCreate(false)}>Cancelar</button>
                <button type="submit" className="btn-primary" style={{ borderRadius: 8, padding: '8px 20px' }} disabled={saving || Boolean(dniWarning) || form.dni.length !== 8}>
                  {saving ? 'Registrando…' : 'Registrar docente'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ═════════ MODAL EDITAR DOCENTE ═════════ */}
      {editDocente && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setEditDocente(null)}>
          <div className="modal-card" style={{ maxWidth: 620, borderRadius: 16 }}>
            <div className="modal-header">
              <h2 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Editar docente — DNI {editDocente.dni}</h2>
              <button className="modal-close" onClick={() => setEditDocente(null)}>✕</button>
            </div>
            <form className="modal-form" style={{ padding: '20px 24px 24px', display: 'flex', flexDirection: 'column', gap: 16 }} onSubmit={handleEdit}>
              {/* Nombres y Apellidos */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Nombres <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <input
                    value={editForm.nombres}
                    onChange={e => setEditForm(f => ({ ...f, nombres: e.target.value }))}
                    required
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  />
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Apellidos <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <input
                    value={editForm.apellidos}
                    onChange={e => setEditForm(f => ({ ...f, apellidos: e.target.value }))}
                    required
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  />
                </div>
              </div>

              {/* Categoría y Dedicación */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Categoría <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <select
                    value={editForm.categoria}
                    onChange={e => setEditForm(f => ({ ...f, categoria: e.target.value }))}
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  >
                    {CATEGORIAS.map(c => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Dedicación <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <select
                    value={editForm.dedicacion}
                    onChange={e => setEditForm(f => ({ ...f, dedicacion: e.target.value }))}
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  >
                    {DEDICACIONES.map(d => <option key={d.value} value={d.value}>{d.label}</option>)}
                  </select>
                </div>
              </div>

              {/* Estado y Grado Académico */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Estado en padrón <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <select
                    value={editForm.estado}
                    onChange={e => setEditForm(f => ({ ...f, estado: e.target.value }))}
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  >
                    {ESTADOS.map(e => <option key={e} value={e}>{e}</option>)}
                  </select>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                    Grado académico
                  </label>
                  <select
                    value={editForm.gradoAcademico}
                    onChange={e => setEditForm(f => ({ ...f, gradoAcademico: e.target.value }))}
                    style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                  >
                    {GRADOS.map(g => <option key={g} value={g}>{g}</option>)}
                  </select>
                </div>
              </div>

              {/* Facultad */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                  Facultad <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <select
                  value={editForm.idFacultad}
                  onChange={e => handleEditFacultadChange(e.target.value)}
                  style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                >
                  {FACULTADES.map(fac => (
                    <option key={fac.id} value={fac.id}>{fac.nombre}</option>
                  ))}
                </select>
              </div>

              {/* Departamento Académico (desplegable dependiente) */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                <label style={{ margin: 0, fontWeight: 600, fontSize: '.84rem', color: '#334155' }}>
                  Departamento Académico <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <select
                  value={editForm.idDepartamento}
                  onChange={e => setEditForm(f => ({ ...f, idDepartamento: Number(e.target.value) }))}
                  style={{ width: '100%', height: 42, borderRadius: 8, border: '1px solid #cbd5e1', padding: '0 12px', fontSize: '.875rem' }}
                >
                  {getDepartamentosPorFacultad(editForm.idFacultad).map(dep => (
                    <option key={dep.id} value={dep.id}>{dep.nombre}</option>
                  ))}
                </select>
              </div>

              <div className="modal-actions" style={{ marginTop: 10, paddingTop: 14, borderTop: '1px solid #e2e8f0' }}>
                <button type="button" className="btn-ghost" style={{ borderRadius: 8 }} onClick={() => setEditDocente(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" style={{ borderRadius: 8, padding: '8px 20px' }} disabled={saving}>
                  {saving ? 'Guardando…' : 'Guardar cambios'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ═══════════ MODAL CONFIRMAR ELIMINACIÓN ═══════════ */}
      {deleteDocente && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setDeleteDocente(null)}>
          <div className="modal-card small" style={{ borderRadius: 16 }}>
            <div className="modal-header">
              <h2 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Confirmar eliminación</h2>
              <button className="modal-close" onClick={() => setDeleteDocente(null)}>✕</button>
            </div>
            <div className="modal-form" style={{ padding: '20px 24px 24px' }}>
              <p style={{ margin: '0 0 8px', color: '#364358' }}>
                ¿Estás seguro de que deseas eliminar al docente:
              </p>
              <p style={{ margin: '0 0 16px', fontWeight: 800, color: '#172033', fontSize: '1.05rem' }}>
                {deleteDocente.apellidos}, {deleteDocente.nombres}
              </p>
              <div className="immutable-notice" style={{ marginBottom: '16px' }}>
                <span><MenuIcon name="alert" size={16} /></span>
                <span>Esta acción no se puede deshacer. Si el docente tiene candidaturas asociadas, la eliminación será rechazada.</span>
              </div>
              <div className="modal-actions">
                <button className="btn-ghost" style={{ borderRadius: 8 }} onClick={() => setDeleteDocente(null)}>Cancelar</button>
                <button
                  className="btn-primary"
                  style={{ background: '#dc2626', borderRadius: 8 }}
                  disabled={saving}
                  onClick={handleDelete}
                >
                  {saving ? 'Eliminando…' : 'Sí, eliminar'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ═════════ MODAL VER DETALLE (FICHA DEL DOCENTE) ═════════ */}
      {viewDocente && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setViewDocente(null)}>
          <div className="modal-card" style={{ maxWidth: 620, borderRadius: 16 }}>
            <div className="modal-header">
              <h2 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Ficha del docente</h2>
              <button className="modal-close" onClick={() => setViewDocente(null)}>✕</button>
            </div>
            <div className="modal-form" style={{ padding: '20px 24px 24px', display: 'flex', flexDirection: 'column', gap: 16 }}>
              {/* Cabecera del perfil */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                padding: '14px 18px',
                background: '#f8fafc',
                borderRadius: 12,
                border: '1px solid #e2e8f0',
              }}>
                <div style={{
                  width: 54, height: 54, borderRadius: 12,
                  background: 'linear-gradient(135deg, #1e40af, #1e293b)',
                  display: 'grid', placeItems: 'center',
                  color: '#fff', fontSize: '1.35rem', fontWeight: 800, flexShrink: 0
                }}>
                  {(viewDocente.apellidos || '?')[0]}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h3 style={{ margin: 0, fontWeight: 800, fontSize: '1.05rem', color: '#0f172a' }}>
                    {viewDocente.apellidos}, {viewDocente.nombres}
                  </h3>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 4, flexWrap: 'wrap' }}>
                    <span style={{ color: '#64748b', fontSize: '.84rem' }}>
                      DNI: <strong style={{ color: '#0f172a', fontFamily: 'monospace', fontSize: '.9rem' }}>{viewDocente.dni}</strong>
                    </span>
                    <span className={`badge ${badgeEst[viewDocente.estado] || ''}`} style={{ fontSize: '.74rem', padding: '3px 10px', textTransform: 'uppercase' }}>
                      {viewDocente.estado}
                    </span>
                    {viewDocente.habilitadoParaVotar ? (
                      <span style={{ background: '#dcfce7', color: '#166534', padding: '3px 9px', borderRadius: 12, fontSize: '.74rem', fontWeight: 700 }}>
                        ✓ Habilitado para votar
                      </span>
                    ) : (
                      <span style={{ background: '#fee2e2', color: '#991b1b', padding: '3px 9px', borderRadius: 12, fontSize: '.74rem', fontWeight: 700 }}>
                        ✕ Inhabilitado
                      </span>
                    )}
                  </div>
                </div>
              </div>

              {/* Grid completo de datos del docente */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '12px 14px' }}>
                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    Facultad
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem' }}>
                    {getFacultadNombre(viewDocente.idFacultad)}
                  </strong>
                </div>

                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    Departamento Académico
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem' }}>
                    {getDepartamentoNombre(viewDocente.idDepartamento)}
                  </strong>
                </div>

                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    Categoría
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem' }}>
                    {viewDocente.categoria}
                  </strong>
                </div>

                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    Dedicación
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem' }}>
                    {viewDocente.dedicacion === 'DE' ? 'Dedicación Exclusiva (DE)'
                      : viewDocente.dedicacion === 'TC' ? 'Tiempo Completo (TC)'
                      : viewDocente.dedicacion === 'TP' ? 'Tiempo Parcial (TP)'
                      : viewDocente.dedicacion}
                  </strong>
                </div>

                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    Grado Académico
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem' }}>
                    {viewDocente.gradoAcademico || 'No registrado'}
                  </strong>
                </div>

                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    Correo Institucional
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem', wordBreak: 'break-all' }}>
                    {viewDocente.email ? (
                      <a href={`mailto:${viewDocente.email}`} style={{ color: '#2563eb', textDecoration: 'none' }}>
                        {viewDocente.email}
                      </a>
                    ) : 'No registrado'}
                  </strong>
                </div>

                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    Fecha de Ingreso
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem' }}>
                    {viewDocente.fechaIngreso || '—'}
                  </strong>
                </div>

                <div style={{ background: '#fff', borderRadius: 10, padding: '10px 14px', border: '1px solid #e2e8f0' }}>
                  <span style={{ display: 'block', fontSize: '.72rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '.05em' }}>
                    ID Interno Docente
                  </span>
                  <strong style={{ display: 'block', color: '#0f172a', marginTop: 4, fontSize: '.92rem' }}>
                    #{viewDocente.id}
                  </strong>
                </div>
              </div>

              {/* Acciones del modal */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 10, paddingTop: 14, borderTop: '1px solid #e2e8f0' }}>
                {canManage && (
                  <button
                    type="button"
                    className="btn-ghost"
                    style={{ display: 'inline-flex', alignItems: 'center', gap: 6, borderRadius: 8 }}
                    onClick={() => {
                      const doc = viewDocente;
                      setViewDocente(null);
                      openEdit(doc);
                    }}
                  >
                    <MenuIcon name="edit" size={14} /> Editar docente
                  </button>
                )}
                <button
                  type="button"
                  className="btn-primary"
                  style={{ borderRadius: 8, padding: '8px 20px' }}
                  onClick={() => setViewDocente(null)}
                >
                  Cerrar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
