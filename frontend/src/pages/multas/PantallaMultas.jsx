import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { fecha } from '../credenciales/LectorQR';
import {
  CAUSAL_DESCARGO, ESTADO_MULTA, MEDIO, MOTIVO, MOTIVO_BASE, ROL, soles,
  imprimirDescargo, imprimirNotificaciones, imprimirReporteGestion, imprimirReporteOmisos, imprimirResolucionMultas,
} from './ReporteMultas';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import '../cierre/cierre.css';
import '../impugnaciones/impugnaciones.css';
import '../computo/computo.css';
import '../nulidades/nulidades.css';
import './multas.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS16 · Reportar omisos y multas — «PantallaMultas» (boundary). Actor: CEUNP.
 *
 * Mensajes del diagrama «Colaboration - Reportar omisos y multas»:
 *   1 solicitarReporteOmisos(id_proceso) → PantallaMultas                     (pestaña Reporte de omisos)
 *   2 generarMultas(id_proceso) → GenerarMultas · 3 obtenerUIT() ParametroGlobal
 *   4 consultarNoVotaron() PadronElectoral · 5 consultarInasistentes() MiembroMesa
 *   6 insertar(id_docente, monto, motivo) Multa · 7 mostrarReporteMultas()     (pestaña Multas y resolución)
 *   8 registrarJustificacion(id_multa, sustento) → RegistrarJustificacion      (pestaña Descargos y pagos)
 *   9 justificar(id_multa) · 10 actualizarEstado('JUSTIFICADA') · 11 confirmar()
 *
 * RF103 omisos al sufragio (2.5 % UIT, Art. 68) · RF104 miembros de mesa inasistentes (3 % UIT, Art. 67)
 * · RF105 UIT y porcentajes parametrizados · RF106 justificación · RF107 reportes de gestión
 * · RN35 · RN36 Pleno con quórum, inapelable · RN40 casos no previstos. El sistema no cobra la multa.
 */

const ESTADO_PROCESO = {
  CERRADO: { clase: 'inscripcion', texto: 'Votación concluida' },
  FINALIZADO: { clase: 'votacion', texto: 'Finalizado' },
  ANULADO: { clase: 'anulado', texto: 'Anulado' },
  VOTACION: { clase: 'votacion', texto: 'En votación' },
};
const CLASE_MULTA = { PENDIENTE: 'creado', PAGADA: 'votacion', JUSTIFICADA: 'inscripcion', EXONERADA: 'inscripcion' };
const COLOR_MULTA = { PENDIENTE: '#d97706', PAGADA: '#059669', JUSTIFICADA: '#2563eb', EXONERADA: '#64748b' };
const PASOS = [
  { codigo: 'OMISOS', texto: 'Reporte de omisos', nota: 'No votaron e inasistentes · RF103-104', icono: 'users' },
  { codigo: 'RESOLUCION', texto: 'Multas y resolución', nota: 'Pleno y notificación · RN35-36', icono: 'scale' },
  { codigo: 'DESCARGOS', texto: 'Descargos y pagos', nota: 'Justificación y recibo · RF106', icono: 'check' },
  { codigo: 'GESTION', texto: 'Reportes de gestión', nota: 'Participación y mesas · RF107', icono: 'graph' },
];
const CAUSALES = Object.keys(CAUSAL_DESCARGO);
const pct = (v) => `${Number(v ?? 0).toFixed(2)} %`;
const si = (v) => v === true || v === 1;
const claveToken = (id) => `cus16-token-${id}`;
const ahoraLocal = () => {
  const d = new Date();
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().slice(0, 16);
};
const conSegundos = (v) => (v ? `${v}:00` : null);
const tiempo = (seg) => {
  if (seg == null) return '—';
  const s = Math.round(Number(seg));
  return s < 60 ? `${s} s` : `${Math.floor(s / 60)} min ${String(s % 60).padStart(2, '0')} s`;
};
const descargoVacio = { tipo: 'JUSTIFICACION', causal: '', sustento: '', documento: '', fechaPresentacion: '', decision: '', fundamento: '', numeroResolucion: '', miembrosPleno: '5' };
const pagoVacio = { numeroRecibo: '', fechaPago: '', observacion: '' };

function leerToken(id) {
  try {
    return sessionStorage.getItem(claveToken(id));
  } catch {
    return null;
  }
}
function guardarToken(id, token) {
  try {
    sessionStorage.setItem(claveToken(id), token);
  } catch { /* almacenamiento no disponible */ }
}

/** Pestaña con la que conviene abrir el proceso. */
function pasoInicial(d) {
  if (!d?.reporte || d.desactualizado) return 'OMISOS';
  if (d.reporte.estado === 'GENERADO' || d.acciones.notificar) return 'RESOLUCION';
  return 'DESCARGOS';
}

function cuenta(codigo, d) {
  switch (codigo) {
    case 'OMISOS': return d.omisos.length;
    case 'RESOLUCION': return d.multas.length;
    case 'DESCARGOS': return d.multas.filter((m) => m.estadoPago === 'PENDIENTE').length;
    case 'GESTION': return d.gestion.length;
    default: return 0;
  }
}

