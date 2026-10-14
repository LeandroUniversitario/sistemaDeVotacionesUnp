import { useState } from "react";
import { apiRequest } from "../api/apiClient";
import MenuIcon from "../components/MenuIcon";

const EMPTY_PROCESO = {
  nombre: "",
  fechaConvocatoria: "",
  fechaInicio: "",
  fechaFin: "",
  tipo: "PRIMERA_VUELTA",
  quorumMinimo: "60",
};

const EMPTY_CARGO = { nombre: "", nivel: "" };

const NIVELES = [
  { value: "RECTOR", label: "Rector" },
  { value: "VICERRECTOR_ACADEMICO", label: "Vicerrector Academico" },
  { value: "VICERRECTOR_INVESTIGACION", label: "Vicerrector de Investigacion" },
  { value: "DECANO", label: "Decano" },
  { value: "DIRECTOR", label: "Director" },
];

const PASOS = [
  { num: 1, label: "Datos del proceso" },
  { num: 2, label: "Cargos electorales" },
  { num: 3, label: "Publicar convocatoria" },
];

export default function CrearProcesoPage({ onSuccess, onCancel, onSessionExpired }) {
  const [paso, setPaso] = useState(1);
  const [procesoForm, setProcesoForm] = useState(EMPTY_PROCESO);
  const [proceso, setProceso] = useState(null);
  const [cargos, setCargos] = useState([]);
  const [cargoForm, setCargoForm] = useState(EMPTY_CARGO);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  function updateProceso(field, value) {
    setProcesoForm((prev) => ({ ...prev, [field]: value }));
  }

  function diasAnticipacion() {
    if (!procesoForm.fechaConvocatoria || !procesoForm.fechaInicio) return null;
    const fConv = new Date(procesoForm.fechaConvocatoria + "T00:00:00");
    const fInic = new Date(procesoForm.fechaInicio.split("T")[0] + "T00:00:00");
    return Math.round((fInic - fConv) / (1000 * 60 * 60 * 24));
  }

  async function handleCrearProceso(e) {
    e.preventDefault();
    setSaving(true);
    setFeedback(null);
    try {
      const result = await apiRequest("/api/procesos", {
        method: "POST",
        body: JSON.stringify({
          ...procesoForm,
          fechaConvocatoria: procesoForm.fechaConvocatoria || null,
          fechaInicio: procesoForm.fechaInicio + ":00",
          fechaFin: procesoForm.fechaFin + ":00",
          quorumMinimo: Number(procesoForm.quorumMinimo),
        }),
      });
      setProceso(result);
      const cargosExistentes = await apiRequest("/api/procesos/" + result.id + "/cargos");
      setCargos(Array.isArray(cargosExistentes) ? cargosExistentes : []);
      setPaso(2);
    } catch (err) {
      if (err.message === "SESSION_EXPIRED") onSessionExpired();
      else setFeedback({ type: "error", text: err.message });
    } finally {
      setSaving(false);
    }
  }

  async function handleAgregarCargo(e) {
    e.preventDefault();
    if (!cargoForm.nombre.trim() || !cargoForm.nivel) return;
    setSaving(true);
    setFeedback(null);
    try {
      const nuevo = await apiRequest("/api/procesos/" + proceso.id + "/cargos", {
        method: "POST",
        body: JSON.stringify(cargoForm),
      });
      setCargos((prev) => [...prev, nuevo]);
      setCargoForm(EMPTY_CARGO);
    } catch (err) {
      if (err.message === "SESSION_EXPIRED") onSessionExpired();
      else setFeedback({ type: "error", text: err.message });
    } finally {
      setSaving(false);
    }
  }

  async function handlePublicar() {
    if (cargos.length === 0) {
      setFeedback({ type: "error", text: "Debes agregar al menos un cargo electoral antes de publicar." });
      return;
    }
    setSaving(true);
    setFeedback(null);
    try {
      await apiRequest("/api/procesos/" + proceso.id + "/estado", {
        method: "PATCH",
        body: JSON.stringify({ estado: "INSCRIPCION" }),
      });
      setFeedback({ type: "success", text: "Convocatoria publicada. El proceso paso a estado INSCRIPCION." });
      setTimeout(() => onSuccess(), 1500);
    } catch (err) {
      if (err.message === "SESSION_EXPIRED") onSessionExpired();
      else setFeedback({ type: "error", text: err.message });
    } finally {
      setSaving(false);
    }
  }

  const dias = diasAnticipacion();
  const diasOk = dias !== null && dias >= 30 && dias <= 45;

  return (
    <div className="crear-proceso-shell">

      <div className="stepper">
        {PASOS.map((p, i) => (
          <div key={p.num} className="stepper-item">
            <div className={"stepper-circle" + (paso === p.num ? " current" : paso > p.num ? " done" : "")}>
              {paso > p.num ? <MenuIcon name="check" size={14} /> : <span>{p.num}</span>}
            </div>
            <span className="stepper-label">{p.label}</span>
            {i < PASOS.length - 1 && <div className={"stepper-line" + (paso > p.num ? " done" : "")} />}
          </div>
        ))}
      </div>

      {feedback && (
        <div className={"alert " + feedback.type} onClick={() => setFeedback(null)}>
          {feedback.text}
        </div>
      )}

      {paso === 1 && (
        <section className="panel form-panel">
          <div className="panel-heading">
            <div>
              <h2>Datos del proceso electoral</h2>
              <p className="muted">Registra nombre, tipo, fechas y quorum minimo (RN02: convocatoria con 30-45 dias de anticipacion).</p>
            </div>
          </div>
          <form className="process-form" onSubmit={handleCrearProceso}>
            <label>Nombre del proceso
              <input value={procesoForm.nombre} onChange={(e) => updateProceso("nombre", e.target.value)} placeholder="Ej: Elecciones Generales UNP 2025" required />
            </label>
            <div className="form-row">
              <label>Tipo de proceso
                <select value={procesoForm.tipo} onChange={(e) => updateProceso("tipo", e.target.value)}>
                  <option value="PRIMERA_VUELTA">Primera vuelta</option>
                  <option value="SEGUNDA_VUELTA">Segunda vuelta</option>
                </select>
              </label>
              <label>Quorum minimo (%)
                <input type="number" min="0" max="100" step="0.01" value={procesoForm.quorumMinimo} onChange={(e) => updateProceso("quorumMinimo", e.target.value)} required />
              </label>
            </div>
            <label>Fecha de convocatoria oficial
              <input type="date" value={procesoForm.fechaConvocatoria} onChange={(e) => updateProceso("fechaConvocatoria", e.target.value)} />
              {dias !== null && (
                <small style={{ color: diasOk ? "#10b981" : "#ef4444", marginTop: 4, display: "block" }}>
                  {diasOk ? ("✓ " + dias + " dias de anticipacion (dentro de los 30-45 requeridos)") : ("⚠ " + dias + " dias — debe publicarse entre 30 y 45 dias antes del sufragio (RN02)")}
                </small>
              )}
            </label>
            <div className="form-row">
              <label>Inicio del sufragio
                <input type="datetime-local" value={procesoForm.fechaInicio} onChange={(e) => updateProceso("fechaInicio", e.target.value)} required />
              </label>
              <label>Fin del sufragio
                <input type="datetime-local" value={procesoForm.fechaFin} onChange={(e) => updateProceso("fechaFin", e.target.value)} required />
              </label>
            </div>
            <div className="form-actions">
              <button type="button" className="btn-ghost" onClick={onCancel}>Cancelar</button>
              <button type="submit" className="btn-primary" disabled={saving}>
                {saving ? "Guardando..." : "Siguiente: Agregar cargos"}
              </button>
            </div>
          </form>
        </section>
      )}

      {paso === 2 && proceso && (
        <div className="cp-layout">
          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Agregar cargo electoral</h2>
                <p className="muted">Inscribe los cargos que se disputaran en <b>{proceso.nombre}</b>.</p>
              </div>
            </div>
            <form onSubmit={handleAgregarCargo}>
              <label>Nombre del cargo
                <input value={cargoForm.nombre} onChange={(e) => setCargoForm((prev) => ({ ...prev, nombre: e.target.value }))} placeholder="Ej: Rector" required />
              </label>
              <label>Nivel
                <select value={cargoForm.nivel} onChange={(e) => setCargoForm((prev) => ({ ...prev, nivel: e.target.value }))} required>
                  <option value="">Seleccionar nivel...</option>
                  {NIVELES.map((n) => (<option key={n.value} value={n.value}>{n.label}</option>))}
                </select>
              </label>
              <div className="form-actions">
                <button type="submit" className="btn-primary" disabled={saving || !cargoForm.nombre || !cargoForm.nivel}>
                  <MenuIcon name="plus" size={15} />
                  {saving ? "Agregando..." : "Agregar cargo"}
                </button>
              </div>
            </form>
          </section>

          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Cargos registrados</h2>
                <p className="muted">{cargos.length} cargo(s) registrado(s)</p>
              </div>
            </div>
            {cargos.length === 0
              ? <p className="empty-state">Aun no hay cargos. Agrega al menos uno para continuar.</p>
              : (
                <ul className="cargo-list">
                  {cargos.map((c) => (
                    <li key={c.id} className="cargo-item">
                      <span className="cargo-icon"><MenuIcon name="ballot" size={18} /></span>
                      <div className="cargo-info">
                        <strong>{c.nombre}</strong>
                        <span className="badge badge-blue">{c.nivel}</span>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            <div className="form-actions" style={{ paddingTop: 16 }}>
              <button className="btn-ghost" onClick={() => setPaso(1)}>Volver</button>
              <button className="btn-primary" onClick={() => setPaso(3)} disabled={cargos.length === 0}>
                Siguiente: Publicar
              </button>
            </div>
          </section>
        </div>
      )}

      {paso === 3 && proceso && (
        <section className="panel">
          <div className="panel-heading">
            <div>
              <h2>Confirmar y publicar convocatoria</h2>
              <p className="muted">Al confirmar el proceso pasara a estado INSCRIPCION y las listas podran inscribirse.</p>
            </div>
          </div>
          <div className="confirm-summary">
            <div className="confirm-row">
              <span className="confirm-icon blue"><MenuIcon name="calendar" size={20} /></span>
              <div>
                <strong>{proceso.nombre}</strong>
                <span className="muted" style={{ display: "block", fontSize: 13 }}>{proceso.tipo} · Quorum: {proceso.quorumMinimo}%</span>
              </div>
            </div>
            <div className="confirm-row">
              <span className="confirm-icon green"><MenuIcon name="ballot" size={20} /></span>
              <div>
                <strong>{cargos.length} cargo(s) electoral(es)</strong>
                <span className="muted" style={{ display: "block", fontSize: 13 }}>{cargos.map((c) => c.nombre).join(", ")}</span>
              </div>
            </div>
            <div className="confirm-row">
              <span className="confirm-icon amber"><MenuIcon name="alert" size={20} /></span>
              <div>
                <strong>Consecuencias de publicar:</strong>
                <ul style={{ margin: "4px 0 0", paddingLeft: 18, fontSize: 13, color: "var(--text-body)" }}>
                  <li>El proceso pasa a estado <b>INSCRIPCION</b>.</li>
                  <li>Las listas electorales podran inscribirse.</li>
                  <li>Este cambio no puede revertirse a CREADO.</li>
                </ul>
              </div>
            </div>
          </div>
          <div className="form-actions">
            <button className="btn-ghost" onClick={() => setPaso(2)}>Volver</button>
            <button className="btn-primary" onClick={handlePublicar} disabled={saving}>
              <MenuIcon name="check" size={16} />
              {saving ? "Publicando..." : "Publicar convocatoria"}
            </button>
          </div>
        </section>
      )}
    </div>
  );
}
