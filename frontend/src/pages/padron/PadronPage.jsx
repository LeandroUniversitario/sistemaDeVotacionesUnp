import { useEffect, useMemo, useRef, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import '../convocatoria/convocatoria.css';
import './padron.css';

/**
 * CUS02 · Gestionar padrón electoral — «PantallaPadron» (boundary).
 *
 * Mensajes del diagrama de colaboración que origina esta pantalla:
 *   1 subirArchivo(archivo)            → 2 leerDatos()                 → ImportarDocentes
 *   5 depurarPadron()                  → 6 procesarReglas()            → FiltrarHabilitados
 *   9 confirmarAprobacion(id_proceso)  → 10 generarDefinitivo(id_proceso) → AprobarPadron
 * y los que recibe: 4 mostrarImportados(), 8 mostrarListaDepurada(), 12 notificarExito().
 */

const PASOS = [
  { num: 1, label: 'Importar docentes' },
  { num: 2, label: 'Depurar padrón' },
  { num: 3, label: 'Aprobar padrón definitivo' },
];

const COLUMNAS = ['DNI', 'Nombres', 'Apellidos', 'Categoría', 'Dedicación', 'Estado', 'Facultad', 'Departamento', 'Grado Académico', 'Fecha Ingreso', 'Fecha Categoría', 'Email', 'URL Foto'];
const POR_PAGINA = 25;

const ESTADO_PROCESO = {
  CREADO: 'Borrador', INSCRIPCION: 'Inscripción', VOTACION: 'En votación',
  CERRADO: 'Cerrado', FINALIZADO: 'Finalizado', ANULADO: 'Anulado',
};

const fmtFechaHora = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
function formatFechaHora(value) {
  if (!value) return '—';
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? '—' : fmtFechaHora.format(d);
}

const num = (v) => Number(v ?? 0);

/** POST multipart con el token de sesión (apiRequest siempre envía JSON). */
async function subirArchivo(path, archivo) {
  const token = sessionStorage.getItem('accessToken');
  const form = new FormData();
  form.append('archivo', archivo);
  const response = await fetch(path, {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  });
  if (response.status === 401) {
    sessionStorage.removeItem('accessToken');
    throw new Error('SESSION_EXPIRED');
  }
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.detail || data.error || data.message || 'No se pudo importar el archivo.');
  return data;
}

