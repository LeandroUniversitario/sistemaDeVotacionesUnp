import { useCallback, useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { CodigoQR, fecha } from '../credenciales/LectorQR';
import { urlVerificacionActa } from '../instalacion/ActaInstalacion';
import { EJEMPLARES, imprimirActaEscrutinio, imprimirCargoEntrega, imprimirCopiaPersonero } from './ActaEscrutinio';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import '../cierre/cierre.css';
import './escrutinio.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS12 · Realizar escrutinio y conciliar — «PantallaEscrutinio» (boundary).
 * Actores: Presidente y Secretario de mesa; los personeros fiscalizan.
 *
 * Mensajes del diagrama de colaboración «Colaboracion - Realizar escrutinio y conciliar»:
 *   1 ingresarTotalCedulas(total) → 2 verificarTotal() → ValidarTotales
 *     3 contarVotantes() → PadronMesa · 4 mostrarResultadoValidacion()
 *   5 ingresarConteoManual(conteo_listas) → 6 compararConDigital(conteo) → ConciliarVotos
 *     7 contarVotosDigitales() → Voto · 8 mostrarCuadre()
 *   9 confirmarEscrutinio() → 10 crearActa(resultados) → GenerarActaEscrutinio
 *     11 insertarActa(hash, contenido) · 12 registrarFirmas(firmas) · 13 mostrarActaGenerada()
 * Paso 4 de la tabla 38: impugnaciones de los personeros (CUS13). Paso 9: tres ejemplares y
 * entrega al CEUNP (RF86, RF87).
 *
 * Flujos alternos (tabla 38): A1 sobran cédulas, A2 faltan cédulas, A3 el conteo manual difiere
 * del digital, A4 votos impugnados pendientes y A5 acta observada.
 */

const PASOS = [
  { codigo: 'CEDULAS', texto: 'Contar cédulas' },
  { codigo: 'CONTEO', texto: 'Conteo y conciliación' },
  { codigo: 'ACTA', texto: 'Acta de escrutinio' },
  { codigo: 'ENTREGA', texto: 'Entrega al CEUNP' },
];
const ORDEN = ['CEDULAS', 'CONTEO', 'ACTA', 'ENTREGA', 'FIN'];
const CARGO = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal' };
const ORIGEN = { TITULAR: 'Titular', SUPLENTE: 'Suplente', REEMPLAZANTE: 'Reemplazante' };
const TIPO_PERSONERO = { MESA: 'de mesa', GENERAL: 'general', ALTERNO: 'alterno' };
const ESTADO_ESCRUTINIO = {
  POR_CERRAR: { clase: 'creado', texto: 'Sufragio sin cerrar' },
  LISTA: { clase: 'creado', texto: 'Por escrutar' },
  CEDULAS_CONTADAS: { clase: 'votacion', texto: 'Escrutinio en curso' },
  CONTEO_REGISTRADO: { clase: 'votacion', texto: 'Conciliando' },
  ACTA_EMITIDA: { clase: 'inscripcion', texto: 'Acta emitida' },
  ENTREGADA: { clase: 'inscripcion', texto: 'Entregada al CEUNP' },
  ANULADA: { clase: 'anulado', texto: 'No aplica' },
};
const OPCION = { BLANCO: 'Votos en blanco', NULO: 'Votos nulos', IMPUGNADO: 'Votos impugnados' };
const si = (v) => v === true || v === 1 || v === '1';
const n = (v) => (v === '' || v == null ? 0 : Number(v));
const hora = (v) => (v ? new Date(v).toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }) : '—');
const conSigno = (d) => (d > 0 ? `+${d}` : String(d));

function estadoDeMesa(m) {
  if (m.estadoEscrutinio) return ESTADO_ESCRUTINIO[m.estadoEscrutinio];
  if (m.estado === 'NO_INSTALADA' || m.estado === 'ANULADA') return ESTADO_ESCRUTINIO.ANULADA;
  return m.estadoCierre === 'ACTA_EMITIDA' ? ESTADO_ESCRUTINIO.LISTA : ESTADO_ESCRUTINIO.POR_CERRAR;
}

/** Formulario del conteo manual a partir de los cargos; si ya hay un conteo, lo trae para el recuento. */
function conteoInicial(cargos) {
  const form = {};
  for (const c of cargos ?? []) {
    const previo = (opcion, idLista = null) => c.conteo.find((k) => k.opcion === opcion && (k.idLista ?? null) === idLista)?.votosManual;
    form[c.idCargo] = {
      listas: Object.fromEntries(c.listas.map((l) => [l.idLista, previo('LISTA', l.idLista) ?? ''])),
      BLANCO: previo('BLANCO') ?? '',
      NULO: previo('NULO') ?? '',
    };
  }
  return form;
}

