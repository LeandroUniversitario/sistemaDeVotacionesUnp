import { useCallback, useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { CodigoQR, EscanerQR, fecha } from '../credenciales/LectorQR';
import { imprimirActaInstalacion, urlVerificacionActa } from './ActaInstalacion';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import './instalacion.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS08 · Instalar mesa — «PantallaInstalacion» (boundary). Actor: Presidente de mesa.
 *
 * Mensajes del diagrama de colaboración «Colaboracion - Instalar mesa»:
 *   1 escanearCredencialQR(token)  → 2 registrarLlegada(token) → RegistrarLlegadaMiembro
 *     3 actualizarAsistencia(id_docente, hora_llegada) → MiembroMesa · 4 mostrarMiembroPresente()
 *   5 ingresarMaterial(padron, actas, cedulas, anfora, cabina) → 6 verificarMaterial(datos) → VerificarMaterial
 *     7 registrarMaterial(id_mesa, estado_material) → MesaElectoral · 8 mostrarEstadoMaterial()
 *   9 confirmarInstalacion() → 10 instalarMesa(id_mesa) → InstalarMesa
 *     11 [antes de 12:00] actualizarEstado('INSTALADA', hora_instalacion) · 12 insertarActa('INSTALACION', hash)
 *     13 mostrarActaInstalacion()
 *
 * Flujos alternos (CUN07): llegada con DNI, suplente o reemplazante de la comunidad universitaria,
 * NO INSTALADA pasadas las 12:00 (RF58) y evaluación de nulidad del CEUNP (RF60).
 */

const PASOS = [
  { codigo: 'MIEMBROS', texto: 'Llegada de miembros' },
  { codigo: 'PERSONEROS', texto: 'Credenciales de personeros' },
  { codigo: 'MATERIAL', texto: 'Material electoral' },
  { codigo: 'ACTA', texto: 'Acta de instalación' },
];
const CARGO = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal', SUPLENTE: 'Suplente' };
const ORIGEN = { TITULAR: 'Titular', SUPLENTE: 'Suplente', REEMPLAZANTE: 'Reemplazante' };
const ESTADO_MESA = {
  PENDIENTE: { clase: 'creado', texto: 'Por instalar' },
  INSTALADA: { clase: 'votacion', texto: 'Instalada' },
  CERRADA: { clase: 'inscripcion', texto: 'Cerrada' },
  NO_INSTALADA: { clase: 'anulado', texto: 'No instalada' },
  ANULADA: { clase: 'anulado', texto: 'Anulada' },
};
const ESTADOS_MATERIAL = [
  { codigo: 'CONFORME', texto: 'Conforme' },
  { codigo: 'OBSERVADO', texto: 'Observado' },
  { codigo: 'NO_RECIBIDO', texto: 'No recibido' },
];
const si = (v) => v === true || v === 1 || v === '1';
const hora = (v) => (v ? new Date(v).toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }) : '—');

