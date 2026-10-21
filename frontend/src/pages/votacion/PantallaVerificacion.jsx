import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { EscanerQR, fecha } from '../credenciales/LectorQR';
import { imprimirConstancia } from './ImpresoraCedula';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import './votacion.css';

const RESULTADOS = {
  APTO: { clase: 'ok', titulo: 'Elector en el padrón de esta mesa', icono: 'check' },
  HABILITADO: { clase: 'info', titulo: 'Ya tiene un terminal habilitado', icono: 'vote' },
  YA_REGISTRADO: { clase: 'mal', titulo: 'Asistencia ya registrada', icono: 'alert' },
  YA_VOTO: { clase: 'mal', titulo: 'El elector ya votó', icono: 'close' },
  INHABILITADO: { clase: 'mal', titulo: 'Elector inhabilitado', icono: 'close' },
  OTRA_MESA: { clase: 'mal', titulo: 'No vota en esta mesa', icono: 'alert' },
  NO_FIGURA: { clase: 'mal', titulo: 'No figura en el padrón', icono: 'alert' },
  QR_INVALIDO: { clase: 'mal', titulo: 'QR inválido o revocado', icono: 'alert' },
};

const ESTADOS = {
  TODOS: 'Todos', PENDIENTE: 'Pendiente', HABILITADO: 'Habilitado', VOTO: 'Votó',
  HABILITADO_SIN_VOTAR: 'Habilitado sin votar', INHABILITADO: 'Inhabilitado',
};
const ESTADOS_TERMINAL = { LIBRE: 'Libre', HABILITADO: 'Habilitado', EN_USO: 'En uso', FUERA_DE_SERVICIO: 'Fuera de servicio' };
const INCIDENCIAS = {
  QR_INVALIDO: 'QR inválido', NO_FIGURA: 'No figura', OTRA_MESA: 'Otra mesa', YA_REGISTRADO: 'Ya registrado',
  INHABILITADO: 'Inhabilitado', SUPLANTACION: 'Suplantación', ABANDONO_TERMINAL: 'Abandono del terminal',
  FALLA_TERMINAL: 'Falla del terminal', REHABILITACION: 'Rehabilitación',
};
const ACCIONES = {
  RECHAZO: { titulo: 'Rechazar el ingreso (el DNI no corresponde al elector)', ayuda: 'Ej.: la persona no es el titular del DNI', boton: 'Rechazar y registrar' },
  ANULAR: { titulo: 'Anular la habilitación (el elector abandonó el terminal)', ayuda: 'Ej.: se retiró sin confirmar su voto', boton: 'Anular habilitación' },
  REHABILITAR: { titulo: 'Rehabilitar el terminal (autoriza el Presidente)', ayuda: 'Ej.: falló el terminal antes de confirmar', boton: 'Rehabilitar terminal' },
};

const hora = (v) => (v ? new Date(v).toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }) : '—');

function Foto({ elector, grande }) {
  const [error, setError] = useState(false);
  const iniciales = `${elector.nombres?.charAt(0) ?? ''}${elector.apellidos?.charAt(0) ?? ''}`;
  if (elector.urlFoto && !error) {
    return <img className={`vt-foto${grande ? ' grande' : ''}`} src={elector.urlFoto} alt={`Fotografía de ${elector.nombre}`} onError={() => setError(true)} />;
  }
  return <div className={`vt-foto vt-foto-vacia${grande ? ' grande' : ''}`} title="Sin fotografía en el padrón">{iniciales}</div>;
}

/**
 * CUS09 · «PantallaVerificacion» (equipo de mesa, actor: Secretario de mesa).
 *   1 escanearQR() → 2 verificar(token) → 3 consultarHabilitacion() → 4 mostrarDatosYFoto()
 *   → 5 confirmarConDNI() → 6 registrarAsistencia() → 7 habilitarTerminal()
 * Además: A1 búsqueda por DNI, A5 suplantación, abandono y rehabilitación (CUS10 A3), terminales
 * fuera de servicio (CUS10 A4) e impresión de la constancia del elector que votó.
 */
