import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { EscanerQR, fecha } from '../credenciales/LectorQR';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import './votacion.css';

const RESULTADOS = {
  APTO: { clase: 'ok', titulo: 'Elector apto para votar', icono: 'check' },
  AUTORIZADO: { clase: 'info', titulo: 'Ya tiene la cabina habilitada', icono: 'vote' },
  YA_VOTO: { clase: 'mal', titulo: 'El elector ya votó', icono: 'close' },
  INHABILITADO: { clase: 'mal', titulo: 'Elector inhabilitado', icono: 'close' },
  OTRA_MESA: { clase: 'mal', titulo: 'No vota en esta mesa', icono: 'alert' },
  NO_FIGURA: { clase: 'mal', titulo: 'No figura en el padrón', icono: 'alert' },
  CREDENCIAL_INVALIDA: { clase: 'mal', titulo: 'Pase QR no válido', icono: 'alert' },
  MESA_NO_ATIENDE: { clase: 'mal', titulo: 'La mesa no puede atender', icono: 'lock' },
};

const ESTADOS = {
  TODOS: 'Todos', PENDIENTE: 'Por votar', AUTORIZADO: 'En cabina', VOTO: 'Votaron', INHABILITADO: 'Inhabilitados',
};

const hora = (v) => (v ? new Date(v).toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }) : '—');

/**
 * CUS09 · Verificar elector («PantallaMesa»).
 *   1 identificarElector(QR | DNI) → 2 consultarPadronMesa → 3 validarNoVoto → 4 autorizarCabina
 * Requiere la mesa INSTALADA (CUS08). La cabina autorizada es la que habilita el CUS10 Emitir voto.
 */
