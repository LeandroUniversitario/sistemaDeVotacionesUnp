import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { EscanerQR, fecha } from '../credenciales/LectorQR';
import { ESTADO_RESULTADO } from '../computo/ActaComputo';
import {
  DECISION_COTEJO, ESTADO_COTEJO, METODO, RESULTADO_VERIFICACION, ROL_USUARIO, TIPO_DOCUMENTO, pct,
  imprimirConstanciaVerificacion, imprimirCotejo, imprimirResultados, imprimirResultadosMesas,
} from './ReporteResultados';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../cierre/cierre.css';
import '../impugnaciones/impugnaciones.css';
import '../computo/computo.css';
import '../nulidades/nulidades.css';
import './resultados.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS17 · Consultar resultados y verificar actas — «PantallaResultados» (boundary).
 * Actores: docente elector y personero de mesa (también miembros de mesa, CEUNP, ADMIN y el
 * portal público sin sesión, con publico = true).
 *
 * Mensajes del diagrama «Colaboration - Consultar resultados y verificar actas»:
 *   1 seleccionarProceso() DocenteElector → PantallaResultados              (selector de proceso)
 *   2 obtenerResultados() → consultarResultados · 3 verificarComputoCerrado() ProcesoElectoral
 *   4 consultarResultados() ResultadoElectoral · 5 devolverResultados()     (pestañas Resultados y Por mesa)
 *   6 mostrarResultados()
 *   7 escanearQR Personero de mesa → PantallaResultados                      (pestaña Verificar acta)
 *   8 verificarActa() → verificarActa · 9 consultarPorToken() ActaElectoral
 *   10 recalcularHash() · 11 mostrarAutenticidad()
 *
 * Además: cotejo del ejemplar físico con el documento digital y discrepancias que atiende el
 * CEUNP (pestaña Cotejos). RF52 QR en cada acta · RF55 consulta pública de autenticidad · RF99
 * resultados solo después de su publicación.
 */

const PASOS = [
  { codigo: 'RESULTADOS', texto: 'Resultados', nota: 'Por cargo y lista · RF99', icono: 'trophy' },
  { codigo: 'MESAS', texto: 'Resultados por mesa', nota: 'Votos y actas de cada mesa', icono: 'table' },
  { codigo: 'VERIFICAR', texto: 'Verificar acta', nota: 'QR o huella SHA-256 · RF55', icono: 'qr' },
  { codigo: 'COTEJOS', texto: 'Cotejos', nota: 'Ejemplar físico vs. digital', icono: 'scale', sesion: true },
];
const CLASE_RESULTADO = { ELEGIDO: 'votacion', SEGUNDA_VUELTA: 'inscripcion', EMPATE: 'creado', SIN_QUORUM: 'anulado', DESIERTO: 'anulado', PENDIENTE: 'creado' };
const CLASE_COTEJO = { CONFORME: 'votacion', OBSERVADO: 'creado', ATENDIDO: 'inscripcion' };
const COLOR_COTEJO = { CONFORME: '#059669', OBSERVADO: '#d97706', ATENDIDO: '#2563eb' };
const ACTAS_MESA = ['ACTA_INSTALACION', 'ACTA_SUFRAGIO', 'ACTA_ESCRUTINIO'];
const CORTO = { ACTA_INSTALACION: 'Instalación', ACTA_SUFRAGIO: 'Sufragio', ACTA_ESCRUTINIO: 'Escrutinio' };
const si = (v) => v === true || v === 1;
const codigoDe = (texto) => {
  const hallados = String(texto ?? '').match(/[0-9a-fA-F]{64}/g);
  return hallados ? hallados[hallados.length - 1].toLowerCase() : null;
};

/** Pestaña inicial según el rol: el personero viene a verificar actas; el docente, a ver resultados. */
function pasoInicial(rol, codigoInicial) {
  if (codigoInicial) return 'VERIFICAR';
  return rol === 'PERSONERO' || rol === 'MIEMBRO_MESA' ? 'VERIFICAR' : 'RESULTADOS';
}

