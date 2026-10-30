import { useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import './tachas.css';

/**
 * CUS04 · Gestionar tachas — «PantallaTachas» (boundary).
 *
 * Mensajes del diagrama de colaboración que origina esta pantalla:
 *   1 ingresarTacha(id_candidato, motivo) [DocenteElector] → 2 enviarTacha(datos)      → RegistrarTacha
 *   5 registrarResolucion(id_tacha, estado) [CEUNP]        → 6 guardarResolucion(datos) → ResolverTacha
 * y los que recibe: 4 confirmarRecepcion(), 9 notificarFallo().
 */

const ESTADO = {
  PENDIENTE: { label: 'Pendiente', cls: 'creado' },
  FUNDADA: { label: 'Fundada', cls: 'anulado' },
  INFUNDADA: { label: 'Infundada', cls: 'votacion' },
};

const fmt = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
const fecha = (v) => (v ? fmt.format(new Date(v)) : '—');
const MIN = 20;

const ROLES = {
  RECTOR: 'Rector', VICERRECTOR_ACADEMICO: 'Vicerrector Académico', VICERRECTOR_INVESTIGACION: 'Vicerrector de Investigación',
  DECANO: 'Decano', JEFE_DEPARTAMENTO: 'Jefe de Departamento', DIRECTOR_POSGRADO: 'Director de Posgrado',
  DIRECTOR_ESCUELA: 'Director de Escuela', TITULAR: 'Titular',
};
const rolLegible = (r) => ROLES[r] ?? (r ?? '').replaceAll('_', ' ').toLowerCase().replace(/^\w/, (c) => c.toUpperCase());

export default function TachasGestionPage({ session, onSessionExpired }) {
  const esCeunp = session.rol === 'CEUNP' || session.rol === 'ADMIN';

  const [procesos, setProcesos] = useState([]);
  const [idProceso, setIdProceso] = useState(null);
  const [candidatos, setCandidatos] = useState([]);
  const [tachas, setTachas] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  // CEUNP
  const [filtro, setFiltro] = useState('PENDIENTE');
  const [idTacha, setIdTacha] = useState(null);
  const [registrando, setRegistrando] = useState(false);
  const [fallo, setFallo] = useState({ estado: '', resolucion: '' });
  const [confirmando, setConfirmando] = useState(false);

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  useEffect(() => {
    (async () => {
      try {
        const lista = await apiRequest('/api/gestion-tachas/procesos');
        setProcesos(lista);
        if (lista[0]) await abrirProceso(lista[0].id);
        else if (!esCeunp) setTachas(await apiRequest('/api/gestion-tachas/mias'));
      } catch (error) {
        manejarError(error);
      } finally {
        setCargando(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function abrirProceso(id) {
    setIdProceso(id);
    setIdTacha(null);
    setRegistrando(false);
    try {
      const [cands, lista] = await Promise.all([
        apiRequest(`/api/gestion-tachas/procesos/${id}/candidatos`),
        esCeunp ? apiRequest(`/api/gestion-tachas/procesos/${id}/tachas`) : apiRequest('/api/gestion-tachas/mias'),
      ]);
      setCandidatos(cands || []);
      setTachas(esCeunp ? (lista || []) : (lista || []).filter((t) => (t.idProceso ?? t.id_proceso) === id));
    } catch (error) {
      manejarError(error);
    }
  }

  async function recargar() {
    const [cands, lista, procs] = await Promise.all([
      apiRequest(`/api/gestion-tachas/procesos/${idProceso}/candidatos`),
      esCeunp ? apiRequest(`/api/gestion-tachas/procesos/${idProceso}/tachas`) : apiRequest('/api/gestion-tachas/mias'),
      apiRequest('/api/gestion-tachas/procesos'),
    ]);
    setCandidatos(cands || []);
    setTachas(esCeunp ? (lista || []) : (lista || []).filter((t) => (t.idProceso ?? t.id_proceso) === idProceso));
    setProcesos(procs || []);
  }

  const proceso = procesos.find((p) => p.id === idProceso);
  const plazoVencido = proceso?.fechaLimiteInscripcion ? new Date(proceso.fechaLimiteInscripcion) < new Date() : false;
  const admite = proceso
    ? proceso.estado === 'INSCRIPCION' && !plazoVencido && Boolean(Number(proceso.admiteTachas ?? proceso.admite_tachas ?? 1))
    : false;

  // ─── 1 ingresarTacha(id_candidato, motivo) → 2 enviarTacha(datos) ────────
  async function ingresarTacha(datos) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest('/api/gestion-tachas', { method: 'POST', body: JSON.stringify(datos) });
      // 4 confirmarRecepcion()
      setFeedback({ type: 'success', text: data.mensaje });
      await recargar();
      if (esCeunp) { setRegistrando(false); setIdTacha(data.tacha.id); setFiltro('PENDIENTE'); }
      return true;
    } catch (error) {
      manejarError(error);
      return false;
    } finally {
      setSaving(false);
    }
  }

  // ─── 5 registrarResolucion(id_tacha, estado) → 6 guardarResolucion(datos) ─
  async function registrarResolucion() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/gestion-tachas/${idTacha}/resolucion`, {
        method: 'POST',
        body: JSON.stringify(fallo),
      });
      // 9 notificarFallo()
      setFeedback({ type: data.tacha.estado === 'FUNDADA' ? 'error' : 'success', text: data.mensaje });
      setFallo({ estado: '', resolucion: '' });
      await recargar();
    } catch (error) {
      manejarError(error);
    } finally {
      setConfirmando(false);
      setSaving(false);
    }
  }

  const tachasFiltradas = useMemo(() => tachas.filter((t) => (
    filtro === 'TODAS' || (filtro === 'PENDIENTE' ? t.estado === 'PENDIENTE' : t.estado !== 'PENDIENTE')
  )), [tachas, filtro]);
  const seleccionada = tachas.find((t) => t.id === idTacha);
  const conteo = (e) => tachas.filter((t) => t.estado === e).length;

  if (cargando) return <p className="empty-state">Cargando…</p>;

  return (
    <div className="pd-shell tc-shell">
      <section className="in-head tc-head">
        <label className="cv-field in-proceso">
          <span className="cv-label">Proceso electoral</span>
          <select value={idProceso ?? ''} onChange={(e) => abrirProceso(Number(e.target.value))} disabled={procesos.length === 0}>
            {procesos.length === 0 && <option>Sin procesos con candidatos</option>}
            {procesos.map((p) => <option key={p.id} value={p.id}>{p.nombre} · {p.estado}</option>)}
          </select>
        </label>
        {proceso && (
          <div className={`in-plazo ${admite ? 'open' : 'closed'}`}>
            <MenuIcon name={admite ? 'scale' : 'lock'} size={18} />
            <div>
              <strong>{admite ? 'Se reciben tachas' : 'No se reciben tachas'}</strong>
              <span>
                {admite
                  ? 'Etapa de INSCRIPCION: cualquier docente del padrón puede tachar a un candidato.'
                  : plazoVencido
                    ? `Venció el plazo de inscripción y presentación de tachas (${fecha(proceso.fechaLimiteInscripcion)}).`
                    : `El proceso no recibe tachas (estado: ${proceso.estado}).`}
              </span>
            </div>
          </div>
        )}
        {esCeunp && admite && (
          <button type="button" className="cv-btn cv-btn-ghost" onClick={() => { setRegistrando(true); setIdTacha(null); setFeedback(null); }}>
            <MenuIcon name="plus" size={15} /> Registrar tacha recibida
          </button>
        )}
      </section>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>
      )}

      {/* ══════════════ Vista del DOCENTE ELECTOR ══════════════ */}
      {!esCeunp && (
        <div className="tc-layout">
          <FormularioTacha
            candidatos={candidatos}
            admite={admite}
            saving={saving}
            onEnviar={ingresarTacha}
          />
          <section className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Mis tachas</h3>
                <p className="muted">Aquí verá el fallo del CEUNP cuando resuelva cada tacha.</p>
              </div>
            </div>
            {tachas.length === 0 && <p className="empty-state">No ha presentado tachas en este proceso.</p>}
            <ul className="tc-list">
              {tachas.map((t) => <TachaResumen key={t.id} tacha={t} />)}
            </ul>
          </section>
        </div>
      )}

      {/* ══════════════ Vista del CEUNP ══════════════ */}
      {esCeunp && (
        <>
          <section className="pd-stats tc-stats">
            <article className="pd-stat amber"><span className="pd-stat-label">Pendientes</span><strong>{conteo('PENDIENTE')}</strong></article>
            <article className="pd-stat red"><span className="pd-stat-label">Fundadas</span><strong>{conteo('FUNDADA')}</strong></article>
            <article className="pd-stat green"><span className="pd-stat-label">Infundadas</span><strong>{conteo('INFUNDADA')}</strong></article>
            <article className="pd-stat"><span className="pd-stat-label">Candidatos en carrera</span><strong>{candidatos.length}</strong></article>
          </section>

          <div className="tc-layout ceunp">
            <aside className="panel tc-bandeja">
              <div className="pd-tabs" role="tablist">
                {[['PENDIENTE', 'Pendientes'], ['RESUELTA', 'Resueltas'], ['TODAS', 'Todas']].map(([k, l]) => (
                  <button key={k} type="button" role="tab" aria-selected={filtro === k} className={`pd-tab${filtro === k ? ' on' : ''}`} onClick={() => setFiltro(k)}>{l}</button>
                ))}
              </div>
              {tachasFiltradas.length === 0 && <p className="empty-state">No hay tachas en esta bandeja.</p>}
              <ul className="tc-list">
                {tachasFiltradas.map((t) => (
                  <li key={t.id}>
                    <button type="button" className={`tc-item${idTacha === t.id ? ' active' : ''}`}
                      onClick={() => { setIdTacha(t.id); setRegistrando(false); setFallo({ estado: '', resolucion: '' }); setFeedback(null); }}>
                      <span className="tc-item-top">
                        <strong>N.º {t.id} · {t.candidato}</strong>
                        <span className={`cv-estado ${ESTADO[t.estado].cls}`}>{ESTADO[t.estado].label}</span>
                      </span>
                      <span className="tc-item-meta">{rolLegible(t.rolEnLista)} · lista «{t.lista}»</span>
                      <span className="tc-item-meta">Presentada {fecha(t.fechaPresentacion)}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </aside>

            <section className="tc-detalle">
              {registrando && (
                <FormularioTacha candidatos={candidatos} admite={admite} saving={saving} onEnviar={ingresarTacha} conDni
                  onCancelar={() => setRegistrando(false)} />
              )}

              {!registrando && !seleccionada && (
                <div className="panel cv-placeholder">
                  <span className="cv-placeholder-icon"><MenuIcon name="scale" size={28} /></span>
                  <h2>Resolución de tachas</h2>
                  <p className="muted">Seleccione una tacha de la bandeja para revisar su fundamento y registrar el fallo del CEUNP.</p>
                </div>
              )}

              {!registrando && seleccionada && (
                <div className="panel cv-form">
                  <div className="cv-section-head">
                    <div>
                      <span className="cv-eyebrow">Tacha N.º {seleccionada.id}</span>
                      <h3>{seleccionada.candidato}</h3>
                      <p className="muted">{rolLegible(seleccionada.rolEnLista)} · lista «{seleccionada.lista}» ({seleccionada.estadoLista}) · {seleccionada.cargo}</p>
                    </div>
                    <span className={`cv-estado ${ESTADO[seleccionada.estado].cls}`}>{ESTADO[seleccionada.estado].label}</span>
                  </div>

                  <dl className="cv-summary">
                    <div><dt>Denunciante</dt><dd>{seleccionada.denunciante}</dd></div>
                    <div><dt>DNI</dt><dd className="mono">{seleccionada.dniDenunciante}</dd></div>
                    <div><dt>Presentada</dt><dd>{fecha(seleccionada.fechaPresentacion)}</dd></div>
                    <div><dt>Estado del candidato</dt><dd>{seleccionada.estadoValidacion}</dd></div>
                    <div className="wide"><dt>Fundamento de la tacha</dt><dd className="tc-texto">{seleccionada.motivo}</dd></div>
                  </dl>

                  {seleccionada.estado === 'PENDIENTE' ? (
                    <div className="tc-fallo">
                      <span className="cv-label">Fallo del CEUNP</span>
                      <div className="tc-opciones" role="radiogroup">
                        <button type="button" role="radio" aria-checked={fallo.estado === 'INFUNDADA'}
                          className={`tc-opcion infundada${fallo.estado === 'INFUNDADA' ? ' on' : ''}`}
                          onClick={() => setFallo({ ...fallo, estado: 'INFUNDADA' })}>
                          <strong>Infundada</strong>
                          <span>El candidato continúa en la lista.</span>
                        </button>
                        <button type="button" role="radio" aria-checked={fallo.estado === 'FUNDADA'}
                          className={`tc-opcion fundada${fallo.estado === 'FUNDADA' ? ' on' : ''}`}
                          onClick={() => setFallo({ ...fallo, estado: 'FUNDADA' })}>
                          <strong>Fundada</strong>
                          <span>El candidato queda EXCLUIDO y la lista entera queda TACHADA (RN12).</span>
                        </button>
                      </div>
                      <label className="cv-field">
                        <span className="cv-label">Fundamento de la resolución</span>
                        <textarea rows={4} maxLength={4000} value={fallo.resolucion}
                          placeholder="Considerandos y base normativa de la decisión…"
                          onChange={(e) => setFallo({ ...fallo, resolucion: e.target.value })} />
                        <small className={fallo.resolucion.trim().length < MIN ? 'cv-hint' : 'cv-hint ok'}>
                          {fallo.resolucion.trim().length}/{MIN} caracteres mínimos
                        </small>
                      </label>
                      <div className="cv-actions">
                        <button type="button" className={`cv-btn ${fallo.estado === 'FUNDADA' ? 'tc-btn-danger' : 'cv-btn-primary'}`}
                          disabled={saving || !fallo.estado || fallo.resolucion.trim().length < MIN}
                          onClick={() => (fallo.estado === 'FUNDADA' ? setConfirmando(true) : registrarResolucion())}>
                          <MenuIcon name="scale" size={15} /> {saving ? 'Registrando…' : 'Registrar resolución'}
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className={`tc-resuelta ${seleccionada.estado.toLowerCase()}`}>
                      <strong>Declarada {seleccionada.estado} el {fecha(seleccionada.fechaResolucion)}{seleccionada.resueltoPor ? ` por ${seleccionada.resueltoPor}` : ''}</strong>
                      <p className="tc-texto">{seleccionada.resolucion}</p>
                    </div>
                  )}
                </div>
              )}
            </section>
          </div>
        </>
      )}

      {confirmando && seleccionada && (
        <div className="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="tc-confirm-title">
          <div className="modal-card small cv-confirm">
            <h2 id="tc-confirm-title">¿Declarar FUNDADA la tacha?</h2>
            <p>
              {seleccionada.candidato} quedará <b>EXCLUIDO</b> y la lista «{seleccionada.lista}» quedará <b>TACHADA</b>,
              fuera de la cédula de votación (RN12). Esta decisión no se puede revertir.
            </p>
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" disabled={saving} onClick={() => setConfirmando(false)}>Cancelar</button>
              <button type="button" className="cv-btn tc-btn-danger" disabled={saving} onClick={registrarResolucion}>
                {saving ? 'Registrando…' : 'Sí, declarar fundada'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/** 1 ingresarTacha(id_candidato, motivo): elegir candidato y fundamentar. */
function FormularioTacha({ candidatos, admite, saving, onEnviar, conDni = false, onCancelar }) {
  const [busqueda, setBusqueda] = useState('');
  const [idCandidato, setIdCandidato] = useState(null);
  const [motivo, setMotivo] = useState('');
  const [dni, setDni] = useState('');
  const [localError, setLocalError] = useState(null);

  const filtrados = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    return candidatos.filter((c) => !q || (c.candidato && c.candidato.toLowerCase().includes(q)) || (c.lista && c.lista.toLowerCase().includes(q)));
  }, [candidatos, busqueda]);

  const grupos = useMemo(() => {
    const m = new Map();
    filtrados.forEach((c) => {
      const k = `${c.cargo} · ${c.lista}`;
      if (!m.has(k)) m.set(k, []);
      m.get(k).push(c);
    });
    return [...m.entries()];
  }, [filtrados]);

  const elegido = candidatos.find((c) => c.id === idCandidato);

  async function enviar(event) {
    event.preventDefault();
    setLocalError(null);

    if (!idCandidato) {
      setLocalError('Por favor seleccione al candidato que desea tachar haciendo clic sobre su tarjeta.');
      return;
    }
    if (motivo.trim().length < MIN) {
      setLocalError(`El fundamento de la tacha debe tener al menos ${MIN} caracteres (actual: ${motivo.trim().length}).`);
      return;
    }
    if (conDni && (!dni || dni.trim().length === 0)) {
      setLocalError('Por favor ingrese el DNI del docente denunciante.');
      return;
    }

    const ok = await onEnviar({ idCandidato, motivo: motivo.trim(), dniDenunciante: conDni ? dni : null });
    if (ok) {
      setIdCandidato(null);
      setMotivo('');
      setDni('');
      setLocalError(null);
    }
  }

  return (
    <form className="panel cv-form" onSubmit={enviar}>
      <div className="cv-section-head">
        <div>
          <h3>{conDni ? 'Registrar tacha recibida' : 'Presentar tacha'}</h3>
          <p className="muted">
            {conDni
              ? 'Tacha presentada por escrito en mesa de partes: indique el DNI del docente denunciante.'
              : 'Cuestione por escrito a un candidato que no cumple los requisitos. La tacha se registra a su nombre.'}
          </p>
        </div>
      </div>

      {!admite && (
        <div style={{
          display: 'flex', gap: 10, alignItems: 'center',
          padding: '10px 14px', borderRadius: 8, background: '#fef2f2',
          border: '1px solid #fecdd3', color: '#991b1b', marginBottom: 14,
          fontSize: '0.85rem', fontWeight: 600
        }}>
          <MenuIcon name="lock" size={16} />
          <span>El plazo de presentación de tachas para este proceso ha concluido.</span>
        </div>
      )}

      {localError && (
        <div className="alert error" role="alert" style={{ marginBottom: 12 }}>
          {localError}
        </div>
      )}

      {conDni && (
        <label className="cv-field">
          <span className="cv-label">DNI del docente denunciante</span>
          <input inputMode="numeric" maxLength={8} value={dni} placeholder="8 dígitos" onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))} />
        </label>
      )}

      <div className="cv-field">
        <span className="cv-label">Candidato a tachar <span className="required-mark">*</span></span>
        {elegido ? (
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            padding: '10px 14px', borderRadius: 8, background: '#eff6ff',
            border: '1.5px solid #3b82f6', marginBottom: 8,
          }}>
            <div>
              <div style={{ fontWeight: 700, color: '#1e40af', fontSize: 14 }}>
                ✓ {elegido.candidato}
              </div>
              <div style={{ fontSize: 12, color: '#3b82f6' }}>
                {rolLegible(elegido.rolEnLista)} · {elegido.categoria} · Lista «{elegido.lista}»
              </div>
            </div>
            <button type="button" className="text-button" style={{ fontSize: 12 }} onClick={() => setIdCandidato(null)}>
              Cambiar
            </button>
          </div>
        ) : (
          <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: '4px 0 8px' }}>
            Seleccione al candidato haciendo clic en una de las tarjetas:
          </p>
        )}

        <input className="pd-search tc-search" placeholder="Buscar por nombre o lista…" value={busqueda} disabled={!admite} onChange={(e) => setBusqueda(e.target.value)} />
        <div className="tc-candidatos" role="radiogroup" aria-label="Candidatos">
          {grupos.length === 0 && <p className="in-empty">No hay candidatos que coincidan con la búsqueda.</p>}
          {grupos.map(([grupo, cs]) => (
            <div key={grupo} className="tc-grupo">
              <span className="tc-grupo-title">{grupo}</span>
              {cs.map((c) => (
                <button key={c.id} type="button" role="radio" aria-checked={idCandidato === c.id}
                  disabled={!admite}
                  className={`tc-cand${idCandidato === c.id ? ' on' : ''}`} onClick={() => { if (admite) { setIdCandidato(c.id); setLocalError(null); } }}>
                  <span className="in-avatar">{c.candidato.charAt(0)}</span>
                  <span className="in-cand-body">
                    <strong>{c.candidato}</strong>
                    <span>{rolLegible(c.rolEnLista)} · {c.categoria}</span>
                  </span>
                  {c.urlHojaVida && <a className="in-link" href={c.urlHojaVida} target="_blank" rel="noreferrer" onClick={(e) => e.stopPropagation()}>Hoja de vida</a>}
                </button>
              ))}
            </div>
          ))}
        </div>
      </div>

      <label className="cv-field">
        <span className="cv-label">Fundamento de la tacha{elegido ? ` contra ${elegido.candidato}` : ''} <span className="required-mark">*</span></span>
        <textarea rows={5} maxLength={4000} value={motivo} placeholder={admite ? "Describa el requisito que incumple el candidato y las pruebas que lo sustentan…" : "Plazo vencido. No se pueden registrar fundamentos."}
          disabled={!admite}
          onChange={(e) => { setMotivo(e.target.value); setLocalError(null); }} />
        <small className={motivo.trim().length < MIN ? 'cv-hint' : 'cv-hint ok'}>{motivo.trim().length}/{MIN} caracteres mínimos</small>
      </label>

      <div className="cv-actions">
        {onCancelar && <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>}
        <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !admite}>
          <MenuIcon name="file" size={15} /> {saving ? 'Enviando…' : 'Enviar tacha'}
        </button>
      </div>
    </form>
  );
}

/** Tarjeta de una tacha propia con su fallo (9 notificarFallo()). */
function TachaResumen({ tacha }) {
  return (
    <li className="tc-mia">
      <div className="tc-item-top">
        <strong>N.º {tacha.id} · {tacha.candidato}</strong>
        <span className={`cv-estado ${ESTADO[tacha.estado].cls}`}>{ESTADO[tacha.estado].label}</span>
      </div>
      <span className="tc-item-meta">{rolLegible(tacha.rolEnLista)} · lista «{tacha.lista}» · presentada {fecha(tacha.fechaPresentacion)}</span>
      <p className="tc-texto small">{tacha.motivo}</p>
      {tacha.estado !== 'PENDIENTE' && (
        <div className={`tc-resuelta ${tacha.estado.toLowerCase()}`}>
          <strong>Fallo del CEUNP ({fecha(tacha.fechaResolucion)})</strong>
          <p className="tc-texto small">{tacha.resolucion}</p>
        </div>
      )}
    </li>
  );
}
