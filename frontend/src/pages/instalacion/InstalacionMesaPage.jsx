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

/**
 * CUS08 · Instalar mesa — «PantallaInstalacion» (boundary).
 *
 *   1 Acreditar miembros   fotocheck QR (CUS07) o DNI; un suplente presente reemplaza al titular ausente
 *   2 Personeros           presencia de los personeros acreditados (CUS05), opcional
 *   3 Material electoral   recepción del material obligatorio
 *   4 Acta de instalación  sp_instalar_mesa valida RN07/RN19, emite y firma el acta (RN28)
 *
 * Vencido el plazo (RN07) el CEUNP declara la mesa NO INSTALADA.
 */

const PASOS = [
  { codigo: 'MIEMBROS', texto: '1. Miembros de mesa' },
  { codigo: 'PERSONEROS', texto: '2. Personeros' },
  { codigo: 'MATERIAL', texto: '3. Material electoral' },
  { codigo: 'ACTA', texto: '4. Acta de instalación' },
];
const CARGO = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal', SUPLENTE: 'Suplente' };
const ESTADO_MESA = {
  PENDIENTE: { clase: 'creado', texto: 'Por instalar' },
  INSTALADA: { clase: 'votacion', texto: 'Instalada' },
  CERRADA: { clase: 'inscripcion', texto: 'Cerrada' },
  NO_INSTALADA: { clase: 'anulado', texto: 'No instalada' },
  ANULADA: { clase: 'anulado', texto: 'Anulada' },
};
const si = (v) => v === true || v === 1 || v === '1';
const hora = (v) => (v ? new Date(v).toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }) : '—');

