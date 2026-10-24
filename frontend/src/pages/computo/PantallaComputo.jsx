import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { EscanerQR, fecha } from '../credenciales/LectorQR';
import {
  ESTADO_RESULTADO, SITUACION_MESA, imprimirActaGeneral, imprimirComunicacionNulidad, imprimirCredencial,
  imprimirResolucionProclamacion, imprimirResultadosMesa, imprimirVerificacionPrevia, urlVerificacionComputo,
} from './ActaComputo';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import '../cierre/cierre.css';
import '../impugnaciones/impugnaciones.css';
import './computo.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS14 · Computar y proclamar resultados — «ComputoResultado» (boundary). Actor: CEUNP.
 *
 * Mensajes del diagrama «Colaboration - Computar y proclamar»:
 *   0 solicitarComputo(idProceso) → 1 ejecutarComputo(idProceso) → ComputarProclamar
 *   2 verificarActasEntregadas(idProceso) · 3 actasEntregadas(totalMesas)     (paso Verificación previa)
 *   4 validarIntegridad(actas) · 5 actasValidas(hashCorrecto)                  (marcar dudosa y comprobar)
 *   6 consolidarVotos(idCargo) · 7 totalesPorLista(votos)                      (paso Consolidación)
 *   8 calcularParticipacion(idCargo) · 9 porcentajeParticipacion(porcentaje)
 *   10 validarQuorum(porcentaje) · 11 quorumValidado(estado)
 *   12 [quorum > 60%] registrarComputo(totales) · 13 computoRegistrado(resultados) (paso Cómputo)
 *   14 determinarGanador(resultados) · 15 ganadorOSegundaVuelta(idLista)
 *   16 [supera minimo] acreditarGanadora(idLista) · 17 listaAcreditada()       (paso Proclamación)
 *   18 mostrarResultados(resultados) · 19 resultadosProclamados()              (paso Publicación)
 *
 * Tabla 39: verificación previa (1-3), sesión con personeros (4, RF91), consolidación y
 * participación (5-6), nulidades pendientes (7), ganador o segunda vuelta (8), proclamación y
 * publicación (9). A1 nulidad total (RN31, RN34) · A2 segunda vuelta (RN33) · A3 acta que difiere (RF95).
 */

const ESTADO_PROCESO = {
  VOTACION: { clase: 'votacion', texto: 'En votación' },
  CERRADO: { clase: 'inscripcion', texto: 'Votación concluida' },
  FINALIZADO: { clase: 'votacion', texto: 'Finalizado' },
  ANULADO: { clase: 'anulado', texto: 'Anulado' },
};
const ETAPA = {
  SESION_INSTALADA: 'Sesión instalada',
  COMPUTADO: 'Computado',
  PROCLAMADO: 'Proclamado',
  PUBLICADO: 'Publicado',
};
const CLASE_SITUACION = {
  HABILITADA: 'votacion', NO_INSTALADA: 'creado', ANULADA: 'anulado', ACTA_NO_AUTENTICA: 'anulado',
  POR_CALIFICAR: 'inscripcion', ACTA_DUDOSA: 'inscripcion', IMPUGNACIONES_PENDIENTES: 'inscripcion',
};
const CLASE_RESULTADO = { ELEGIDO: 'votacion', SEGUNDA_VUELTA: 'inscripcion', EMPATE: 'inscripcion', SIN_QUORUM: 'anulado', DESIERTO: 'anulado', PENDIENTE: 'creado' };
const TIPO_ACTA = { INSTALACION: 'Instalación', SUFRAGIO: 'Sufragio', ESCRUTINIO: 'Escrutinio' };
const TIPO_PERSONERO = { MESA: 'de mesa', GENERAL: 'general', ALTERNO: 'alterno' };
const PASOS = [
  { codigo: 'VERIFICACION', texto: 'Verificación previa', nota: 'Mesas y actas · RF89-RF90', icono: 'shield' },
  { codigo: 'SESION', texto: 'Sesión de cómputo', nota: 'Pleno y personeros · RF91', icono: 'users' },
  { codigo: 'CONSOLIDACION', texto: 'Consolidación', nota: 'Votos y participación · RF92-RF93', icono: 'table' },
  { codigo: 'COMPUTO', texto: 'Cómputo oficial', nota: 'Quórum y ganador · RN31, RF96', icono: 'graph' },
  { codigo: 'PROCLAMACION', texto: 'Proclamación', nota: 'Resolución y credencial · RF98', icono: 'trophy' },
  { codigo: 'PUBLICACION', texto: 'Publicación', nota: 'Portal electoral · RF99', icono: 'external' },
];
const pct = (v) => `${Number(v ?? 0).toFixed(2)} %`;
const si = (v) => v === true || v === 1;
const claveTokens = (id) => `cus14-tokens-${id}`;

function leerTokens(id) {
  try {
    return JSON.parse(sessionStorage.getItem(claveTokens(id)) ?? '{}');
  } catch {
    return {};
  }
}
function guardarToken(id, tipo, token) {
  try {
    sessionStorage.setItem(claveTokens(id), JSON.stringify({ ...leerTokens(id), [tipo]: token }));
  } catch { /* almacenamiento no disponible */ }
}

/** Paso en curso según el estado del proceso y del cómputo. */
function pasoActual(d) {
  const etapa = d?.computo?.estado;
  if (!d || d.proceso.estado === 'VOTACION') return 'VERIFICACION';
  if (!etapa) return d.bloqueos.length ? 'VERIFICACION' : 'SESION';
  if (etapa === 'SESION_INSTALADA') return d.bloqueos.length ? 'VERIFICACION' : 'COMPUTO';
  if (etapa === 'COMPUTADO') return d.proceso.estado === 'ANULADO' ? 'PUBLICACION' : 'PROCLAMACION';
  return 'PUBLICACION';
}

function pasoHecho(codigo, d) {
  const etapa = d?.computo?.estado;
  const computado = etapa && etapa !== 'SESION_INSTALADA';
  switch (codigo) {
    case 'VERIFICACION': return d.proceso.estado !== 'VOTACION' && d.bloqueos.length === 0;
    case 'SESION': return Boolean(etapa);
    case 'CONSOLIDACION':
    case 'COMPUTO': return Boolean(computado);
    case 'PROCLAMACION': return etapa === 'PROCLAMADO' || etapa === 'PUBLICADO' || (computado && d.proceso.estado === 'ANULADO');
    case 'PUBLICACION': return etapa === 'PUBLICADO';
    default: return false;
  }
}

