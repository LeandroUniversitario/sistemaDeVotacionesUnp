import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { fecha } from '../credenciales/LectorQR';
import { ESTADO_RESULTADO, SITUACION_MESA } from '../computo/ActaComputo';
import {
  CAUSAL, DESTINATARIO, imprimirActaSorteo, imprimirConvocatoriaSegunda, imprimirOficios, imprimirRecurso, imprimirResolucion,
} from './ResolucionNulidad';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import '../cierre/cierre.css';
import '../impugnaciones/impugnaciones.css';
import '../computo/computo.css';
import './nulidades.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS15 · Gestionar nulidades y segunda vuelta — «PantallaNulidades» (boundary). Actor: CEUNP.
 *
 * Mensajes del diagrama «Colaboration - Gestionar nulidades y segunda vuelta»:
 *   1 ingresarNulidadParcial(id_mesa, causal) → DeclararNulidadParcial          (pestaña Nulidad parcial)
 *   2 anularMesa(id_mesa, causal) · 3 actualizarEstado('ANULADA') · 4 mostrarMesaExcluida() (Resolución del Pleno)
 *   5 ingresarNulidadTotal(id_proceso, motivo) → DeclararNulidadTotal           (pestaña Nulidad total)
 *   6 anularProceso(id_proceso, motivo) · 7 actualizarEstado('ANULADO', motivo)  (Resolución del Pleno)
 *   8 registrarComunicacion('SUNEDU, AU, CU') · 9 mostrarResolucionNulidad()   (Comunicación y publicación)
 *   10 convocarSegundaVuelta(id_proceso, fechas) → ConfigurarSegundaVuelta      (pestaña Segunda vuelta)
 *   11 crearSegundaVuelta · 12 insertar · 13 copiarDosMasVotadas · 14 copiarPadron · 15 mostrarSegundaVuelta()
 *
 * RF100 nulidad parcial (Art. 64) · RF101 nulidad total (Art. 65) · RF102 comunicación (Art. 66)
 * · RN33 segunda vuelta · RN34 resolución · RN36 Pleno con quórum, inapelable · RF94 los
 * recursos pendientes bloquean el cómputo y la proclamación.
 */

const ESTADO_PROCESO = {
  VOTACION: { clase: 'votacion', texto: 'En votación' },
  CERRADO: { clase: 'inscripcion', texto: 'Votación concluida' },
  FINALIZADO: { clase: 'votacion', texto: 'Finalizado' },
  ANULADO: { clase: 'anulado', texto: 'Anulado' },
  CREADO: { clase: 'creado', texto: 'Creado' },
  INSCRIPCION: { clase: 'inscripcion', texto: 'Inscripción' },
};
const ETAPA = { SESION_INSTALADA: 'Sesión instalada', COMPUTADO: 'Computado', PROCLAMADO: 'Proclamado', PUBLICADO: 'Publicado' };
const ESTADO_RECURSO = {
  PRESENTADA: { clase: 'inscripcion', texto: 'Pendiente' },
  FUNDADA: { clase: 'anulado', texto: 'Fundada' },
  INFUNDADA: { clase: 'votacion', texto: 'Infundada' },
  IMPROCEDENTE: { clase: 'creado', texto: 'Improcedente' },
};
const CLASE_SITUACION = {
  HABILITADA: 'votacion', NO_INSTALADA: 'creado', ANULADA: 'anulado', ACTA_NO_AUTENTICA: 'anulado',
  POR_CALIFICAR: 'inscripcion', ACTA_DUDOSA: 'inscripcion', IMPUGNACIONES_PENDIENTES: 'inscripcion',
};
const CLASE_RESULTADO = { ELEGIDO: 'votacion', SEGUNDA_VUELTA: 'inscripcion', EMPATE: 'inscripcion', SIN_QUORUM: 'anulado', DESIERTO: 'anulado', PENDIENTE: 'creado' };
const CAUSALES_PARCIAL = ['INSTALACION_IRREGULAR', 'FRAUDE_MESA', 'ADMISION_INDEBIDA', 'ACTA_NO_AUTENTICA', 'OTRA_CAUSAL'];
const CAUSALES_TOTAL = ['FRAUDE', 'COHECHO', 'SOBORNO', 'INTIMIDACION', 'VIOLENCIA'];
const DESTINOS_OFICIO = ['SUNEDU', 'ASAMBLEA_UNIVERSITARIA', 'CONSEJO_UNIVERSITARIO'];
const DESTINOS = [...DESTINOS_OFICIO, 'PORTAL', 'EL_PERUANO'];
const TIPO_PERSONERO = { MESA: 'de mesa', GENERAL: 'general', ALTERNO: 'alterno' };
const OPCION = { BLANCO: 'Votos en blanco', NULO: 'Votos nulos', IMPUGNADO: 'Impugnados sin resolver' };
const PASOS = [
  { codigo: 'PARCIAL', texto: 'Nulidad parcial', nota: 'Votación de una mesa · RF100', icono: 'table' },
  { codigo: 'TOTAL', texto: 'Nulidad total', nota: 'Toda la elección · RF101', icono: 'alert' },
  { codigo: 'RESOLUCION', texto: 'Resolución del Pleno', nota: 'Quórum y mayoría · RN36', icono: 'scale' },
  { codigo: 'COMUNICACION', texto: 'Comunicación', nota: 'SUNEDU, AU, CU y portal · RF102', icono: 'external' },
  { codigo: 'SEGUNDA', texto: 'Segunda vuelta', nota: 'Finalistas y sorteo · RN33', icono: 'calendar' },
];
const pct = (v) => `${Number(v ?? 0).toFixed(2)} %`;
const si = (v) => v === true || v === 1;
const claveTokens = (id) => `cus15-tokens-${id}`;
const recursoVacio = { idMesa: null, causal: '', origen: 'DE_OFICIO', idPersonero: '', sustento: '', pruebas: '' };
const ahoraLocal = () => {
  const d = new Date();
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().slice(0, 16);
};

function leerTokens(id) {
  try {
    return JSON.parse(sessionStorage.getItem(claveTokens(id)) ?? '{}');
  } catch {
    return {};
  }
}
function guardarToken(id, idNulidad, token) {
  try {
    sessionStorage.setItem(claveTokens(id), JSON.stringify({ ...leerTokens(id), [idNulidad]: token }));
  } catch { /* almacenamiento no disponible */ }
}

/** Pestaña con la que conviene abrir el proceso. */
function pasoInicial(d) {
  if (!d) return 'PARCIAL';
  if (d.nulidades.some((n) => n.estado === 'PRESENTADA')) return 'RESOLUCION';
  if (d.nulidades.some((n) => n.estado === 'FUNDADA' && n.alcance === 'TOTAL' && n.comunicacionesOficio < 3)) return 'COMUNICACION';
  if (d.acciones.convocarSegundaVuelta || d.cargos.some((c) => c.empateSinDirimir) || d.proceso.tipo === 'SEGUNDA_VUELTA' || d.segundaVuelta) return 'SEGUNDA';
  if (d.acciones.registrarParcial) return 'PARCIAL';
  return d.acciones.registrarTotal || d.acciones.formalizarParticipacion ? 'TOTAL' : 'RESOLUCION';
}

function cuenta(codigo, d) {
  switch (codigo) {
    case 'PARCIAL': return d.nulidades.filter((n) => n.alcance === 'PARCIAL').length;
    case 'TOTAL': return d.nulidades.filter((n) => n.alcance === 'TOTAL').length;
    case 'RESOLUCION': return d.nulidades.filter((n) => n.estado === 'PRESENTADA').length;
    case 'COMUNICACION': return d.nulidades.filter((n) => n.estado === 'FUNDADA').length;
    case 'SEGUNDA': return d.cargos.filter((c) => ['SEGUNDA_VUELTA', 'EMPATE'].includes(c.estadoResultado)).length;
    default: return 0;
  }
}

