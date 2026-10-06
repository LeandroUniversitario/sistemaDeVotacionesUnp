import { useEffect, useState, useCallback, useRef, useMemo } from 'react';
import { apiRequest } from '../api/apiClient';

const ROLES = ['ADMIN', 'CEUNP', 'DOCENTE', 'PERSONERO', 'MIEMBRO_MESA'];
const ROLES_CON_DOCENTE = ['CEUNP', 'DOCENTE', 'PERSONERO', 'MIEMBRO_MESA'];

/**
 * Página de administración de usuarios del sistema.
 * ETAPA 1 — Gestión de Seguridad y Usuarios del Sistema.
 * Solo accesible para el rol ADMIN.
 */
export default function UsuariosPage({ teachers, onSessionExpired }) {
  const [users, setUsers]       = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [search, setSearch]     = useState('');
  const [filtroRol, setFiltroRol]     = useState('');
  const [filtroEstado, setFiltroEstado] = useState('');

  const FORM_INIT = { username: '', password: '', rol: 'CEUNP', idDocente: '' };
  const [form, setForm]           = useState(FORM_INIT);
  const [usernameWarning, setUsernameWarning] = useState('');
  const [feedback, setFeedback]   = useState(null);
  const [saving, setSaving]       = useState(false);
  const [showModal, setShowModal] = useState(false);

  // Buscador de docente en el modal
  const [teacherSearch, setTeacherSearch] = useState('');
  const [showTeacherDrop, setShowTeacherDrop] = useState(false);
  const teacherDropRef = useRef(null);

  // ── Editar rol / Restablecer contraseña ──────────────────────────────────
  const [editUser, setEditUser] = useState(null);   // usuario en edición de rol
  const [newRol, setNewRol]     = useState('');
  const [resetUser, setResetUser] = useState(null); // usuario para reset pwd
  const [newPassword, setNewPassword] = useState('');

  // ── Cargar usuarios ──────────────────────────────────────────────────────
  const loadUsers = useCallback(async () => {
    try {
      const data = await apiRequest('/api/auth/users');
      setUsers(data);
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    }
  }, [onSessionExpired]);

  useEffect(() => { loadUsers(); }, [loadUsers]);

  // Cerrar dropdown de docente al hacer clic fuera
  useEffect(() => {
    function handleClickOutside(e) {
      if (teacherDropRef.current && !teacherDropRef.current.contains(e.target)) {
        setShowTeacherDrop(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // ── Filtros reactivos ────────────────────────────────────────────────────
  useEffect(() => {
    const q = search.toLowerCase();
    setFiltered(users.filter(u => {
      const matchSearch = !q
        || u.username.toLowerCase().includes(q)
        || (u.idDocente && String(u.idDocente).includes(q));
      const matchRol    = !filtroRol    || u.rol === filtroRol;
      const matchEstado = !filtroEstado || (filtroEstado === 'ACTIVO' ? u.activo : !u.activo);
      return matchSearch && matchRol && matchEstado;
    }));
  }, [users, search, filtroRol, filtroEstado]);

  // ── Validación reactiva de username duplicado ────────────────────────────
  function handleUsernameChange(val) {
    setForm({ ...form, username: val });
    if (users.some(u => u.username.toLowerCase() === val.toLowerCase())) {
      setUsernameWarning('⚠ El nombre de usuario ya está en uso');
    } else {
      setUsernameWarning('');
    }
  }

  // ── Crear usuario ────────────────────────────────────────────────────────
  async function createUser(event) {
    event.preventDefault();
    if (usernameWarning) return;
    setSaving(true);
    setFeedback(null);
    try {
      await apiRequest('/api/auth/users', {
        method: 'POST',
        body: JSON.stringify({ ...form, idDocente: form.idDocente ? Number(form.idDocente) : null }),
      });
      setForm(FORM_INIT);
      setShowModal(false);
      setFeedback({ type: 'success', text: 'Usuario creado correctamente.' });
      await loadUsers();
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  // ── Toggle activo/inactivo (nunca eliminar) ───────────────────────────────
  async function toggleUser(user) {
    setSaving(true);
    try {
      await apiRequest(`/api/auth/users/${user.id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ activo: !user.activo }),
      });
      setFeedback({ type: 'success', text: `Usuario ${user.activo ? 'desactivado' : 'activado'}.` });
      await loadUsers();
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  // ── Editar rol ───────────────────────────────────────────────────────────
  async function guardarRol() {
    if (!editUser || !newRol) return;
    setSaving(true);
    try {
      await apiRequest(`/api/auth/users/${editUser.id}/rol`, {
        method: 'PATCH',
        body: JSON.stringify({ rol: newRol }),
      });
      setEditUser(null);
      setFeedback({ type: 'success', text: 'Rol actualizado.' });
      await loadUsers();
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  // ── Restablecer contraseña ───────────────────────────────────────────────
  async function restablecerPassword() {
    if (!resetUser || newPassword.length < 8) return;
    setSaving(true);
    try {
      await apiRequest(`/api/auth/users/${resetUser.id}/password`, {
        method: 'PATCH',
        body: JSON.stringify({ password: newPassword }),
      });
      setResetUser(null);
      setNewPassword('');
      setFeedback({ type: 'success', text: 'Contraseña restablecida correctamente.' });
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setSaving(false);
    }
  }

  function rolBadge(rol) {
    const map = { ADMIN: 'badge-red', CEUNP: 'badge-blue', DOCENTE: 'badge-green',
                  PERSONERO: 'badge-orange', MIEMBRO_MESA: 'badge-purple' };
    return <span className={`badge ${map[rol] || ''}`}>{rol}</span>;
  }

  return (
    <div className="page-container">
      {feedback && (
        <div className={`alert ${feedback.type}`} onClick={() => setFeedback(null)}>
          {feedback.text}
        </div>
      )}

      {/* ── Cabecera ── */}
      <div className="page-header">
        <p className="page-subtitle">Gestiona las cuentas de acceso — ETAPA 1</p>
        <button className="btn-primary" onClick={() => setShowModal(true)}>
          <span>＋</span> Nuevo usuario
        </button>
      </div>

      {/* ── Barra de búsqueda y filtros ── */}
      <div className="filter-bar">
        <div className="search-box">
          <span className="search-icon">🔍</span>
          <input
            type="text"
            placeholder="Buscar por username o ID docente..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          {search && <button className="clear-btn" onClick={() => setSearch('')}>✕</button>}
        </div>
        <select value={filtroRol} onChange={e => setFiltroRol(e.target.value)} className="filter-select">
          <option value="">Todos los roles</option>
          {ROLES.map(r => <option key={r}>{r}</option>)}
        </select>
        <select value={filtroEstado} onChange={e => setFiltroEstado(e.target.value)} className="filter-select">
          <option value="">Todos los estados</option>
          <option value="ACTIVO">Activo</option>
          <option value="INACTIVO">Inactivo</option>
        </select>
        <span className="result-count">{filtered.length} resultado{filtered.length !== 1 ? 's' : ''}</span>
      </div>

      {/* ── Tabla ── */}
      <div className="panel">
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Usuario</th>
                <th>Rol</th>
                <th>ID Docente</th>
                <th>Estado</th>
                <th>Operaciones</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Sin resultados</td></tr>
              ) : filtered.map(user => (
                <tr key={user.id}>
                  <td><strong>{user.username}</strong></td>
                  <td>{rolBadge(user.rol)}</td>
                  <td>{user.idDocente ? `#${user.idDocente}` : '—'}</td>
                  <td>
                    <span className={`status-pill ${user.activo ? 'active' : 'inactive'}`}>
                      {user.activo ? 'Activo' : 'Inactivo'}
                    </span>
                  </td>
                  <td className="action-cell">
                    {/* Editar rol */}
                    <button
                      className="icon-btn" title="Editar rol"
                      onClick={() => { setEditUser(user); setNewRol(user.rol); }}
                    >✏️</button>
                    {/* Restablecer contraseña */}
                    <button
                      className="icon-btn" title="Restablecer contraseña"
                      onClick={() => { setResetUser(user); setNewPassword(''); }}
                    >🔑</button>
                    {/* Activar / Inactivar */}
                    <button
                      className={`icon-btn ${user.activo ? 'danger' : 'success'}`}
                      title={user.activo ? 'Desactivar' : 'Activar'}
                      disabled={saving}
                      onClick={() => toggleUser(user)}
                    >{user.activo ? '🚫' : '✅'}</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ══ MODAL: Nuevo usuario ══ */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-card" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Nuevo usuario</h2>
              <button className="modal-close" onClick={() => setShowModal(false)}>✕</button>
            </div>
            <form className="modal-form" onSubmit={createUser}>
              <label>Nombre de usuario
                <input
                  value={form.username}
                  pattern="[A-Za-z0-9._-]+"
                  minLength={3} maxLength={80}
                  onChange={e => handleUsernameChange(e.target.value)}
                  required
                />
                {usernameWarning && <span className="field-warning">{usernameWarning}</span>}
              </label>
              <label>Contraseña
                <input
                  type="password" minLength={8} autoComplete="new-password"
                  value={form.password}
                  onChange={e => setForm({ ...form, password: e.target.value })}
                  required
                />
              </label>
              <label>Rol
                <select value={form.rol} onChange={e => setForm({ ...form, rol: e.target.value })}>
                  {ROLES.map(r => <option key={r}>{r}</option>)}
                </select>
              </label>
              <label>
                Vincular con docente del padrón
                {ROLES_CON_DOCENTE.includes(form.rol) && <span className="required-mark"> *</span>}
                {/* Buscador de docente */}
                <div className="docente-search-wrap" ref={teacherDropRef}>
                  <input
                    type="text"
                    placeholder="Buscar por DNI, apellidos o nombres..."
                    value={teacherSearch}
                    autoComplete="off"
                    onChange={e => {
                      setTeacherSearch(e.target.value);
                      setShowTeacherDrop(true);
                      if (!e.target.value) setForm(f => ({ ...f, idDocente: '' }));
                    }}
                    onFocus={() => setShowTeacherDrop(true)}
                  />
                  {form.idDocente && (
                    <button type="button" className="clear-btn" style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)' }}
                      onClick={() => { setForm(f => ({ ...f, idDocente: '' })); setTeacherSearch(''); }}>
                      ✕
                    </button>
                  )}
                  {showTeacherDrop && (
                    <div className="docente-dropdown">
                      <button
                        type="button"
                        className={`docente-option ${!form.idDocente ? 'selected' : ''}`}
                        onClick={() => { setForm(f => ({ ...f, idDocente: '' })); setTeacherSearch(''); setShowTeacherDrop(false); }}
                      >
                        — Sin vinculación (solo rol ADMIN) —
                      </button>
                      {teachers
                        .filter(t => {
                          const q = teacherSearch.toLowerCase().trim();
                          return !q || `${t.dni} ${t.apellidos} ${t.nombres}`.toLowerCase().includes(q);
                        })
                        .slice(0, 40)
                        .map(t => (
                          <button
                            type="button"
                            key={t.id}
                            className={`docente-option ${String(form.idDocente) === String(t.id) ? 'selected' : ''}`}
                            onClick={() => {
                              setForm(f => ({ ...f, idDocente: String(t.id) }));
                              setTeacherSearch(`${t.dni} · ${t.apellidos}, ${t.nombres}`);
                              setShowTeacherDrop(false);
                            }}
                          >
                            <span className="docente-option-dni">{t.dni}</span>
                            <span className="docente-option-name">{t.apellidos}, {t.nombres}</span>
                          </button>
                        ))}
                    </div>
                  )}
                </div>
                {ROLES_CON_DOCENTE.includes(form.rol) && !form.idDocente && (
                  <span className="field-warning">Obligatorio para el rol {form.rol}</span>
                )}
              </label>
              <div className="modal-actions">
                <button type="button" className="btn-ghost" onClick={() => setShowModal(false)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={saving || !!usernameWarning}>
                  {saving ? 'Creando...' : 'Crear usuario'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ══ MODAL: Editar rol ══ */}
      {editUser && (
        <div className="modal-overlay" onClick={() => setEditUser(null)}>
          <div className="modal-card small" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Editar rol — {editUser.username}</h2>
              <button className="modal-close" onClick={() => setEditUser(null)}>✕</button>
            </div>
            <div className="modal-form">
              <label>Nuevo rol
                <select value={newRol} onChange={e => setNewRol(e.target.value)}>
                  {ROLES.map(r => <option key={r}>{r}</option>)}
                </select>
              </label>
              <div className="modal-actions">
                <button className="btn-ghost" onClick={() => setEditUser(null)}>Cancelar</button>
                <button className="btn-primary" onClick={guardarRol} disabled={saving}>
                  Guardar cambio
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ══ MODAL: Restablecer contraseña ══ */}
      {resetUser && (
        <div className="modal-overlay" onClick={() => setResetUser(null)}>
          <div className="modal-card small" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Restablecer contraseña — {resetUser.username}</h2>
              <button className="modal-close" onClick={() => setResetUser(null)}>✕</button>
            </div>
            <div className="modal-form">
              <label>Nueva contraseña
                <input
                  type="password" minLength={8}
                  value={newPassword}
                  onChange={e => setNewPassword(e.target.value)}
                  autoFocus
                />
              </label>
              <div className="modal-actions">
                <button className="btn-ghost" onClick={() => setResetUser(null)}>Cancelar</button>
                <button
                  className="btn-primary"
                  onClick={restablecerPassword}
                  disabled={saving || newPassword.length < 8}
                >
                  Restablecer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