export default function PantallaEscrutinio({ session, onSessionExpired }) {
  const esMiembro = session.rol === 'MIEMBRO_MESA';
  const puedeOperar = esMiembro || session.rol === 'CEUNP';

  const [idDocenteSesion, setIdDocenteSesion] = useState(session.idDocente ?? null);
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [mesas, setMesas] = useState([]);
  const [idMesa, setIdMesa] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [paso, setPaso] = useState('CEDULAS');
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [confirmando, setConfirmando] = useState(null);       // 'CEDULAS' | 'CONTEO' | 'ACTA' | 'ENTREGA'
  const [cedulas, setCedulas] = useState({ total: '', destruidas: false, observacion: '' });
  const [conteo, setConteo] = useState({});
  const [impugnacion, setImpugnacion] = useState(null);       // { idPersonero, idCargo, motivo } mientras se registra
  const [datosActa, setDatosActa] = useState({ prevaleceFisica: false, observaciones: '' });
  const [personeros, setPersoneros] = useState([]);           // id_personero que firman
  const [entrega, setEntrega] = useState({ recibidoPor: '', ejemplares: [], copiasPersoneros: '0', entregaPadron: true, entregaMaterial: true, observacion: '' });
  const [emitida, setEmitida] = useState(null);               // { tokenQr, idActa } tras emitir

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const aplicarDetalle = useCallback((data, reiniciarConteo = false) => {
    setDetalle(data);
    setPaso(data.paso === 'FIN' ? 'ENTREGA' : data.paso);
    if (reiniciarConteo) setConteo(conteoInicial(data.cargos));
    setMesas((prev) => prev.map((m) => (m.id === data.mesa.id
      ? { ...m, estado: data.mesa.estado, estadoCierre: data.mesa.estadoCierre, estadoEscrutinio: data.registro?.estado ?? null } : m)));
  }, []);

  const cargarMesas = useCallback(async (proceso) => {
    const lista = await apiRequest(esMiembro || !proceso ? '/api/escrutinio/mesas' : `/api/escrutinio/mesas?procesoId=${proceso}`);
    setMesas(lista);
    return lista;
  }, [esMiembro]);

  const primeraMesa = (lista) => lista.find((m) => ['CEDULAS_CONTADAS', 'CONTEO_REGISTRADO', 'ACTA_EMITIDA'].includes(m.estadoEscrutinio))
    ?? lista.find((m) => !m.estadoEscrutinio && m.estadoCierre === 'ACTA_EMITIDA') ?? lista[0];

  useEffect(() => {
    (async () => {
      try {
        if (esMiembro && idDocenteSesion == null) {
          const yo = await apiRequest('/api/auth/me');
          setIdDocenteSesion(yo.idDocente ?? null);
        }
        let proceso = null;
        if (!esMiembro) {
          const lista = await apiRequest('/api/escrutinio/procesos');
          setProcesos(lista);
          proceso = lista[0]?.id ?? null;
          setIdProceso(proceso);
        }
        const lista = await cargarMesas(proceso);
        const primera = primeraMesa(lista);
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
        aplicarDetalle(await apiRequest(`/api/escrutinio/mesas/${idMesa}`), true);
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
      setIdMesa(primeraMesa(lista)?.id ?? null);
    } catch (e) {
      manejarError(e);
    }
  }

  function elegirMesa(id) {
    setIdMesa(id);
    setFeedback(null);
    setConfirmando(null);
    setEmitida(null);
    setImpugnacion(null);
    setCedulas({ total: '', destruidas: false, observacion: '' });
    setDatosActa({ prevaleceFisica: false, observaciones: '' });
    setPersoneros([]);
    setEntrega({ recibidoPor: '', ejemplares: [], copiasPersoneros: '0', entregaPadron: true, entregaMaterial: true, observacion: '' });
  }

  async function ejecutar(promesa, reiniciarConteo = false) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await promesa;
      aplicarDetalle(data.detalle, reiniciarConteo);
      setFeedback({ type: 'success', text: data.mensaje });
      if (!esMiembro) apiRequest('/api/escrutinio/procesos').then(setProcesos).catch(() => {});
      return data;
    } catch (e) {
      manejarError(e);
      return null;
    } finally {
      setSaving(false);
      setConfirmando(null);
    }
  }

  /** 1 ingresarTotalCedulas(total) → 2 verificarTotal() → 4 mostrarResultadoValidacion(). */
  function ingresarTotalCedulas() {
    return ejecutar(apiRequest(`/api/escrutinio/mesas/${idMesa}/cedulas`, {
      method: 'POST',
      body: JSON.stringify({ totalCedulas: Number(cedulas.total), destruidas: cedulas.destruidas, observacion: cedulas.observacion }),
    }), true);
  }

  /** Paso 4 de la tabla 38: el personero impugna un voto; la cédula se cuenta como impugnada (A4). */
  async function registrarImpugnacion() {
    const data = await ejecutar(apiRequest(`/api/escrutinio/mesas/${idMesa}/impugnaciones`, {
      method: 'POST',
      body: JSON.stringify({ idPersonero: Number(impugnacion.idPersonero), idCargo: Number(impugnacion.idCargo), motivo: impugnacion.motivo }),
    }));
    if (data) setImpugnacion(null);
  }

  /** 5 ingresarConteoManual(conteo_listas) → 6 compararConDigital(conteo) → 8 mostrarCuadre(). */
  async function ingresarConteoManual() {
    const filas = [];
    for (const c of detalle.cargos) {
      const f = conteo[c.idCargo] ?? { listas: {} };
      for (const l of c.listas) filas.push({ idCargo: c.idCargo, opcion: 'LISTA', idLista: l.idLista, votos: n(f.listas[l.idLista]) });
      filas.push({ idCargo: c.idCargo, opcion: 'BLANCO', votos: n(f.BLANCO) });
      filas.push({ idCargo: c.idCargo, opcion: 'NULO', votos: n(f.NULO) });
      filas.push({ idCargo: c.idCargo, opcion: 'IMPUGNADO', votos: c.impugnaciones });
    }
    const data = await ejecutar(apiRequest(`/api/escrutinio/mesas/${idMesa}/conteo`, { method: 'POST', body: JSON.stringify({ conteo: filas }) }));
    if (data) {
      // 8 mostrarCuadre(): se queda en el conteo para ver las diferencias; A3 se avisa como alerta.
      setPaso('CONTEO');
      if (data.detalle.cargos.some((c) => !c.cuadra || !c.totalCuadra)) setFeedback({ type: 'error', text: data.mensaje });
    }
  }

  /** 9 confirmarEscrutinio() → 10 crearActa(resultados) → 13 mostrarActaGenerada(). */
  async function confirmarEscrutinio() {
    const data = await ejecutar(apiRequest(`/api/escrutinio/mesas/${idMesa}/acta`, {
      method: 'POST',
      body: JSON.stringify({ prevaleceFisica: datosActa.prevaleceFisica, observaciones: datosActa.observaciones, personeros }),
    }));
    if (data) setEmitida({ tokenQr: data.tokenQr, idActa: data.idActa });
  }

  /** Paso 9 de la tabla 38: tres ejemplares y entrega al CEUNP (RF86, RF87). */
  function registrarEntrega() {
    return ejecutar(apiRequest(`/api/escrutinio/mesas/${idMesa}/entrega`, {
      method: 'POST',
      body: JSON.stringify({
        recibidoPor: entrega.recibidoPor,
        ejemplares: entrega.ejemplares.length,
        copiasPersoneros: n(entrega.copiasPersoneros),
        entregaPadron: entrega.entregaPadron,
        entregaMaterial: entrega.entregaMaterial,
        observacion: entrega.observacion,
      }),
    }));
  }

  async function refrescar() {
    try {
      if (!esMiembro) setProcesos(await apiRequest('/api/escrutinio/procesos'));
      await cargarMesas(idProceso);
      if (idMesa) aplicarDetalle(await apiRequest(`/api/escrutinio/mesas/${idMesa}`));
    } catch (e) {
      manejarError(e);
    }
  }

  // ─── Render ────────────────────────────────────────────────────────────

  if (cargando) return <div className="panel"><p className="muted">Cargando mesas…</p></div>;

  const proceso = procesos.find((p) => p.id === idProceso);
  const mesa = detalle?.mesa;
  const registro = detalle?.registro;
  const cierre = detalle?.cierre;
  const cargos = detalle?.cargos ?? [];
  const firmantes = detalle?.firmantes ?? [];
  const presidencia = firmantes.find((f) => f.cargo === 'PRESIDENTE');
  const secretaria = firmantes.find((f) => f.cargo === 'SECRETARIO');
  const ejerce = (f) => !esMiembro || !f || f.origen === 'REEMPLAZANTE' || f.idDocente === idDocenteSesion;
  const soyPresidente = ejerce(presidencia);
  const soySecretario = soyPresidente || ejerce(secretaria);
  const avance = detalle ? ORDEN.indexOf(detalle.paso) : 0;
  const votantes = registro?.totalVotantes ?? cierre?.totalVotaron ?? 0;

  // 2-3 verificarTotal() / contarVotantes(): vista previa del cuadre de cédulas (RF77, RF78)
  const totalCedulas = cedulas.total === '' ? null : Number(cedulas.total);
  const sobran = totalCedulas != null ? Math.max(totalCedulas - votantes, 0) : 0;
  const faltan = totalCedulas != null ? Math.max(votantes - totalCedulas, 0) : 0;
  const difiereCedulas = sobran > 0 || faltan > 0;
  const cedulasListas = totalCedulas != null && totalCedulas >= 0 && (!sobran || cedulas.destruidas) && (!difiereCedulas || cedulas.observacion.trim());

  // Cuadre registrado (8 mostrarCuadre)
  const conteoRegistrado = cargos.length > 0 && cargos.every((c) => c.conteo.length > 0) && registro?.estado !== 'CEDULAS_CONTADAS';
  const cuadra = si(registro?.conteoCuadra);
  const totalCuadra = si(registro?.totalCuadra);
  const veces = registro?.vecesConteo ?? 0;
  const necesitaRecuento = registro?.estado === 'CONTEO_REGISTRADO' && !cuadra && veces < 2;
  const exigePrevalencia = registro?.estado === 'CONTEO_REGISTRADO' && !cuadra && veces >= 2;
  const obsObligatoria = exigePrevalencia || (registro?.estado === 'CONTEO_REGISTRADO' && !totalCuadra && !registro?.observacionCedulas);
  const actaLista = !necesitaRecuento && (!exigePrevalencia || datosActa.prevaleceFisica) && (!obsObligatoria || datosActa.observaciones.trim());
  const saldraObservada = Boolean(datosActa.observaciones.trim() || registro?.observacionCedulas);
  const impugnados = cargos.reduce((s, c) => s + n(c.impugnaciones), 0);

  const entregaLista = entrega.recibidoPor.trim() && entrega.ejemplares.length === 3
    && ((entrega.entregaPadron && entrega.entregaMaterial) || entrega.observacion.trim());

  return (
    <div className="pd-shell cq-shell im-shell cs-shell es-shell mx">
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
          <div className={`in-plazo ${registro && !['ACTA_EMITIDA', 'ENTREGADA'].includes(registro.estado) ? 'open' : 'closed'}`}>
            <MenuIcon name={registro ? 'table' : 'lock'} size={18} />
            <div>
              <strong>
                {!registro ? 'Escrutinio por iniciar'
                  : ['ACTA_EMITIDA', 'ENTREGADA'].includes(registro.estado) ? `Escrutinio concluido a las ${hora(registro.horaFin)}`
                    : `Escrutinio en curso desde las ${hora(registro.horaInicio)}`}
              </strong>
              <span>RN26 · El escrutinio es ininterrumpido e irreversible: lo registrado no se modifica.</span>
            </div>
          </div>
        )}
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      {proceso && (
        <section className="cq-resumen">
          <div className="cq-kpi" style={{ '--cq-color': '#d97706' }}>
            <span>Mesas por escrutar <em>CUS11</em></span>
            <strong>{Math.max(proceso.cerradas - proceso.actas - proceso.enCurso, 0)}<small> / {proceso.mesas}</small></strong>
            <small>{proceso.cerradas} con acta de sufragio</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#059669' }}>
            <span>Escrutinios en curso <em>RN26</em></span>
            <strong>{proceso.enCurso}</strong>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
            <span>Actas de escrutinio <em>RF85</em></span>
            <strong>{proceso.actas}</strong>
            <i className="cq-barra"><b style={{ width: `${proceso.mesas ? Math.round((proceso.actas / proceso.mesas) * 100) : 0}%` }} /></i>
            <small>{proceso.observadas} observada(s)</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
            <span>Entregadas al CEUNP <em>RF87</em></span>
            <strong>{proceso.entregadas}<small> / {proceso.actas}</small></strong>
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
            const est = estadoDeMesa(m);
            return (
              <button key={m.id} type="button" className={`im-mesa${m.id === idMesa ? ' on' : ''}`} onClick={() => elegirMesa(m.id)}>
                <span className="im-mesa-num">Mesa {m.numero}</span>
                <span className={`cv-estado ${est.clase}`}>{est.texto}</span>
                <small>{m.ubicacion}</small>
                {m.totalVotaron != null && <small>Votaron {m.totalVotaron}{si(m.observada) ? ' · acta observada' : ''}</small>}
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
          <div className="panel mx-ficha">
            <div className="mx-ficha-top">
              <div>
                <h3>Mesa {mesa.numero}</h3>
                <p>{mesa.ubicacion}</p>
              </div>
              <span className={`cv-estado ${estadoDeMesa({ ...mesa, estadoEscrutinio: registro?.estado }).clase}`}>
                {estadoDeMesa({ ...mesa, estadoEscrutinio: registro?.estado }).texto}
              </span>
            </div>
            <dl className="mx-datos">
              <div><dt>Proceso</dt><dd>{mesa.proceso}</dd></div>
              <div><dt>Cierre del sufragio</dt><dd>{hora(cierre?.horaCierre ?? mesa.horaCierre)}</dd></div>
              <div><dt>Acta de sufragio</dt><dd>{cierre?.idActaSufragio ? `N.º ${String(cierre.idActaSufragio).padStart(6, '0')}` : 'Pendiente'}</dd></div>
              {presidencia && <div><dt>Preside</dt><dd>{presidencia.nombre}</dd></div>}
              {secretaria && <div><dt>Secretaría</dt><dd>{secretaria.nombre}</dd></div>}
            </dl>
          </div>

          {!puedeOperar && <div className="alert success" role="note">Vista de consulta: el escrutinio lo realizan el presidente y el secretario de mesa, o el CEUNP.</div>}

          {/* 3 contarVotantes() · 4 mostrarResultadoValidacion() */}
          <section className="cq-resumen">
            <div className="cq-kpi" style={{ '--cq-color': '#059669' }}>
              <span>Electores que votaron <em>RF77</em></span>
              <strong>{votantes}<small> / {cierre?.totalElectores ?? mesa.totalElectores}</small></strong>
              <small>según el acta de sufragio</small>
            </div>
            <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
              <span>Cédulas del ánfora <em>RF78</em></span>
              <strong>{registro?.cedulasContadas ?? '—'}{registro && <small> · escrutadas {registro.cedulasEscrutadas}</small>}</strong>
              <small>
                {!registro ? 'por contar'
                  : registro.cedulasSobrantes ? `A1: ${registro.cedulasSobrantes} destruida(s) sin abrir`
                    : registro.cedulasFaltantes ? `A2: faltan ${registro.cedulasFaltantes}` : 'coinciden con los votantes'}
              </small>
            </div>
            <div className="cq-kpi" style={{ '--cq-color': cuadra ? '#059669' : '#e11d48' }}>
              <span>Conciliación <em>RF83</em></span>
              <strong>{registro?.estado === 'CEDULAS_CONTADAS' || !registro ? '—' : cuadra ? 'Cuadra' : 'Difiere'}</strong>
              <small>{veces > 1 ? `${veces - 1} recuento(s)` : veces === 1 ? 'primer conteo' : 'conteo manual pendiente'}</small>
            </div>
            <div className="cq-kpi" style={{ '--cq-color': '#f59e0b' }}>
              <span>Votos impugnados <em>A4</em></span>
              <strong>{impugnados}</strong>
              <small>pendientes de resolver (CUS13)</small>
            </div>
          </section>

          <div className="pd-tabs cq-tabs mx-pasos" role="tablist" aria-label="Pasos del escrutinio">
            {PASOS.map((p, i) => {
              const hecho = i < avance;
              return (
                <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
                  className={`pd-tab mx-paso${paso === p.codigo ? ' on' : ''}${hecho ? ' hecho' : ''}`} disabled={i > avance} onClick={() => setPaso(p.codigo)}>
                  <span className="mx-paso-num">{hecho ? <MenuIcon name="check" size={14} /> : i + 1}</span>
                  <span className="mx-paso-texto">
                    <b>{p.texto}</b>
                    <small>{hecho ? 'Completado' : i === avance ? 'En curso' : 'Pendiente'}</small>
                  </span>
                </button>
              );
            })}
          </div>

          {/* ── 1-4: contar las cédulas del ánfora ── */}
          {paso === 'CEDULAS' && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Contar las cédulas del ánfora</h3>
                  <p className="muted">El presidente abre el ánfora y cuenta las cédulas sin abrirlas. El sistema compara el total con los electores que votaron (RF77). Si sobran, se retiran al azar y se destruyen sin abrirlas (A1); si faltan, se continúa y se anota (A2). Al registrar, empieza el escrutinio.</p>
                </div>
              </div>
              {registro ? (
                <dl className="cq-meta">
                  <div><dt>Inicio del escrutinio</dt><dd>{fecha(registro.horaInicio)}</dd></div>
                  <div><dt>Electores que votaron</dt><dd>{registro.totalVotantes}</dd></div>
                  <div><dt>Cédulas contadas</dt><dd>{registro.cedulasContadas}</dd></div>
                  <div><dt>Sobrantes destruidas (A1)</dt><dd>{registro.cedulasSobrantes}</dd></div>
                  <div><dt>Faltantes (A2)</dt><dd>{registro.cedulasFaltantes}</dd></div>
                  <div><dt>Cédulas escrutadas</dt><dd>{registro.cedulasEscrutadas}</dd></div>
                  <div><dt>Contó</dt><dd>{registro.iniciadoPor ?? '—'}</dd></div>
                  {registro.observacionCedulas && <div className="es-ancho"><dt>Observación</dt><dd>{registro.observacionCedulas}</dd></div>}
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
                  {detalle.puedeContar && (
                    <form className="cv-form" onSubmit={(e) => { e.preventDefault(); setConfirmando('CEDULAS'); }}>
                      <div className="im-cedulas">
                        <label className="cv-field">
                          <span className="cv-label">Cédulas contadas en el ánfora</span>
                          <input type="number" min={0} max={100000} required value={cedulas.total} disabled={!puedeOperar || !soyPresidente || saving}
                            onChange={(e) => { setCedulas((c) => ({ ...c, total: e.target.value })); setConfirmando(null); }} />
                          <small className="muted">Votaron {votantes} electores (acta de sufragio).</small>
                        </label>
                      </div>
                      {totalCedulas != null && (
                        <div className={`es-validacion ${difiereCedulas ? (sobran ? 'sobran' : 'faltan') : 'ok'}`} role="status">
                          <MenuIcon name={difiereCedulas ? 'alert' : 'check'} size={18} />
                          <div>
                            <strong>
                              {sobran ? `A1 · Sobran ${sobran} cédula(s)` : faltan ? `A2 · Faltan ${faltan} cédula(s)` : 'Las cédulas coinciden con los electores que votaron'}
                            </strong>
                            <span>
                              {sobran ? `Retire al azar ${sobran} cédula(s) sin abrirlas, destrúyalas y regístrelo. Se escrutarán ${votantes}.`
                                : faltan ? `Se continúa con ${totalCedulas} cédula(s) y la diferencia queda en el acta.`
                                  : `Se escrutarán ${totalCedulas} cédulas.`}
                            </span>
                          </div>
                        </div>
                      )}
                      {sobran > 0 && (
                        <label className="im-check">
                          <input type="checkbox" checked={cedulas.destruidas} disabled={!puedeOperar || !soyPresidente || saving}
                            onChange={(e) => setCedulas((c) => ({ ...c, destruidas: e.target.checked }))} />
                          <span>Retiré al azar {sobran} cédula(s) sobrante(s) y las destruí sin abrirlas (RN27)</span>
                        </label>
                      )}
                      {difiereCedulas && (
                        <label className="cv-field">
                          <span className="cv-label">Observación (obligatoria)</span>
                          <textarea rows={2} maxLength={1000} required value={cedulas.observacion} disabled={!puedeOperar || !soyPresidente || saving}
                            placeholder={sobran ? 'Ej.: se encontraron 2 cédulas más; se retiraron al azar y se destruyeron sin abrir.' : 'Ej.: faltan 2 cédulas; se continúa con el escrutinio.'}
                            onChange={(e) => setCedulas((c) => ({ ...c, observacion: e.target.value }))} />
                        </label>
                      )}
                      {puedeOperar && !soyPresidente && <p className="muted im-nota">Cuenta las cédulas el presidente en funciones: {presidencia?.nombre}.</p>}
                      {puedeOperar && soyPresidente && confirmando !== 'CEDULAS' && (
                        <div className="cv-actions">
                          <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !cedulasListas}>
                            <MenuIcon name="check" size={15} /> Verificar total e iniciar escrutinio
                          </button>
                        </div>
                      )}
                      {confirmando === 'CEDULAS' && (
                        <div className="cq-confirmar-emision" role="alert">
                          <div>
                            <strong>¿Registrar {totalCedulas} cédula(s) en el ánfora de la mesa {mesa.numero}?</strong>
                            <span>Empieza el escrutinio a las {hora(new Date())}. El conteo de cédulas ya no se podrá cambiar (RN26).</span>
                          </div>
                          <div className="cv-actions">
                            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                            <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={ingresarTotalCedulas}>
                              <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar e iniciar'}
                            </button>
                          </div>
                        </div>
                      )}
                    </form>
                  )}
                </>
              )}
              {registro && (
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('CONTEO')}>Continuar con el conteo</button>
                </div>
              )}
            </div>
          )}

          {/* ── Paso 4 y 5-8: impugnaciones, conteo manual y conciliación ── */}
          {paso === 'CONTEO' && registro && (
            <>
              <div className="panel cv-form">
                <div className="cv-section-head">
                  <div>
                    <h3>Votos impugnados (paso 4 · A4)</h3>
                    <p className="muted">El presidente lee cada cédula y la muestra a los personeros. Si un personero presente impugna un voto, registre la impugnación y aparte la cédula: se cuenta como impugnada hasta que la mesa la resuelva por mayoría o el CEUNP en apelación (CUS13).</p>
                  </div>
                  {detalle.puedeConciliar && puedeOperar && soySecretario && !impugnacion && (
                    <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving || detalle.personeros.length === 0}
                      onClick={() => setImpugnacion({ idPersonero: detalle.personeros[0]?.idPersonero ?? '', idCargo: cargos[0]?.idCargo ?? '', motivo: '' })}>
                      <MenuIcon name="alert" size={13} /> Registrar impugnación
                    </button>
                  )}
                </div>
                {detalle.personeros.length === 0 && <p className="muted im-nota">No hay personeros presentes en la mesa: nadie puede impugnar votos (RN24).</p>}
                {impugnacion && (
                  <form className="es-impugnar" onSubmit={(e) => { e.preventDefault(); registrarImpugnacion(); }}>
                    <label className="cv-field">
                      <span className="cv-label">Personero que impugna</span>
                      <select value={impugnacion.idPersonero} onChange={(e) => setImpugnacion((i) => ({ ...i, idPersonero: e.target.value }))}>
                        {detalle.personeros.map((p) => (
                          <option key={p.idPersonero} value={p.idPersonero}>{p.nombre} · {p.lista}</option>
                        ))}
                      </select>
                    </label>
                    <label className="cv-field">
                      <span className="cv-label">Cargo de la cédula</span>
                      <select value={impugnacion.idCargo} onChange={(e) => setImpugnacion((i) => ({ ...i, idCargo: e.target.value }))}>
                        {cargos.map((c) => <option key={c.idCargo} value={c.idCargo}>{c.nombre}</option>)}
                      </select>
                    </label>
                    <label className="cv-field es-ancho">
                      <span className="cv-label">Motivo</span>
                      <textarea rows={2} maxLength={1000} required value={impugnacion.motivo} placeholder="Ej.: la cédula tiene una marca fuera del recuadro."
                        onChange={(e) => setImpugnacion((i) => ({ ...i, motivo: e.target.value }))} />
                    </label>
                    <div className="cv-actions es-ancho">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setImpugnacion(null)}>Cancelar</button>
                      <button type="submit" className="cv-btn im-btn-peligro" disabled={saving || !impugnacion.motivo.trim()}>
                        <MenuIcon name="alert" size={15} /> {saving ? 'Registrando…' : 'Registrar impugnación'}
                      </button>
                    </div>
                  </form>
                )}
                {detalle.impugnaciones.length > 0 && (
                  <div className="table-wrap">
                    <table>
                      <thead><tr><th>N.º</th><th>Cargo</th><th>Personero</th><th>Motivo</th><th>Estado</th></tr></thead>
                      <tbody>
                        {detalle.impugnaciones.map((i) => (
                          <tr key={i.idImpugnacion}>
                            <td>{i.idImpugnacion}</td>
                            <td>{i.cargo}</td>
                            <td><strong>{i.personero}</strong><small className="pd-sub">{i.lista}</small></td>
                            <td>{i.motivo}</td>
                            <td><span className="cv-estado creado">{i.estado === 'PRESENTADA' ? 'Pendiente' : i.estado}</span></td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>

              <form className="panel cv-form" onSubmit={(e) => { e.preventDefault(); setConfirmando('CONTEO'); }}>
                <div className="cv-section-head">
                  <div>
                    <h3>Conteo manual por lista (RF79)</h3>
                    <p className="muted">El secretario agrupa las cédulas leídas e ingresa el conteo de cada cargo: votos por lista, en blanco, nulos e impugnados. Al registrarlo, el sistema lo compara con el conteo digital de la mesa (RF83) y con los electores que votaron (RF82). Registrarlo otra vez es un recuento (A3).</p>
                  </div>
                  {veces > 0 && <span className="im-contador">{veces === 1 ? 'Conteo registrado' : `Recuento ${veces - 1}`}</span>}
                </div>

                {cargos.map((c) => {
                  const f = conteo[c.idCargo] ?? { listas: {}, BLANCO: '', NULO: '' };
                  const suma = c.listas.reduce((s, l) => s + n(f.listas[l.idLista]), 0) + n(f.BLANCO) + n(f.NULO) + n(c.impugnaciones);
                  const editable = detalle.puedeConciliar && puedeOperar && soySecretario && !saving;
                  const set = (cambio) => setConteo((prev) => ({ ...prev, [c.idCargo]: { ...f, ...cambio } }));
                  return (
                    <div key={c.idCargo} className="es-cargo">
                      <div className="es-cargo-head">
                        <h4>{c.nombre}</h4>
                        <span className={`es-suma ${suma === n(c.votantes) ? 'ok' : suma > (registro.cedulasEscrutadas ?? 0) ? 'mal' : ''}`}>
                          Suma {suma} de {c.votantes} votantes
                        </span>
                      </div>
                      <div className="es-opciones">
                        {c.listas.map((l) => (
                          <label key={l.idLista} className="es-opcion">
                            <span className="es-opcion-nombre">
                              <b className="es-orden">{l.ordenCedula ?? '·'}</b>
                              <span>{l.nombre}{l.simbolo ? <small> · símbolo {l.simbolo}</small> : null}</span>
                            </span>
                            <input type="number" min={0} inputMode="numeric" placeholder="0" value={f.listas[l.idLista] ?? ''} disabled={!editable}
                              aria-label={`Votos de ${l.nombre}`} onChange={(e) => set({ listas: { ...f.listas, [l.idLista]: e.target.value } })} />
                          </label>
                        ))}
                        {['BLANCO', 'NULO'].map((o) => (
                          <label key={o} className="es-opcion especial">
                            <span className="es-opcion-nombre"><b className="es-orden">{o === 'BLANCO' ? 'B' : 'N'}</b><span>{OPCION[o]}</span></span>
                            <input type="number" min={0} inputMode="numeric" placeholder="0" value={f[o]} disabled={!editable}
                              aria-label={OPCION[o]} onChange={(e) => set({ [o]: e.target.value })} />
                          </label>
                        ))}
                        <label className="es-opcion especial">
                          <span className="es-opcion-nombre"><b className="es-orden">I</b><span>{OPCION.IMPUGNADO} <small>· según las impugnaciones registradas</small></span></span>
                          <input type="number" value={c.impugnaciones} disabled readOnly aria-label={OPCION.IMPUGNADO} />
                        </label>
                      </div>
                    </div>
                  );
                })}

                {detalle.puedeConciliar && puedeOperar && !soySecretario && <p className="muted im-nota">Ingresa el conteo el secretario o el presidente en funciones.</p>}
                {detalle.puedeConciliar && puedeOperar && soySecretario && confirmando !== 'CONTEO' && (
                  <div className="cv-actions">
                    {registro.estado === 'CONTEO_REGISTRADO' && <span className="cv-actions-note muted">Si recontó las cédulas, corrija los números y regístrelos otra vez.</span>}
                    <button type="submit" className="cv-btn cv-btn-primary" disabled={saving}>
                      <MenuIcon name="scale" size={15} /> {registro.estado === 'CONTEO_REGISTRADO' ? 'Registrar recuento y conciliar' : 'Registrar conteo y conciliar'}
                    </button>
                  </div>
                )}
                {confirmando === 'CONTEO' && (
                  <div className="cq-confirmar-emision" role="alert">
                    <div>
                      <strong>¿Registrar el conteo manual de la mesa {mesa.numero}?</strong>
                      <span>El sistema lo comparará con el conteo digital y mostrará las diferencias por opción.</span>
                    </div>
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                      <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={ingresarConteoManual}>
                        <MenuIcon name="check" size={15} /> {saving ? 'Conciliando…' : 'Registrar y conciliar'}
                      </button>
                    </div>
                  </div>
                )}
              </form>

              {conteoRegistrado && <Cuadre cargos={cargos} cuadra={cuadra} veces={veces} />}
              {registro.estado === 'CONTEO_REGISTRADO' && (
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('ACTA')}>Continuar con el acta</button>
                </div>
              )}
            </>
          )}

          {/* ── 9-13: confirmar el escrutinio y generar el acta ── */}
          {paso === 'ACTA' && detalle.puedeEmitir && (
            <form className="panel cv-form" onSubmit={(e) => { e.preventDefault(); setConfirmando('ACTA'); }}>
              <div className="cv-section-head">
                <div>
                  <h3>Confirmar el escrutinio (RF85)</h3>
                  <p className="muted">El acta lleva la hora de inicio y fin, los votos por lista, en blanco, nulos e impugnados, el total, las observaciones y las firmas de los miembros. Se emite con QR y huella SHA-256 y ya no se modifica (RN28).</p>
                </div>
              </div>

              {cuadra && totalCuadra && (
                <div className="es-validacion ok" role="status">
                  <MenuIcon name="check" size={18} />
                  <div><strong>El conteo manual coincide con el digital y con los electores que votaron</strong><span>Puede confirmar el escrutinio.</span></div>
                </div>
              )}
              {necesitaRecuento && (
                <div className="es-validacion faltan" role="alert">
                  <MenuIcon name="alert" size={18} />
                  <div>
                    <strong>A3 · El conteo manual difiere del digital</strong>
                    <span>Recuente las cédulas y registre otra vez el conteo antes de confirmar.</span>
                  </div>
                  <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => setPaso('CONTEO')}>Volver al conteo</button>
                </div>
              )}
              {exigePrevalencia && (
                <>
                  <div className="es-validacion sobran" role="alert">
                    <MenuIcon name="alert" size={18} />
                    <div>
                      <strong>A3 · La diferencia persiste tras {veces - 1} recuento(s)</strong>
                      <span>Prevalece la cédula física (RF84): el acta registra el conteo manual y detalla la diferencia con el digital.</span>
                    </div>
                  </div>
                  <label className="im-check">
                    <input type="checkbox" checked={datosActa.prevaleceFisica} disabled={!soyPresidente || saving}
                      onChange={(e) => setDatosActa((d) => ({ ...d, prevaleceFisica: e.target.checked }))} />
                    <span>Confirmo que prevalece la cédula física y que la diferencia se detalla en la observación</span>
                  </label>
                </>
              )}
              {cuadra && !totalCuadra && (
                <div className="es-validacion faltan" role="status">
                  <MenuIcon name="alert" size={18} />
                  <div>
                    <strong>RF82 · El total de votos no es igual al de electores que votaron</strong>
                    <span>{registro.observacionCedulas ? 'Se explica con la observación del conteo de cédulas.' : 'Registre la observación.'}</span>
                  </div>
                </div>
              )}

              <label className="cv-field">
                <span className="cv-label">Observaciones{obsObligatoria ? ' (obligatorias)' : ''}</span>
                <textarea rows={3} maxLength={1000} required={obsObligatoria} value={datosActa.observaciones} disabled={!puedeOperar || !soyPresidente || saving}
                  placeholder="Ej.: una cédula de la Lista A tenía una marca adicional y se calificó nula; tras el recuento prevalece la cédula física."
                  onChange={(e) => setDatosActa((d) => ({ ...d, observaciones: e.target.value }))} />
                <small className="muted">{saldraObservada ? 'El acta se emitirá marcada como OBSERVADA (A5).' : 'Sin observaciones, el acta se emite sin marca.'}</small>
              </label>

              <div className="cs-firmantes">
                <h4>Firman el acta</h4>
                <ul>
                  {firmantes.map((f) => (
                    <li key={f.cargo}>
                      <MenuIcon name="check" size={14} />
                      <span><strong>{f.nombre}</strong> · {CARGO[f.cargo]} de mesa ({ORIGEN[f.origen]})</span>
                    </li>
                  ))}
                  {detalle.personeros.map((p) => (
                    <li key={p.idPersonero}>
                      <label className="im-check">
                        <input type="checkbox" checked={personeros.includes(p.idPersonero)} disabled={!puedeOperar || !soyPresidente || saving}
                          onChange={(e) => setPersoneros((l) => (e.target.checked ? [...l, p.idPersonero] : l.filter((x) => x !== p.idPersonero)))} />
                        <span>{p.nombre} · personero {TIPO_PERSONERO[p.tipo] ?? p.tipo} de {p.lista} (si desea firmar)</span>
                      </label>
                    </li>
                  ))}
                </ul>
                {detalle.personeros.length === 0 && <p className="muted im-nota">No hay personeros presentes en la mesa.</p>}
              </div>

              {puedeOperar && !soyPresidente && <p className="muted im-nota">Confirma el escrutinio el presidente en funciones: {presidencia?.nombre}.</p>}
              {puedeOperar && soyPresidente && confirmando !== 'ACTA' && (
                <div className="cv-actions">
                  <button type="submit" className="cv-btn cv-btn-success" disabled={saving || !actaLista}>
                    <MenuIcon name="file" size={15} /> Confirmar escrutinio y generar acta
                  </button>
                </div>
              )}
              {confirmando === 'ACTA' && (
                <div className="cq-confirmar-emision" role="alert">
                  <div>
                    <strong>¿Emitir el acta de escrutinio de la mesa {mesa.numero}?</strong>
                    <span>
                      {cargos.map((c) => `${c.nombre}: ${c.totalManual ?? 0} votos`).join(' · ')} · firman {firmantes.length + personeros.length}
                      {saldraObservada ? ' · OBSERVADA' : ''}. El escrutinio termina y el acta ya no podrá modificarse.
                    </span>
                  </div>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                    <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={confirmarEscrutinio}>
                      <MenuIcon name="check" size={15} /> {saving ? 'Emitiendo…' : 'Confirmar y firmar'}
                    </button>
                  </div>
                </div>
              )}
            </form>
          )}

          {(paso === 'ACTA' || paso === 'ENTREGA') && detalle.acta && <ActaVista acta={detalle.acta} emitida={emitida} />}

          {/* ── Paso 9 de la tabla 38: entrega al CEUNP (RF86, RF87) ── */}
          {paso === 'ENTREGA' && detalle.acta && (
            detalle.puedeEntregar ? (
              <form className="panel cv-form" onSubmit={(e) => { e.preventDefault(); setConfirmando('ENTREGA'); }}>
                <div className="cv-section-head">
                  <div>
                    <h3>Entrega de actas y material al CEUNP (RF86, RF87)</h3>
                    <p className="muted">Imprima los tres ejemplares del acta electoral (CEUNP, ONPE y local de votación) y las copias que pidan los personeros. Entregue al CEUNP las actas, el padrón con la lista de firmas y el material, y registre quién los recibe.</p>
                  </div>
                </div>
                <div className="es-ejemplares">
                  {EJEMPLARES.map((e) => (
                    <label key={e} className="im-check">
                      <input type="checkbox" checked={entrega.ejemplares.includes(e)} disabled={!puedeOperar || !soyPresidente || saving}
                        onChange={(ev) => setEntrega((d) => ({ ...d, ejemplares: ev.target.checked ? [...d.ejemplares, e] : d.ejemplares.filter((x) => x !== e) }))} />
                      <span>Ejemplar {e}</span>
                    </label>
                  ))}
                </div>
                <div className="im-cedulas">
                  <label className="cv-field">
                    <span className="cv-label">Recibe por el CEUNP</span>
                    <input type="text" maxLength={150} required value={entrega.recibidoPor} placeholder="Nombre y cargo de quien recibe"
                      disabled={!puedeOperar || !soyPresidente || saving} onChange={(e) => setEntrega((d) => ({ ...d, recibidoPor: e.target.value }))} />
                  </label>
                  <label className="cv-field">
                    <span className="cv-label">Copias simples para personeros</span>
                    <input type="number" min={0} max={50} value={entrega.copiasPersoneros} disabled={!puedeOperar || !soyPresidente || saving}
                      onChange={(e) => setEntrega((d) => ({ ...d, copiasPersoneros: e.target.value }))} />
                  </label>
                </div>
                <div className="es-ejemplares">
                  <label className="im-check">
                    <input type="checkbox" checked={entrega.entregaPadron} disabled={!puedeOperar || !soyPresidente || saving}
                      onChange={(e) => setEntrega((d) => ({ ...d, entregaPadron: e.target.checked }))} />
                    <span>Padrón de la mesa con la lista de firmas</span>
                  </label>
                  <label className="im-check">
                    <input type="checkbox" checked={entrega.entregaMaterial} disabled={!puedeOperar || !soyPresidente || saving}
                      onChange={(e) => setEntrega((d) => ({ ...d, entregaMaterial: e.target.checked }))} />
                    <span>Material electoral (ánfora, cédulas no utilizadas y útiles)</span>
                  </label>
                </div>
                <label className="cv-field">
                  <span className="cv-label">Observación{!(entrega.entregaPadron && entrega.entregaMaterial) ? ' (obligatoria)' : ''}</span>
                  <textarea rows={2} maxLength={500} value={entrega.observacion} disabled={!puedeOperar || !soyPresidente || saving}
                    required={!(entrega.entregaPadron && entrega.entregaMaterial)} placeholder="Ej.: el ánfora se entrega lacrada."
                    onChange={(e) => setEntrega((d) => ({ ...d, observacion: e.target.value }))} />
                </label>
                {puedeOperar && !soyPresidente && <p className="muted im-nota">Registra la entrega el presidente en funciones o el CEUNP.</p>}
                {puedeOperar && soyPresidente && confirmando !== 'ENTREGA' && (
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirActaEscrutinio(detalle.acta, emitida?.idActa === detalle.acta.idActa ? emitida.tokenQr : null)}>
                      <MenuIcon name="file" size={15} /> Imprimir tres ejemplares
                    </button>
                    <button type="submit" className="cv-btn cv-btn-success" disabled={saving || !entregaLista}>
                      <MenuIcon name="upload" size={15} /> Registrar entrega al CEUNP
                    </button>
                  </div>
                )}
                {confirmando === 'ENTREGA' && (
                  <div className="cq-confirmar-emision" role="alert">
                    <div>
                      <strong>¿Registrar la entrega al CEUNP de la mesa {mesa.numero}?</strong>
                      <span>Recibe {entrega.recibidoPor}: 3 ejemplares, {n(entrega.copiasPersoneros)} copia(s) para personeros{entrega.entregaPadron ? ', padrón' : ''}{entrega.entregaMaterial ? ' y material' : ''}. Con esto termina el escrutinio de la mesa.</span>
                    </div>
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                      <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={registrarEntrega}>
                        <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar entrega'}
                      </button>
                    </div>
                  </div>
                )}
              </form>
            ) : registro?.estado === 'ENTREGADA' && (
              <div className="panel cv-form">
                <div className="cv-section-head">
                  <div>
                    <h3>Actas entregadas al CEUNP</h3>
                    <p className="muted">Cargo de entrega N.º {registro.codigoCargo} · {fecha(registro.fechaEntrega)}</p>
                  </div>
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => imprimirCargoEntrega(mesa, registro, detalle.acta)}>
                    <MenuIcon name="file" size={15} /> Imprimir cargo de entrega
                  </button>
                </div>
                <dl className="cq-meta">
                  <div><dt>Recibió</dt><dd>{registro.recibidoPor}</dd></div>
                  <div><dt>Ejemplares</dt><dd>{registro.ejemplares} (CEUNP, ONPE y local)</dd></div>
                  <div><dt>Copias para personeros</dt><dd>{registro.copiasPersoneros}</dd></div>
                  <div><dt>Padrón</dt><dd>{si(registro.entregaPadron) ? 'Entregado' : 'No entregado'}</dd></div>
                  <div><dt>Material</dt><dd>{si(registro.entregaMaterial) ? 'Entregado' : 'No entregado'}</dd></div>
                  <div><dt>Registró</dt><dd>{registro.entregadoPor ?? '—'}</dd></div>
                  {registro.observacionEntrega && <div className="es-ancho"><dt>Observación</dt><dd>{registro.observacionEntrega}</dd></div>}
                </dl>
              </div>
            )
          )}
        </>
      )}
    </div>
  );
}