function descargarCsv(nombre, filas) {
  const escapar = (v) => `"${String(v ?? '').replaceAll('"', '""')}"`;
  const contenido = '﻿' + filas.map((f) => f.map(escapar).join(',')).join('\r\n');
  const url = URL.createObjectURL(new Blob([contenido], { type: 'text/csv;charset=utf-8' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = nombre;
  a.click();
  URL.revokeObjectURL(url);
}

export default function PadronPage({ session, onChange, onSessionExpired }) {
  const esAdmin = session?.rol === 'ADMIN';

  // ADMIN solo ve paso 1 (importar); CEUNP ve solo depurar y aprobar
  const PASOS_VISIBLES = esAdmin
    ? [{ num: 1, label: 'Importar docentes' }]
    : [{ num: 2, label: 'Depurar padrón' }, { num: 3, label: 'Aprobar padrón definitivo' }];

  const [paso, setPaso] = useState(esAdmin ? 1 : 2);
  const [resumen, setResumen] = useState(null);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  // Paso 1
  const [archivo, setArchivo] = useState(null);
  const [arrastrando, setArrastrando] = useState(false);
  const [importacion, setImportacion] = useState(null);
  const inputRef = useRef(null);

  // Paso 2
  const [depuracion, setDepuracion] = useState(null);   // { resumen, motivos, docentes, cambios? }
  const [filtro, setFiltro] = useState('TODOS');
  const [busqueda, setBusqueda] = useState('');
  const [pagina, setPagina] = useState(1);

  // Paso 3
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);         // { proceso, cargos, requisitos }
  const [electores, setElectores] = useState([]);
  const [confirmando, setConfirmando] = useState(false);
  const [busquedaPadron, setBusquedaPadron] = useState('');
  const [cargoPadron, setCargoPadron] = useState('TODOS');
  const [paginaPadron, setPaginaPadron] = useState(1);

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  async function cargarResumen() {
    try {
      setResumen(await apiRequest('/api/padron/resumen'));
    } catch (error) {
      manejarError(error);
    }
  }

  useEffect(() => {
    cargarResumen();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function irAPaso(numero) {
    setFeedback(null);
    setPaso(numero);
    if (numero === 2 && !depuracion) cargarListaDepurada();
    if (numero === 3) cargarProcesos();
  }

  // ─── 1 subirArchivo(archivo) → 2 leerDatos() ─────────────────────────────
  function elegirArchivo(file) {
    if (!file) return;
    setArchivo(file);
    setImportacion(null);
    setFeedback(null);
  }

  async function subirArchivoPadron() {
    if (!archivo) return;
    setSaving(true);
    setFeedback(null);
    try {
      const data = await subirArchivo('/api/padron/importar', archivo);
      // 4 mostrarImportados()
      setImportacion(data);
      setResumen(data.resumen);
      setDepuracion(null);
      setFeedback({ type: num(data.insertados) + num(data.actualizados) > 0 ? 'success' : 'error', text: data.mensaje });
      onChange?.();
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  function descargarPlantilla() {
    descargarCsv('plantilla_padron_docentes.csv', [
      COLUMNAS,
      ['03681234', 'Juan Carlos', 'Mendoza Pérez', 'PRINCIPAL', 'DE', 'ACTIVO', 'Facultad de Ingeniería Industrial', 'Ingeniería Informática', 'DOCTOR', '01/11/1997', '01/05/2008', 'jmendoza@unp.edu.pe', ''],
    ]);
  }

  // ─── 5 depurarPadron() → 6 procesarReglas() ──────────────────────────────
  async function cargarListaDepurada() {
    try {
      setDepuracion(await apiRequest('/api/padron/depurado'));
    } catch (error) {
      manejarError(error);
    }
  }

  async function depurarPadron() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest('/api/padron/depurar', { method: 'POST' });
      // 8 mostrarListaDepurada()
      setDepuracion(data);
      setResumen(data.resumen);
      setFiltro('INHABILITADOS');
      setPagina(1);
      setFeedback({ type: 'success', text: data.mensaje });
      onChange?.();
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  const docentesFiltrados = useMemo(() => {
    const lista = depuracion?.docentes ?? [];
    const q = busqueda.trim().toLowerCase();
    return lista.filter((d) => {
      const hab = Boolean(num(d.habilitado));
      if (filtro === 'HABILITADOS' && !hab) return false;
      if (filtro === 'INHABILITADOS' && hab) return false;
      if (!q) return true;
      return d.dni.includes(q) || d.docente.toLowerCase().includes(q) || (d.facultad ?? '').toLowerCase().includes(q);
    });
  }, [depuracion, filtro, busqueda]);

  // ─── 9 confirmarAprobacion(id_proceso) → 10 generarDefinitivo(id_proceso) ─
  async function cargarProcesos() {
    try {
      const lista = await apiRequest('/api/padron/procesos');
      setProcesos(lista);
      const preferido = idProceso ?? lista.find((p) => ['CREADO', 'INSCRIPCION'].includes(p.estado))?.id ?? lista[0]?.id;
      if (preferido) abrirProceso(preferido);
    } catch (error) {
      manejarError(error);
    }
  }

  async function abrirProceso(id) {
    setIdProceso(id);
    setBusquedaPadron('');
    setCargoPadron('TODOS');
    setPaginaPadron(1);
    try {
      const [det, lista] = await Promise.all([
        apiRequest(`/api/padron/procesos/${id}`),
        apiRequest(`/api/padron/procesos/${id}/electores`),
      ]);
      setDetalle(det);
      setElectores(lista);
    } catch (error) {
      manejarError(error);
    }
  }

  async function confirmarAprobacion() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/padron/procesos/${idProceso}/aprobar`, { method: 'POST' });
      // 12 notificarExito()
      setDetalle({ proceso: data.proceso, cargos: data.cargos, requisitos: data.requisitos });
      setElectores(await apiRequest(`/api/padron/procesos/${idProceso}/electores`));
      setProcesos(await apiRequest('/api/padron/procesos'));
      setFeedback({ type: 'success', text: data.mensaje });
      onChange?.();
    } catch (error) {
      manejarError(error);
    } finally {
      setConfirmando(false);
      setSaving(false);
    }
  }

  const cargosPadron = useMemo(() => [...new Set(electores.map((e) => e.cargo))], [electores]);
  const electoresFiltrados = useMemo(() => {
    const q = busquedaPadron.trim().toLowerCase();
    return electores.filter((e) => (cargoPadron === 'TODOS' || e.cargo === cargoPadron)
      && (!q || e.dni.includes(q) || e.docente.toLowerCase().includes(q)));
  }, [electores, busquedaPadron, cargoPadron]);

  function exportarPadron() {
    descargarCsv(`padron_${detalle?.proceso?.nombre ?? 'proceso'}.csv`.replace(/\s+/g, '_'), [
      ['Cargo', 'DNI', 'Docente', 'Categoría', 'Facultad', 'Mesa'],
      ...electoresFiltrados.map((e) => [e.cargo, e.dni, e.docente, e.categoria, e.facultad, e.numeroMesa ?? '']),
    ]);
  }

  const requisitos = detalle?.requisitos ?? [];
  const aprobable = requisitos.length > 0 && requisitos.every((r) => r.cumple);
  const yaAprobado = num(detalle?.proceso?.registrosPadron) > 0;

  // ─── Render ─────────────────────────────────────────────────────────────
  return (
    <div className="pd-shell">
      {/* En ADMIN no se muestran las tarjetas métricas superiores para centrar la vista en la carga masiva */}
      {!esAdmin && (
        <section className="pd-stats" aria-label="Resumen de docentes">
          <Stat label="Docentes registrados" value={resumen?.total} />
          <Stat label="Habilitados para votar" value={resumen?.habilitados} tone="green" />
          <Stat label="Inhabilitados" value={resumen?.inhabilitados} tone="red" />
          <Stat
            label="Última depuración"
            value={resumen?.ultimaDepuracion ? formatFechaHora(resumen.ultimaDepuracion) : 'Pendiente'}
            sub={resumen ? (resumen.depuracionVigente ? 'Vigente' : 'Depure después de importar') : ''}
            tone={resumen?.depuracionVigente ? 'green' : 'amber'}
            small
          />
        </section>
      )}

      {/* Los pasos numerados solo aplican al flujo CEUNP (depuración y aprobación); en ADMIN se omite el paso 1 aislado */}
      {!esAdmin && (
        <nav className="cv-steps" aria-label="Pasos del padrón">
          {PASOS_VISIBLES.map((p) => (
            <button
              key={p.num}
              type="button"
              className={`cv-step${paso === p.num ? ' current' : ''}${paso > p.num ? ' done' : ''}`}
              onClick={() => irAPaso(p.num)}
            >
              <span>{p.label}</span>
            </button>
          ))}
        </nav>
      )}

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}

      {/* ── Paso 1: Importar ─────────────────────────────────────── */}
      {paso === 1 && (
        <div className="pd-grid" style={{ gridTemplateColumns: "1.2fr 1fr", alignItems: "stretch" }}>
          <section className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Subir padrón de docentes</h3>
                <p className="muted">Excel (.xlsx) o CSV. Si el DNI ya existe se actualizan sus datos; si no, se registra. La facultad y el departamento deben existir en el sistema.</p>
              </div>
            </div>

            <div
              className={`pd-drop${arrastrando ? ' over' : ''}${archivo ? ' has-file' : ''}`}
              role="button"
              tabIndex={0}
              onClick={() => inputRef.current?.click()}
              onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') inputRef.current?.click(); }}
              onDragOver={(e) => { e.preventDefault(); setArrastrando(true); }}
              onDragLeave={() => setArrastrando(false)}
              onDrop={(e) => { e.preventDefault(); setArrastrando(false); elegirArchivo(e.dataTransfer.files[0]); }}
            >
              <input ref={inputRef} type="file" accept=".xlsx,.csv" hidden onChange={(e) => elegirArchivo(e.target.files[0])} />
              <span className="pd-drop-icon"><MenuIcon name="upload" size={26} /></span>
              {archivo ? (
                <>
                  <strong>{archivo.name}</strong>
                  <span>{(archivo.size / 1024).toFixed(1)} KB · clic para cambiar</span>
                </>
              ) : (
                <>
                  <strong>Arrastre el archivo aquí o haga clic para elegirlo</strong>
                  <span>.xlsx o .csv · máximo 5 MB</span>
                </>
              )}
            </div>

            <div className="pd-columns">
              <span className="cv-label">Columnas esperadas (primera fila):</span>
              <div>{COLUMNAS.map((c) => <code key={c}>{c}</code>)}</div>
            </div>

            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={descargarPlantilla}>
                <MenuIcon name="download" size={15} /> Plantilla CSV
              </button>
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => irAPaso(2)}>Omitir, ya están registrados</button>
              <button type="button" className="cv-btn cv-btn-primary" disabled={!archivo || saving} onClick={subirArchivoPadron}>
                <MenuIcon name="upload" size={15} /> {saving ? 'Importando…' : 'Subir archivo'}
              </button>
            </div>
          </section>

          <section className="panel cv-form" style={{ display: "flex", flexDirection: "column" }}>
            <div className="cv-section-head">
              <div>
                <h3>Resultado de la importación</h3>
                <p className="muted">
                  {resumen?.ultimaImportacion ? `Última importación: ${formatFechaHora(resumen.ultimaImportacion)}` : 'Aún no se ha importado ningún archivo desde esta pantalla.'}
                </p>
              </div>
            </div>
            {!importacion ? (
              <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", padding: "40px 20px", textAlign: "center" }}>
                <p className="empty-state" style={{ margin: 0 }}>Suba un archivo para ver cuántos docentes se registraron o actualizaron.</p>
              </div>
            ) : (
              <>
                <div className="pd-mini-stats">
                  <Stat label="Nuevos" value={importacion.insertados} tone="green" />
                  <Stat label="Actualizados" value={importacion.actualizados} />
                  <Stat label="Cuentas creadas" value={importacion.usuariosCreados ?? 0} tone="green" />
                  <Stat label="Filas con error" value={importacion.errores.length} tone={importacion.errores.length ? 'red' : undefined} />
                </div>
                {importacion.errores.length > 0 && (
                  <details className="pd-errors" open={importacion.errores.length <= 5}>
                    <summary>Ver {importacion.errores.length} fila(s) con error</summary>
                    <ul>{importacion.errores.map((e) => <li key={e}>{e}</li>)}</ul>
                  </details>
                )}
                {!esAdmin && (
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-primary" onClick={() => irAPaso(2)}>Continuar a depurar</button>
                  </div>
                )}
              </>
            )}
          </section>
        </div>
      )}

      {/* ── Paso 2: Docentes registrados (Admin) / Depurar padrón (CEUNP) ── */}
      {paso === 2 && (
        <section className="panel cv-form">
          <div className="cv-section-head" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px', flexWrap: 'wrap' }}>
            <div>
              <h3>{esAdmin ? 'Docentes registrados' : 'Depurar padrón'}</h3>
              <p className="muted">
                {esAdmin
                  ? 'Lista general de docentes importados en el sistema con sus datos de adscripción y estado actual.'
                  : 'Aplica las reglas de habilitación a todos los docentes: solo docentes ACTIVOS (fuera licencia, suspendidos e inactivos), DNI de 8 dígitos y datos completos.'}
              </p>
            </div>
            <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
              {esAdmin ? (
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => irAPaso(1)}>
                  <MenuIcon name="upload" size={15} /> Subir nuevo padrón
                </button>
              ) : (
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={depurarPadron}>
                  <MenuIcon name="filter" size={15} /> {saving ? 'Depurando…' : 'Depurar padrón'}
                </button>
              )}
            </div>
          </div>

          {!esAdmin && depuracion?.cambios && (
            <div className="pd-changes">
              <span><b>{depuracion.cambios.habilitados}</b> rehabilitados</span>
              <span><b>{depuracion.cambios.inhabilitados}</b> inhabilitados</span>
              <span>en esta depuración</span>
            </div>
          )}

          {!esAdmin && (depuracion?.motivos ?? []).length > 0 && (
            <div className="pd-motivos">
              {depuracion.motivos.map((m) => (
                <span key={m.motivo} className="pd-motivo"><b>{m.total}</b> {m.motivo}</span>
              ))}
            </div>
          )}

          <div className="pd-toolbar">
            <div className="pd-tabs" role="tablist">
              {[
                ['TODOS', 'Todos', depuracion?.docentes?.length ?? 0],
                ['HABILITADOS', 'Habilitados', num(depuracion?.resumen?.habilitados)],
                ['INHABILITADOS', 'Inhabilitados', num(depuracion?.resumen?.inhabilitados)],
              ].map(([key, label, total]) => (
                <button key={key} type="button" role="tab" aria-selected={filtro === key}
                  className={`pd-tab${filtro === key ? ' on' : ''}`}
                  onClick={() => { setFiltro(key); setPagina(1); }}>
                  {label} <span>{total}</span>
                </button>
              ))}
            </div>
            <input className="pd-search" placeholder="Buscar por DNI, nombre o facultad…" value={busqueda}
              onChange={(e) => { setBusqueda(e.target.value); setPagina(1); }} />
          </div>

          {!depuracion ? (
            <p className="empty-state">Cargando lista…</p>
          ) : (
            <TablaPaginada
              filas={docentesFiltrados}
              pagina={pagina}
              onPagina={setPagina}
              vacio="No hay docentes que coincidan con el filtro."
              columnas={esAdmin
                ? ['DNI', 'Docente', 'Categoría', 'Dedicación', 'Facultad', 'Estado']
                : ['DNI', 'Docente', 'Categoría', 'Facultad', 'Estado', 'Habilitación']}
              renderFila={(d) => (
                <tr key={d.id}>
                  <td className="mono"><code>{d.dni}</code></td>
                  <td><strong>{d.docente}</strong><small className="pd-sub">{d.departamento}</small></td>
                  <td>{d.categoria}</td>
                  {esAdmin ? <td>{d.dedicacion || '—'}</td> : null}
                  <td>{d.facultad}</td>
                  <td>
                    <span className={`badge ${d.estado === 'ACTIVO' ? 'creado' : 'anulado'}`}>
                      {d.estado}
                    </span>
                  </td>
                  {!esAdmin && (
                    <td>
                      {num(d.habilitado)
                        ? <span className="cv-estado votacion">Habilitado</span>
                        : <span className="pd-inhab"><span className="cv-estado anulado">Inhabilitado</span><small>{d.motivo}</small></span>}
                    </td>
                  )}
                </tr>
              )}
            />
          )}

          <div className="cv-actions">
            <button type="button" className="cv-btn cv-btn-primary" disabled={!resumen?.depuracionVigente} onClick={() => irAPaso(3)}
              title={resumen?.depuracionVigente ? '' : 'Depure el padrón para continuar'}>
              Continuar a aprobar
            </button>
          </div>
        </section>
      )}

      {/* ── Paso 3: Aprobar ──────────────────────────────────────── */}
      {paso === 3 && (
        <div className="pd-approve">
          <aside className="panel pd-procesos">
            <h3>Proceso electoral</h3>
            {procesos.length === 0 && <p className="empty-state">No hay procesos. Créelos en «Convocatoria y cronograma».</p>}
            <ul>
              {procesos.map((p) => (
                <li key={p.id}>
                  <button type="button" className={`cv-list-item${idProceso === p.id ? ' active' : ''}`} onClick={() => abrirProceso(p.id)}>
                    <span className="cv-list-name">{p.nombre}</span>
                    <span className="cv-list-meta">
                      {num(p.totalCargos)} cargo(s) · {num(p.electoresPadron) > 0 ? `${p.electoresPadron} electores en padrón` : 'sin padrón'}
                    </span>
                    <span className={`cv-estado ${p.estado.toLowerCase()}`}>{ESTADO_PROCESO[p.estado] ?? p.estado}</span>
                  </button>
                </li>
              ))}
            </ul>
          </aside>

          {detalle && (
            <section className="pd-approve-main">
              <div className="panel cv-form">
                <div className="cv-section-head">
                  <div>
                    <h3>{detalle.proceso.nombre}</h3>
                    <p className="muted">
                      {yaAprobado
                        ? `Padrón aprobado el ${formatFechaHora(detalle.proceso.fechaPadron)} · ${detalle.proceso.electoresPadron} electores, ${detalle.proceso.registrosPadron} registros.`
                        : 'El padrón definitivo aún no se ha generado para este proceso.'}
                    </p>
                  </div>
                  {yaAprobado && <span className="cv-estado votacion">Padrón aprobado</span>}
                </div>

                <div className="cv-review">
                  <ul className="cv-checklist">
                    {requisitos.map((r) => (
                      <li key={r.codigo} className={r.cumple ? 'ok' : 'bad'}>
                        <span className="cv-check-icon"><MenuIcon name={r.cumple ? 'check' : 'close'} size={14} /></span>
                        {r.descripcion}
                      </li>
                    ))}
                  </ul>
                  <div className="table-wrap pd-cargos">
                    <table>
                      <thead><tr><th>Cargo</th><th className="num">Previstos</th><th className="num">En padrón</th></tr></thead>
                      <tbody>
                        {detalle.cargos.map((c) => (
                          <tr key={c.idCargo}>
                            <td><strong>{c.cargo}</strong>{c.jurisdiccion && <small className="pd-sub">{c.jurisdiccion}</small>}</td>
                            <td className="num">{c.previstos}</td>
                            <td className="num">{num(c.enPadron) || '—'}</td>
                          </tr>
                        ))}
                        {detalle.cargos.length === 0 && <tr><td colSpan={3} className="empty-state">Sin cargos.</td></tr>}
                      </tbody>
                    </table>
                  </div>
                </div>

                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => irAPaso(2)}>Volver a depurar</button>
                  <button type="button" className="cv-btn cv-btn-success" disabled={!aprobable || saving} onClick={() => setConfirmando(true)}>
                    <MenuIcon name="check" size={15} /> {yaAprobado ? 'Regenerar padrón definitivo' : 'Aprobar padrón definitivo'}
                  </button>
                </div>
              </div>

              {electores.length > 0 && (
                <div className="panel cv-form">
                  <div className="cv-section-head">
                    <div>
                      <h3>Padrón definitivo</h3>
                      <p className="muted">{electoresFiltrados.length} de {electores.length} registros</p>
                    </div>
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={exportarPadron}>
                      <MenuIcon name="download" size={15} /> Exportar CSV
                    </button>
                  </div>
                  <div className="pd-toolbar">
                    <select className="pd-select" value={cargoPadron} onChange={(e) => { setCargoPadron(e.target.value); setPaginaPadron(1); }}>
                      <option value="TODOS">Todos los cargos</option>
                      {cargosPadron.map((c) => <option key={c} value={c}>{c}</option>)}
                    </select>
                    <input className="pd-search" placeholder="Buscar por DNI o nombre…" value={busquedaPadron}
                      onChange={(e) => { setBusquedaPadron(e.target.value); setPaginaPadron(1); }} />
                  </div>
                  <TablaPaginada
                    filas={electoresFiltrados}
                    pagina={paginaPadron}
                    onPagina={setPaginaPadron}
                    vacio="Sin coincidencias."
                    columnas={['Cargo', 'DNI', 'Elector', 'Categoría', 'Facultad', 'Mesa']}
                    renderFila={(e) => (
                      <tr key={`${e.idCargo}-${e.idDocente}`}>
                        <td>{e.cargo}</td>
                        <td className="mono">{e.dni}</td>
                        <td><strong>{e.docente}</strong></td>
                        <td>{e.categoria}</td>
                        <td>{e.facultad}</td>
                        <td>{e.numeroMesa ?? '—'}</td>
                      </tr>
                    )}
                  />
                </div>
              )}
            </section>
          )}
        </div>
      )}

      {confirmando && detalle && (
        <div className="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="pd-confirm-title">
          <div className="modal-card small cv-confirm">
            <h2 id="pd-confirm-title">{yaAprobado ? '¿Regenerar el padrón definitivo?' : '¿Aprobar el padrón definitivo?'}</h2>
            <p>
              Se {yaAprobado ? 'reemplazará el padrón de' : 'generará el padrón de'} «{detalle.proceso.nombre}» con{' '}
              {detalle.cargos.reduce((s, c) => s + num(c.previstos), 0)} registros de votación según los docentes habilitados.
              Solo votarán quienes figuren en él (RN04).
            </p>
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" disabled={saving} onClick={() => setConfirmando(false)}>Cancelar</button>
              <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={confirmarAprobacion}>
                {saving ? 'Generando…' : 'Sí, aprobar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function Stat({ label, value, sub, tone, small }) {
  return (
    <article className={`pd-stat${tone ? ` ${tone}` : ''}`}>
      <span className="pd-stat-label">{label}</span>
      <strong className={small ? 'small' : ''}>{value ?? '…'}</strong>
      {sub && <span className="pd-stat-sub">{sub}</span>}
    </article>
  );
}

function TablaPaginada({ filas, pagina, onPagina, columnas, renderFila, vacio }) {
  const paginas = Math.max(1, Math.ceil(filas.length / POR_PAGINA));
  const actual = Math.min(pagina, paginas);
  const visibles = filas.slice((actual - 1) * POR_PAGINA, actual * POR_PAGINA);
  return (
    <>
      <div className="table-wrap">
        <table>
          <thead><tr>{columnas.map((c) => <th key={c}>{c}</th>)}</tr></thead>
          <tbody>
            {visibles.map(renderFila)}
            {visibles.length === 0 && <tr><td colSpan={columnas.length} className="empty-state">{vacio}</td></tr>}
          </tbody>
        </table>
      </div>
      {paginas > 1 && (
        <div className="pd-pager">
          <button type="button" className="cv-btn cv-btn-ghost" disabled={actual === 1} onClick={() => onPagina(actual - 1)}>Anterior</button>
          <span>Página {actual} de {paginas}</span>
          <button type="button" className="cv-btn cv-btn-ghost" disabled={actual === paginas} onClick={() => onPagina(actual + 1)}>Siguiente</button>
        </div>
      )}
    </>
  );
}