export default function PantallaNulidades({ session, onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [paso, setPaso] = useState('PARCIAL');
  const [idMesa, setIdMesa] = useState(null);
  const [mesa, setMesa] = useState(null);
  const [idNulidad, setIdNulidad] = useState(null);
  const [nulidad, setNulidad] = useState(null);
  const [accion, setAccion] = useState(null);   // PARCIAL | TOTAL | PARTICIPACION | RESOLVER | COMUNICAR:<dest> | DIRIMIR:<cargo> | SEGUNDA
  const [confirmando, setConfirmando] = useState(false);
  const [recurso, setRecurso] = useState(recursoVacio);
  const [resolucion, setResolucion] = useState({ decision: '', fundamento: '', numeroResolucion: '', miembrosPleno: '5', votosFavor: '5', votosContra: '0', votoDirimente: false });
  const [comunicacion, setComunicacion] = useState({ documento: '', fechaEnvio: '', observacion: '' });
  const [sorteo, setSorteo] = useState({ semilla: '', numeroResolucion: '', miembrosPleno: '5', fundamento: '' });
  const [segunda, setSegunda] = useState({ fechaInicio: '', fechaFin: '' });
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
    const d = await apiRequest(`/api/nulidades/procesos/${id}`);
    setDetalle(d);
    setTokens(leerTokens(id));
    if (moverPaso) setPaso(pasoInicial(d));
    const quorum = String(d.parametros?.quorumPleno ?? 5);
    setResolucion((r) => ({ ...r, miembrosPleno: quorum, votosFavor: quorum, votosContra: '0' }));
    setSorteo((s) => ({ ...s, miembrosPleno: quorum }));
    return d;
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/nulidades/procesos');
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
        setMesa(await apiRequest(`/api/nulidades/mesas/${idMesa}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idMesa, manejarError]);

  useEffect(() => {
    if (!idNulidad) {
      setNulidad(null);
      return;
    }
    (async () => {
      try {
        setNulidad(await apiRequest(`/api/nulidades/${idNulidad}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idNulidad, detalle, manejarError]);

  function limpiarAccion() {
    setAccion(null);
    setConfirmando(false);
  }

  function irA(codigo) {
    setPaso(codigo);
    setIdMesa(null);
    limpiarAccion();
    setFeedback(null);
  }

  async function cambiarProceso(id) {
    setIdProceso(id);
    setIdMesa(null);
    setIdNulidad(null);
    setRecurso(recursoVacio);
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
      setProcesos(await apiRequest('/api/nulidades/procesos'));
      await cargarDetalle(idProceso, false);
      if (idMesa) setMesa(await apiRequest(`/api/nulidades/mesas/${idMesa}`));
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
      if (data.nulidad) setNulidad(data.nulidad);
      setFeedback({ type: 'success', text: data.mensaje });
      limpiarAccion();
      alTerminar?.(data);
      setProcesos(await apiRequest('/api/nulidades/procesos'));
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

  const cuerpoRecurso = (r) => ({
    causal: r.causal,
    origen: r.origen,
    idPersonero: r.origen === 'PERSONERO' && r.idPersonero ? Number(r.idPersonero) : null,
    sustento: r.sustento,
    pruebas: r.pruebas || null,
  });

  /** 1 ingresarNulidadParcial(id_mesa, causal). */
  const registrarParcial = () => ejecutar(`/api/nulidades/procesos/${idProceso}/parcial`, { ...cuerpoRecurso(recurso), idMesa: recurso.idMesa }, (d) => {
    setRecurso(recursoVacio);
    setIdNulidad(d.idNulidad);
    setPaso('RESOLUCION');
  });

  /** 5 ingresarNulidadTotal(id_proceso, motivo). */
  const registrarTotal = () => ejecutar(`/api/nulidades/procesos/${idProceso}/total`, cuerpoRecurso(recurso), (d) => {
    setRecurso(recursoVacio);
    setIdNulidad(d.idNulidad);
    setPaso('RESOLUCION');
  });

  /** A1 del CUS14: se formaliza la nulidad por participación insuficiente que determinó el cómputo. */
  const formalizarParticipacion = () => ejecutar(`/api/nulidades/procesos/${idProceso}/total`, {
    causal: 'PARTICIPACION_INSUFICIENTE',
    origen: 'DE_OFICIO',
    sustento: `El cómputo oficial registró una participación de ${pct(detalle.proceso.participacionPct)} (${detalle.proceso.votaron} de ${detalle.proceso.electoresHabiles} electores hábiles), que no supera el mínimo de ${pct(detalle.proceso.quorumMinimo)} (RN31).`,
  }, (d) => {
    setIdNulidad(d.idNulidad);
    setPaso('RESOLUCION');
  });

  /** 2-4 anularMesa · 6-7 anularProceso: resolución del Pleno. */
  const resolver = () => ejecutar(`/api/nulidades/${idNulidad}/resolucion`, {
    decision: resolucion.decision,
    fundamento: resolucion.fundamento,
    numeroResolucion: resolucion.numeroResolucion,
    miembrosPleno: Number(resolucion.miembrosPleno),
    votosFavor: Number(resolucion.votosFavor),
    votosContra: Number(resolucion.votosContra),
    votoDirimente: resolucion.votoDirimente,
  }, (d) => {
    if (d.tokenQr) {
      guardarToken(idProceso, d.idNulidad, d.tokenQr);
      setTokens(leerTokens(idProceso));
    }
    setResolucion((r) => ({ ...r, decision: '', fundamento: '', numeroResolucion: '', votoDirimente: false }));
  });

  /** 8 registrarComunicacion('SUNEDU, AU, CU') y publicación. */
  const comunicar = (destinatario) => ejecutar(`/api/nulidades/${idNulidad}/comunicaciones`, {
    destinatario,
    documento: comunicacion.documento || null,
    fechaEnvio: comunicacion.fechaEnvio ? `${comunicacion.fechaEnvio}:00` : null,
    observacion: comunicacion.observacion || null,
  }, () => setComunicacion({ documento: '', fechaEnvio: '', observacion: '' }));

  /** Sorteo del Pleno que dirime un empate. */
  const dirimir = (idCargo) => ejecutar(`/api/nulidades/cargos/${idCargo}/dirimencia`, {
    semilla: sorteo.semilla,
    numeroResolucion: sorteo.numeroResolucion,
    miembrosPleno: Number(sorteo.miembrosPleno),
    fundamento: sorteo.fundamento || null,
  }, () => setSorteo((s) => ({ ...s, semilla: '', numeroResolucion: '', fundamento: '' })));

  /** 10-15 convocarSegundaVuelta(id_proceso, fechas). */
  const convocarSegunda = () => ejecutar(`/api/nulidades/procesos/${idProceso}/segunda-vuelta`, {
    fechaInicio: segunda.fechaInicio ? `${segunda.fechaInicio}:00` : null,
    fechaFin: segunda.fechaFin ? `${segunda.fechaFin}:00` : null,
  }, () => setSegunda({ fechaInicio: '', fechaFin: '' }));

  async function imprimirConDocumento(id, fn) {
    try {
      const n = id === nulidad?.idNulidad ? nulidad : await apiRequest(`/api/nulidades/${id}`);
      fn(n);
    } catch (e) {
      manejarError(e);
    }
  }

  // ─── Datos derivados ─────────────────────────────────────────────────────

  const comunicacionesPorNulidad = useMemo(() => {
    const mapa = new Map();
    (detalle?.comunicaciones ?? []).forEach((c) => mapa.set(c.idNulidad, [...(mapa.get(c.idNulidad) ?? []), c]));
    return mapa;
  }, [detalle]);

  if (cargando) return <div className="panel"><p className="muted">Cargando nulidades…</p></div>;
  if (!detalle) {
    return (
      <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mx">
        {feedback && <div className={`alert ${feedback.type}`} role="status">{feedback.text}</div>}
        <div className="panel"><p className="empty-state">No hay procesos con votación concluida ni segundas vueltas.</p></div>
      </div>
    );
  }

  const { proceso, acciones, resumenMesas: rm, participacion, parametros, nulidades } = detalle;
  const estProc = ESTADO_PROCESO[proceso.estado] ?? { clase: 'creado', texto: proceso.estado };
  const quorum = parametros?.quorumPleno ?? 5;
  const pendientes = nulidades.filter((n) => n.estado === 'PRESENTADA');
  const total = nulidades.find((n) => n.alcance === 'TOTAL' && ['PRESENTADA', 'FUNDADA'].includes(n.estado));
  const anulado = proceso.estado === 'ANULADO';
  const seleccionada = nulidades.find((n) => n.idNulidad === idNulidad) ?? null;
  const fundadas = nulidades.filter((n) => n.estado === 'FUNDADA');
  const cargosSegunda = detalle.cargos.filter((c) => ['SEGUNDA_VUELTA', 'EMPATE'].includes(c.estadoResultado) || c.dirimencia);

  return (
    <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mx">
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))}>
            {procesos.map((p) => (
              <option key={p.id} value={p.id}>
                {p.nombre} · {p.tipo === 'SEGUNDA_VUELTA' ? '2.ª vuelta · ' : ''}{p.estado}{p.estadoComputo ? ` · ${ETAPA[p.estadoComputo]}` : ''}{p.pendientes ? ` · ${p.pendientes} recurso(s)` : ''}
              </option>
            ))}
          </select>
        </label>
        <div className={`in-plazo ${anulado ? 'closed' : 'open'}`}>
          <MenuIcon name="scale" size={18} />
          <div>
            <strong>{anulado ? 'Elección anulada' : `${estProc.texto}${proceso.estadoComputo ? ` · ${ETAPA[proceso.estadoComputo]}` : ''}`}</strong>
            <span>RF94 los recursos pendientes detienen el cómputo y la proclamación · RN36 el Pleno resuelve con quórum de {quorum} · RN33 segunda vuelta en {parametros.plazoSegundaVuelta} días</span>
          </div>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      <div className="pd-tabs cq-tabs mx-pasos cp-pasos nl-pasos" role="tablist" aria-label="Gestión de nulidades y segunda vuelta">
        {PASOS.map((p) => {
          const n = cuenta(p.codigo, detalle);
          const alerta = (p.codigo === 'RESOLUCION' && n > 0) || (p.codigo === 'SEGUNDA' && detalle.cargos.some((c) => c.empateSinDirimir));
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
        <div className="cq-kpi" style={{ '--cq-color': pendientes.length ? '#d97706' : '#059669' }}>
          <span>Recursos pendientes <em>RF94</em></span>
          <strong>{pendientes.length}<small> / {nulidades.length}</small></strong>
          <small>{fundadas.length} fundado(s) · {nulidades.filter((n) => ['INFUNDADA', 'IMPROCEDENTE'].includes(n.estado)).length} desestimado(s)</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': rm.anuladas ? '#e11d48' : '#2563eb' }}>
          <span>Mesas anuladas <em>RF100</em></span>
          <strong>{rm.anuladas}<small> / {rm.total}</small></strong>
          <small>{rm.cerradas} cerrada(s) · {rm.noInstaladas} no instalada(s)</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': participacion && !si(participacion.alcanzaQuorum) ? '#e11d48' : '#059669' }}>
          <span>Participación <em>RN31</em></span>
          <strong>{pct(participacion?.participacionPct)}</strong>
          <i className="cq-barra cp-barra" style={{ '--cp-umbral': `${proceso.quorumMinimo}%` }}>
            <b style={{ width: `${Math.min(100, Number(participacion?.participacionPct ?? 0))}%` }} />
          </i>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': anulado ? '#e11d48' : detalle.segundaVuelta ? '#2563eb' : '#059669' }}>
          <span>Elección <em>{proceso.tipo === 'SEGUNDA_VUELTA' ? 'Segunda vuelta' : 'Primera vuelta'}</em></span>
          <strong className="cp-etapa">{anulado ? 'Anulada' : total ? 'Nulidad en trámite' : detalle.segundaVuelta ? 'Segunda vuelta' : 'Válida'}</strong>
          <small><span className={`cv-estado ${estProc.clase}`}>{estProc.texto}</span></small>
        </div>
      </section>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}
      {detalle.soloLectura && <div className="alert success" role="note">Vista de consulta: las nulidades y la segunda vuelta las declara el Pleno del CEUNP.</div>}
      {detalle.avisos.length > 0 && (
        <div className="mx-mensaje aviso nl-avisos" role="note">
          <MenuIcon name="alert" size={18} />
          <div>
            <h4>Pendientes del proceso</h4>
            <ul className="cp-lista">{detalle.avisos.map((a) => <li key={a}>{a}</li>)}</ul>
          </div>
        </div>
      )}
      {anulado && proceso.motivoAnulacion && (
        <div className="mx-mensaje peligro" role="note">
          <MenuIcon name="close" size={18} />
          <div><h4>Elección anulada</h4><p>{proceso.motivoAnulacion}</p></div>
        </div>
      )}

      {/* ── 1-4 Nulidad parcial (RF100) ── */}
      {paso === 'PARCIAL' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Nulidad de la votación de una mesa (Art. 64)</h3>
                <p className="muted">Se plantea con la votación concluida y antes del cómputo general (RN26), de oficio o a pedido de un personero acreditado. Si el Pleno la declara fundada, la mesa y sus actas quedan anuladas y sus votos se excluyen del cómputo. La mesa que no se instaló se evalúa en la instalación (RF60).</p>
              </div>
            </div>
            {!acciones.registrarParcial && acciones.motivoNoParcial && (
              <div className="mx-mensaje info" role="note"><MenuIcon name="info" size={18} /><div><p>{acciones.motivoNoParcial}</p></div></div>
            )}
            <div className="table-wrap">
              <table>
                <thead><tr><th>Mesa</th><th>Sufragio</th><th>Situación para el cómputo</th><th>Recursos</th><th /></tr></thead>
                <tbody>
                  {detalle.mesas.map((m) => {
                    const puede = acciones.registrarParcial && m.estado === 'CERRADA' && !m.recursosPendientes;
                    return (
                      <tr key={m.idMesa} className={m.idMesa === idMesa ? 'ig-fila on' : 'ig-fila'}>
                        <td><strong>Mesa {m.numeroMesa}</strong><small className="pd-sub">{m.ubicacion}</small></td>
                        <td>{m.estado === 'CERRADA' ? 'Cerrado' : m.estado.replaceAll('_', ' ').toLowerCase()}<small className="pd-sub">{m.totalVotantes ?? 0} de {m.totalElectores} votaron</small></td>
                        <td>
                          <span className={`cv-estado ${CLASE_SITUACION[m.situacion] ?? 'creado'}`}>{SITUACION_MESA[m.situacion] ?? m.situacion}</span>
                          {m.resolucionNulidad && <small className="pd-sub">Nulidad · {m.resolucionNulidad}</small>}
                          {!m.resolucionNulidad && m.calificacion && <small className="pd-sub">{m.calificacion === 'NULIDAD' ? 'Nulidad' : 'Válida'}{m.resolucionCalificacion ? ` · ${m.resolucionCalificacion}` : ''}</small>}
                          {m.evaluacionNulidad && <small className="pd-sub">RF60: {m.evaluacionNulidad.toLowerCase().replaceAll('_', ' ')}</small>}
                        </td>
                        <td>{m.recursosPendientes ? <span className="cv-estado inscripcion">{m.recursosPendientes} pendiente(s)</span> : <span className="muted">—</span>}</td>
                        <td>
                          <div className="nl-acciones-fila">
                            <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => { setIdMesa(m.idMesa === idMesa ? null : m.idMesa); limpiarAccion(); }}>
                              <MenuIcon name="eye" size={13} /> {m.idMesa === idMesa ? 'Cerrar' : 'Ver'}
                            </button>
                            {puede && (
                              <button type="button" className="cv-btn cv-btn-ghost cq-mini im-btn-peligro" disabled={saving}
                                onClick={() => { setIdMesa(m.idMesa); setRecurso({ ...recursoVacio, idMesa: m.idMesa }); setAccion('PARCIAL'); setConfirmando(false); }}>
                                <MenuIcon name="scale" size={13} /> Plantear nulidad
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                  {detalle.mesas.length === 0 && <tr><td colSpan={5} className="muted">El proceso no tiene mesas.</td></tr>}
                </tbody>
              </table>
            </div>
          </div>

          {mesa && (
            <div className="panel mx-ficha ig-expediente">
              <div className="mx-ficha-top">
                <div>
                  <h3>Mesa {mesa.mesa.numeroMesa}</h3>
                  <p>{mesa.mesa.ubicacion}</p>
                </div>
                <div className="cs-acciones-head">
                  <span className={`cv-estado ${CLASE_SITUACION[mesa.mesa.situacion] ?? 'creado'}`}>{SITUACION_MESA[mesa.mesa.situacion] ?? mesa.mesa.situacion}</span>
                  <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => { setIdMesa(null); limpiarAccion(); }}><MenuIcon name="close" size={13} /> Cerrar</button>
                </div>
              </div>
              <dl className="mx-datos">
                <div><dt>Votaron</dt><dd>{mesa.mesa.totalVotantes ?? 0} de {mesa.mesa.totalElectores}</dd></div>
                <div><dt>Escrutinio</dt><dd>{mesa.mesa.estadoEscrutinio ? mesa.mesa.estadoEscrutinio.replaceAll('_', ' ').toLowerCase() : '—'}</dd></div>
                <div><dt>Actas entregadas</dt><dd>{mesa.mesa.fechaEntrega ? fecha(mesa.mesa.fechaEntrega) : '—'}</dd></div>
                <div><dt>Recursos</dt><dd>{mesa.recursos.length}</dd></div>
              </dl>
              <h4 className="cp-sub">{mesa.mesa.estado === 'ANULADA' ? '4 mostrarMesaExcluida(): votos excluidos del cómputo' : 'Votos de la mesa (se excluirían si se declara la nulidad)'}</h4>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Cargo</th><th>Opción</th><th className="n">Votos</th></tr></thead>
                  <tbody>
                    {mesa.conteo.map((c) => (
                      <tr key={`${c.idCargo}-${c.opcion}-${c.idLista ?? ''}`} className={mesa.mesa.estado === 'ANULADA' ? 'nl-excluido' : ''}>
                        <td>{c.cargo}</td><td>{c.lista}</td><td className="n">{c.votos}</td>
                      </tr>
                    ))}
                    {mesa.conteo.length === 0 && <tr><td colSpan={3} className="muted">Sin acta de escrutinio.</td></tr>}
                  </tbody>
                </table>
              </div>
              {mesa.recursos.length > 0 && (
                <>
                  <h4 className="cp-sub">Recursos de nulidad de la mesa</h4>
                  <ul className="nl-recursos">
                    {mesa.recursos.map((r) => (
                      <li key={r.idNulidad}>
                        <span className={`cv-estado ${ESTADO_RECURSO[r.estado]?.clase}`}>{ESTADO_RECURSO[r.estado]?.texto}</span>
                        <span>N.º {r.idNulidad} · {CAUSAL[r.causal] ?? r.causal}<small>{r.origen === 'PERSONERO' ? r.personero : 'De oficio'} · {fecha(r.fechaPresentacion)}{r.numeroResolucion ? ` · ${r.numeroResolucion}` : ''}</small></span>
                        <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => { setIdNulidad(r.idNulidad); irA('RESOLUCION'); }}>
                          <MenuIcon name="file" size={13} /> Expediente
                        </button>
                      </li>
                    ))}
                  </ul>
                </>
              )}
              {accion === 'PARCIAL' && recurso.idMesa === mesa.mesa.idMesa && (
                <FormRecurso
                  alcance="PARCIAL" mesa={mesa.mesa} recurso={recurso} setRecurso={setRecurso} personeros={detalle.personeros}
                  saving={saving} confirmando={confirmando} setConfirmando={setConfirmando}
                  onCancelar={limpiarAccion} onConfirmar={registrarParcial}
                />
              )}
            </div>
          )}

          <TablaRecursos titulo="Recursos de nulidad parcial" filas={nulidades.filter((n) => n.alcance === 'PARCIAL')}
            onAbrir={(id) => { setIdNulidad(id); irA('RESOLUCION'); }} />
        </>
      )}

      {/* ── 5-7 Nulidad total (RF101) ── */}
      {paso === 'TOTAL' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Nulidad total de la elección (Art. 65)</h3>
                <p className="muted">Procede por fraude, cohecho, soborno, intimidación o violencia que alteren el resultado, o cuando la participación no supera el mínimo (RN31). Se plantea con la votación concluida y antes de la proclamación. Si el Pleno la declara fundada, el proceso, sus mesas y sus actas quedan anulados (y su segunda vuelta, si estaba convocada) y se comunica a SUNEDU, la Asamblea y el Consejo Universitario.</p>
              </div>
            </div>
            <dl className="mx-datos cp-meta">
              <div><dt>Estado del proceso</dt><dd><span className={`cv-estado ${estProc.clase}`}>{estProc.texto}</span></dd></div>
              <div><dt>Cómputo</dt><dd>{proceso.estadoComputo ? `${ETAPA[proceso.estadoComputo]}${proceso.fechaComputo ? ` · ${fecha(proceso.fechaComputo)}` : ''}` : 'Sin cómputo'}</dd></div>
              <div><dt>Participación</dt><dd>{pct(participacion?.participacionPct)} · mínimo {pct(proceso.quorumMinimo)}</dd></div>
              <div><dt>Resultado</dt><dd>{proceso.resultado === 'NULIDAD_TOTAL' ? 'Nulidad total (A1)' : proceso.resultado ?? '—'}</dd></div>
            </dl>

            {acciones.formalizarParticipacion && (
              <div className="mx-mensaje peligro" role="note">
                <MenuIcon name="alert" size={18} />
                <div>
                  <h4>A1 · El cómputo determinó la nulidad por participación insuficiente</h4>
                  <p>Votó el {pct(proceso.participacionPct)} de los electores hábiles, sin superar el {pct(proceso.quorumMinimo)} (RN31). Registre el recurso de oficio para que el Pleno emita la resolución de nulidad y se comunique (RN34, RF102).</p>
                  {accion !== 'PARTICIPACION' ? (
                    <div className="cv-actions cp-izq">
                      <button type="button" className="cv-btn cv-btn-primary im-btn-peligro" disabled={saving} onClick={() => setAccion('PARTICIPACION')}>
                        <MenuIcon name="scale" size={15} /> Formalizar nulidad (A1)
                      </button>
                    </div>
                  ) : (
                    <div className="cq-confirmar-emision" role="alert">
                      <div>
                        <strong>¿Registrar de oficio la nulidad por participación insuficiente?</strong>
                        <span>Luego el Pleno la declara fundada con su resolución y se comunica a SUNEDU, AU y CU.</span>
                      </div>
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Volver</button>
                        <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={formalizarParticipacion}>
                          <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar'}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}

            {!acciones.registrarTotal && acciones.motivoNoTotal && !acciones.formalizarParticipacion && (
              <div className="mx-mensaje info" role="note"><MenuIcon name="info" size={18} /><div><p>{acciones.motivoNoTotal}</p></div></div>
            )}
            {acciones.registrarTotal && (accion !== 'TOTAL' ? (
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-primary im-btn-peligro" disabled={saving}
                  onClick={() => { setRecurso(recursoVacio); setAccion('TOTAL'); setConfirmando(false); }}>
                  <MenuIcon name="scale" size={15} /> Plantear nulidad total
                </button>
              </div>
            ) : (
              <FormRecurso
                alcance="TOTAL" proceso={proceso} recurso={recurso} setRecurso={setRecurso} personeros={detalle.personeros}
                saving={saving} confirmando={confirmando} setConfirmando={setConfirmando}
                onCancelar={limpiarAccion} onConfirmar={registrarTotal}
              />
            ))}
          </div>

          <TablaRecursos titulo="Recursos de nulidad total" filas={nulidades.filter((n) => n.alcance === 'TOTAL')}
            onAbrir={(id) => { setIdNulidad(id); irA('RESOLUCION'); }} />
        </>
      )}

      {/* ── 2-4 / 6-7 Resolución del Pleno (RN36) ── */}
      {paso === 'RESOLUCION' && (
        <>
          <TablaRecursos titulo="Recursos de nulidad del proceso" filas={nulidades} activo={idNulidad}
            nota={`El Pleno resuelve cada recurso con quórum de ${quorum} de sus 9 miembros y mayoría simple; en empate decide el voto dirimente del Presidente (RN36). La decisión es inapelable.`}
            onAbrir={(id) => { setIdNulidad(id === idNulidad ? null : id); limpiarAccion(); }} />
          {seleccionada && (
            <Expediente
              n={seleccionada} documento={nulidad?.idNulidad === seleccionada.idNulidad ? nulidad : null} proceso={proceso}
              acciones={acciones} quorum={quorum} token={tokens[seleccionada.idNulidad]}
              resolucion={resolucion} setResolucion={setResolucion} accion={accion} setAccion={setAccion}
              confirmando={confirmando} setConfirmando={setConfirmando} saving={saving}
              onResolver={resolver} onCancelar={limpiarAccion} onCerrar={() => { setIdNulidad(null); limpiarAccion(); }}
              onComunicar={() => irA('COMUNICACION')}
            />
          )}
        </>
      )}

      {/* ── 8-9 Comunicación y publicación (RF102) ── */}
      {paso === 'COMUNICACION' && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Comunicación y publicación de las nulidades declaradas</h3>
              <p className="muted">La resolución que declara una nulidad se comunica por oficio a SUNEDU, la Asamblea Universitaria y el Consejo Universitario, y se publica en el portal electoral y, si corresponde, en el diario oficial El Peruano (RF102, Art. 66). La publicación en el portal la muestra en la consulta pública.</p>
            </div>
          </div>
          {fundadas.length === 0 && <p className="empty-state">No hay nulidades declaradas fundadas en este proceso.</p>}
          {fundadas.map((n) => {
            const enviadas = comunicacionesPorNulidad.get(n.idNulidad) ?? [];
            const abierta = n.idNulidad === idNulidad;
            return (
              <div key={n.idNulidad} className={`ig-form nl-comunicar${abierta ? ' on' : ''}`}>
                <div className="cp-cargo-head">
                  <h4>Resolución {n.numeroResolucion} · {n.alcance === 'PARCIAL' ? `nulidad de la mesa ${n.numeroMesa}` : 'nulidad total'}<small className="pd-sub">{CAUSAL[n.causal] ?? n.causal} · {fecha(n.fechaResolucion)}</small></h4>
                  <div className="cs-acciones-head">
                    <span className={`cv-estado ${n.comunicacionesOficio >= 3 ? 'votacion' : 'inscripcion'}`}>{n.comunicacionesOficio} de 3 oficios</span>
                    <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirConDocumento(n.idNulidad, (x) => imprimirOficios(x))}>
                      <MenuIcon name="file" size={13} /> Imprimir oficios
                    </button>
                    <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirConDocumento(n.idNulidad, (x) => imprimirResolucion(x, tokens[n.idNulidad]))}>
                      <MenuIcon name="qr" size={13} /> Resolución
                    </button>
                  </div>
                </div>
                <div className="nl-destinos">
                  {DESTINOS.map((dst) => {
                    const c = enviadas.find((x) => x.destinatario === dst);
                    const formAbierto = abierta && accion === `COMUNICAR:${dst}`;
                    return (
                      <div key={dst} className={`nl-destino${c ? ' hecho' : ''}${DESTINOS_OFICIO.includes(dst) ? ' oficio' : ''}`}>
                        <div className="nl-destino-top">
                          <span className="cv-check-icon"><MenuIcon name={c ? 'check' : dst === 'PORTAL' || dst === 'EL_PERUANO' ? 'external' : 'file'} size={12} /></span>
                          <strong>{DESTINATARIO[dst]}</strong>
                        </div>
                        {c ? (
                          <small>{c.documento ?? '—'} · {fecha(c.fechaEnvio)}{c.observacion ? <><br />{c.observacion}</> : null}</small>
                        ) : acciones.comunicar && !formAbierto ? (
                          <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving}
                            onClick={() => { setIdNulidad(n.idNulidad); setAccion(`COMUNICAR:${dst}`); setConfirmando(false); setComunicacion({ documento: '', fechaEnvio: ahoraLocal(), observacion: '' }); }}>
                            <MenuIcon name={dst === 'PORTAL' ? 'external' : 'plus'} size={13} /> {dst === 'PORTAL' ? 'Publicar' : 'Registrar envío'}
                          </button>
                        ) : !c && !acciones.comunicar ? <small className="muted">Pendiente</small> : null}
                      </div>
                    );
                  })}
                </div>
                {abierta && accion?.startsWith('COMUNICAR:') && (() => {
                  const dst = accion.split(':')[1];
                  const portal = dst === 'PORTAL';
                  return (
                    <form className="nl-form-com" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
                      <div className="ig-grid">
                        <label className="cv-field">
                          <span className="cv-label">{portal ? 'Sección o enlace del portal' : dst === 'EL_PERUANO' ? 'Edición o separata' : 'N.º de oficio'}</span>
                          <input maxLength={80} required={!portal} value={comunicacion.documento} disabled={saving}
                            placeholder={portal ? 'Portal electoral' : 'Ej.: Oficio N.º 015-2026-CEUNP'}
                            onChange={(e) => setComunicacion((c) => ({ ...c, documento: e.target.value }))} />
                        </label>
                        <label className="cv-field">
                          <span className="cv-label">{portal ? 'Fecha de publicación' : 'Fecha de envío'}</span>
                          <input type="datetime-local" value={comunicacion.fechaEnvio} disabled={saving} onChange={(e) => setComunicacion((c) => ({ ...c, fechaEnvio: e.target.value }))} />
                        </label>
                        <label className="cv-field">
                          <span className="cv-label">Observación</span>
                          <input maxLength={500} value={comunicacion.observacion} disabled={saving} onChange={(e) => setComunicacion((c) => ({ ...c, observacion: e.target.value }))} />
                        </label>
                      </div>
                      {!confirmando ? (
                        <div className="cv-actions">
                          <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Cancelar</button>
                          <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || (!portal && !comunicacion.documento.trim())}>
                            <MenuIcon name={portal ? 'external' : 'check'} size={15} /> {portal ? 'Publicar en el portal' : 'Registrar comunicación'}
                          </button>
                        </div>
                      ) : (
                        <div className="cq-confirmar-emision" role="alert">
                          <div>
                            <strong>{portal ? `¿Publicar la Resolución ${n.numeroResolucion} en el portal electoral?` : `¿Registrar el envío a ${DESTINATARIO[dst]}?`}</strong>
                            <span>{portal ? 'La resolución será visible en la consulta pública, sin datos del voto.' : 'Cada destinatario se registra una sola vez.'}</span>
                          </div>
                          <div className="cv-actions">
                            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                            <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={() => comunicar(dst)}>
                              <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar'}
                            </button>
                          </div>
                        </div>
                      )}
                    </form>
                  );
                })()}
              </div>
            );
          })}
        </div>
      )}

      {/* ── 10-15 Segunda vuelta (RN33) y dirimencia de empates ── */}
      {paso === 'SEGUNDA' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>{proceso.tipo === 'SEGUNDA_VUELTA' ? 'Segunda vuelta en curso' : 'Segunda vuelta entre las dos listas más votadas'}</h3>
                <p className="muted">{proceso.tipo === 'SEGUNDA_VUELTA'
                  ? `Proceso convocado desde «${proceso.procesoPadre}». Gana la lista con la mitad más uno de los votos válidos; si las dos empatan, el Pleno lo dirime por sorteo antes de proclamar (RF97).`
                  : `Si ninguna lista supera el mínimo, pasan las dos más votadas de cada cargo (RN33). Si varias empatan por un cupo, el Pleno lo dirime por sorteo verificable. La segunda vuelta se convoca dentro de los ${parametros.plazoSegundaVuelta} días siguientes al cómputo${parametros.limiteSegundaVuelta ? ` (hasta el ${fecha(parametros.limiteSegundaVuelta)})` : ''}.`}</p>
              </div>
            </div>
            {cargosSegunda.length === 0 && (
              <p className="empty-state">{proceso.estadoComputo && proceso.estadoComputo !== 'SESION_INSTALADA'
                ? 'Ningún cargo de este proceso va a segunda vuelta ni tiene empates.'
                : 'El cómputo del proceso aún no se realiza: la segunda vuelta se determina en el cómputo oficial (CUS14).'}</p>
            )}
            {cargosSegunda.map((c) => (
              <CargoSegunda key={c.idCargo} c={c} proceso={proceso} acciones={acciones} quorum={quorum}
                sorteo={sorteo} setSorteo={setSorteo} accion={accion} setAccion={setAccion}
                confirmando={confirmando} setConfirmando={setConfirmando} saving={saving}
                onDirimir={() => dirimir(c.idCargo)} onCancelar={limpiarAccion} />
            ))}

            {proceso.tipo === 'PRIMERA_VUELTA' && !detalle.segundaVuelta && cargosSegunda.some((c) => c.estadoResultado === 'SEGUNDA_VUELTA') && (
              <div className="ig-form cp-segunda">
                <h4>10 convocarSegundaVuelta(id_proceso, fechas)</h4>
                {!acciones.convocarSegundaVuelta ? (
                  <p className="ig-texto">{acciones.motivoNoSegunda ?? (anulado ? 'La elección está anulada: no se convoca segunda vuelta.' : 'La segunda vuelta la convoca el CEUNP.')}</p>
                ) : (
                  <>
                    <div className="ig-grid">
                      <label className="cv-field">
                        <span className="cv-label">Inicio de la votación</span>
                        <input type="datetime-local" value={segunda.fechaInicio} disabled={saving} onChange={(e) => setSegunda((s) => ({ ...s, fechaInicio: e.target.value }))} />
                      </label>
                      <label className="cv-field">
                        <span className="cv-label">Fin de la votación</span>
                        <input type="datetime-local" value={segunda.fechaFin} disabled={saving} onChange={(e) => setSegunda((s) => ({ ...s, fechaFin: e.target.value }))} />
                        {segunda.fechaInicio && segunda.fechaFin && segunda.fechaFin <= segunda.fechaInicio && <small className="cv-error">El fin debe ser posterior al inicio.</small>}
                      </label>
                    </div>
                    {accion !== 'SEGUNDA' ? (
                      <div className="cv-actions cp-izq">
                        <button type="button" className="cv-btn cv-btn-primary" disabled={saving || !segunda.fechaInicio || !segunda.fechaFin || segunda.fechaFin <= segunda.fechaInicio} onClick={() => setAccion('SEGUNDA')}>
                          <MenuIcon name="calendar" size={15} /> Convocar segunda vuelta
                        </button>
                      </div>
                    ) : (
                      <div className="cq-confirmar-emision" role="alert">
                        <div>
                          <strong>¿Convocar la segunda vuelta del {fecha(segunda.fechaInicio)} al {fecha(segunda.fechaFin)}?</strong>
                          <span>11 crearSegundaVuelta: se crea un proceso nuevo con las dos listas más votadas de cada cargo, sus candidatos y el mismo padrón.</span>
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
          </div>

          {detalle.segundasVueltas.length > 0 && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>15 mostrarSegundaVuelta()</h3>
                  <p className="muted">Procesos de segunda vuelta convocados desde esta elección. Su preparación (mesas, miembros y cédula) continúa en Convocatoria y cronograma; el cómputo, en Cómputo y proclamación.</p>
                </div>
              </div>
              {detalle.segundasVueltas.map((sv) => (
                <div key={sv.id} className={`ig-form nl-sv${sv.estado === 'ANULADO' ? ' anulada' : ''}`}>
                  <div className="cp-cargo-head">
                    <h4>Proceso N.º {sv.id} · {sv.nombre}<small className="pd-sub">Votación del {fecha(sv.fechaInicio)} al {fecha(sv.fechaFin)}</small></h4>
                    <div className="cs-acciones-head">
                      <span className={`cv-estado ${ESTADO_PROCESO[sv.estado]?.clase ?? 'creado'}`}>{ESTADO_PROCESO[sv.estado]?.texto ?? sv.estado}</span>
                      <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirConvocatoriaSegunda(proceso, sv)}>
                        <MenuIcon name="file" size={13} /> Imprimir convocatoria
                      </button>
                      <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => cambiarProceso(sv.id)}>
                        <MenuIcon name="eye" size={13} /> Abrir
                      </button>
                    </div>
                  </div>
                  <dl className="mx-datos">
                    <div><dt>Cargos</dt><dd>{sv.cargos}</dd></div>
                    <div><dt>Listas finalistas</dt><dd>{sv.listas}</dd></div>
                    <div><dt>Padrón copiado</dt><dd>{sv.padron} electores</dd></div>
                    <div><dt>Mesas</dt><dd>{sv.mesas}{sv.estadoComputo ? ` · ${ETAPA[sv.estadoComputo]}` : ''}</dd></div>
                  </dl>
                  {sv.motivoAnulacion && <p className="ig-texto nl-motivo">{sv.motivoAnulacion}</p>}
                  <div className="table-wrap">
                    <table>
                      <thead><tr><th>Cargo</th><th>Lista finalista</th><th className="n">Candidatos</th></tr></thead>
                      <tbody>
                        {sv.listasFinalistas.map((l) => <tr key={`${l.cargo}-${l.lista}`}><td>{l.cargo}</td><td>{l.ordenCedula != null ? `${l.ordenCedula}. ` : ''}{l.lista}</td><td className="n">{l.candidatos}</td></tr>)}
                      </tbody>
                    </table>
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}

/** 1 / 5 Formulario del recurso de nulidad (parcial de una mesa o total de la elección). */
function FormRecurso({ alcance, mesa, recurso, setRecurso, personeros, saving, confirmando, setConfirmando, onCancelar, onConfirmar }) {
  const parcial = alcance === 'PARCIAL';
  const causales = parcial ? CAUSALES_PARCIAL : CAUSALES_TOTAL;
  const habilitados = personeros.filter((p) => !parcial || p.tipo !== 'MESA' || p.idMesa === mesa?.idMesa);
  const listo = recurso.causal && recurso.sustento.trim().length >= 10 && (recurso.origen === 'DE_OFICIO' || recurso.idPersonero);
  const personero = habilitados.find((p) => String(p.idPersonero) === String(recurso.idPersonero));
  const set = (campo) => (e) => { setRecurso((r) => ({ ...r, [campo]: e.target.value })); setConfirmando(false); };

  return (
    <form className="ig-form nl-recurso" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
      <h4>{parcial ? `1 ingresarNulidadParcial · mesa ${mesa.numeroMesa}` : '5 ingresarNulidadTotal · toda la elección'}</h4>
      <div className="cv-field">
        <span className="cv-label">Causal ({parcial ? 'Art. 64' : 'Art. 65'})</span>
        <div className="cq-chips" role="group" aria-label="Causal">
          {causales.map((c) => (
            <button key={c} type="button" className={`cq-chip${recurso.causal === c ? ' on' : ''}`} disabled={saving}
              onClick={() => { setRecurso((r) => ({ ...r, causal: c })); setConfirmando(false); }}>
              {CAUSAL[c]}
            </button>
          ))}
        </div>
      </div>
      <div className="ig-grid">
        <div className="cv-field">
          <span className="cv-label">Origen del recurso</span>
          <div className="im-estados cq-chips" role="group" aria-label="Origen">
            {[['DE_OFICIO', 'De oficio (CEUNP)'], ['PERSONERO', 'A pedido de personero']].map(([v, t]) => (
              <button key={v} type="button" className={`cq-chip${recurso.origen === v ? ' on' : ''}`} disabled={saving}
                onClick={() => { setRecurso((r) => ({ ...r, origen: v, idPersonero: '' })); setConfirmando(false); }}>{t}</button>
            ))}
          </div>
        </div>
        {recurso.origen === 'PERSONERO' && (
          <label className="cv-field cp-ancho2">
            <span className="cv-label">Personero acreditado</span>
            <select required value={recurso.idPersonero} disabled={saving} onChange={set('idPersonero')}>
              <option value="">Seleccione…</option>
              {habilitados.map((p) => (
                <option key={p.idPersonero} value={p.idPersonero}>{p.nombre} · {p.lista} · {TIPO_PERSONERO[p.tipo] ?? p.tipo}{p.numeroMesa ? ` (mesa ${p.numeroMesa})` : ''}</option>
              ))}
            </select>
            {habilitados.length === 0 && <small className="cv-error">No hay personeros acreditados que puedan pedirla{parcial ? ' (el personero de mesa solo pide la de su mesa)' : ''}.</small>}
          </label>
        )}
        <label className="cv-field cp-ancho3">
          <span className="cv-label">Sustento del recurso</span>
          <textarea rows={3} minLength={10} maxLength={1000} required value={recurso.sustento} disabled={saving} onChange={set('sustento')}
            placeholder={parcial ? 'Ej.: la mesa se instaló sin el quórum de sus miembros y fuera del local designado.' : 'Ej.: se comprobó la entrega de dádivas a electores en varios locales de votación.'} />
          <small className="muted">{recurso.sustento.trim().length} / 1000 · mínimo 10 caracteres</small>
        </label>
        <label className="cv-field cp-ancho3">
          <span className="cv-label">Pruebas ofrecidas (opcional)</span>
          <input maxLength={500} value={recurso.pruebas} disabled={saving} onChange={set('pruebas')} placeholder="Ej.: acta de incidencias, fotografías, declaración de testigos" />
        </label>
      </div>
      {!confirmando ? (
        <div className="cv-actions">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
          <button type="submit" className="cv-btn cv-btn-primary im-btn-peligro" disabled={saving || !listo}>
            <MenuIcon name="scale" size={15} /> Registrar recurso
          </button>
        </div>
      ) : (
        <div className="cq-confirmar-emision" role="alert">
          <div>
            <strong>{parcial ? `¿Registrar el recurso de nulidad de la mesa ${mesa.numeroMesa}?` : '¿Registrar el recurso de nulidad total de la elección?'}</strong>
            <span>
              {CAUSAL[recurso.causal]} · {recurso.origen === 'PERSONERO' ? `pedido por ${personero?.nombre ?? 'el personero'}` : 'de oficio'}.{' '}
              {parcial ? 'El cómputo general queda en espera hasta que el Pleno lo resuelva (RF94).' : 'No se podrá proclamar ni convocar la segunda vuelta hasta que el Pleno lo resuelva (RF94).'}
            </span>
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

function TablaRecursos({ titulo, nota, filas, activo, onAbrir }) {
  return (
    <div className="panel cv-form">
      <div className="cv-section-head">
        <div>
          <h3>{titulo}</h3>
          {nota && <p className="muted">{nota}</p>}
        </div>
      </div>
      <div className="table-wrap">
        <table>
          <thead><tr><th>Recurso</th><th>Objeto</th><th>Causal</th><th>Origen</th><th>Estado</th><th /></tr></thead>
          <tbody>
            {filas.map((n) => (
              <tr key={n.idNulidad} className={n.idNulidad === activo ? 'ig-fila on' : 'ig-fila'}>
                <td><strong>N.º {n.idNulidad}</strong><small className="pd-sub">{fecha(n.fechaPresentacion)} · {n.etapa === 'ANTES_COMPUTO' ? 'antes del cómputo' : 'después del cómputo'}</small></td>
                <td>{n.alcance === 'PARCIAL' ? <>Mesa {n.numeroMesa}<small className="pd-sub">{n.ubicacion}</small></> : 'Toda la elección'}</td>
                <td>{CAUSAL[n.causal] ?? n.causal}</td>
                <td>{n.origen === 'PERSONERO' ? <>{n.personero}<small className="pd-sub">{n.listaPersonero} · {TIPO_PERSONERO[n.tipoPersonero] ?? n.tipoPersonero}</small></> : 'De oficio'}</td>
                <td>
                  <span className={`cv-estado ${ESTADO_RECURSO[n.estado]?.clase}`}>{ESTADO_RECURSO[n.estado]?.texto ?? n.estado}</span>
                  {n.numeroResolucion && <small className="pd-sub">{n.numeroResolucion}</small>}
                </td>
                <td>
                  <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => onAbrir(n.idNulidad)}>
                    <MenuIcon name={n.estado === 'PRESENTADA' ? 'scale' : 'eye'} size={13} /> {n.idNulidad === activo ? 'Cerrar' : n.estado === 'PRESENTADA' ? 'Resolver' : 'Ver'}
                  </button>
                </td>
              </tr>
            ))}
            {filas.length === 0 && <tr><td colSpan={6} className="muted">No hay recursos registrados.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/** Expediente del recurso y resolución del Pleno (2 anularMesa · 6 anularProceso · 9 mostrarResolucionNulidad). */
function Expediente({
  n, documento, proceso, acciones, quorum, token, resolucion, setResolucion, accion, setAccion, confirmando, setConfirmando,
  saving, onResolver, onCancelar, onCerrar, onComunicar,
}) {
  const parcial = n.alcance === 'PARCIAL';
  const participacion = n.causal === 'PARTICIPACION_INSUFICIENTE';
  const sinMateria = !participacion && (proceso.estado === 'ANULADO' || (parcial && n.estadoMesa === 'ANULADA'));
  const opciones = participacion ? ['FUNDADA'] : sinMateria ? ['IMPROCEDENTE'] : ['FUNDADA', 'INFUNDADA', 'IMPROCEDENTE'];
  const miembros = Number(resolucion.miembrosPleno);
  const favor = Number(resolucion.votosFavor);
  const contra = Number(resolucion.votosContra);
  const empate = favor === contra && favor > 0;
  const errorVotos = miembros < quorum ? `Sin quórum: se requieren ${quorum} miembros (RN36).`
    : favor + contra > miembros ? 'Los votos superan a los miembros presentes.'
    : favor < contra ? 'La decisión no alcanza mayoría simple.'
    : empate && !resolucion.votoDirimente ? 'Empate: se requiere el voto dirimente del Presidente.'
    : favor === 0 ? 'Indique los votos a favor de la decisión.' : null;
  const listo = resolucion.decision && opciones.includes(resolucion.decision) && resolucion.fundamento.trim().length >= 10
    && resolucion.numeroResolucion.trim() && !errorVotos;
  const resolviendo = accion === 'RESOLVER';
  const set = (campo) => (e) => { setResolucion((r) => ({ ...r, [campo]: e.target.value })); setConfirmando(false); };
  const doc = documento?.documento;

  return (
    <div className="panel mx-ficha ig-expediente">
      <div className="mx-ficha-top">
        <div>
          <h3>Recurso de nulidad N.º {n.idNulidad}</h3>
          <p>{parcial ? `Nulidad parcial · mesa ${n.numeroMesa} (${n.ubicacion})` : 'Nulidad total de la elección'} · {CAUSAL[n.causal] ?? n.causal}</p>
        </div>
        <div className="cs-acciones-head">
          <span className={`cv-estado ${ESTADO_RECURSO[n.estado]?.clase}`}>{ESTADO_RECURSO[n.estado]?.texto}</span>
          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirRecurso({ ...n, proceso: proceso.nombre })}>
            <MenuIcon name="file" size={13} /> Cargo del recurso
          </button>
          {n.estado !== 'PRESENTADA' && (
            <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => documento && imprimirResolucion(documento, token)} disabled={!doc}>
              <MenuIcon name="qr" size={13} /> Imprimir resolución{token ? ' con QR' : ''}
            </button>
          )}
          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={onCerrar}><MenuIcon name="close" size={13} /> Cerrar</button>
        </div>
      </div>
      <dl className="mx-datos">
        <div><dt>Presentado</dt><dd>{fecha(n.fechaPresentacion)}</dd></div>
        <div><dt>Etapa</dt><dd>{n.etapa === 'ANTES_COMPUTO' ? 'Antes del cómputo' : 'Después del cómputo'}</dd></div>
        <div><dt>Origen</dt><dd>{n.origen === 'PERSONERO' ? `${n.personero} (${n.listaPersonero})` : 'De oficio (CEUNP)'}</dd></div>
        <div><dt>Registrado por</dt><dd>{n.registradoPor ?? '—'}</dd></div>
      </dl>
      <h4 className="cp-sub">Sustento</h4>
      <p className="ig-texto">{n.sustento}</p>
      {n.pruebas && <><h4 className="cp-sub">Pruebas ofrecidas</h4><p className="ig-texto">{n.pruebas}</p></>}

      {n.estado !== 'PRESENTADA' && (
        <>
          <h4 className="cp-sub">9 mostrarResolucionNulidad()</h4>
          <dl className="mx-datos cp-meta">
            <div><dt>Resolución</dt><dd>{n.numeroResolucion}</dd></div>
            <div><dt>Fecha</dt><dd>{fecha(n.fechaResolucion)}</dd></div>
            <div><dt>Votación del Pleno</dt><dd>{n.votosFavor} a favor · {n.votosContra} en contra de {n.miembrosPleno}{si(n.votoDirimente) ? ' · dirimente' : ''}</dd></div>
            <div><dt>Integridad</dt><dd><span className={`cv-estado ${si(n.resolucionIntegra) ? 'votacion' : 'anulado'}`}>{si(n.resolucionIntegra) ? 'Huella coincide' : 'Alterada'}</span></dd></div>
          </dl>
          <dl className="nl-texto">
            <div><dt>Fundamento</dt><dd>{n.fundamentoResolucion}</dd></div>
            {doc?.efecto && <div><dt>Efecto</dt><dd>{doc.efecto}</dd></div>}
            <div><dt>Huella SHA-256</dt><dd className="cp-hash">{n.hashIntegridad}</dd></div>
          </dl>
          {(doc?.votos_excluidos ?? []).length > 0 && (
            <div className="table-wrap">
              <table>
                <thead><tr><th>Cargo</th><th>Opción excluida del cómputo</th><th className="n">Votos</th></tr></thead>
                <tbody>{doc.votos_excluidos.map((v) => <tr key={`${v.cargo}-${v.lista}`} className="nl-excluido"><td>{v.cargo}</td><td>{OPCION[v.opcion] ?? v.lista}</td><td className="n">{v.votos}</td></tr>)}</tbody>
              </table>
            </div>
          )}
          {!token && <p className="muted cp-nota">El QR de la resolución solo se entrega al emitirla; la reimpresión lleva la huella SHA-256.</p>}
          {n.estado === 'FUNDADA' && (
            <div className="cv-actions cp-izq">
              <button type="button" className="cv-btn cv-btn-primary" onClick={onComunicar}>
                <MenuIcon name="external" size={15} /> Comunicar y publicar ({n.comunicaciones} de 5)
              </button>
            </div>
          )}
        </>
      )}

      {n.estado === 'PRESENTADA' && acciones.resolver && (!resolviendo ? (
        <div className="cv-actions cp-izq">
          <button type="button" className="cv-btn cv-btn-primary" disabled={saving}
            onClick={() => { setAccion('RESOLVER'); setConfirmando(false); setResolucion((r) => ({ ...r, decision: opciones.length === 1 ? opciones[0] : '' })); }}>
            <MenuIcon name="scale" size={15} /> Resolver en el Pleno
          </button>
        </div>
      ) : (
        <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>{parcial ? '2 anularMesa · resolución del Pleno' : '6 anularProceso · resolución del Pleno'}</h4>
          {sinMateria && <p className="ig-texto">La {parcial && n.estadoMesa === 'ANULADA' ? 'mesa' : 'elección'} ya fue anulada: el recurso solo puede declararse improcedente por sustracción de la materia.</p>}
          {participacion && <p className="ig-texto">La falta de participación quedó determinada por el cómputo oficial: la nulidad solo se declara fundada (RN31).</p>}
          <div className="im-estados cq-chips" role="group" aria-label="Decisión">
            {opciones.map((o) => (
              <button key={o} type="button" className={`cq-chip${resolucion.decision === o ? ' on' : ''}`}
                onClick={() => { setResolucion((r) => ({ ...r, decision: o })); setConfirmando(false); }}>
                {ESTADO_RECURSO[o].texto}
              </button>
            ))}
          </div>
          <div className="ig-grid nl-pleno">
            <label className="cv-field">
              <span className="cv-label">N.º de resolución (RN34)</span>
              <input required maxLength={40} value={resolucion.numeroResolucion} disabled={saving} onChange={set('numeroResolucion')} placeholder="Ej.: 021-2026-CEUNP" />
            </label>
            <label className="cv-field">
              <span className="cv-label">Miembros presentes</span>
              <input type="number" min={1} max={9} required value={resolucion.miembrosPleno} disabled={saving} onChange={set('miembrosPleno')} />
            </label>
            <label className="cv-field">
              <span className="cv-label">Votos a favor</span>
              <input type="number" min={0} max={9} required value={resolucion.votosFavor} disabled={saving} onChange={set('votosFavor')} />
            </label>
            <label className="cv-field">
              <span className="cv-label">Votos en contra</span>
              <input type="number" min={0} max={9} required value={resolucion.votosContra} disabled={saving} onChange={set('votosContra')} />
            </label>
            {empate && (
              <label className="cv-field nl-check">
                <input type="checkbox" checked={resolucion.votoDirimente} disabled={saving}
                  onChange={(e) => { setResolucion((r) => ({ ...r, votoDirimente: e.target.checked })); setConfirmando(false); }} />
                <span>El Presidente ejerce su voto dirimente a favor de la decisión</span>
              </label>
            )}
            <label className="cv-field nl-ancho">
              <span className="cv-label">Fundamento de la resolución</span>
              <textarea rows={3} minLength={10} maxLength={1000} required value={resolucion.fundamento} disabled={saving} onChange={set('fundamento')}
                placeholder={resolucion.decision === 'FUNDADA' ? 'Ej.: de las pruebas actuadas se acredita la causal invocada…' : 'Ej.: no se acredita la causal invocada…'} />
            </label>
          </div>
          {errorVotos && <small className="cv-error">{errorVotos}</small>}
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="submit" className={`cv-btn ${resolucion.decision === 'FUNDADA' ? 'cv-btn-primary im-btn-peligro' : 'cv-btn-success'}`} disabled={saving || !listo}>
                <MenuIcon name="scale" size={15} /> Emitir resolución
              </button>
            </div>
          ) : (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>¿Declarar {ESTADO_RECURSO[resolucion.decision].texto.toUpperCase()} el recurso N.º {n.idNulidad} ({resolucion.numeroResolucion})?</strong>
                <span>
                  {resolucion.decision === 'FUNDADA'
                    ? parcial ? `La mesa ${n.numeroMesa} y sus actas quedan ANULADAS y sus votos se excluyen del cómputo.`
                      : participacion ? 'Se formaliza la nulidad total ya determinada por el cómputo.'
                        : 'El proceso, sus mesas y sus actas quedan ANULADOS (y su segunda vuelta, si la hay).'
                    : 'El recurso se desestima y el proceso continúa.'} La decisión es inapelable (RN36).
                </span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onResolver}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Emitiendo…' : 'Confirmar'}
                </button>
              </div>
            </div>
          )}
        </form>
      ))}
    </div>
  );
}

/** Cargo con su ranking: finalistas, empates y sorteo del Pleno. */
function CargoSegunda({ c, proceso, acciones, quorum, sorteo, setSorteo, accion, setAccion, confirmando, setConfirmando, saving, onDirimir, onCancelar }) {
  const abierto = accion === `DIRIMIR:${c.idCargo}`;
  const empatadas = c.listas.filter((l) => l.empatada);
  const listo = sorteo.semilla.trim().length >= 4 && sorteo.numeroResolucion.trim() && Number(sorteo.miembrosPleno) >= quorum;
  const set = (campo) => (e) => { setSorteo((s) => ({ ...s, [campo]: e.target.value })); setConfirmando(false); };
  const d = c.dirimencia;

  return (
    <div className="cp-cargo">
      <div className="cp-cargo-head">
        <h4>{c.cargo}</h4>
        <div className="cs-acciones-head">
          <span className={`cv-estado ${CLASE_RESULTADO[c.estadoResultado] ?? 'creado'}`}>{ESTADO_RESULTADO[c.estadoResultado] ?? c.estadoResultado}{c.listaGanadora ? `: ${c.listaGanadora}` : ''}</span>
          {d && (
            <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirActaSorteo(proceso, c)}>
              <MenuIcon name="file" size={13} /> Acta del sorteo
            </button>
          )}
        </div>
      </div>
      <div className="table-wrap">
        <table>
          <thead><tr><th>Lista</th><th className="n">Votos</th><th className="n">% de válidos</th><th>Situación</th></tr></thead>
          <tbody>
            {c.listas.map((l) => {
              const elegida = d && (d.listasElegidas ?? []).includes(l.idLista);
              return (
                <tr key={l.idLista} className={l.finalista || elegida || l.idLista === c.idListaGanadora ? 'cp-puntera' : l.empatada && !d ? 'cp-alerta' : ''}>
                  <td>{l.ordenCedula != null ? `${l.ordenCedula}. ` : ''}{l.lista}</td>
                  <td className="n">{l.votos}</td>
                  <td className="n">{pct(l.porcentajeValidos)}</td>
                  <td>
                    {l.idLista === c.idListaGanadora ? 'Ganadora'
                      : elegida ? 'Elegida por sorteo'
                        : l.finalista ? 'Pasa a la segunda vuelta'
                          : l.empatada ? (d ? 'No elegida en el sorteo' : 'Empatada: sorteo pendiente') : '—'}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      {d && <p className="muted cp-nota">Sorteo {d.numeroResolucion} del {fecha(d.fecha)} · semilla «{d.semilla}» · {d.cupos} cupo(s).</p>}
      {c.empateSinDirimir && (
        <div className="ig-form cp-segunda">
          <h4>{c.estadoResultado === 'EMPATE' ? 'Empate en la segunda vuelta (RF97)' : `Empate por ${c.cupos} cupo(s) de la segunda vuelta (RN33)`}</h4>
          <p className="ig-texto">{empatadas.map((l) => l.lista).join(', ')} empataron con {empatadas[0]?.votos} votos. El Pleno anuncia en sesión una semilla pública; el sistema ordena las listas por la huella SHA-256 de «semilla | cargo | lista» y elige {c.estadoResultado === 'EMPATE' ? 'la ganadora' : 'las que pasan'}. Cualquiera puede repetir el cálculo.</p>
          {!acciones.dirimir ? <p className="muted">El sorteo lo realiza el Pleno del CEUNP.</p> : !abierto ? (
            <div className="cv-actions cp-izq">
              <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => { setAccion(`DIRIMIR:${c.idCargo}`); setConfirmando(false); }}>
                <MenuIcon name="sorteo" size={15} /> Dirimir por sorteo
              </button>
            </div>
          ) : (
            <form onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
              <div className="ig-grid">
                <label className="cv-field">
                  <span className="cv-label">Semilla pública</span>
                  <input required minLength={4} maxLength={100} value={sorteo.semilla} disabled={saving} onChange={set('semilla')} placeholder="Ej.: número leído en la sesión" />
                </label>
                <label className="cv-field">
                  <span className="cv-label">N.º de resolución</span>
                  <input required maxLength={40} value={sorteo.numeroResolucion} disabled={saving} onChange={set('numeroResolucion')} />
                </label>
                <label className="cv-field">
                  <span className="cv-label">Miembros del Pleno</span>
                  <input type="number" min={1} max={9} required value={sorteo.miembrosPleno} disabled={saving} onChange={set('miembrosPleno')} />
                  {Number(sorteo.miembrosPleno) < quorum && <small className="cv-error">Sin quórum: se requieren {quorum} miembros (RN36).</small>}
                </label>
                <label className="cv-field cp-ancho3">
                  <span className="cv-label">Fundamento (opcional)</span>
                  <input maxLength={1000} value={sorteo.fundamento} disabled={saving} onChange={set('fundamento')} />
                </label>
              </div>
              {!confirmando ? (
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
                  <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !listo}>
                    <MenuIcon name="sorteo" size={15} /> Realizar sorteo
                  </button>
                </div>
              ) : (
                <div className="cq-confirmar-emision" role="alert">
                  <div>
                    <strong>¿Realizar el sorteo de {c.cargo} con la semilla «{sorteo.semilla}»?</strong>
                    <span>El resultado es definitivo: {c.estadoResultado === 'EMPATE' ? 'la lista elegida queda como ganadora y ya se puede proclamar.' : 'las listas elegidas pasan a la segunda vuelta.'}</span>
                  </div>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                    <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onDirimir}>
                      <MenuIcon name="check" size={15} /> {saving ? 'Sorteando…' : 'Confirmar'}
                    </button>
                  </div>
                </div>
              )}
            </form>
          )}
        </div>
      )}
    </div>
  );
}