/** 8 mostrarCuadre(): conteo manual contra digital por opción (RF82, RF83, A3, A4). */
function Cuadre({ cargos, cuadra, veces }) {
  return (
    <div className={`panel cv-form es-cuadre ${cuadra ? 'ok' : 'mal'}`}>
      <div className="cv-section-head">
        <div>
          <h3>Cuadre con el conteo digital (RF83)</h3>
          <p className="muted">
            {cuadra
              ? 'El conteo manual coincide con los votos digitales de la mesa. Las cédulas impugnadas faltan en su opción hasta que se resuelvan (A4).'
              : veces < 2
                ? 'A3: hay diferencias por opción. Recuente las cédulas de las opciones marcadas y registre el conteo otra vez.'
                : 'A3: la diferencia persiste tras el recuento. Prevalece la cédula física y la diferencia se detalla en el acta (RF84).'}
          </p>
        </div>
        <span className={`cv-estado ${cuadra ? 'votacion' : 'anulado'}`}>{cuadra ? 'Cuadra' : 'Difiere'}</span>
      </div>
      {cargos.map((c) => (
        <div key={c.idCargo} className="table-wrap">
          <table>
            <thead>
              <tr><th>{c.nombre}</th><th className="es-n">Manual</th><th className="es-n">Digital</th><th className="es-n">Diferencia</th></tr>
            </thead>
            <tbody>
              {c.conteo.map((k) => (
                <tr key={`${k.opcion}-${k.idLista ?? 0}`} className={k.opcion !== 'IMPUGNADO' && k.diferencia !== 0 ? 'es-difiere' : ''}>
                  <td>{k.opcion === 'LISTA' ? <strong>{k.ordenCedula != null ? `${k.ordenCedula}. ` : ''}{k.nombre}</strong> : OPCION[k.opcion]}</td>
                  <td className="es-n">{k.votosManual}</td>
                  <td className="es-n">{k.opcion === 'IMPUGNADO' ? '—' : k.votosDigital}</td>
                  <td className={`es-n es-dif${k.diferencia > 0 ? ' mas' : k.diferencia < 0 ? ' menos' : ''}`}>
                    {k.opcion === 'IMPUGNADO' ? '—' : conSigno(k.diferencia)}
                  </td>
                </tr>
              ))}
              <tr className="es-total">
                <td>Total · votaron {c.votantes}{c.totalCuadra ? '' : ' (RF82: no coincide)'}</td>
                <td className="es-n">{c.totalManual}</td>
                <td className="es-n">{c.totalDigital}</td>
                <td className="es-n">{c.cuadra ? <span className="cv-estado votacion">Cuadra</span> : <span className="cv-estado anulado">Difiere</span>}</td>
              </tr>
            </tbody>
          </table>
        </div>
      ))}
    </div>
  );
}

