import { useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import './sorteo.css';

/**
 * CUS06 · Realizar sorteos — «PantallaSorteoMesa» (boundary).
 *
 * Mensajes del diagrama de colaboración que origina esta pantalla:
 *   1 solicitarSorteo(id_proceso) → 2 obtenerUniverso()            → FiltrarElegibles
 *   6 ingresarSemilla(semilla)     → 7 generarAleatoriedad(semilla) → EjecutarSorteo
 * y los que recibe: 5 mostrarElegibles(), 12 confirmarAsignacion().
 */

const ROL = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal', SUPLENTE: 'Suplente' };
const fmt = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
const fecha = (v) => (v ? fmt.format(new Date(v)) : '—');
const num = (v) => Number(v ?? 0);

function semillaAleatoria() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export default function SorteoMesaPage({ onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [detalle, setDetalle] = useState(null);       // { proceso, parametros, mesas, miembros, cedula }
  const [universo, setUniverso] = useState(null);     // 5 mostrarElegibles()
  const [tab, setTab] = useState('MESAS');
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const [mesasForm, setMesasForm] = useState({ electoresPorMesa: '', ubicacion: '' });
  const [semilla, setSemilla] = useState('');
  const [preview, setPreview] = useState(null);
  const [resultado, setResultado] = useState(null);   // 12 confirmarAsignacion()
  const [confirmando, setConfirmando] = useState(false);
  const [verImpedidos, setVerImpedidos] = useState(false);
  const [semillasCedula, setSemillasCedula] = useState({});

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/sorteo-mesas/procesos');
        setProcesos(lista);
        if (lista[0]) await solicitarSorteo(lista[0].id);
      } catch (error) {
        manejarError(error);
      } finally {
        setCargando(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ─── 1 solicitarSorteo(id_proceso) → 2 obtenerUniverso() ─────────────────
  async function solicitarSorteo(id) {
    setIdProceso(id);
    setPreview(null);
    setResultado(null);
    setSemilla('');
    setFeedback(null);
    try {
      const [det, uni] = await Promise.all([
        apiRequest(`/api/sorteo-mesas/procesos/${id}`),
        apiRequest(`/api/sorteo-mesas/procesos/${id}/elegibles`),
      ]);
      setDetalle(det);
      setUniverso(uni);
      setMesasForm({ electoresPorMesa: String(det.parametros.electoresPorMesa), ubicacion: det.parametros.ubicacion ?? '' });
    } catch (error) {
      manejarError(error);
    }
  }

  async function recargar() {
    const [det, uni] = await Promise.all([
      apiRequest(`/api/sorteo-mesas/procesos/${idProceso}`),
      apiRequest(`/api/sorteo-mesas/procesos/${idProceso}/elegibles`),
    ]);
    setDetalle(det);
    setUniverso(uni);
  }

  async function conformarMesas(event) {
    event.preventDefault();
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/sorteo-mesas/procesos/${idProceso}/mesas`, {
        method: 'POST',
        body: JSON.stringify({ electoresPorMesa: Number(mesasForm.electoresPorMesa), ubicacion: mesasForm.ubicacion }),
      });
      setFeedback({ type: 'success', text: data.mensaje });
      await recargar();
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  // ─── 6 ingresarSemilla(semilla) → 7 generarAleatoriedad(semilla) ─────────
  async function vistaPrevia() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/sorteo-mesas/procesos/${idProceso}/vista-previa`, {
        method: 'POST', body: JSON.stringify({ semilla }),
      });
      setPreview(data);
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  async function realizarSorteo() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/sorteo-mesas/procesos/${idProceso}/sortear`, {
        method: 'POST', body: JSON.stringify({ semilla }),
      });
      setResultado(data);
      setPreview(null);
      setFeedback({ type: 'success', text: data.mensaje });
      await recargar();
    } catch (error) {
      manejarError(error);
    } finally {
      setConfirmando(false);
      setSaving(false);
    }
  }

  async function sortearCedula(cargo) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/sorteo-mesas/cargos/${cargo.id}/orden-cedula`, {
        method: 'POST', body: JSON.stringify({ semilla: semillasCedula[cargo.id] ?? '' }),
      });
      setDetalle((d) => ({ ...d, cedula: data.cargos }));
      setSemillasCedula((s) => ({ ...s, [cargo.id]: data.semilla }));
      setFeedback({ type: 'success', text: `${data.mensaje} Secreto revelado: ${data.secretoServidor.slice(0, 16)}… · semilla: ${data.semilla.slice(0, 16)}…` });
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  if (cargando) return <p className="empty-state">Cargando…</p>;

  const proceso = detalle?.proceso;
  const admite = Boolean(proceso?.admiteSorteo);
  const mesas = detalle?.mesas ?? [];
  const pendientes = mesas.filter((m) => num(m.miembros) === 0);
  const sorteadas = mesas.filter((m) => num(m.miembros) > 0);
  const miembrosDe = (idMesa) => (detalle?.miembros ?? []).filter((m) => m.idMesa === idMesa);
  const insuficientes = preview?.mesas.filter((m) => !m.suficientes) ?? [];

  return (
    <div className="pd-shell so-shell">
      <section className="in-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => solicitarSorteo(Number(e.target.value))}>
            {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
          </select>
        </label>
        {proceso && (
          <div className={`in-plazo ${admite ? 'open' : 'closed'}`}>
            <MenuIcon name={admite ? 'sorteo' : 'lock'} size={18} />
            <div>
              <strong>{admite ? 'Sorteos habilitados' : 'Sorteos cerrados'}</strong>
              <span>{admite ? `${num(proceso.electoresPadron)} electores en el padrón · los sorteos se hacen antes de la votación` : `El proceso está en ${proceso.estado}.`}</span>
            </div>
          </div>
        )}
      </section>

      <div className="pd-tabs so-tabs" role="tablist">
        <button type="button" role="tab" aria-selected={tab === 'MESAS'} className={`pd-tab${tab === 'MESAS' ? ' on' : ''}`} onClick={() => setTab('MESAS')}>
          Miembros de mesa <span>{sorteadas.length}/{mesas.length}</span>
        </button>
        <button type="button" role="tab" aria-selected={tab === 'CEDULA'} className={`pd-tab${tab === 'CEDULA' ? ' on' : ''}`} onClick={() => setTab('CEDULA')}>
          Orden en la cédula (RN18)
        </button>
      </div>

      {feedback && <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>}

      {tab === 'MESAS' && detalle && (
        <>
          {/* Paso previo: conformar mesas */}
          {mesas.length === 0 && (
            <form className="panel cv-form" onSubmit={conformarMesas}>
              <div className="cv-section-head">
                <div>
                  <h3>Conformar mesas de sufragio</h3>
                  <p className="muted">Reparte el padrón aprobado en mesas. Es el requisito previo del sorteo de sus miembros.</p>
                </div>
              </div>
              {num(proceso.electoresPadron) === 0 ? (
                <p className="tc-aviso so-aviso"><MenuIcon name="alert" size={14} /> RN04: el proceso no tiene padrón aprobado. Genérelo en «Padrón electoral» (CUS02).</p>
              ) : (
                <>
                  <div className="so-field-guide" role="note">
                    <strong>¿Qué valor debo ingresar?</strong>
                    <p>
                      Es la cantidad <b>máxima de electores que tendrá cada mesa</b>, no la cantidad total
                      del padrón. El sistema distribuirá automáticamente los {num(proceso.electoresPadron)} electores
                      y creará las mesas necesarias. Ingrese un número entero entre <b>6 y 1000</b>.
                    </p>
                    <p className="muted">
                      Ejemplo: con 85 electores, <b>200</b> forma 1 mesa; <b>50</b> forma 2 mesas
                      (50 y 35 electores). Use un valor menor si necesita dividir el padrón en varias mesas.
                    </p>
                  </div>
                  <div className="cv-grid two">
                    <label className="cv-field">
                      <span className="cv-label">Electores por mesa (máximo)</span>
                      <input type="number" min={6} max={1000} value={mesasForm.electoresPorMesa}
                        onChange={(e) => setMesasForm({ ...mesasForm, electoresPorMesa: e.target.value })}
                        aria-describedby="electores-por-mesa-ayuda" />
                      <small className="cv-hint">
                        {num(mesasForm.electoresPorMesa) >= 6
                          ? `Se formarán ${Math.ceil(num(proceso.electoresPadron) / num(mesasForm.electoresPorMesa))} mesa(s) para ${num(proceso.electoresPadron)} electores.`
                          : 'RN19: al menos 6 electores por mesa.'}
                      </small>
                      <small id="electores-por-mesa-ayuda" className="cv-hint">
                        No es necesario colocar exactamente el total de electores. Es el límite máximo por mesa.
                      </small>
                    </label>
                    <label className="cv-field">
                      <span className="cv-label">Ubicación (RN08)</span>
                      <input maxLength={200} value={mesasForm.ubicacion} onChange={(e) => setMesasForm({ ...mesasForm, ubicacion: e.target.value })} />
                    </label>
                  </div>
                  <div className="cv-actions">
                    <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !admite || num(mesasForm.electoresPorMesa) < 6}>
                      <MenuIcon name="table" size={15} /> {saving ? 'Conformando…' : 'Conformar mesas'}
                    </button>
                  </div>
                </>
              )}
            </form>
          )}

          {/* 5 mostrarElegibles() */}
          {mesas.length > 0 && universo && (
            <section className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Universo de elegibles</h3>
                  <p className="muted">Docentes del padrón habilitado, sin autoridades vigentes, candidatos ni personeros (RN20).</p>
                </div>
              </div>
              <div className="pd-mini-stats so-stats">
                <article className="pd-stat"><span className="pd-stat-label">Habilitados en el padrón</span><strong>{universo.habilitados}</strong></article>
                <article className="pd-stat red"><span className="pd-stat-label">Impedidos (RN20)</span><strong>{universo.impedidos.length}</strong></article>
                <article className="pd-stat"><span className="pd-stat-label">Ya son miembros</span><strong>{universo.yaMiembros}</strong></article>
                <article className="pd-stat green"><span className="pd-stat-label">Elegibles para el sorteo</span><strong>{universo.elegibles}</strong></article>
              </div>
              <div className="so-mesas-chips">
                {universo.mesas.map((m) => (
                  <span key={m.id} className={`so-chip${num(m.miembros) > 0 ? ' done' : num(m.elegibles) < 6 ? ' bad' : ''}`}>
                    <b>Mesa {m.numeroMesa}</b> {m.totalElectores} electores · {num(m.miembros) > 0 ? 'sorteada' : `${m.elegibles} elegibles`}
                  </span>
                ))}
              </div>
              {universo.impedidos.length > 0 && (
                <div>
                  <button type="button" className="text-button" onClick={() => setVerImpedidos((v) => !v)}>
                    {verImpedidos ? 'Ocultar' : 'Ver'} los {universo.impedidos.length} docentes impedidos
                  </button>
                  {verImpedidos && (
                    <div className="table-wrap so-impedidos">
                      <table>
                        <thead><tr><th>DNI</th><th>Docente</th><th>Mesa</th><th>Motivo</th></tr></thead>
                        <tbody>
                          {universo.impedidos.map((d) => (
                            <tr key={d.idDocente}><td className="mono">{d.dni}</td><td>{d.docente}</td><td>{d.numeroMesa ?? '—'}</td><td className="so-motivo">{d.motivo}</td></tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}
            </section>
          )}

          {/* 6 ingresarSemilla(semilla) */}
          {pendientes.length > 0 && admite && (
            <section className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Aporte a la semilla del sorteo</h3>
                  <p className="muted">
                    El sistema ya fijó un secreto y publica solo su huella (compromiso). La semilla final es SHA-256(secreto | su aporte):
                    nadie puede conocer el resultado antes de sortear, y al sortear se revela el secreto para que cualquiera lo verifique.
                    Su aporte puede ser un dato público acordado en el acto (por ejemplo, el número ganador de una lotería) o quedar vacío.
                  </p>
                </div>
              </div>
              <div className="so-semilla">
                <input className="mono" maxLength={128} value={semilla} placeholder="Opcional: dato público acordado en el acto"
                  onChange={(e) => { setSemilla(e.target.value); setPreview(null); }} aria-label="Semilla del sorteo" />
                <button type="button" className="cv-btn cv-btn-soft" onClick={() => { setSemilla(semillaAleatoria()); setPreview(null); }}>
                  <MenuIcon name="refresh" size={15} /> Generar aleatoria
                </button>
              </div>
              <details className="so-algoritmo">
                <summary>¿Cómo se sortea? (RNF01 · auditable)</summary>
                <ol>
                  <li>Semilla base = SHA-256(secreto del sistema | aporte). El secreto se compromete antes (se publica su SHA-256) y se revela al sortear.</li>
                  <li>Semilla de cada mesa = SHA-256(semilla base | número de mesa).</li>
                  <li>Los elegibles de la mesa se ordenan por SHA-256(semilla de la mesa | DNI).</li>
                  <li>Los 6 primeros: Presidente, Secretario y Vocal (titulares) y 3 suplentes (RN19).</li>
                </ol>
              </details>
              <div className="cv-actions">
                <span className="muted so-pend">{pendientes.length} mesa(s) pendiente(s) de sorteo</span>
                <button type="button" className="cv-btn cv-btn-ghost" disabled={saving} onClick={vistaPrevia}>
                  <MenuIcon name="eye" size={15} /> Vista previa
                </button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving || insuficientes.length > 0}
                  onClick={() => setConfirmando(true)}>
                  <MenuIcon name="sorteo" size={15} /> Realizar sorteo
                </button>
              </div>

              {preview && (
                <div className="so-preview">
                  <p className="so-preview-head">
                    <MenuIcon name="eye" size={14} /> Compromiso del sorteo: <code>{preview.compromiso.slice(0, 24)}…</code> — los miembros se conocen solo al sortear.
                  </p>
                  {insuficientes.length > 0 && (
                    <p className="tc-aviso so-aviso bad"><MenuIcon name="alert" size={14} />
                      RN19: {insuficientes.map((m) => `mesa ${m.numeroMesa} (${m.elegibles} elegibles)`).join(', ')} no tiene(n) 6 docentes elegibles.
                    </p>
                  )}
                  <div className="so-grid">
                    {preview.mesas.map((m) => (
                      <div key={m.idMesa} className="panel so-mesa-previa">
                        <strong>Mesa {m.numeroMesa}</strong> · {m.elegibles} docentes elegibles {m.suficientes ? '' : '(insuficientes)'}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </section>
          )}

          {/* 12 confirmarAsignacion() */}
          {sorteadas.length > 0 && (
            <section className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Miembros de mesa sorteados</h3>
                  <p className="muted">RN19: el cargo es irrenunciable; una mesa sorteada no se vuelve a sortear.</p>
                </div>
                {resultado && (
                  <span className={`cv-estado ${resultado.verificado ? 'votacion' : 'anulado'}`}>
                    {resultado.verificado ? 'Resultado verificado' : 'Revisar: no coincide con el cálculo'}
                  </span>
                )}
              </div>
              {resultado && (
                <p className="so-preview-head">
                  Compromiso publicado: <code className="so-seed">{resultado.compromiso}</code><br />
                  Secreto revelado: <code className="so-seed">{resultado.secretoServidor}</code><br />
                  Aporte del acto: <code className="so-seed">{resultado.aporteOperador || '(vacío)'}</code><br />
                  Semilla base = SHA-256(secreto | aporte): <code className="so-seed">{resultado.semillaBase}</code>
                </p>
              )}
              <div className="so-grid">
                {sorteadas.map((m) => (
                  <MesaCard key={m.id} numero={m.numeroMesa} miembros={miembrosDe(m.id)} semilla={m.semilla} fecha={m.fechaSorteo} ubicacion={m.ubicacion} />
                ))}
              </div>
            </section>
          )}
        </>
      )}

      {tab === 'CEDULA' && detalle && (
        <section className="so-cedula">
          {detalle.cedula.length === 0 && <p className="empty-state">El proceso no tiene cargos.</p>}
          {detalle.cedula.map((c) => (
            <div key={c.id} className="panel cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>{c.nombre}</h3>
                  <p className="muted">
                    {c.listas.length} lista(s) ADMITIDA(s){num(c.porCalificar) > 0 ? ` · ${c.porCalificar} aún sin calificar (no entran al sorteo)` : ''}
                  </p>
                </div>
                <span className={`cv-estado ${c.sorteado ? 'votacion' : 'creado'}`}>{c.sorteado ? 'Orden sorteado' : 'Pendiente'}</span>
              </div>
              {c.listas.length === 0 ? (
                <p className="in-empty">El CEUNP debe admitir las listas antes de sortear su orden.</p>
              ) : (
                <ol className="so-orden">
                  {c.listas.map((l) => (
                    <li key={l.id}>
                      <span className="so-num">{l.ordenCedula ?? '—'}</span>
                      <span className="in-simbolo" aria-hidden="true">{l.nombre.charAt(0)}</span>
                      <span><strong>{l.nombre}</strong>{l.simbolo ? <small className="pd-sub">{l.simbolo}</small> : null}</span>
                    </li>
                  ))}
                </ol>
              )}
              {c.compromiso && !c.sorteado && (
                <p className="muted">Compromiso del sorteo: <code>{c.compromiso.slice(0, 24)}…</code></p>
              )}
              {admite && c.listas.length > 0 && !c.sorteado && (
                <div className="so-semilla">
                  <input className="mono" maxLength={128} placeholder="Aporte opcional (dato público del acto)" value={semillasCedula[c.id] ?? ''}
                    onChange={(e) => setSemillasCedula((s) => ({ ...s, [c.id]: e.target.value }))} aria-label={`Semilla para ${c.nombre}`} />
                  <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => sortearCedula(c)}>
                    <MenuIcon name="sorteo" size={15} /> Sortear orden
                  </button>
                </div>
              )}
            </div>
          ))}
        </section>
      )}

      {confirmando && (
        <div className="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="so-confirm-title">
          <div className="modal-card small cv-confirm">
            <h2 id="so-confirm-title">¿Realizar el sorteo?</h2>
            <p>
              Se sortearán {pendientes.length} mesa(s){semilla ? <> con el aporte <code>{semilla.slice(0, 16)}</code></> : ''}. Los docentes sorteados quedan
              designados (RN19: cargo irrenunciable) y el sorteo no se puede repetir.
            </p>
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" disabled={saving} onClick={() => setConfirmando(false)}>Cancelar</button>
              <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={realizarSorteo}>
                {saving ? 'Sorteando…' : 'Sí, sortear'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function MesaCard({ numero, miembros, semilla, fecha: fechaSorteo, ubicacion, previa = false }) {
  return (
    <article className={`so-mesa${previa ? ' previa' : ''}`}>
      <header>
        <strong>Mesa {numero}</strong>
        <span>{ubicacion ?? (previa ? 'Vista previa' : '')}</span>
      </header>
      {miembros.length === 0 && <p className="in-empty">Sin miembros.</p>}
      <ol>
        {miembros.map((m) => (
          <li key={`${m.ordenSorteo}-${m.idDocente}`} className={m.titular ? 'titular' : ''}>
            <span className="so-rol">{ROL[m.rol] ?? m.rol}</span>
            <span className="so-docente">{m.docente}<small>DNI {m.dni}</small></span>
          </li>
        ))}
      </ol>
      {semilla && (
        <footer title={semilla}>
          Semilla {semilla.slice(0, 12)}…{fechaSorteo ? ` · ${fecha(fechaSorteo)}` : ''}
        </footer>
      )}
    </article>
  );
}