export default function PantallaMultas({ onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [paso, setPaso] = useState('OMISOS');
  const [accion, setAccion] = useState(null);   // GENERAR | RESOLUCION | NOTIFICAR | NOTIFICAR:<id> | DESCARGO | PAGO
  const [confirmando, setConfirmando] = useState(false);
  const [filtro, setFiltro] = useState({ motivo: 'TODOS', estado: 'TODOS', texto: '' });
  const [idMulta, setIdMulta] = useState(null);
  const [multa, setMulta] = useState(null);
  const [resolucion, setResolucion] = useState({ numeroResolucion: '', miembrosPleno: '5', fundamento: '' });
  const [notificacion, setNotificacion] = useState({ medio: 'CORREO_INSTITUCIONAL', documento: '', fecha: '' });
  const [descargo, setDescargo] = useState(descargoVacio);
  const [pago, setPago] = useState(pagoVacio);
  const [documentoResolucion, setDocumentoResolucion] = useState(null);
  const [token, setToken] = useState(null);
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const cargarDetalle = useCallback(async (id, moverPaso) => {
    if (!id) return null;
    const d = await apiRequest(`/api/multas/procesos/${id}`);
    setDetalle(d);
    setToken(leerToken(id));
    if (moverPaso) setPaso(pasoInicial(d));
    const quorum = String(d.parametros?.quorumPleno ?? 5);
    setResolucion((r) => ({ ...r, miembrosPleno: quorum }));
    setDescargo((x) => ({ ...x, miembrosPleno: quorum }));
    return d;
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/multas/procesos');
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
    if (!idMulta) {
      setMulta(null);
      return;
    }
    (async () => {
      try {
        setMulta(await apiRequest(`/api/multas/${idMulta}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idMulta, manejarError]);

  useEffect(() => {
    setDocumentoResolucion(null);
    if (!idProceso || detalle?.reporte?.estado !== 'RESUELTO') return;
    (async () => {
      try {
        setDocumentoResolucion(await apiRequest(`/api/multas/procesos/${idProceso}/resolucion`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idProceso, detalle?.reporte?.estado, detalle?.reporte?.numeroResolucion, manejarError]);

  function limpiarAccion() {
    setAccion(null);
    setConfirmando(false);
  }

  function irA(codigo) {
    setPaso(codigo);
    limpiarAccion();
    setFeedback(null);
  }

  async function cambiarProceso(id) {
    setIdProceso(id);
    setIdMulta(null);
    setFiltro({ motivo: 'TODOS', estado: 'TODOS', texto: '' });
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
      setProcesos(await apiRequest('/api/multas/procesos'));
      await cargarDetalle(idProceso, false);
      if (idMulta) setMulta(await apiRequest(`/api/multas/${idMulta}`));
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
      if (data.multa) setMulta(data.multa);
      if (data.resolucion) setDocumentoResolucion(data.resolucion);
      setFeedback({ type: 'success', text: data.mensaje });
      limpiarAccion();
      alTerminar?.(data);
      setProcesos(await apiRequest('/api/multas/procesos'));
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

  /** 2 generarMultas(id_proceso): 3 obtenerUIT · 4 consultarNoVotaron · 5 consultarInasistentes · 6 insertar. */
  const generar = () => ejecutar(`/api/multas/procesos/${idProceso}/generar`, {}, () => setPaso('RESOLUCION'));

  /** 7 mostrarReporteMultas(): el Pleno determina las multas con su resolución (RN35, RN36). */
  const emitirResolucion = () => ejecutar(`/api/multas/procesos/${idProceso}/resolucion`, {
    numeroResolucion: resolucion.numeroResolucion,
    miembrosPleno: Number(resolucion.miembrosPleno),
    fundamento: resolucion.fundamento.trim() || null,
  }, (d) => {
    if (d.tokenQr) {
      guardarToken(idProceso, d.tokenQr);
      setToken(d.tokenQr);
    }
    setResolucion((r) => ({ ...r, numeroResolucion: '', fundamento: '' }));
  });

  /** Notificación de las multas determinadas (todas las que faltan o una). */
  const notificar = (id) => ejecutar(`/api/multas/procesos/${idProceso}/notificacion`, {
    idMulta: id ?? null,
    medio: notificacion.medio,
    documento: notificacion.documento.trim() || null,
    fecha: conSegundos(notificacion.fecha),
  }, () => setNotificacion((n) => ({ ...n, documento: '' })));

  /** 8 registrarJustificacion → 9 justificar · 10 actualizarEstado · 11 confirmar. */
  const justificar = () => ejecutar(`/api/multas/${idMulta}/justificacion`, {
    tipo: descargo.tipo,
    causal: descargo.causal,
    sustento: descargo.sustento,
    documento: descargo.documento.trim() || null,
    fechaPresentacion: descargo.tipo === 'JUSTIFICACION' ? conSegundos(descargo.fechaPresentacion) : null,
    decision: descargo.tipo === 'EXONERACION' ? 'ADMITIDA' : descargo.decision,
    fundamento: descargo.fundamento,
    numeroResolucion: descargo.numeroResolucion,
    miembrosPleno: Number(descargo.miembrosPleno),
  }, () => setDescargo((x) => ({ ...descargoVacio, miembrosPleno: x.miembrosPleno })));

  /** Pago registrado con el recibo de Tesorería (el sistema no cobra). */
  const pagar = () => ejecutar(`/api/multas/${idMulta}/pago`, {
    numeroRecibo: pago.numeroRecibo,
    fechaPago: conSegundos(pago.fechaPago),
    observacion: pago.observacion.trim() || null,
  }, () => setPago(pagoVacio));

  function abrirMulta(id) {
    setIdMulta(id === idMulta ? null : id);
    limpiarAccion();
    setPaso('DESCARGOS');
  }

  // ─── Datos derivados ─────────────────────────────────────────────────────

  const multasFiltradas = useMemo(() => {
    const texto = filtro.texto.trim().toLowerCase();
    return (detalle?.multas ?? []).filter((m) => (filtro.motivo === 'TODOS' || m.motivo === filtro.motivo)
      && (filtro.estado === 'TODOS' || m.estadoPago === filtro.estado)
      && (!texto || `${m.dni} ${m.docente} ${m.facultad} ${m.departamento ?? ''}`.toLowerCase().includes(texto)));
  }, [detalle, filtro]);

  const omisosFiltrados = useMemo(() => {
    const texto = filtro.texto.trim().toLowerCase();
    return (detalle?.omisos ?? []).filter((o) => (filtro.motivo === 'TODOS' || o.motivo === filtro.motivo)
      && (!texto || `${o.dni} ${o.docente} ${o.facultad} ${o.departamento ?? ''}`.toLowerCase().includes(texto)));
  }, [detalle, filtro]);

  if (cargando) return <div className="panel"><p className="muted">Cargando omisos y multas…</p></div>;
  if (!detalle) {
    return (
      <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mu-shell mx">
        {feedback && <div className={`alert ${feedback.type}`} role="status">{feedback.text}</div>}
        <div className="panel"><p className="empty-state">No hay procesos con la votación concluida: el reporte de omisos se obtiene al cerrar el sufragio (CUS11).</p></div>
      </div>
    );
  }

  const { proceso, parametros: par, resumenMesas: rm, participacion, reporte, resumen, acciones } = detalle;
  const estProc = ESTADO_PROCESO[proceso.estado] ?? { clase: 'creado', texto: proceso.estado };
  const quorum = par.quorumPleno ?? 5;
  const resuelto = reporte?.estado === 'RESUELTO';
  const omisosVotacion = detalle.omisos.filter((o) => o.motivo === 'OMISO_VOTACION');
  const omisosMesa = detalle.omisos.filter((o) => o.motivo === 'OMISO_MESA');
  const montoEstimado = detalle.omisos.reduce((s, o) => s + Number(o.montoEstimado ?? 0), 0);
  const sinNotificar = detalle.multas.filter((m) => !m.fechaNotificacion);
  const seleccionada = detalle.multas.find((m) => m.idMulta === idMulta) ?? null;
  const etapa = !reporte ? 'Sin generar' : detalle.desactualizado ? 'Desactualizado' : resuelto ? 'Determinadas' : 'Generadas';

  const filtros = (conEstado) => (
    <div className="mu-filtros">
      <div className="cq-chips" role="group" aria-label="Motivo">
        {[['TODOS', 'Todos'], ['OMISO_VOTACION', 'No votaron'], ['OMISO_MESA', 'Inasistentes a mesa']].map(([v, t]) => (
          <button key={v} type="button" className={`cq-chip${filtro.motivo === v ? ' on' : ''}`} onClick={() => setFiltro((f) => ({ ...f, motivo: v }))}>{t}</button>
        ))}
      </div>
      {conEstado && (
        <div className="cq-chips" role="group" aria-label="Estado">
          {['TODOS', 'PENDIENTE', 'PAGADA', 'JUSTIFICADA', 'EXONERADA'].map((v) => (
            <button key={v} type="button" className={`cq-chip${filtro.estado === v ? ' on' : ''}`} onClick={() => setFiltro((f) => ({ ...f, estado: v }))}>
              {v === 'TODOS' ? 'Todo estado' : ESTADO_MULTA[v]}
            </button>
          ))}
        </div>
      )}
      <label className="mu-buscar">
        <MenuIcon name="search" size={14} />
        <input value={filtro.texto} onChange={(e) => setFiltro((f) => ({ ...f, texto: e.target.value }))} placeholder="DNI, docente o facultad" aria-label="Buscar" />
      </label>
    </div>
  );

  return (
    <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mu-shell mx">
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))}>
            {procesos.map((p) => (
              <option key={p.id} value={p.id}>
                {p.nombre} · {p.tipo === 'SEGUNDA_VUELTA' ? '2.ª vuelta · ' : ''}{p.estado}{p.numeroResolucion ? ` · ${p.numeroResolucion}` : p.estadoReporte ? ' · multas generadas' : ''}{p.pendientes ? ` · ${p.pendientes} pendiente(s)` : ''}
              </option>
            ))}
          </select>
        </label>
        <div className={`in-plazo ${resuelto ? 'closed' : 'open'}`}>
          <MenuIcon name="coins" size={18} />
          <div>
            <strong>{resuelto ? `Multas determinadas · ${reporte.numeroResolucion}` : `${estProc.texto} · multas ${etapa.toLowerCase()}`}</strong>
            <span>RF105 UIT {soles(par.uit)} · {pct(par.pctElector)} al omiso ({soles(par.montoElector)}) · {pct(par.pctMiembro)} al miembro de mesa ({soles(par.montoMiembro)}) · RN36 quórum {quorum}</span>
          </div>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      <div className="pd-tabs cq-tabs mx-pasos cp-pasos nl-pasos mu-pasos" role="tablist" aria-label="Reportar omisos y multas">
        {PASOS.map((p) => {
          const n = cuenta(p.codigo, detalle);
          const alerta = (p.codigo === 'OMISOS' && (detalle.desactualizado || acciones.generar && !reporte))
            || (p.codigo === 'RESOLUCION' && (acciones.emitirResolucion || acciones.notificar));
          return (
            <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
              className={`pd-tab mx-paso${paso === p.codigo ? ' on' : ''}${alerta ? ' nl-alerta' : ''}`}
              onClick={() => irA(p.codigo)}>
              <span className="mx-paso-num"><MenuIcon name={p.icono} size={14} /></span>
              <span className="mx-paso-texto"><b>{p.texto}{n ? <em className="nl-cuenta">{n}</em> : null}</b><small>{p.nota}</small></span>
            </button>
          );
        })}
      </div>

      <section className="cq-resumen">
        <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
          <span>No votaron <em>RF103</em></span>
          <strong>{reporte ? resumen.omisosVotacion : omisosVotacion.length}<small> / {participacion?.electoresHabiles ?? '—'}</small></strong>
          <small>{pct(par.pctElector)} UIT · {soles(par.montoElector)} c/u</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
          <span>Inasistentes a mesa <em>RF104</em></span>
          <strong>{reporte ? resumen.omisosMesa : omisosMesa.length}</strong>
          <small>{pct(par.pctMiembro)} UIT · {soles(par.montoMiembro)} c/u</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': '#d97706' }}>
          <span>Monto {reporte ? 'determinado' : 'estimado'} <em>RN35</em></span>
          <strong className="mu-monto">{soles(reporte ? resumen.montoTotal : montoEstimado)}</strong>
          <small>{reporte ? `${soles(resumen.montoPendiente)} pendiente · ${soles(resumen.montoPagada)} pagado` : 'Aún no se generan las multas'}</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': resuelto ? '#059669' : detalle.desactualizado ? '#e11d48' : '#2563eb' }}>
          <span>Multas <em>{reporte ? `${reporte.vecesGenerado}.ª generación` : 'CUS16'}</em></span>
          <strong className="cp-etapa">{etapa}</strong>
          <small><span className={`cv-estado ${estProc.clase}`}>{estProc.texto}</span>{resuelto ? ` · ${resumen.notificadas} de ${resumen.total} notificada(s)` : ''}</small>
        </div>
      </section>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}
      {detalle.soloLectura && <div className="alert success" role="note">Vista de consulta: las multas las genera y determina el Pleno del CEUNP.</div>}
      {detalle.avisos.length > 0 && (
        <div className="mx-mensaje aviso nl-avisos" role="note">
          <MenuIcon name="alert" size={18} />
          <div>
            <h4>Pendientes del proceso</h4>
            <ul className="cp-lista">{detalle.avisos.map((a) => <li key={a}>{a}</li>)}</ul>
          </div>
        </div>
      )}

      {/* ── 1-6 Reporte de omisos y generación de multas (RF103-RF105) ── */}
      {paso === 'OMISOS' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>1 solicitarReporteOmisos · docentes que no votaron y miembros de mesa que no asistieron</h3>
                <p className="muted">Con el sufragio cerrado, el sistema cruza el padrón (4 consultarNoVotaron) y los miembros titulares de mesa (5 consultarInasistentes) y calcula la multa con la UIT vigente (3 obtenerUIT). No figuran los electores de mesas que no se instalaron, porque no pudieron votar. Puede volver a generar las multas hasta que el Pleno emita la resolución.</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirReporteOmisos(detalle)}>
                  <MenuIcon name="file" size={15} /> Imprimir reporte
                </button>
              </div>
            </div>

            <div className="mu-parametros">
              <div><span>3 obtenerUIT()</span><strong>{soles(par.uit)}</strong><small>Parámetro UIT (RF105)</small></div>
              <div><span>Omisión al sufragio</span><strong>{pct(par.pctElector)}</strong><small>{soles(par.montoElector)} · Art. 68</small></div>
              <div><span>Inasistencia a mesa</span><strong>{pct(par.pctMiembro)}</strong><small>{soles(par.montoMiembro)} · Art. 67</small></div>
              <div><span>Mesas instaladas</span><strong>{rm.instaladas} / {rm.total}</strong><small>{rm.noInstaladas} sin instalar · {rm.abiertas} abierta(s)</small></div>
              <div><span>Participación</span><strong>{pct(participacion?.participacionPct)}</strong><small>{participacion?.votaron ?? 0} de {participacion?.electoresHabiles ?? 0} electores</small></div>
            </div>

            {!acciones.generar && acciones.motivoNoGenerar && !detalle.soloLectura && (
              <div className="mx-mensaje info" role="note"><MenuIcon name="info" size={18} /><div><p>{acciones.motivoNoGenerar}</p></div></div>
            )}
            {acciones.generar && (accion !== 'GENERAR' ? (
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => setAccion('GENERAR')}>
                  <MenuIcon name="coins" size={15} /> {reporte ? 'Volver a generar multas' : 'Generar multas'}
                </button>
              </div>
            ) : (
              <div className="cq-confirmar-emision" role="alert">
                <div>
                  <strong>¿Generar {detalle.omisos.length} multa(s) por {soles(montoEstimado)}?</strong>
                  <span>2 generarMultas · 6 insertar: {omisosVotacion.length} por omisión al sufragio y {omisosMesa.length} por inasistencia a la mesa, con la UIT de {soles(par.uit)}. {reporte ? 'Se actualizan las multas pendientes con los omisos actuales.' : 'Luego el Pleno las determina con su resolución.'}</span>
                </div>
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                  <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={generar}>
                    <MenuIcon name="check" size={15} /> {saving ? 'Generando…' : 'Confirmar'}
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Omisos del proceso</h3>
                <p className="muted">{detalle.omisos.length} omiso(s) según el registro actual del sufragio. El monto es el que tendría la multa con los parámetros vigentes.</p>
              </div>
            </div>
            {filtros(false)}
            <div className="table-wrap">
              <table>
                <thead><tr><th>Docente</th><th>Facultad</th><th>Motivo</th><th>Mesa</th><th className="n">Multa</th><th>Situación</th></tr></thead>
                <tbody>
                  {omisosFiltrados.map((o) => {
                    const generada = detalle.multas.find((m) => m.idDocente === o.idDocente && m.motivo === o.motivo);
                    return (
                      <tr key={`${o.idDocente}-${o.motivo}`}>
                        <td><strong>{o.docente}</strong><small className="pd-sub">DNI {o.dni} · {o.categoria?.toLowerCase()}</small></td>
                        <td>{o.facultad}<small className="pd-sub">{o.departamento ?? '—'}</small></td>
                        <td>
                          <span className={`mu-motivo ${o.motivo === 'OMISO_MESA' ? 'mesa' : 'voto'}`}>{MOTIVO[o.motivo]}</span>
                          <small className="pd-sub">{MOTIVO_BASE[o.motivo]}{o.rolMesa ? ` · ${ROL[o.rolMesa] ?? o.rolMesa}` : ''}</small>
                          {si(o.asistioSinVotar) && <small className="pd-sub mu-nota">Asistió y no votó (CUS10 A3)</small>}
                        </td>
                        <td>{o.numeroMesa ?? '—'}</td>
                        <td className="n">{soles(o.montoEstimado)}</td>
                        <td>{generada
                          ? <span className={`cv-estado ${CLASE_MULTA[generada.estadoPago]}`}>Multa N.º {generada.idMulta}</span>
                          : <span className="cv-estado creado">Por generar</span>}</td>
                      </tr>
                    );
                  })}
                  {omisosFiltrados.length === 0 && <tr><td colSpan={6} className="muted">{detalle.omisos.length ? 'Ningún omiso coincide con el filtro.' : 'No hay omisos: todos los electores votaron y los titulares asistieron.'}</td></tr>}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {/* ── 6-7 Multas generadas, resolución del Pleno y notificación ── */}
      {paso === 'RESOLUCION' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>7 mostrarReporteMultas · resolución del Pleno</h3>
                <p className="muted">El Pleno del CEUNP, con quórum de {quorum} de sus 9 miembros, determina las multas generadas mediante resolución inapelable (RN35, RN36). La resolución lleva QR y huella SHA-256; luego las multas quedan fijas y se notifican al docente.</p>
              </div>
              {resuelto && (
                <div className="cs-acciones-head">
                  <button type="button" className="cv-btn cv-btn-ghost" disabled={!documentoResolucion} onClick={() => imprimirResolucionMultas(documentoResolucion, token)}>
                    <MenuIcon name="qr" size={15} /> Imprimir resolución{token ? ' con QR' : ''}
                  </button>
                </div>
              )}
            </div>

            {!reporte && <p className="empty-state">Aún no se generan las multas de este proceso: hágalo en «Reporte de omisos».</p>}
            {reporte && (
              <dl className="mx-datos cp-meta">
                <div><dt>Generadas</dt><dd>{fecha(reporte.fechaGeneracion)} · {reporte.generadoPor}</dd></div>
                <div><dt>UIT y porcentajes</dt><dd>{soles(reporte.uitReferencia)} · {pct(reporte.pctElector)} · {pct(reporte.pctMiembro)}</dd></div>
                <div><dt>Multas</dt><dd>{reporte.omisosVotacion} al sufragio · {reporte.omisosMesa} de mesa · {soles(reporte.montoTotal)}</dd></div>
                <div><dt>Resolución</dt><dd>{resuelto
                  ? <>{reporte.numeroResolucion} · {fecha(reporte.fechaResolucion)} <span className={`cv-estado ${si(reporte.resolucionIntegra) ? 'votacion' : 'anulado'}`}>{si(reporte.resolucionIntegra) ? 'Huella coincide' : 'Alterada'}</span></>
                  : <span className="cv-estado creado">Pendiente del Pleno</span>}</dd></div>
              </dl>
            )}
            {resuelto && (
              <dl className="nl-texto">
                <div><dt>Fundamento</dt><dd>{reporte.fundamento}</dd></div>
                <div><dt>Huella SHA-256</dt><dd className="cp-hash">{reporte.hashIntegridad}</dd></div>
              </dl>
            )}
            {resuelto && !token && <p className="muted cp-nota">El QR de la resolución solo se entrega al emitirla; la reimpresión lleva la huella SHA-256.</p>}
            {detalle.desactualizado && (
              <div className="mx-mensaje peligro" role="note"><MenuIcon name="alert" size={18} /><div><p>Las multas generadas ya no coinciden con los omisos o los parámetros actuales: vuelva a generarlas antes de la resolución.</p></div></div>
            )}

            {acciones.emitirResolucion && (accion !== 'RESOLUCION' ? (
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => { setAccion('RESOLUCION'); setConfirmando(false); }}>
                  <MenuIcon name="scale" size={15} /> Emitir resolución del Pleno
                </button>
              </div>
            ) : (
              <form className="ig-form mu-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
                <h4>Resolución que determina {reporte.omisosVotacion + reporte.omisosMesa} multa(s) por {soles(reporte.montoTotal)}</h4>
                <div className="ig-grid nl-pleno">
                  <label className="cv-field">
                    <span className="cv-label">N.º de resolución</span>
                    <input required maxLength={40} value={resolucion.numeroResolucion} disabled={saving} placeholder="Ej.: 031-2026-CEUNP"
                      onChange={(e) => { setResolucion((r) => ({ ...r, numeroResolucion: e.target.value })); setConfirmando(false); }} />
                  </label>
                  <label className="cv-field">
                    <span className="cv-label">Miembros presentes del Pleno</span>
                    <input type="number" min={1} max={9} required value={resolucion.miembrosPleno} disabled={saving}
                      onChange={(e) => { setResolucion((r) => ({ ...r, miembrosPleno: e.target.value })); setConfirmando(false); }} />
                    {Number(resolucion.miembrosPleno) < quorum && <small className="cv-error">Sin quórum: se requieren {quorum} miembros (RN36).</small>}
                  </label>
                  <label className="cv-field nl-ancho">
                    <span className="cv-label">Fundamento (opcional)</span>
                    <textarea rows={3} maxLength={1000} value={resolucion.fundamento} disabled={saving}
                      placeholder="Si lo deja vacío se usa el texto de los artículos 67 y 68 del Reglamento de Elecciones."
                      onChange={(e) => { setResolucion((r) => ({ ...r, fundamento: e.target.value })); setConfirmando(false); }} />
                  </label>
                </div>
                {!confirmando ? (
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Cancelar</button>
                    <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !resolucion.numeroResolucion.trim() || Number(resolucion.miembrosPleno) < quorum}>
                      <MenuIcon name="scale" size={15} /> Emitir resolución
                    </button>
                  </div>
                ) : (
                  <div className="cq-confirmar-emision" role="alert">
                    <div>
                      <strong>¿Emitir la Resolución {resolucion.numeroResolucion} con {resolucion.miembrosPleno} miembros del Pleno?</strong>
                      <span>Las multas quedan determinadas y ya no se podrán volver a generar. La decisión es inapelable (RN36).</span>
                    </div>
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                      <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={emitirResolucion}>
                        <MenuIcon name="check" size={15} /> {saving ? 'Emitiendo…' : 'Confirmar'}
                      </button>
                    </div>
                  </div>
                )}
              </form>
            ))}
          </div>

          {resuelto && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Notificación a los docentes</h3>
                  <p className="muted">{resumen.notificadas} de {resumen.total} multa(s) notificada(s). Desde la notificación corre el plazo de {par.plazoJustificacion} días para presentar la justificación (Disp. Final 2.ª y 5.ª).</p>
                </div>
                <div className="cs-acciones-head">
                  <button type="button" className="cv-btn cv-btn-ghost" disabled={!detalle.multas.length}
                    onClick={() => imprimirNotificaciones(proceso, reporte, detalle.multas, par.plazoJustificacion, token)}>
                    <MenuIcon name="file" size={15} /> Imprimir cédulas
                  </button>
                </div>
              </div>
              {acciones.notificar && (
                <FormNotificacion
                  titulo={accion?.startsWith('NOTIFICAR:') ? `Notificar la multa N.º ${accion.split(':')[1]}` : `Notificar las ${sinNotificar.length} multa(s) pendientes de notificación`}
                  abierto={accion === 'NOTIFICAR' || accion?.startsWith('NOTIFICAR:')}
                  notificacion={notificacion} setNotificacion={setNotificacion} saving={saving}
                  confirmando={confirmando} setConfirmando={setConfirmando}
                  onAbrir={() => { setAccion('NOTIFICAR'); setConfirmando(false); setNotificacion((n) => ({ ...n, fecha: ahoraLocal() })); }}
                  onCancelar={limpiarAccion}
                  onConfirmar={() => notificar(accion?.startsWith('NOTIFICAR:') ? Number(accion.split(':')[1]) : null)}
                />
              )}
            </div>
          )}

          {reporte && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>6 insertar · multas {resuelto ? 'determinadas' : 'generadas'}</h3>
                  <p className="muted">{detalle.multas.length} multa(s). Cada una guarda la UIT y el porcentaje con que se calculó.</p>
                </div>
              </div>
              {filtros(true)}
              <TablaMultas filas={multasFiltradas} activo={idMulta} gestionar={acciones.descargo} onAbrir={abrirMulta}
                onNotificar={acciones.notificar ? (id) => { setAccion(`NOTIFICAR:${id}`); setConfirmando(false); setNotificacion((n) => ({ ...n, fecha: ahoraLocal() })); } : null} />
            </div>
          )}
        </>
      )}

      {/* ── 8-11 Descargos (justificación y exoneración) y pagos ── */}
      {paso === 'DESCARGOS' && (
        <>
          <section className="mu-estados">
            {['PENDIENTE', 'PAGADA', 'JUSTIFICADA', 'EXONERADA'].map((e) => (
              <button key={e} type="button" className={`mu-estado${filtro.estado === e ? ' on' : ''}`} style={{ '--mu-color': COLOR_MULTA[e] }}
                onClick={() => setFiltro((f) => ({ ...f, estado: f.estado === e ? 'TODOS' : e }))}>
                <span>{ESTADO_MULTA[e]}</span>
                <strong>{resumen[e.toLowerCase()]}</strong>
                <small>{soles(resumen[`monto${e.charAt(0)}${e.slice(1).toLowerCase()}`])}</small>
              </button>
            ))}
          </section>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>8 registrarJustificacion · multas del proceso</h3>
                <p className="muted">El docente presenta su justificación dentro de los {par.plazoJustificacion} días de notificado; el Pleno la admite o la deniega (RF106). En casos no previstos el CEUNP puede exonerar de oficio (RN40). El pago se registra con el recibo de Tesorería: el sistema no cobra la multa.</p>
              </div>
            </div>
            {!resuelto && <div className="mx-mensaje info" role="note"><MenuIcon name="info" size={18} /><div><p>Los descargos y pagos se registran cuando el Pleno ya determinó las multas con su resolución.</p></div></div>}
            {filtros(true)}
            <TablaMultas filas={multasFiltradas} activo={idMulta} gestionar={acciones.descargo} onAbrir={abrirMulta} />
          </div>

          {seleccionada && (
            <FichaMulta
              m={seleccionada} documento={multa?.idMulta === seleccionada.idMulta ? multa : null} acciones={acciones} quorum={quorum}
              accion={accion} setAccion={setAccion} confirmando={confirmando} setConfirmando={setConfirmando} saving={saving}
              descargo={descargo} setDescargo={setDescargo} pago={pago} setPago={setPago}
              onJustificar={justificar} onPagar={pagar} onCancelar={limpiarAccion}
              onCerrar={() => { setIdMulta(null); limpiarAccion(); }}
            />
          )}

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>11 confirmar · descargos resueltos</h3>
                <p className="muted">{detalle.descargos.length} descargo(s) resuelto(s) por el Pleno en este proceso.</p>
              </div>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th>Resolución</th><th>Docente</th><th>Descargo</th><th>Decisión</th><th className="n">Multa</th><th /></tr></thead>
                <tbody>
                  {detalle.descargos.map((j) => (
                    <tr key={j.idJustificacion}>
                      <td><strong>{j.numeroResolucion}</strong><small className="pd-sub">{fecha(j.fechaResolucion)} · {j.miembrosPleno} miembros</small></td>
                      <td>{j.docente}<small className="pd-sub">DNI {j.dni} · {MOTIVO[j.motivo]}</small></td>
                      <td>{j.tipo === 'EXONERACION' ? 'Exoneración de oficio' : 'Justificación'}<small className="pd-sub">{CAUSAL_DESCARGO[j.causal] ?? j.causal}</small></td>
                      <td><span className={`cv-estado ${j.decision === 'ADMITIDA' ? 'votacion' : 'anulado'}`}>{j.decision === 'ADMITIDA' ? 'Admitida' : 'Denegada'}</span></td>
                      <td className="n">{soles(j.monto)}<small className="pd-sub">{ESTADO_MULTA[j.estadoPago]}</small></td>
                      <td>
                        <div className="nl-acciones-fila">
                          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => abrirMulta(j.idMulta)}>
                            <MenuIcon name="eye" size={13} /> Multa
                          </button>
                          <button type="button" className="cv-btn cv-btn-ghost cq-mini"
                            onClick={async () => {
                              try {
                                imprimirDescargo(await apiRequest(`/api/multas/${j.idMulta}`), j);
                              } catch (e) {
                                manejarError(e);
                              }
                            }}>
                            <MenuIcon name="file" size={13} /> Resolución
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                  {detalle.descargos.length === 0 && <tr><td colSpan={6} className="muted">No hay descargos resueltos.</td></tr>}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {/* ── RF107 Reportes de gestión ── */}
      {paso === 'GESTION' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Reporte de gestión del proceso (RF107)</h3>
                <p className="muted">Participación por mesa, instalación, asistencia de los miembros titulares, incidencias, tiempo promedio de atención por elector y actas emitidas y entregadas. Junto con el reporte de multas sirve para la memoria del Comité Electoral.</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirReporteGestion(detalle, tiempo)}>
                  <MenuIcon name="file" size={15} /> Imprimir reporte de gestión
                </button>
              </div>
            </div>
            <div className="mu-parametros">
              <div><span>Participación</span><strong>{pct(participacion?.participacionPct)}</strong><small>Mínimo {pct(participacion?.quorumMinimo)} · {si(participacion?.alcanzaQuorum) ? 'alcanzado' : 'no alcanzado'}</small></div>
              <div><span>Mesas instaladas</span><strong>{rm.instaladas} / {rm.total}</strong><small>{rm.noInstaladas} sin instalar</small></div>
              <div><span>Actas entregadas</span><strong>{rm.actasEntregadas} / {rm.total}</strong><small>al CEUNP</small></div>
              <div><span>Incidencias</span><strong>{detalle.incidencias.reduce((s, i) => s + Number(i.total), 0)}</strong><small>{detalle.incidencias.length} tipo(s)</small></div>
              <div><span>Multas determinadas</span><strong>{resumen.total}</strong><small>{soles(resumen.montoTotal)}</small></div>
            </div>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr><th>Mesa</th><th>Instalación</th><th className="n">Electores</th><th className="n">Votaron</th><th>Participación</th><th className="n">Titulares</th><th className="n">Incid.</th><th className="n">Atención</th><th>Actas</th></tr>
                </thead>
                <tbody>
                  {detalle.gestion.map((g) => {
                    const p = g.electores ? (100 * Number(g.votaron)) / Number(g.electores) : 0;
                    return (
                      <tr key={g.idMesa}>
                        <td><strong>Mesa {g.numeroMesa}</strong><small className="pd-sub">{g.ubicacion}</small></td>
                        <td>{g.horaInstalacion ? fecha(g.horaInstalacion) : <span className="cv-estado anulado">No instalada</span>}<small className="pd-sub">{g.estado?.replaceAll('_', ' ').toLowerCase()}</small></td>
                        <td className="n">{g.electores}</td>
                        <td className="n">{g.votaron}</td>
                        <td>
                          <i className="cq-barra mu-barra"><b style={{ width: `${Math.min(100, p)}%` }} /></i>
                          <small className="pd-sub">{pct(p)}</small>
                        </td>
                        <td className="n">{g.titularesPresentes} / {Number(g.titularesPresentes) + Number(g.titularesAusentes)}<small className="pd-sub">{g.suplentesEnFuncion ? `${g.suplentesEnFuncion} suplente(s)` : 'sin suplentes'}</small></td>
                        <td className="n">{g.incidencias}</td>
                        <td className="n">{tiempo(g.atencionPromedioSeg)}</td>
                        <td>{g.actasEmitidas} / 3<small className="pd-sub">{g.fechaEntrega ? `Entregadas ${fecha(g.fechaEntrega)}` : 'Sin entregar'}</small></td>
                      </tr>
                    );
                  })}
                  {detalle.gestion.length === 0 && <tr><td colSpan={9} className="muted">El proceso no tiene mesas.</td></tr>}
                </tbody>
              </table>
            </div>
          </div>

          <div className="mu-dos">
            <div className="panel cv-form">
              <div className="cv-section-head"><div><h3>Incidencias por tipo</h3></div></div>
              <ul className="mu-barras">
                {detalle.incidencias.map((i) => {
                  const max = Math.max(...detalle.incidencias.map((x) => Number(x.total)));
                  return (
                    <li key={i.tipo}>
                      <span>{i.tipo.replaceAll('_', ' ').toLowerCase()}</span>
                      <i><b style={{ width: `${(100 * Number(i.total)) / max}%` }} /></i>
                      <strong>{i.total}</strong>
                    </li>
                  );
                })}
              </ul>
              {detalle.incidencias.length === 0 && <p className="muted">Sin incidencias registradas en las mesas.</p>}
            </div>
            <div className="panel cv-form">
              <div className="cv-section-head"><div><h3>Multas por estado</h3></div></div>
              <ul className="mu-barras">
                {['PENDIENTE', 'PAGADA', 'JUSTIFICADA', 'EXONERADA'].map((e) => (
                  <li key={e} style={{ '--mu-color': COLOR_MULTA[e] }}>
                    <span>{ESTADO_MULTA[e]}</span>
                    <i><b style={{ width: `${resumen.total ? (100 * resumen[e.toLowerCase()]) / resumen.total : 0}%` }} /></i>
                    <strong>{resumen[e.toLowerCase()]}</strong>
                  </li>
                ))}
              </ul>
              <p className="muted cp-nota">Recaudación registrada: {soles(resumen.montoPagada)} de {soles(resumen.montoTotal)}. El cobro corresponde a Tesorería (CUN12).</p>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

function TablaMultas({ filas, activo, gestionar, onAbrir, onNotificar }) {
  return (
    <div className="table-wrap">
      <table>
        <thead><tr><th>Multa</th><th>Docente</th><th>Motivo</th><th className="n">Monto</th><th>Notificación</th><th>Estado</th><th /></tr></thead>
        <tbody>
          {filas.map((m) => (
            <tr key={m.idMulta} className={m.idMulta === activo ? 'ig-fila on' : 'ig-fila'}>
              <td><strong>N.º {String(m.idMulta).padStart(5, '0')}</strong><small className="pd-sub">{fecha(m.fechaGeneracion)}</small></td>
              <td>{m.docente}<small className="pd-sub">DNI {m.dni} · {m.facultad}</small></td>
              <td>
                <span className={`mu-motivo ${m.motivo === 'OMISO_MESA' ? 'mesa' : 'voto'}`}>{MOTIVO[m.motivo]}</span>
                <small className="pd-sub">{m.numeroMesa ? `Mesa ${m.numeroMesa}` : '—'}{m.rolMesa ? ` · ${ROL[m.rolMesa] ?? m.rolMesa}` : ''}{si(m.asistioSinVotar) ? ' · asistió y no votó' : ''}</small>
              </td>
              <td className="n">{soles(m.monto)}<small className="pd-sub">{Number(m.porcentajeUit).toFixed(1)} % UIT</small></td>
              <td>{m.fechaNotificacion
                ? <>{fecha(m.fechaNotificacion)}<small className="pd-sub">{MEDIO[m.medioNotificacion] ?? m.medioNotificacion}{m.documentoNotificacion ? ` · ${m.documentoNotificacion}` : ''}</small></>
                : <span className="muted">Sin notificar</span>}</td>
              <td>
                <span className={`cv-estado ${CLASE_MULTA[m.estadoPago]}`}>{ESTADO_MULTA[m.estadoPago]}</span>
                {m.numeroRecibo && <small className="pd-sub">Recibo {m.numeroRecibo}</small>}
                {m.resolucionDescargo && <small className="pd-sub">{m.tipoDescargo === 'EXONERACION' ? 'Exoneración de oficio' : `Justificación ${m.decisionDescargo === 'ADMITIDA' ? 'admitida' : 'denegada'}`} · {m.resolucionDescargo}</small>}
              </td>
              <td>
                <div className="nl-acciones-fila">
                  {onNotificar && !m.fechaNotificacion && (
                    <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => onNotificar(m.idMulta)}>
                      <MenuIcon name="external" size={13} /> Notificar
                    </button>
                  )}
                  <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => onAbrir(m.idMulta)}>
                    <MenuIcon name={gestionar && m.estadoPago === 'PENDIENTE' ? 'edit' : 'eye'} size={13} /> {m.idMulta === activo ? 'Cerrar' : gestionar && m.estadoPago === 'PENDIENTE' ? 'Gestionar' : 'Ver'}
                  </button>
                </div>
              </td>
            </tr>
          ))}
          {filas.length === 0 && <tr><td colSpan={7} className="muted">No hay multas que coincidan.</td></tr>}
        </tbody>
      </table>
    </div>
  );
}

function FormNotificacion({ titulo, abierto, notificacion, setNotificacion, saving, confirmando, setConfirmando, onAbrir, onCancelar, onConfirmar }) {
  if (!abierto) {
    return (
      <div className="cv-actions cp-izq">
        <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={onAbrir}>
          <MenuIcon name="external" size={15} /> Notificar multas pendientes
        </button>
      </div>
    );
  }
  const cedula = notificacion.medio === 'CEDULA_PERSONAL';
  const listo = notificacion.medio && (!cedula || notificacion.documento.trim());
  const set = (campo) => (e) => { setNotificacion((n) => ({ ...n, [campo]: e.target.value })); setConfirmando(false); };
  return (
    <form className="ig-form mu-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
      <h4>{titulo}</h4>
      <div className="cv-field">
        <span className="cv-label">Medio de notificación</span>
        <div className="cq-chips" role="group" aria-label="Medio">
          {Object.entries(MEDIO).map(([v, t]) => (
            <button key={v} type="button" className={`cq-chip${notificacion.medio === v ? ' on' : ''}`} disabled={saving}
              onClick={() => { setNotificacion((n) => ({ ...n, medio: v })); setConfirmando(false); }}>{t}</button>
          ))}
        </div>
      </div>
      <div className="ig-grid">
        <label className="cv-field">
          <span className="cv-label">{cedula ? 'N.º de cédula o cargo' : 'Referencia (opcional)'}</span>
          <input maxLength={80} required={cedula} value={notificacion.documento} disabled={saving} onChange={set('documento')}
            placeholder={cedula ? 'Ej.: Cédula N.º 045-2026-CEUNP' : 'Ej.: correo del 28/10'} />
        </label>
        <label className="cv-field">
          <span className="cv-label">Fecha de notificación</span>
          <input type="datetime-local" value={notificacion.fecha} disabled={saving} onChange={set('fecha')} />
        </label>
      </div>
      {!confirmando ? (
        <div className="cv-actions">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
          <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !listo}>
            <MenuIcon name="external" size={15} /> Registrar notificación
          </button>
        </div>
      ) : (
        <div className="cq-confirmar-emision" role="alert">
          <div>
            <strong>¿Registrar la notificación por {MEDIO[notificacion.medio].toLowerCase()}?</strong>
            <span>Desde esta fecha corre el plazo para que el docente presente su justificación.</span>
          </div>
          <div className="cv-actions">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
            <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onConfirmar}>
              <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar'}
            </button>
          </div>
        </div>
      )}
    </form>
  );
}

/** Ficha de la multa: 8 registrarJustificacion · 9 justificar · 10 actualizarEstado · 11 confirmar, y pago. */
function FichaMulta({
  m, documento, acciones, quorum, accion, setAccion, confirmando, setConfirmando, saving,
  descargo, setDescargo, pago, setPago, onJustificar, onPagar, onCancelar, onCerrar,
}) {
  const pendiente = m.estadoPago === 'PENDIENTE';
  const lista = documento?.descargosLista ?? [];
  const yaJustifico = lista.some((j) => j.tipo === 'JUSTIFICACION');
  const vencido = m.limiteJustificacion && new Date(m.limiteJustificacion) < new Date();
  const exoneracion = descargo.tipo === 'EXONERACION';
  const setD = (campo) => (e) => { setDescargo((x) => ({ ...x, [campo]: e.target.value })); setConfirmando(false); };
  const setP = (campo) => (e) => { setPago((x) => ({ ...x, [campo]: e.target.value })); setConfirmando(false); };
  const listoDescargo = descargo.causal && descargo.sustento.trim().length >= 10 && descargo.fundamento.trim().length >= 10
    && descargo.numeroResolucion.trim() && Number(descargo.miembrosPleno) >= quorum && (exoneracion || descargo.decision);
  const listoPago = pago.numeroRecibo.trim().length >= 3;

  return (
    <div className="panel mx-ficha ig-expediente">
      <div className="mx-ficha-top">
        <div>
          <h3>Multa N.º {String(m.idMulta).padStart(5, '0')} · {m.docente}</h3>
          <p>{MOTIVO[m.motivo]} ({MOTIVO_BASE[m.motivo]}) · DNI {m.dni} · {m.facultad}</p>
        </div>
        <div className="cs-acciones-head">
          <span className={`cv-estado ${CLASE_MULTA[m.estadoPago]}`}>{ESTADO_MULTA[m.estadoPago]}</span>
          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={onCerrar}><MenuIcon name="close" size={13} /> Cerrar</button>
        </div>
      </div>
      <dl className="mx-datos">
        <div><dt>Monto</dt><dd>{soles(m.monto)} · {Number(m.porcentajeUit).toFixed(1)} % de {soles(m.uitReferencia)}</dd></div>
        <div><dt>Mesa</dt><dd>{m.numeroMesa ? `Mesa ${m.numeroMesa}` : '—'}{m.rolMesa ? ` · ${ROL[m.rolMesa] ?? m.rolMesa} titular` : ''}</dd></div>
        <div><dt>Notificada</dt><dd>{m.fechaNotificacion ? `${fecha(m.fechaNotificacion)} · ${MEDIO[m.medioNotificacion] ?? ''}` : 'Sin notificar'}</dd></div>
        <div><dt>Plazo de justificación</dt><dd>{m.limiteJustificacion ? <>{fecha(m.limiteJustificacion)}{vencido ? <span className="cv-estado anulado"> Vencido</span> : null}</> : 'Corre desde la notificación'}</dd></div>
      </dl>
      {si(m.asistioSinVotar) && <p className="ig-texto">El docente asistió a la mesa y no votó (CUS10 A3): el CEUNP resuelve si lo justifica (Disp. Final 5.ª).</p>}
      {m.estadoPago === 'PAGADA' && <p className="ig-texto">Pagada el {fecha(m.fechaPago)} con el recibo {m.numeroRecibo}{m.observacion ? ` · ${m.observacion}` : ''}.</p>}

      {lista.length > 0 && (
        <>
          <h4 className="cp-sub">Descargos de la multa</h4>
          <ul className="nl-recursos">
            {lista.map((j) => (
              <li key={j.idJustificacion}>
                <span className={`cv-estado ${j.decision === 'ADMITIDA' ? 'votacion' : 'anulado'}`}>{j.decision === 'ADMITIDA' ? 'Admitida' : 'Denegada'}</span>
                <span>{j.tipo === 'EXONERACION' ? 'Exoneración de oficio' : 'Justificación'} · {CAUSAL_DESCARGO[j.causal] ?? j.causal}<small>{j.numeroResolucion} · {fecha(j.fechaResolucion)} · {j.sustento}</small></span>
                <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirDescargo(documento, j)}>
                  <MenuIcon name="file" size={13} /> Resolución
                </button>
              </li>
            ))}
          </ul>
        </>
      )}

      {pendiente && acciones.descargo && accion !== 'DESCARGO' && accion !== 'PAGO' && (
        <div className="cv-actions cp-izq">
          <button type="button" className="cv-btn cv-btn-primary" disabled={saving}
            onClick={() => { setAccion('DESCARGO'); setConfirmando(false); setDescargo((x) => ({ ...x, tipo: yaJustifico || vencido ? 'EXONERACION' : 'JUSTIFICACION', fechaPresentacion: ahoraLocal() })); }}>
            <MenuIcon name="check" size={15} /> Registrar justificación
          </button>
          <button type="button" className="cv-btn cv-btn-ghost" disabled={saving}
            onClick={() => { setAccion('PAGO'); setConfirmando(false); setPago({ ...pagoVacio, fechaPago: ahoraLocal() }); }}>
            <MenuIcon name="coins" size={15} /> Registrar pago
          </button>
        </div>
      )}

      {accion === 'DESCARGO' && (
        <form className="ig-form mu-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>8 registrarJustificacion(id_multa, sustento) · 9 justificar()</h4>
          <div className="cq-chips" role="group" aria-label="Tipo de descargo">
            {[['JUSTIFICACION', 'Justificación del docente (RF106)'], ['EXONERACION', 'Exoneración de oficio (RN40)']].map(([v, t]) => (
              <button key={v} type="button" className={`cq-chip${descargo.tipo === v ? ' on' : ''}`}
                disabled={saving || (v === 'JUSTIFICACION' && (yaJustifico || vencido))}
                onClick={() => { setDescargo((x) => ({ ...x, tipo: v, decision: '' })); setConfirmando(false); }}>{t}</button>
            ))}
          </div>
          {(yaJustifico || vencido) && <p className="ig-texto">{yaJustifico ? 'El docente ya presentó una justificación que fue denegada' : 'Venció el plazo de justificación'}: solo cabe la exoneración de oficio del CEUNP (RN40).</p>}
          <div className="cv-field">
            <span className="cv-label">Causal</span>
            <div className="cq-chips" role="group" aria-label="Causal">
              {CAUSALES.map((c) => (
                <button key={c} type="button" className={`cq-chip${descargo.causal === c ? ' on' : ''}`} disabled={saving}
                  onClick={() => { setDescargo((x) => ({ ...x, causal: c })); setConfirmando(false); }}>{CAUSAL_DESCARGO[c]}</button>
              ))}
            </div>
          </div>
          <div className="ig-grid nl-pleno">
            <label className="cv-field nl-ancho">
              <span className="cv-label">{exoneracion ? 'Hecho que motiva la exoneración' : 'Sustento del docente'}</span>
              <textarea rows={2} minLength={10} maxLength={1000} required value={descargo.sustento} disabled={saving} onChange={setD('sustento')}
                placeholder={exoneracion ? 'Ej.: el docente figuraba en el padrón pese a estar de licencia.' : 'Ej.: estuvo hospitalizado el día de la elección.'} />
            </label>
            <label className="cv-field">
              <span className="cv-label">Documento sustentatorio</span>
              <input maxLength={150} value={descargo.documento} disabled={saving} onChange={setD('documento')} placeholder="Ej.: certificado médico N.º 1234" />
            </label>
            {!exoneracion && (
              <label className="cv-field">
                <span className="cv-label">Presentado el</span>
                <input type="datetime-local" value={descargo.fechaPresentacion} disabled={saving} onChange={setD('fechaPresentacion')} />
              </label>
            )}
            <label className="cv-field">
              <span className="cv-label">N.º de resolución</span>
              <input required maxLength={40} value={descargo.numeroResolucion} disabled={saving} onChange={setD('numeroResolucion')} placeholder="Ej.: 040-2026-CEUNP" />
            </label>
            <label className="cv-field">
              <span className="cv-label">Miembros del Pleno</span>
              <input type="number" min={1} max={9} required value={descargo.miembrosPleno} disabled={saving} onChange={setD('miembrosPleno')} />
              {Number(descargo.miembrosPleno) < quorum && <small className="cv-error">Sin quórum: se requieren {quorum} (RN36).</small>}
            </label>
          </div>
          {!exoneracion && (
            <div className="cv-field">
              <span className="cv-label">Decisión del Pleno</span>
              <div className="cq-chips" role="group" aria-label="Decisión">
                {[['ADMITIDA', 'Admitir: multa justificada'], ['DENEGADA', 'Denegar: sigue pendiente']].map(([v, t]) => (
                  <button key={v} type="button" className={`cq-chip${descargo.decision === v ? ' on' : ''}`} disabled={saving}
                    onClick={() => { setDescargo((x) => ({ ...x, decision: v })); setConfirmando(false); }}>{t}</button>
                ))}
              </div>
            </div>
          )}
          <label className="cv-field">
            <span className="cv-label">Fundamento de la decisión</span>
            <textarea rows={2} minLength={10} maxLength={1000} required value={descargo.fundamento} disabled={saving} onChange={setD('fundamento')}
              placeholder="Ej.: el certificado médico acredita el impedimento el día de la elección." />
          </label>
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !listoDescargo}>
                <MenuIcon name="scale" size={15} /> Resolver descargo
              </button>
            </div>
          ) : (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>{exoneracion ? `¿Exonerar la multa de ${m.docente}?` : descargo.decision === 'ADMITIDA' ? `¿Admitir la justificación de ${m.docente}?` : `¿Denegar la justificación de ${m.docente}?`}</strong>
                <span>10 actualizarEstado: la multa {exoneracion ? 'queda exonerada' : descargo.decision === 'ADMITIDA' ? 'queda justificada' : 'sigue pendiente de pago'}. Resolución {descargo.numeroResolucion}, inapelable (RN36).</span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onJustificar}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : '11 Confirmar'}
                </button>
              </div>
            </div>
          )}
        </form>
      )}

      {accion === 'PAGO' && (
        <form className="ig-form mu-form mu-pago" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>Pago de la multa en Tesorería</h4>
          <div className="ig-grid">
            <label className="cv-field">
              <span className="cv-label">N.º de recibo</span>
              <input required minLength={3} maxLength={40} value={pago.numeroRecibo} disabled={saving} onChange={setP('numeroRecibo')} placeholder="Ej.: 001-0004587" />
            </label>
            <label className="cv-field">
              <span className="cv-label">Fecha de pago</span>
              <input type="datetime-local" value={pago.fechaPago} disabled={saving} onChange={setP('fechaPago')} />
            </label>
            <label className="cv-field">
              <span className="cv-label">Observación</span>
              <input maxLength={300} value={pago.observacion} disabled={saving} onChange={setP('observacion')} />
            </label>
          </div>
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !listoPago}>
                <MenuIcon name="coins" size={15} /> Registrar pago
              </button>
            </div>
          ) : (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>¿Registrar el pago de {soles(m.monto)} con el recibo {pago.numeroRecibo}?</strong>
                <span>La multa queda pagada y ya no admite descargos.</span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onPagar}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar'}
                </button>
              </div>
            </div>
          )}
        </form>
      )}
    </div>
  );
}
