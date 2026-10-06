import { useEffect, useState } from 'react';
import { apiRequest } from '../api/apiClient';

/**
 * Página de gestión de tachas electorales.
 * Permite presentar una tacha y resolverlas (ADMIN/CEUNP).
 *
 * @param {{ processes, teachers, canManage, onSessionExpired }} props
 */
export default function TachasPage({ processes, teachers, canManage, onSessionExpired }) {
  const [tachas, setTachas] = useState([]);
  const [cargos, setCargos] = useState([]);
  const [listas, setListas] = useState([]);
  const [candidatos, setCandidatos] = useState([]);
  const [selectedProcess, setSelectedProcess] = useState('');
  const [selectedCargo, setSelectedCargo] = useState('');
  const [selectedLista, setSelectedLista] = useState('');
  const [denunciante, setDenunciante] = useState('');
  const [candidato, setCandidato] = useState('');
  const [motivo, setMotivo] = useState('');
  const [filter, setFilter] = useState('PENDIENTE');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);

  function handleRequestError(requestError) {
    if (requestError.message === 'SESSION_EXPIRED') onSessionExpired();
    else setError(requestError.message);
  }

  async function loadTachas(currentFilter = filter) {
    try {
      const suffix = currentFilter ? `?estado=${currentFilter}` : '';
      setTachas(await apiRequest(`/api/tachas${suffix}`));
    } catch (requestError) {
      handleRequestError(requestError);
    }
  }

  useEffect(() => {
    if (canManage) loadTachas();
  }, [canManage]);

  async function loadCargos(processId) {
    setSelectedProcess(processId);
    setSelectedCargo('');
    setSelectedLista('');
    setCargos([]);
    setListas([]);
    setCandidatos([]);
    if (!processId) return;
    try {
      setCargos(await apiRequest(`/api/procesos/${processId}/cargos`));
    } catch (requestError) {
      handleRequestError(requestError);
    }
  }

  async function loadListas(cargoId) {
    setSelectedCargo(cargoId);
    setSelectedLista('');
    setListas([]);
    setCandidatos([]);
    if (!cargoId) return;
    try {
      setListas(await apiRequest(`/api/cargos/${cargoId}/listas`));
    } catch (requestError) {
      handleRequestError(requestError);
    }
  }

  async function loadCandidatos(listaId) {
    setSelectedLista(listaId);
    setCandidatos([]);
    if (!listaId) return;
    try {
      setCandidatos(await apiRequest(`/api/listas/${listaId}/candidatos`));
    } catch (requestError) {
      handleRequestError(requestError);
    }
  }

  async function submitTacha(event) {
    event.preventDefault();
    setSaving(true);
    setError('');
    setMessage('');
    try {
      await apiRequest('/api/tachas', {
        method: 'POST',
        body: JSON.stringify({
          idDocenteDenunciante: Number(denunciante),
          idCandidato: Number(candidato),
          motivo,
        }),
      });
      setDenunciante('');
      setCandidato('');
      setMotivo('');
      setSelectedProcess('');
      setSelectedCargo('');
      setSelectedLista('');
      setCargos([]);
      setListas([]);
      setCandidatos([]);
      setMessage('Tacha presentada correctamente.');
      if (canManage) await loadTachas();
    } catch (requestError) {
      handleRequestError(requestError);
    } finally {
      setSaving(false);
    }
  }

  async function resolveTacha(idTacha, estado) {
    setSaving(true);
    setError('');
    try {
      await apiRequest(`/api/tachas/${idTacha}/resolver`, {
        method: 'POST',
        body: JSON.stringify({ estado }),
      });
      setMessage(`Tacha ${estado === 'FUNDADA' ? 'fundada' : 'declarada infundada'}.`);
      await loadTachas();
    } catch (requestError) {
      handleRequestError(requestError);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="candidaturas-layout">
      {error && <div className="alert error">{error}</div>}
      {message && <div className="alert success">{message}</div>}

      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Presentar tacha</h2>
            <p className="muted">Registra el candidato cuestionado y el motivo de la denuncia.</p>
          </div>
        </div>
        <form className="tacha-form" onSubmit={submitTacha}>
          <label>Docente denunciante
            <select value={denunciante} onChange={(event) => setDenunciante(event.target.value)} required>
              <option value="">Selecciona un docente</option>
              {teachers.map((teacher) => (
                <option key={teacher.id} value={teacher.id}>
                  #{teacher.id} · {teacher.apellidos}, {teacher.nombres}
                </option>
              ))}
            </select>
          </label>
          <label>Proceso electoral
            <select value={selectedProcess} onChange={(event) => loadCargos(event.target.value)} required>
              <option value="">Selecciona un proceso</option>
              {processes.map((process) => <option key={process.id} value={process.id}>{process.nombre}</option>)}
            </select>
          </label>
          <label>Cargo electoral
            <select value={selectedCargo} disabled={!selectedProcess}
              onChange={(event) => loadListas(event.target.value)} required>
              <option value="">Selecciona un cargo</option>
              {cargos.map((cargo) => <option key={cargo.id} value={cargo.id}>{cargo.nombre}</option>)}
            </select>
          </label>
          <label>Lista electoral
            <select value={selectedLista} disabled={!selectedCargo}
              onChange={(event) => loadCandidatos(event.target.value)} required>
              <option value="">Selecciona una lista</option>
              {listas.map((lista) => <option key={lista.id} value={lista.id}>{lista.nombre}</option>)}
            </select>
          </label>
          <label>Candidato
            <select value={candidato} disabled={!selectedLista}
              onChange={(event) => setCandidato(event.target.value)} required>
              <option value="">Selecciona un candidato</option>
              {candidatos.map((item) => (
                <option key={item.id} value={item.id}>
                  #{item.id} · Docente #{item.idDocente} · {item.rolEnLista}
                </option>
              ))}
            </select>
          </label>
          <label>Motivo
            <textarea value={motivo} onChange={(event) => setMotivo(event.target.value)} rows="3" required />
          </label>
          <button className="primary-small" type="submit" disabled={saving}>Presentar tacha</button>
        </form>
      </section>

      {canManage && (
        <section className="panel">
          <div className="panel-heading">
            <div>
              <h2>Tachas para resolver</h2>
              <p className="muted">Solo el CEUNP o un administrador puede emitir la resolución.</p>
            </div>
            <select className="filter-select" value={filter} onChange={(event) => {
              setFilter(event.target.value);
              loadTachas(event.target.value);
            }}>
              <option value="PENDIENTE">Pendientes</option>
              <option value="">Todas</option>
              <option value="FUNDADA">Fundadas</option>
              <option value="INFUNDADA">Infundadas</option>
            </select>
          </div>
          {!tachas.length ? <p className="empty-state">No hay tachas para mostrar.</p> : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>ID</th><th>Candidato</th><th>Denunciante</th>
                    <th>Motivo</th><th>Estado</th><th>Acción</th>
                  </tr>
                </thead>
                <tbody>
                  {tachas.map((tacha) => (
                    <tr key={tacha.id}>
                      <td>#{tacha.id}</td>
                      <td>#{tacha.idCandidato}</td>
                      <td>#{tacha.idDocenteDenunciante}</td>
                      <td>{tacha.motivo}</td>
                      <td><span className={`badge ${tacha.estado.toLowerCase()}`}>{tacha.estado}</span></td>
                      <td>
                        {tacha.estado === 'PENDIENTE' && (
                          <div className="action-buttons">
                            <button className="approve-button" disabled={saving}
                              onClick={() => resolveTacha(tacha.id, 'INFUNDADA')}>Infundada</button>
                            <button className="reject-button" disabled={saving}
                              onClick={() => resolveTacha(tacha.id, 'FUNDADA')}>Fundada</button>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      )}
    </div>
  );
}
