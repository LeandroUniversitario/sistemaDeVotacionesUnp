import { useState, useEffect } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';

export default function MiembroMesaPage() {
  const [mesas, setMesas] = useState([]);
  const [selectedMesa, setSelectedMesa] = useState(null);
  const [dniElector, setDniElector] = useState('');
  const [electorVerificado, setElectorVerificado] = useState(null);
  const [loading, setLoading] = useState(false);
  const [feedback, setFeedback] = useState(null);

  useEffect(() => {
    loadMesas();
  }, []);

  async function loadMesas() {
    setLoading(true);
    try {
      const data = await apiRequest('/api/mesas');
      setMesas(data);
    } catch (error) {
      setFeedback({ type: 'error', text: 'Error cargando mesas: ' + error.message });
    } finally {
      setLoading(false);
    }
  }

  async function handleInstalar() {
    if (!selectedMesa) return;
    setLoading(true);
    setFeedback(null);
    try {
      const resp = await apiRequest(`/api/mesas/${selectedMesa.id}/instalar`, { method: 'POST' });
      setSelectedMesa(resp.mesa);
      setFeedback({ type: 'success', text: 'Mesa instalada correctamente.' });
      loadMesas();
    } catch (error) {
      setFeedback({ type: 'error', text: error.message });
    } finally {
      setLoading(false);
    }
  }

  async function handleCerrar() {
    if (!selectedMesa) return;
    setLoading(true);
    setFeedback(null);
    try {
      const resp = await apiRequest(`/api/mesas/${selectedMesa.id}/cerrar`, { method: 'POST' });
      setSelectedMesa(resp.mesa);
      setFeedback({ type: 'success', text: 'Sufragio cerrado correctamente.' });
      loadMesas();
    } catch (error) {
      setFeedback({ type: 'error', text: error.message });
    } finally {
      setLoading(false);
    }
  }

  async function handleVerificarElector(e) {
    e.preventDefault();
    setFeedback(null);
    setElectorVerificado(null);
    setLoading(true);
    try {
      const data = await apiRequest(`/api/mesas/${selectedMesa.id}/verificar-elector?dni=${dniElector}`);
      setElectorVerificado(data);
    } catch (error) {
      setFeedback({ type: 'error', text: error.message });
    } finally {
      setLoading(false);
    }
  }

  async function handleRegistrarAsistencia() {
    if (!electorVerificado) return;
    setLoading(true);
    try {
      await apiRequest(`/api/mesas/${selectedMesa.id}/asistencia`, {
        method: 'POST',
        body: JSON.stringify({ dni: electorVerificado.dni })
      });
      setFeedback({ type: 'success', text: `Asistencia de ${electorVerificado.nombres} registrada con éxito. (Habilitar terminal)` });
      setElectorVerificado(null);
      setDniElector('');
    } catch (error) {
      setFeedback({ type: 'error', text: error.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="miembro-mesa-layout">
      <div className="panel-heading">
        <div>
          <h2>Gestión de Mesa de Sufragio</h2>
          <p className="muted">Instalación, verificación de electores y cierre</p>
        </div>
      </div>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="alert">
          {feedback.text}
        </div>
      )}

      <div className="panel" style={{ marginBottom: '20px' }}>
        <h3>Seleccionar Mesa asignada</h3>
        <select 
          value={selectedMesa ? selectedMesa.id : ''} 
          onChange={(e) => {
            const m = mesas.find(x => x.id === Number(e.target.value));
            setSelectedMesa(m || null);
            setElectorVerificado(null);
            setFeedback(null);
          }}
          disabled={loading}
          style={{ maxWidth: '300px', marginTop: '10px' }}
        >
          <option value="">-- Seleccione --</option>
          {mesas.map(m => (
            <option key={m.id} value={m.id}>Mesa {m.numero} - {m.estado}</option>
          ))}
        </select>
      </div>

      {selectedMesa && (
        <div className="panel">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3>Mesa {selectedMesa.numero} <span className={`badge ${selectedMesa.estado.toLowerCase()}`}>{selectedMesa.estado}</span></h3>
            <div className="action-buttons">
              {selectedMesa.estado === 'PENDIENTE' && (
                <button className="primary-small" onClick={handleInstalar} disabled={loading}>
                  <MenuIcon name="plus" /> Instalar Mesa
                </button>
              )}
              {selectedMesa.estado === 'INSTALADA' && (
                <button className="primary-small reject-button" onClick={handleCerrar} disabled={loading}>
                  <MenuIcon name="lock" /> Cerrar Sufragio
                </button>
              )}
            </div>
          </div>

          {selectedMesa.estado === 'INSTALADA' && (
            <div style={{ padding: '20px', border: '1px solid #e3e9f1', borderRadius: '8px', background: '#fcfdfd' }}>
              <h4>Verificar Elector (QR / DNI)</h4>
              <form onSubmit={handleVerificarElector} style={{ display: 'flex', gap: '10px', marginTop: '15px' }}>
                <input 
                  placeholder="Ingrese DNI del elector" 
                  value={dniElector} 
                  onChange={e => setDniElector(e.target.value)}
                  maxLength={8}
                  required
                  style={{ maxWidth: '250px' }}
                />
                <button type="submit" className="primary-small" disabled={loading}>
                  Buscar
                </button>
              </form>

              {electorVerificado && (
                <div style={{ marginTop: '20px', padding: '15px', background: '#eef2f6', borderRadius: '8px' }}>
                  <p><strong>Nombres:</strong> {electorVerificado.nombres} {electorVerificado.apellidos}</p>
                  <p><strong>DNI:</strong> {electorVerificado.dni}</p>
                  {electorVerificado.yaVoto ? (
                    <p style={{ color: '#ae2b35', fontWeight: 'bold', marginTop: '10px' }}>Este elector ya ha votado.</p>
                  ) : (
                    <button className="primary-small" style={{ marginTop: '15px' }} onClick={handleRegistrarAsistencia} disabled={loading}>
                      Confirmar Identidad y Habilitar Voto
                    </button>
                  )}
                </div>
              )}
            </div>
          )}

          {selectedMesa.estado === 'CERRADA' && (
            <div style={{ padding: '20px', textAlign: 'center', color: '#536176' }}>
              <h4>El sufragio ha finalizado.</h4>
              <p>Proceda a realizar el escrutinio (Conteo de votos manual).</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
