import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { fecha } from '../credenciales/LectorQR';
import { imprimirConstanciaImpugnacion, imprimirRelacionImpugnaciones } from './ConstanciaImpugnacion';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import '../cierre/cierre.css';
import './impugnaciones.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS13 · Gestionar impugnaciones y apelaciones — «PantallaImpugnaciones» (boundary).
 * Actores: Personero de mesa, Presidente de mesa y CEUNP.
 *
 * Mensajes del diagrama «Colaboration - Gestionar impugnaciones y apelaciones»:
 *   1 ingresarImpugnacion(id_mesa, motivo) → 2 registrarImpugnacion(datos) → RegistrarImpugnacion
 *     3 verificarAcreditacion(id_personero) · 4 insertar(id_personero, id_mesa, motivo) · 5 confirmarRegistro()
 *   6 registrarDecisionMesa(id_impugnacion, decision) → 7 resolverEnMesa(datos) → ResolverImpugnacion
 *     8 actualizarDecisionMesa(decision) · 9 notificarDecision()
 *   10 [decision rechazada] apelarDecision(id_impugnacion) → TramitarApelacion
 *   11 registrarFalloCEUNP(id_impugnacion, decision) → 12 resolverApelacion(id_impugnacion, decision)
 *     13 actualizarDecisionCEUNP(decision, 'RESUELTA') · 14 notificarFalloFinal()
 *
 * Reglas: RN24 (solo personeros de mesa impugnan), RN23 (la mesa decide por mayoría; el CEUNP
 * resuelve la apelación en segunda y última instancia) y RN36 (quórum del Pleno, voto dirimente,
 * fallo inapelable).
 */

const ESTADO_MESA = {
  PENDIENTE: { clase: 'creado', texto: 'Por instalar' },
  INSTALADA: { clase: 'votacion', texto: 'Sufragio abierto' },
  CERRADA: { clase: 'inscripcion', texto: 'Sufragio cerrado' },
  NO_INSTALADA: { clase: 'anulado', texto: 'No instalada' },
  ANULADA: { clase: 'anulado', texto: 'Anulada' },
};
const SITUACION = {
  PENDIENTE_MESA: { clase: 'creado', texto: 'Por resolver en mesa' },
  APELABLE: { clase: 'inscripcion', texto: 'Plazo de apelación' },
  EN_APELACION: { clase: 'anulado', texto: 'En apelación (CEUNP)' },
  FIRME: { clase: 'votacion', texto: 'Firme' },
};
const DECISION_MESA = { PENDIENTE: 'Pendiente', ACEPTADA: 'Fundada', RECHAZADA: 'Infundada' };
const DECISION_CEUNP = { PENDIENTE: 'Pendiente', CONFIRMADA: 'Confirmada', MODIFICADA: 'Modificada' };
const TIPO_PERSONERO = { MESA: 'de mesa', GENERAL: 'general', ALTERNO: 'alterno' };
const FILTROS = [
  { codigo: 'APELADAS', texto: 'Apelaciones por resolver' },
  { codigo: 'PENDIENTES', texto: 'Por resolver en mesa' },
  { codigo: 'FIRMES', texto: 'Firmes' },
  { codigo: 'TODAS', texto: 'Todas' },
];
const PASOS = [
  { codigo: 'PRESENTADA', texto: 'Impugnación', nota: 'Personero de mesa (RN24)' },
  { codigo: 'MESA', texto: 'Decisión de la mesa', nota: 'Primera instancia (RN23)' },
  { codigo: 'APELACION', texto: 'Apelación', nota: 'Solo si es infundada (RF81)' },
  { codigo: 'FALLO', texto: 'Fallo del CEUNP', nota: 'Última instancia (RN36)' },
];
const vacioDecision = { decision: '', votosFavor: '', votosContra: '', opcion: '', idLista: '', fundamento: '' };
const vacioFallo = (quorum) => ({
  decision: '', numeroResolucion: '', miembrosPleno: String(quorum ?? 5), votosFavor: '', votosContra: '',
  votoDirimente: '', opcion: '', idLista: '', fundamento: '',
});

function textoOpcion(opcion, lista) {
  if (opcion === 'LISTA') return lista ? `Lista ${lista}` : 'Lista';
  if (opcion === 'BLANCO') return 'Voto en blanco';
  if (opcion === 'NULO') return 'Voto nulo';
  if (opcion === 'IMPUGNADO') return 'Impugnado (sin asignar)';
  return '—';
}

/** Estado de cada paso del trámite: hecho, en curso (on) u omitido (no corresponde). */
function estadoPaso(codigo, i) {
  const sinApelacion = !i.fechaApelacion && (i.decisionMesa === 'ACEPTADA' || (i.decisionMesa === 'RECHAZADA' && i.situacion === 'FIRME'));
  switch (codigo) {
    case 'PRESENTADA':
      return { hecho: true, texto: 'Registrada' };
    case 'MESA':
      return i.decisionMesa === 'PENDIENTE' ? { on: true, texto: 'En curso' } : { hecho: true, texto: DECISION_MESA[i.decisionMesa] };
    case 'APELACION':
      if (i.fechaApelacion) return { hecho: true, texto: 'Elevada al CEUNP' };
      if (i.decisionMesa === 'ACEPTADA') return { omitido: true, texto: 'No corresponde (fundada)' };
      if (sinApelacion) return { omitido: true, texto: 'No se apeló: firme' };
      if (i.decisionMesa === 'RECHAZADA') return { on: true, texto: 'Plazo abierto' };
      return {};
    case 'FALLO':
      if (i.decisionCeunp !== 'PENDIENTE') return { hecho: true, texto: DECISION_CEUNP[i.decisionCeunp] };
      if (i.estado === 'APELADA') return { on: true, texto: 'Por resolver' };
      if (sinApelacion) return { omitido: true, texto: 'No corresponde' };
      return {};
    default:
      return {};
  }
}