export default function InstalacionMesaPage({ session, onSessionExpired }) {
  const esMiembro = session.rol === 'MIEMBRO_MESA';
  const esCeunp = session.rol === 'CEUNP';
  const puedeOperar = esMiembro || esCeunp;

  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [mesas, setMesas] = useState([]);
  const [idMesa, setIdMesa] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [paso, setPaso] = useState('MIEMBROS');
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [lectura, setLectura] = useState(null);          // resultado de la última lectura QR
  const [dni, setDni] = useState({ clave: null, valor: '' }); // acreditación manual en curso
  const [material, setMaterial] = useState({});
  const [observaciones, setObservaciones] = useState('');
  const [materialCambiado, setMaterialCambiado] = useState(false);
  const [confirmando, setConfirmando] = useState(false);
  const [emitida, setEmitida] = useState(null);           // { tokenQr, idActa } tras instalar
  const [motivo, setMotivo] = useState('');
  const [declarando, setDeclarando] = useState(false);

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const aplicarDetalle = useCallback((data) => {
    setDetalle(data);
    const items = {};
    data.material.forEach((m) => { items[m.codigo] = m.recibido; });
    setMaterial(items);
    setObservaciones(data.observaciones ?? '');
    setMaterialCambiado(false);
    setMesas((prev) => prev.map((m) => (m.id === data.mesa.id ? { ...m, ...data.mesa } : m)));
  }, []);

  const cargarMesas = useCallback(async (proceso) => {
    const lista = await apiRequest(esMiembro || !proceso ? '/api/instalacion/mesas' : `/api/instalacion/mesas?procesoId=${proceso}`);
    setMesas(lista);
    return lista;
  }, [esMiembro]);

  useEffect(() => {
    (async () => {
      try {
        let proceso = null;
        if (!esMiembro) {
          const lista = await apiRequest('/api/instalacion/procesos');
          setProcesos(lista);
          proceso = lista[0]?.id ?? null;
          setIdProceso(proceso);
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
  }, [esMiembro, cargarMesas, manejarError]);

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

  async function cambiarProceso(id) {
    setIdProceso(id);
    setIdMesa(null);
    setFeedback(null);
    try {
      const lista = await cargarMesas(id);
      setIdMesa((lista.find((m) => m.estado === 'PENDIENTE') ?? lista[0])?.id ?? null);
    } catch (e) {
      manejarError(e);
    }
  }

  function elegirMesa(id) {
    setIdMesa(id);
    setPaso('MIEMBROS');
    setFeedback(null);
    setLectura(null);
    setEmitida(null);
    setConfirmando(false);
    setDni({ clave: null, valor: '' });
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

  // ─── Paso 1 y 2: acreditación ──────────────────────────────────────────

  const leerCredencial = useCallback(async (codigo) => {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/instalacion/mesas/${idMesa}/acreditar`, { method: 'POST', body: JSON.stringify({ codigo }) });
      setLectura({ hora: new Date(), ...data });
      if (data.detalle) aplicarDetalle(data.detalle);
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
      presente ? 'Acreditación registrada con DNI.' : (tipo === 'miembro' ? 'Se registró la inasistencia.' : 'Se retiró al personero de la instalación.'),
    ).then((ok) => { if (ok) setDni({ clave: null, valor: '' }); });
  }

  /** Botón «Con DNI» o, si está abierto, el formulario para escribir el DNI. */
  function formDni(tipo, id) {
    const clave = `${tipo}-${id}`;
    if (dni.clave !== clave) {
      return (
        <button type="button" className="cv-btn cv-btn-soft cq-mini" disabled={saving} onClick={() => setDni({ clave, valor: '' })}>
          <MenuIcon name="user" size={13} /> Con DNI
        </button>
      );
    }
    return (
      <form className="im-dni" onSubmit={(e) => { e.preventDefault(); asistencia(tipo, id, true, dni.valor); }}>
        <input autoFocus inputMode="numeric" maxLength={8} placeholder="DNI" value={dni.valor}
          aria-label="DNI que presenta la persona" onChange={(e) => setDni({ clave, valor: e.target.value.replace(/\D/g, '') })} />
        <button type="submit" className="cv-btn cv-btn-success cq-mini" disabled={saving || dni.valor.length === 0}>Acreditar</button>
        <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => setDni({ clave: null, valor: '' })}>Cancelar</button>
      </form>
    );
  }

  // ─── Paso 3: material ──────────────────────────────────────────────────

  function marcarMaterial(codigo, valor) {
    setMaterial((prev) => ({ ...prev, [codigo]: valor }));
    setMaterialCambiado(true);
  }

  function marcarTodo() {
    const todo = {};
    detalle.material.forEach((m) => { todo[m.codigo] = true; });
    setMaterial(todo);
    setMaterialCambiado(true);
  }

  function guardarMaterial() {
    return ejecutar(
      apiRequest(`/api/instalacion/mesas/${idMesa}/material`, { method: 'PUT', body: JSON.stringify({ items: material, observaciones }) }),
      (data) => (data.requisitos?.find((r) => r.codigo === 'MATERIAL')?.cumplido
        ? 'Material registrado: todo el material obligatorio fue recibido.'
        : 'Material registrado. Aún falta material obligatorio.'),
    );
  }

  // ─── Paso 4: instalación ───────────────────────────────────────────────

  async function instalar() {
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
    }
  }

  async function refrescar() {
    try {
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
  const personerosPresentes = detalle?.personeros.filter((p) => si(p.presente)).length ?? 0;
  const pendientesRequisito = detalle?.requisitos.filter((r) => !r.cumplido) ?? [];
  const obligatoriosFaltan = detalle?.material.filter((m) => m.obligatorio && !material[m.codigo]).length ?? 0;

  return (
    <div className="pd-shell cq-shell im-shell">
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

      {proceso && (
        <section className="cq-resumen">
          <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
            <span>Mesas del proceso</span>
            <strong>{proceso.mesas}</strong>
            <small>{proceso.pendientes} por instalar</small>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#059669' }}>
            <span>Instaladas <em>RN07</em></span>
            <strong>{proceso.instaladas}<small> / {proceso.mesas}</small></strong>
            <i className="cq-barra"><b style={{ width: `${proceso.mesas ? Math.round((proceso.instaladas / proceso.mesas) * 100) : 0}%` }} /></i>
          </div>
          <div className="cq-kpi" style={{ '--cq-color': '#e11d48' }}>
            <span>No instaladas</span>
            <strong>{proceso.noInstaladas}</strong>
            <small>Sus electores no pueden votar</small>
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
              <p className="muted">{mesa.proceso} · {mesa.totalElectores} electores · proceso en {mesa.estadoProceso}</p>
            </div>
            <span className={`cv-estado ${(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).clase}`}>
              {(ESTADO_MESA[mesa.estado] ?? ESTADO_MESA.PENDIENTE).texto}
              {mesa.horaInstalacion && ` · ${hora(mesa.horaInstalacion)}`}
            </span>
          </div>

          {!puedeOperar && <div className="alert success" role="note">Vista de consulta: la instalación la realizan los miembros de mesa o el CEUNP.</div>}

          <div className="pd-tabs cq-tabs" role="tablist">
            {PASOS.map((p) => {
              const hecho = (p.codigo === 'MIEMBROS' && detalle.conformacion.every((c) => !c.vacante))
                || (p.codigo === 'PERSONEROS' && personerosPresentes > 0)
                || (p.codigo === 'MATERIAL' && detalle.requisitos.find((r) => r.codigo === 'MATERIAL')?.cumplido)
                || (p.codigo === 'ACTA' && detalle.acta);
              return (
                <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
                  className={`pd-tab${paso === p.codigo ? ' on' : ''}`} onClick={() => setPaso(p.codigo)}>
                  {hecho && <MenuIcon name="check" size={13} />} {p.texto}
                </button>
              );
            })}
          </div>

          {/* ── Paso 1: miembros ── */}
          {paso === 'MIEMBROS' && (
            <>
              {editable && (
                <div className="panel cv-form">
                  <div className="cv-section-head">
                    <div>
                      <h3>Acreditar con credencial QR</h3>
                      <p className="muted">Lea el fotocheck del miembro de mesa o la credencial del personero (CUS07). Si no tiene su QR, use «Con DNI» en la tabla.</p>
                    </div>
                  </div>
                  <EscanerQR onCodigo={leerCredencial} deshabilitado={saving} />
                  {lectura && (
                    <div className={`cq-resultado ${lectura.aceptada ? 'ok' : 'mal'}`} role="status" aria-live="polite">
                      <div className="cq-resultado-head">
                        <span className="cq-resultado-icono"><MenuIcon name={lectura.aceptada ? 'check' : 'alert'} size={22} /></span>
                        <div>
                          <strong>{lectura.aceptada ? 'Acreditado' : 'No se acreditó'}</strong>
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
                        ? 'Propuesta según quién está presente: si falta un titular, asume el cargo el primer suplente presente (orden del sorteo).'
                        : 'Cargos con los que se instaló la mesa.'}
                    </p>
                  </div>
                  <span className="im-contador">{presentes} de {detalle.miembros.length} presentes</span>
                </div>
                <div className="im-cargos">
                  {detalle.conformacion.map((c) => (
                    <div key={c.cargo} className={`im-cargo${c.vacante ? ' vacante' : ''}`}>
                      <span>{CARGO[c.cargo]}</span>
                      <strong>{c.vacante ? 'Sin cubrir' : c.nombre}</strong>
                      {c.reemplazo && <em>Suplente · reemplaza a {c.reemplazaA}</em>}
                      {c.vacante && <em>Titular: {c.titular ?? '—'}</em>}
                    </div>
                  ))}
                </div>

                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Orden</th><th>Miembro</th><th>Sorteado como</th><th>Asistencia</th>{editable && <th aria-label="Acciones" />}</tr></thead>
                    <tbody>
                      {detalle.miembros.map((m) => (
                        <tr key={m.idDocente}>
                          <td>{m.ordenSorteo ?? '—'}</td>
                          <td><strong>{m.nombre}</strong><small className="pd-sub">DNI {m.dni} · {m.facultad ?? '—'}</small></td>
                          <td>
                            {CARGO[m.rol]}{si(m.titular) ? ' (titular)' : ''}
                            {m.rolInstalacion && m.rolInstalacion !== m.rol && <small className="pd-sub">Ejerce: {CARGO[m.rolInstalacion]}</small>}
                            {!si(m.credencialVigente) && <small className="pd-sub">Sin fotocheck vigente</small>}
                          </td>
                          <td>
                            {si(m.asistio) && <span className="cv-estado votacion">Presente · {m.metodoAcreditacion} {hora(m.horaAcreditacion)}</span>}
                            {m.asistio !== null && m.asistio !== undefined && !si(m.asistio) && <span className="cv-estado anulado">No asistió</span>}
                            {(m.asistio === null || m.asistio === undefined) && <span className="cv-estado creado">Sin registrar</span>}
                          </td>
                          {editable && (
                            <td className="cq-row-actions">
                              {!si(m.asistio) && formDni('miembro', m.idDocente)}
                              {(si(m.asistio) || m.asistio === null || m.asistio === undefined) && dni.clave !== `miembro-${m.idDocente}` && (
                                <button type="button" className="cv-btn cv-btn-ghost cq-mini" disabled={saving} onClick={() => asistencia('miembro', m.idDocente, false)}>
                                  <MenuIcon name="close" size={13} /> {si(m.asistio) ? 'Quitar' : 'Ausente'}
                                </button>
                              )}
                            </td>
                          )}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('PERSONEROS')}>Continuar con personeros</button>
                </div>
              </div>
            </>
          )}

          {/* ── Paso 2: personeros ── */}
          {paso === 'PERSONEROS' && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Personeros presentes</h3>
                  <p className="muted">Personeros acreditados de esta mesa y personeros generales de las listas en carrera. Su presencia es opcional; los presentes firman el acta. Para registrarlos con QR use el lector del paso 1.</p>
                </div>
                <span className="im-contador">{personerosPresentes} presente(s)</span>
              </div>
              {detalle.personeros.length === 0 ? <p className="empty-state">No hay personeros acreditados para esta mesa (CUS05).</p> : (
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Personero</th><th>Lista</th><th>Tipo</th><th>Presencia</th>{editable && <th aria-label="Acciones" />}</tr></thead>
                    <tbody>
                      {detalle.personeros.map((p) => (
                        <tr key={p.idPersonero}>
                          <td><strong>{p.nombre}</strong><small className="pd-sub">DNI {p.dni}</small></td>
                          <td>{p.lista}<small className="pd-sub">{p.cargo}</small></td>
                          <td>{p.tipo === 'MESA' ? 'De mesa' : p.tipo === 'GENERAL' ? 'General' : 'Alterno'}</td>
                          <td>{si(p.presente) ? <span className="cv-estado votacion">Presente · {p.metodo} {hora(p.horaAcreditacion)}</span> : <span className="cv-estado creado">No registrado</span>}</td>
                          {editable && (
                            <td className="cq-row-actions">
                              {!si(p.presente) && formDni('personero', p.idPersonero)}
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

          {/* ── Paso 3: material ── */}
          {paso === 'MATERIAL' && (
            <div className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Material electoral recibido</h3>
                  <p className="muted">Marque lo que recibió la mesa. Sin el material obligatorio (*) la mesa no se puede instalar.</p>
                </div>
                {editable && <button type="button" className="cv-btn cv-btn-soft" onClick={marcarTodo} disabled={saving}><MenuIcon name="check" size={15} /> Marcar todo</button>}
              </div>
              <ul className="im-material">
                {detalle.material.map((m) => (
                  <li key={m.codigo}>
                    <label>
                      <input type="checkbox" checked={!!material[m.codigo]} disabled={!editable || saving}
                        onChange={(e) => marcarMaterial(m.codigo, e.target.checked)} />
                      <span>{m.descripcion}{m.obligatorio && <b title="Obligatorio"> *</b>}</span>
                    </label>
                  </li>
                ))}
              </ul>
              <label className="cv-field">
                <span className="cv-label">Observaciones de la instalación (opcional)</span>
                <textarea rows={3} maxLength={500} value={observaciones} disabled={!editable || saving}
                  placeholder="Ej.: el cartel llegó a las 08:40; se reemplazó el lapicero del secretario."
                  onChange={(e) => { setObservaciones(e.target.value); setMaterialCambiado(true); }} />
              </label>
              {detalle.registro?.fechaActualizacion && (
                <p className="muted im-nota">Último registro: {fecha(detalle.registro.fechaActualizacion)}{detalle.registro.registradoPor ? ` por ${detalle.registro.registradoPor}` : ''}.</p>
              )}
              {editable && (
                <div className="cv-actions">
                  {obligatoriosFaltan > 0 && <span className="cv-actions-note cv-error">Falta {obligatoriosFaltan} material obligatorio.</span>}
                  <button type="button" className="cv-btn cv-btn-success" disabled={saving || !materialCambiado} onClick={guardarMaterial}>
                    <MenuIcon name="check" size={15} /> {saving ? 'Guardando…' : 'Guardar material'}
                  </button>
                  <button type="button" className="cv-btn cv-btn-primary" disabled={materialCambiado} onClick={() => setPaso('ACTA')}>Continuar con el acta</button>
                </div>
              )}
            </div>
          )}

          {/* ── Paso 4: acta ── */}
          {paso === 'ACTA' && (
            <>
              {mesa.estado === 'PENDIENTE' && (
                <div className="panel cv-form">
                  <div className="cv-section-head">
                    <div>
                      <h3>Instalar la mesa</h3>
                      <p className="muted">Al instalar se emite el Acta de Instalación con huella SHA-256, la firman los tres miembros que ejercen el cargo y los personeros presentes, y se habilita el sufragio de la mesa.</p>
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
                      <button type="button" className="cv-btn cv-btn-success" disabled={saving || !detalle.puedeInstalar} onClick={() => setConfirmando(true)}>
                        <MenuIcon name="shield" size={15} /> Instalar mesa y emitir acta
                      </button>
                    </div>
                  )}
                  {confirmando && (
                    <div className="cq-confirmar-emision" role="alert">
                      <div>
                        <strong>¿Instalar la mesa {mesa.numero}?</strong>
                        <span>
                          Se registrará la hora de instalación y el acta ya no podrá modificarse (RN28). Quienes no se acreditaron quedarán como inasistentes (RN35).
                          {' '}Cargos: {detalle.conformacion.map((c) => `${CARGO[c.cargo]} ${c.nombre ?? '—'}`).join(' · ')}.
                        </span>
                      </div>
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Cancelar</button>
                        <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={instalar}>
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
                            <span className="cv-label">Motivo (RN07)</span>
                            <textarea rows={2} minLength={10} maxLength={255} required value={motivo}
                              placeholder="Ej.: a las 12:00 no se presentaron los miembros suficientes para conformar la mesa."
                              onChange={(e) => setMotivo(e.target.value)} />
                          </label>
                          <div className="cv-actions">
                            <span className="cv-actions-note muted">Sus electores no podrán votar en esta mesa y los miembros no acreditados quedarán como inasistentes.</span>
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
                        <strong>Mesa no instalada</strong>
                        <span>{detalle.registro?.motivoNoInstalacion} · {fecha(detalle.registro?.fechaActualizacion)}{detalle.registro?.cerradoPor ? ` · ${detalle.registro.cerradoPor}` : ''}</span>
                      </div>
                    </div>
                  </div>
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

/** Acta de instalación emitida: datos, firmas y, solo al emitirse, el QR de verificación. */
function ActaVista({ acta, mesa, emitida }) {
  const c = acta.contenido ?? {};
  const token = emitida && emitida.idActa === acta.idActa ? emitida.tokenQr : null;
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
