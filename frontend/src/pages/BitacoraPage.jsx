import { useEffect, useState, useCallback } from 'react';
import { apiRequest } from '../api/apiClient';

const ACCIONES_LABEL = {
  LOGIN_OK: '✅ Login exitoso',
  LOGIN_FAIL: '❌ Login fallido',
  CREAR_PROCESO: '🗳️ Crear proceso',
  IMPORTAR_PADRON: '📥 Importar padrón',
  APROBAR_PADRON: '✔️ Aprobar padrón',
  CREAR_CANDIDATURA: '👤 Crear candidatura',
  RESOLVER_TACHA: '⚖️ Resolver tacha',
  EJECUTAR_SORTEO: '🎲 Ejecutar sorteo',
  EMISION_VOTO: '🗳️ Emisión de voto',
  CAMBIO_PASSWORD: '🔑 Cambio de contraseña',
  CREAR_USUARIO: '👤 Crear usuario',
  INACTIVAR_USUARIO: '🚫 Inactivar usuario',
  CAMBIO_PARAMETRO: '⚙️ Cambio de parámetro',
};

/**
 * Página de Bitácora / Auditoría — Solo lectura para el ADMIN.
 * La tabla log_auditoria es INSERT-ONLY. No hay botones de editar ni eliminar.
 */
export default function BitacoraPage({ onSessionExpired }) {
  const [logs, setLogs]         = useState([]);
  const [totalPages, setTotalPages] = useState(0);
  const [totalItems, setTotalItems] = useState(0);
  const [loading, setLoading]   = useState(false);
  const [feedback, setFeedback] = useState(null);

  // Filtros
  const [accion, setAccion]     = useState('');
  const [idUsuario, setIdUsuario] = useState('');
  const [desde, setDesde]       = useState('');
  const [hasta, setHasta]       = useState('');
  const [page, setPage]         = useState(0);
  const PAGE_SIZE = 25;

  const [tiposAccion, setTiposAccion] = useState([]);

  // Cargar tipos de acción
  useEffect(() => {
    apiRequest('/api/auditoria/acciones')
      .then(setTiposAccion)
      .catch(() => {});
  }, []);

  const loadLogs = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page, size: PAGE_SIZE });
      if (accion)    params.append('accion', accion);
      if (idUsuario) params.append('idUsuario', idUsuario);
      if (desde)     params.append('desde', desde + ':00');
      if (hasta)     params.append('hasta', hasta + ':59');

      const data = await apiRequest(`/api/auditoria?${params.toString()}`);
      setLogs(data.content || []);
      setTotalPages(data.totalPages || 0);
      setTotalItems(data.totalElements || 0);
    } catch (error) {
      if (error.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: error.message });
    } finally {
      setLoading(false);
    }
  }, [accion, idUsuario, desde, hasta, page, onSessionExpired]);

  useEffect(() => { loadLogs(); }, [loadLogs]);

  function formatFecha(dt) {
    if (!dt) return '—';
    return new Date(dt).toLocaleString('es-PE', {
      day: '2-digit', month: '2-digit', year: 'numeric',
      hour: '2-digit', minute: '2-digit', second: '2-digit',
    });
  }

  function formatDetalle(json) {
    if (!json) return '—';
    try {
      return JSON.stringify(JSON.parse(json), null, 2);
    } catch {
      return json;
    }
  }

  function buscar(e) {
    e.preventDefault();
    setPage(0);
    loadLogs();
  }

  return (
    <div className="page-container">
      {/* ── Cabecera con badges ── */}
      <div className="page-header">
        <p className="page-subtitle">Registro inalterable de todas las acciones del sistema</p>
        <div className="audit-badges">
          <span className="badge-audit">🔒 INSERT-ONLY</span>
          <span className="badge-audit warn">🕵️ Solo lectura</span>
        </div>
      </div>

      <div className="immutable-notice">
        <span>⚠️</span>
        <span>
          La bitácora es <strong>inalterable e inmutable</strong>. No existen acciones de edición o eliminación
          sobre este registro. Los eventos de emisión de voto no revelan la opción elegida por el elector,
          garantizando el <strong>secreto del voto</strong>.
        </span>
      </div>

      {feedback && (
        <div className={`alert ${feedback.type}`} onClick={() => setFeedback(null)}>
          {feedback.text}
        </div>
      )}

      {/* ── Filtros ── */}
      <form className="filter-bar audit-filter" onSubmit={buscar}>
        <select value={accion} onChange={e => setAccion(e.target.value)} className="filter-select">
          <option value="">Todas las acciones</option>
          {tiposAccion.map(a => (
            <option key={a} value={a}>{ACCIONES_LABEL[a] || a}</option>
          ))}
        </select>
        <input
          type="number" placeholder="ID Usuario"
          value={idUsuario} onChange={e => setIdUsuario(e.target.value)}
          className="filter-input-sm"
        />
        <div className="date-range">
          <input type="datetime-local" value={desde} onChange={e => setDesde(e.target.value)} title="Desde" />
          <span>→</span>
          <input type="datetime-local" value={hasta} onChange={e => setHasta(e.target.value)} title="Hasta" />
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>Filtrar</button>
        <button type="button" className="btn-ghost" onClick={() => {
          setAccion(''); setIdUsuario(''); setDesde(''); setHasta(''); setPage(0);
        }}>Limpiar</button>
        {totalItems > 0 && (
          <span className="result-count">{totalItems.toLocaleString()} registro{totalItems !== 1 ? 's' : ''}</span>
        )}
      </form>

      {/* ── Tabla ── */}
      <div className="panel">
        <div className="table-wrap audit-table">
          <table>
            <thead>
              <tr>
                <th>Fecha / Hora</th>
                <th>ID Usuario</th>
                <th>Acción</th>
                <th>IP Origen</th>
                <th>Detalle JSON</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="loading-row">Cargando registros...</td></tr>
              ) : logs.length === 0 ? (
                <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Sin registros para los filtros aplicados</td></tr>
              ) : logs.map(log => (
                <tr key={log.id}>
                  <td className="mono">{formatFecha(log.fechaHora)}</td>
                  <td>{log.idUsuario ? `#${log.idUsuario}` : '—'}</td>
                  <td>
                    <span className="action-badge">
                      {ACCIONES_LABEL[log.accion] || log.accion}
                    </span>
                  </td>
                  <td className="mono">{log.ipOrigen || '—'}</td>
                  <td>
                    <details className="json-detail">
                      <summary>Ver detalle</summary>
                      <pre className="json-pre">{formatDetalle(log.detalleJson)}</pre>
                    </details>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Paginación */}
        {totalPages > 1 && (
          <div className="pagination">
            <button disabled={page === 0} onClick={() => setPage(p => p - 1)} className="page-btn">‹ Anterior</button>
            <span>Página {page + 1} de {totalPages}</span>
            <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)} className="page-btn">Siguiente ›</button>
          </div>
        )}
      </div>
    </div>
  );
}
