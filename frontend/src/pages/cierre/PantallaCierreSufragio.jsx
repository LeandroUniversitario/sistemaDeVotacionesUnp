import { useCallback, useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { CodigoQR, fecha } from '../credenciales/LectorQR';
import { urlVerificacionActa } from '../instalacion/ActaInstalacion';
import { imprimirActaSufragio, imprimirListaNoVoto } from './ActaSufragio';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import './cierre.css';

/**
 * CUS11 · Cerrar sufragio — «PantallaCierreSufragio» (boundary). Actor: Presidente de mesa.
 *
 * Mensajes del diagrama de colaboración «Colaboracion - Cerrar Sufragio»:
 *   1 solicitarCierre(id_mesa) → 2 cerrarVotacion(id_mesa) → CerrarVotacion
 *     3 actualizarEstado('CERRADA', hora_cierre) → MesaElectoral · 4 mostrarTotalVotantes(total)
 *   5 confirmarAusentes() → 6 marcarAusentes(id_mesa) → MarcarAusentes
 *     7 actualizarNoVoto(id_mesa) → PadronMesa · 8 mostrarListaNoVoto()
 *   9 ingresarObservaciones(cedulas_no_usadas, observaciones) → 10 generarActa(datos) → GenerarActaSufragio
 *     11 insertarActa('SUFRAGIO', hash, contenido) · 12 registrarFirmas(firmas) · 13 mostrarActaSufragio()
 *
 * Flujos alternos (tabla 37): A1 electores aún votando a las 15:00 y A2 diferencia con la lista física.
 */

const PASOS = [
  { codigo: 'CERRAR', texto: '1. Cerrar la votación' },
  { codigo: 'AUSENTES', texto: '2. Marcar NO VOTÓ' },
  { codigo: 'ACTA', texto: '3. Acta de sufragio' },
];
const ORDEN = ['CERRAR', 'AUSENTES', 'ACTA', 'EMITIDA'];
const CARGO = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario' };
const ORIGEN = { TITULAR: 'Titular', SUPLENTE: 'Suplente', REEMPLAZANTE: 'Reemplazante' };
const ESTADO_MESA = {
  PENDIENTE: { clase: 'creado', texto: 'Por instalar' },
  INSTALADA: { clase: 'votacion', texto: 'Sufragio abierto' },
  CERRADA: { clase: 'inscripcion', texto: 'Sufragio cerrado' },
  NO_INSTALADA: { clase: 'anulado', texto: 'No instalada' },
  ANULADA: { clase: 'anulado', texto: 'Anulada' },
};
const si = (v) => v === true || v === 1 || v === '1';
const hora = (v) => (v ? new Date(v).toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }) : '—');

