import { useState } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';

export default function SorteosPage({ processes }) {
  const [loading, setLoading] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [resultado, setResultado] = useState(null);
  const [selectedProcess, setSelectedProcess] = useState('');

  async function handleSorteo(e) {
    e.preventDefault();
    if (!selectedProcess) {
      setFeedback({ type: 'error', text: 'Seleccione un proceso electoral' });
      return;
    }
    
    setLoading(true);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/sorteos/generar-mesas?procesoId=${selectedProcess}`, { method: 'POST' });
      setResultado(data);
      setFeedback({ type: 'success', text: data.mensaje });
    } catch (error) {
      setFeedback({ type: 'error', text: 'Error en el sorteo: ' + error.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="panel form-panel">
      <div className="panel-heading">
        <div>
          <h2>Sorteo de Miembros de Mesa</h2>
          <p className="muted">Genera de forma aleatoria, segura y trazable a los titulares y suplentes.</p>
        </div>
      </div>

      {feedback && <div className={`alert ${feedback.type}`}>{feedback.text}</div>}

      {!resultado ? (
        <form onSubmit={handleSorteo} style={{ marginTop: '20px' }}>
          <div className="form-row">
            <label>Proceso Electoral
              <select value={selectedProcess} onChange={e => setSelectedProcess(e.target.value)} required disabled={loading}>
                <option value="">-- Seleccione el proceso --</option>
                {processes.map(p => (
                  <option key={p.id} value={p.id}>{p.nombre}</option>
                ))}
              </select>
            </label>
          </div>
          
          <div style={{ background: '#fff3d8', color: '#836116', padding: '15px', borderRadius: '8px', marginTop: '20px' }}>
            <strong>Advertencia:</strong> Esta acción es irreversible e invalidará los sorteos anteriores para este proceso, salvo resolución expresa del CEUNP.
          </div>

          <div className="form-actions" style={{ marginTop: '30px' }}>
            <button type="submit" disabled={loading || !selectedProcess}>
              <MenuIcon name="calendar" /> {loading ? 'Sorteando...' : 'Ejecutar Sorteo Público'}
            </button>
          </div>
        </form>
      ) : (
        <div style={{ marginTop: '30px', padding: '20px', border: '1px solid #e3e9f1', borderRadius: '12px' }}>
          <h3>Resultados del Sorteo</h3>
          <ul style={{ listStyle: 'none', padding: 0, marginTop: '15px', lineHeight: '2' }}>
            <li><strong>Fecha y Hora:</strong> {new Date(resultado.fechaSorteo).toLocaleString()}</li>
            <li><strong>Semilla criptográfica:</strong> <code style={{ background: '#eef2f6', padding: '2px 6px', borderRadius: '4px' }}>{resultado.semilla}</code></li>
            <li><strong>Estado:</strong> Completado correctamente y registrado en bitácora.</li>
          </ul>
          <p style={{ marginTop: '20px' }}>Las actas de sorteo y credenciales de los miembros elegidos ya están disponibles para su impresión.</p>
          <button className="primary-small" style={{ marginTop: '20px' }} onClick={() => setResultado(null)}>Volver</button>
        </div>
      )}
    </div>
  );
}