export default function VerificarElectorPage({ onSessionExpired }) {
  const [mesas, setMesas] = useState([]);
  const [idMesa, setIdMesa] = useState('');
  const [tablero, setTablero] = useState(null);
  const [modo, setModo] = useState('QR');
  const [dni, setDni] = useState('');
  const [ficha, setFicha] = useState(null);
  const [anulando, setAnulando] = useState(null);
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
    setTablero(null);
    cargarTablero(idMesa);
  }, [idMesa, cargarTablero]);

  // El padrón se refresca solo para ver cuándo terminan de votar los electores en cabina.
  useEffect(() => {
    if (!idMesa) return undefined;
    const timer = setInterval(() => cargarTablero(idMesa, true), 15000);
    return () => clearInterval(timer);
  }, [idMesa, cargarTablero]);

  async function verificar(cuerpo) {
    setOcupado(true);
    setAviso(null);
    setAnulando(null);
    try {
      setFicha(await apiRequest(`/api/sufragio/mesas/${idMesa}/verificar`, { method: 'POST', body: JSON.stringify(cuerpo) }));
    } catch (e) {
      fallo(e);
    } finally {
      setOcupado(false);
    }
  }

  function verificarDni(event) {
    event.preventDefault();
    if (dni.trim()) verificar({ dni: dni.trim() });
  }

  async function autorizar() {
    const elector = ficha?.elector;
    if (!elector) return;
    setOcupado(true);
    try {
      const r = await apiRequest(`/api/sufragio/mesas/${idMesa}/autorizaciones`, {
        method: 'POST',
        body: JSON.stringify({ idDocente: elector.idDocente, metodo: ficha.metodo, idCredencial: ficha.idCredencial ?? null }),
      });
      setAviso({ tipo: 'success', texto: `${r.mensaje} La autorización vence a las ${hora(r.autorizacion?.fechaExpiracion)}` });
      setFicha(null);
      setDni('');
      await cargarTablero(idMesa);
    } catch (e) {
      fallo(e);
    } finally {
      setOcupado(false);
    }
  }

  async function confirmarAnulacion(event) {
    event.preventDefault();
    setOcupado(true);
    try {
      setTablero(await apiRequest(`/api/sufragio/mesas/${idMesa}/autorizaciones/${anulando.idAutorizacion}/anular`, {
        method: 'POST', body: JSON.stringify({ motivo }),
      }));
      setAviso({ tipo: 'success', texto: `Se anuló la autorización de ${anulando.nombre}.` });
      setAnulando(null);
      setMotivo('');
      setFicha(null);
    } catch (e) {
      fallo(e);
    } finally {
      setOcupado(false);
    }
  }

  function pedirAnulacion(elector) {
    setAnulando({ idAutorizacion: elector.idAutorizacion, nombre: elector.nombre });
    setMotivo('');
  }

  const electores = useMemo(() => {
    const texto = busqueda.trim().toLowerCase();
    return (tablero?.electores ?? []).filter((e) =>
      (filtro === 'TODOS' || e.estadoElector === filtro)
      && (!texto || e.nombre.toLowerCase().includes(texto) || e.dni.includes(texto)));
  }, [tablero, filtro, busqueda]);

  const mesa = tablero?.mesa;
  const resumen = tablero?.resumen;
  const info = ficha ? RESULTADOS[ficha.resultado] ?? RESULTADOS.NO_FIGURA : null;
  const elector = ficha?.elector;

  return (
    <div className="pd-shell vt-shell">
      <div className="panel vt-head">
        <label>
          Mesa de sufragio
          <select value={idMesa} onChange={(e) => setIdMesa(e.target.value)} disabled={!mesas.length}>
            {!mesas.length && <option value="">No tiene mesas asignadas</option>}
            {mesas.map((m) => (
              <option key={m.id} value={m.id}>Mesa {m.numero} · {m.ubicacion} · {m.estado}</option>
            ))}
          </select>
        </label>
        {mesa && <span className={`badge ${mesa.estado === 'INSTALADA' ? 'votacion' : 'cerrado'}`}>{mesa.estado}</span>}
        <div className="vt-head-actions">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={() => cargarTablero(idMesa)} disabled={!idMesa || ocupado}>
            <MenuIcon name="list" size={15} /> Actualizar padrón
          </button>
        </div>
      </div>

      {aviso && <div className={`alert ${aviso.tipo}`} role="alert" onClick={() => setAviso(null)}>{aviso.texto}</div>}

      {mesa && !mesa.atiende && (
        <div className="vt-aviso">
          <MenuIcon name="alert" size={18} />
          <div>
            <strong>La mesa no puede atender electores.</strong>
            {mesa.motivoNoAtiende} {mesa.estado === 'PENDIENTE' && 'Instálela desde «Mi Mesa de Sufragio».'}
          </div>
        </div>
      )}

      {resumen && (
        <section className="pd-stats vt-stats">
          <div className="pd-stat"><span className="pd-stat-label">Electores de la mesa</span><strong>{resumen.electores}</strong></div>
          <div className="pd-stat green"><span className="pd-stat-label">Votaron</span><strong>{resumen.voto}</strong><span className="pd-stat-sub">{resumen.participacion}% de participación</span></div>
          <div className="pd-stat"><span className="pd-stat-label">En cabina</span><strong>{resumen.autorizado}</strong><span className="pd-stat-sub">autorizados sin terminar</span></div>
          <div className="pd-stat amber"><span className="pd-stat-label">Por votar</span><strong>{resumen.pendiente}</strong></div>
          <div className="pd-stat red"><span className="pd-stat-label">Inhabilitados</span><strong>{resumen.inhabilitado}</strong></div>
        </section>
      )}

      {mesa && (
        <div className="vt-grid">
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Identificar elector</h3>
                <p className="muted">Lea su pase de votación QR o digite su DNI. Compare la foto del DNI con la persona.</p>
              </div>
            </div>
            <div className="pd-tabs" role="tablist">
              {['QR', 'DNI'].map((m) => (
                <button key={m} type="button" role="tab" aria-selected={modo === m} className={`pd-tab${modo === m ? ' on' : ''}`}
                  onClick={() => { setModo(m); setFicha(null); }}>
                  {m === 'QR' ? 'Pase QR' : 'DNI'}
                </button>
              ))}
            </div>
            {modo === 'QR' ? (
              <EscanerQR onCodigo={(codigo) => verificar({ codigo })} deshabilitado={ocupado || !mesa.atiende} />
            ) : (
              <form className="vt-dni" onSubmit={verificarDni}>
                <input value={dni} inputMode="numeric" maxLength={8} autoFocus placeholder="DNI del elector (8 dígitos)"
                  aria-label="DNI del elector" onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))} />
                <button type="submit" className="cv-btn cv-btn-primary" disabled={ocupado || !dni || !mesa.atiende}>
                  <MenuIcon name="check" size={15} /> Verificar
                </button>
              </form>
            )}
          </div>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Resultado de la verificación</h3>
                <p className="muted">La cabina se habilita por {tablero.minutosAutorizacion} minutos para el elector verificado.</p>
              </div>
            </div>
            {!ficha && <p className="vt-vacio">Aún no se ha verificado a ningún elector.</p>}
            {ficha && (
              <div className={`cq-resultado ${info.clase}`} role="status" aria-live="polite">
                <div className="cq-resultado-head">
                  <span className="cq-resultado-icono"><MenuIcon name={info.icono} size={22} /></span>
                  <div>
                    <strong>{info.titulo}</strong>
                    <span>{ficha.mensaje}</span>
                  </div>
                </div>
                {elector && (
                  <div className="cq-titular">
                    <div className="in-avatar">{elector.nombre.charAt(0)}</div>
                    <div className="in-cand-body">
                      <strong>{elector.nombre}</strong>
                      <span>DNI {elector.dni} · {elector.categoria} · {elector.facultad ?? '—'}</span>
                      <span>Identificado con {ficha.metodo === 'QR' ? 'pase QR' : 'DNI'} · votó {elector.cargosVotados} de {elector.cargos} cargo(s)</span>
                    </div>
                  </div>
                )}
                <div className="vt-ficha-acciones">
                  {ficha.apto && (
                    <button type="button" className="cv-btn cv-btn-success" onClick={autorizar} disabled={ocupado}>
                      <MenuIcon name="vote" size={16} /> Habilitar cabina de votación
                    </button>
                  )}
                  {ficha.resultado === 'AUTORIZADO' && elector && (
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => pedirAnulacion(elector)} disabled={ocupado}>
                      <MenuIcon name="close" size={15} /> Anular autorización
                    </button>
                  )}
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => { setFicha(null); setDni(''); }}>
                    Siguiente elector
                  </button>
                </div>
              </div>
            )}
            {anulando && (
              <form className="vt-anular" onSubmit={confirmarAnulacion}>
                <strong>Anular la autorización de {anulando.nombre}</strong>
                <input value={motivo} maxLength={255} autoFocus placeholder="Motivo (por ejemplo: el elector se retiró sin votar)"
                  onChange={(e) => setMotivo(e.target.value)} />
                <div className="vt-ficha-acciones">
                  <button type="submit" className="cv-btn cv-btn-primary" disabled={ocupado || motivo.trim().length < 5}>Confirmar anulación</button>
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setAnulando(null)}>Cancelar</button>
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
              <p className="muted">Solo muestra quién votó, nunca por quién. Se actualiza cada 15 segundos.</p>
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
                <tr><th>DNI</th><th>Elector</th><th>Cargos votados</th><th>Estado</th><th>Hora</th><th /></tr>
              </thead>
              <tbody>
                {electores.map((e) => (
                  <tr key={e.idDocente}>
                    <td>{e.dni}</td>
                    <td><strong>{e.nombre}</strong><br /><small className="muted">{e.categoria} · {e.facultad ?? '—'}</small></td>
                    <td>{e.cargosVotados} / {e.cargos}</td>
                    <td><span className={`vt-estado ${e.estadoElector}`}>{ESTADOS[e.estadoElector] ?? e.estadoElector}</span></td>
                    <td>{e.estadoElector === 'AUTORIZADO' ? `vence ${hora(e.autorizacionVence)}` : e.estadoElector === 'VOTO' ? hora(e.ultimaVotacion) : '—'}</td>
                    <td className="vt-acciones">
                      {e.estadoElector === 'PENDIENTE' && (
                        <button type="button" className="cv-btn cv-btn-soft vt-mini" disabled={ocupado || !mesa.atiende}
                          onClick={() => { setModo('DNI'); setDni(e.dni); verificar({ dni: e.dni }); }}>
                          Verificar
                        </button>
                      )}
                      {e.estadoElector === 'AUTORIZADO' && (
                        <button type="button" className="cv-btn cv-btn-ghost vt-mini" disabled={ocupado} onClick={() => pedirAnulacion(e)}>
                          Anular
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
                {!electores.length && (
                  <tr><td colSpan={6} className="vt-vacio">No hay electores con ese filtro.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {tablero?.autorizaciones?.length > 0 && (
        <div className="panel cv-form">
          <h3 className="cq-h3">Autorizaciones de cabina de esta mesa</h3>
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>Elector</th><th>Identificado con</th><th>Autorizado</th><th>Estado</th><th>Detalle</th></tr>
              </thead>
              <tbody>
                {tablero.autorizaciones.map((a) => (
                  <tr key={a.idAutorizacion}>
                    <td><strong>{a.nombre}</strong><br /><small className="muted">DNI {a.dni}</small></td>
                    <td>{a.metodo === 'QR' ? 'Pase QR' : 'DNI'}</td>
                    <td>{fecha(a.fechaAutorizacion)}<br /><small className="muted">por {a.autorizadoPor ?? '—'}</small></td>
                    <td><span className={`vt-estado ${a.estado === 'PENDIENTE' ? 'AUTORIZADO' : a.estado}`}>{a.estado}</span></td>
                    <td>{a.estado === 'USADA' ? `Votó a las ${hora(a.fechaUso)}` : a.estado === 'ANULADA' ? a.motivoAnulacion : `Vence ${hora(a.fechaExpiracion)}`}</td>
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
