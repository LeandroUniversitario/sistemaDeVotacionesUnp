import { useState } from 'react';
import { apiRequest } from '../api/apiClient';
import CandidateTable from '../components/CandidateTable';

/**
 * Página de gestión de candidaturas electorales.
 * Permite seleccionar proceso → cargo → lista y registrar candidatos.
 *
 * @param {{ processes, teachers, selectedProcess, onProcessChange, canManage, onSessionExpired }} props
 */
export default function CandidaturasPage({
  processes, teachers, selectedProcess, onProcessChange, canManage, onSessionExpired,
}) {
  const [cargos, setCargos] = useState([]);
  const [selectedCargo, setSelectedCargo] = useState(null);
  const [listas, setListas] = useState([]);
  const [selectedLista, setSelectedLista] = useState(null);
  const [candidatos, setCandidatos] = useState([]);
  const [name, setName] = useState('');
  const [simbolo, setSimbolo] = useState('');
  const [teacherId, setTeacherId] = useState('');
  const [role, setRole] = useState('');
  const [category, setCategory] = useState('PRINCIPAL');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);

  function handleError(requestError) {
    if (requestError.message === 'SESSION_EXPIRED') onSessionExpired();
    else setError(requestError.message);
  }

  async function loadCargos(process) {
    onProcessChange(process);
    setSelectedCargo(null);
    setListas([]);
    setSelectedLista(null);
    if (!process) return;
    try {
      setCargos(await apiRequest(`/api/procesos/${process.id}/cargos`));
    } catch (requestError) {
      handleError(requestError);
    }
  }

  async function loadListas(cargo) {
    setSelectedCargo(cargo);
    setSelectedLista(null);
    if (!cargo) return;
    try {
      setListas(await apiRequest(`/api/cargos/${cargo.id}/listas`));
    } catch (requestError) {
      handleError(requestError);
    }
  }

  async function loadCandidatos(lista) {
    setSelectedLista(lista);
    if (!lista) return;
    try {
      setCandidatos(await apiRequest(`/api/listas/${lista.id}/candidatos`));
    } catch (requestError) {
      handleError(requestError);
    }
  }

  async function createList(event) {
    event.preventDefault();
    if (!selectedCargo) return;
    setSaving(true);
    setError('');
    setMessage('');
    try {
      await apiRequest(`/api/cargos/${selectedCargo.id}/listas`, {
        method: 'POST',
        body: JSON.stringify({ nombre: name, simbolo: simbolo || null }),
      });
      setName('');
      setSimbolo('');
      setMessage('Lista electoral registrada.');
      await loadListas(selectedCargo);
    } catch (requestError) {
      handleError(requestError);
    } finally {
      setSaving(false);
    }
  }

  async function allowCategory(event) {
    event.preventDefault();
    if (!selectedCargo) return;
    setSaving(true);
    setError('');
    try {
      await apiRequest(`/api/cargos/${selectedCargo.id}/categorias-permitidas`, {
        method: 'POST',
        body: JSON.stringify({ categoria: category }),
      });
      setMessage(`Categoría ${category} permitida para el cargo.`);
    } catch (requestError) {
      handleError(requestError);
    } finally {
      setSaving(false);
    }
  }

  async function createCandidate(event) {
    event.preventDefault();
    if (!selectedLista) return;
    setSaving(true);
    setError('');
    try {
      await apiRequest(`/api/listas/${selectedLista.id}/candidatos`, {
        method: 'POST',
        body: JSON.stringify({ idDocente: Number(teacherId), rolEnLista: role }),
      });
      setTeacherId('');
      setRole('');
      setMessage('Candidato registrado como pendiente de validación.');
      await loadCandidatos(selectedLista);
    } catch (requestError) {
      handleError(requestError);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="candidaturas-layout">
      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Configuración de candidaturas</h2>
            <p className="muted">Selecciona el proceso, cargo y lista que deseas administrar.</p>
          </div>
        </div>
        {error && <div className="alert error">{error}</div>}
        {message && <div className="alert success">{message}</div>}

        <label>Proceso electoral
          <select value={selectedProcess?.id || ''} onChange={(event) =>
            loadCargos(processes.find((item) => item.id === Number(event.target.value)) || null)}>
            <option value="">Selecciona un proceso</option>
            {processes.map((process) => <option key={process.id} value={process.id}>{process.nombre}</option>)}
          </select>
        </label>
        <label>Cargo electoral
          <select value={selectedCargo?.id || ''} disabled={!selectedProcess} onChange={(event) =>
            loadListas(cargos.find((item) => item.id === Number(event.target.value)) || null)}>
            <option value="">Selecciona un cargo</option>
            {cargos.map((cargo) => <option key={cargo.id} value={cargo.id}>{cargo.nombre}</option>)}
          </select>
        </label>
        <label>Lista electoral
          <select value={selectedLista?.id || ''} disabled={!selectedCargo} onChange={(event) =>
            loadCandidatos(listas.find((item) => item.id === Number(event.target.value)) || null)}>
            <option value="">Selecciona una lista</option>
            {listas.map((lista) => <option key={lista.id} value={lista.id}>{lista.nombre}</option>)}
          </select>
        </label>
      </section>

      {canManage && selectedCargo && (
        <section className="panel">
          <div className="panel-heading">
            <div>
              <h2>Administrar cargo</h2>
              <p className="muted">{selectedCargo.nombre} · {selectedCargo.nivelJurisdiccion}</p>
            </div>
          </div>
          <div className="form-row">
            <form onSubmit={allowCategory}>
              <label>Categoría permitida
                <select value={category} onChange={(event) => setCategory(event.target.value)}>
                  <option>PRINCIPAL</option>
                  <option>ASOCIADO</option>
                  <option>AUXILIAR</option>
                </select>
              </label>
              <button className="primary-small" type="submit" disabled={saving}>Permitir categoría</button>
            </form>
            <form onSubmit={createList}>
              <label>Nombre de la nueva lista
                <input value={name} onChange={(event) => setName(event.target.value)} required />
              </label>
              <label>Símbolo
                <input value={simbolo} onChange={(event) => setSimbolo(event.target.value)} />
              </label>
              <button className="primary-small" type="submit" disabled={saving}>Crear lista</button>
            </form>
          </div>
        </section>
      )}

      {canManage && selectedLista && (
        <section className="panel">
          <div className="panel-heading">
            <div>
              <h2>Registrar candidato</h2>
              <p className="muted">El docente debe estar activo y cumplir la categoría del cargo.</p>
            </div>
          </div>
          <form className="candidate-form" onSubmit={createCandidate}>
            <label>Docente
              <select value={teacherId} onChange={(event) => setTeacherId(event.target.value)} required>
                <option value="">Selecciona un docente</option>
                {teachers.map((teacher) => (
                  <option key={teacher.id} value={teacher.id}>
                    {teacher.apellidos}, {teacher.nombres} · {teacher.categoria}
                  </option>
                ))}
              </select>
            </label>
            <label>Rol en la lista
              <input value={role} onChange={(event) => setRole(event.target.value)}
                placeholder="Representante titular" required />
            </label>
            <button className="primary-small" type="submit" disabled={saving}>Registrar candidato</button>
          </form>
          <CandidateTable candidates={candidatos} />
        </section>
      )}
    </div>
  );
}