export default function PantallaImpugnaciones({ session, onSessionExpired }) {
  const esCeunp = session.rol === 'CEUNP';
  const esAdmin = session.rol === 'ADMIN';
  const supervisa = esCeunp || esAdmin;
  const esPersonero = session.rol === 'PERSONERO';

  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [vista, setVista] = useState(supervisa ? 'BANDEJA' : 'MESA');   // BANDEJA | MESA
  const [mesas, setMesas] = useState([]);
  const [idMesa, setIdMesa] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [bandeja, setBandeja] = useState(null);
  const [filtro, setFiltro] = useState('APELADAS');
  const [idSel, setIdSel] = useState(null);
  const [accion, setAccion] = useState(null);         // REGISTRAR | DECIDIR | APELAR | FALLAR
  const [confirmando, setConfirmando] = useState(false);
  const [nueva, setNueva] = useState({ idPersonero: '', idCargo: '', motivo: '' });
  const [decision, setDecision] = useState(vacioDecision);
  const [apelacion, setApelacion] = useState({ idPersonero: '', fundamento: '' });
  const [fallo, setFallo] = useState(vacioFallo(5));
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const cargarMesas = useCallback(async (proceso) => {
    const lista = await apiRequest(!supervisa || !proceso ? '/api/impugnaciones/mesas' : `/api/impugnaciones/mesas?procesoId=${proceso}`);
    setMesas(lista);
    return lista;
  }, [supervisa]);

  const cargarBandeja = useCallback(async (proceso) => {
    if (!supervisa || !proceso) return;
    setBandeja(await apiRequest(`/api/impugnaciones/bandeja?procesoId=${proceso}`));
  }, [supervisa]);

  useEffect(() => {
    (async () => {
      try {
        let proceso = null;
        if (supervisa) {
          const lista = await apiRequest('/api/impugnaciones/procesos');
          setProcesos(lista);
          proceso = lista[0]?.id ?? null;
          setIdProceso(proceso);
          await cargarBandeja(proceso);
        }
        const lista = await cargarMesas(proceso);
        const primera = lista.find((m) => m.porResolver > 0) ?? lista.find((m) => m.estado === 'CERRADA') ?? lista[0];
        if (primera) setIdMesa(primera.id);
      } catch (e) {
        manejarError(e);
      } finally {
        setCargando(false);
      }
    })();
  }, [supervisa, cargarMesas, cargarBandeja, manejarError]);

  useEffect(() => {
    if (!idMesa || vista !== 'MESA') return;
    (async () => {
      try {
        setDetalle(await apiRequest(`/api/impugnaciones/mesas/${idMesa}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idMesa, vista, manejarError]);

  function limpiarAccion() {
    setAccion(null);
    setConfirmando(false);
  }

  async function cambiarProceso(id) {
    setIdProceso(id);
    setIdMesa(null);
    setDetalle(null);
    setIdSel(null);
    limpiarAccion();
    setFeedback(null);
    try {
      await cargarBandeja(id);
      const lista = await cargarMesas(id);
      setIdMesa((lista.find((m) => m.porResolver > 0) ?? lista[0])?.id ?? null);
    } catch (e) {
      manejarError(e);
    }
  }

  function elegirMesa(id) {
    setIdMesa(id);
    setIdSel(null);
    limpiarAccion();
    setFeedback(null);
  }

  function elegirImpugnacion(i) {
    setIdSel(i.id);
    limpiarAccion();
    setDecision(vacioDecision);
    setApelacion({ idPersonero: '', fundamento: '' });
    setFallo(vacioFallo(bandeja?.quorumPleno));
  }

  async function refrescar() {
    try {
      if (supervisa) {
        setProcesos(await apiRequest('/api/impugnaciones/procesos'));
        await cargarBandeja(idProceso);
      }
      await cargarMesas(idProceso);
      if (idMesa && vista === 'MESA') setDetalle(await apiRequest(`/api/impugnaciones/mesas/${idMesa}`));
    } catch (e) {
      manejarError(e);
    }
  }

  async function ejecutar(promesa, alTerminar) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await promesa;
      if (data.detalle) setDetalle(data.detalle);
      setFeedback({ type: 'success', text: data.mensaje });
      alTerminar?.(data);
      limpiarAccion();
      if (supervisa) {
        await cargarBandeja(idProceso);
        setProcesos(await apiRequest('/api/impugnaciones/procesos'));
      }
      await cargarMesas(idProceso);
      return data;
    } catch (e) {
      manejarError(e);
      setConfirmando(false);
      return null;
    } finally {
      setSaving(false);
    }
  }

  /** 1 ingresarImpugnacion(id_mesa, motivo) → 2 registrarImpugnacion(datos) → 5 confirmarRegistro(). */
  function ingresarImpugnacion() {
    return ejecutar(apiRequest(`/api/impugnaciones/mesas/${idMesa}/impugnaciones`, {
      method: 'POST',
      body: JSON.stringify({
        idPersonero: nueva.idPersonero === '' ? null : Number(nueva.idPersonero),
        idCargo: nueva.idCargo === '' ? null : Number(nueva.idCargo),
        motivo: nueva.motivo,
      }),
    }), (data) => {
      setNueva({ idPersonero: '', idCargo: '', motivo: '' });
      if (data.idImpugnacion) setIdSel(data.idImpugnacion);
    });
  }

  /** 6 registrarDecisionMesa(id_impugnacion, decision) → 7 resolverEnMesa(datos) → 9 notificarDecision(). */
  function registrarDecisionMesa() {
    return ejecutar(apiRequest(`/api/impugnaciones/${idSel}/decision-mesa`, {
      method: 'POST',
      body: JSON.stringify({
        decision: decision.decision,
        votosFavor: decision.votosFavor === '' ? null : Number(decision.votosFavor),
        votosContra: decision.votosContra === '' ? null : Number(decision.votosContra),
        opcion: decision.opcion,
        idLista: decision.opcion === 'LISTA' && decision.idLista !== '' ? Number(decision.idLista) : null,
        fundamento: decision.fundamento,
      }),
    }), () => setDecision(vacioDecision));
  }

  /** 10 [decision rechazada] apelarDecision(id_impugnacion). */
  function apelarDecision() {
    return ejecutar(apiRequest(`/api/impugnaciones/${idSel}/apelacion`, {
      method: 'POST',
      body: JSON.stringify({
        idPersonero: apelacion.idPersonero === '' ? null : Number(apelacion.idPersonero),
        fundamento: apelacion.fundamento,
      }),
    }), () => setApelacion({ idPersonero: '', fundamento: '' }));
  }

  /** 11 registrarFalloCEUNP(id_impugnacion, decision) → 12 resolverApelacion → 14 notificarFalloFinal(). */
  function registrarFalloCeunp() {
    const modifica = fallo.decision === 'MODIFICADA';
    return ejecutar(apiRequest(`/api/impugnaciones/${idSel}/fallo`, {
      method: 'POST',
      body: JSON.stringify({
        decision: fallo.decision,
        numeroResolucion: fallo.numeroResolucion,
        miembrosPleno: Number(fallo.miembrosPleno),
        votosFavor: fallo.votosFavor === '' ? null : Number(fallo.votosFavor),
        votosContra: fallo.votosContra === '' ? null : Number(fallo.votosContra),
        votoDirimente: fallo.votoDirimente || null,
        opcion: modifica ? fallo.opcion : null,
        idLista: modifica && fallo.opcion === 'LISTA' && fallo.idLista !== '' ? Number(fallo.idLista) : null,
        fundamento: fallo.fundamento,
      }),
    }), () => setFallo(vacioFallo(bandeja?.quorumPleno)));
  }

  // ─── Datos derivados ─────────────────────────────────────────────────────

  const lista = useMemo(() => {
    if (vista === 'BANDEJA') {
      const todas = bandeja?.impugnaciones ?? [];
      if (filtro === 'APELADAS') return todas.filter((i) => i.estado === 'APELADA');
      if (filtro === 'PENDIENTES') return todas.filter((i) => i.decisionMesa === 'PENDIENTE');
      if (filtro === 'FIRMES') return todas.filter((i) => i.situacion === 'FIRME');
      return todas;
    }
    return detalle?.impugnaciones ?? [];
  }, [vista, bandeja, filtro, detalle]);

  const seleccionada = useMemo(() => {
    const fuente = vista === 'BANDEJA' ? bandeja?.impugnaciones : detalle?.impugnaciones;
    return fuente?.find((i) => i.id === idSel) ?? null;
  }, [vista, bandeja, detalle, idSel]);

  const cargosDisponibles = vista === 'BANDEJA' ? (bandeja?.cargos ?? []) : (detalle?.cargos ?? []);
  const listasDe = (idCargo) => {
    const cargo = cargosDisponibles.find((c) => c.idCargo === idCargo);
    if (cargo) return cargo.listas;
    return cargosDisponibles.flatMap((c) => c.listas);
  };

  if (cargando) return <div className="panel"><p className="muted">Cargando impugnaciones…</p></div>;

  const proceso = procesos.find((p) => p.id === idProceso);
  const mesa = detalle?.mesa;
  const resumen = vista === 'BANDEJA' ? bandeja?.resumen : detalle?.resumen;
  const miembros = detalle?.miembros?.length || 3;
  const quorum = bandeja?.quorumPleno ?? 5;
  const misPersonerosMesa = (detalle?.personeros ?? []).filter((p) => (detalle?.misPersoneros ?? []).some((m) => m.idPersonero === p.idPersonero));

  return (
    <div className="pd-shell cq-shell im-shell cs-shell ig-shell mx">
      <section className="in-head">
        {supervisa && (
          <label className="cv-field in-proceso">
            <span className="cv-label">Proceso electoral</span>
            <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))}>
              {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
            </select>
          </label>
        )}
        <div className="in-plazo open">
          <MenuIcon name="scale" size={18} />
          <div>
            <strong>{esPersonero ? 'Impugne votos durante el escrutinio de su mesa' : 'Impugnaciones de votos y apelaciones'}</strong>
            <span>RN24 solo impugnan los personeros de mesa · RN23 la mesa decide por mayoría · RN36 el CEUNP falla en última instancia</span>
          </div>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      {supervisa && (
        <div className="pd-tabs cq-tabs mx-pasos ig-vistas" role="tablist" aria-label="Vista">
          {[
            { codigo: 'BANDEJA', texto: 'Bandeja del CEUNP', nota: `${proceso?.apeladas ?? 0} apelación(es) por resolver`, icono: 'scale' },
            { codigo: 'MESA', texto: 'Por mesa de sufragio', nota: `${proceso?.mesas ?? 0} mesa(s)`, icono: 'table' },
          ].map((v) => (
            <button key={v.codigo} type="button" role="tab" aria-selected={vista === v.codigo}
              className={`pd-tab mx-paso${vista === v.codigo ? ' on' : ''}`}
              onClick={() => { setVista(v.codigo); setIdSel(null); limpiarAccion(); setFeedback(null); }}>
              <span className="mx-paso-num"><MenuIcon name={v.icono} size={14} /></span>
              <span className="mx-paso-texto"><b>{v.texto}</b><small>{v.nota}</small></span>
            </button>
          ))}
        </div>
      )}

      {resumen && (
        <section className="cq-resumen">
          <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
            <span>Impugnaciones <em>RF80</em></span>
            <strong>{resumen.total}</strong>
            <small>{resumen.aceptadas} fundada(s) · {resumen.rechazadas} infundada(s)</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#d97706' }}>
            <span>Por resolver en mesa <em>RN23</em></span>
            <strong>{resumen.porResolver}</strong>
            <small>se cuentan como IMPUGNADO (CUS12 A4)</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
            <span>En apelación <em>RF81</em></span>
            <strong>{resumen.apeladas}</strong>
            <small>{resumen.falladas} fallada(s) por el CEUNP</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#059669' }}>
            <span>Firmes <em>RN36</em></span>
            <strong>{resumen.firmes}<small> / {resumen.total}</small></strong>
            <i className="cq-barra"><b style={{ width: `${resumen.total ? Math.round((resumen.firmes / resumen.total) * 100) : 0}%` }} /></i>
          </div>
        </section>
      )}

      {vista === 'MESA' && (mesas.length === 0 ? (
        <div className="panel"><p className="empty-state">
          {esPersonero ? 'No está acreditado como personero en una mesa de un proceso en curso.'
            : session.rol === 'MIEMBRO_MESA' ? 'No figura como miembro de ninguna mesa de un proceso en curso.' : 'El proceso no tiene mesas.'}
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
                <small>{m.impugnaciones} impugnación(es){m.porResolver ? ` · ${m.porResolver} por resolver` : ''}{m.apeladas ? ` · ${m.apeladas} apelada(s)` : ''}</small>
                {!supervisa && <small>{m.proceso}</small>}
              </button>
            );
          })}
        </section>
      ))}

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}

      {/* ── Ficha de la mesa y registro (mensajes 1-5) ── */}
      {vista === 'MESA' && detalle && (
        <>
          <div className="panel mx-ficha">
            <div className="mx-ficha-top">
              <div>
                <h3>Mesa {mesa.numero}</h3>
                <p>{mesa.ubicacion}</p>
              </div>
              <span className={`cv-estado ${(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).clase}`}>
                {(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).texto}
              </span>
            </div>
            <dl className="mx-datos">
              <div><dt>Proceso</dt><dd>{mesa.proceso} · {mesa.estadoProceso}</dd></div>
              <div><dt>Escrutinio</dt><dd>{detalle.escrutinio ? String(detalle.escrutinio.estado).replaceAll('_', ' ').toLowerCase() : (mesa.estado === 'CERRADA' ? 'Por iniciar' : '—')}</dd></div>
              <div><dt>Miembros en funciones</dt><dd>{detalle.miembros.length ? detalle.miembros.map((m) => m.nombre.split(',')[0]).join(' · ') : '—'}</dd></div>
              <div><dt>Plazo para apelar</dt><dd>{detalle.plazoApelacionHoras > 0 ? `${detalle.plazoApelacionHoras} h desde la decisión` : 'Sin plazo'}</dd></div>
            </dl>
          </div>

          {mesa.estado !== 'CERRADA' && (
            <div className="mx-mensaje info" role="note">
              <MenuIcon name="info" size={18} />
              <div>
                <h4>Las impugnaciones se presentan en el escrutinio</h4>
                <p>La mesa {mesa.numero} está {(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).texto.toLowerCase()}. Se podrá impugnar un voto cuando se cierre el sufragio (CUS11) y la mesa cuente las cédulas (CUS12).</p>
              </div>
            </div>
          )}
          {!detalle.registroDisponible && (
            <div className="alert error" role="note">Falta instalar el escrutinio (CUS12): ejecute base-de-datos/11_escrutinio_conciliacion.sql para registrar impugnaciones.</div>
          )}
          {detalle.registroDisponible && !detalle.puedeRegistrar && detalle.motivoNoRegistra && mesa.estado === 'CERRADA' && !supervisa && (
            <div className="mx-mensaje info" role="note">
              <MenuIcon name="info" size={18} />
              <div>
                <h4>Registro de impugnaciones no disponible</h4>
                <p>{detalle.motivoNoRegistra} Las impugnaciones ya registradas se siguen tramitando aquí.</p>
              </div>
            </div>
          )}
          {supervisa && <div className="alert success" role="note">Vista de supervisión: las impugnaciones las presenta el personero de mesa y las resuelve primero la mesa. El CEUNP falla las apelaciones desde la bandeja.</div>}

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Impugnaciones de la mesa {mesa.numero}</h3>
                <p className="muted">Un personero de mesa impugna una cédula cuando el presidente la lee en el escrutinio. La cédula se cuenta como IMPUGNADA hasta que la mesa decida a qué opción va.</p>
              </div>
              <div className="cs-acciones-head">
                <span className="im-contador">{detalle.impugnaciones.length} registrada(s)</span>
                {detalle.impugnaciones.length > 0 && (
                  <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirRelacionImpugnaciones(mesa, detalle.impugnaciones)}>
                    <MenuIcon name="file" size={13} /> Imprimir relación
                  </button>
                )}
                {detalle.puedeRegistrar && accion !== 'REGISTRAR' && (
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => { setIdSel(null); setAccion('REGISTRAR'); setConfirmando(false); }}>
                    <MenuIcon name="plus" size={15} /> Registrar impugnación
                  </button>
                )}
              </div>
            </div>

            {accion === 'REGISTRAR' && (
              <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
                <h4>1 · Ingresar impugnación</h4>
                <div className="im-cedulas">
                  {esPersonero ? (
                    <div className="cv-field">
                      <span className="cv-label">Personero que impugna</span>
                      <p className="ig-fijo">{misPersonerosMesa.length ? `Usted · personero ${TIPO_PERSONERO[misPersonerosMesa[0].tipo] ?? ''} de ${misPersonerosMesa.map((p) => p.lista).join(', ')}` : '—'}</p>
                    </div>
                  ) : (
                    <label className="cv-field">
                      <span className="cv-label">Personero presente que impugna (RN24)</span>
                      <select required value={nueva.idPersonero} disabled={saving} onChange={(e) => setNueva((n) => ({ ...n, idPersonero: e.target.value }))}>
                        <option value="">Seleccione…</option>
                        {detalle.personeros.map((p) => (
                          <option key={p.idPersonero} value={p.idPersonero}>{p.nombre} · personero {TIPO_PERSONERO[p.tipo] ?? ''} de {p.lista}</option>
                        ))}
                      </select>
                      {detalle.personeros.length === 0 && <small className="cv-error">No hay personeros presentes en la mesa: nadie puede impugnar votos (RN24).</small>}
                    </label>
                  )}
                  <label className="cv-field">
                    <span className="cv-label">Cargo de la cédula</span>
                    <select value={nueva.idCargo} disabled={saving} onChange={(e) => setNueva((n) => ({ ...n, idCargo: e.target.value }))}>
                      <option value="">{detalle.cargos.length === 1 ? detalle.cargos[0].nombre : 'Seleccione…'}</option>
                      {detalle.cargos.map((c) => <option key={c.idCargo} value={c.idCargo}>{c.nombre}</option>)}
                    </select>
                  </label>
                </div>
                <label className="cv-field">
                  <span className="cv-label">Motivo de la impugnación</span>
                  <textarea rows={3} minLength={10} maxLength={1000} required value={nueva.motivo} disabled={saving}
                    placeholder="Ej.: la cédula no tiene la firma del presidente en el reverso; tiene una marca adicional fuera del recuadro."
                    onChange={(e) => setNueva((n) => ({ ...n, motivo: e.target.value }))} />
                  <small className="muted">{nueva.motivo.trim().length}/1000 · mínimo 10 caracteres</small>
                </label>
                {!confirmando ? (
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Cancelar</button>
                    <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || nueva.motivo.trim().length < 10 || (!esPersonero && !nueva.idPersonero)}>
                      <MenuIcon name="check" size={15} /> Registrar impugnación
                    </button>
                  </div>
                ) : (
                  <div className="cq-confirmar-emision" role="alert">
                    <div>
                      <strong>¿Registrar la impugnación en la mesa {mesa.numero}?</strong>
                      <span>La cédula quedará como IMPUGNADA y la mesa deberá resolverla por mayoría de sus miembros.</span>
                    </div>
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                      <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={ingresarImpugnacion}>
                        <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar registro'}
                      </button>
                    </div>
                  </div>
                )}
              </form>
            )}

            <ListaImpugnaciones lista={lista} idSel={idSel} onElegir={elegirImpugnacion} mostrarMesa={false} esCeunp={esCeunp}
              vacio={mesa.estado === 'CERRADA' ? 'No hay impugnaciones en esta mesa.' : 'Aún no hay escrutinio en esta mesa.'} />
          </div>
        </>
      )}

      {/* ── Bandeja del CEUNP ── */}
      {vista === 'BANDEJA' && bandeja && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Bandeja de impugnaciones y apelaciones</h3>
              <p className="muted">El CEUNP resuelve en segunda y última instancia las apelaciones contra las decisiones de las mesas. El Pleno requiere quórum de {quorum} miembros y decide por mayoría simple, con voto dirimente del Presidente (RN36).</p>
            </div>
            <div className="cs-acciones-head">
              <div className="cq-chips" role="group" aria-label="Filtrar">
                {FILTROS.map((f) => (
                  <button key={f.codigo} type="button" className={`cq-chip${filtro === f.codigo ? ' on' : ''}`} onClick={() => setFiltro(f.codigo)}>{f.texto}</button>
                ))}
              </div>
              {bandeja.impugnaciones.length > 0 && (
                <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirRelacionImpugnaciones({ proceso: proceso?.nombre }, bandeja.impugnaciones)}>
                  <MenuIcon name="file" size={13} /> Imprimir relación
                </button>
              )}
            </div>
          </div>
          <ListaImpugnaciones lista={lista} idSel={idSel} onElegir={elegirImpugnacion} mostrarMesa esCeunp={esCeunp}
            vacio={filtro === 'APELADAS' ? 'No hay apelaciones por resolver.' : 'No hay impugnaciones con este filtro.'} />
        </div>
      )}

      {/* ── Expediente de la impugnación seleccionada ── */}
      {seleccionada && (
        <Expediente
          i={seleccionada}
          accion={accion}
          setAccion={(a) => { setAccion(a); setConfirmando(false); }}
          confirmando={confirmando}
          setConfirmando={setConfirmando}
          saving={saving}
          esCeunp={esCeunp}
          esPersonero={esPersonero}
          miembros={miembros}
          quorum={quorum}
          listas={listasDe(seleccionada.idCargo)}
          personerosLista={(detalle?.personeros ?? []).filter((p) => p.idLista === seleccionada.idListaPersonero)}
          decision={decision} setDecision={setDecision} onDecidir={registrarDecisionMesa}
          apelacion={apelacion} setApelacion={setApelacion} onApelar={apelarDecision}
          fallo={fallo} setFallo={setFallo} onFallar={registrarFalloCeunp}
          onCerrar={() => { setIdSel(null); limpiarAccion(); }}
        />
      )}
    </div>
  );
}

/** Lista de impugnaciones (por mesa o bandeja del CEUNP). */
function ListaImpugnaciones({ lista, idSel, onElegir, mostrarMesa, vacio, esCeunp }) {
  if (lista.length === 0) return <p className="empty-state">{vacio}</p>;
  return (
    <div className="table-wrap ig-tabla">
      <table>
        <thead>
          <tr>
            <th>N.º</th>{mostrarMesa && <th>Mesa</th>}<th>Personero</th><th>Motivo</th><th>Mesa (1.ª inst.)</th><th>CEUNP</th><th>Situación</th><th />
          </tr>
        </thead>
        <tbody>
          {lista.map((i) => {
            const sit = SITUACION[i.situacion] ?? SITUACION.PENDIENTE_MESA;
            return (
              <tr key={i.id} className={i.id === idSel ? 'ig-fila on' : 'ig-fila'}>
                <td><strong>{String(i.id).padStart(4, '0')}</strong><small className="pd-sub">{fecha(i.fechaPresentacion)}</small></td>
                {mostrarMesa && <td>Mesa {i.numeroMesa}</td>}
                <td><strong>{i.personero}</strong><small className="pd-sub">{i.listaPersonero}{i.cargo ? ` · ${i.cargo}` : ''}</small></td>
                <td className="ig-motivo">{i.motivo}</td>
                <td>
                  <span className={`ig-decision ${String(i.decisionMesa).toLowerCase()}`}>{DECISION_MESA[i.decisionMesa]}</span>
                  {i.decisionMesa !== 'PENDIENTE' && <small className="pd-sub">{i.votosMesaFavor}–{i.votosMesaContra} · {textoOpcion(i.opcionMesa, i.listaMesa)}</small>}
                </td>
                <td>
                  {i.estado === 'APELADA' ? <span className="ig-decision apelada">Apelada</span>
                    : i.decisionCeunp !== 'PENDIENTE' ? <span className={`ig-decision ${i.decisionCeunp.toLowerCase()}`}>{DECISION_CEUNP[i.decisionCeunp]}</span>
                      : <span className="muted">—</span>}
                  {i.numeroResolucion && <small className="pd-sub">Res. {i.numeroResolucion}</small>}
                </td>
                <td>
                  <span className={`cv-estado ${sit.clase}`}>{sit.texto}</span>
                  <small className="pd-sub">{textoOpcion(i.opcionVigente, i.listaVigente)}</small>
                </td>
                <td>
                  <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => onElegir(i)}>
                    <MenuIcon name="eye" size={13} /> {i.puedeDecidir || i.puedeApelar || (esCeunp && i.estado === 'APELADA') ? 'Tramitar' : 'Ver'}
                  </button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

/** Opción a la que va la cédula: una lista admitida del cargo, en blanco o nulo. */
function OpcionCedula({ nombre, valor, lista, listas, disabled, onCambiar }) {
  return (
    <div className="ig-opciones" role="radiogroup" aria-label="Opción de la cédula">
      {listas.map((l) => {
        const on = valor === 'LISTA' && String(lista) === String(l.idLista);
        return (
          <label key={l.idLista} className={on ? 'on' : ''}>
            <input type="radio" name={nombre} checked={on} disabled={disabled} onChange={() => onCambiar('LISTA', String(l.idLista))} />
            <span className="ig-op-num">{l.ordenCedula ?? '·'}</span>
            <span><b>{l.nombre}</b>{l.simbolo && <small>{l.simbolo}</small>}</span>
          </label>
        );
      })}
      {[['BLANCO', 'Voto en blanco'], ['NULO', 'Voto nulo']].map(([codigo, texto]) => (
        <label key={codigo} className={valor === codigo ? `on ${codigo.toLowerCase()}` : ''}>
          <input type="radio" name={nombre} checked={valor === codigo} disabled={disabled} onChange={() => onCambiar(codigo, '')} />
          <span className="ig-op-num">{codigo === 'BLANCO' ? 'B' : 'N'}</span>
          <span><b>{texto}</b></span>
        </label>
      ))}
    </div>
  );
}

/** Expediente: trámite completo de la impugnación con las acciones que corresponden al actor. */
function Expediente({
  i, accion, setAccion, confirmando, setConfirmando, saving, esCeunp, esPersonero, miembros, quorum, listas,
  personerosLista, decision, setDecision, onDecidir, apelacion, setApelacion, onApelar, fallo, setFallo, onFallar, onCerrar,
}) {
  const sit = SITUACION[i.situacion] ?? SITUACION.PENDIENTE_MESA;
  const puedeFallar = esCeunp && i.estado === 'APELADA';

  // Validaciones de la decisión de la mesa (RN23)
  const dFavor = decision.votosFavor === '' ? null : Number(decision.votosFavor);
  const dContra = decision.votosContra === '' ? null : Number(decision.votosContra);
  const dSuma = (dFavor ?? 0) + (dContra ?? 0);
  const dMayoria = dFavor != null && dContra != null && dFavor !== dContra ? (dFavor > dContra ? 'ACEPTADA' : 'RECHAZADA') : null;
  const dError = dFavor == null || dContra == null ? null
    : dSuma !== miembros ? `Votan los ${miembros} miembros en funciones (suman ${dSuma}).`
      : dFavor === dContra ? 'Hay empate: la mesa decide por mayoría simple.'
        : decision.decision && dMayoria !== decision.decision ? `La mayoría (${dFavor} a ${dContra}) declara la impugnación ${dMayoria === 'ACEPTADA' ? 'fundada' : 'infundada'}.` : null;
  const decisionLista = decision.decision && dFavor != null && dContra != null && !dError && decision.opcion
    && (decision.opcion !== 'LISTA' || decision.idLista) && decision.fundamento.trim().length >= 10;

  // Validaciones del fallo (RN36)
  const fMiembros = Number(fallo.miembrosPleno || 0);
  const fFavor = fallo.votosFavor === '' ? null : Number(fallo.votosFavor);
  const fContra = fallo.votosContra === '' ? null : Number(fallo.votosContra);
  const fEmpate = fFavor != null && fContra != null && fFavor === fContra;
  const fGana = fFavor == null || fContra == null ? null : fEmpate ? (fallo.votoDirimente || null) : (fFavor > fContra ? 'FAVOR' : 'CONTRA');
  const fError = fMiembros < quorum ? `RN36: el Pleno resuelve con quórum de ${quorum} miembros.`
    : fFavor == null || fContra == null ? null
      : fFavor + fContra !== fMiembros ? `Los votos deben sumar ${fMiembros} (suman ${fFavor + fContra}).`
        : fEmpate && !fallo.votoDirimente ? 'Empate: registre el voto dirimente del Presidente del CEUNP.'
          : fallo.decision && fGana && ((fallo.decision === 'MODIFICADA') !== (fGana === 'FAVOR'))
            ? `La mayoría del Pleno ${fGana === 'FAVOR' ? 'ampara' : 'rechaza'} la apelación: el fallo debe ${fGana === 'FAVOR' ? 'MODIFICAR' : 'CONFIRMAR'} la decisión.` : null;
  const igualMesa = fallo.decision === 'MODIFICADA' && fallo.opcion && fallo.opcion === i.opcionMesa
    && (fallo.opcion !== 'LISTA' || String(fallo.idLista) === String(i.idListaMesa));
  const falloListo = fallo.decision && fallo.numeroResolucion.trim() && fFavor != null && fContra != null && !fError && !igualMesa
    && (fallo.decision === 'CONFIRMADA' || (fallo.opcion && (fallo.opcion !== 'LISTA' || fallo.idLista)))
    && fallo.fundamento.trim().length >= 10;

  return (
    <div className="panel cv-form ig-expediente">
      <div className="cv-section-head">
        <div>
          <h3>Impugnación N.º {String(i.id).padStart(4, '0')} · Mesa {i.numeroMesa}</h3>
          <p className="muted">Presentada el {fecha(i.fechaPresentacion)} por {i.personero} (personero {TIPO_PERSONERO[i.tipoPersonero] ?? ''} de {i.listaPersonero}){i.cargo ? ` · cargo ${i.cargo}` : ''}.</p>
        </div>
        <div className="cs-acciones-head">
          <span className={`cv-estado ${sit.clase}`}>{sit.texto}</span>
          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => imprimirConstanciaImpugnacion(i)}>
            <MenuIcon name="file" size={13} /> Imprimir constancia
          </button>
          <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={onCerrar} aria-label="Cerrar expediente">
            <MenuIcon name="close" size={13} />
          </button>
        </div>
      </div>

      <div className="pd-tabs cq-tabs mx-pasos ig-pasos" aria-label="Trámite">
        {PASOS.map((p, n) => {
          const e = estadoPaso(p.codigo, i);
          return (
            <div key={p.codigo} className={`pd-tab mx-paso${e.on ? ' on' : ''}${e.hecho ? ' hecho' : ''}${e.omitido ? ' ig-omitido' : ''}`}>
              <span className="mx-paso-num">{e.hecho ? <MenuIcon name="check" size={14} /> : n + 1}</span>
              <span className="mx-paso-texto"><b>{p.texto}</b><small>{e.texto ?? p.nota}</small></span>
            </div>
          );
        })}
      </div>

      <div className="ig-instancias">
        <section className="ig-instancia">
          <h4><MenuIcon name="alert" size={14} /> Impugnación</h4>
          <p className="ig-texto">{i.motivo}</p>
        </section>

        <section className={`ig-instancia${i.decisionMesa === 'PENDIENTE' ? ' pendiente' : ''}`}>
          <h4><MenuIcon name="users" size={14} /> Decisión de la mesa</h4>
          {i.decisionMesa === 'PENDIENTE' ? <p className="muted">Pendiente. La cédula se cuenta como IMPUGNADA.</p> : (
            <>
              <dl className="cq-meta">
                <div><dt>Decisión</dt><dd><span className={`ig-decision ${i.decisionMesa.toLowerCase()}`}>{DECISION_MESA[i.decisionMesa]}</span></dd></div>
                <div><dt>Votación</dt><dd>{i.votosMesaFavor} a favor · {i.votosMesaContra} en contra</dd></div>
                <div><dt>La cédula va a</dt><dd>{textoOpcion(i.opcionMesa, i.listaMesa)}</dd></div>
                <div><dt>Registró</dt><dd>{i.decididoPor ?? '—'} · {fecha(i.fechaDecisionMesa)}</dd></div>
              </dl>
              <p className="ig-texto">{i.fundamentoMesa}</p>
              {i.decisionMesa === 'RECHAZADA' && !i.fechaApelacion && i.venceApelacion && (
                <p className="muted im-nota">{i.puedeApelar || i.situacion === 'APELABLE' ? `Puede apelarse hasta el ${fecha(i.venceApelacion)}.` : `El plazo para apelar venció el ${fecha(i.venceApelacion)}: la decisión quedó firme.`}</p>
              )}
            </>
          )}
        </section>

        {i.fechaApelacion && (
          <section className="ig-instancia">
            <h4><MenuIcon name="upload" size={14} /> Apelación ante el CEUNP</h4>
            <dl className="cq-meta">
              <div><dt>Apela</dt><dd>{i.apelante}</dd></div>
              <div><dt>Fecha</dt><dd>{fecha(i.fechaApelacion)}</dd></div>
              <div><dt>Registró</dt><dd>{i.apelacionRegistradaPor ?? '—'}</dd></div>
            </dl>
            <p className="ig-texto">{i.fundamentoApelacion}</p>
          </section>
        )}

        {i.decisionCeunp !== 'PENDIENTE' && (
          <section className="ig-instancia final">
            <h4><MenuIcon name="scale" size={14} /> Fallo del CEUNP · Resolución {i.numeroResolucion}</h4>
            <dl className="cq-meta">
              <div><dt>Fallo</dt><dd><span className={`ig-decision ${i.decisionCeunp.toLowerCase()}`}>{DECISION_CEUNP[i.decisionCeunp]}</span></dd></div>
              <div><dt>Pleno</dt><dd>{i.miembrosPleno} miembros · {i.votosPlenoFavor} a favor · {i.votosPlenoContra} en contra{i.votoDirimente ? ` · dirimente ${i.votoDirimente === 'FAVOR' ? 'a favor' : 'en contra'}` : ''}</dd></div>
              <div><dt>Opción final</dt><dd>{textoOpcion(i.opcionFinal, i.listaFinal)}</dd></div>
              <div><dt>Fecha</dt><dd>{fecha(i.fechaFallo)}</dd></div>
            </dl>
            <p className="ig-texto">{i.fundamentoCeunp}</p>
            <p className="muted im-nota">RN36: el fallo del CEUNP es inapelable.</p>
          </section>
        )}
      </div>

      {/* Acciones del actor */}
      {!accion && (i.puedeDecidir || i.puedeApelar || puedeFallar) && (
        <div className="cv-actions">
          {i.puedeDecidir && (
            <button type="button" className="cv-btn cv-btn-primary" onClick={() => setAccion('DECIDIR')}>
              <MenuIcon name="users" size={15} /> Registrar decisión de la mesa
            </button>
          )}
          {i.puedeApelar && (
            <button type="button" className="cv-btn im-btn-peligro" onClick={() => setAccion('APELAR')}>
              <MenuIcon name="upload" size={15} /> Apelar ante el CEUNP
            </button>
          )}
          {puedeFallar && (
            <button type="button" className="cv-btn cv-btn-success" onClick={() => setAccion('FALLAR')}>
              <MenuIcon name="scale" size={15} /> Registrar fallo del CEUNP
            </button>
          )}
        </div>
      )}
      {!accion && esPersonero && i.decisionMesa === 'RECHAZADA' && !i.puedeApelar && !i.fechaApelacion && (
        <p className="muted im-nota">Solo apela un personero de {i.listaPersonero} dentro del plazo.</p>
      )}

      {/* 6-9 · Decisión de la mesa */}
      {accion === 'DECIDIR' && (
        <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>Decisión de la mesa · primera instancia (RN23)</h4>
          <p className="muted im-nota">Los {miembros} miembros en funciones votan; decide la mayoría simple. Luego indique a qué opción va la cédula.</p>
          <div className="im-estados" role="radiogroup" aria-label="Decisión">
            {[['ACEPTADA', 'Fundada (se acepta la impugnación)', 'no_recibido'], ['RECHAZADA', 'Infundada (se rechaza)', 'conforme']].map(([codigo, texto, clase]) => (
              <label key={codigo} className={decision.decision === codigo ? `on ${clase}` : ''}>
                <input type="radio" name="decision-mesa" checked={decision.decision === codigo} disabled={saving}
                  onChange={() => setDecision((d) => ({ ...d, decision: codigo }))} />
                {texto}
              </label>
            ))}
          </div>
          <div className="im-cedulas">
            <label className="cv-field">
              <span className="cv-label">Miembros a favor de la impugnación</span>
              <input type="number" min={0} max={miembros} required value={decision.votosFavor} disabled={saving}
                onChange={(e) => setDecision((d) => ({ ...d, votosFavor: e.target.value }))} />
            </label>
            <label className="cv-field">
              <span className="cv-label">Miembros en contra</span>
              <input type="number" min={0} max={miembros} required value={decision.votosContra} disabled={saving}
                onChange={(e) => setDecision((d) => ({ ...d, votosContra: e.target.value }))} />
            </label>
          </div>
          {dError && <small className="cv-error">{dError}</small>}
          <div className="cv-field">
            <span className="cv-label">La cédula impugnada va a</span>
            <OpcionCedula nombre={`op-mesa-${i.id}`} valor={decision.opcion} lista={decision.idLista} listas={listas} disabled={saving}
              onCambiar={(opcion, idLista) => setDecision((d) => ({ ...d, opcion, idLista }))} />
          </div>
          <label className="cv-field">
            <span className="cv-label">Fundamento</span>
            <textarea rows={3} minLength={10} maxLength={1000} required value={decision.fundamento} disabled={saving}
              placeholder="Ej.: la cédula lleva la firma del presidente y una sola marca dentro del recuadro de la lista; es válida."
              onChange={(e) => setDecision((d) => ({ ...d, fundamento: e.target.value }))} />
          </label>
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAccion(null)}>Cancelar</button>
              <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !decisionLista}>
                <MenuIcon name="check" size={15} /> Registrar decisión
              </button>
            </div>
          ) : (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>¿Declarar {decision.decision === 'ACEPTADA' ? 'FUNDADA' : 'INFUNDADA'} la impugnación ({dFavor} a {dContra})?</strong>
                <span>La cédula irá a {textoOpcion(decision.opcion, listas.find((l) => String(l.idLista) === String(decision.idLista))?.nombre)}. {decision.decision === 'RECHAZADA' ? 'El personero podrá apelar ante el CEUNP.' : 'La decisión quedará firme.'}</span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={onDecidir}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar decisión'}
                </button>
              </div>
            </div>
          )}
        </form>
      )}

      {/* 10 · Apelación */}
      {accion === 'APELAR' && (
        <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>Apelar la decisión de la mesa (RF81)</h4>
          <p className="muted im-nota">La mesa eleva la apelación al CEUNP, que resuelve en segunda y última instancia{i.venceApelacion ? `. Plazo: hasta el ${fecha(i.venceApelacion)}` : ''}.</p>
          {!esPersonero && (
            <label className="cv-field">
              <span className="cv-label">Personero de {i.listaPersonero} que apela</span>
              <select value={apelacion.idPersonero} disabled={saving} onChange={(e) => setApelacion((a) => ({ ...a, idPersonero: e.target.value }))}>
                <option value="">{i.personero} (quien impugnó)</option>
                {personerosLista.filter((p) => p.idPersonero !== i.idPersonero).map((p) => <option key={p.idPersonero} value={p.idPersonero}>{p.nombre}</option>)}
              </select>
            </label>
          )}
          <label className="cv-field">
            <span className="cv-label">Fundamento de la apelación</span>
            <textarea rows={3} minLength={10} maxLength={1000} required value={apelacion.fundamento} disabled={saving}
              placeholder="Ej.: la marca está fuera del recuadro y no permite identificar la voluntad del elector; debe ser nulo."
              onChange={(e) => setApelacion((a) => ({ ...a, fundamento: e.target.value }))} />
          </label>
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAccion(null)}>Cancelar</button>
              <button type="submit" className="cv-btn im-btn-peligro-solido" disabled={saving || apelacion.fundamento.trim().length < 10}>
                <MenuIcon name="upload" size={15} /> Apelar
              </button>
            </div>
          ) : (
            <div className="cq-confirmar-emision peligro" role="alert">
              <div>
                <strong>¿Elevar la apelación al CEUNP?</strong>
                <span>La cédula volverá a contarse como IMPUGNADA hasta el fallo, que es inapelable.</span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                <button type="button" className="cv-btn im-btn-peligro-solido" disabled={saving} onClick={onApelar}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Elevando…' : 'Confirmar apelación'}
                </button>
              </div>
            </div>
          )}
        </form>
      )}

      {/* 11-14 · Fallo del CEUNP */}
      {accion === 'FALLAR' && (
        <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>Fallo del CEUNP · segunda y última instancia (RN36)</h4>
          <div className="im-estados" role="radiogroup" aria-label="Fallo">
            {[['CONFIRMADA', 'Confirmar la decisión de la mesa', 'conforme'], ['MODIFICADA', 'Modificar la decisión (ampara la apelación)', 'no_recibido']].map(([codigo, texto, clase]) => (
              <label key={codigo} className={fallo.decision === codigo ? `on ${clase}` : ''}>
                <input type="radio" name="fallo" checked={fallo.decision === codigo} disabled={saving}
                  onChange={() => setFallo((f) => ({ ...f, decision: codigo }))} />
                {texto}
              </label>
            ))}
          </div>
          <div className="ig-grid">
            <label className="cv-field">
              <span className="cv-label">N.º de resolución</span>
              <input maxLength={40} required value={fallo.numeroResolucion} disabled={saving} placeholder="Ej.: 045-2026-CEUNP"
                onChange={(e) => setFallo((f) => ({ ...f, numeroResolucion: e.target.value }))} />
            </label>
            <label className="cv-field">
              <span className="cv-label">Miembros del Pleno presentes</span>
              <input type="number" min={1} max={30} required value={fallo.miembrosPleno} disabled={saving}
                onChange={(e) => setFallo((f) => ({ ...f, miembrosPleno: e.target.value }))} />
              <small className="muted">Quórum: {quorum}</small>
            </label>
            <label className="cv-field">
              <span className="cv-label">Votos a favor de la apelación</span>
              <input type="number" min={0} max={30} required value={fallo.votosFavor} disabled={saving}
                onChange={(e) => setFallo((f) => ({ ...f, votosFavor: e.target.value }))} />
            </label>
            <label className="cv-field">
              <span className="cv-label">Votos en contra</span>
              <input type="number" min={0} max={30} required value={fallo.votosContra} disabled={saving}
                onChange={(e) => setFallo((f) => ({ ...f, votosContra: e.target.value }))} />
            </label>
          </div>
          {fEmpate && (
            <div className="cv-field">
              <span className="cv-label">Voto dirimente del Presidente del CEUNP</span>
              <div className="im-estados" role="radiogroup" aria-label="Voto dirimente">
                {[['FAVOR', 'A favor de la apelación'], ['CONTRA', 'En contra']].map(([codigo, texto]) => (
                  <label key={codigo} className={fallo.votoDirimente === codigo ? 'on observado' : ''}>
                    <input type="radio" name="dirimente" checked={fallo.votoDirimente === codigo} disabled={saving}
                      onChange={() => setFallo((f) => ({ ...f, votoDirimente: codigo }))} />
                    {texto}
                  </label>
                ))}
              </div>
            </div>
          )}
          {fError && <small className="cv-error">{fError}</small>}
          {fallo.decision === 'MODIFICADA' && (
            <div className="cv-field">
              <span className="cv-label">Opción final de la cédula (la mesa la asignó a {textoOpcion(i.opcionMesa, i.listaMesa)})</span>
              <OpcionCedula nombre={`op-final-${i.id}`} valor={fallo.opcion} lista={fallo.idLista} listas={listas} disabled={saving}
                onCambiar={(opcion, idLista) => setFallo((f) => ({ ...f, opcion, idLista }))} />
              {igualMesa && <small className="cv-error">Para modificar, elija una opción distinta de la que fijó la mesa.</small>}
            </div>
          )}
          <label className="cv-field">
            <span className="cv-label">Fundamento del fallo</span>
            <textarea rows={3} minLength={10} maxLength={1000} required value={fallo.fundamento} disabled={saving}
              placeholder="Ej.: revisada la cédula, la marca no permite identificar la voluntad del elector (Art. 53)."
              onChange={(e) => setFallo((f) => ({ ...f, fundamento: e.target.value }))} />
          </label>
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAccion(null)}>Cancelar</button>
              <button type="submit" className="cv-btn cv-btn-success" disabled={saving || !falloListo}>
                <MenuIcon name="scale" size={15} /> Registrar fallo
              </button>
            </div>
          ) : (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>¿Registrar el fallo {fallo.numeroResolucion}: {fallo.decision === 'MODIFICADA' ? 'MODIFICAR' : 'CONFIRMAR'} la decisión de la mesa?</strong>
                <span>La cédula irá a {fallo.decision === 'MODIFICADA'
                  ? textoOpcion(fallo.opcion, listas.find((l) => String(l.idLista) === String(fallo.idLista))?.nombre)
                  : textoOpcion(i.opcionMesa, i.listaMesa)}. El fallo es inapelable y ya no podrá cambiarse.</span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onFallar}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Registrando…' : 'Confirmar fallo'}
                </button>
              </div>
            </div>
          )}
        </form>
      )}
    </div>
  );
}
