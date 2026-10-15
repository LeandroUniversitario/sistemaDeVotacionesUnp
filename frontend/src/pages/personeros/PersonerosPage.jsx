import { useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import './personeros.css';

/**
 * CUS05 · Acreditar personeros — «PantallaPersoneros» (boundary).
 *
 * Mensajes del diagrama de colaboración que origina esta pantalla:
 *   1 solicitarAcreditacion(id_lista, dni)  → 2 verificarRequisitos(dni)   → ValidarPersonero
 *   5 confirmarAcreditacion(tipo, id_mesa)  → 6 guardarAcreditacion(datos) → AcreditarPersonero
 * y los que recibe: 4 mostrarDatosPersonero(docente), 8 notificarExito().
 */

const TIPOS = [
  { codigo: 'GENERAL', titulo: 'Personero general', desc: 'Representa a la lista ante el CEUNP en todo el proceso.' },
  { codigo: 'ALTERNO', titulo: 'Personero alterno', desc: 'Reemplaza al personero general en su ausencia.' },
  { codigo: 'MESA', titulo: 'Personero de mesa', desc: 'Fiscaliza una mesa de sufragio el día de la elección.' },
];

const ESTADO_LISTA = { INSCRITA: 'creado', ADMITIDA: 'votacion', TACHADA: 'anulado', EXCLUIDA: 'anulado' };
const ESTADO_PERSONERO = { ACREDITADO: 'votacion', PENDIENTE: 'creado', REVOCADO: 'anulado' };

const fmt = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
const fecha = (v) => (v ? fmt.format(new Date(v)) : '—');
const vigentes = (l) => l.personeros.filter((p) => p.estadoAcreditacion !== 'REVOCADO');

export default function PersonerosPage({ onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);      // { proceso, mesas, listas }
  const [idLista, setIdLista] = useState(null);
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  // Solicitud de acreditación
  const [dni, setDni] = useState('');
  const [validacion, setValidacion] = useState(null);
  const [tipo, setTipo] = useState('');
  const [idMesa, setIdMesa] = useState('');

  // Revocación
  const [revocando, setRevocando] = useState(null);  // personero
  const [motivo, setMotivo] = useState('');

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/personeros/procesos');
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
    limpiarSolicitud();
    try {
      const data = await apiRequest(`/api/personeros/procesos/${id}`);
      setDetalle(data);
      setIdLista(data.listas.find((l) => l.habil)?.id ?? data.listas[0]?.id ?? null);
    } catch (error) {
      manejarError(error);
    }
  }

  function limpiarSolicitud() {
    setDni('');
    setValidacion(null);
    setTipo('');
    setIdMesa('');
  }

  function elegirLista(id) {
    setIdLista(id);
    limpiarSolicitud();
    setRevocando(null);
    setFeedback(null);
  }

  const lista = detalle?.listas.find((l) => l.id === idLista);
  const admite = Boolean(detalle?.proceso?.admiteAcreditacion);
  const puedeAcreditar = admite && lista?.habil;

  // ─── 1 solicitarAcreditacion(id_lista, dni) → 2 verificarRequisitos(dni) ─
  async function solicitarAcreditacion(event) {
    event.preventDefault();
    setSaving(true);
    setFeedback(null);
    setValidacion(null);
    setTipo('');
    setIdMesa('');
    try {
      // 4 mostrarDatosPersonero(docente)
      const data = await apiRequest(`/api/personeros/listas/${idLista}/validar?dni=${encodeURIComponent(dni)}`);
      setValidacion(data);
      const libre = data.cupos.general ? 'GENERAL' : data.cupos.alterno ? 'ALTERNO' : data.cupos.mesas.length ? 'MESA' : '';
      setTipo(libre);
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  // ─── 5 confirmarAcreditacion(tipo, id_mesa) → 6 guardarAcreditacion(datos)
  async function confirmarAcreditacion() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/personeros/listas/${idLista}`, {
        method: 'POST',
        body: JSON.stringify({ idDocente: validacion.docente.id, tipo, idMesa: tipo === 'MESA' ? Number(idMesa) : null }),
      });
      // 8 notificarExito()
      setDetalle({ proceso: data.proceso, mesas: data.mesas, listas: data.listas });
      setFeedback({ type: 'success', text: data.mensaje });
      limpiarSolicitud();
      setProcesos(await apiRequest('/api/personeros/procesos'));
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  async function revocar() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/personeros/${revocando.id}/revocar`, {
        method: 'POST',
        body: JSON.stringify({ motivo }),
      });
      setDetalle({ proceso: data.proceso, mesas: data.mesas, listas: data.listas });
      setFeedback({ type: 'success', text: data.mensaje });
      setRevocando(null);
      setMotivo('');
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  if (cargando) return <p className="empty-state">Cargando…</p>;
  if (procesos.length === 0) {
    return (
      <div className="panel cv-placeholder">
        <span className="cv-placeholder-icon"><MenuIcon name="person" size={28} /></span>
        <h2>No hay procesos con listas</h2>
        <p className="muted">Los personeros se acreditan para listas inscritas en un proceso publicado (CUS01 y CUS03).</p>
      </div>
    );
  }

  const cupoDisponible = (c) => {
    if (!validacion) return false;
    if (c === 'GENERAL') return validacion.cupos.general;
    if (c === 'ALTERNO') return validacion.cupos.alterno;
    return validacion.cupos.mesas.length > 0;
  };
  const listoParaConfirmar = validacion?.apto && tipo && cupoDisponible(tipo) && (tipo !== 'MESA' || idMesa);
  const totalMesas = detalle?.mesas.length ?? 0;

  return (
    <div className="pd-shell ps-shell">
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => abrirProceso(Number(e.target.value))}>
            {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
          </select>
        </label>
        {detalle && (
          <div className={`in-plazo ${admite ? 'open' : 'closed'}`}>
            <MenuIcon name={admite ? 'person' : 'lock'} size={18} />
            <div>
              <strong>{admite ? 'Acreditación abierta' : 'Acreditación cerrada'}</strong>
              <span>{admite ? `${totalMesas} mesa${totalMesas === 1 ? '' : 's'} de sufragio creada${totalMesas === 1 ? '' : 's'}` : `El proceso está en ${detalle.proceso.estado}.`}</span>
            </div>
          </div>
        )}
      </section>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}

      <div className="in-layout">
        {/* ── Listas ───────────────────────────────────────────── */}
        <aside className="panel ps-listas">
          <h3>Listas del proceso</h3>
          {detalle?.listas.length === 0 && <p className="in-empty">No hay listas inscritas.</p>}
          <ul>
            {detalle?.listas.map((l) => {
              const v = vigentes(l);
              const general = v.some((p) => p.tipo === 'GENERAL');
              const alterno = v.some((p) => p.tipo === 'ALTERNO');
              const mesa = v.filter((p) => p.tipo === 'MESA').length;
              return (
                <li key={l.id}>
                  <button type="button" className={`in-lista${idLista === l.id ? ' active' : ''}${l.habil ? '' : ' off'}`} onClick={() => elegirLista(l.id)}>
                    <span className="in-simbolo" aria-hidden="true">{l.nombre.charAt(0).toUpperCase()}</span>
                    <span className="in-lista-body">
                      <strong>{l.nombre}</strong>
                      <span>{l.cargo}</span>
                      <span className="ps-cupos">
                        <i className={general ? 'on' : ''}>G</i>
                        <i className={alterno ? 'on' : ''}>A</i>
                        <i className={mesa ? 'on' : ''}>M {mesa}/{totalMesas}</i>
                      </span>
                    </span>
                    <span className={`cv-estado ${ESTADO_LISTA[l.estado] ?? ''}`}>{l.estado}</span>
                  </button>
                </li>
              );
            })}
          </ul>
        </aside>

        {/* ── Lista seleccionada ───────────────────────────────── */}
        <section className="in-work">
          {!lista && (
            <div className="panel cv-placeholder">
              <span className="cv-placeholder-icon"><MenuIcon name="person" size={28} /></span>
              <h2>Acreditar personeros</h2>
              <p className="muted">Elija una lista para ver y acreditar a sus personeros.</p>
            </div>
          )}

          {lista && (
            <>
              <div className="panel cv-form">
                <div className="cv-section-head">
                  <div className="in-lista-head">
                    <span className="in-simbolo lg" aria-hidden="true">{lista.nombre.charAt(0).toUpperCase()}</span>
                    <div>
                      <h3>{lista.nombre}</h3>
                      <p className="muted">{lista.cargo} · {vigentes(lista).length} personero(s) acreditado(s)</p>
                    </div>
                  </div>
                  <span className={`cv-estado ${ESTADO_LISTA[lista.estado] ?? ''}`}>{lista.estado}</span>
                </div>
                {!lista.habil && <p className="tc-aviso ps-aviso"><MenuIcon name="lock" size={14} /> La lista está {lista.estado}: no puede acreditar personeros.</p>}

                {lista.personeros.length === 0 ? (
                  <p className="empty-state">La lista aún no tiene personeros.</p>
                ) : (
                  <div className="table-wrap">
                    <table>
                      <thead><tr><th>Tipo</th><th>Personero</th><th>Mesa</th><th>Acreditado</th><th>Estado</th><th aria-label="Acciones" /></tr></thead>
                      <tbody>
                        {lista.personeros.map((p) => (
                          <tr key={p.id} className={p.estadoAcreditacion === 'REVOCADO' ? 'ps-revocado' : ''}>
                            <td><span className={`ps-tipo ${p.tipo.toLowerCase()}`}>{p.tipo}</span></td>
                            <td><strong>{p.docente}</strong><small className="pd-sub">DNI {p.dni} · {p.categoria}</small></td>
                            <td>{p.numeroMesa ?? '—'}</td>
                            <td>{fecha(p.fechaAcreditacion)}</td>
                            <td><span className={`cv-estado ${ESTADO_PERSONERO[p.estadoAcreditacion] ?? ''}`}>{p.estadoAcreditacion}</span></td>
                            <td>
                              {admite && p.estadoAcreditacion !== 'REVOCADO' && (
                                <button type="button" className="cv-icon-btn" title="Revocar acreditación" aria-label={`Revocar a ${p.docente}`}
                                  onClick={() => { setRevocando(p); setMotivo(''); setFeedback(null); }}>
                                  <MenuIcon name="close" size={16} />
                                </button>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}

                {revocando && (
                  <div className="ps-revocar">
                    <label className="cv-field">
                      <span className="cv-label">Motivo para revocar a {revocando.docente}</span>
                      <input value={motivo} maxLength={500} placeholder="Ej.: renuncia presentada por la lista" onChange={(e) => setMotivo(e.target.value)} />
                    </label>
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setRevocando(null)}>Cancelar</button>
                      <button type="button" className="cv-btn tc-btn-danger ps-danger" disabled={saving || motivo.trim().length < 10} onClick={revocar}>
                        Revocar acreditación
                      </button>
                    </div>
                  </div>
                )}
              </div>

              {puedeAcreditar && (
                <div className="panel cv-form">
                  <div className="cv-section-head">
                    <div>
                      <h3>Solicitar acreditación</h3>
                      <p className="muted">Ingrese el DNI del docente propuesto por la lista. Se verifican RN20 y RN21 antes de acreditar.</p>
                    </div>
                  </div>

                  <form className="in-search-row" onSubmit={solicitarAcreditacion}>
                    <input inputMode="numeric" maxLength={8} placeholder="DNI del docente" value={dni} aria-label="DNI del personero"
                      onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))} />
                    <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !dni}>
                      <MenuIcon name="search" size={15} /> Verificar requisitos
                    </button>
                  </form>

                  {validacion && (
                    <div className="in-result">
                      <div className="in-cand">
                        <div className="in-avatar">{validacion.docente.nombre.charAt(0)}</div>
                        <div className="in-cand-body">
                          <strong>{validacion.docente.nombre}</strong>
                          <span>DNI {validacion.docente.dni} · {validacion.docente.categoria} · {validacion.docente.dedicacion}</span>
                          <span>{validacion.docente.facultad} · {validacion.docente.departamento}</span>
                        </div>
                        <span className={`cv-estado ${validacion.apto ? 'votacion' : 'anulado'}`}>{validacion.apto ? 'Apto' : 'No apto'}</span>
                      </div>
                      <ul className="in-reqs">
                        {validacion.requisitos.map((r) => (
                          <li key={r.codigo} className={r.estado.toLowerCase()}>
                            <span className="cv-check-icon"><MenuIcon name={r.estado === 'OK' ? 'check' : 'close'} size={13} /></span>
                            {r.descripcion}
                          </li>
                        ))}
                      </ul>

                      {validacion.apto && (
                        <>
                          <span className="cv-label">Tipo de personero</span>
                          <div className="ps-tipos" role="radiogroup">
                            {TIPOS.map((t) => {
                              const libre = cupoDisponible(t.codigo);
                              return (
                                <button key={t.codigo} type="button" role="radio" aria-checked={tipo === t.codigo} disabled={!libre}
                                  className={`ps-tipo-card${tipo === t.codigo ? ' on' : ''}`} onClick={() => setTipo(t.codigo)}>
                                  <strong>{t.titulo}</strong>
                                  <span>{t.desc}</span>
                                  <em>{libre ? (t.codigo === 'MESA' ? `${validacion.cupos.mesas.length} mesa(s) libre(s)` : 'Cupo libre') : t.codigo === 'MESA' && totalMesas === 0 ? 'Aún no hay mesas (CUS06)' : 'Cupo ocupado'}</em>
                                </button>
                              );
                            })}
                          </div>
                          {tipo === 'MESA' && (
                            <label className="cv-field">
                              <span className="cv-label">Mesa de sufragio</span>
                              <select value={idMesa} onChange={(e) => setIdMesa(e.target.value)}>
                                <option value="">Seleccione la mesa…</option>
                                {validacion.cupos.mesas.map((m) => <option key={m.id} value={m.id}>Mesa {m.numeroMesa} · {m.ubicacion}</option>)}
                              </select>
                            </label>
                          )}
                          <div className="cv-actions">
                            <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarSolicitud}>Cancelar</button>
                            <button type="button" className="cv-btn cv-btn-success" disabled={saving || !listoParaConfirmar} onClick={confirmarAcreditacion}>
                              <MenuIcon name="check" size={15} /> {saving ? 'Acreditando…' : 'Confirmar acreditación'}
                            </button>
                          </div>
                        </>
                      )}
                    </div>
                  )}
                </div>
              )}
            </>
          )}
        </section>
      </div>
    </div>
  );
}