/** 13 mostrarActaGenerada(): resultados, firmas y, solo al emitirse, el QR de verificación. */
function ActaVista({ acta, emitida }) {
  const c = acta.contenido ?? {};
  const token = emitida && emitida.idActa === acta.idActa ? emitida.tokenQr : null;
  return (
    <div className={`panel cv-form im-acta${c.observada ? ' es-observada' : ''}`}>
      <div className="cv-section-head">
        <div>
          <h3>Acta de Escrutinio N.º {String(acta.idActa).padStart(6, '0')}{c.observada ? ' · OBSERVADA' : ''}</h3>
          <p className="muted">Emitida el {fecha(acta.fechaEmision)} · estado {acta.estado}</p>
        </div>
        <div className="cs-acciones-head">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirCopiaPersonero(acta, token)}>
            <MenuIcon name="file" size={15} /> Copia para personero
          </button>
          <button type="button" className="cv-btn cv-btn-primary" onClick={() => imprimirActaEscrutinio(acta, token)}>
            <MenuIcon name="file" size={15} /> Imprimir tres ejemplares
          </button>
        </div>
      </div>

      <div className="im-acta-cuerpo">
        <dl className="cq-meta">
          <div><dt>Inicio</dt><dd>{c.hora_inicio}</dd></div>
          <div><dt>Fin</dt><dd>{c.hora_fin}</dd></div>
          <div><dt>Votaron</dt><dd>{c.electores_que_votaron}</dd></div>
          <div><dt>Cédulas escrutadas</dt><dd>{c.cedulas_escrutadas} de {c.cedulas_contadas}</dd></div>
          <div><dt>Recuentos</dt><dd>{c.recuentos}</dd></div>
          <div><dt>Conciliación</dt><dd>{c.conteo_coincide_digital ? 'Coincide con el digital' : 'Prevalece la cédula física'}</dd></div>
          <div><dt>Impugnaciones</dt><dd>{(c.impugnaciones ?? []).length}</dd></div>
          <div><dt>Acta</dt><dd>{c.observada ? 'Observada (A5)' : 'Sin observaciones'}</dd></div>
        </dl>
        {token && (
          <div className="im-acta-qr">
            <CodigoQR valor={urlVerificacionActa(token)} size={150} titulo="QR de verificación del acta" />
            <small>Este QR se muestra solo ahora: imprima los ejemplares para conservarlo.</small>
          </div>
        )}
      </div>

      {(c.resultados ?? []).map((r) => (
        <div key={r.id_cargo} className="table-wrap">
          <table>
            <thead><tr><th>{r.cargo}</th><th className="es-n">Votos</th><th className="es-n">Digital</th></tr></thead>
            <tbody>
              {r.opciones.map((o) => (
                <tr key={`${o.opcion}-${o.id_lista ?? 0}`}>
                  <td>{o.opcion === 'LISTA' ? <strong>{o.orden != null ? `${o.orden}. ` : ''}{o.nombre}</strong> : o.nombre}</td>
                  <td className="es-n">{o.manual}</td>
                  <td className="es-n">{o.opcion === 'IMPUGNADO' ? '—' : o.digital}</td>
                </tr>
              ))}
              <tr className="es-total"><td>Total de votos emitidos · votaron {r.votantes}</td><td className="es-n">{r.total}</td><td className="es-n">{r.total_digital}</td></tr>
            </tbody>
          </table>
        </div>
      ))}

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
      {c.observacion_cedulas && <p className="im-nota"><strong>Cédulas:</strong> {c.observacion_cedulas}</p>}
      {c.observaciones && <p className="im-nota"><strong>Observaciones:</strong> {c.observaciones}</p>}
      <p className="muted im-nota">Huella SHA-256 del contenido: <code className="im-hash">{acta.hashIntegridad}</code></p>
    </div>
  );
}