export default function InstalacionMesaPage({ session, onSessionExpired }) {
  const esMiembro = session.rol === 'MIEMBRO_MESA';
  const esCeunp = session.rol === 'CEUNP';
  const puedeOperar = esMiembro || esCeunp;

  const [idDocenteSesion, setIdDocenteSesion] = useState(session.idDocente ?? null);
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [mesas, setMesas] = useState([]);
  const [idMesa, setIdMesa] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [alertas, setAlertas] = useState([]);
  const [paso, setPaso] = useState('MIEMBROS');
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [lectura, setLectura] = useState(null);              // resultado de la última lectura QR (4)
  const [dni, setDni] = useState({ clave: null, valor: '' }); // llegada con DNI o reemplazante en curso
  const [material, setMaterial] = useState({});              // 5 ingresarMaterial(...)
  const [cedulas, setCedulas] = useState('');
  const [firmadas, setFirmadas] = useState(false);
  const [observaciones, setObservaciones] = useState('');
  const [materialCambiado, setMaterialCambiado] = useState(false);
  const [confirmando, setConfirmando] = useState(false);
  const [emitida, setEmitida] = useState(null);               // { tokenQr, idActa } tras instalar
  const [motivo, setMotivo] = useState('');
  const [declarando, setDeclarando] = useState(false);
  const [evaluacion, setEvaluacion] = useState({ decision: 'PROCEDE', fundamento: '' });

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const aplicarDetalle = useCallback((data) => {
    setDetalle(data);
    const items = {};
    data.material.items.forEach((m) => { items[m.codigo] = { estado: m.estado, observacion: m.observacion ?? '' }; });
    setMaterial(items);
    setCedulas(data.material.cedulasRecibidas ?? '');
    setFirmadas(!!data.material.cedulasFirmadas);
    setObservaciones(data.material.observaciones ?? '');
    setMaterialCambiado(false);
    setMesas((prev) => prev.map((m) => (m.id === data.mesa.id ? { ...m, ...data.mesa } : m)));
  }, []);

  const cargarMesas = useCallback(async (proceso) => {
    const lista = await apiRequest(esMiembro || !proceso ? '/api/instalacion/mesas' : `/api/instalacion/mesas?procesoId=${proceso}`);
    setMesas(lista);
    return lista;
  }, [esMiembro]);

  const cargarAlertas = useCallback(async () => {
    if (esMiembro) return;
    setAlertas(await apiRequest('/api/instalacion/alertas'));
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
          const lista = await apiRequest('/api/instalacion/procesos');
          setProcesos(lista);
          proceso = lista[0]?.id ?? null;
          setIdProceso(proceso);
          await cargarAlertas();
        }
        const lista = await cargarMesas(proceso);
        const primera = lista.find((m) => m.estado === 'PENDIENTE') ?? lista[0];
        if (primera) setIdMesa(primera.id);
      } catch (e) {
        manejarError(e);
      } finally {
        setCargando(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [esMiembro, cargarMesas, cargarAlertas, manejarError]);

  useEffect(() => {
    if (!idMesa) { setDetalle(null); return; }
    (async () => {
      try {
        aplicarDetalle(await apiRequest(`/api/instalacion/mesas/${idMesa}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idMesa, aplicarDetalle, manejarError]);

  async function cambiarProceso(id, mesaElegida = null) {
    setIdProceso(id);
    setIdMesa(null);
    setFeedback(null);
    try {
      const lista = await cargarMesas(id);
      setIdMesa(mesaElegida ?? (lista.find((m) => m.estado === 'PENDIENTE') ?? lista[0])?.id ?? null);
    } catch (e) {
      manejarError(e);
    }
  }

  function elegirMesa(id, pasoInicial = 'MIEMBROS') {
    setIdMesa(id);
    setPaso(pasoInicial);
    setFeedback(null);
    setLectura(null);
    setEmitida(null);
    setConfirmando(false);
    setDeclarando(false);
    setDni({ clave: null, valor: '' });
  }

  function irAAlerta(a) {
    if (a.idProceso !== idProceso) cambiarProceso(a.idProceso, a.idMesa);
    elegirMesa(a.idMesa, 'ACTA');
  }

  async function ejecutar(promesa, exito) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await promesa;
      aplicarDetalle(data.detalle ?? data);
      if (exito) setFeedback({ type: 'success', text: typeof exito === 'function' ? exito(data) : exito });
      return data;
    } catch (e) {
      manejarError(e);
      return null;
    } finally {
      setSaving(false);
    }
  }

  // ─── 1-4: llegada de miembros y personeros ─────────────────────────────

  /** 1 escanearCredencialQR(token) → 2 registrarLlegada(token). */
  const escanearCredencialQR = useCallback(async (token) => {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/instalacion/mesas/${idMesa}/llegada`, { method: 'POST', body: JSON.stringify({ codigo: token }) });
      setLectura({ hora: new Date(), ...data });
      if (data.detalle) aplicarDetalle(data.detalle); // 4 mostrarMiembroPresente()
    } catch (e) {
      manejarError(e);
    } finally {
      setSaving(false);
    }
  }, [idMesa, aplicarDetalle, manejarError]);

  function asistencia(tipo, id, presente, dniValor) {
    const ruta = tipo === 'miembro' ? 'miembros' : 'personeros';
    return ejecutar(
      apiRequest(`/api/instalacion/mesas/${idMesa}/${ruta}/${id}/asistencia`, { method: 'POST', body: JSON.stringify({ presente, dni: dniValor ?? null }) }),
      presente ? 'Llegada registrada con DNI.' : (tipo === 'miembro' ? 'Se registró la inasistencia.' : 'Se retiró al personero de la instalación.'),
    ).then((ok) => { if (ok) setDni({ clave: null, valor: '' }); });
  }

  function registrarReemplazante(cargo, dniValor) {
    return ejecutar(
      apiRequest(`/api/instalacion/mesas/${idMesa}/reemplazantes`, { method: 'POST', body: JSON.stringify({ cargo, dni: dniValor }) }),
      `Reemplazante registrado para el cargo de ${CARGO[cargo].toLowerCase()}.`,
    ).then((ok) => { if (ok) setDni({ clave: null, valor: '' }); });
  }

  function quitarReemplazante(cargo) {
    return ejecutar(apiRequest(`/api/instalacion/mesas/${idMesa}/reemplazantes/${cargo}`, { method: 'DELETE' }), 'Reemplazante retirado.');
  }

  /** Botón que abre un formulario de DNI; al enviarlo ejecuta «accion(dni)». */
  function formDni(clave, textoBoton, textoEnviar, accion, icono = 'user') {
    if (dni.clave !== clave) {
      return (
        <button type="button" className="cv-btn cv-btn-soft cq-mini" disabled={saving} onClick={() => setDni({ clave, valor: '' })}>
          <MenuIcon name={icono} size={13} /> {textoBoton}
        </button>
      );
    }
    return (
      <form className="im-dni" onSubmit={(e) => { e.preventDefault(); accion(dni.valor); }}>
        <input autoFocus inputMode="numeric" maxLength={8} placeholder="DNI" value={dni.valor}
          aria-label="DNI que presenta la persona" onChange={(e) => setDni({ clave, valor: e.target.value.replace(/\D/g, '') })} />
        <button type="submit" className="cv-btn cv-btn-success cq-mini" disabled={saving || dni.valor.length === 0}>{textoEnviar}</button>
        <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => setDni({ clave: null, valor: '' })}>Cancelar</button>
      </form>
    );
  }

  // ─── 5-8: material ─────────────────────────────────────────────────────

  function marcarMaterial(codigo, cambio) {
    setMaterial((prev) => ({ ...prev, [codigo]: { ...prev[codigo], ...cambio } }));
    setMaterialCambiado(true);
  }

  function todoConforme() {
    const todo = {};
    detalle.material.items.forEach((m) => { todo[m.codigo] = { estado: 'CONFORME', observacion: '' }; });
    setMaterial(todo);
    if (!cedulas) setCedulas(detalle.mesa.totalElectores ?? '');
    setMaterialCambiado(true);
  }

  /** 5 ingresarMaterial(padron, actas, cedulas, anfora, cabina) → 6 verificarMaterial(datos). */
  function ingresarMaterial() {
    const items = {};
    Object.entries(material).forEach(([codigo, v]) => { items[codigo] = { estado: v.estado, observacion: v.observacion || null }; });
    return ejecutar(
      apiRequest(`/api/instalacion/mesas/${idMesa}/material`, {
        method: 'PUT',
        body: JSON.stringify({ items, cedulasRecibidas: cedulas === '' ? null : Number(cedulas), cedulasFirmadas: firmadas, observaciones }),
      }),
      (data) => (data.material.completo && data.requisitos.find((r) => r.codigo === 'CEDULAS')?.cumplido
        ? 'Material verificado: todo el material fue recibido y las cédulas están firmadas.'
        : 'Material registrado. Aún falta material o la firma de las cédulas.'),
    );
  }

  // ─── 9-13: instalación y flujos alternos ───────────────────────────────

  /** 9 confirmarInstalacion() → 10 instalarMesa(id_mesa) → 13 mostrarActaInstalacion(). */
  async function confirmarInstalacion() {
    const data = await ejecutar(apiRequest(`/api/instalacion/mesas/${idMesa}/instalar`, { method: 'POST' }), (d) => d.mensaje);
    setConfirmando(false);
    if (data) {
      setEmitida({ tokenQr: data.tokenQr, idActa: data.idActa });
      setPaso('ACTA');
    }
  }

  async function declararNoInstalada() {
    const data = await ejecutar(apiRequest(`/api/instalacion/mesas/${idMesa}/no-instalada`, { method: 'POST', body: JSON.stringify({ motivo }) }), (d) => d.mensaje);
    if (data) {
      setDeclarando(false);
      setMotivo('');
      cargarAlertas().catch(manejarError);
    }
  }

  async function evaluarNulidad() {
    const data = await ejecutar(apiRequest(`/api/instalacion/mesas/${idMesa}/evaluacion-nulidad`, { method: 'POST', body: JSON.stringify(evaluacion) }), (d) => d.mensaje);
    if (data) {
      setEvaluacion({ decision: 'PROCEDE', fundamento: '' });
      cargarAlertas().catch(manejarError);
    }
  }

  async function refrescar() {
    try {
      if (!esMiembro) {
        setProcesos(await apiRequest('/api/instalacion/procesos'));
        await cargarAlertas();
      }
      await cargarMesas(idProceso);
      if (idMesa) aplicarDetalle(await apiRequest(`/api/instalacion/mesas/${idMesa}`));
    } catch (e) {
      manejarError(e);
    }
  }

  // ─── Render ────────────────────────────────────────────────────────────

  if (cargando) return <div className="panel"><p className="muted">Cargando mesas…</p></div>;

  const proceso = procesos.find((p) => p.id === idProceso);
  const mesa = detalle?.mesa;
  const ventana = detalle?.ventana;
  const editable = puedeOperar && detalle?.editable;
  const presentes = detalle?.miembros.filter((m) => si(m.asistio)).length ?? 0;
  const yoPresente = !esMiembro || detalle?.miembros.some((m) => m.idDocente === idDocenteSesion && si(m.asistio));
  const presidencia = detalle?.conformacion[0];
  const soyPresidente = !esMiembro || !presidencia?.idDocente || presidencia.origen === 'REEMPLAZANTE' || presidencia.idDocente === idDocenteSesion;
  const personerosPresentes = detalle?.personeros.filter((p) => si(p.presente)).length ?? 0;
  const pendientesRequisito = detalle?.requisitos.filter((r) => !r.cumplido) ?? [];
  const faltaMaterial = Object.values(material).filter((m) => m.estado === 'NO_RECIBIDO').length;

  return (
    <div className="pd-shell cq-shell im-shell mx">
      <section className="in-head">
        {!esMiembro && (
          <label className="cv-field in-proceso">
            <span className="cv-label">Proceso electoral</span>
            <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))}>
              {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
            </select>
          </label>
        )}
        {ventana && (
          <div className={`in-plazo ${ventana.abierta ? 'open' : 'closed'}`}>
            <MenuIcon name={ventana.abierta ? 'check' : 'lock'} size={18} />
            <div>
              <strong>{ventana.abierta ? 'Instalación abierta' : ventana.vencida ? 'Plazo de instalación vencido' : 'Instalación aún no disponible'}</strong>
              <span>{ventana.mensaje} Horario: {ventana.horaInicio} a {ventana.horaLimite} · hora del servidor {hora(ventana.ahora)}.</span>
            </div>
          </div>
        )}
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      {/* RF60: aviso al CEUNP de mesas no instaladas pendientes de evaluación */}
      {!esMiembro && alertas.length > 0 && (
        <section className="im-alertas" role="alert">
          <div className="im-alertas-head">
            <MenuIcon name="bell" size={18} />
            <strong>{alertas.length} mesa(s) no instalada(s) esperan la evaluación de nulidad del CEUNP (RF60)</strong>
          </div>
          <ul>
            {alertas.map((a) => (
              <li key={a.idMesa}>
                <span>Mesa {a.numero} · {a.proceso}</span>
                <small>{a.motivoNoInstalacion}</small>
                <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => irAAlerta(a)}>
                  {esCeunp ? 'Evaluar' : 'Ver'}
                </button>
              </li>
            ))}
          </ul>
        </section>
      )}

      {proceso && (
        <section className="cq-resumen">
          <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
            <span>Mesas del proceso</span>
            <strong>{proceso.mesas}</strong>
            <small>{proceso.pendientes} por instalar</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#059669' }}>
            <span>Instaladas <em>RF58</em></span>
            <strong>{proceso.instaladas}<small> / {proceso.mesas}</small></strong>
            <i className="cq-barra"><b style={{ width: `${proceso.mesas ? Math.round((proceso.instaladas / proceso.mesas) * 100) : 0}%` }} /></i>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
            <span>No instaladas <em>RF60</em></span>
            <strong>{proceso.noInstaladas}</strong>
            <small>{proceso.porEvaluar} sin evaluación de nulidad</small>
          </div>
        </section>
      )}

      {mesas.length === 0 ? (
        <div className="panel"><p className="empty-state">
          {esMiembro ? 'No figura como miembro de ninguna mesa de un proceso en curso.' : 'El proceso no tiene mesas: créelas y sortee sus miembros en Sorteos (CUS06).'}
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
                <small>{m.presentes}/{m.miembros} miembros · material {si(m.materialCompleto) ? 'completo' : 'pendiente'}</small>
                {m.estado === 'NO_INSTALADA' && <small>{m.evaluacionNulidad ? `Nulidad: ${m.evaluacionNulidad === 'PROCEDE' ? 'procede' : 'no procede'}` : 'Nulidad sin evaluar'}</small>}
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
              <span className={`cv-estado ${(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).clase}`}>
                {(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).texto}
              </span>
            </div>
            <dl className="mx-datos">
              <div><dt>Proceso</dt><dd>{mesa.proceso}</dd></div>
              <div><dt>Electores</dt><dd>{mesa.totalElectores}</dd></div>
              <div><dt>Etapa del proceso</dt><dd>{mesa.estadoProceso}</dd></div>
              <div><dt>Miembros presentes</dt><dd>{presentes} de {detalle.miembros.length}</dd></div>
              {mesa.horaInstalacion && <div><dt>Instalada</dt><dd>{hora(mesa.horaInstalacion)}</dd></div>}
            </dl>
          </div>

          {!puedeOperar && <div className="alert success" role="note">Vista de consulta: la instalación la realiza el presidente de mesa o el CEUNP.</div>}
          {esMiembro && editable && !yoPresente && (
            <div className="alert error" role="note">Registre primero su propia llegada: lea su fotocheck o use «Con DNI» en la tabla de miembros.</div>
          )}

          <div className="pd-tabs cq-tabs mx-pasos" role="tablist" aria-label="Pasos de la instalación">
            {PASOS.map((p, i) => {
              const hecho = (p.codigo === 'MIEMBROS' && detalle.conformacion.every((c) => !c.vacante))
                || (p.codigo === 'PERSONEROS' && personerosPresentes > 0)
                || (p.codigo === 'MATERIAL' && detalle.material.completo && detalle.requisitos.find((r) => r.codigo === 'CEDULAS')?.cumplido)
                || (p.codigo === 'ACTA' && detalle.acta);
              return (
                <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
                  className={`pd-tab mx-paso${paso === p.codigo ? ' on' : ''}${hecho ? ' hecho' : ''}`} onClick={() => setPaso(p.codigo)}>
                  <span className="mx-paso-num">{hecho ? <MenuIcon name="check" size={14} /> : i + 1}</span>
                  <span className="mx-paso-texto">
                    <b>{p.texto}</b>
                    <small>{hecho ? 'Completado' : paso === p.codigo ? 'En curso' : 'Pendiente'}</small>
                  </span>
                </button>
              );
            })}
          </div>

          {/* ── 1-4: llegada de miembros ── */}
          {paso === 'MIEMBROS' && (
            <>
              {editable && (
                <div className="panel cv-form">
                  <div className="cv-section-head">
                    <div>
                      <h3>Escanear credencial QR (RF56)</h3>
                      <p className="muted">Lea el fotocheck del miembro de mesa o la credencial del personero (CUS07); se registra la hora de llegada. Sin QR, use «Con DNI» en la tabla.</p>
                    </div>
                  </div>
                  <EscanerQR onCodigo={escanearCredencialQR} deshabilitado={saving} />
                  {lectura && (
                    <div className={`cq-resultado ${lectura.aceptada ? 'ok' : 'mal'}`} role="status" aria-live="polite">
                      <div className="cq-resultado-head">
                        <span className="cq-resultado-icono"><MenuIcon name={lectura.aceptada ? 'check' : 'alert'} size={22} /></span>
                        <div>
                          <strong>{lectura.aceptada ? 'Miembro presente' : 'No se registró la llegada'}</strong>
                          <span>{lectura.mensaje}</span>
                        </div>
                      </div>
                      {lectura.titular && (
                        <div className="cq-titular">
                          <div className="in-avatar">{lectura.titular.nombre?.charAt(0)}</div>
                          <div className="in-cand-body">
                            <strong>{lectura.titular.nombre}</strong>
                            <span>DNI {lectura.titular.dni} · {lectura.titular.funcion}</span>
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}

              <div className="panel cv-form">
                <div className="cv-section-head">
                  <div>
                    <h3>Conformación de la mesa</h3>
                    <p className="muted">
                      {mesa.estado === 'PENDIENTE'
                        ? 'Si falta un titular asume el primer suplente presente (orden del sorteo). Si faltan titulares y suplentes, registre a otro integrante de la comunidad universitaria (CUN07).'
                        : 'Cargos con los que se instaló la mesa.'}
                    </p>
                  </div>
                  <span className="im-contador">{presentes} de {detalle.miembros.length} presentes</span>
                </div>
                <div className="im-cargos">
                  {detalle.conformacion.map((c) => (
                    <div key={c.cargo} className={`im-cargo${c.vacante ? ' vacante' : ''}${c.origen === 'REEMPLAZANTE' ? ' reemplazo' : ''}`}>
                      <span>{CARGO[c.cargo]}</span>
                      <strong>{c.vacante ? 'Sin cubrir' : c.nombre}</strong>
                      {!c.vacante && <em>{ORIGEN[c.origen]}{c.origen !== 'TITULAR' && c.titular ? ` · reemplaza a ${c.titular}` : ''}</em>}
                      {c.vacante && <em>Titular: {c.titular ?? '—'}</em>}
                      {editable && yoPresente && c.vacante && c.admiteReemplazante
                        && formDni(`reemplazo-${c.cargo}`, 'Registrar reemplazante', 'Registrar', (v) => registrarReemplazante(c.cargo, v), 'plus')}
                      {editable && yoPresente && c.origen === 'REEMPLAZANTE' && (
                        <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving} onClick={() => quitarReemplazante(c.cargo)}>
                          <MenuIcon name="close" size={13} /> Quitar
                        </button>
                      )}
                    </div>
                  ))}
                </div>

                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Orden</th><th>Miembro</th><th>Sorteado como</th><th>Llegada</th>{editable && <th aria-label="Acciones" />}</tr></thead>
                    <tbody>
                      {detalle.miembros.map((m) => {
                        const sinRegistro = m.asistio === null || m.asistio === undefined;
                        return (
                          <tr key={m.idDocente}>
                            <td>{m.ordenSorteo ?? '—'}</td>
                            <td><strong>{m.nombre}</strong><small className="pd-sub">DNI {m.dni} · {m.facultad ?? '—'}</small></td>
                            <td>
                              {CARGO[m.rol]}{si(m.titular) ? ' (titular)' : ''}
                              {m.rolInstalacion && m.rolInstalacion !== m.rol && <small className="pd-sub">Ejerce: {CARGO[m.rolInstalacion]}</small>}
                              {!si(m.credencialVigente) && <small className="pd-sub">Sin fotocheck vigente</small>}
                            </td>
                            <td>
                              {si(m.asistio) && <span className="cv-estado votacion">Presente · {m.metodo} {hora(m.horaLlegada)}</span>}
                              {!sinRegistro && !si(m.asistio) && <span className="cv-estado anulado">No asistió</span>}
                              {sinRegistro && <span className="cv-estado creado">Sin registrar</span>}
                            </td>
                            {editable && (
                              <td className="cq-row-actions">
                                {!si(m.asistio) && formDni(`miembro-${m.idDocente}`, 'Con DNI', 'Registrar', (v) => asistencia('miembro', m.idDocente, true, v))}
                                {(si(m.asistio) || sinRegistro) && dni.clave !== `miembro-${m.idDocente}` && (
                                  <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving} onClick={() => asistencia('miembro', m.idDocente, false)}>
                                    <MenuIcon name="close" size={13} /> {si(m.asistio) ? 'Quitar' : 'Ausente'}
                                  </button>
                                )}
                              </td>
                            )}
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('PERSONEROS')}>Continuar con personeros</button>
                </div>
              </div>
            </>
          )}

          {/* ── Personeros (CUN07 paso 4: el presidente recibe sus credenciales) ── */}
          {paso === 'PERSONEROS' && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Credenciales de personeros</h3>
                  <p className="muted">El presidente recibe las credenciales de los personeros de esta mesa y de los personeros generales de las listas en carrera (CUS05). Es opcional; los presentes firman el acta. Para recibirlas con QR use el lector del paso 1.</p>
                </div>
                <span className="im-contador">{personerosPresentes} presente(s)</span>
              </div>
              {detalle.personeros.length === 0 ? <p className="empty-state">No hay personeros acreditados para esta mesa (CUS05).</p> : (
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Personero</th><th>Lista</th><th>Tipo</th><th>Credencial</th>{editable && <th aria-label="Acciones" />}</tr></thead>
                    <tbody>
                      {detalle.personeros.map((p) => (
                        <tr key={p.idPersonero}>
                          <td><strong>{p.nombre}</strong><small className="pd-sub">DNI {p.dni}</small></td>
                          <td>{p.lista}<small className="pd-sub">{p.cargo}</small></td>
                          <td>{p.tipo === 'MESA' ? 'De mesa' : p.tipo === 'GENERAL' ? 'General' : 'Alterno'}</td>
                          <td>{si(p.presente) ? <span className="cv-estado votacion">Recibida · {p.metodo} {hora(p.horaLlegada)}</span> : <span className="cv-estado creado">No presentada</span>}</td>
                          {editable && (
                            <td className="cq-row-actions">
                              {!si(p.presente) && formDni(`personero-${p.idPersonero}`, 'Con DNI', 'Registrar', (v) => asistencia('personero', p.idPersonero, true, v))}
                              {si(p.presente) && (
                                <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving} onClick={() => asistencia('personero', p.idPersonero, false)}>
                                  <MenuIcon name="close" size={13} /> Quitar
                                </button>
                              )}
                            </td>
                          )}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setPaso('MIEMBROS')}>Volver</button>
                <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('MATERIAL')}>Continuar con el material</button>
              </div>
            </div>
          )}

          {/* ── 5-8: material ── */}
          {paso === 'MATERIAL' && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Material electoral (RF57)</h3>
                  <p className="muted">Verifique el estado de cada material recibido. Sin todo el material la mesa no se instala. Las cédulas se cuentan y el presidente las firma en el reverso (CUN07).</p>
                </div>
                {editable && yoPresente && <button type="button" className="cv-btn cv-btn-soft" onClick={todoConforme} disabled={saving}><MenuIcon name="check" size={15} /> Todo conforme</button>}
              </div>
              <div className="table-wrap">
                <table className="im-tabla-material">
                  <thead><tr><th>Material</th><th>Estado</th><th>Observación</th></tr></thead>
                  <tbody>
                    {detalle.material.items.map((m) => {
                      const valor = material[m.codigo] ?? { estado: 'NO_RECIBIDO', observacion: '' };
                      return (
                        <tr key={m.codigo} className={`im-mat-${valor.estado.toLowerCase()}`}>
                          <td><strong>{m.descripcion}</strong></td>
                          <td>
                            <div className="im-estados" role="radiogroup" aria-label={`Estado de ${m.descripcion}`}>
                              {ESTADOS_MATERIAL.map((e) => (
                                <label key={e.codigo} className={valor.estado === e.codigo ? `on ${e.codigo.toLowerCase()}` : ''}>
                                  <input type="radio" name={`mat-${m.codigo}`} value={e.codigo} checked={valor.estado === e.codigo}
                                    disabled={!editable || !yoPresente || saving} onChange={() => marcarMaterial(m.codigo, { estado: e.codigo })} />
                                  {e.texto}
                                </label>
                              ))}
                            </div>
                          </td>
                          <td>
                            <input className="im-obs-input" maxLength={200} value={valor.observacion ?? ''}
                              placeholder={valor.estado === 'OBSERVADO' ? 'Describa el problema (obligatorio)' : 'Opcional'}
                              disabled={!editable || !yoPresente || saving} onChange={(e) => marcarMaterial(m.codigo, { observacion: e.target.value })} />
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
              <div className="im-cedulas">
                <label className="cv-field">
                  <span className="cv-label">Cantidad de cédulas recibidas (RF59)</span>
                  <input type="number" min={0} max={100000} value={cedulas} disabled={!editable || !yoPresente || saving}
                    onChange={(e) => { setCedulas(e.target.value); setMaterialCambiado(true); }} />
                  <small className="muted">Electores de la mesa: {mesa.totalElectores}{cedulas !== '' && Number(cedulas) < mesa.totalElectores ? ' · hay menos cédulas que electores' : ''}</small>
                </label>
                <label className="im-check">
                  <input type="checkbox" checked={firmadas} disabled={!editable || !yoPresente || saving}
                    onChange={(e) => { setFirmadas(e.target.checked); setMaterialCambiado(true); }} />
                  <span>El presidente firmó las cédulas en el reverso</span>
                </label>
              </div>
              <label className="cv-field">
                <span className="cv-label">Observaciones de la instalación (van en el acta)</span>
                <textarea rows={3} maxLength={500} value={observaciones} disabled={!editable || !yoPresente || saving}
                  placeholder="Ej.: el cartel de candidatos llegó con una esquina rota."
                  onChange={(e) => { setObservaciones(e.target.value); setMaterialCambiado(true); }} />
              </label>
              {detalle.material.registrado && detalle.registro?.fechaActualizacion && (
                <p className="muted im-nota">Último registro: {fecha(detalle.registro.fechaActualizacion)}{detalle.registro.registradoPor ? ` por ${detalle.registro.registradoPor}` : ''}.</p>
              )}
              {editable && yoPresente && (
                <div className="cv-actions">
                  {faltaMaterial > 0 && <span className="cv-actions-note cv-error">{faltaMaterial} material(es) sin recibir.</span>}
                  <button type="button" className="cv-btn cv-btn-success" disabled={saving || !materialCambiado} onClick={ingresarMaterial}>
                    <MenuIcon name="check" size={15} /> {saving ? 'Verificando…' : 'Verificar y registrar material'}
                  </button>
                  <button type="button" className="cv-btn cv-btn-primary" disabled={materialCambiado} onClick={() => setPaso('ACTA')}>Continuar con el acta</button>
                </div>
              )}
            </div>
          )}

          {/* ── 9-13: acta ── */}
          {paso === 'ACTA' && (
            <>
              {mesa.estado === 'PENDIENTE' && (
                <div className="panel cv-form">
                  <div className="cv-section-head">
                    <div>
                      <h3>Instalar la mesa</h3>
                      <p className="muted">Al confirmar se registra la hora de instalación, se emite el Acta de Instalación con huella SHA-256 (RF59), la firman quienes ejercen los tres cargos y los personeros presentes, y se habilita el sufragio de la mesa.</p>
                    </div>
                  </div>
                  <ul className="im-requisitos">
                    {detalle.requisitos.map((r) => (
                      <li key={r.codigo} className={r.cumplido ? 'ok' : 'mal'}>
                        <MenuIcon name={r.cumplido ? 'check' : 'close'} size={16} />
                        <div><strong>{r.texto}</strong>{!r.cumplido && r.detalle && <span>{r.detalle}</span>}</div>
                      </li>
                    ))}
                  </ul>

                  {editable && !confirmando && (
                    <div className="cv-actions">
                      {pendientesRequisito.length > 0 && <span className="cv-actions-note muted">Complete los requisitos pendientes para instalar.</span>}
                      {pendientesRequisito.length === 0 && !soyPresidente && <span className="cv-actions-note muted">Instala el presidente en funciones: {presidencia?.nombre}.</span>}
                      <button type="button" className="cv-btn cv-btn-success" disabled={saving || !detalle.puedeInstalar || !soyPresidente || !yoPresente} onClick={() => setConfirmando(true)}>
                        <MenuIcon name="shield" size={15} /> Instalar mesa y emitir acta
                      </button>
                    </div>
                  )}
                  {confirmando && (
                    <div className="cq-confirmar-emision" role="alert">
                      <div>
                        <strong>¿Instalar la mesa {mesa.numero}?</strong>
                        <span>
                          La hora de instalación será la del servidor y el acta ya no podrá modificarse (RN28). Quienes no llegaron quedarán como inasistentes (RN35).
                          {' '}Cargos: {detalle.conformacion.map((c) => `${CARGO[c.cargo]} ${c.nombre ?? '—'}`).join(' · ')}. Cédulas: {detalle.material.cedulasRecibidas}.
                        </span>
                      </div>
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Cancelar</button>
                        <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={confirmarInstalacion}>
                          <MenuIcon name="check" size={15} /> {saving ? 'Instalando…' : 'Confirmar instalación'}
                        </button>
                      </div>
                    </div>
                  )}

                  {esCeunp && detalle.puedeDeclararNoInstalada && (
                    <div className="im-no-instalada">
                      {!declarando ? (
                        <button type="button" className="cv-btn cv-btn-ghost im-btn-peligro" onClick={() => setDeclarando(true)} disabled={saving}>
                          <MenuIcon name="alert" size={15} /> Declarar mesa NO INSTALADA
                        </button>
                      ) : (
                        <form onSubmit={(e) => { e.preventDefault(); declararNoInstalada(); }} className="cv-form">
                          <label className="cv-field">
                            <span className="cv-label">Motivo (RF58)</span>
                            <textarea rows={2} minLength={10} maxLength={255} required value={motivo}
                              placeholder="Ej.: a las 12:00 no se presentaron los miembros suficientes para conformar la mesa."
                              onChange={(e) => setMotivo(e.target.value)} />
                          </label>
                          <div className="cv-actions">
                            <span className="cv-actions-note muted">Sus electores no podrán votar en esta mesa y los miembros que no llegaron quedarán como inasistentes.</span>
                            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setDeclarando(false)}>Cancelar</button>
                            <button type="submit" className="cv-btn im-btn-peligro-solido" disabled={saving || motivo.trim().length < 10}>Declarar no instalada</button>
                          </div>
                        </form>
                      )}
                    </div>
                  )}
                </div>
              )}

              {mesa.estado === 'NO_INSTALADA' && (
                <div className="panel cv-form">
                  <div className="cq-resultado mal">
                    <div className="cq-resultado-head">
                      <span className="cq-resultado-icono"><MenuIcon name="alert" size={22} /></span>
                      <div>
                        <strong>Mesa no instalada{si(detalle.registro?.automatica) ? ' (registro automático, RF58)' : ''}</strong>
                        <span>{detalle.registro?.motivoNoInstalacion} · {fecha(detalle.registro?.fechaActualizacion)}{detalle.registro?.cerradoPor ? ` · ${detalle.registro.cerradoPor}` : ''}</span>
                      </div>
                    </div>
                  </div>

                  <div className="cv-section-head">
                    <div>
                      <h3>Evaluación de nulidad (RF60)</h3>
                      <p className="muted">El CEUNP evalúa si procede la nulidad de la votación de esta mesa (Art. 64a).</p>
                    </div>
                  </div>
                  {detalle.registro?.evaluacionNulidad ? (
                    <dl className="cq-meta">
                      <div><dt>Decisión</dt><dd>{detalle.registro.evaluacionNulidad === 'PROCEDE' ? 'Procede la nulidad' : 'No procede la nulidad'}</dd></div>
                      <div><dt>Fecha</dt><dd>{fecha(detalle.registro.fechaEvaluacion)}</dd></div>
                      <div><dt>Registró</dt><dd>{detalle.registro.evaluadoPor ?? '—'}</dd></div>
                      <div className="im-dl-ancho"><dt>Fundamento</dt><dd>{detalle.registro.fundamentoEvaluacion}</dd></div>
                    </dl>
                  ) : esCeunp && detalle.puedeEvaluarNulidad ? (
                    <form className="cv-form" onSubmit={(e) => { e.preventDefault(); evaluarNulidad(); }}>
                      <div className="im-estados" role="radiogroup" aria-label="Decisión">
                        {[['PROCEDE', 'Procede la nulidad'], ['NO_PROCEDE', 'No procede']].map(([codigo, texto]) => (
                          <label key={codigo} className={evaluacion.decision === codigo ? `on ${codigo === 'PROCEDE' ? 'no_recibido' : 'conforme'}` : ''}>
                            <input type="radio" name="decision" value={codigo} checked={evaluacion.decision === codigo}
                              onChange={() => setEvaluacion((v) => ({ ...v, decision: codigo }))} />
                            {texto}
                          </label>
                        ))}
                      </div>
                      <label className="cv-field">
                        <span className="cv-label">Fundamento</span>
                        <textarea rows={3} minLength={10} maxLength={500} required value={evaluacion.fundamento}
                          placeholder="Ej.: los electores de la mesa representan menos del 2% del padrón y no alteran el resultado."
                          onChange={(e) => setEvaluacion((v) => ({ ...v, fundamento: e.target.value }))} />
                      </label>
                      <div className="cv-actions">
                        <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || evaluacion.fundamento.trim().length < 10}>
                          <MenuIcon name="scale" size={15} /> Registrar evaluación
                        </button>
                      </div>
                    </form>
                  ) : <p className="muted im-nota">Pendiente de evaluación por el CEUNP.</p>}
                </div>
              )}

              {detalle.acta && <ActaVista acta={detalle.acta} mesa={mesa} emitida={emitida} />}
            </>
          )}
        </>
      )}
    </div>
  );
}

/** 13 mostrarActaInstalacion(): datos, firmas y, solo al emitirse, el QR de verificación. */
function ActaVista({ acta, mesa, emitida }) {
  const c = acta.contenido ?? {};
  const token = emitida && emitida.idActa === acta.idActa ? emitida.tokenQr : null;
  const observados = Object.entries(c.material ?? {}).filter(([, v]) => v?.estado === 'OBSERVADO').length;
  return (
    <div className="panel cv-form im-acta">
      <div className="cv-section-head">
        <div>
          <h3>Acta de Instalación N.º {String(acta.idActa).padStart(6, '0')}</h3>
          <p className="muted">Emitida el {fecha(acta.fechaEmision)} · estado {acta.estado}</p>
        </div>
        <button type="button" className="cv-btn cv-btn-primary" onClick={() => imprimirActaInstalacion(acta, mesa, token)}>
          <MenuIcon name="file" size={15} /> Imprimir acta
        </button>
      </div>

      <div className="im-acta-cuerpo">
        <dl className="cq-meta">
          <div><dt>Mesa</dt><dd>{c.mesa} · {c.ubicacion}</dd></div>
          <div><dt>Hora de instalación</dt><dd>{c.hora_instalacion}</dd></div>
          <div><dt>Electores</dt><dd>{c.total_electores}</dd></div>
          <div><dt>Cédulas recibidas</dt><dd>{c.cedulas_recibidas ?? '—'}</dd></div>
          <div><dt>Material observado</dt><dd>{observados}</dd></div>
          <div><dt>Personeros</dt><dd>{c.personeros?.length ?? 0}</dd></div>
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