export default function PantallaComputo({ session, onSessionExpired }) {
  const esCeunp = session.rol === 'CEUNP';
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [paso, setPaso] = useState('VERIFICACION');
  const [idMesa, setIdMesa] = useState(null);
  const [mesa, setMesa] = useState(null);
  const [accion, setAccion] = useState(null);   // CONCLUIR | DUDOSA:<id> | COMPROBAR:<id> | CALIFICAR | COMPUTAR | PROCLAMAR | PUBLICAR | SEGUNDA
  const [confirmando, setConfirmando] = useState(false);
  const [formSesion, setFormSesion] = useState({ lugar: 'Sala de sesiones del CEUNP', miembrosCeunp: '5', observaciones: '', personeros: [] });
  const [motivoDuda, setMotivoDuda] = useState('');
  const [comprobacion, setComprobacion] = useState({ tokenQr: '', observacion: '' });
  const [lectura, setLectura] = useState(null);
  const [calificacion, setCalificacion] = useState({ calificacion: '', fundamento: '', numeroResolucion: '' });
  const [proclamacion, setProclamacion] = useState({ numeroResolucion: '', miembrosPleno: '5', presidente: '', fundamento: '' });
  const [segunda, setSegunda] = useState({ fechaInicio: '', fechaFin: '' });
  const [filasMesa, setFilasMesa] = useState(null);
  const [tokens, setTokens] = useState({});
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const cargarDetalle = useCallback(async (id, moverPaso) => {
    if (!id) return null;
    const d = await apiRequest(`/api/computo/procesos/${id}`);
    setDetalle(d);
    setTokens(leerTokens(id));
    if (moverPaso) setPaso(pasoActual(d));
    const quorum = String(d.parametros?.quorumPleno ?? 5);
    setFormSesion((f) => ({ ...f, miembrosCeunp: f.miembrosCeunp || quorum }));
    setProclamacion((p) => ({ ...p, miembrosPleno: p.miembrosPleno || quorum }));
    return d;
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/computo/procesos');
        setProcesos(lista);
        const primero = lista[0]?.id ?? null;
        setIdProceso(primero);
        await cargarDetalle(primero, true);
      } catch (e) {
        manejarError(e);
      } finally {
        setCargando(false);
      }
    })();
  }, [cargarDetalle, manejarError]);

  useEffect(() => {
    if (!idMesa) {
      setMesa(null);
      return;
    }
    (async () => {
      try {
        setMesa(await apiRequest(`/api/computo/mesas/${idMesa}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idMesa, manejarError]);

  useEffect(() => {
    if (!idProceso || !['CONSOLIDACION', 'PUBLICACION'].includes(paso)) return;
    (async () => {
      try {
        setFilasMesa(await apiRequest(`/api/computo/procesos/${idProceso}/resultados-mesa`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idProceso, paso, detalle?.computo?.estado, manejarError]);

  function limpiarAccion() {
    setAccion(null);
    setConfirmando(false);
    setLectura(null);
  }

  async function cambiarProceso(id) {
    setIdProceso(id);
    setIdMesa(null);
    setFilasMesa(null);
    limpiarAccion();
    setFeedback(null);
    try {
      await cargarDetalle(id, true);
    } catch (e) {
      manejarError(e);
    }
  }

  async function refrescar() {
    try {
      setProcesos(await apiRequest('/api/computo/procesos'));
      await cargarDetalle(idProceso, false);
      if (idMesa) setMesa(await apiRequest(`/api/computo/mesas/${idMesa}`));
    } catch (e) {
      manejarError(e);
    }
  }

  async function ejecutar(ruta, cuerpo, alTerminar) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(ruta, { method: 'POST', body: JSON.stringify(cuerpo ?? {}) });
      if (data.detalle) setDetalle(data.detalle);
      if (data.mesa) setMesa(data.mesa);
      setFeedback({ type: data.comprobacion?.resultado === 'NO_AUTENTICA' ? 'error' : 'success', text: data.mensaje });
      limpiarAccion();
      alTerminar?.(data);
      setProcesos(await apiRequest('/api/computo/procesos'));
      return data;
    } catch (e) {
      manejarError(e);
      setConfirmando(false);
      return null;
    } finally {
      setSaving(false);
    }
  }

  // ─── Acciones del CEUNP ──────────────────────────────────────────────────

  const concluirVotacion = () => ejecutar(`/api/computo/procesos/${idProceso}/concluir-votacion`, {}, (d) => setPaso(pasoActual(d.detalle)));

  const instalarSesion = () => ejecutar(`/api/computo/procesos/${idProceso}/sesion`, {
    lugar: formSesion.lugar,
    miembrosCeunp: Number(formSesion.miembrosCeunp),
    observaciones: formSesion.observaciones || null,
    personeros: formSesion.personeros,
  }, (d) => setPaso(pasoActual(d.detalle)));

  const registrarPersonero = (idPersonero) => ejecutar(`/api/computo/procesos/${idProceso}/sesion/personeros`, { idPersonero });

  /** 4 validarIntegridad(actas): el acta se marca dudosa. */
  const marcarDudosa = (idActa) => ejecutar(`/api/computo/actas/${idActa}/dudosa`, { motivo: motivoDuda }, () => setMotivoDuda(''));

  /** 5 actasValidas(hashCorrecto): huella SHA-256 y QR del ejemplar físico. */
  const comprobarActa = (idActa, token) => ejecutar(`/api/computo/actas/${idActa}/comprobacion`, {
    tokenQr: (token ?? comprobacion.tokenQr) || null,
    observacion: comprobacion.observacion || null,
  }, (d) => {
    setLectura(d.comprobacion);
    setComprobacion({ tokenQr: '', observacion: '' });
  });

  const calificarMesa = () => ejecutar(`/api/computo/mesas/${idMesa}/calificacion`, {
    calificacion: calificacion.calificacion,
    fundamento: calificacion.fundamento,
    numeroResolucion: calificacion.numeroResolucion || null,
  }, () => setCalificacion({ calificacion: '', fundamento: '', numeroResolucion: '' }));

  /** 1 ejecutarComputo(idProceso) → 2-15 en una sola transacción. */
  const ejecutarComputo = () => ejecutar(`/api/computo/procesos/${idProceso}/computo`, {}, (d) => {
    if (d.tokenQr) {
      guardarToken(idProceso, 'acta', d.tokenQr);
      setTokens(leerTokens(idProceso));
    }
    setPaso('COMPUTO');
  });

  /** 16 acreditarGanadora(idLista) → 17 listaAcreditada(). */
  const proclamar = () => ejecutar(`/api/computo/procesos/${idProceso}/proclamacion`, {
    numeroResolucion: proclamacion.numeroResolucion,
    miembrosPleno: Number(proclamacion.miembrosPleno),
    presidente: proclamacion.presidente,
    fundamento: proclamacion.fundamento || null,
  }, (d) => {
    if (d.tokenQr) {
      guardarToken(idProceso, 'proclamacion', d.tokenQr);
      setTokens(leerTokens(idProceso));
    }
  });

  /** 18 mostrarResultados(resultados) → 19 resultadosProclamados(). */
  const publicar = () => ejecutar(`/api/computo/procesos/${idProceso}/publicacion`, {}, () => setPaso('PUBLICACION'));

  const convocarSegunda = () => ejecutar(`/api/computo/procesos/${idProceso}/segunda-vuelta`, {
    fechaInicio: segunda.fechaInicio ? `${segunda.fechaInicio}:00` : null,
    fechaFin: segunda.fechaFin ? `${segunda.fechaFin}:00` : null,
  }, () => setSegunda({ fechaInicio: '', fechaFin: '' }));

  // ─── Datos derivados ─────────────────────────────────────────────────────

  const actasPorMesa = useMemo(() => {
    const mapa = new Map();
    (detalle?.actas ?? []).forEach((a) => mapa.set(a.idMesa, [...(mapa.get(a.idMesa) ?? []), a]));
    return mapa;
  }, [detalle]);

  if (cargando) return <div className="panel"><p className="muted">Cargando cómputo…</p></div>;
  if (!detalle) {
    return (
      <div className="pd-shell cq-shell cs-shell ig-shell cp-shell mx">
        {feedback && <div className={`alert ${feedback.type}`} role="status">{feedback.text}</div>}
        <div className="panel"><p className="empty-state">No hay procesos con mesas en votación o por computar.</p></div>
      </div>
    );
  }

  const { proceso, computo, acciones, resumenMesas: rm, participacion, parametros } = detalle;
  const etapa = computo?.estado;
  const computado = Boolean(etapa) && etapa !== 'SESION_INSTALADA';
  const anulado = proceso.estado === 'ANULADO';
  const estProc = ESTADO_PROCESO[proceso.estado] ?? { clase: 'creado', texto: proceso.estado };
  const general = participacion?.general;
  const actasVig = (detalle.actas ?? []).filter((a) => a.estado === 'VIGENTE');
  const quorum = parametros?.quorumPleno ?? 5;

  return (
    <div className="pd-shell cq-shell cs-shell ig-shell cp-shell mx">
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))}>
            {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}{p.estadoComputo ? ` · ${ETAPA[p.estadoComputo]}` : ''}</option>)}
          </select>
        </label>
        <div className={`in-plazo ${anulado ? 'closed' : 'open'}`}>
          <MenuIcon name="trophy" size={18} />
          <div>
            <strong>{etapa ? `${ETAPA[etapa]}${computo.resultado === 'NULIDAD_TOTAL' ? ' · nulidad total' : ''}` : estProc.texto}</strong>
            <span>RN32 cómputo con todas las actas · RN31 participación mayor al {pct(proceso.quorumMinimo)} · RN26 cómputo único e irreversible</span>
          </div>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      <div className="pd-tabs cq-tabs mx-pasos cp-pasos" role="tablist" aria-label="Etapas del cómputo">
        {PASOS.map((p, i) => {
          const hecho = pasoHecho(p.codigo, detalle);
          return (
            <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
              className={`pd-tab mx-paso${paso === p.codigo ? ' on' : ''}${hecho ? ' hecho' : ''}`}
              onClick={() => { setPaso(p.codigo); limpiarAccion(); setFeedback(null); }}>
              <span className="mx-paso-num">{hecho ? <MenuIcon name="check" size={14} /> : i + 1}</span>
              <span className="mx-paso-texto"><b>{p.texto}</b><small>{p.nota}</small></span>
            </button>
          );
        })}
      </div>

      <section className="cq-resumen">
        <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
          <span>Mesas habilitadas <em>RF89</em></span>
          <strong>{rm.habilitadas}<small> / {rm.total}</small></strong>
          <small>{rm.noInstaladas} no instalada(s) · {rm.anuladas} anulada(s)</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': rm.bloqueadas ? '#d97706' : '#059669' }}>
          <span>Actas íntegras <em>RF90</em></span>
          <strong>{actasVig.filter((a) => si(a.integra)).length}<small> / {actasVig.length}</small></strong>
          <small>{(detalle.actas ?? []).filter((a) => si(a.dudosa)).length} dudosa(s) · {rm.bloqueadas} mesa(s) pendientes</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': general && !si(general.alcanzaQuorum) ? '#e11d48' : '#059669' }}>
          <span>Participación <em>RN31</em></span>
          <strong>{pct(general?.participacionPct)}</strong>
          <i className="cq-barra cp-barra" style={{ '--cp-umbral': `${proceso.quorumMinimo}%` }}>
            <b style={{ width: `${Math.min(100, Number(general?.participacionPct ?? 0))}%` }} />
          </i>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': anulado ? '#e11d48' : '#059669' }}>
          <span>Etapa <em>CUS14</em></span>
          <strong className="cp-etapa">{etapa ? ETAPA[etapa] : 'Sin sesión'}</strong>
          <small><span className={`cv-estado ${estProc.clase}`}>{estProc.texto}</span></small>
        </div>
      </section>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}
      {detalle.soloLectura && <div className="alert success" role="note">Vista de consulta: el cómputo y la proclamación los realiza el CEUNP.</div>}

      {/* ── 1-3 Verificación previa ── */}
      {paso === 'VERIFICACION' && (
        <>
          {proceso.estado === 'VOTACION' && (
            <div className="mx-mensaje info" role="note">
              <MenuIcon name="info" size={18} />
              <div>
                <h4>La votación del proceso sigue abierta</h4>
                <p>El cómputo general se hace con la votación concluida (RN32). {acciones.motivoNoConcluye ?? 'Todas las mesas cerraron su sufragio o no se instalaron: puede concluir la votación.'}</p>
                {acciones.concluirVotacion && (accion !== 'CONCLUIR' ? (
                  <div className="cv-actions cp-izq">
                    <button type="button" className="cv-btn cv-btn-primary" disabled={saving || Boolean(acciones.motivoNoConcluye)} onClick={() => setAccion('CONCLUIR')}>
                      <MenuIcon name="lock" size={15} /> Concluir votación
                    </button>
                  </div>
                ) : (
                  <div className="cq-confirmar-emision" role="alert">
                    <div>
                      <strong>¿Concluir la votación del proceso?</strong>
                      <span>El proceso pasa a CERRADO: ya no se instalan mesas ni se emiten votos.</span>
                    </div>
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                      <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={concluirVotacion}>
                        <MenuIcon name="check" size={15} /> {saving ? 'Concluyendo…' : 'Confirmar'}
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {detalle.bloqueos.length > 0 && proceso.estado !== 'VOTACION' && (
            <div className="mx-mensaje peligro" role="note">
              <MenuIcon name="alert" size={18} />
              <div>
                <h4>{detalle.bloqueos.length} mesa(s) impiden el cómputo (RN32)</h4>
                <ul className="cp-lista">{detalle.bloqueos.map((b) => <li key={b}>{b}</li>)}</ul>
              </div>
            </div>
          )}

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Mesas instaladas y no instaladas, y sus actas</h3>
                <p className="muted">Cada mesa entrega tres actas (instalación, sufragio y escrutinio) con su huella SHA-256. Marque como dudosa el acta que no coincida con su ejemplar físico y compruebe su autenticidad con el QR (RF90). Si el acta difiere del conteo, el CEUNP la califica (A3, RF95).</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirVerificacionPrevia(detalle)}>
                  <MenuIcon name="file" size={13} /> Imprimir verificación
                </button>
              </div>
            </div>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr><th>Mesa</th><th>Sufragio</th><th>Entrega de actas</th><th>Actas</th><th>Impugnaciones</th><th>Situación</th><th /></tr>
                </thead>
                <tbody>
                  {detalle.mesas.map((m) => {
                    const actas = actasPorMesa.get(m.idMesa) ?? [];
                    return (
                      <tr key={m.idMesa} className={m.idMesa === idMesa ? 'ig-fila on' : 'ig-fila'}>
                        <td><strong>Mesa {m.numeroMesa}</strong><small className="pd-sub">{m.ubicacion}</small></td>
                        <td>{m.estado === 'CERRADA' ? 'Cerrado' : m.estado.replaceAll('_', ' ').toLowerCase()}<small className="pd-sub">{m.totalVotantes ?? 0} de {m.totalElectores} votaron</small></td>
                        <td>{m.fechaEntrega ? <>Entregadas<small className="pd-sub">{fecha(m.fechaEntrega)} · {m.codigoCargo}</small></> : <span className="muted">{m.estadoEscrutinio ? m.estadoEscrutinio.replaceAll('_', ' ').toLowerCase() : '—'}</span>}</td>
                        <td>
                          <div className="cp-actas">
                            {actas.map((a) => (
                              <span key={a.idActa} title={`Acta N.º ${a.idActa}`}
                                className={`cp-acta ${!si(a.integra) || a.comprobacion === 'NO_AUTENTICA' ? 'mal' : si(a.dudosa) && !a.comprobacion ? 'duda' : 'ok'}`}>
                                {TIPO_ACTA[a.tipo]?.slice(0, 3) ?? a.tipo}
                              </span>
                            ))}
                            {actas.length === 0 && <span className="muted">—</span>}
                          </div>
                        </td>
                        <td>{m.impugnaciones}{m.impugnacionesPendientes ? <small className="pd-sub">{m.impugnacionesPendientes} pendiente(s)</small> : null}</td>
                        <td>
                          <span className={`cv-estado ${CLASE_SITUACION[m.situacion] ?? 'creado'}`}>{SITUACION_MESA[m.situacion] ?? m.situacion}</span>
                          {m.calificacion && <small className="pd-sub">{m.calificacion === 'NULIDAD' ? 'Nulidad' : 'Válida'}{m.resolucionCalificacion ? ` · ${m.resolucionCalificacion}` : ''}</small>}
                        </td>
                        <td>
                          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => { setIdMesa(m.idMesa === idMesa ? null : m.idMesa); limpiarAccion(); }}>
                            <MenuIcon name="eye" size={13} /> {m.idMesa === idMesa ? 'Cerrar' : 'Revisar'}
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {mesa && (
            <FichaMesa
              datos={mesa} acciones={acciones} saving={saving} accion={accion} setAccion={(a) => { setAccion(a); setConfirmando(false); setLectura(null); }}
              confirmando={confirmando} setConfirmando={setConfirmando}
              motivoDuda={motivoDuda} setMotivoDuda={setMotivoDuda} onMarcar={marcarDudosa}
              comprobacion={comprobacion} setComprobacion={setComprobacion} onComprobar={comprobarActa} lectura={lectura}
              calificacion={calificacion} setCalificacion={setCalificacion} onCalificar={calificarMesa}
              onCerrar={() => { setIdMesa(null); limpiarAccion(); }}
            />
          )}
        </>
      )}

      {/* ── 4 Sesión de cómputo general (RF91) ── */}
      {paso === 'SESION' && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Sesión de cómputo general</h3>
              <p className="muted">El Pleno del CEUNP instala la sesión con quórum de {quorum} de sus 9 miembros (RN36). Los personeros acreditados pueden asistir (asistencia facultativa) y se registra su presencia.</p>
            </div>
          </div>
          {!etapa && !acciones.instalarSesion && (
            <p className="empty-state">{proceso.estado === 'VOTACION' ? 'Concluya primero la votación del proceso (Verificación previa).' : 'La sesión no se instaló.'}</p>
          )}
          {acciones.instalarSesion && (
            <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); setAccion('SESION'); }}>
              <h4>Instalar la sesión de cómputo</h4>
              <div className="ig-grid">
                <label className="cv-field cp-ancho2">
                  <span className="cv-label">Lugar de la sesión</span>
                  <input required maxLength={200} value={formSesion.lugar} disabled={saving} onChange={(e) => setFormSesion((f) => ({ ...f, lugar: e.target.value }))} />
                </label>
                <label className="cv-field">
                  <span className="cv-label">Miembros del CEUNP presentes</span>
                  <input type="number" min={1} max={9} required value={formSesion.miembrosCeunp} disabled={saving} onChange={(e) => setFormSesion((f) => ({ ...f, miembrosCeunp: e.target.value }))} />
                  {Number(formSesion.miembrosCeunp) < quorum && <small className="cv-error">Sin quórum: se requieren {quorum} miembros (RN36).</small>}
                </label>
                <label className="cv-field">
                  <span className="cv-label">Observaciones</span>
                  <input maxLength={1000} value={formSesion.observaciones} disabled={saving} onChange={(e) => setFormSesion((f) => ({ ...f, observaciones: e.target.value }))} />
                </label>
              </div>
              <div className="cv-field">
                <span className="cv-label">Personeros presentes ({formSesion.personeros.length} de {detalle.personeros.length})</span>
                <div className="ig-opciones">
                  {detalle.personeros.map((p) => {
                    const on = formSesion.personeros.includes(p.idPersonero);
                    return (
                      <label key={p.idPersonero} className={on ? 'on' : ''}>
                        <input type="checkbox" checked={on} disabled={saving}
                          onChange={() => setFormSesion((f) => ({ ...f, personeros: on ? f.personeros.filter((x) => x !== p.idPersonero) : [...f.personeros, p.idPersonero] }))} />
                        <span className="ig-op-num">{on ? <MenuIcon name="check" size={13} /> : p.lista?.slice(-1)}</span>
                        <span>{p.nombre}<small>{p.lista} · personero {TIPO_PERSONERO[p.tipo] ?? p.tipo}{p.numeroMesa ? ` (mesa ${p.numeroMesa})` : ''}</small></span>
                      </label>
                    );
                  })}
                </div>
                {detalle.personeros.length === 0 && <small className="muted">El proceso no tiene personeros acreditados.</small>}
              </div>
              {!(confirmando && accion === 'SESION') ? (
                <div className="cv-actions">
                  <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !formSesion.lugar.trim() || Number(formSesion.miembrosCeunp) < quorum}>
                    <MenuIcon name="users" size={15} /> Instalar sesión
                  </button>
                </div>
              ) : (
                <div className="cq-confirmar-emision" role="alert">
                  <div>
                    <strong>¿Instalar la sesión de cómputo en {formSesion.lugar}?</strong>
                    <span>{formSesion.miembrosCeunp} miembros del CEUNP y {formSesion.personeros.length} personero(s). Luego se pueden registrar personeros que lleguen antes del cómputo.</span>
                  </div>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                    <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={instalarSesion}>
                      <MenuIcon name="check" size={15} /> {saving ? 'Instalando…' : 'Confirmar'}
                    </button>
                  </div>
                </div>
              )}
            </form>
          )}
          {etapa && (
            <>
              <dl className="cq-meta cp-meta">
                <div><dt>Lugar</dt><dd>{computo.lugarSesion}</dd></div>
                <div><dt>Instalada</dt><dd>{fecha(computo.fechaSesion)}</dd></div>
                <div><dt>Miembros del CEUNP</dt><dd>{computo.miembrosCeunp} de 9</dd></div>
                <div><dt>Registró</dt><dd>{computo.sesionInstaladaPor ?? '—'}</dd></div>
                {computo.observacionesSesion && <div className="cp-ancho2"><dt>Observaciones</dt><dd>{computo.observacionesSesion}</dd></div>}
              </dl>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Personero</th><th>Lista</th><th>Tipo</th><th>Asistencia</th><th /></tr></thead>
                  <tbody>
                    {detalle.personeros.map((p) => (
                      <tr key={p.idPersonero}>
                        <td><strong>{p.nombre}</strong><small className="pd-sub">DNI {p.dni}</small></td>
                        <td>{p.lista}<small className="pd-sub">{p.cargo}</small></td>
                        <td>{TIPO_PERSONERO[p.tipo] ?? p.tipo}{p.numeroMesa ? ` · mesa ${p.numeroMesa}` : ''}</td>
                        <td>{si(p.presente) ? <span className="cv-estado votacion">Presente · {fecha(p.horaRegistro)}</span> : <span className="muted">No asistió</span>}</td>
                        <td>
                          {!si(p.presente) && acciones.registrarPersonero && (
                            <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving} onClick={() => registrarPersonero(p.idPersonero)}>
                              <MenuIcon name="plus" size={13} /> Registrar llegada
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                    {detalle.personeros.length === 0 && <tr><td colSpan={5} className="muted">El proceso no tiene personeros acreditados.</td></tr>}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      )}

      {/* ── 5-6 Consolidación y participación (6-11) ── */}
      {paso === 'CONSOLIDACION' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>{computado ? 'Consolidado de las actas computadas' : 'Consolidado provisional'}</h3>
                <p className="muted">Votos de la cédula física de cada acta de escrutinio (RF84) más las cédulas impugnadas que la mesa o el CEUNP asignaron (CUS13). No incluye las mesas anuladas. {computado ? '' : 'El resultado oficial lo fija el cómputo.'}</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={!filasMesa} onClick={() => imprimirResultadosMesa(proceso, filasMesa ?? [], detalle.consolidado)}>
                  <MenuIcon name="file" size={13} /> Imprimir resultados por mesa
                </button>
              </div>
            </div>
            {detalle.consolidado.map((c) => (
              <div key={c.idCargo} className="cp-cargo">
                <div className="cp-cargo-head">
                  <h4>{c.cargo}</h4>
                  <span className={`cv-estado ${CLASE_RESULTADO[c.proyeccion] ?? 'creado'}`}>{computado ? ESTADO_RESULTADO[c.estadoResultado] : `Proyección: ${ESTADO_RESULTADO[c.proyeccion]}`}</span>
                </div>
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Lista</th><th className="n">Actas</th><th className="n">Impugnados asignados</th><th className="n">Votos</th><th className="n">% válidos</th><th className="n">Conteo digital</th></tr></thead>
                    <tbody>
                      {c.listas.map((l) => (
                        <tr key={l.idLista} className={c.listaPuntera === l.lista ? 'cp-puntera' : ''}>
                          <td><strong>{l.ordenCedula != null ? `${l.ordenCedula}. ` : ''}{l.lista}</strong></td>
                          <td className="n">{l.votosActas}</td><td className="n">{l.impugnadosAsignados}</td>
                          <td className="n"><strong>{l.votos}</strong></td>
                          <td className="n">
                            {pct(l.porcentaje)}
                            <i className="cq-barra cp-barra" style={{ '--cp-umbral': `${c.porcentajeMinimoVictoria}%` }}><b style={{ width: `${Math.min(100, Number(l.porcentaje))}%` }} /></i>
                          </td>
                          <td className="n">{l.votosDigital}</td>
                        </tr>
                      ))}
                      <tr className="cp-total"><td>Votos válidos</td><td /><td /><td className="n">{c.validos}</td><td className="n">100.00 %</td><td /></tr>
                      <tr><td>Votos en blanco</td><td /><td /><td className="n">{c.blancos}</td><td /><td /></tr>
                      <tr><td>Votos nulos</td><td /><td /><td className="n">{c.nulos}</td><td /><td /></tr>
                      {c.impugnados > 0 && <tr className="cp-alerta"><td>Impugnados sin resolver (CUS13)</td><td /><td /><td className="n">{c.impugnados}</td><td /><td /></tr>}
                      <tr className="cp-total"><td>Votos emitidos</td><td /><td /><td className="n">{c.emitidos}</td><td /><td /></tr>
                    </tbody>
                  </table>
                </div>
                <p className="muted cp-nota">Para ganar en {proceso.tipo === 'SEGUNDA_VUELTA' ? 'segunda vuelta se requiere la mitad más uno' : `primera vuelta se requiere más del ${pct(c.porcentajeMinimoVictoria)}`} de los votos válidos (RF96). Mesas con acta: {c.mesasComputables}.</p>
              </div>
            ))}
          </div>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Participación por cargo (8-9 calcularParticipacion)</h3>
                <p className="muted">La elección es válida si votó más del {pct(proceso.quorumMinimo)} de los electores hábiles (RN31). Si ningún cargo lo supera, se declara la nulidad total (A1).</p>
              </div>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th>Cargo</th><th className="n">Electores hábiles</th><th className="n">Votaron</th><th className="n">No votaron</th><th className="n">Participación</th><th>Quórum (10-11)</th></tr></thead>
                <tbody>
                  {participacion.cargos.map((c) => (
                    <tr key={c.idCargo}>
                      <td><strong>{c.cargo}</strong></td>
                      <td className="n">{c.electoresHabiles}</td><td className="n">{c.votaron}</td><td className="n">{c.faltan}</td>
                      <td className="n">{pct(c.participacionPct)}</td>
                      <td><span className={`cv-estado ${si(c.alcanzaQuorum) ? 'votacion' : 'anulado'}`}>{si(c.alcanzaQuorum) ? 'Supera el mínimo' : 'No alcanza'}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {/* ── 1 ejecutarComputo · 12-15 ── */}
      {paso === 'COMPUTO' && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Cómputo oficial y acta general de sufragios</h3>
              <p className="muted">El cómputo es único e irreversible (RN26). Registra los resultados, determina la lista ganadora o la segunda vuelta (RF96, RF97) y emite el acta general con huella SHA-256 y QR (RF92).</p>
            </div>
          </div>

          {!computado && (
            <>
              <ul className="cv-checklist">
                {[
                  { ok: proceso.estado === 'CERRADO', texto: 'Votación del proceso concluida (RN32)' },
                  { ok: Boolean(etapa), texto: `Sesión de cómputo instalada con quórum (RF91)${etapa ? ` · ${computo.lugarSesion}` : ''}` },
                  { ok: detalle.bloqueos.length === 0, texto: detalle.bloqueos.length ? `Mesas pendientes: ${detalle.bloqueos.join(' ')}` : 'Todas las mesas tienen sus actas entregadas, verificadas y calificadas (RF89, RF90)' },
                  { ok: actasVig.every((a) => si(a.integra)), texto: 'Huella SHA-256 de todas las actas vigentes coincide (RF90)' },
                  { ok: general && si(general.alcanzaQuorum), aviso: true, texto: `Participación ${pct(general?.participacionPct)}: ${general && si(general.alcanzaQuorum) ? 'supera' : 'NO supera'} el ${pct(proceso.quorumMinimo)} (si no lo supera, nulidad total A1)` },
                ].map((r) => (
                  <li key={r.texto} className={r.ok ? 'ok' : r.aviso ? 'cp-aviso' : 'bad'}>
                    <span className="cv-check-icon"><MenuIcon name={r.ok ? 'check' : r.aviso ? 'alert' : 'close'} size={12} /></span>{r.texto}
                  </li>
                ))}
              </ul>
              {esCeunp && (accion !== 'COMPUTAR' ? (
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-primary" disabled={saving || !acciones.ejecutarComputo} onClick={() => setAccion('COMPUTAR')}>
                    <MenuIcon name="graph" size={15} /> Ejecutar cómputo oficial
                  </button>
                </div>
              ) : (
                <div className="cq-confirmar-emision" role="alert">
                  <div>
                    <strong>¿Ejecutar el cómputo oficial de «{proceso.nombre}»?</strong>
                    <span>Se computan {rm.habilitadas} mesa(s). {general && !si(general.alcanzaQuorum) ? `La participación (${pct(general.participacionPct)}) no supera el mínimo: se declarará la NULIDAD TOTAL de la elección.` : 'Se registran los resultados y el proceso pasa a FINALIZADO.'} No se podrá repetir ni modificar (RN26).</span>
                  </div>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                    <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={ejecutarComputo}>
                      <MenuIcon name="check" size={15} /> {saving ? 'Computando…' : 'Confirmar cómputo'}
                    </button>
                  </div>
                </div>
              ))}
            </>
          )}

          {computado && (
            <>
              {computo.resultado === 'NULIDAD_TOTAL' && (
                <div className="mx-mensaje peligro" role="note">
                  <MenuIcon name="alert" size={18} />
                  <div>
                    <h4>A1 · Nulidad total de la elección (RN31, RN34)</h4>
                    <p>{proceso.motivoAnulacion} Comuníquela a SUNEDU, la Asamblea Universitaria y el Consejo Universitario, y publique el acta general.</p>
                  </div>
                </div>
              )}
              <dl className="cq-meta cp-meta">
                <div><dt>Cómputo</dt><dd>{fecha(computo.fechaComputo)} · {computo.computadoPor}</dd></div>
                <div><dt>Mesas computadas</dt><dd>{computo.mesasComputadas} de {computo.mesasTotal}</dd></div>
                <div><dt>Participación</dt><dd>{pct(computo.participacionPct)} ({computo.votaron} de {computo.electoresHabiles})</dd></div>
                <div><dt>Resultado</dt><dd>{computo.resultado === 'VALIDA' ? 'Elección válida' : 'Nulidad total'}</dd></div>
                <div className="cp-ancho2"><dt>Huella SHA-256 del acta general</dt><dd className="cp-hash">{computo.hashIntegridad} {si(computo.actaIntegra) ? '· íntegra' : '· ALTERADA'}</dd></div>
              </dl>
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-primary" onClick={() => imprimirActaGeneral(computo, tokens.acta)}>
                  <MenuIcon name="file" size={15} /> Imprimir acta general{tokens.acta ? ' (con QR)' : ''}
                </button>
                {computo.resultado === 'NULIDAD_TOTAL' && (
                  <button type="button" className="cv-btn cv-btn-ghost im-btn-peligro" onClick={() => imprimirComunicacionNulidad(computo, proceso)}>
                    <MenuIcon name="alert" size={15} /> Imprimir comunicación de nulidad
                  </button>
                )}
                {tokens.acta && (
                  <a className="cv-btn cv-btn-ghost" href={urlVerificacionComputo(tokens.acta)} target="_blank" rel="noreferrer">
                    <MenuIcon name="key" size={15} /> Verificar QR
                  </a>
                )}
              </div>
              {!tokens.acta && <p className="muted cp-nota">El QR del acta solo se entrega al emitirla; esta reimpresión lleva la huella SHA-256 para su verificación.</p>}

              {detalle.resultados && (
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Cargo (14-15 determinarGanador)</th><th>Resultado</th><th>Lista</th><th className="n">Votos</th><th className="n">% válidos</th><th className="n">Participación</th></tr></thead>
                    <tbody>
                      {detalle.resultados.cargos.map((c) => {
                        const filas = detalle.resultados.detalle.filter((r) => r.idCargo === c.idCargo && r.tipoVoto === 'VALIDO');
                        return filas.map((r, i) => (
                          <tr key={`${c.idCargo}-${r.idLista}`} className={r.idLista === c.idListaGanadora ? 'cp-puntera' : ''}>
                            {i === 0 && <td rowSpan={filas.length}><strong>{c.cargo}</strong></td>}
                            {i === 0 && <td rowSpan={filas.length}><span className={`cv-estado ${CLASE_RESULTADO[c.estadoResultado] ?? 'creado'}`}>{ESTADO_RESULTADO[c.estadoResultado]}</span></td>}
                            <td>{r.posicion}. {r.lista}</td>
                            <td className="n">{r.totalVotos}</td><td className="n">{pct(r.porcentajeValidos)}</td>
                            {i === 0 && <td rowSpan={filas.length} className="n">{pct(c.participacionPct)}</td>}
                          </tr>
                        ));
                      })}
                    </tbody>
                  </table>
                </div>
              )}

              {/* A2 · Segunda vuelta (RN33) */}
              {(acciones.convocarSegundaVuelta || detalle.segundaVuelta) && (
                <div className="ig-form cp-segunda">
                  <h4>A2 · Segunda vuelta entre las dos listas más votadas (RN33)</h4>
                  {detalle.segundaVuelta ? (
                    <p className="ig-texto">Convocada: proceso N.º {detalle.segundaVuelta.id} «{detalle.segundaVuelta.nombre}» del {fecha(detalle.segundaVuelta.fechaInicio)} al {fecha(detalle.segundaVuelta.fechaFin)} ({detalle.segundaVuelta.estado}). Continúe su preparación en Convocatoria y cronograma.</p>
                  ) : (
                    <>
                      <p className="ig-texto">Ninguna lista superó el mínimo en {detalle.resultados?.cargos.filter((c) => c.estadoResultado === 'SEGUNDA_VUELTA').map((c) => c.cargo).join(', ')}. La segunda vuelta se realiza dentro de los {parametros.plazoSegundaVuelta} días siguientes al cómputo{parametros.limiteSegundaVuelta ? ` (hasta el ${fecha(parametros.limiteSegundaVuelta)})` : ''}.</p>
                      <div className="ig-grid">
                        <label className="cv-field">
                          <span className="cv-label">Inicio de la votación</span>
                          <input type="datetime-local" value={segunda.fechaInicio} disabled={saving} onChange={(e) => setSegunda((s) => ({ ...s, fechaInicio: e.target.value }))} />
                        </label>
                        <label className="cv-field">
                          <span className="cv-label">Fin de la votación</span>
                          <input type="datetime-local" value={segunda.fechaFin} disabled={saving} onChange={(e) => setSegunda((s) => ({ ...s, fechaFin: e.target.value }))} />
                        </label>
                      </div>
                      {accion !== 'SEGUNDA' ? (
                        <div className="cv-actions cp-izq">
                          <button type="button" className="cv-btn cv-btn-primary" disabled={saving || !segunda.fechaInicio || !segunda.fechaFin} onClick={() => setAccion('SEGUNDA')}>
                            <MenuIcon name="calendar" size={15} /> Convocar segunda vuelta
                          </button>
                        </div>
                      ) : (
                        <div className="cq-confirmar-emision" role="alert">
                          <div>
                            <strong>¿Convocar la segunda vuelta del {fecha(segunda.fechaInicio)} al {fecha(segunda.fechaFin)}?</strong>
                            <span>Se crea un proceso nuevo con las dos listas más votadas y el mismo padrón.</span>
                          </div>
                          <div className="cv-actions">
                            <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                            <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={convocarSegunda}>
                              <MenuIcon name="check" size={15} /> {saving ? 'Convocando…' : 'Confirmar'}
                            </button>
                          </div>
                        </div>
                      )}
                    </>
                  )}
                </div>
              )}
            </>
          )}
        </div>
      )}

      {/* ── 16-17 Proclamación (RF98) ── */}
      {paso === 'PROCLAMACION' && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Proclamación de resultados</h3>
              <p className="muted">El Presidente del CEUNP proclama, en sesión del Pleno con quórum de {quorum} miembros (RN36), a la lista que superó el mínimo de cada cargo y se le entrega su credencial (RF98).</p>
            </div>
          </div>
          {!computado && <p className="empty-state">Realice primero el cómputo oficial.</p>}
          {computado && anulado && <p className="empty-state">La elección fue declarada nula (A1): no hay resultados que proclamar. Publique el acta general.</p>}
          {acciones.motivoNoProclama && (
            <div className="mx-mensaje peligro" role="note"><MenuIcon name="alert" size={18} /><div><p>{acciones.motivoNoProclama}</p></div></div>
          )}
          {acciones.proclamar && (
            <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setAccion('PROCLAMAR'); setConfirmando(true); }}>
              <h4>16 · Acreditar a la lista ganadora</h4>
              <div className="ig-grid">
                <label className="cv-field">
                  <span className="cv-label">N.º de resolución</span>
                  <input required maxLength={40} placeholder="RES-CEUNP-001-2026" value={proclamacion.numeroResolucion} disabled={saving} onChange={(e) => setProclamacion((p) => ({ ...p, numeroResolucion: e.target.value }))} />
                </label>
                <label className="cv-field">
                  <span className="cv-label">Miembros del Pleno</span>
                  <input type="number" min={1} max={9} required value={proclamacion.miembrosPleno} disabled={saving} onChange={(e) => setProclamacion((p) => ({ ...p, miembrosPleno: e.target.value }))} />
                  {Number(proclamacion.miembrosPleno) < quorum && <small className="cv-error">Sin quórum: se requieren {quorum} (RN36).</small>}
                </label>
                <label className="cv-field cp-ancho2">
                  <span className="cv-label">Presidente del CEUNP que proclama</span>
                  <input required maxLength={150} value={proclamacion.presidente} disabled={saving} onChange={(e) => setProclamacion((p) => ({ ...p, presidente: e.target.value }))} />
                </label>
              </div>
              <label className="cv-field">
                <span className="cv-label">Fundamento (opcional)</span>
                <textarea rows={2} maxLength={1000} value={proclamacion.fundamento} disabled={saving} onChange={(e) => setProclamacion((p) => ({ ...p, fundamento: e.target.value }))} />
              </label>
              <ul className="cv-checklist">
                {detalle.resultados?.cargos.map((c) => (
                  <li key={c.idCargo} className={c.estadoResultado === 'ELEGIDO' ? 'ok' : 'cp-aviso'}>
                    <span className="cv-check-icon"><MenuIcon name={c.estadoResultado === 'ELEGIDO' ? 'trophy' : 'alert'} size={12} /></span>
                    {c.cargo}: {c.estadoResultado === 'ELEGIDO' ? `se proclama a ${c.listaGanadora}` : `${ESTADO_RESULTADO[c.estadoResultado]}, no se proclama`}
                  </li>
                ))}
              </ul>
              {!(confirmando && accion === 'PROCLAMAR') ? (
                <div className="cv-actions">
                  <button type="submit" className="cv-btn cv-btn-success" disabled={saving || !proclamacion.numeroResolucion.trim() || !proclamacion.presidente.trim() || Number(proclamacion.miembrosPleno) < quorum}>
                    <MenuIcon name="trophy" size={15} /> Proclamar resultados
                  </button>
                </div>
              ) : (
                <div className="cq-confirmar-emision" role="alert">
                  <div>
                    <strong>¿Emitir la resolución {proclamacion.numeroResolucion} de proclamación?</strong>
                    <span>Se acredita a las listas ganadoras con su código de credencial. La proclamación no se puede deshacer.</span>
                  </div>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                    <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={proclamar}>
                      <MenuIcon name="check" size={15} /> {saving ? 'Proclamando…' : 'Confirmar proclamación'}
                    </button>
                  </div>
                </div>
              )}
            </form>
          )}
          {computo?.proclamacion && (
            <>
              <dl className="cq-meta cp-meta">
                <div><dt>Resolución</dt><dd>{computo.numeroResolucion}</dd></div>
                <div><dt>Fecha</dt><dd>{fecha(computo.fechaProclamacion)}</dd></div>
                <div><dt>Presidente del CEUNP</dt><dd>{computo.presidenteCeunp}</dd></div>
                <div><dt>Miembros del Pleno</dt><dd>{computo.miembrosPleno}</dd></div>
              </dl>
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-primary" onClick={() => imprimirResolucionProclamacion(computo, tokens.proclamacion)}>
                  <MenuIcon name="file" size={15} /> Imprimir resolución{tokens.proclamacion ? ' (con QR)' : ''}
                </button>
                {tokens.proclamacion && (
                  <a className="cv-btn cv-btn-ghost" href={urlVerificacionComputo(tokens.proclamacion)} target="_blank" rel="noreferrer">
                    <MenuIcon name="key" size={15} /> Verificar QR
                  </a>
                )}
              </div>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Cargo</th><th>Lista proclamada (17 listaAcreditada)</th><th className="n">Votos</th><th className="n">% válidos</th><th>Credencial</th><th /></tr></thead>
                  <tbody>
                    {detalle.proclamados.map((p) => (
                      <tr key={p.idCargo} className="cp-puntera">
                        <td><strong>{p.cargo}</strong></td><td>{p.lista}</td>
                        <td className="n">{p.votos}</td><td className="n">{pct(p.porcentajeValidos)}</td>
                        <td><code className="cp-codigo">{p.codigoCredencial}</code></td>
                        <td>
                          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirCredencial(computo, p)}>
                            <MenuIcon name="qr" size={13} /> Imprimir credencial
                          </button>
                        </td>
                      </tr>
                    ))}
                    {detalle.proclamados.length === 0 && <tr><td colSpan={6} className="muted">Ningún cargo tiene lista ganadora: segunda vuelta o nueva elección.</td></tr>}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      )}

      {/* ── 18-19 Publicación (RF99) ── */}
      {paso === 'PUBLICACION' && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Publicación en el portal electoral</h3>
              <p className="muted">Los resultados por mesa y generales se publican en el portal después de la proclamación (RF99). Si la elección se anuló, se publica el acta general con la nulidad.</p>
            </div>
            {filasMesa && (
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirResultadosMesa(proceso, filasMesa, detalle.consolidado)}>
                  <MenuIcon name="file" size={13} /> Imprimir resultados por mesa
                </button>
              </div>
            )}
          </div>
          {etapa === 'PUBLICADO' ? (
            <div className="cq-resultado ok" role="status">
              <div className="cq-resultado-head">
                <span className="cq-resultado-icono"><MenuIcon name="check" size={22} /></span>
                <div>
                  <h4>19 · Resultados publicados</h4>
                  <p>Publicados el {fecha(computo.fechaPublicacion)} por {computo.publicadoPor}. El portal muestra el consolidado, la proclamación y los resultados por mesa.</p>
                </div>
              </div>
              <div className="cv-actions cp-izq">
                <a className="cv-btn cv-btn-ghost" href={`/api/publico/procesos/${proceso.id}/resultados`} target="_blank" rel="noreferrer">
                  <MenuIcon name="external" size={15} /> Ver en el portal
                </a>
              </div>
            </div>
          ) : !acciones.publicar ? (
            <p className="empty-state">{computado ? 'Proclame primero los resultados (RF98).' : 'Realice primero el cómputo oficial.'}</p>
          ) : accion !== 'PUBLICAR' ? (
            <div className="cv-actions cp-izq">
              <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => setAccion('PUBLICAR')}>
                <MenuIcon name="external" size={15} /> Publicar resultados
              </button>
            </div>
          ) : (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>¿Publicar los resultados de «{proceso.nombre}» en el portal?</strong>
                <span>Quedan visibles para toda la comunidad universitaria y ya no se pueden retirar.</span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={publicar}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Publicando…' : 'Confirmar publicación'}
                </button>
              </div>
            </div>
          )}
          {filasMesa && filasMesa.length > 0 && (
            <div className="table-wrap">
              <table>
                <thead><tr><th>Mesa</th><th>Cargo</th><th>Opción</th><th className="n">Votos</th></tr></thead>
                <tbody>
                  {filasMesa.filter((f) => f.opcion !== 'IMPUGNADO' || f.votos > 0).map((f) => (
                    <tr key={`${f.idMesa}-${f.cargo}-${f.opcion}-${f.lista}`}>
                      <td>Mesa {f.numeroMesa}</td><td>{f.cargo}</td><td>{f.lista}</td><td className="n">{f.votos}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

/** Revisión de una mesa: actas (marcar dudosa, comprobar), conteo y calificación del CEUNP. */
function FichaMesa({
  datos, acciones, saving, accion, setAccion, confirmando, setConfirmando,
  motivoDuda, setMotivoDuda, onMarcar, comprobacion, setComprobacion, onComprobar, lectura,
  calificacion, setCalificacion, onCalificar, onCerrar,
}) {
  const m = datos.mesa;
  const puede = acciones.verificarActas;
  const noAutentica = m.actasNoAutenticas > 0 || m.actasAlteradas > 0;
  const califica = puede && !m.calificacion && ['CERRADA'].includes(m.estado) && m.estadoEscrutinio === 'ENTREGADA';
  const nulidad = calificacion.calificacion === 'NULIDAD';
  const listo = calificacion.calificacion && calificacion.fundamento.trim().length >= 10 && (!nulidad || calificacion.numeroResolucion.trim());
  const cargos = [...new Set(datos.conteo.map((c) => c.cargo))];

  return (
    <div className="panel mx-ficha ig-expediente">
      <div className="mx-ficha-top">
        <div>
          <h3>Mesa {m.numeroMesa}</h3>
          <p>{m.ubicacion}</p>
        </div>
        <div className="cs-acciones-head">
          <span className={`cv-estado ${CLASE_SITUACION[m.situacion] ?? 'creado'}`}>{SITUACION_MESA[m.situacion] ?? m.situacion}</span>
          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={onCerrar}><MenuIcon name="close" size={13} /> Cerrar</button>
        </div>
      </div>
      <dl className="mx-datos">
        <div><dt>Votaron</dt><dd>{m.totalVotantes ?? 0} de {m.totalElectores}</dd></div>
        <div><dt>Conciliación</dt><dd>{m.estadoEscrutinio ? (si(m.conteoCuadra) && si(m.totalCuadra) ? 'Coincide con el conteo digital' : 'Difiere: prevalece la cédula física') : '—'}</dd></div>
        <div><dt>Acta observada</dt><dd>{si(m.observada) ? 'Sí' : 'No'}</dd></div>
        <div><dt>Calificación del CEUNP</dt><dd>{m.calificacion ? `${m.calificacion === 'NULIDAD' ? 'Nulidad' : 'Válida'}${m.resolucionCalificacion ? ` · ${m.resolucionCalificacion}` : ''}` : si(m.requiereCalificacion) ? 'Pendiente (A3)' : 'No requiere'}</dd></div>
      </dl>

      <h4 className="cp-sub">Actas de la mesa (4-5 validarIntegridad / actasValidas)</h4>
      <div className="table-wrap">
        <table>
          <thead><tr><th>Acta</th><th>Emisión</th><th>Huella SHA-256</th><th>Autenticidad (RF90)</th><th /></tr></thead>
          <tbody>
            {datos.actas.map((a) => (
              <tr key={a.idActa}>
                <td><strong>{TIPO_ACTA[a.tipo] ?? a.tipo}</strong><small className="pd-sub">N.º {String(a.idActa).padStart(6, '0')} · {a.estado}</small></td>
                <td>{fecha(a.fechaEmision)}</td>
                <td><span className={`cv-estado ${si(a.integra) ? 'votacion' : 'anulado'}`}>{si(a.integra) ? 'Coincide' : 'Alterada'}</span><small className="pd-sub cp-hash">{a.hashIntegridad?.slice(0, 16)}…</small></td>
                <td>
                  {a.comprobacion ? (
                    <><span className={`cv-estado ${a.comprobacion === 'AUTENTICA' ? 'votacion' : 'anulado'}`}>{a.comprobacion === 'AUTENTICA' ? 'Auténtica' : 'No auténtica'}</span>
                      <small className="pd-sub">QR {a.qrCoincide == null ? 'no leído' : si(a.qrCoincide) ? 'coincide' : 'no coincide'} · {fecha(a.fechaComprobacion)}</small></>
                  ) : si(a.dudosa) ? (
                    <><span className="cv-estado inscripcion">Dudosa</span><small className="pd-sub">{a.motivoDuda}</small></>
                  ) : <span className="muted">Sin observación</span>}
                </td>
                <td>
                  {puede && a.estado === 'VIGENTE' && !si(a.dudosa) && (
                    <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving} onClick={() => setAccion(`DUDOSA:${a.idActa}`)}>
                      <MenuIcon name="alert" size={13} /> Marcar dudosa
                    </button>
                  )}
                  {puede && si(a.dudosa) && !a.comprobacion && (
                    <button type="button" className="cv-btn cv-btn-primary cq-mini" disabled={saving} onClick={() => setAccion(`COMPROBAR:${a.idActa}`)}>
                      <MenuIcon name="key" size={13} /> Comprobar autenticidad
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {accion?.startsWith('DUDOSA:') && (
        <form className="ig-form" onSubmit={(e) => { e.preventDefault(); onMarcar(Number(accion.split(':')[1])); }}>
          <h4>4 · Marcar el acta como dudosa</h4>
          <label className="cv-field">
            <span className="cv-label">Motivo</span>
            <textarea rows={2} minLength={10} maxLength={500} required value={motivoDuda} disabled={saving}
              placeholder="Ej.: el ejemplar físico presenta enmendaduras en el total de votos."
              onChange={(e) => setMotivoDuda(e.target.value)} />
          </label>
          <div className="cv-actions">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAccion(null)}>Cancelar</button>
            <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || motivoDuda.trim().length < 10}>
              <MenuIcon name="alert" size={15} /> {saving ? 'Registrando…' : 'Marcar dudosa'}
            </button>
          </div>
        </form>
      )}

      {accion?.startsWith('COMPROBAR:') && (
        <div className="ig-form">
          <h4>5 · Comprobar la autenticidad con el QR del ejemplar físico</h4>
          <p className="muted">Lea el QR impreso en el acta física (o pegue su enlace). Se recalcula la huella SHA-256 del contenido guardado y se compara el QR con el del acta. Sin QR, solo se comprueba la huella.</p>
          <label className="cv-field">
            <span className="cv-label">Observación (opcional)</span>
            <input maxLength={500} value={comprobacion.observacion} disabled={saving} onChange={(e) => setComprobacion((c) => ({ ...c, observacion: e.target.value }))} />
          </label>
          <EscanerQR deshabilitado={saving} onCodigo={(codigo) => onComprobar(Number(accion.split(':')[1]), codigo)} />
          <div className="cv-actions">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAccion(null)}>Cancelar</button>
            <button type="button" className="cv-btn cv-btn-ghost" disabled={saving} onClick={() => onComprobar(Number(accion.split(':')[1]), '')}>
              <MenuIcon name="key" size={15} /> Comprobar solo la huella
            </button>
          </div>
        </div>
      )}

      {lectura && (
        <div className={`cq-resultado ${lectura.resultado === 'AUTENTICA' ? 'ok' : 'mal'}`} role="status" aria-live="polite">
          <div className="cq-resultado-head">
            <span className="cq-resultado-icono"><MenuIcon name={lectura.resultado === 'AUTENTICA' ? 'check' : 'alert'} size={22} /></span>
            <div>
              <h4>{lectura.resultado === 'AUTENTICA' ? 'Acta auténtica' : 'Acta NO auténtica'}</h4>
              <p>Huella {si(lectura.huellaCoincide) ? 'coincide' : 'NO coincide'} · QR {lectura.qrCoincide == null ? 'no leído' : si(lectura.qrCoincide) ? 'coincide' : 'NO coincide'}</p>
            </div>
          </div>
          <dl className="cq-meta">
            <div><dt>Huella guardada</dt><dd className="cp-hash">{lectura.hashIntegridad}</dd></div>
            <div><dt>Huella recalculada</dt><dd className="cp-hash">{lectura.hashRecalculado}</dd></div>
          </dl>
        </div>
      )}

      {cargos.length > 0 && (
        <>
          <h4 className="cp-sub">Conteo del acta de escrutinio (6-7 consolidarVotos)</h4>
          <div className="table-wrap">
            <table>
              <thead><tr><th>Cargo</th><th>Opción</th><th className="n">Cédula física</th><th className="n">Impugnados asignados</th><th className="n">Se computa</th><th className="n">Conteo digital</th></tr></thead>
              <tbody>
                {datos.conteo.filter((c) => c.opcion !== 'IMPUGNADO' || c.votosActa > 0).map((c) => (
                  <tr key={`${c.idCargo}-${c.opcion}-${c.idLista}`} className={c.opcion !== 'IMPUGNADO' && c.votosActa !== c.votosDigital ? 'cp-alerta' : ''}>
                    <td>{c.cargo}</td><td>{c.lista}</td>
                    <td className="n">{c.votosActa}</td><td className="n">{c.impugnadosAsignados}</td>
                    <td className="n"><strong>{c.opcion === 'IMPUGNADO' ? '—' : c.votos}</strong></td>
                    <td className="n">{c.opcion === 'IMPUGNADO' ? '—' : c.votosDigital}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {califica && (
        accion !== 'CALIFICAR' ? (
          <div className="cv-actions cp-izq">
            {si(m.requiereCalificacion) && !noAutentica && (
              <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={() => { setAccion('CALIFICAR'); setCalificacion((c) => ({ ...c, calificacion: 'VALIDA' })); }}>
                <MenuIcon name="check" size={15} /> Calificar acta válida
              </button>
            )}
            <button type="button" className="cv-btn cv-btn-ghost im-btn-peligro" disabled={saving} onClick={() => { setAccion('CALIFICAR'); setCalificacion((c) => ({ ...c, calificacion: 'NULIDAD' })); }}>
              <MenuIcon name="close" size={15} /> Declarar nulidad de la mesa
            </button>
          </div>
        ) : (
          <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
            <h4>{nulidad ? 'Paso 7 · Nulidad de la votación de la mesa (RF94)' : 'A3 · Calificación del acta que difiere (RF95)'}</h4>
            <div className="im-estados cq-chips" role="group" aria-label="Calificación">
              {(!noAutentica && si(m.requiereCalificacion) ? ['VALIDA', 'NULIDAD'] : ['NULIDAD']).map((c) => (
                <button key={c} type="button" className={`cq-chip${calificacion.calificacion === c ? ' on' : ''}`} onClick={() => { setCalificacion((x) => ({ ...x, calificacion: c })); setConfirmando(false); }}>
                  {c === 'VALIDA' ? 'Válida (cédula física)' : 'Nulidad'}
                </button>
              ))}
            </div>
            <div className="ig-grid">
              {nulidad && (
                <label className="cv-field">
                  <span className="cv-label">N.º de resolución (RN34)</span>
                  <input required maxLength={40} value={calificacion.numeroResolucion} disabled={saving} onChange={(e) => setCalificacion((c) => ({ ...c, numeroResolucion: e.target.value }))} />
                </label>
              )}
              <label className="cv-field cp-ancho3">
                <span className="cv-label">Fundamento del CEUNP</span>
                <textarea rows={2} minLength={10} maxLength={1000} required value={calificacion.fundamento} disabled={saving}
                  placeholder={nulidad ? 'Ej.: el acta no es auténtica; se declara la nulidad de la votación de la mesa.' : 'Ej.: revisadas las cédulas, prevalece el conteo físico del acta.'}
                  onChange={(e) => setCalificacion((c) => ({ ...c, fundamento: e.target.value }))} />
              </label>
            </div>
            {!confirmando ? (
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAccion(null)}>Cancelar</button>
                <button type="submit" className={`cv-btn ${nulidad ? 'cv-btn-primary im-btn-peligro' : 'cv-btn-success'}`} disabled={saving || !listo}>
                  <MenuIcon name="scale" size={15} /> Registrar calificación
                </button>
              </div>
            ) : (
              <div className="cq-confirmar-emision" role="alert">
                <div>
                  <strong>{nulidad ? `¿Declarar la nulidad de la mesa ${m.numeroMesa} (${calificacion.numeroResolucion})?` : `¿Calificar válida el acta de la mesa ${m.numeroMesa}?`}</strong>
                  <span>{nulidad ? 'La mesa y sus actas quedan ANULADAS y sus votos no se computan.' : 'Se computa con el conteo de la cédula física (RF84).'} La decisión del CEUNP es inapelable (RN36).</span>
                </div>
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                  <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onCalificar}>
                    <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar'}
                  </button>
                </div>
              </div>
            )}
          </form>
        )
      )}
    </div>
  );
}
