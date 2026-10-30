import { useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import './inscripcion.css';

/**
 * CUS03 · Gestionar inscripción de listas — «PantallaInscripcion» (boundary).
 *
 * Mensajes del diagrama de colaboración que origina esta pantalla:
 *   1 ingresarDatosLista(nombre, cargo) → 2 guardarLista(datos)          → RegistrarDatosLista
 *   5 buscarCandidato(dni, rol)         → 6 comprobarRequisitos(dni)     → ValidarCandidato
 *   9 confirmarCandidato()              → 10 grabarCandidato(id_docente, rol) → AgregarCandidato
 * y los que recibe: 4 mostrarConfirmacionLista(), 8 mostrarDatosCandidato(docente), 12 actualizarVistaListas().
 */

const EMPTY_LISTA = { idCargo: '', nombre: '', simbolo: '', urlPlanGobierno: '' };

const ESTADO_LISTA = {
  INSCRITA: { label: 'Inscrita', cls: 'creado' },
  ADMITIDA: { label: 'Admitida', cls: 'votacion' },
  TACHADA: { label: 'Tachada', cls: 'anulado' },
  EXCLUIDA: { label: 'Excluida', cls: 'anulado' },
};

const ESTADO_CANDIDATO = {
  PENDIENTE: 'creado', APROBADO: 'votacion', OBSERVADO: 'inscripcion', EXCLUIDO: 'anulado',
};

const fmt = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
const formatFechaHora = (v) => (v ? fmt.format(new Date(v)) : '—');
const num = (v) => Number(v ?? 0);

function tiempoRestante(limite) {
  if (!limite) return null;
  const ms = new Date(limite) - new Date();
  if (ms <= 0) return null;
  const dias = Math.floor(ms / 86400000);
  const horas = Math.floor((ms % 86400000) / 3600000);
  return dias > 0 ? `${dias} d ${horas} h` : `${horas} h`;
}

export default function InscripcionPage({ onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);       // { proceso, cargos[] }
  const [cargando, setCargando] = useState(true);

  const [vista, setVista] = useState(null);           // null | 'nueva' | { idLista }
  const [listaForm, setListaForm] = useState(EMPTY_LISTA);

  // Búsqueda de candidato para un rol de la lista seleccionada
  const [slot, setSlot] = useState(null);             // { rol, etiqueta }
  const [dni, setDni] = useState('');
  const [validacion, setValidacion] = useState(null); // respuesta de ValidarCandidato
  const [urlHojaVida, setUrlHojaVida] = useState('');

  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/inscripcion/procesos');
        setProcesos(lista);
        if (lista[0]) await abrirProceso(lista[0].id);
      } catch (error) {
        manejarError(error);
      } finally {
        setCargando(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function abrirProceso(id) {
    setIdProceso(id);
    setVista(null);
    cerrarBusqueda();
    try {
      setDetalle(await apiRequest(`/api/inscripcion/procesos/${id}`));
    } catch (error) {
      manejarError(error);
    }
  }

  function aplicarDetalle(data) {
    setDetalle({ proceso: data.proceso, cargos: data.cargos });
  }

  const proceso = detalle?.proceso;
  const plazoAbierto = Boolean(num(proceso?.plazoAbierto));
  const cargos = detalle?.cargos ?? [];
  const listaSel = useMemo(() => {
    if (!vista?.idLista) return null;
    for (const c of cargos) {
      const l = c.listas.find((x) => x.id === vista.idLista);
      if (l) return { ...l, cargo: c };
    }
    return null;
  }, [vista, cargos]);

  // ─── 1 ingresarDatosLista(nombre, cargo) → 2 guardarLista(datos) ─────────
  function nuevaLista(idCargo = '') {
    setVista('nueva');
    const autoCargo = idCargo ? String(idCargo) : (cargos.length === 1 ? String(cargos[0].id) : '');
    setListaForm({ ...EMPTY_LISTA, idCargo: autoCargo });
    cerrarBusqueda();
    setFeedback(null);
  }

  async function ingresarDatosLista(event) {
    event.preventDefault();
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest('/api/inscripcion/listas', {
        method: 'POST',
        body: JSON.stringify({ ...listaForm, idCargo: Number(listaForm.idCargo) }),
      });
      // 4 mostrarConfirmacionLista()
      aplicarDetalle(data);
      setVista({ idLista: data.idLista });
      setFeedback({ type: 'success', text: data.mensaje });
      setProcesos(await apiRequest('/api/inscripcion/procesos'));
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  async function retirarLista(lista) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/inscripcion/listas/${lista.id}`, { method: 'DELETE' });
      aplicarDetalle(data);
      setVista(null);
      setFeedback({ type: 'success', text: data.mensaje });
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  // ─── 5 buscarCandidato(dni, rol) → 6 comprobarRequisitos(dni) ────────────
  function abrirBusqueda(rol) {
    setSlot(rol);
    setDni('');
    setValidacion(null);
    setUrlHojaVida('');
    setFeedback(null);
  }

  function cerrarBusqueda() {
    setSlot(null);
    setDni('');
    setValidacion(null);
    setUrlHojaVida('');
  }

  async function buscarCandidato(event) {
    event.preventDefault();
    if (!dni.trim()) return;
    setSaving(true);
    setValidacion(null);
    setFeedback(null);
    try {
      // 8 mostrarDatosCandidato(docente)
      setValidacion(await apiRequest(
        `/api/inscripcion/listas/${listaSel.id}/validar?dni=${encodeURIComponent(dni.trim())}&rol=${encodeURIComponent(slot.codigo)}`,
      ));
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  // ─── 9 confirmarCandidato() → 10 grabarCandidato(id_docente, rol) ────────
  async function confirmarCandidato() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/inscripcion/listas/${listaSel.id}/candidatos`, {
        method: 'POST',
        body: JSON.stringify({ idDocente: validacion.docente.id, rol: slot.codigo, urlHojaVida }),
      });
      // 12 actualizarVistaListas()
      aplicarDetalle(data);
      cerrarBusqueda();
      setFeedback({ type: 'success', text: data.mensaje });
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  async function quitarCandidato(candidato) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/inscripcion/candidatos/${candidato.id}`, { method: 'DELETE' });
      aplicarDetalle(data);
      setFeedback({ type: 'success', text: data.mensaje });
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  // ─── Render ─────────────────────────────────────────────────────────────
  if (cargando) return <p className="empty-state">Cargando…</p>;

  if (procesos.length === 0) {
    return (
      <div className="panel cv-placeholder">
        <span className="cv-placeholder-icon"><MenuIcon name="ballot" size={28} /></span>
        <h2>No hay procesos con inscripción</h2>
        <p className="muted">Publique una convocatoria en «Convocatoria y cronograma» (CUS01) para abrir la inscripción de listas.</p>
      </div>
    );
  }

  const restante = tiempoRestante(proceso?.fechaLimiteInscripcion);
  const editable = plazoAbierto && listaSel?.estado === 'INSCRITA';

  return (
    <div className="pd-shell in-shell">
      {/* ── Proceso y plazo ─────────────────────────────────────── */}
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => abrirProceso(Number(e.target.value))}>
            {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
          </select>
        </label>
        {proceso && (
          <div className={`in-plazo ${plazoAbierto ? 'open' : 'closed'}`}>
            <MenuIcon name={plazoAbierto ? 'calendar' : 'lock'} size={18} />
            <div>
              <strong>{plazoAbierto ? 'Inscripción abierta' : 'Inscripción cerrada'}</strong>
              <span>
                {proceso.fechaLimiteInscripcion
                  ? `${plazoAbierto ? 'Hasta' : 'Cerró el'} ${formatFechaHora(proceso.fechaLimiteInscripcion)}${restante ? ` · quedan ${restante}` : ''}`
                  : `Proceso en ${proceso.estado}`}
              </span>
            </div>
          </div>
        )}
        {plazoAbierto && (
          <button type="button" className="cv-btn cv-btn-primary" onClick={() => nuevaLista()}>
            <MenuIcon name="plus" size={16} /> Inscribir lista
          </button>
        )}
      </section>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}

      <div className="in-layout">
        {/* ── Cargos y listas ──────────────────────────────────── */}
        <aside className="in-cargos">
          {cargos.map((c) => (
            <section key={c.id} className="panel in-cargo">
              <header>
                <div>
                  <h3>{c.nombre}</h3>
                  <span className="muted">{c.jurisdiccion ?? 'Toda la universidad'} · {c.listas.length} lista{c.listas.length === 1 ? '' : 's'}</span>
                </div>
                {plazoAbierto && (
                  <button type="button" className="cv-icon-btn in-add" title={`Inscribir lista para ${c.nombre}`} onClick={() => nuevaLista(c.id)}>
                    <MenuIcon name="plus" size={18} />
                  </button>
                )}
              </header>
              {c.listas.length === 0 && <p className="in-empty">Sin listas inscritas.</p>}
              <ul>
                {c.listas.map((l) => (
                  <li key={l.id}>
                    <button
                      type="button"
                      className={`in-lista${vista?.idLista === l.id ? ' active' : ''}`}
                      onClick={() => { setVista({ idLista: l.id }); cerrarBusqueda(); setFeedback(null); }}
                    >
                      <span className="in-simbolo" aria-hidden="true">{l.nombre.charAt(0).toUpperCase()}</span>
                      <span className="in-lista-body">
                        <strong>{l.nombre}</strong>
                        <span>{l.candidatos.length}/{c.roles.length} candidatos{l.completa ? ' · fórmula completa' : ''}</span>
                      </span>
                      <span className={`cv-estado ${ESTADO_LISTA[l.estado]?.cls ?? ''}`}>{ESTADO_LISTA[l.estado]?.label ?? l.estado}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </section>
          ))}
          {cargos.length === 0 && <p className="empty-state">El proceso no tiene cargos.</p>}
        </aside>

        {/* ── Área de trabajo ──────────────────────────────────── */}
        <section className="in-work">
          {!vista && (
            <div className="panel cv-placeholder">
              <span className="cv-placeholder-icon"><MenuIcon name="ballot" size={28} /></span>
              <h2>Inscripción de listas</h2>
              <p className="muted">
                Inscriba la lista con su nombre y cargo, y luego registre a cada candidato buscándolo por DNI.
                El sistema comprueba los requisitos (RN09, RN11, RN20, RN21, RF03) antes de grabarlo.
              </p>
              {plazoAbierto && (
                <button type="button" className="cv-btn cv-btn-primary" onClick={() => nuevaLista()}>
                  <MenuIcon name="plus" size={16} /> Inscribir lista
                </button>
              )}
            </div>
          )}

          {vista === 'nueva' && (
            <form className="panel cv-form" onSubmit={ingresarDatosLista}>
              <div className="cv-section-head">
                <div>
                  <h3>Inscribir lista</h3>
                  <p className="muted">RN13: solo dentro del plazo de inscripción. RN17: el símbolo no puede ser una bandera ni la foto de una persona.</p>
                </div>
              </div>
              <div className="cv-grid two">
                <label className="cv-field">
                  <span className="cv-label">Cargo al que postula</span>
                  {cargos.length === 1 ? (
                    <div style={{
                      height: 42,
                      display: 'flex',
                      alignItems: 'center',
                      padding: '0 12px',
                      background: '#f8fafc',
                      border: '1px solid #cbd5e1',
                      borderRadius: 8,
                      fontWeight: 700,
                      color: '#0f172a',
                      fontSize: '.875rem'
                    }}>
                      {cargos[0].nombre}{cargos[0].jurisdiccion ? ` — ${cargos[0].jurisdiccion}` : ''}
                    </div>
                  ) : (
                    <select required value={listaForm.idCargo} onChange={(e) => setListaForm({ ...listaForm, idCargo: e.target.value })}>
                      <option value="">Seleccione…</option>
                      {cargos.map((c) => <option key={c.id} value={c.id}>{c.nombre}{c.jurisdiccion ? ` — ${c.jurisdiccion}` : ''}</option>)}
                    </select>
                  )}
                </label>
                <label className="cv-field">
                  <span className="cv-label">Nombre de la lista</span>
                  <input required maxLength={150} value={listaForm.nombre} placeholder="Ej.: Unidad Universitaria"
                    onChange={(e) => setListaForm({ ...listaForm, nombre: e.target.value })} />
                </label>
                <label className="cv-field">
                  <span className="cv-label">Símbolo (descripción)</span>
                  <input maxLength={100} value={listaForm.simbolo} placeholder="Ej.: Estrella azul"
                    onChange={(e) => setListaForm({ ...listaForm, simbolo: e.target.value })} />
                </label>
                <label className="cv-field">
                  <span className="cv-label">Plan de gobierno (enlace, RN15)</span>
                  <input type="url" maxLength={300} value={listaForm.urlPlanGobierno} placeholder="https://…"
                    onChange={(e) => setListaForm({ ...listaForm, urlPlanGobierno: e.target.value })} />
                </label>
              </div>
              {listaForm.idCargo && (
                <p className="in-hint">
                  Fórmula requerida: {cargos.find((c) => String(c.id) === listaForm.idCargo)?.roles.map((r) => r.etiqueta).join(' + ')}
                </p>
              )}
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setVista(null)}>Cancelar</button>
                <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !listaForm.idCargo || !listaForm.nombre.trim()}>
                  {saving ? 'Guardando…' : 'Inscribir lista'}
                </button>
              </div>
            </form>
          )}

          {listaSel && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div className="in-lista-head">
                  <span className="in-simbolo lg" aria-hidden="true">{listaSel.nombre.charAt(0).toUpperCase()}</span>
                  <div>
                    <h3>{listaSel.nombre}</h3>
                    <p className="muted">
                      {listaSel.cargo.nombre}{listaSel.cargo.jurisdiccion ? ` — ${listaSel.cargo.jurisdiccion}` : ''}
                      {listaSel.simbolo ? ` · Símbolo: ${listaSel.simbolo}` : ''}
                      {' · '}Inscrita el {formatFechaHora(listaSel.fechaInscripcion)}
                    </p>
                    {listaSel.urlPlanGobierno && (
                      <a className="in-link" href={listaSel.urlPlanGobierno} target="_blank" rel="noreferrer">
                        <MenuIcon name="file" size={14} /> Plan de gobierno
                      </a>
                    )}
                  </div>
                </div>
                <span className={`cv-estado ${ESTADO_LISTA[listaSel.estado]?.cls ?? ''}`}>{ESTADO_LISTA[listaSel.estado]?.label}</span>
              </div>

              <div className={`in-formula-status ${listaSel.completa ? 'ok' : ''}`}>
                <MenuIcon name={listaSel.completa ? 'check' : 'alert'} size={16} />
                {listaSel.completa
                  ? 'Fórmula completa (RN10). Queda pendiente la calificación del CEUNP.'
                  : `Fórmula incompleta (RN10): faltan ${listaSel.rolesFaltantes.length} candidato(s).`}
              </div>

              {/* Fórmula: un espacio por rol */}
              <ul className="in-formula">
                {listaSel.cargo.roles.map((rol) => {
                  const cand = listaSel.candidatos.find((c) => c.rolEnLista === rol.codigo && c.estadoValidacion !== 'EXCLUIDO');
                  const buscando = slot?.codigo === rol.codigo;
                  return (
                    <li key={rol.codigo} className={`in-slot${cand ? ' filled' : ''}${buscando ? ' searching' : ''}`}>
                      <span className="in-slot-rol">{rol.etiqueta}</span>
                      {cand ? (
                        <div className="in-cand">
                          <div className="in-avatar">{cand.docente.charAt(0)}</div>
                          <div className="in-cand-body">
                            <strong>{cand.docente}</strong>
                            <span>DNI {cand.dni} · {cand.categoria}{cand.gradoAcademico ? ` · ${cand.gradoAcademico}` : ''}</span>
                            {cand.urlHojaVida && <a className="in-link" href={cand.urlHojaVida} target="_blank" rel="noreferrer">Hoja de vida</a>}
                          </div>
                          <span className={`cv-estado ${ESTADO_CANDIDATO[cand.estadoValidacion] ?? ''}`}>{cand.estadoValidacion}</span>
                          {editable && (
                            <button type="button" className="cv-icon-btn" title="Quitar candidato" aria-label={`Quitar a ${cand.docente}`}
                              disabled={saving || num(cand.totalTachas) > 0} onClick={() => quitarCandidato(cand)}>
                              <MenuIcon name="trash" size={16} />
                            </button>
                          )}
                        </div>
                      ) : buscando ? (
                        <BuscadorCandidato
                          dni={dni}
                          setDni={setDni}
                          onBuscar={buscarCandidato}
                          onCancelar={cerrarBusqueda}
                          validacion={validacion}
                          urlHojaVida={urlHojaVida}
                          setUrlHojaVida={setUrlHojaVida}
                          onConfirmar={confirmarCandidato}
                          saving={saving}
                        />
                      ) : (
                        <div className="in-vacante">
                          <span>Vacante</span>
                          {editable && (
                            <button type="button" className="cv-btn cv-btn-soft" onClick={() => abrirBusqueda(rol)}>
                              <MenuIcon name="search" size={15} /> Buscar candidato
                            </button>
                          )}
                        </div>
                      )}
                    </li>
                  );
                })}
              </ul>

              {listaSel.candidatos.filter((c) => c.estadoValidacion === 'EXCLUIDO').length > 0 && (
                <p className="in-hint">
                  Excluidos: {listaSel.candidatos.filter((c) => c.estadoValidacion === 'EXCLUIDO').map((c) => c.docente).join(', ')}
                </p>
              )}

              <div className="cv-actions">
                {editable && (
                  <button type="button" className="cv-btn cv-btn-ghost in-danger" disabled={saving || num(listaSel.totalTachas) > 0}
                    onClick={() => retirarLista(listaSel)}>
                    <MenuIcon name="trash" size={15} /> Retirar lista
                  </button>
                )}
                {!editable && (
                  <span className="muted">
                    {plazoAbierto ? 'La lista ya fue calificada por el CEUNP.' : 'El plazo de inscripción terminó (RN13): la lista ya no admite cambios.'}
                  </span>
                )}
              </div>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

/** 5 buscarCandidato(dni, rol) · 8 mostrarDatosCandidato(docente) · 9 confirmarCandidato() */
function BuscadorCandidato({ dni, setDni, onBuscar, onCancelar, validacion, urlHojaVida, setUrlHojaVida, onConfirmar, saving }) {
  return (
    <div className="in-search">
      <form className="in-search-row" onSubmit={onBuscar}>
        <input autoFocus inputMode="numeric" maxLength={8} placeholder="DNI del docente" value={dni}
          onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))} aria-label="DNI del candidato" />
        <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || dni.length === 0}>
          <MenuIcon name="search" size={15} /> {saving && !validacion ? 'Buscando…' : 'Buscar'}
        </button>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
      </form>

      {validacion && (
        <div className="in-result">
          <div className="in-cand">
            <div className="in-avatar">{validacion.docente.nombre.charAt(0)}</div>
            <div className="in-cand-body">
              <strong>{validacion.docente.nombre}</strong>
              <span>
                DNI {validacion.docente.dni} · {validacion.docente.categoria} · {validacion.docente.dedicacion}
                {validacion.docente.gradoAcademico ? ` · ${validacion.docente.gradoAcademico}` : ''}
              </span>
              <span>{validacion.docente.facultad} · {validacion.docente.departamento}</span>
            </div>
            <span className={`cv-estado ${validacion.apto ? 'votacion' : 'anulado'}`}>{validacion.apto ? 'Apto' : 'No apto'}</span>
          </div>

          <ul className="in-reqs">
            {validacion.requisitos.map((r) => (
              <li key={r.codigo} className={r.estado.toLowerCase()}>
                <span className="cv-check-icon">
                  <MenuIcon name={r.estado === 'OK' ? 'check' : r.estado === 'FALLA' ? 'close' : 'alert'} size={13} />
                </span>
                {r.descripcion}
              </li>
            ))}
          </ul>

          {validacion.apto && (
            <div className="in-confirm">
              <label className="cv-field">
                <span className="cv-label">Hoja de vida (enlace, RN15) — opcional</span>
                <input type="url" maxLength={300} placeholder="https://…" value={urlHojaVida} onChange={(e) => setUrlHojaVida(e.target.value)} />
              </label>
              <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onConfirmar}>
                <MenuIcon name="check" size={15} /> {saving ? 'Grabando…' : 'Confirmar candidato'}
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