export default function PantallaResultados({ session, publico = false, codigoInicial = null, procesoInicial = null, onSessionExpired, onIniciarSesion }) {
  const base = publico ? '/api/publico/consulta' : '/api/resultados';
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [errorDetalle, setErrorDetalle] = useState(null);
  const [paso, setPaso] = useState(pasoInicial(session?.rol, codigoInicial));
  // El código del QR se verifica una sola vez aunque el efecto se monte dos veces (StrictMode)
  const codigoConsultado = useRef(false);
  const [idCargoMesa, setIdCargoMesa] = useState(null);
  const [buscarMesa, setBuscarMesa] = useState('');
  const [verificacion, setVerificacion] = useState(null);
  const [codigoVerificado, setCodigoVerificado] = useState(null);
  const [historial, setHistorial] = useState([]);
  const [cotejo, setCotejo] = useState(null);          // { fisico: {clave: valor}, comparado, observacion, confirmando }
  const [resultadoCotejo, setResultadoCotejo] = useState(null);
  const [filtroCotejo, setFiltroCotejo] = useState('TODOS');
  const [idCotejo, setIdCotejo] = useState(null);
  const [atencion, setAtencion] = useState({ decision: '', respuesta: '', confirmando: false });
  const [cargando, setCargando] = useState(true);
  const [verificando, setVerificando] = useState(false);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  /** 2 obtenerResultados() → 3 verificarComputoCerrado() → 4 consultarResultados() → 5 devolverResultados(). */
  const cargarDetalle = useCallback(async (id) => {
    setErrorDetalle(null);
    if (!id) {
      setDetalle(null);
      return null;
    }
    try {
      const d = await apiRequest(`${base}/procesos/${id}`);
      setDetalle(d);
      setIdCargoMesa((actual) => (d.cargos.some((c) => c.idCargo === actual) ? actual : d.cargos[0]?.idCargo ?? null));
      return d;
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
      setDetalle(null);
      setErrorDetalle(e.message);
      return null;
    }
  }, [base, onSessionExpired]);

  // ─── 7-11 Verificar acta ──────────────────────────────────────────────────

  const verificar = useCallback(async (entrada, canal) => {
    const codigo = codigoDe(entrada);
    setVerificando(true);
    setFeedback(null);
    setCotejo(null);
    setResultadoCotejo(null);
    try {
      const c = canal ?? (/\/(verificar|api\/publico)\//.test(String(entrada)) ? 'QR' : 'CODIGO');
      const data = publico
        ? await apiRequest(`/api/publico/verificacion/${encodeURIComponent(codigo ?? String(entrada).trim().slice(0, 120))}`)
        : await apiRequest('/api/resultados/verificacion', { method: 'POST', body: JSON.stringify({ codigo: String(entrada), canal: c }) });
      setVerificacion(data);
      setCodigoVerificado(codigo);
      setHistorial((h) => [{ hora: new Date(), codigo, ...data }, ...h].slice(0, 10));
      setPaso('VERIFICAR');
      return data;
    } catch (e) {
      manejarError(e);
      return null;
    } finally {
      setVerificando(false);
    }
  }, [publico, manejarError]);

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest(`${base}/procesos`);
        setProcesos(lista);
        const elegido = lista.find((p) => p.id === Number(procesoInicial))?.id ?? lista[0]?.id ?? null;
        setIdProceso(elegido);
        await cargarDetalle(elegido);
        if (codigoInicial && !codigoConsultado.current) {
          codigoConsultado.current = true;
          await verificar(codigoInicial, 'QR');
        }
      } catch (e) {
        manejarError(e);
      } finally {
        setCargando(false);
      }
    })();
    // Solo al abrir la pantalla
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function cambiarProceso(id) {
    setIdProceso(id);
    setFeedback(null);
    setIdCotejo(null);
    setBuscarMesa('');
    await cargarDetalle(id);
  }

  async function refrescar() {
    try {
      setProcesos(await apiRequest(`${base}/procesos`));
      await cargarDetalle(idProceso);
    } catch (e) {
      manejarError(e);
    }
  }

  function irA(codigo) {
    setPaso(codigo);
    setFeedback(null);
  }

  // ─── Cotejo del ejemplar físico ───────────────────────────────────────────

  function iniciarCotejo() {
    setResultadoCotejo(null);
    setCotejo({ fisico: Object.fromEntries(verificacion.cifras.map((c) => [c.clave, ''])), comparado: false, observacion: '', confirmando: false });
  }

  const comparacion = useMemo(() => {
    if (!cotejo || !verificacion) return null;
    const lineas = verificacion.cifras.map((c) => {
      const valor = cotejo.fisico[c.clave];
      const anotada = valor !== '' && valor != null;
      return { ...c, fisico: anotada ? Number(valor) : null, anotada, coincide: anotada && Number(valor) === Number(c.digital) };
    });
    return {
      lineas,
      completas: lineas.every((l) => l.anotada && Number.isInteger(l.fisico) && l.fisico >= 0),
      diferencias: lineas.filter((l) => l.anotada && !l.coincide).length,
    };
  }, [cotejo, verificacion]);

  async function registrarCotejo() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest('/api/resultados/cotejos', {
        method: 'POST',
        body: JSON.stringify({
          codigo: codigoVerificado,
          idVerificacion: verificacion.idVerificacion,
          cifras: comparacion.lineas.map((l) => ({ clave: l.clave, fisico: l.fisico })),
          observacion: cotejo.observacion.trim() || null,
        }),
      });
      setResultadoCotejo(data);
      setCotejo(null);
      setFeedback({ type: data.cotejo.estado === 'CONFORME' ? 'success' : 'error', text: data.mensaje });
      await cargarDetalle(idProceso);
    } catch (e) {
      manejarError(e);
      setCotejo((c) => (c ? { ...c, confirmando: false } : c));
    } finally {
      setSaving(false);
    }
  }

  async function atenderCotejo() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/resultados/cotejos/${idCotejo}/atencion`, {
        method: 'POST', body: JSON.stringify({ decision: atencion.decision, respuesta: atencion.respuesta }),
      });
      setFeedback({ type: 'success', text: data.mensaje });
      setAtencion({ decision: '', respuesta: '', confirmando: false });
      await cargarDetalle(idProceso);
    } catch (e) {
      manejarError(e);
      setAtencion((a) => ({ ...a, confirmando: false }));
    } finally {
      setSaving(false);
    }
  }

  // ─── Datos derivados ─────────────────────────────────────────────────────

  const documentos = useMemo(() => detalle?.documentos ?? [], [detalle]);
  const actasPorMesa = useMemo(() => {
    const mapa = {};
    documentos.filter((d) => d.idMesa && ACTAS_MESA.includes(d.tipoDocumento)).forEach((d) => {
      (mapa[d.idMesa] ??= {})[d.tipoDocumento] = d;
    });
    return mapa;
  }, [documentos]);
  const cargoMesa = detalle?.cargos.find((c) => c.idCargo === idCargoMesa) ?? detalle?.cargos[0];
  const mesasFiltradas = useMemo(() => {
    const t = buscarMesa.trim().toLowerCase();
    return (detalle?.mesas ?? []).filter((m) => !t || `${m.numeroMesa} ${m.ubicacion ?? ''}`.toLowerCase().includes(t));
  }, [detalle, buscarMesa]);
  const cotejos = detalle?.cotejos ?? [];
  const cotejosFiltrados = cotejos.filter((k) => filtroCotejo === 'TODOS' || k.estado === filtroCotejo);
  const seleccionado = cotejos.find((k) => k.idCotejo === idCotejo) ?? null;
  const pasos = PASOS.filter((p) => !p.sesion || !publico);

  if (cargando) return <div className="panel"><p className="muted">Cargando resultados…</p></div>;

  const p = detalle?.proceso;
  const nulo = p?.resultado === 'NULIDAD_TOTAL';
  const ver = detalle?.verificaciones ?? {};
  const infoVer = verificacion ? RESULTADO_VERIFICACION[verificacion.resultado] ?? RESULTADO_VERIFICACION.NO_ENCONTRADA : null;
  const observados = cotejos.filter((k) => k.estado === 'OBSERVADO').length;

  const cuenta = (codigo) => {
    if (!detalle) return 0;
    switch (codigo) {
      case 'RESULTADOS': return detalle.cargos.length;
      case 'MESAS': return detalle.mesas.length;
      case 'VERIFICAR': return documentos.length;
      case 'COTEJOS': return cotejos.length;
      default: return 0;
    }
  };

  return (
    <div className={`pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell rs-shell mx${publico ? ' rs-publico' : ''}`}>
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">1 seleccionarProceso · proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))} disabled={!procesos.length}>
            {!procesos.length && <option value="">Sin resultados publicados</option>}
            {procesos.map((x) => (
              <option key={x.id} value={x.id}>
                {x.nombre} · {x.tipo === 'SEGUNDA_VUELTA' ? '2.ª vuelta · ' : ''}{x.resultado === 'NULIDAD_TOTAL' ? 'nulidad total' : `${pct(x.participacionPct)} de participación`}
              </option>
            ))}
          </select>
        </label>
        <div className={`in-plazo ${p ? (nulo ? 'closed' : 'open') : 'closed'}`}>
          <MenuIcon name={p ? 'trophy' : 'lock'} size={18} />
          <div>
            <strong>{p ? (p.origen === 'CUS14' ? `Resultados publicados · ${fecha(p.fechaPublicacion)}` : `Cómputo oficial · ${fecha(p.fechaComputo)}`) : 'Sin resultados que mostrar'}</strong>
            <span>{p ? `3 verificarComputoCerrado: ${p.origen === 'CUS14' ? `cómputo publicado por el CEUNP${p.numeroResolucion ? ` · ${p.numeroResolucion}` : ''}` : 'cómputo heredado (sin sesión de cómputo)'} · RF99` : 'RF99: los resultados se muestran después de su publicación por el CEUNP.'}</span>
          </div>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      <div className="pd-tabs cq-tabs mx-pasos cp-pasos nl-pasos rs-pasos" role="tablist" aria-label="Consultar resultados y verificar actas"
        style={{ '--rs-pasos': pasos.length }}>
        {pasos.map((x) => {
          const n = cuenta(x.codigo);
          const alerta = x.codigo === 'COTEJOS' && observados > 0 && detalle?.puedeAtender;
          return (
            <button key={x.codigo} type="button" role="tab" aria-selected={paso === x.codigo}
              className={`pd-tab mx-paso${paso === x.codigo ? ' on' : ''}${alerta ? ' nl-alerta' : ''}`} onClick={() => irA(x.codigo)}>
              <span className="mx-paso-num"><MenuIcon name={x.icono} size={14} /></span>
              <span className="mx-paso-texto"><b>{x.texto}{n ? <em className="nl-cuenta">{n}</em> : null}</b><small>{x.nota}</small></span>
            </button>
          );
        })}
      </div>

      {p && (
        <section className="cq-resumen">
          <div className="cq-kpi" style={{ '--cq-color': nulo ? '#e11d48' : '#059669' }}>
            <span>Resultado <em>{p.tipo === 'SEGUNDA_VUELTA' ? '2.ª vuelta' : '1.ª vuelta'}</em></span>
            <strong className="cp-etapa">{nulo ? 'Nulidad total' : 'Elección válida'}</strong>
            <small>{p.numeroResolucion ? `Proclamación ${p.numeroResolucion}` : `Cómputo del ${fecha(p.fechaComputo)}`}</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
            <span>Participación <em>RN31</em></span>
            <strong>{pct(p.participacionPct)}</strong>
            <small>{p.votaron ?? 0} de {p.electoresHabiles ?? 0} electores · mínimo {pct(p.quorumMinimo)}</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#6366f1' }}>
            <span>Mesas <em>RF99</em></span>
            <strong>{p.mesasComputadas ?? detalle.mesas.length}<small> / {p.mesasTotal ?? p.mesas}</small></strong>
            <small>{p.mesasAnuladas ? `${p.mesasAnuladas} anulada(s) · ` : ''}{p.mesasNoInstaladas ? `${p.mesasNoInstaladas} no instalada(s)` : 'con resultados por mesa'}</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': Number(ver.alteradas) > 0 ? '#e11d48' : '#0ea5e9' }}>
            <span>Verificaciones <em>RF55</em></span>
            <strong>{ver.total ?? 0}</strong>
            <small>{ver.autenticas ?? 0} auténtica(s){Number(ver.alteradas) > 0 ? ` · ${ver.alteradas} alterada(s)` : ''} · {documentos.length} documento(s) con QR</small>
          </div>
        </section>
      )}

      {feedback && <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>}
      {errorDetalle && paso !== 'VERIFICAR' && (
        <div className="mx-mensaje aviso" role="note"><MenuIcon name="lock" size={18} /><div><p>{errorDetalle}</p></div></div>
      )}
      {!procesos.length && paso !== 'VERIFICAR' && (
        <div className="panel"><p className="empty-state">Aún no hay resultados publicados. El CEUNP los publica después del cómputo y la proclamación (RF99). Puede verificar un acta con su QR en «Verificar acta».</p></div>
      )}

      {/* ── 6 mostrarResultados(): resultados por cargo ── */}
      {paso === 'RESULTADOS' && detalle && (
        <>
          {nulo && (
            <div className="mx-mensaje peligro" role="note">
              <MenuIcon name="alert" size={18} />
              <div><h4>Elección declarada nula</h4><p>La participación no alcanzó el mínimo o el CEUNP declaró la nulidad total (RN31, RN34). La resolución se comunica a SUNEDU, la Asamblea Universitaria y el Consejo Universitario.</p></div>
            </div>
          )}
          {detalle.segundaVuelta.length > 0 && (
            <div className="mx-mensaje info" role="note">
              <MenuIcon name="calendar" size={18} />
              <div><h4>Segunda vuelta convocada (RN33)</h4>
                <ul className="cp-lista">{detalle.segundaVuelta.map((s) => <li key={s.id}>{s.nombre} · {fecha(s.fechaInicio)} · {s.estado}</li>)}</ul>
              </div>
            </div>
          )}
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>4 consultarResultados · resultados por cargo</h3>
                <p className="muted">Votos de cada lista sobre los votos válidos, con los votos en blanco y nulos. {p.origen === 'CUS14' ? 'Son los resultados del cómputo general que el CEUNP proclamó y publicó.' : 'Resultados del cómputo oficial.'} Ninguna cifra revela el voto de un docente.</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirResultados(detalle)}>
                  <MenuIcon name="file" size={15} /> Imprimir resultados
                </button>
              </div>
            </div>
            {detalle.cargos.map((c) => {
              const ganadora = c.listas.find((l) => l.ganadora);
              return (
                <div key={c.idCargo} className="cp-cargo rs-cargo">
                  <div className="cp-cargo-head">
                    <h4>{c.cargo}</h4>
                    <span className={`cv-estado ${CLASE_RESULTADO[c.estadoResultado] ?? 'creado'}`}>{ESTADO_RESULTADO[c.estadoResultado] ?? c.estadoResultado}</span>
                  </div>
                  {ganadora && (
                    <div className="rs-ganadora">
                      <MenuIcon name="trophy" size={20} />
                      <div>
                        <strong>{ganadora.lista}</strong>
                        <span>{ganadora.votos} votos · {pct(ganadora.porcentajeValidos)} de los válidos{c.codigoCredencial ? ` · credencial ${c.codigoCredencial}` : ''}</span>
                        {ganadora.formula && <small>{ganadora.formula.replaceAll('_', ' ').toLowerCase()}</small>}
                      </div>
                    </div>
                  )}
                  <ul className="rs-barras">
                    {c.listas.map((l) => (
                      <li key={l.idLista} className={l.ganadora ? 'gana' : ''}>
                        <span><b>{l.posicion}.</b> {l.lista}</span>
                        <i style={{ '--rs-umbral': `${c.porcentajeMinimoVictoria ?? 50}%` }}><b style={{ width: `${Math.min(100, Number(l.porcentajeValidos ?? 0))}%` }} /></i>
                        <strong>{pct(l.porcentajeValidos)}</strong>
                        <em>{l.votos}</em>
                      </li>
                    ))}
                  </ul>
                  <dl className="rs-totales">
                    <div><dt>Válidos</dt><dd>{c.validos}</dd></div>
                    <div><dt>En blanco</dt><dd>{c.blancos}</dd></div>
                    <div><dt>Nulos</dt><dd>{c.nulos}</dd></div>
                    <div><dt>Emitidos</dt><dd>{c.emitidos}</dd></div>
                    <div><dt>Participación</dt><dd>{pct(c.participacionPct)}</dd></div>
                  </dl>
                  <p className="muted cp-nota">Para ganar en {p.tipo === 'SEGUNDA_VUELTA' ? 'segunda vuelta se requiere la mitad más uno' : `primera vuelta se requiere más del ${pct(c.porcentajeMinimoVictoria)}`} de los votos válidos (RF96, RF97). La línea marca ese mínimo.</p>
                </div>
              );
            })}
          </div>
          {detalle.nulidades.length > 0 && (
            <div className="panel cv-form">
              <div className="cv-section-head"><div><h3>Resoluciones de nulidad publicadas (RF102)</h3><p className="muted">Mesas o elección anuladas por el Pleno del CEUNP (CUS15).</p></div></div>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Resolución</th><th>Alcance</th><th>Mesa</th><th>Causal</th><th>Fecha</th></tr></thead>
                  <tbody>{detalle.nulidades.map((n) => (
                    <tr key={n.idNulidad}><td><strong>{n.numeroResolucion}</strong></td><td>{n.alcance === 'TOTAL' ? 'Total' : 'Parcial'}</td><td>{n.numeroMesa ?? '—'}</td>
                      <td>{String(n.causal).replaceAll('_', ' ').toLowerCase()}</td><td>{fecha(n.fechaResolucion)}</td></tr>
                  ))}</tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}

      {/* ── 5 devolverResultados(): resultados por mesa y sus actas ── */}
      {paso === 'MESAS' && detalle && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Resultados por mesa</h3>
              <p className="muted">Cifras del acta de escrutinio de cada mesa con las impugnaciones resueltas (CUS12, CUS13). Cada mesa muestra sus tres actas: el check indica que su huella SHA-256 coincide con el contenido; «Verificar» registra la consulta (RF55).</p>
            </div>
            <div className="cs-acciones-head">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirResultadosMesas(detalle, cargoMesa?.idCargo)} disabled={!cargoMesa}>
                <MenuIcon name="file" size={15} /> Imprimir por mesa
              </button>
            </div>
          </div>
          <div className="rs-filtros">
            {detalle.cargos.length > 1 && (
              <div className="cq-chips" role="group" aria-label="Cargo">
                {detalle.cargos.map((c) => (
                  <button key={c.idCargo} type="button" className={`cq-chip${cargoMesa?.idCargo === c.idCargo ? ' on' : ''}`} onClick={() => setIdCargoMesa(c.idCargo)}>{c.cargo}</button>
                ))}
              </div>
            )}
            <label className="rs-buscar">
              <MenuIcon name="search" size={14} />
              <input value={buscarMesa} onChange={(e) => setBuscarMesa(e.target.value)} placeholder="N.º de mesa o local" aria-label="Buscar mesa" />
            </label>
          </div>
          {cargoMesa && (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Mesa</th><th className="n">Votaron</th>
                    {cargoMesa.listas.map((l) => <th key={l.idLista} className="n" title={l.lista}>{l.simbolo ? `${l.simbolo} · ` : ''}{l.lista.length > 22 ? `${l.lista.slice(0, 22)}…` : l.lista}</th>)}
                    <th className="n">Blanco</th><th className="n">Nulo</th><th className="n">Total</th><th>Actas (RF52)</th>
                  </tr>
                </thead>
                <tbody>
                  {mesasFiltradas.map((m) => {
                    const c = m.cargos.find((x) => x.idCargo === cargoMesa.idCargo);
                    const votos = (opcion, idLista) => c?.opciones.find((o) => o.opcion === opcion && (opcion !== 'LISTA' || o.idLista === idLista))?.votos ?? 0;
                    const actas = actasPorMesa[m.idMesa] ?? {};
                    const anulada = m.estadoMesa === 'ANULADA';
                    return (
                      <tr key={m.idMesa} className={anulada ? 'rs-anulada' : ''}>
                        <td><strong>Mesa {m.numeroMesa}</strong><small className="pd-sub">{anulada ? 'Anulada (CUS15): no se computa' : m.ubicacion}</small></td>
                        <td className="n">{m.votaron ?? '—'}<small className="pd-sub">de {m.electores ?? '—'}</small></td>
                        {cargoMesa.listas.map((l) => <td key={l.idLista} className="n">{votos('LISTA', l.idLista)}</td>)}
                        <td className="n">{votos('BLANCO')}</td><td className="n">{votos('NULO')}</td>
                        <td className="n"><strong>{c?.total ?? 0}</strong></td>
                        <td>
                          <div className="rs-actas">
                            {ACTAS_MESA.map((t) => {
                              const a = actas[t];
                              if (!a) return <span key={t} className="rs-acta falta" title={`${TIPO_DOCUMENTO[t]}: no emitida`}>{CORTO[t]}</span>;
                              return (
                                <button key={t} type="button" className={`rs-acta ${si(a.integra) ? 'ok' : 'mal'}`} disabled={verificando}
                                  title={`${TIPO_DOCUMENTO[t]} · ${si(a.integra) ? 'huella coincide' : 'huella NO coincide'} · verificar`}
                                  onClick={() => verificar(a.hashIntegridad, 'LISTA')}>
                                  <MenuIcon name={si(a.integra) ? 'check' : 'alert'} size={12} /> {CORTO[t]}
                                </button>
                              );
                            })}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                  {mesasFiltradas.length === 0 && <tr><td colSpan={cargoMesa.listas.length + 6} className="muted">Ninguna mesa coincide con la búsqueda.</td></tr>}
                </tbody>
              </table>
            </div>
          )}
          <p className="muted cp-nota">Fuente: {detalle.mesas[0]?.fuente === 'URNA_DIGITAL' ? 'conteo de la urna digital (cierre sin escrutinio manual).' : 'acta de escrutinio de cada mesa (conteo manual que prevalece, RF84).'}</p>
        </div>
      )}

      {/* ── 7 escanearQR · 8 verificarActa · 11 mostrarAutenticidad ── */}
      {paso === 'VERIFICAR' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>7 escanearQR · verificar la autenticidad de un acta</h3>
                <p className="muted">Lea con la cámara o la pistola lectora el QR de cualquier documento del proceso (actas de instalación, sufragio y escrutinio, acta general de cómputo, resolución de proclamación, de nulidad o de multas, o la constancia de voto). Si el QR no se puede leer, escriba la huella SHA-256 impresa al pie del documento. El sistema recalcula la huella del documento digital y la compara con la registrada al emitirlo (RF55).</p>
              </div>
            </div>
            <EscanerQR onCodigo={(c) => verificar(c)} deshabilitado={verificando} />
            {verificando && <p className="muted">8 verificarActa · 9 consultarPorToken · 10 recalcularHash…</p>}
          </div>

          {verificacion && (
            <div className={`panel cv-form rs-verificacion ${infoVer.clase}`}>
              <div className={`cq-resultado ${infoVer.clase === 'ok' ? 'ok' : 'mal'} rs-resultado-${infoVer.clase}`} role="status" aria-live="polite">
                <div className="cq-resultado-head">
                  <span className="cq-resultado-icono"><MenuIcon name={infoVer.icono} size={22} /></span>
                  <div>
                    <strong>11 mostrarAutenticidad · {infoVer.titulo}</strong>
                    <span>{verificacion.mensaje}</span>
                  </div>
                </div>
                {verificacion.resultado !== 'NO_ENCONTRADA' && (
                  <dl className="cq-meta">
                    <div><dt>Documento</dt><dd>{TIPO_DOCUMENTO[verificacion.tipoDocumento] ?? verificacion.tipoDocumento}</dd></div>
                    <div><dt>Proceso</dt><dd>{verificacion.proceso}</dd></div>
                    <div><dt>Mesa</dt><dd>{verificacion.numeroMesa ? `${verificacion.numeroMesa} · ${verificacion.ubicacion ?? ''}` : '—'}</dd></div>
                    <div><dt>Emitido</dt><dd>{fecha(verificacion.fechaEmision)}</dd></div>
                    <div><dt>Estado</dt><dd>{verificacion.estado}</dd></div>
                    {verificacion.numeroResolucion && <div><dt>Resolución</dt><dd>{verificacion.numeroResolucion}</dd></div>}
                    <div><dt>Firmas</dt><dd>{verificacion.firmas || '—'}</dd></div>
                    <div><dt>Verificado por</dt><dd>{METODO[verificacion.metodo]} · {verificacion.vecesVerificado === 1 ? '1.ª consulta' : `${verificacion.vecesVerificado} consultas`}</dd></div>
                  </dl>
                )}
              </div>

              {verificacion.hashGuardado && (
                <div className="rs-hashes">
                  <h4>10 recalcularHash()</h4>
                  <div><span>Huella registrada al emitir</span><code>{verificacion.hashGuardado}</code></div>
                  <div><span>Huella recalculada ahora</span><code className={si(verificacion.contenidoIntegro) ? 'ok' : 'mal'}>{verificacion.hashRecalculado}</code></div>
                </div>
              )}

              <ContenidoDocumento verificacion={verificacion} />

              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirConstanciaVerificacion(verificacion, codigoVerificado)}>
                  <MenuIcon name="file" size={15} /> Imprimir constancia de verificación
                </button>
                {verificacion.idProceso && verificacion.idProceso !== idProceso && procesos.some((x) => x.id === verificacion.idProceso) && (
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => { cambiarProceso(verificacion.idProceso); setPaso('RESULTADOS'); }}>
                    <MenuIcon name="trophy" size={15} /> Ver resultados del proceso
                  </button>
                )}
                {verificacion.puedeCotejar && !cotejo && (
                  <button type="button" className="cv-btn cv-btn-primary" onClick={iniciarCotejo}>
                    <MenuIcon name="scale" size={15} /> Cotejar con mi ejemplar físico
                  </button>
                )}
                {publico && verificacion.cifras?.length > 0 && (
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={onIniciarSesion}>
                    <MenuIcon name="login" size={15} /> Inicie sesión para cotejar su ejemplar
                  </button>
                )}
              </div>

              {cotejo && (
                <div className="ig-form rs-cotejo">
                  <h4>Cotejo del ejemplar físico</h4>
                  <p className="muted">Anote las cifras tal como figuran en su ejemplar impreso (copia del personero o de la mesa) y pulse «Comparar». Si alguna no coincide, describa la discrepancia: queda reportada al CEUNP.</p>
                  <div className="table-wrap">
                    <table>
                      <thead><tr><th>Grupo</th><th>Concepto</th><th className="n">Ejemplar físico</th>{cotejo.comparado && <><th className="n">Documento digital</th><th>¿Coincide?</th></>}</tr></thead>
                      <tbody>
                        {comparacion.lineas.map((l) => (
                          <tr key={l.clave} className={cotejo.comparado && !l.coincide ? 'rs-difiere' : ''}>
                            <td>{l.grupo}</td><td>{l.etiqueta}</td>
                            <td className="n">
                              <input type="number" min="0" step="1" className="rs-cifra" value={cotejo.fisico[l.clave]} aria-label={`${l.grupo} ${l.etiqueta}`}
                                onChange={(e) => setCotejo((x) => ({ ...x, comparado: false, confirmando: false, fisico: { ...x.fisico, [l.clave]: e.target.value } }))} />
                            </td>
                            {cotejo.comparado && <><td className="n">{l.digital}</td><td>{l.coincide ? <span className="cv-estado votacion">Coincide</span> : <span className="cv-estado anulado">Difiere</span>}</td></>}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  {cotejo.comparado && (comparacion.diferencias > 0 || !si(verificacion.contenidoIntegro)) && (
                    <label className="cv-field">
                      <span className="cv-label">Discrepancia que reporta al CEUNP (obligatoria)</span>
                      <textarea rows={3} maxLength={1000} value={cotejo.observacion} placeholder="Ej.: en mi copia del acta de la mesa 001 la Lista A tiene 14 votos, firmada por el presidente y el secretario."
                        onChange={(e) => setCotejo((x) => ({ ...x, observacion: e.target.value, confirmando: false }))} />
                    </label>
                  )}
                  {!cotejo.confirmando ? (
                    <div className="cv-actions cp-izq">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setCotejo(null)}>Cancelar</button>
                      <button type="button" className="cv-btn cv-btn-primary" disabled={!comparacion.completas}
                        onClick={() => setCotejo((x) => ({ ...x, comparado: true }))}>
                        <MenuIcon name="scale" size={15} /> Comparar
                      </button>
                      {cotejo.comparado && (
                        <button type="button" className={`cv-btn ${comparacion.diferencias ? 'cv-btn-danger' : 'cv-btn-success'}`}
                          disabled={(comparacion.diferencias > 0 || !si(verificacion.contenidoIntegro)) && cotejo.observacion.trim().length < 10}
                          onClick={() => setCotejo((x) => ({ ...x, confirmando: true }))}>
                          <MenuIcon name={comparacion.diferencias ? 'alert' : 'check'} size={15} /> {comparacion.diferencias ? 'Reportar discrepancia al CEUNP' : 'Registrar cotejo conforme'}
                        </button>
                      )}
                    </div>
                  ) : (
                    <div className="cq-confirmar-emision" role="alert">
                      <div>
                        <strong>{comparacion.diferencias ? `¿Reportar ${comparacion.diferencias} diferencia(s) al CEUNP?` : '¿Registrar el cotejo conforme?'}</strong>
                        <span>El cotejo queda registrado a su nombre ({ROL_USUARIO[session?.rol] ?? session?.rol}) y no se puede modificar.</span>
                      </div>
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setCotejo((x) => ({ ...x, confirmando: false }))}>Volver</button>
                        <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={registrarCotejo}>
                          <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar'}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {resultadoCotejo && (
                <div className={`mx-mensaje ${resultadoCotejo.cotejo.estado === 'CONFORME' ? 'info' : 'aviso'}`} role="note">
                  <MenuIcon name={resultadoCotejo.cotejo.estado === 'CONFORME' ? 'check' : 'alert'} size={18} />
                  <div>
                    <h4>Cotejo N.º {resultadoCotejo.cotejo.idCotejo} · {ESTADO_COTEJO[resultadoCotejo.cotejo.estado]}</h4>
                    <p>{resultadoCotejo.mensaje}</p>
                    <div className="cv-actions cp-izq">
                      <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirCotejo({ ...resultadoCotejo.cotejo, ...verificacion, lineas: resultadoCotejo.lineas, estado: resultadoCotejo.cotejo.estado, idCotejo: resultadoCotejo.cotejo.idCotejo, fecha: new Date(), registradoPor: session?.username, rol: session?.rol, hashIntegridad: verificacion.hashGuardado })}>
                        <MenuIcon name="file" size={13} /> Imprimir cotejo
                      </button>
                      <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => irA('COTEJOS')}>Ver mis cotejos</button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {detalle && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Documentos con QR del proceso (RF52)</h3>
                  <p className="muted">Documentos de «{p.proceso}» con su huella SHA-256. La integridad se recalcula al consultar; «Verificar» hace la consulta completa y la registra.</p>
                </div>
              </div>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Documento</th><th>Mesa</th><th>Emitido</th><th>Huella SHA-256</th><th>Integridad</th><th className="n">Verif.</th><th className="n">Cotejos</th><th /></tr></thead>
                  <tbody>
                    {documentos.map((d) => (
                      <tr key={`${d.tipoDocumento}-${d.idDocumento}`}>
                        <td><strong>{TIPO_DOCUMENTO[d.tipoDocumento] ?? d.tipoDocumento}</strong>{d.numeroResolucion && <small className="pd-sub">{d.numeroResolucion}</small>}</td>
                        <td>{d.numeroMesa ?? 'General'}</td>
                        <td>{fecha(d.fechaEmision)}<small className="pd-sub">{d.estado}</small></td>
                        <td><code className="rs-huella" title={d.hashIntegridad}>{d.hashIntegridad?.slice(0, 16)}…</code></td>
                        <td><span className={`cv-estado ${si(d.integra) ? 'votacion' : 'anulado'}`}>{si(d.integra) ? 'Íntegra' : 'Alterada'}</span></td>
                        <td className="n">{d.verificaciones}</td>
                        <td className="n">{d.cotejos}{d.observados ? <small className="pd-sub rs-obs">{d.observados} observado(s)</small> : null}</td>
                        <td><button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={verificando} onClick={() => verificar(d.hashIntegridad, 'LISTA')}>Verificar</button></td>
                      </tr>
                    ))}
                    {documentos.length === 0 && <tr><td colSpan={8} className="muted">El proceso no tiene documentos con QR.</td></tr>}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {historial.length > 0 && (
            <div className="panel cv-form">
              <div className="cv-section-head"><div><h3>Verificaciones de esta sesión</h3></div></div>
              <ul className="rs-historial">
                {historial.map((h) => {
                  const r = RESULTADO_VERIFICACION[h.resultado] ?? RESULTADO_VERIFICACION.NO_ENCONTRADA;
                  return (
                    <li key={h.idVerificacion} className={r.clase}>
                      <MenuIcon name={r.icono} size={14} />
                      <span>{h.hora.toLocaleTimeString('es-PE')}</span>
                      <strong>{TIPO_DOCUMENTO[h.tipoDocumento] ?? 'Código desconocido'}{h.numeroMesa ? ` · mesa ${h.numeroMesa}` : ''}</strong>
                      <em>{r.titulo}</em>
                    </li>
                  );
                })}
              </ul>
            </div>
          )}
        </>
      )}

      {/* ── Cotejos y discrepancias ── */}
      {paso === 'COTEJOS' && !publico && detalle && (
        <>
          <section className="rs-estados">
            {['TODOS', 'OBSERVADO', 'ATENDIDO', 'CONFORME'].map((e) => (
              <button key={e} type="button" className={`rs-estado${filtroCotejo === e ? ' on' : ''}`} style={{ '--rs-color': COLOR_COTEJO[e] ?? '#64748b' }} onClick={() => setFiltroCotejo(e)}>
                <span>{e === 'TODOS' ? 'Todos' : ESTADO_COTEJO[e]}</span>
                <strong>{e === 'TODOS' ? cotejos.length : cotejos.filter((k) => k.estado === e).length}</strong>
                <small>{e === 'OBSERVADO' ? (detalle.puedeAtender ? 'Por atender' : 'En revisión del CEUNP') : e === 'ATENDIDO' ? 'Con respuesta' : e === 'CONFORME' ? 'Cifras iguales' : detalle.supervisa ? 'Del proceso' : 'Registrados por usted'}</small>
              </button>
            ))}
          </section>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>{detalle.supervisa ? 'Cotejos del proceso' : 'Mis cotejos'}</h3>
                <p className="muted">{detalle.puedeAtender
                  ? 'Discrepancias que personeros y docentes reportaron al cotejar su ejemplar con el documento digital. Atiéndalas: aclarada (se anotó o leyó mal) o fundada (procede revisar el acta en el cómputo o tramitar la nulidad).'
                  : 'Cotejos que registró al comparar su ejemplar impreso con el documento digital y la respuesta del CEUNP a las discrepancias.'}</p>
              </div>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th>N.º</th><th>Documento</th><th>Registrado por</th><th className="n">Diferencias</th><th>Estado</th><th>Fecha</th><th /></tr></thead>
                <tbody>
                  {cotejosFiltrados.map((k) => (
                    <tr key={k.idCotejo} className={k.idCotejo === idCotejo ? 'rs-sel' : ''}>
                      <td>{String(k.idCotejo).padStart(5, '0')}</td>
                      <td><strong>{TIPO_DOCUMENTO[k.tipoDocumento] ?? k.tipoDocumento}</strong><small className="pd-sub">{k.numeroMesa ? `Mesa ${k.numeroMesa}` : 'General'}</small></td>
                      <td>{k.registradoPor ?? k.username}<small className="pd-sub">{ROL_USUARIO[k.rol] ?? k.rol}{k.listaPersonero ? ` · ${k.listaPersonero}` : ''}</small></td>
                      <td className="n">{k.diferencias} / {k.lineas}{!si(k.contenidoIntegro) && <small className="pd-sub rs-obs">huella alterada</small>}</td>
                      <td><span className={`cv-estado ${CLASE_COTEJO[k.estado]}`}>{ESTADO_COTEJO[k.estado]}</span>{k.decision && <small className="pd-sub">{DECISION_COTEJO[k.decision]}</small>}</td>
                      <td>{fecha(k.fecha)}</td>
                      <td>
                        <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => { setIdCotejo(k.idCotejo === idCotejo ? null : k.idCotejo); setAtencion({ decision: '', respuesta: '', confirmando: false }); }}>
                          {k.estado === 'OBSERVADO' && detalle.puedeAtender ? 'Atender' : 'Ver'}
                        </button>
                      </td>
                    </tr>
                  ))}
                  {cotejosFiltrados.length === 0 && <tr><td colSpan={7} className="muted">{cotejos.length ? 'Ningún cotejo con ese estado.' : 'Aún no hay cotejos. Verifique un acta y pulse «Cotejar con mi ejemplar físico».'}</td></tr>}
                </tbody>
              </table>
            </div>
          </div>

          {seleccionado && (
            <div className="panel cv-form mx-ficha">
              <div className="mx-ficha-top">
                <div>
                  <h3>Cotejo N.º {String(seleccionado.idCotejo).padStart(5, '0')} · {TIPO_DOCUMENTO[seleccionado.tipoDocumento]}{seleccionado.numeroMesa ? ` de la mesa ${seleccionado.numeroMesa}` : ''}</h3>
                  <p>{seleccionado.registradoPor ?? seleccionado.username} · {ROL_USUARIO[seleccionado.rol]} · {fecha(seleccionado.fecha)}</p>
                </div>
                <span className={`cv-estado ${CLASE_COTEJO[seleccionado.estado]}`}>{ESTADO_COTEJO[seleccionado.estado]}</span>
              </div>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Grupo</th><th>Concepto</th><th className="n">Documento digital</th><th className="n">Ejemplar físico</th><th>¿Coincide?</th></tr></thead>
                  <tbody>
                    {(seleccionado.cifras ?? []).map((l) => (
                      <tr key={l.clave} className={l.coincide ? '' : 'rs-difiere'}>
                        <td>{l.grupo}</td><td>{l.etiqueta}</td><td className="n">{l.digital}</td><td className="n">{l.fisico}</td>
                        <td>{l.coincide ? <span className="cv-estado votacion">Coincide</span> : <span className="cv-estado anulado">Difiere</span>}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {seleccionado.observacion && <p className="ig-texto"><strong>Discrepancia reportada:</strong> {seleccionado.observacion}</p>}
              {seleccionado.respuesta && (
                <div className="mx-mensaje info" role="note"><MenuIcon name="info" size={18} />
                  <div><h4>Respuesta del CEUNP · {DECISION_COTEJO[seleccionado.decision]}</h4><p>{seleccionado.respuesta}</p><small>{seleccionado.atendidoPor} · {fecha(seleccionado.fechaRespuesta)}</small></div>
                </div>
              )}
              {seleccionado.estado === 'OBSERVADO' && detalle.puedeAtender && (
                <div className="ig-form rs-cotejo">
                  <h4>Atender la discrepancia</h4>
                  <div className="cq-chips" role="group" aria-label="Decisión">
                    {Object.entries(DECISION_COTEJO).map(([v, t]) => (
                      <button key={v} type="button" className={`cq-chip${atencion.decision === v ? ' on' : ''}`} onClick={() => setAtencion((a) => ({ ...a, decision: v, confirmando: false }))}>{t}</button>
                    ))}
                  </div>
                  <label className="cv-field">
                    <span className="cv-label">Respuesta del CEUNP</span>
                    <textarea rows={3} maxLength={1000} value={atencion.respuesta} placeholder="Ej.: se revisó el ejemplar del CEUNP y el acta digital coincide; la copia del personero tiene un error de transcripción."
                      onChange={(e) => setAtencion((a) => ({ ...a, respuesta: e.target.value, confirmando: false }))} />
                  </label>
                  {!atencion.confirmando ? (
                    <div className="cv-actions cp-izq">
                      <button type="button" className="cv-btn cv-btn-primary" disabled={!atencion.decision || atencion.respuesta.trim().length < 10}
                        onClick={() => setAtencion((a) => ({ ...a, confirmando: true }))}>
                        <MenuIcon name="check" size={15} /> Registrar respuesta
                      </button>
                    </div>
                  ) : (
                    <div className="cq-confirmar-emision" role="alert">
                      <div>
                        <strong>¿Registrar la discrepancia como {DECISION_COTEJO[atencion.decision].toLowerCase()}?</strong>
                        <span>La respuesta no se modifica. {atencion.decision === 'FUNDADA' ? 'Revise luego el acta en «Cómputo y proclamación» o tramite la nulidad (CUS15).' : ''}</span>
                      </div>
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAtencion((a) => ({ ...a, confirmando: false }))}>Volver</button>
                        <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={atenderCotejo}>
                          <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar'}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              )}
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirCotejo(seleccionado)}><MenuIcon name="file" size={15} /> Imprimir cotejo</button>
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setIdCotejo(null)}>Cerrar</button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

/** Resumen legible del contenido del documento verificado. */
function ContenidoDocumento({ verificacion }) {
  const doc = verificacion.contenido;
  if (!doc || verificacion.resultado === 'NO_ENCONTRADA') return null;
  const tipo = verificacion.tipoDocumento;

  if (tipo === 'CONSTANCIA_VOTO') {
    return <p className="ig-texto">Constancia de participación de <strong>{doc.docente}</strong> en la elección de {doc.cargo}. La constancia acredita que votó; nunca por quién.</p>;
  }
  if (tipo === 'RESOLUCION_MULTAS') {
    return <p className="ig-texto">Resolución {doc.resolucion}: {doc.omisos_votacion} multa(s) por omisión al sufragio y {doc.omisos_mesa} por inasistencia a la mesa, por S/ {Number(doc.monto_total).toFixed(2)} (UIT S/ {Number(doc.uit).toFixed(2)}). La relación de docentes no es pública.</p>;
  }
  if (verificacion.cifras?.length) {
    const grupos = verificacion.cifras.reduce((g, c) => ({ ...g, [c.grupo]: [...(g[c.grupo] ?? []), c] }), {});
    return (
      <div className="rs-contenido">
        <h4>9 consultarPorToken · contenido del documento digital</h4>
        <div className="rs-grupos">
          {Object.entries(grupos).map(([grupo, lineas]) => (
            <div key={grupo} className="rs-grupo">
              <span>{grupo}</span>
              <dl>{lineas.map((l) => <div key={l.clave}><dt>{l.etiqueta}</dt><dd>{l.digital}</dd></div>)}</dl>
            </div>
          ))}
        </div>
        {doc.observaciones && <p className="ig-texto"><strong>Observaciones del acta:</strong> {doc.observaciones}</p>}
      </div>
    );
  }
  return doc.fundamento || doc.causal ? (
    <p className="ig-texto">{doc.causal ? `Causal: ${String(doc.causal).replaceAll('_', ' ').toLowerCase()}. ` : ''}{doc.fundamento ?? ''}</p>
  ) : null;
}