export default function PantallaCierreSufragio({ session, onSessionExpired }) {
  const esMiembro = session.rol === 'MIEMBRO_MESA';
  const puedeOperar = esMiembro || session.rol === 'CEUNP';

  const [idDocenteSesion, setIdDocenteSesion] = useState(session.idDocente ?? null);
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [mesas, setMesas] = useState([]);
  const [idMesa, setIdMesa] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [paso, setPaso] = useState('CERRAR');
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [confirmando, setConfirmando] = useState(null);       // 'CERRAR' | 'AUSENTES' | 'ACTA'
  const [datosActa, setDatosActa] = useState({ cedulasNoUtilizadas: '', firmasListaFisica: '', observaciones: '' });
  const [personeros, setPersoneros] = useState([]);           // id_personero que firman
  const [emitida, setEmitida] = useState(null);               // { tokenQr, idActa } tras emitir

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const aplicarDetalle = useCallback((data) => {
    setDetalle(data);
    setPaso(data.paso === 'EMITIDA' ? 'ACTA' : data.paso);
    setMesas((prev) => prev.map((m) => (m.id === data.mesa.id
      ? { ...m, estado: data.mesa.estado, estadoCierre: data.registro?.estado ?? null } : m)));
  }, []);

  const cargarMesas = useCallback(async (proceso) => {
    const lista = await apiRequest(esMiembro || !proceso ? '/api/cierre/mesas' : `/api/cierre/mesas?procesoId=${proceso}`);
    setMesas(lista);
    return lista;
  }, [esMiembro]);

  useEffect(() => {
    (async () => {
      try {
        if (esMiembro && idDocenteSesion == null) {
          const yo = await apiRequest('/api/auth/me');
          setIdDocenteSesion(yo.idDocente ?? null);
        }
        let proceso = null;
        if (!esMiembro) {
          const lista = await apiRequest('/api/cierre/procesos');
          setProcesos(lista);
          proceso = lista[0]?.id ?? null;
          setIdProceso(proceso);
        }
        const lista = await cargarMesas(proceso);
        const primera = lista.find((m) => m.estado === 'INSTALADA')
          ?? lista.find((m) => m.estado === 'CERRADA' && m.estadoCierre !== 'ACTA_EMITIDA') ?? lista[0];
        if (primera) setIdMesa(primera.id);
      } catch (e) {
        manejarError(e);
      } finally {
        setCargando(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [esMiembro, cargarMesas, manejarError]);

  useEffect(() => {
    if (!idMesa) { setDetalle(null); return; }
    (async () => {
      try {
        aplicarDetalle(await apiRequest(`/api/cierre/mesas/${idMesa}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idMesa, aplicarDetalle, manejarError]);

  async function cambiarProceso(id) {
    setIdProceso(id);
    setIdMesa(null);
    setFeedback(null);
    try {
      const lista = await cargarMesas(id);
      setIdMesa((lista.find((m) => m.estado === 'INSTALADA') ?? lista[0])?.id ?? null);
    } catch (e) {
      manejarError(e);
    }
  }

  function elegirMesa(id) {
    setIdMesa(id);
    setFeedback(null);
    setConfirmando(null);
    setEmitida(null);
    setDatosActa({ cedulasNoUtilizadas: '', firmasListaFisica: '', observaciones: '' });
    setPersoneros([]);
  }

  async function ejecutar(promesa) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await promesa;
      aplicarDetalle(data.detalle);
      setFeedback({ type: 'success', text: data.mensaje });
      return data;
    } catch (e) {
      manejarError(e);
      return null;
    } finally {
      setSaving(false);
      setConfirmando(null);
    }
  }

  /** 1 solicitarCierre(id_mesa) → 2 cerrarVotacion(id_mesa) → 4 mostrarTotalVotantes(total). */
  function solicitarCierre() {
    return ejecutar(apiRequest(`/api/cierre/mesas/${idMesa}/cerrar`, { method: 'POST' }));
  }

  /** 5 confirmarAusentes() → 6 marcarAusentes(id_mesa) → 8 mostrarListaNoVoto(). */
  function confirmarAusentes() {
    return ejecutar(apiRequest(`/api/cierre/mesas/${idMesa}/ausentes`, { method: 'POST' }));
  }

  /** 9 ingresarObservaciones(cedulas_no_usadas, observaciones) → 10 generarActa(datos) → 13 mostrarActaSufragio(). */
  async function ingresarObservaciones() {
    const data = await ejecutar(apiRequest(`/api/cierre/mesas/${idMesa}/acta`, {
      method: 'POST',
      body: JSON.stringify({
        cedulasNoUtilizadas: datosActa.cedulasNoUtilizadas === '' ? null : Number(datosActa.cedulasNoUtilizadas),
        firmasListaFisica: datosActa.firmasListaFisica === '' ? null : Number(datosActa.firmasListaFisica),
        observaciones: datosActa.observaciones,
        personeros,
      }),
    }));
    if (data) setEmitida({ tokenQr: data.tokenQr, idActa: data.idActa });
  }

  async function refrescar() {
    try {
      if (!esMiembro) setProcesos(await apiRequest('/api/cierre/procesos'));
      await cargarMesas(idProceso);
      if (idMesa) aplicarDetalle(await apiRequest(`/api/cierre/mesas/${idMesa}`));
    } catch (e) {
      manejarError(e);
    }
  }

  // ─── Render ────────────────────────────────────────────────────────────

  if (cargando) return <div className="panel"><p className="muted">Cargando mesas…</p></div>;

  const proceso = procesos.find((p) => p.id === idProceso);
  const mesa = detalle?.mesa;
  const registro = detalle?.registro;
  const resumen = detalle?.resumen;
  const presidencia = detalle?.firmantes.find((f) => f.cargo === 'PRESIDENTE');
  const soyPresidente = !esMiembro || !presidencia || presidencia.origen === 'REEMPLAZANTE' || presidencia.idDocente === idDocenteSesion;
  const operable = puedeOperar && soyPresidente;
  const avance = detalle ? ORDEN.indexOf(detalle.paso) : 0;
  const votaron = registro?.totalVotaron ?? resumen?.VOTO ?? 0;
  const habiles = registro?.totalElectores ?? ((resumen?.electores ?? 0) - (resumen?.INHABILITADO ?? 0));
  const firmasFisicas = datosActa.firmasListaFisica === '' ? null : Number(datosActa.firmasListaFisica);
  const difiere = firmasFisicas != null && firmasFisicas !== votaron;
  const sugeridas = registro?.cedulasRecibidas != null ? Math.max(registro.cedulasRecibidas - votaron, 0) : null;

  return (
    <div className="pd-shell cq-shell im-shell cs-shell">
      <section className="in-head">
        {!esMiembro && (
          <label className="cv-field in-proceso">
            <span className="cv-label">Proceso electoral</span>
            <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))}>
              {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
            </select>
          </label>
        )}
        {detalle && (
          <div className={`in-plazo ${detalle.horario.alcanzada ? 'closed' : 'open'}`}>
            <MenuIcon name={detalle.horario.alcanzada ? 'lock' : 'calendar'} size={18} />
            <div>
              <strong>{detalle.horario.alcanzada ? 'Hora de cierre alcanzada' : `El sufragio termina a las ${detalle.horario.horaCierre}`}</strong>
              <span>
                RN06 · {fecha(detalle.horario.fin)} · hora del servidor {hora(detalle.horario.ahora)}
                {!detalle.horario.control && ' Control horario desactivado (SUFRAGIO_CONTROL_HORARIO = 0).'}
              </span>
            </div>
          </div>
        )}
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      {proceso && (
        <section className="cq-resumen">
          <div className="cq-kpi" style={{ '--cq-color': '#059669' }}>
            <span>Mesas con sufragio abierto</span>
            <strong>{proceso.abiertas}<small> / {proceso.mesas}</small></strong>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
            <span>Mesas cerradas <em>RF74</em></span>
            <strong>{proceso.cerradas}</strong>
            <i className="cq-barra"><b style={{ width: `${proceso.mesas ? Math.round((proceso.cerradas / proceso.mesas) * 100) : 0}%` }} /></i>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
            <span>Actas de sufragio <em>RF76</em></span>
            <strong>{proceso.actas}</strong>
            <small>{proceso.cerradas - proceso.actas} por emitir</small>
          </div>
        </section>
      )}

      {mesas.length === 0 ? (
        <div className="panel"><p className="empty-state">
          {esMiembro ? 'No figura como miembro de ninguna mesa de un proceso en curso.' : 'El proceso no tiene mesas.'}
        </p></div>
      ) : (
        <section className="im-mesas" aria-label="Mesas de sufragio">
          {mesas.map((m) => {
            const est = ESTADO_MESA[m.estado] ?? ESTADO_MESA.PENDIENTE;
            return (
              <button key={m.id} type="button" className={`im-mesa${m.id === idMesa ? ' on' : ''}`} onClick={() => elegirMesa(m.id)}>
                <span className="im-mesa-num">Mesa {m.numero}</span>
                <span className={`cv-estado ${est.clase}`}>{est.texto}</span>
                <small>{m.ubicacion}</small>
                {m.estado === 'CERRADA' && <small>{m.estadoCierre === 'ACTA_EMITIDA' ? 'Acta de sufragio emitida' : 'Acta de sufragio pendiente'}</small>}
                {esMiembro && <small>{m.proceso}</small>}
              </button>
            );
          })}
        </section>
      )}

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}

      {detalle && (
        <>
          <div className="panel im-cabecera">
            <div>
              <h3>Mesa {mesa.numero} · {mesa.ubicacion}</h3>
              <p className="muted">
                {mesa.proceso} · instalada {hora(mesa.horaInstalacion)}
                {presidencia && ` · preside ${presidencia.nombre}`}
              </p>
            </div>
            <span className={`cv-estado ${(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).clase}`}>
              {(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).texto}
              {mesa.horaCierre && ` · ${hora(mesa.horaCierre)}`}
            </span>
          </div>

          {!puedeOperar && <div className="alert success" role="note">Vista de consulta: el cierre lo realiza el presidente de mesa o el CEUNP.</div>}
          {puedeOperar && !soyPresidente && (
            <div className="alert success" role="note">Cierra el sufragio el presidente en funciones: {presidencia?.nombre}.</div>
          )}

          {/* 4 mostrarTotalVotantes(total) */}
          <section className="cq-resumen">
            <div className="cq-kpi" style={{ '--cq-color': '#059669' }}>
              <span>Votaron <em>RF74</em></span>
              <strong>{votaron}<small> / {habiles}</small></strong>
              <i className="cq-barra"><b style={{ width: `${habiles ? Math.round((votaron / habiles) * 100) : 0}%` }} /></i>
            </div>
            <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
              <span>No votaron <em>RF75</em></span>
              <strong>{registro?.totalNoVotaron ?? detalle.noVotaron.length}</strong>
              <small>{detalle.noVotaron.filter((e) => si(e.asistio)).length} asistieron sin votar</small>
            </div>
            <div className="cq-kpi" style={{ '--cq-color': '#f59e0b' }}>
              <span>Votando ahora <em>A1</em></span>
              <strong>{detalle.votando}</strong>
              <small>habilitaciones de terminal pendientes</small>
            </div>
          </section>

          <div className="pd-tabs cq-tabs" role="tablist">
            {PASOS.map((p, i) => (
              <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
                className={`pd-tab${paso === p.codigo ? ' on' : ''}`} disabled={i > avance} onClick={() => setPaso(p.codigo)}>
                {i < avance && <MenuIcon name="check" size={13} />} {p.texto}
              </button>
            ))}
          </div>

          {/* ── 1-4: cerrar la votación ── */}
          {paso === 'CERRAR' && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Cerrar la votación</h3>
                  <p className="muted">A las {detalle.horario.horaCierre} se cierran las puertas: votan solo quienes ya están dentro (RN06, Art. 51a). Al cerrar, la mesa deja de verificar electores, se deshabilitan sus terminales y se registra la hora de cierre.</p>
                </div>
              </div>
              {registro ? (
                <dl className="cq-meta">
                  <div><dt>Hora de cierre</dt><dd>{fecha(registro.horaCierre)}{si(registro.cierreAnticipado) ? ' (votaron todos)' : ''}</dd></div>
                  <div><dt>Electores hábiles</dt><dd>{registro.totalElectores}</dd></div>
                  <div><dt>Votaron</dt><dd>{registro.totalVotaron}</dd></div>
                  <div><dt>Cerró</dt><dd>{registro.cerradoPor ?? '—'}</dd></div>
                </dl>
              ) : (
                <>
                  <ul className="im-requisitos">
                    {detalle.requisitos.map((r) => (
                      <li key={r.codigo} className={r.cumplido ? 'ok' : 'mal'}>
                        <MenuIcon name={r.cumplido ? 'check' : 'close'} size={16} />
                        <div><strong>{r.texto}</strong>{!r.cumplido && r.detalle && <span>{r.detalle}</span>}</div>
                      </li>
                    ))}
                  </ul>
                  {operable && confirmando !== 'CERRAR' && (
                    <div className="cv-actions">
                      <button type="button" className="cv-btn im-btn-peligro-solido" disabled={saving || !detalle.puedeCerrar} onClick={() => setConfirmando('CERRAR')}>
                        <MenuIcon name="lock" size={15} /> Cerrar el sufragio
                      </button>
                    </div>
                  )}
                  {confirmando === 'CERRAR' && (
                    <div className="cq-confirmar-emision" role="alert">
                      <div>
                        <strong>¿Cerrar el sufragio de la mesa {mesa.numero}?</strong>
                        <span>Votaron {votaron} de {habiles} electores. Ya no se podrá verificar ni votar en esta mesa.</span>
                      </div>
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                        <button type="button" className="cv-btn im-btn-peligro-solido" disabled={saving} onClick={solicitarCierre}>
                          <MenuIcon name="check" size={15} /> {saving ? 'Cerrando…' : 'Confirmar cierre'}
                        </button>
                      </div>
                    </div>
                  )}
                </>
              )}
            </div>
          )}

          {/* ── 5-8: marcar NO VOTÓ ── */}
          {paso === 'AUSENTES' && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Electores que no votaron (RF75)</h3>
                  <p className="muted">
                    {detalle.puedeMarcar
                      ? 'Revise la lista y confirme: se marcará NO VOTÓ en el padrón de la mesa a cada elector hábil que no votó, haya asistido o no.'
                      : `Marcados NO VOTÓ el ${fecha(registro?.fechaAusentes)}${registro?.marcadoPor ? ` por ${registro.marcadoPor}` : ''}.`}
                  </p>
                </div>
                <div className="cs-acciones-head">
                  <span className="im-contador">{detalle.noVotaron.length} elector(es)</span>
                  {!detalle.puedeMarcar && (
                    <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirListaNoVoto(mesa, detalle.noVotaron)}>
                      <MenuIcon name="file" size={13} /> Imprimir lista
                    </button>
                  )}
                </div>
              </div>
              {detalle.noVotaron.length === 0 ? <p className="empty-state">Votaron todos los electores de la mesa.</p> : (
                <div className="table-wrap cs-lista">
                  <table>
                    <thead><tr><th>Elector</th><th>Asistencia</th><th>Marca</th></tr></thead>
                    <tbody>
                      {detalle.noVotaron.map((e) => (
                        <tr key={e.idDocente}>
                          <td><strong>{e.nombre}</strong><small className="pd-sub">DNI {e.dni} · {e.facultad ?? '—'}</small></td>
                          <td>{si(e.asistio) ? <span className="cv-estado creado">Asistió {hora(e.horaAsistencia)} y no votó</span> : 'No asistió'}</td>
                          <td>{si(e.marcado) ? <span className="cv-estado anulado">NO VOTÓ</span> : <span className="muted">Por marcar</span>}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
              {operable && detalle.puedeMarcar && confirmando !== 'AUSENTES' && (
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => setConfirmando('AUSENTES')}>
                    <MenuIcon name="check" size={15} /> Confirmar ausentes y marcar NO VOTÓ
                  </button>
                </div>
              )}
              {confirmando === 'AUSENTES' && (
                <div className="cq-confirmar-emision" role="alert">
                  <div>
                    <strong>¿Marcar NO VOTÓ a {detalle.noVotaron.length} elector(es)?</strong>
                    <span>La marca queda en el padrón y no se puede quitar.</span>
                  </div>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                    <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={confirmarAusentes}>
                      <MenuIcon name="check" size={15} /> {saving ? 'Marcando…' : 'Marcar NO VOTÓ'}
                    </button>
                  </div>
                </div>
              )}
              {!detalle.puedeMarcar && (
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('ACTA')}>Continuar con el acta</button>
                </div>
              )}
            </div>
          )}

          {/* ── 9-13: acta de sufragio ── */}
          {paso === 'ACTA' && detalle.puedeEmitir && (
            <form className="panel cv-form" onSubmit={(e) => { e.preventDefault(); setConfirmando('ACTA'); }}>
              <div className="cv-section-head">
                <div>
                  <h3>Datos del acta de sufragio (RF76)</h3>
                  <p className="muted">El acta lleva la hora de cierre, el total de electores que votaron, las cédulas no utilizadas, las observaciones y las firmas. Se emite con QR y huella SHA-256 y ya no se modifica (RN28).</p>
                </div>
              </div>
              <div className="im-cedulas">
                <label className="cv-field">
                  <span className="cv-label">Cédulas no utilizadas</span>
                  <input type="number" min={0} max={registro?.cedulasRecibidas ?? 100000} required value={datosActa.cedulasNoUtilizadas}
                    disabled={!operable || saving} onChange={(e) => setDatosActa((d) => ({ ...d, cedulasNoUtilizadas: e.target.value }))} />
                  <small className="muted">Recibidas en la instalación: {registro?.cedulasRecibidas ?? '—'}{sugeridas != null ? ` · esperadas sin usar: ${sugeridas}` : ''}</small>
                </label>
                <label className="cv-field">
                  <span className="cv-label">Firmas en la lista física (opcional)</span>
                  <input type="number" min={0} value={datosActa.firmasListaFisica}
                    disabled={!operable || saving} onChange={(e) => setDatosActa((d) => ({ ...d, firmasListaFisica: e.target.value }))} />
                  <small className={difiere ? 'cv-error' : 'muted'}>
                    {difiere ? `A2: difiere del sistema (${votaron} votantes). Registre la observación.` : `El sistema registra ${votaron} votantes.`}
                  </small>
                </label>
              </div>
              <label className="cv-field">
                <span className="cv-label">Observaciones{difiere ? ' (obligatorias)' : ''}</span>
                <textarea rows={3} maxLength={1000} required={difiere} value={datosActa.observaciones} disabled={!operable || saving}
                  placeholder="Ej.: un elector se retiró de la cabina sin votar; la lista física tiene una firma menos."
                  onChange={(e) => setDatosActa((d) => ({ ...d, observaciones: e.target.value }))} />
              </label>

              <div className="cs-firmantes">
                <h4>Firman el acta</h4>
                <ul>
                  {detalle.firmantes.map((f) => (
                    <li key={f.cargo}>
                      <MenuIcon name="check" size={14} />
                      <span><strong>{f.nombre}</strong> · {CARGO[f.cargo]} de mesa ({ORIGEN[f.origen]})</span>
                    </li>
                  ))}
                  {detalle.personeros.map((p) => (
                    <li key={p.idPersonero}>
                      <label className="im-check">
                        <input type="checkbox" checked={personeros.includes(p.idPersonero)} disabled={!operable || saving}
                          onChange={(e) => setPersoneros((l) => (e.target.checked ? [...l, p.idPersonero] : l.filter((x) => x !== p.idPersonero)))} />
                        <span>{p.nombre} · personero {p.tipo === 'MESA' ? 'de mesa' : p.tipo === 'GENERAL' ? 'general' : 'alterno'} de {p.lista} (si desea firmar)</span>
                      </label>
                    </li>
                  ))}
                </ul>
                {detalle.personeros.length === 0 && <p className="muted im-nota">No hay personeros presentes en la mesa.</p>}
              </div>

              {operable && confirmando !== 'ACTA' && (
                <div className="cv-actions">
                  <button type="submit" className="cv-btn cv-btn-success" disabled={saving || datosActa.cedulasNoUtilizadas === '' || (difiere && !datosActa.observaciones.trim())}>
                    <MenuIcon name="file" size={15} /> Generar acta de sufragio
                  </button>
                </div>
              )}
              {confirmando === 'ACTA' && (
                <div className="cq-confirmar-emision" role="alert">
                  <div>
                    <strong>¿Emitir el acta de sufragio de la mesa {mesa.numero}?</strong>
                    <span>Votaron {votaron} · cédulas no utilizadas {datosActa.cedulasNoUtilizadas} · firman {detalle.firmantes.length + personeros.length}. El acta ya no podrá modificarse.</span>
                  </div>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                    <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={ingresarObservaciones}>
                      <MenuIcon name="check" size={15} /> {saving ? 'Emitiendo…' : 'Confirmar y firmar'}
                    </button>
                  </div>
                </div>
              )}
            </form>
          )}

          {paso === 'ACTA' && detalle.acta && <ActaVista acta={detalle.acta} emitida={emitida} />}
        </>
      )}
    </div>
  );
}

/** 13 mostrarActaSufragio(): datos, firmas y, solo al emitirse, el QR de verificación. */
function ActaVista({ acta, emitida }) {
  const c = acta.contenido ?? {};
  const token = emitida && emitida.idActa === acta.idActa ? emitida.tokenQr : null;
  return (
    <div className="panel cv-form im-acta">
      <div className="cv-section-head">
        <div>
          <h3>Acta de Sufragio N.º {String(acta.idActa).padStart(6, '0')}</h3>
          <p className="muted">Emitida el {fecha(acta.fechaEmision)} · estado {acta.estado}</p>
        </div>
        <button type="button" className="cv-btn cv-btn-primary" onClick={() => imprimirActaSufragio(acta, token)}>
          <MenuIcon name="file" size={15} /> Imprimir acta
        </button>
      </div>

      <div className="im-acta-cuerpo">
        <dl className="cq-meta">
          <div><dt>Hora de cierre</dt><dd>{c.hora_cierre}</dd></div>
          <div><dt>Electores hábiles</dt><dd>{c.total_electores}</dd></div>
          <div><dt>Votaron</dt><dd>{c.electores_que_votaron}</dd></div>
          <div><dt>No votaron</dt><dd>{c.electores_que_no_votaron}</dd></div>
          <div><dt>Cédulas no utilizadas</dt><dd>{c.cedulas_no_utilizadas}{c.cedulas_recibidas != null ? ` de ${c.cedulas_recibidas}` : ''}</dd></div>
          <div><dt>Lista física</dt><dd>{c.firmas_lista_fisica != null ? `${c.firmas_lista_fisica} firmas${c.diferencia_lista_fisica ? ` (diferencia ${c.diferencia_lista_fisica})` : ''}` : '—'}</dd></div>
        </dl>
        {token && (
          <div className="im-acta-qr">
            <CodigoQR valor={urlVerificacionActa(token)} size={150} titulo="QR de verificación del acta" />
            <small>Este QR se muestra solo ahora: imprima el acta para conservarlo.</small>
          </div>
        )}
      </div>

      <div className="table-wrap">
        <table>
          <thead><tr><th>Firmante</th><th>Cargo</th><th>Firma digital</th></tr></thead>
          <tbody>
            {acta.firmas.map((f) => (
              <tr key={f.idDocente}>
                <td><strong>{f.nombre}</strong><small className="pd-sub">DNI {f.dni}</small></td>
                <td>{f.rol}</td>
                <td><code className="im-hash">{f.firmaDigital?.slice(0, 16)}…</code><small className="pd-sub">{fecha(f.fechaFirma)}</small></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {c.observaciones && <p className="im-nota"><strong>Observaciones:</strong> {c.observaciones}</p>}
      <p className="muted im-nota">Huella SHA-256 del contenido: <code className="im-hash">{acta.hashIntegridad}</code></p>
    </div>
  );
}
