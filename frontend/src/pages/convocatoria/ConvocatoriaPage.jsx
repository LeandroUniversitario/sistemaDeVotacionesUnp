import { useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import CronogramaTimeline from './CronogramaTimeline';
import {
  CATEGORIAS, EMPTY_FORM, ESTADO_LABEL, NIVELES, addDays, formToPayload, formatFecha,
  formatFechaHora, formatHora, nombreCargo, procesoToForm, toIsoDate, validarCronograma,
} from './convocatoriaUtils';
import './convocatoria.css';

/**
 * CUS01 · Gestionar convocatoria y cronograma — «PantallaConvocatoria» (boundary).
 *
 * Mensajes del diagrama de colaboración que origina esta pantalla:
 *   1  ingresarDatosProceso()  → 2  guardarProceso(datos)        → RegistrarProceso
 *   5  ingresarCargo(nombre, nivel) → 6  guardarCargo(datos_cargo) → AgregarCargo
 *   9  confirmarPublicacion()  → 10 cambiarEstado(id_proceso, estado) → PublicarConvocatoria
 * y los que recibe: 4 mostrarConfirmacion(), 8 actualizarListaCargos(), 12 notificarPublicacion().
 */

const PASOS = [
  { num: 1, label: 'Datos y cronograma', icon: 'calendar' },
  { num: 2, label: 'Cargos a elegir', icon: 'ballot' },
  { num: 3, label: 'Publicar convocatoria', icon: 'check' },
];

const EMPTY_CARGO = {
  idCatalogo: '',
  nombre: '',
  nivel: 'UNIVERSIDAD',
  idFacultad: '',
  idJurisdiccion: '',
  votan: [...CATEGORIAS],
  postulan: [...CATEGORIAS],
};

export default function ConvocatoriaPage({ onChange, onSessionExpired }) {
  const [convocatorias, setConvocatorias] = useState([]);
  const [loadingLista, setLoadingLista] = useState(true);
  const [catalogos, setCatalogos] = useState({ cargos: [], facultades: [], departamentos: [] });

  const [seleccion, setSeleccion] = useState(null);   // null | 'nuevo' | idProceso
  const [detalle, setDetalle] = useState(null);       // { proceso, cargos, editable, requisitos }
  const [paso, setPaso] = useState(1);
  const [form, setForm] = useState(EMPTY_FORM);
  const [tocado, setTocado] = useState(false);
  const [cargoForm, setCargoForm] = useState(EMPTY_CARGO);
  const [confirmando, setConfirmando] = useState(false);

  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  // ─── Carga inicial ──────────────────────────────────────────────────────
  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  async function cargarLista() {
    setLoadingLista(true);
    try {
      setConvocatorias(await apiRequest('/api/convocatorias'));
    } catch (error) {
      manejarError(error);
    } finally {
      setLoadingLista(false);
    }
  }

  useEffect(() => {
    cargarLista();
    apiRequest('/api/convocatorias/catalogos').then(setCatalogos).catch(manejarError);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ─── Selección ──────────────────────────────────────────────────────────
  function aplicarDetalle(data) {
    setDetalle({ proceso: data.proceso, cargos: data.cargos, editable: data.editable, requisitos: data.requisitos });
    setForm(procesoToForm(data.proceso));
  }

  function nuevaConvocatoria() {
    setSeleccion('nuevo');
    setDetalle(null);
    setForm({ ...EMPTY_FORM, fechaConvocatoria: toIsoDate(new Date()) });
    setTocado(false);
    setCargoForm(EMPTY_CARGO);
    setPaso(1);
    setFeedback(null);
  }

  async function abrirConvocatoria(id) {
    setFeedback(null);
    setSaving(true);
    try {
      const data = await apiRequest(`/api/convocatorias/${id}`);
      aplicarDetalle(data);
      setSeleccion(id);
      setTocado(false);
      setCargoForm(EMPTY_CARGO);
      setPaso(data.editable && data.cargos.length > 0 ? 2 : 1);
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  function irAPaso(numero) {
    setFeedback(null);
    setPaso(numero);
  }

  function cerrarEditor() {
    setSeleccion(null);
    setDetalle(null);
    setFeedback(null);
  }

  // ─── 1 ingresarDatosProceso() → 2 guardarProceso(datos) ──────────────────
  const validacion = useMemo(() => validarCronograma(form), [form]);

  async function ingresarDatosProceso(event) {
    event.preventDefault();
    setTocado(true);
    if (Object.keys(validacion.errores).length > 0) return;
    setSaving(true);
    setFeedback(null);
    try {
      const esNuevo = seleccion === 'nuevo';
      const data = await apiRequest(
        esNuevo ? '/api/convocatorias' : `/api/convocatorias/${seleccion}/cronograma`,
        { method: esNuevo ? 'POST' : 'PUT', body: JSON.stringify(formToPayload(form)) },
      );
      // 4 mostrarConfirmacion()
      aplicarDetalle(data);
      setSeleccion(data.proceso.id);
      setFeedback({ type: 'success', text: data.mensaje });
      setPaso(2);
      cargarLista();
      onChange?.();
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  function sugerirFechas() {
    const base = form.fechaConvocatoria || toIsoDate(new Date());
    setForm((f) => ({
      ...f,
      fechaConvocatoria: base,
      diaSufragio: addDays(base, 40),
      fechaLimiteInscripcion: `${addDays(base, 20)}T18:00`,
      horaInicio: '09:00',
      horaFin: '15:00',
    }));
  }

  // ─── 5 ingresarCargo(nombre, nivel) → 6 guardarCargo(datos_cargo) ────────
  function elegirCatalogo(value) {
    if (value === 'otro') {
      setCargoForm((c) => ({ ...c, idCatalogo: 'otro', nombre: '', nivel: 'UNIVERSIDAD', idFacultad: '', idJurisdiccion: '' }));
      return;
    }
    const item = catalogos.cargos.find((c) => String(c.id) === value);
    setCargoForm((c) => ({
      ...c,
      idCatalogo: value,
      nombre: item?.nombre ?? '',
      nivel: item?.nivel ?? 'UNIVERSIDAD',
      idFacultad: '',
      idJurisdiccion: '',
    }));
  }

  function toggleCategoria(campo, categoria) {
    setCargoForm((c) => ({
      ...c,
      [campo]: c[campo].includes(categoria) ? c[campo].filter((x) => x !== categoria) : [...c[campo], categoria],
    }));
  }

  const departamentosFiltrados = catalogos.departamentos.filter(
    (d) => !cargoForm.idFacultad || String(d.idFacultad) === String(cargoForm.idFacultad),
  );

  const cargoValido = cargoForm.nombre.trim()
    && (cargoForm.nivel === 'UNIVERSIDAD' || cargoForm.idJurisdiccion)
    && cargoForm.votan.length > 0 && cargoForm.postulan.length > 0;

  async function ingresarCargo(event) {
    event.preventDefault();
    if (!cargoValido) return;
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/convocatorias/${seleccion}/cargos`, {
        method: 'POST',
        body: JSON.stringify({
          nombre: cargoForm.nombre.trim(),
          nivel: cargoForm.nivel,
          idJurisdiccion: cargoForm.nivel === 'UNIVERSIDAD' ? null : Number(cargoForm.idJurisdiccion),
          categoriasVotan: cargoForm.votan,
          categoriasPostulan: cargoForm.postulan,
        }),
      });
      // 8 actualizarListaCargos()
      aplicarDetalle(data);
      setFeedback({ type: 'success', text: data.mensaje });
      setCargoForm((c) => ({ ...EMPTY_CARGO, votan: c.votan, postulan: c.postulan }));
      cargarLista();
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  async function quitarCargo(cargo) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/convocatorias/${seleccion}/cargos/${cargo.id}`, { method: 'DELETE' });
      aplicarDetalle(data);
      setFeedback({ type: 'success', text: data.mensaje });
      cargarLista();
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  // ─── 9 confirmarPublicacion() → 10 cambiarEstado(id_proceso, estado) ────
  async function confirmarPublicacion() {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/convocatorias/${seleccion}/publicar`, { method: 'POST' });
      // 12 notificarPublicacion()
      aplicarDetalle(data);
      setFeedback({ type: 'success', text: data.mensaje });
      setConfirmando(false);
      cargarLista();
      onChange?.();
    } catch (error) {
      setConfirmando(false);
      manejarError(error);
    } finally {
      setSaving(false);
    }
  }

  // ─── Render ─────────────────────────────────────────────────────────────
  const proceso = detalle?.proceso;
  const editable = seleccion === 'nuevo' || detalle?.editable;
  const cargos = detalle?.cargos ?? [];
  const requisitos = detalle?.requisitos ?? [];
  const publicable = requisitos.length > 0 && requisitos.every((r) => r.cumple);
  const errores = tocado ? validacion.errores : {};

  return (
    <div className="cv-shell">
      {/* ── Lista de convocatorias ─────────────────────────────────── */}
      <aside className="cv-list panel">
        <div className="cv-list-head">
          <div>
            <h2>Convocatorias</h2>
            <p className="muted">{convocatorias.length} registrada{convocatorias.length === 1 ? '' : 's'}</p>
          </div>
          <button type="button" className="cv-btn cv-btn-primary" onClick={nuevaConvocatoria}>
            <MenuIcon name="plus" size={16} /> Nueva
          </button>
        </div>

        {loadingLista && <p className="empty-state">Cargando…</p>}
        {!loadingLista && convocatorias.length === 0 && (
          <p className="empty-state">Aún no hay convocatorias. Cree la primera con «Nueva».</p>
        )}
        <ul className="cv-list-items">
          {seleccion === 'nuevo' && (
            <li>
              <button type="button" className="cv-list-item active">
                <span className="cv-list-name">Nueva convocatoria</span>
                <span className="cv-list-meta">Sin guardar</span>
              </button>
            </li>
          )}
          {convocatorias.map((c) => (
            <li key={c.id}>
              <button
                type="button"
                className={`cv-list-item${seleccion === c.id ? ' active' : ''}`}
                onClick={() => abrirConvocatoria(c.id)}
              >
                <span className="cv-list-name">{c.nombre}</span>
                <span className="cv-list-meta">
                  Sufragio {formatFecha(c.fechaInicio?.slice(0, 10))} · {c.totalCargos} cargo{Number(c.totalCargos) === 1 ? '' : 's'}
                </span>
                <span className={`cv-estado ${c.estado?.toLowerCase()}`}>{ESTADO_LABEL[c.estado] ?? c.estado}</span>
              </button>
            </li>
          ))}
        </ul>
      </aside>

      {/* ── Área de trabajo ────────────────────────────────────────── */}
      <section className="cv-work">
        {feedback && (
          <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>
            {feedback.text}
          </div>
        )}

        {seleccion === null && (
          <div className="panel cv-placeholder">
            <span className="cv-placeholder-icon"><MenuIcon name="calendar" size={28} /></span>
            <h2>Gestionar convocatoria y cronograma</h2>
            <p className="muted">
              Registre el proceso electoral con su cronograma, agregue los cargos a elegir y publique la
              convocatoria para abrir la inscripción de listas. Seleccione una convocatoria de la lista o cree una nueva.
            </p>
            <button type="button" className="cv-btn cv-btn-primary" onClick={nuevaConvocatoria}>
              <MenuIcon name="plus" size={16} /> Nueva convocatoria
            </button>
          </div>
        )}

        {seleccion !== null && (
          <>
            <header className="cv-work-head">
              <div>
                <span className="cv-eyebrow">{seleccion === 'nuevo' ? 'Nueva convocatoria' : `Convocatoria N.º ${proceso?.id}`}</span>
                <h2>{proceso?.nombre || form.nombre || 'Proceso electoral sin nombre'}</h2>
              </div>
              <div className="cv-work-head-actions">
                {proceso && <span className={`cv-estado ${proceso.estado.toLowerCase()}`}>{ESTADO_LABEL[proceso.estado] ?? proceso.estado}</span>}
                <button type="button" className="cv-btn cv-btn-ghost" onClick={cerrarEditor}>Cerrar</button>
              </div>
            </header>

            {!editable && proceso ? (
              <VistaPublicada proceso={proceso} cargos={cargos} />
            ) : (
              <>
                <nav className="cv-steps" aria-label="Pasos de la convocatoria">
                  {PASOS.map((p) => {
                    const bloqueado = p.num > 1 && seleccion === 'nuevo';
                    return (
                      <button
                        key={p.num}
                        type="button"
                        className={`cv-step${paso === p.num ? ' current' : ''}${paso > p.num ? ' done' : ''}`}
                        disabled={bloqueado}
                        onClick={() => irAPaso(p.num)}
                        title={bloqueado ? 'Guarde primero los datos del proceso' : p.label}
                      >
                        <span className="cv-step-num">{paso > p.num ? <MenuIcon name="check" size={14} /> : p.num}</span>
                        <span>{p.label}</span>
                      </button>
                    );
                  })}
                </nav>

                {paso === 1 && (
                  <form className="panel cv-form" onSubmit={ingresarDatosProceso} noValidate>
                    <div className="cv-section-head">
                      <div>
                        <h3>Datos del proceso y cronograma</h3>
                        <p className="muted">La convocatoria se publica entre 30 y 45 días antes del sufragio (RN02). El sufragio es de 09:00 a 15:00 (RN06).</p>
                      </div>
                      <button type="button" className="cv-btn cv-btn-soft" onClick={sugerirFechas}>
                        <MenuIcon name="refresh" size={15} /> Sugerir fechas
                      </button>
                    </div>

                    <div className="cv-grid">
                      <Campo label="Nombre del proceso" error={errores.nombre} className="span-3">
                        <input
                          value={form.nombre}
                          maxLength={200}
                          onChange={(e) => setForm({ ...form, nombre: e.target.value })}
                          placeholder="Ej.: Elecciones de Rector y Vicerrectores 2027"
                        />
                      </Campo>
                      <Campo label="Quórum mínimo (%)" error={errores.quorumMinimo} hint="RN31: participación mínima para validar la elección.">
                        <input
                          type="number" min="0" max="100" step="0.01"
                          value={form.quorumMinimo}
                          onChange={(e) => setForm({ ...form, quorumMinimo: e.target.value })}
                        />
                      </Campo>
                    </div>

                    <div className="cv-grid three">
                      <Campo label="Fecha de convocatoria" error={errores.fechaConvocatoria}>
                        <input type="date" value={form.fechaConvocatoria} onChange={(e) => setForm({ ...form, fechaConvocatoria: e.target.value })} />
                      </Campo>
                      <Campo label="Cierre de inscripción de listas" error={errores.fechaLimiteInscripcion}>
                        <input type="datetime-local" value={form.fechaLimiteInscripcion} onChange={(e) => setForm({ ...form, fechaLimiteInscripcion: e.target.value })} />
                      </Campo>
                      <span aria-hidden="true" />
                      <Campo label="Día del sufragio" error={errores.diaSufragio}>
                        <input type="date" value={form.diaSufragio} onChange={(e) => setForm({ ...form, diaSufragio: e.target.value })} />
                      </Campo>
                      <Campo label="Apertura de mesas">
                        <input type="time" value={form.horaInicio} onChange={(e) => setForm({ ...form, horaInicio: e.target.value })} />
                      </Campo>
                      <Campo label="Cierre del sufragio" error={errores.horaFin}>
                        <input type="time" value={form.horaFin} onChange={(e) => setForm({ ...form, horaFin: e.target.value })} />
                      </Campo>
                    </div>

                    <CronogramaTimeline cronograma={form} />

                    <div className="cv-actions">
                      {Object.keys(errores).length > 0 && (
                        <span className="cv-error cv-actions-note">Corrija los campos marcados para continuar.</span>
                      )}
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={cerrarEditor}>Cancelar</button>
                      <button type="submit" className="cv-btn cv-btn-primary" disabled={saving}>
                        {saving ? 'Guardando…' : seleccion === 'nuevo' ? 'Registrar proceso y continuar' : 'Guardar cronograma'}
                      </button>
                    </div>
                  </form>
                )}

                {paso === 2 && (
                  <div className="cv-cargos">
                    <form className="panel cv-form" onSubmit={ingresarCargo}>
                      <div className="cv-section-head">
                        <div>
                          <h3>Agregar cargo</h3>
                          <p className="muted">Defina qué categorías docentes votan y cuáles pueden postular (RF03).</p>
                        </div>
                      </div>

                      <Campo label="Cargo">
                        <select value={cargoForm.idCatalogo} onChange={(e) => elegirCatalogo(e.target.value)}>
                          <option value="">Seleccione un cargo…</option>
                          {NIVELES.map((n) => (
                            <optgroup key={n.value} label={n.label}>
                              {catalogos.cargos.filter((c) => c.nivel === n.value).map((c) => (
                                <option key={c.id} value={c.id}>{c.nombre}</option>
                              ))}
                            </optgroup>
                          ))}
                          <option value="otro">Otro cargo…</option>
                        </select>
                      </Campo>

                      {cargoForm.idCatalogo === 'otro' && (
                        <div className="cv-grid two">
                          <Campo label="Nombre del cargo">
                            <input value={cargoForm.nombre} maxLength={150} onChange={(e) => setCargoForm({ ...cargoForm, nombre: e.target.value })} placeholder="Ej.: Representante docente" />
                          </Campo>
                          <Campo label="Nivel">
                            <select value={cargoForm.nivel} onChange={(e) => setCargoForm({ ...cargoForm, nivel: e.target.value, idFacultad: '', idJurisdiccion: '' })}>
                              {NIVELES.map((n) => <option key={n.value} value={n.value}>{n.label}</option>)}
                            </select>
                          </Campo>
                        </div>
                      )}

                      {cargoForm.nombre && cargoForm.nivel === 'FACULTAD' && (
                        <Campo label="Facultad">
                          <select value={cargoForm.idJurisdiccion} onChange={(e) => setCargoForm({ ...cargoForm, idJurisdiccion: e.target.value })}>
                            <option value="">Seleccione la facultad…</option>
                            {catalogos.facultades.map((f) => <option key={f.id} value={f.id}>{f.nombre}</option>)}
                          </select>
                        </Campo>
                      )}

                      {cargoForm.nombre && cargoForm.nivel === 'DEPARTAMENTO' && (
                        <div className="cv-grid two">
                          <Campo label="Facultad">
                            <select value={cargoForm.idFacultad} onChange={(e) => setCargoForm({ ...cargoForm, idFacultad: e.target.value, idJurisdiccion: '' })}>
                              <option value="">Todas</option>
                              {catalogos.facultades.map((f) => <option key={f.id} value={f.id}>{f.nombre}</option>)}
                            </select>
                          </Campo>
                          <Campo label="Departamento académico">
                            <select value={cargoForm.idJurisdiccion} onChange={(e) => setCargoForm({ ...cargoForm, idJurisdiccion: e.target.value })}>
                              <option value="">Seleccione…</option>
                              {departamentosFiltrados.map((d) => <option key={d.id} value={d.id}>{d.nombre}</option>)}
                            </select>
                          </Campo>
                        </div>
                      )}

                      <div className="cv-cats">
                        <CategoriaPicker titulo="Votan" valores={cargoForm.votan} onToggle={(c) => toggleCategoria('votan', c)} />
                        <CategoriaPicker titulo="Pueden postular" valores={cargoForm.postulan} onToggle={(c) => toggleCategoria('postulan', c)} />
                      </div>

                      <div className="cv-actions">
                        <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !cargoValido}>
                          <MenuIcon name="plus" size={15} /> {saving ? 'Agregando…' : 'Agregar cargo'}
                        </button>
                      </div>
                    </form>

                    <div className="panel cv-form">
                      <div className="cv-section-head">
                        <div>
                          <h3>Cargos de la convocatoria</h3>
                          <p className="muted">{cargos.length} cargo{cargos.length === 1 ? '' : 's'} registrado{cargos.length === 1 ? '' : 's'}</p>
                        </div>
                      </div>
                      {cargos.length === 0 ? (
                        <p className="empty-state">Aún no hay cargos. Agregue al menos uno para poder publicar.</p>
                      ) : (
                        <ul className="cv-cargo-list">
                          {cargos.map((c) => (
                            <li key={c.id} className="cv-cargo">
                              <span className={`cv-nivel ${c.nivelJurisdiccion.toLowerCase()}`}>{c.nivelJurisdiccion.slice(0, 3)}</span>
                              <div className="cv-cargo-body">
                                <strong>{nombreCargo(c)}</strong>
                                <span>Votan: {fmtCats(c.categoriasVotan)} · Postulan: {fmtCats(c.categoriasPostulan)}</span>
                              </div>
                              <button
                                type="button"
                                className="cv-icon-btn"
                                title="Quitar cargo"
                                aria-label={`Quitar ${c.nombre}`}
                                disabled={saving || Number(c.totalListas) > 0}
                                onClick={() => quitarCargo(c)}
                              >
                                <MenuIcon name="trash" size={16} />
                              </button>
                            </li>
                          ))}
                        </ul>
                      )}
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => irAPaso(1)}>Volver al cronograma</button>
                        <button type="button" className="cv-btn cv-btn-primary" disabled={cargos.length === 0} onClick={() => irAPaso(3)}>
                          Continuar a publicar
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {paso === 3 && proceso && (
                  <div className="panel cv-form">
                    <div className="cv-section-head">
                      <div>
                        <h3>Revisar y publicar</h3>
                        <p className="muted">Al publicar, el proceso pasa de CREADO a INSCRIPCION: se abre la inscripción de listas y el cronograma queda fijo.</p>
                      </div>
                    </div>

                    <div className="cv-review">
                      <ul className="cv-checklist">
                        {requisitos.map((r) => (
                          <li key={r.codigo} className={r.cumple ? 'ok' : 'bad'}>
                            <span className="cv-check-icon"><MenuIcon name={r.cumple ? 'check' : 'close'} size={14} /></span>
                            {r.descripcion}
                          </li>
                        ))}
                      </ul>
                      <dl className="cv-summary">
                        <div><dt>Convocatoria</dt><dd>{formatFecha(proceso.fechaConvocatoria)}</dd></div>
                        <div><dt>Cierre de inscripción</dt><dd>{formatFechaHora(proceso.fechaLimiteInscripcion)}</dd></div>
                        <div><dt>Sufragio</dt><dd>{formatFecha(proceso.fechaInicio?.slice(0, 10))}, {formatHora(proceso.fechaInicio)}–{formatHora(proceso.fechaFin)}</dd></div>
                        <div><dt>Quórum mínimo</dt><dd>{Number(proceso.quorumMinimo)}%</dd></div>
                        <div className="wide"><dt>Cargos</dt><dd>{cargos.map(nombreCargo).join(' · ') || '—'}</dd></div>
                      </dl>
                    </div>

                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => irAPaso(2)}>Volver a cargos</button>
                      <button type="button" className="cv-btn cv-btn-success" disabled={!publicable || saving} onClick={() => setConfirmando(true)}>
                        <MenuIcon name="check" size={15} /> Publicar convocatoria
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}
          </>
        )}
      </section>

      {confirmando && proceso && (
        <div className="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="cv-confirm-title">
          <div className="modal-card small cv-confirm">
            <h2 id="cv-confirm-title">¿Publicar la convocatoria?</h2>
            <p>
              «{proceso.nombre}» pasará a <b>INSCRIPCION</b>. Las listas podrán inscribirse hasta el{' '}
              {formatFechaHora(proceso.fechaLimiteInscripcion)}. Después no podrá modificar el cronograma ni los cargos.
            </p>
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)} disabled={saving}>Cancelar</button>
              <button type="button" className="cv-btn cv-btn-success" onClick={confirmarPublicacion} disabled={saving}>
                {saving ? 'Publicando…' : 'Sí, publicar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/** Convocatoria ya publicada: cronograma y cargos en solo lectura. */
function VistaPublicada({ proceso, cargos }) {
  return (
    <div className="panel cv-form">
      <div className="cv-published-banner">
        <MenuIcon name="check" size={18} />
        <div>
          <strong>Convocatoria publicada</strong>
          <span>El cronograma y los cargos ya no se pueden modificar. Estado actual: {proceso.estado}.</span>
        </div>
      </div>
      <CronogramaTimeline cronograma={procesoToForm(proceso)} />
      <h3 className="cv-sub">Cargos convocados</h3>
      <ul className="cv-cargo-list">
        {cargos.map((c) => (
          <li key={c.id} className="cv-cargo">
            <span className={`cv-nivel ${c.nivelJurisdiccion.toLowerCase()}`}>{c.nivelJurisdiccion.slice(0, 3)}</span>
            <div className="cv-cargo-body">
              <strong>{nombreCargo(c)}</strong>
              <span>Votan: {fmtCats(c.categoriasVotan)} · Postulan: {fmtCats(c.categoriasPostulan)} · Listas: {c.totalListas}</span>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

function Campo({ label, error, hint, className = '', children }) {
  return (
    <label className={`cv-field ${className}${error ? ' has-error' : ''}`}>
      <span className="cv-label">{label}</span>
      {children}
      {error ? <small className="cv-error">{error}</small> : hint ? <small className="cv-hint">{hint}</small> : null}
    </label>
  );
}

function CategoriaPicker({ titulo, valores, onToggle }) {
  return (
    <fieldset className="cv-catpick">
      <legend>{titulo}</legend>
      <div>
        {CATEGORIAS.map((c) => (
          <button
            key={c}
            type="button"
            className={`cv-chip${valores.includes(c) ? ' on' : ''}`}
            aria-pressed={valores.includes(c)}
            onClick={() => onToggle(c)}
          >
            {c.charAt(0) + c.slice(1).toLowerCase()}
          </button>
        ))}
      </div>
      {valores.length === 0 && <small className="cv-error">Elija al menos una categoría.</small>}
    </fieldset>
  );
}

function fmtCats(csv) {
  if (!csv) return '—';
  const lista = csv.split(',');
  if (lista.length === CATEGORIAS.length) return 'todas';
  return lista.map((c) => c.charAt(0) + c.slice(1).toLowerCase()).join(', ');
}
