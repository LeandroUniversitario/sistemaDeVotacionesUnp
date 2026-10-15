import { useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { ListaCredencialesQR, TIPOS_CREDENCIAL, fecha, numeroCredencial } from './LectorQR';
import VerificarCredencialPanel from './VerificarCredencialPanel';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../tachas/tachas.css';
import '../personeros/personeros.css';
import './credenciales.css';

/**
 * CUS07 · Emitir credenciales y QR — «PantallaCredenciales» (boundary).
 *
 * Mensajes del diagrama de colaboración:
 *   1 solicitarCredencial(id_docente)  (CEUNP → PantallaCredenciales; uno o varios titulares)
 *   2 crearHash(id_docente) → GenerarTokenQR  · calcularSHA256() · 3 consultarDatos(id_docente) → Docente
 *   4 guardarConstancia(token_hash) → EmitirConstancia · 5 insertar(token_qr_hash, id_docente) → CredencialQR
 *   6 renderizarQR(token_hash) → LectorQR · 7 mostrarCredencialLista() → PantallaCredenciales
 */

const TABS = ['ELECTOR', 'MIEMBRO_MESA', 'PERSONERO'];
const FILTROS = [
  { codigo: 'todos', texto: 'Todos' },
  { codigo: 'pendientes', texto: 'Sin credencial' },
  { codigo: 'vigentes', texto: 'Con credencial' },
  { codigo: 'noaptos', texto: 'No aptos' },
];
const POR_PAGINA = 100;
const ESTADO_PROCESO = { CREADO: 'creado', INSCRIPCION: 'inscripcion', VOTACION: 'votacion', CERRADO: 'anulado', FINALIZADO: 'anulado' };

export default function CredencialesPage({ onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [tab, setTab] = useState('ELECTOR');
  const [detalle, setDetalle] = useState(null);       // { proceso, tipo, resumen, titulares }
  const [historial, setHistorial] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const [busqueda, setBusqueda] = useState('');
  const [filtro, setFiltro] = useState('todos');
  const [pagina, setPagina] = useState(1);
  const [seleccion, setSeleccion] = useState(() => new Set());
  const [confirmando, setConfirmando] = useState(null);  // { ids, reemplazos }
  const [emitido, setEmitido] = useState(null);           // respuesta de la emisión (7)
  const [revocando, setRevocando] = useState(null);
  const [motivo, setMotivo] = useState('');

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/credenciales/procesos');
        setProcesos(lista);
        if (lista[0]) {
          setIdProceso(lista[0].id);
          await cargar(lista[0].id, 'ELECTOR');
        }
      } catch (error) {
        manejarError(error);
      } finally {
        setCargando(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function cargar(id, tipo) {
    if (TABS.includes(tipo)) {
      setDetalle(await apiRequest(`/api/credenciales/procesos/${id}?tipo=${tipo}`));
      return;
    }
    // Verificar / Historial: el resumen de arriba debe ser del proceso elegido
    if (detalle?.proceso?.id !== id) {
      setDetalle(await apiRequest(`/api/credenciales/procesos/${id}?tipo=ELECTOR`));
    }
    if (tipo === 'HISTORIAL') {
      setHistorial(await apiRequest(`/api/credenciales/procesos/${id}/historial`));
    }
  }

  function reiniciarVista() {
    setSeleccion(new Set());
    setPagina(1);
    setConfirmando(null);
    setRevocando(null);
  }

  async function cambiarProceso(id) {
    setIdProceso(id);
    setFeedback(null);
    reiniciarVista();
    try { await cargar(id, tab); } catch (error) { manejarError(error); }
  }

  async function cambiarTab(nuevo) {
    setTab(nuevo);
    setFeedback(null);
    setBusqueda('');
    setFiltro('todos');
    reiniciarVista();
    try { await cargar(idProceso, nuevo); } catch (error) { manejarError(error); }
  }

  const titulares = useMemo(() => {
    if (!detalle || detalle.tipo !== tab) return [];
    const q = busqueda.trim().toLowerCase();
    return detalle.titulares.filter((t) => {
      if (filtro === 'pendientes' && (!t.apto || t.credencial)) return false;
      if (filtro === 'vigentes' && !t.credencial) return false;
      if (filtro === 'noaptos' && t.apto) return false;
      if (!q) return true;
      return [t.nombre, t.dni, t.numeroMesa, t.funcion].some((v) => String(v ?? '').toLowerCase().includes(q));
    });
  }, [detalle, tab, busqueda, filtro]);

  const admite = Boolean(detalle?.proceso?.admiteEmision);
  const visibles = titulares.slice(0, pagina * POR_PAGINA);
  const seleccionables = titulares.filter((t) => t.apto);
  const pendientes = (detalle?.titulares ?? []).filter((t) => t.apto && !t.credencial);
  const todosMarcados = seleccionables.length > 0 && seleccionables.every((t) => seleccion.has(t.idTitular));

  function alternar(id) {
    setSeleccion((prev) => {
      const nuevo = new Set(prev);
      if (nuevo.has(id)) nuevo.delete(id); else nuevo.add(id);
      return nuevo;
    });
  }

  function alternarTodos() {
    setSeleccion(todosMarcados ? new Set() : new Set(seleccionables.map((t) => t.idTitular)));
  }

  // ─── 1 solicitarCredencial(id_docente) ───────────────────────────────────
  function solicitarCredencial(ids) {
    if (ids.length === 0) return;
    const reemplazos = detalle.titulares.filter((t) => ids.includes(t.idTitular) && t.credencial).length;
    setRevocando(null);
    setFeedback(null);
    setConfirmando({ ids, reemplazos });
  }

  async function confirmarEmision() {
    const { ids } = confirmando;
    setSaving(true);
    setFeedback(null);
    try {
      // 2-6 en el servidor: crearHash → calcularSHA256 → consultarDatos → guardarConstancia → insertar → renderizarQR
      const data = await apiRequest(`/api/credenciales/procesos/${idProceso}/emitir`, {
        method: 'POST',
        body: JSON.stringify({ tipo: tab, ids }),
      });
      setConfirmando(null);
      setSeleccion(new Set());
      setEmitido(data);       // 7 mostrarCredencialLista()
      await cargar(idProceso, tab);
      setProcesos(await apiRequest('/api/credenciales/procesos'));
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  async function revocar() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/credenciales/${revocando.credencial.id}/revocar`, {
        method: 'POST',
        body: JSON.stringify({ motivo }),
      });
      setFeedback({ type: 'success', text: data.mensaje });
      setRevocando(null);
      setMotivo('');
      await cargar(idProceso, tab);
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  if (cargando) return <p className="empty-state">Cargando…</p>;
  if (procesos.length === 0) {
    return (
      <div className="panel cv-placeholder">
        <span className="cv-placeholder-icon"><MenuIcon name="qr" size={28} /></span>
        <h2>No hay procesos electorales</h2>
        <p className="muted">Las credenciales se emiten para un proceso con padrón aprobado (CUS02), mesas sorteadas (CUS06) y personeros acreditados (CUS05).</p>
      </div>
    );
  }

  const proceso = detalle?.proceso ?? procesos.find((p) => p.id === idProceso);
  const resumen = detalle?.resumen;

  return (
    <div className="pd-shell cq-shell">
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => cambiarProceso(Number(e.target.value))}>
            {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
          </select>
        </label>
        {proceso && (
          <div className={`in-plazo ${proceso.admiteEmision ? 'open' : 'closed'}`}>
            <MenuIcon name={proceso.admiteEmision ? 'qr' : 'lock'} size={18} />
            <div>
              <strong>{proceso.admiteEmision ? 'Emisión abierta' : 'Emisión cerrada'}</strong>
              <span>{proceso.admiteEmision ? `Las credenciales vencen al cierre del sufragio: ${fecha(proceso.fechaFin)}` : proceso.motivoNoAdmite}</span>
            </div>
          </div>
        )}
      </section>

      {resumen && (
        <section className="cq-resumen">
          {TABS.map((t) => {
            const r = resumen[t];
            const pct = r.aptos ? Math.round((r.vigentes / r.aptos) * 100) : 0;
            return (
              <button key={t} type="button" className={`cq-kpi${tab === t ? ' on' : ''}`} style={{ '--cq-color': TIPOS_CREDENCIAL[t].color }} onClick={() => cambiarTab(t)}>
                <span>{TIPOS_CREDENCIAL[t].corto} <em>{TIPOS_CREDENCIAL[t].rf}</em></span>
                <strong>{r.vigentes}<small> / {r.aptos} aptos</small></strong>
                <i className="cq-barra"><b style={{ width: `${Math.min(pct, 100)}%` }} /></i>
                <small>{r.pendientes} sin credencial{r.titulares > r.aptos ? ` · ${r.titulares - r.aptos} no apto(s)` : ''}</small>
              </button>
            );
          })}
        </section>
      )}

      <div className="pd-tabs cq-tabs" role="tablist">
        {TABS.map((t) => (
          <button key={t} type="button" role="tab" aria-selected={tab === t} className={`pd-tab${tab === t ? ' on' : ''}`} onClick={() => cambiarTab(t)}>
            {TIPOS_CREDENCIAL[t].corto}
          </button>
        ))}
        <button type="button" role="tab" aria-selected={tab === 'VERIFICAR'} className={`pd-tab${tab === 'VERIFICAR' ? ' on' : ''}`} onClick={() => cambiarTab('VERIFICAR')}>Verificar QR</button>
        <button type="button" role="tab" aria-selected={tab === 'HISTORIAL'} className={`pd-tab${tab === 'HISTORIAL' ? ' on' : ''}`} onClick={() => cambiarTab('HISTORIAL')}>Historial</button>
      </div>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}

      {tab === 'VERIFICAR' && <VerificarCredencialPanel onSessionExpired={onSessionExpired} />}

      {tab === 'HISTORIAL' && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Historial de emisiones</h3>
              <p className="muted">Credenciales vigentes y revocadas del proceso (las 500 más recientes). Las revocadas no se borran: sirven de evidencia.</p>
            </div>
          </div>
          {historial.length === 0 ? <p className="empty-state">Aún no se emitieron credenciales en este proceso.</p> : (
            <div className="table-wrap">
              <table>
                <thead><tr><th>Credencial</th><th>Tipo</th><th>Titular</th><th>Mesa</th><th>Emitida</th><th>Estado</th><th>Lecturas</th></tr></thead>
                <tbody>
                  {historial.map((h) => (
                    <tr key={h.id} className={h.estado === 'REVOCADA' ? 'ps-revocado' : ''}>
                      <td>{numeroCredencial(h.id)}</td>
                      <td><span className="cq-tipo" style={{ '--cq-color': TIPOS_CREDENCIAL[h.tipo].color }}>{TIPOS_CREDENCIAL[h.tipo].corto}</span></td>
                      <td><strong>{h.nombre}</strong><small className="pd-sub">DNI {h.dni}</small></td>
                      <td>{h.numeroMesa ?? '—'}</td>
                      <td>{fecha(h.fechaEmision)}<small className="pd-sub">por {h.emisor ?? '—'}</small></td>
                      <td>
                        <span className={`cv-estado ${h.estado === 'VIGENTE' ? 'votacion' : 'anulado'}`}>{h.estado}</span>
                        {h.motivoRevocacion && <small className="pd-sub">{fecha(h.fechaRevocacion)} · {h.motivoRevocacion}</small>}
                      </td>
                      <td>{h.usos}{h.ultimoUso && <small className="pd-sub">{fecha(h.ultimoUso)}</small>}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {TABS.includes(tab) && detalle && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>{TIPOS_CREDENCIAL[tab].titulo} ({TIPOS_CREDENCIAL[tab].rf})</h3>
              <p className="muted">
                {tab === 'ELECTOR' && 'Docentes habilitados del padrón definitivo con mesa asignada.'}
                {tab === 'MIEMBRO_MESA' && 'Titulares y suplentes sorteados para cada mesa (CUS06).'}
                {tab === 'PERSONERO' && 'Personeros acreditados de listas inscritas o admitidas (CUS05).'}
              </p>
            </div>
            {admite && (
              <div className="cq-acciones">
                <button type="button" className="cv-btn cv-btn-ghost" disabled={saving || seleccion.size === 0} onClick={() => solicitarCredencial([...seleccion])}>
                  <MenuIcon name="qr" size={15} /> Emitir seleccionadas ({seleccion.size})
                </button>
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving || pendientes.length === 0} onClick={() => solicitarCredencial(pendientes.map((t) => t.idTitular))}>
                  <MenuIcon name="qr" size={15} /> Emitir pendientes ({pendientes.length})
                </button>
              </div>
            )}
          </div>

          {confirmando && (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>¿Emitir {confirmando.ids.length} credencial(es)?</strong>
                <span>
                  Los códigos QR se mostrarán una sola vez para imprimirlos o descargarlos.
                  {confirmando.reemplazos > 0 && ` ${confirmando.reemplazos} titular(es) ya tienen credencial vigente: la anterior quedará revocada.`}
                </span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(null)}>Cancelar</button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={confirmarEmision}>
                  <MenuIcon name="check" size={15} /> {saving ? 'Emitiendo…' : 'Emitir'}
                </button>
              </div>
            </div>
          )}

          <div className="cq-filtros">
            <input type="search" value={busqueda} placeholder="Buscar por nombre, DNI o mesa" aria-label="Buscar titular"
              onChange={(e) => { setBusqueda(e.target.value); setPagina(1); }} />
            <div className="cq-chips" role="group" aria-label="Filtrar">
              {FILTROS.map((f) => (
                <button key={f.codigo} type="button" className={`cq-chip${filtro === f.codigo ? ' on' : ''}`} onClick={() => { setFiltro(f.codigo); setPagina(1); }}>{f.texto}</button>
              ))}
            </div>
          </div>

          {detalle.titulares.length === 0 ? (
            <p className="empty-state">
              {tab === 'ELECTOR' && 'No hay padrón definitivo en este proceso: apruébelo en «Padrón electoral» (CUS02).'}
              {tab === 'MIEMBRO_MESA' && 'Aún no hay miembros de mesa: realice el sorteo en «Sorteos» (CUS06).'}
              {tab === 'PERSONERO' && 'No hay personeros acreditados: acredítelos en «Personeros» (CUS05).'}
            </p>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th className="cq-check">
                      {admite && <input type="checkbox" checked={todosMarcados} onChange={alternarTodos} aria-label="Seleccionar todos los aptos" disabled={seleccionables.length === 0} />}
                    </th>
                    <th>Titular</th><th>Función</th><th>Mesa</th><th>Credencial</th><th aria-label="Acciones" />
                  </tr>
                </thead>
                <tbody>
                  {visibles.map((t) => (
                    <tr key={t.idTitular} className={t.apto ? '' : 'cq-noapto'}>
                      <td className="cq-check">
                        {admite && t.apto && <input type="checkbox" checked={seleccion.has(t.idTitular)} onChange={() => alternar(t.idTitular)} aria-label={`Seleccionar a ${t.nombre}`} />}
                      </td>
                      <td><strong>{t.nombre}</strong><small className="pd-sub">DNI {t.dni} · {t.categoria}</small></td>
                      <td>{t.funcion}{t.cargo && <small className="pd-sub">{t.cargo}</small>}</td>
                      <td>{t.numeroMesa ?? '—'}{t.ubicacion && <small className="pd-sub">{t.ubicacion}</small>}</td>
                      <td>
                        {t.credencial ? (
                          <>
                            <span className="cv-estado votacion">Vigente</span>
                            <small className="pd-sub">{numeroCredencial(t.credencial.id)} · {fecha(t.credencial.fechaEmision)}{t.credencial.usos ? ` · ${t.credencial.usos} lectura(s)` : ''}</small>
                          </>
                        ) : t.apto ? (
                          <span className="cv-estado creado">Sin credencial</span>
                        ) : (
                          <>
                            <span className="cv-estado anulado">No apto</span>
                            <small className="pd-sub">{t.motivo}</small>
                          </>
                        )}
                      </td>
                      <td className="cq-row-actions">
                        {admite && t.apto && (
                          <button type="button" className="cv-btn cv-btn-soft cq-mini" disabled={saving} onClick={() => solicitarCredencial([t.idTitular])}>
                            <MenuIcon name={t.credencial ? 'refresh' : 'qr'} size={13} /> {t.credencial ? 'Reemitir' : 'Emitir'}
                          </button>
                        )}
                        {t.credencial && (
                          <button type="button" className="cv-icon-btn" title="Revocar credencial" aria-label={`Revocar credencial de ${t.nombre}`}
                            onClick={() => { setRevocando(t); setMotivo(''); setConfirmando(null); setFeedback(null); }}>
                            <MenuIcon name="close" size={16} />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {titulares.length === 0 && <p className="empty-state">Ningún titular coincide con el filtro.</p>}
            </div>
          )}

          {titulares.length > visibles.length && (
            <button type="button" className="cv-btn cv-btn-ghost cq-mas-btn" onClick={() => setPagina((p) => p + 1)}>
              Mostrar más ({titulares.length - visibles.length} restantes)
            </button>
          )}

          {revocando && (
            <div className="ps-revocar">
              <label className="cv-field">
                <span className="cv-label">Motivo para revocar la credencial de {revocando.nombre}</span>
                <input value={motivo} maxLength={255} placeholder="Ej.: el titular reportó la pérdida del fotocheck" onChange={(e) => setMotivo(e.target.value)} />
              </label>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setRevocando(null)}>Cancelar</button>
                <button type="button" className="cv-btn tc-btn-danger ps-danger" disabled={saving || motivo.trim().length < 10} onClick={revocar}>
                  Revocar credencial
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {emitido && (
        <ListaCredencialesQR resultado={emitido} proceso={emitido.proceso} onCerrar={() => setEmitido(null)} />
      )}
    </div>
  );
}
