import { useEffect, useState } from 'react';
import { apiRequest } from '../api/apiClient';

/**
 * CUS-DOCENTE — Listas y fórmulas postulantes.
 * Página de solo lectura para que el docente consulte
 * las fórmulas / listas inscritas en el proceso electoral activo.
 */
export default function ListasDocentePage({ onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [procesosLoading, setProcesosLoading] = useState(true);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [detalleLoading, setDetalleLoading] = useState(false);
  const [error, setError] = useState(null);

  // Carga la lista de procesos disponibles
  useEffect(() => {
    setProcesosLoading(true);
    apiRequest('/api/docente/listas-postulantes')
      .then((data) => {
        setProcesos(data);
        if (data.length === 1) setIdProceso(data[0].id);
      })
      .catch((err) => {
        if (err.message === 'SESSION_EXPIRED') onSessionExpired?.();
        else setError(err.message);
      })
      .finally(() => setProcesosLoading(false));
  }, []);

  // Cuando cambia idProceso, carga el detalle
  useEffect(() => {
    if (!idProceso) { setDetalle(null); return; }
    setDetalleLoading(true);
    setDetalle(null);
    apiRequest(`/api/docente/listas-postulantes/${idProceso}`)
      .then(setDetalle)
      .catch((err) => {
        if (err.message === 'SESSION_EXPIRED') onSessionExpired?.();
        else setError(err.message);
      })
      .finally(() => setDetalleLoading(false));
  }, [idProceso]);

  if (procesosLoading) {
    return (
      <div className="panel" style={{ textAlign: 'center', padding: '2rem', color: '#6b7280' }}>
        <span>Cargando procesos electorales...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="panel" style={{ color: '#dc2626', padding: '1.5rem' }}>
        <strong>Error:</strong> {error}
      </div>
    );
  }

  if (procesos.length === 0) {
    return (
      <div className="panel" style={{ textAlign: 'center', padding: '2.5rem', color: '#6b7280' }}>
        <div style={{ fontSize: '2.5rem', marginBottom: '0.75rem' }}>🗳️</div>
        <p style={{ fontWeight: 600, fontSize: '1rem', marginBottom: '0.4rem' }}>
          Sin proceso electoral activo
        </p>
        <p style={{ fontSize: '0.875rem' }}>
          No hay procesos en etapa de inscripción o votación en este momento.
        </p>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>

      {/* Selector de proceso (si hay más de uno) */}
      {procesos.length > 1 && (
        <div className="panel" style={{ padding: '1rem 1.25rem' }}>
          <label style={{ fontWeight: 600, fontSize: '0.875rem', color: '#374151', marginBottom: '0.5rem', display: 'block' }}>
            Proceso electoral
          </label>
          <select
            className="form-control"
            value={idProceso ?? ''}
            onChange={(e) => setIdProceso(Number(e.target.value))}
            style={{ maxWidth: 420 }}
          >
            <option value="">— Seleccione un proceso —</option>
            {procesos.map((p) => (
              <option key={p.id} value={p.id}>
                {p.nombre}
                {p.estado === 'VOTACION' ? ' 🗳️ (En votación)' : ' 📋 (Inscripción)'}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Aviso informativo */}
      {idProceso && (
        <div style={{
          background: '#eff6ff',
          border: '1px solid #bfdbfe',
          borderRadius: 8,
          padding: '0.75rem 1rem',
          fontSize: '0.82rem',
          color: '#1d4ed8',
          display: 'flex',
          gap: '0.5rem',
          alignItems: 'flex-start',
        }}>
          <span>ℹ️</span>
          <span>
            Las elecciones en la UNP se realizan bajo el sistema de <strong>lista completa</strong>.
            Al votar, su voto aplica a todos los integrantes de la fórmula seleccionada
            (Rector y Vicerrectores). No se puede votar por candidatos de distintas listas.
          </span>
        </div>
      )}

      {/* Cargando detalle */}
      {detalleLoading && (
        <div className="panel" style={{ textAlign: 'center', padding: '2rem', color: '#6b7280' }}>
          Cargando listas inscritas...
        </div>
      )}

      {/* Detalle de cargos y listas */}
      {detalle && !detalleLoading && (
        <>
          {(detalle.cargos ?? []).map((cargo) => (
            <div key={cargo.id} className="panel" style={{ padding: '1.25rem 1.5rem' }}>
              {/* Encabezado del cargo */}
              <div style={{ marginBottom: '1rem', borderBottom: '1px solid #e5e7eb', paddingBottom: '0.75rem' }}>
                <h3 style={{ margin: 0, fontSize: '1rem', color: '#111827', fontWeight: 700 }}>
                  {cargo.nombre}
                  {cargo.jurisdiccion && (
                    <span style={{ fontWeight: 400, color: '#6b7280', fontSize: '0.875rem' }}>
                      {' '}— {cargo.jurisdiccion}
                    </span>
                  )}
                </h3>
                <p style={{ margin: '0.25rem 0 0', fontSize: '0.78rem', color: '#9ca3af' }}>
                  {(cargo.listas ?? []).length} lista(s) inscrita(s)
                </p>
              </div>

              {/* Listas del cargo */}
              {(cargo.listas ?? []).length === 0 ? (
                <p style={{ color: '#9ca3af', fontSize: '0.875rem', fontStyle: 'italic' }}>
                  Ninguna lista inscrita aún.
                </p>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  {(cargo.listas ?? []).map((lista, listaIdx) => (
                    <div
                      key={lista.id}
                      style={{
                        border: '1px solid #e5e7eb',
                        borderRadius: 8,
                        overflow: 'hidden',
                      }}
                    >
                      {/* Cabecera de la lista */}
                      <div style={{
                        background: '#f9fafb',
                        padding: '0.75rem 1rem',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        borderBottom: '1px solid #e5e7eb',
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                          <div style={{
                            width: 36, height: 36, borderRadius: '50%',
                            background: '#e0e7ff',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontWeight: 700, color: '#4338ca', fontSize: '1rem',
                          }}>
                            {listaIdx + 1}
                          </div>
                          <div>
                            <div style={{ fontWeight: 700, color: '#111827', fontSize: '0.95rem' }}>
                              {lista.nombre}
                            </div>
                            {lista.simbolo && (
                              <div style={{ fontSize: '0.78rem', color: '#6b7280' }}>
                                Símbolo: {lista.simbolo}
                              </div>
                            )}
                          </div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          {lista.urlPlanGobierno && (
                            <a
                              href={lista.urlPlanGobierno}
                              target="_blank"
                              rel="noopener noreferrer"
                              style={{
                                fontSize: '0.78rem',
                                color: '#2563eb',
                                textDecoration: 'none',
                                border: '1px solid #bfdbfe',
                                borderRadius: 6,
                                padding: '0.2rem 0.6rem',
                                background: '#eff6ff',
                              }}
                            >
                              📄 Plan de gobierno
                            </a>
                          )}
                          <span style={{
                            fontSize: '0.72rem',
                            fontWeight: 600,
                            padding: '0.2rem 0.6rem',
                            borderRadius: 999,
                            background: lista.estado === 'ADMITIDA' ? '#dcfce7' : '#fef9c3',
                            color: lista.estado === 'ADMITIDA' ? '#15803d' : '#854d0e',
                          }}>
                            {lista.estado}
                          </span>
                        </div>
                      </div>

                      {/* Candidatos de la lista */}
                      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.83rem' }}>
                        <thead>
                          <tr style={{ background: '#f3f4f6' }}>
                            <th style={thStyle}>Cargo en fórmula</th>
                            <th style={thStyle}>Candidato</th>
                            <th style={thStyle}>DNI</th>
                            <th style={thStyle}>Categoría</th>
                            <th style={thStyle}>Grado</th>
                          </tr>
                        </thead>
                        <tbody>
                          {(lista.candidatos ?? []).length === 0 ? (
                            <tr>
                              <td colSpan={5} style={{ ...tdStyle, color: '#9ca3af', fontStyle: 'italic', textAlign: 'center' }}>
                                Sin candidatos registrados aún
                              </td>
                            </tr>
                          ) : (
                            (lista.candidatos ?? [])
                              .filter(c => c.estadoValidacion !== 'EXCLUIDO')
                              .map((candidato) => (
                                <tr key={candidato.id} style={{ borderBottom: '1px solid #f3f4f6' }}>
                                  <td style={{ ...tdStyle, fontWeight: 600, color: '#374151' }}>
                                    {rolLabel(candidato.rolEnLista)}
                                  </td>
                                  <td style={tdStyle}>{candidato.docente}</td>
                                  <td style={{ ...tdStyle, color: '#6b7280', fontFamily: 'monospace' }}>{candidato.dni}</td>
                                  <td style={tdStyle}>
                                    <span style={{
                                      padding: '0.15rem 0.5rem',
                                      borderRadius: 999,
                                      background: categoriaColor(candidato.categoria).bg,
                                      color: categoriaColor(candidato.categoria).text,
                                      fontWeight: 600,
                                      fontSize: '0.72rem',
                                    }}>
                                      {candidato.categoria}
                                    </span>
                                  </td>
                                  <td style={{ ...tdStyle, color: '#6b7280' }}>{candidato.gradoAcademico ?? '—'}</td>
                                </tr>
                              ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </>
      )}
    </div>
  );
}

// ── Helpers de estilo ──────────────────────────────────────────────────────

const thStyle = {
  padding: '0.5rem 0.75rem',
  textAlign: 'left',
  fontWeight: 600,
  color: '#374151',
  fontSize: '0.78rem',
  borderBottom: '1px solid #e5e7eb',
};

const tdStyle = {
  padding: '0.55rem 0.75rem',
  color: '#111827',
  verticalAlign: 'middle',
};

function rolLabel(rol) {
  const map = {
    RECTOR: '🎓 Rector',
    VICERRECTOR_ACADEMICO: '📚 Vicerrector Académico',
    VICERRECTOR_INVESTIGACION: '🔬 Vicerrector de Investigación',
    TITULAR: 'Titular',
    ACCESITARIO: 'Accesitario',
  };
  return map[rol] ?? rol;
}

function categoriaColor(cat) {
  if (cat === 'PRINCIPAL')  return { bg: '#dbeafe', text: '#1e40af' };
  if (cat === 'ASOCIADO')   return { bg: '#fef9c3', text: '#854d0e' };
  if (cat === 'AUXILIAR')   return { bg: '#dcfce7', text: '#15803d' };
  return { bg: '#f3f4f6', text: '#374151' };
}