export default function PantallaVerificacion({ onSessionExpired }) {
  const [mesas, setMesas] = useState([]);
  const [idMesa, setIdMesa] = useState('');
  const [tablero, setTablero] = useState(null);
  const [modo, setModo] = useState('QR');
  const [dni, setDni] = useState('');
  const [ficha, setFicha] = useState(null);
  const [idTerminal, setIdTerminal] = useState('');
  const [accion, setAccion] = useState(null);
  const [motivo, setMotivo] = useState('');
  const [filtro, setFiltro] = useState('TODOS');
  const [busqueda, setBusqueda] = useState('');
  const [ocupado, setOcupado] = useState(false);
  const [aviso, setAviso] = useState(null);

  const fallo = useCallback((e) => {
    if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setAviso({ tipo: 'error', texto: e.message });
  }, [onSessionExpired]);

  const cargarTablero = useCallback(async (id, silencioso = false) => {
    if (!id) return;
    try {
      setTablero(await apiRequest(`/api/sufragio/mesas/${id}`));
    } catch (e) {
      if (!silencioso) fallo(e);
    }
  }, [fallo]);

  useEffect(() => {
    apiRequest('/api/sufragio/mesas')
      .then((data) => {
        setMesas(data);
        const instalada = data.find((m) => m.estado === 'INSTALADA') ?? data[0];
        if (instalada) setIdMesa(String(instalada.id));
      })
      .catch(fallo);
  }, [fallo]);

  useEffect(() => {
    setFicha(null);
    setAccion(null);
    setTablero(null);
    cargarTablero(idMesa);
  }, [idMesa, cargarTablero]);

  // Padrón y terminales se refrescan solos para ver quién terminó de votar.
  useEffect(() => {
    if (!idMesa) return undefined;
    const timer = setInterval(() => cargarTablero(idMesa, true), 8000);
    return () => clearInterval(timer);
  }, [idMesa, cargarTablero]);

  const terminalesLibres = useMemo(
    () => (tablero?.terminales ?? []).filter((t) => t.estadoTerminal === 'LIBRE'), [tablero]);

  useEffect(() => {
    if (!terminalesLibres.some((t) => String(t.idTerminal) === idTerminal)) {
      setIdTerminal(terminalesLibres[0] ? String(terminalesLibres[0].idTerminal) : '');
    }
  }, [terminalesLibres, idTerminal]);

  async function ejecutar(promesa, exito) {
    setOcupado(true);
    setAviso(null);
    try {
      const r = await promesa();
      if (exito) setAviso({ tipo: 'success', texto: typeof exito === 'function' ? exito(r) : exito });
      return r ?? true;
    } catch (e) {
      fallo(e);
      return null;
    } finally {
      setOcupado(false);
    }
  }

  async function verificar(cuerpo) {
    setAccion(null);
    const r = await ejecutar(() => apiRequest(`/api/sufragio/mesas/${idMesa}/verificar`, { method: 'POST', body: JSON.stringify(cuerpo) }));
    if (r) {
      setFicha(r);
      cargarTablero(idMesa, true);
    }
  }

  function verificarDni(event) {
    event.preventDefault();
    if (dni.trim()) verificar({ dni: dni.trim() });
  }

  /** 5 confirmarConDNI() → 6 registrarAsistencia() → 7 habilitarTerminal() */
  async function confirmar() {
    const r = await ejecutar(() => apiRequest(`/api/sufragio/mesas/${idMesa}/asistencias`, {
      method: 'POST',
      body: JSON.stringify({ idDocente: ficha.elector.idDocente, metodo: ficha.metodo, idCredencial: ficha.idCredencial ?? null, idTerminal: Number(idTerminal) }),
    }), (resp) => resp.mensaje);
    if (r) {
      setFicha(null);
      setDni('');
      cargarTablero(idMesa);
    }
  }

  function abrirAccion(tipo, elector) {
    setAccion({ tipo, elector });
    setMotivo('');
  }

  async function confirmarAccion(event) {
    event.preventDefault();
    const { tipo, elector } = accion;
    let llamada;
    if (tipo === 'RECHAZO') {
      llamada = () => apiRequest(`/api/sufragio/mesas/${idMesa}/rechazos`, {
        method: 'POST', body: JSON.stringify({ idDocente: elector?.idDocente ?? null, dni: elector?.dni ?? (dni || null), motivo }),
      });
    } else if (tipo === 'ANULAR') {
      llamada = () => apiRequest(`/api/sufragio/mesas/${idMesa}/habilitaciones/${elector.idHabilitacion}/anular`, {
        method: 'POST', body: JSON.stringify({ motivo }),
      });
    } else {
      llamada = () => apiRequest(`/api/sufragio/mesas/${idMesa}/rehabilitaciones`, {
        method: 'POST', body: JSON.stringify({ idDocente: elector.idDocente, idTerminal: Number(idTerminal), motivo }),
      });
    }
    const r = await ejecutar(llamada, (resp) => resp.mensaje);
    if (r) {
      setAccion(null);
      setFicha(null);
      setDni('');
      cargarTablero(idMesa);
    }
  }

  async function cambiarTerminal(t) {
    const r = await ejecutar(() => apiRequest(`/api/sufragio/mesas/${idMesa}/terminales/${t.idTerminal}`, {
      method: 'PUT', body: JSON.stringify({ activo: !t.activo }),
    }), t.activo ? `${t.nombre} quedó fuera de servicio.` : `${t.nombre} volvió a operar.`);
    if (Array.isArray(r)) setTablero((prev) => ({ ...prev, terminales: r }));
  }

  async function entregarConstancia(elector) {
    const c = await ejecutar(() => apiRequest(`/api/sufragio/mesas/${idMesa}/constancias/${elector.idDocente}`));
    if (!c) return;
    await imprimirConstancia(c);
    // eslint-disable-next-line no-alert
    if (window.confirm(`¿Se imprimió y entregó la constancia a ${elector.nombre}?`)) {
      await ejecutar(() => apiRequest(`/api/sufragio/mesas/${idMesa}/constancias/${elector.idDocente}`, { method: 'DELETE' }),
        'Constancia entregada.');
    }
  }

  const electores = useMemo(() => {
    const texto = busqueda.trim().toLowerCase();
    return (tablero?.electores ?? []).filter((e) =>
      (filtro === 'TODOS' || e.estadoElector === filtro)
      && (!texto || e.nombre.toLowerCase().includes(texto) || e.dni.includes(texto)));
  }, [tablero, filtro, busqueda]);

  const mesa = tablero?.mesa;
  const resumen = tablero?.resumen;
  const puedeRehabilitar = tablero?.puedeRehabilitar;
  const info = ficha ? RESULTADOS[ficha.resultado] ?? RESULTADOS.NO_FIGURA : null;
  const elector = ficha?.elector;
  const selectorTerminal = (
    <label className="vt-terminal-select">
      Terminal
      <select value={idTerminal} onChange={(e) => setIdTerminal(e.target.value)} disabled={!terminalesLibres.length}>
        {!terminalesLibres.length && <option value="">No hay terminales libres</option>}
        {terminalesLibres.map((t) => <option key={t.idTerminal} value={t.idTerminal}>{t.nombre}</option>)}
      </select>
    </label>
  );

  return (
    <div className="pd-shell vt-shell">
      <div className="panel vt-head">
        <label>
          Mesa de sufragio
          <select value={idMesa} onChange={(e) => setIdMesa(e.target.value)} disabled={!mesas.length}>
            {!mesas.length && <option value="">No tiene mesas asignadas</option>}
            {mesas.map((m) => <option key={m.id} value={m.id}>Mesa {m.numero} · {m.ubicacion} · {m.estado}</option>)}
          </select>
        </label>
        {mesa && <span className={`badge ${mesa.estado === 'INSTALADA' ? 'votacion' : 'cerrado'}`}>{mesa.estado}</span>}
        <div className="vt-head-actions">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={() => cargarTablero(idMesa)} disabled={!idMesa || ocupado}>
            <MenuIcon name="list" size={15} /> Actualizar
          </button>
        </div>
      </div>

      {aviso && <div className={`alert ${aviso.tipo}`} role="alert" onClick={() => setAviso(null)}>{aviso.texto}</div>}

      {mesa && !mesa.atiende && (
        <div className="vt-aviso">
          <MenuIcon name="alert" size={18} />
          <div><strong>La mesa no puede atender electores.</strong>{mesa.motivoNoAtiende}</div>
        </div>
      )}

      {resumen && (
        <section className="pd-stats vt-stats">
          <div className="pd-stat amber"><span className="pd-stat-label">Pendientes</span><strong>{resumen.PENDIENTE}</strong><span className="pd-stat-sub">de {resumen.electores} electores</span></div>
          <div className="pd-stat"><span className="pd-stat-label">Habilitados</span><strong>{resumen.HABILITADO}</strong><span className="pd-stat-sub">en un terminal</span></div>
          <div className="pd-stat green"><span className="pd-stat-label">Votaron</span><strong>{resumen.VOTO}</strong><span className="pd-stat-sub">{resumen.participacion}% de participación</span></div>
          <div className="pd-stat red"><span className="pd-stat-label">Habilitados sin votar</span><strong>{resumen.HABILITADO_SIN_VOTAR}</strong><span className="pd-stat-sub">incidencias por resolver</span></div>
          <div className="pd-stat"><span className="pd-stat-label">Inhabilitados</span><strong>{resumen.INHABILITADO}</strong></div>
        </section>
      )}

      {tablero && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Terminales de votación</h3>
              <p className="muted">Para conectar un equipo de cabina, ábralo en «Terminal de votación» con la cuenta de la mesa.</p>
            </div>
          </div>
          {!tablero.terminales.length && <p className="vt-vacio">Aún no hay terminales conectados a esta mesa.</p>}
          <div className="vt-terminales">
            {tablero.terminales.map((t) => (
              <div key={t.idTerminal} className={`vt-terminal ${t.estadoTerminal}`}>
                <MenuIcon name="vote" size={18} />
                <div>
                  <strong>{t.nombre}</strong>
                  <span>{ESTADOS_TERMINAL[t.estadoTerminal]}{t.estadoTerminal !== 'LIBRE' && t.fechaHabilitacion ? ` desde ${hora(t.fechaHabilitacion)}` : ''}</span>
                </div>
                <button type="button" className="cv-btn cv-btn-ghost vt-mini" disabled={ocupado || t.estadoTerminal === 'HABILITADO' || t.estadoTerminal === 'EN_USO'}
                  onClick={() => cambiarTerminal(t)}>
                  {t.activo ? 'Fuera de servicio' : 'Reactivar'}
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {mesa && (
        <div className="vt-grid">
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>1. Identificar elector</h3>
                <p className="muted">Escanee el QR del pase de votación. Si no se puede leer, busque por DNI.</p>
              </div>
            </div>
            <div className="pd-tabs" role="tablist">
              {['QR', 'DNI'].map((m) => (
                <button key={m} type="button" role="tab" aria-selected={modo === m} className={`pd-tab${modo === m ? ' on' : ''}`}
                  onClick={() => { setModo(m); setFicha(null); setAccion(null); }}>
                  {m === 'QR' ? 'Escanear QR' : 'Buscar por DNI'}
                </button>
              ))}
            </div>
            {modo === 'QR' ? (
              <EscanerQR onCodigo={(codigo) => verificar({ codigo })} deshabilitado={ocupado || !mesa.atiende} />
            ) : (
              <form className="vt-dni" onSubmit={verificarDni}>
                <input value={dni} inputMode="numeric" maxLength={8} placeholder="DNI del elector (8 dígitos)"
                  aria-label="DNI del elector" onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))} />
                <button type="submit" className="cv-btn cv-btn-primary" disabled={ocupado || !dni || !mesa.atiende}>
                  <MenuIcon name="check" size={15} /> Buscar
                </button>
              </form>
            )}
          </div>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>2. Comparar y confirmar</h3>
                <p className="muted">Compare los nombres y la fotografía con el DNI y con el rostro del elector.</p>
              </div>
            </div>
            {!ficha && <p className="vt-vacio">Aún no se ha verificado a ningún elector.</p>}
            {ficha && (
              <div className={`cq-resultado ${info.clase}`} role="status" aria-live="polite">
                <div className="cq-resultado-head">
                  <span className="cq-resultado-icono"><MenuIcon name={info.icono} size={22} /></span>
                  <div><strong>{info.titulo}</strong><span>{ficha.mensaje}</span></div>
                </div>
                {elector && (
                  <div className="vt-ficha">
                    <Foto elector={elector} grande />
                    <div className="in-cand-body">
                      <strong>{elector.apellidos}, {elector.nombres}</strong>
                      <span>DNI <b>{elector.dni}</b></span>
                      <span>{elector.categoria} · {elector.facultad ?? '—'}</span>
                      <span>Identificado con {ficha.metodo === 'QR' ? 'pase QR' : 'búsqueda por DNI'}</span>
                    </div>
                  </div>
                )}
                <div className="vt-ficha-acciones">
                  {ficha.apto && (
                    <>
                      {selectorTerminal}
                      <button type="button" className="cv-btn cv-btn-success" onClick={confirmar} disabled={ocupado || !idTerminal}>
                        <MenuIcon name="check" size={16} /> Confirmar con DNI y habilitar terminal
                      </button>
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => abrirAccion('RECHAZO', elector)} disabled={ocupado}>
                        <MenuIcon name="close" size={15} /> El DNI no corresponde
                      </button>
                    </>
                  )}
                  {ficha.resultado === 'HABILITADO' && (
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => abrirAccion('ANULAR', elector)} disabled={ocupado}>
                      Anular habilitación
                    </button>
                  )}
                  {ficha.resultado === 'YA_REGISTRADO' && puedeRehabilitar && (
                    <button type="button" className="cv-btn cv-btn-primary" onClick={() => abrirAccion('REHABILITAR', elector)} disabled={ocupado}>
                      Rehabilitar terminal
                    </button>
                  )}
                  {ficha.resultado === 'QR_INVALIDO' && (
                    <button type="button" className="cv-btn cv-btn-primary" onClick={() => { setModo('DNI'); setFicha(null); }}>
                      Verificar por DNI
                    </button>
                  )}
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => { setFicha(null); setDni(''); setAccion(null); }}>
                    Siguiente elector
                  </button>
                </div>
              </div>
            )}
            {accion && (
              <form className="vt-anular" onSubmit={confirmarAccion}>
                <strong>{ACCIONES[accion.tipo].titulo}{accion.elector ? ` · ${accion.elector.nombre}` : ''}</strong>
                {accion.tipo === 'REHABILITAR' && selectorTerminal}
                <input value={motivo} maxLength={255} placeholder={`Motivo. ${ACCIONES[accion.tipo].ayuda}`}
                  onChange={(e) => setMotivo(e.target.value)} />
                <div className="vt-ficha-acciones">
                  <button type="submit" className="cv-btn cv-btn-primary"
                    disabled={ocupado || motivo.trim().length < 5 || (accion.tipo === 'REHABILITAR' && !idTerminal)}>
                    {ACCIONES[accion.tipo].boton}
                  </button>
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAccion(null)}>Cancelar</button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {tablero && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Padrón de la mesa {mesa.numero}</h3>
              <p className="muted">Muestra quién asistió y quién votó, nunca por quién.</p>
            </div>
          </div>
          <div className="vt-filtros">
            <input type="search" value={busqueda} placeholder="Buscar por nombre o DNI" onChange={(e) => setBusqueda(e.target.value)} />
            <div className="cq-chips">
              {Object.entries(ESTADOS).map(([clave, texto]) => (
                <button key={clave} type="button" className={`cq-chip${filtro === clave ? ' on' : ''}`} onClick={() => setFiltro(clave)}>{texto}</button>
              ))}
            </div>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th /><th>DNI</th><th>Elector</th><th>Estado</th><th>Asistencia</th><th>Terminal</th><th /></tr>
              </thead>
              <tbody>
                {electores.map((e) => (
                  <tr key={e.idDocente}>
                    <td><Foto elector={e} /></td>
                    <td>{e.dni}</td>
                    <td><strong>{e.nombre}</strong><br /><small className="muted">{e.categoria} · {e.facultad ?? '—'}</small></td>
                    <td><span className={`vt-estado ${e.estadoElector}`}>{ESTADOS[e.estadoElector]}</span></td>
                    <td>{e.horaAsistencia ? `${hora(e.horaAsistencia)} (${e.metodoAsistencia})` : '—'}</td>
                    <td>{e.terminal ?? '—'}</td>
                    <td className="vt-acciones">
                      {e.estadoElector === 'PENDIENTE' && (
                        <button type="button" className="cv-btn cv-btn-soft vt-mini" disabled={ocupado || !mesa.atiende}
                          onClick={() => { setModo('DNI'); setDni(e.dni); verificar({ dni: e.dni }); }}>Verificar</button>
                      )}
                      {e.estadoElector === 'HABILITADO' && (
                        <button type="button" className="cv-btn cv-btn-ghost vt-mini" disabled={ocupado} onClick={() => abrirAccion('ANULAR', e)}>Anular</button>
                      )}
                      {e.estadoElector === 'HABILITADO_SIN_VOTAR' && puedeRehabilitar && (
                        <button type="button" className="cv-btn cv-btn-soft vt-mini" disabled={ocupado || !mesa.atiende} onClick={() => abrirAccion('REHABILITAR', e)}>Rehabilitar</button>
                      )}
                      {e.estadoElector === 'VOTO' && (
                        <button type="button" className="cv-btn cv-btn-ghost vt-mini" disabled={ocupado} onClick={() => entregarConstancia(e)}>Constancia</button>
                      )}
                    </td>
                  </tr>
                ))}
                {!electores.length && <tr><td colSpan={7} className="vt-vacio">No hay electores con ese filtro.</td></tr>}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {tablero?.incidencias?.length > 0 && (
        <div className="panel cv-form">
          <h3 className="cq-h3">Incidencias de la mesa (RF66)</h3>
          <div className="table-wrap">
            <table>
              <thead><tr><th>Hora</th><th>Tipo</th><th>Elector</th><th>Detalle</th><th>Registró</th></tr></thead>
              <tbody>
                {tablero.incidencias.map((i) => (
                  <tr key={i.idIncidencia}>
                    <td>{fecha(i.fecha)}</td>
                    <td><span className={`vt-estado ${i.tipo === 'REHABILITACION' ? 'HABILITADO' : 'INHABILITADO'}`}>{INCIDENCIAS[i.tipo] ?? i.tipo}</span></td>
                    <td>{i.nombre ? <>{i.nombre}<br /><small className="muted">DNI {i.dni}</small></> : '—'}</td>
                    <td>{i.detalle ?? '—'}</td>
                    <td>{i.registradoPor ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
