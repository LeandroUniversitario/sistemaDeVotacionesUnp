import { useState, useEffect } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';
import './convocatoria/convocatoria.css';
import './padron/padron.css';
import './credenciales/credenciales.css';
import './inscripcion/inscripcion.css';
import './votacion/votacion.css';
import './mesa/mesa-ejecutivo.css';

const ESTADO_MESA = {
  PENDIENTE: { clase: 'creado', texto: 'Por instalar' },
  INSTALADA: { clase: 'votacion', texto: 'Sufragio abierto' },
  CERRADA: { clase: 'inscripcion', texto: 'Sufragio cerrado' },
  NO_INSTALADA: { clase: 'anulado', texto: 'No instalada' },
  ANULADA: { clase: 'anulado', texto: 'Anulada' },
};

export default function MiembroMesaPage({ onIrImpugnaciones, onIrInstalacion, onIrCierre, onIrEscrutinio }) {
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

  const estado = selectedMesa ? (ESTADO_MESA[selectedMesa.estado] ?? { clase: '', texto: selectedMesa.estado }) : null;

  return (
    <div className="pd-shell mx">
      <div className="panel mx-elegir">
        <label className="cv-field">
          <span className="cv-label">Mesa asignada</span>
          <select
            value={selectedMesa ? selectedMesa.id : ''}
            onChange={(e) => {
              const m = mesas.find(x => x.id === Number(e.target.value));
              setSelectedMesa(m || null);
              setElectorVerificado(null);
              setFeedback(null);
            }}
            disabled={loading}
          >
            <option value="">Seleccione una mesa</option>
            {mesas.map(m => (
              <option key={m.id} value={m.id}>Mesa {m.numero} · {(ESTADO_MESA[m.estado] ?? { texto: m.estado }).texto}</option>
            ))}
          </select>
        </label>
        <p className="muted">Desde aquí instala la mesa, verifica a los electores y cierra el sufragio.</p>
      </div>

      {feedback && (
        <div className={`alert ${feedback.type}`} role="alert">
          {feedback.text}
        </div>
      )}

      {selectedMesa && (
        <div className="panel mx-ficha">
          <div className="mx-ficha-top">
            <div>
              <h3>Mesa {selectedMesa.numero}</h3>
              <p>Gestión de la jornada de sufragio</p>
            </div>
            <div className="mx-acciones">
              <span className={`cv-estado ${estado.clase}`}>{estado.texto}</span>
            </div>
          </div>

          {selectedMesa.estado === 'PENDIENTE' && (
            <div className="mx-mensaje info">
              <MenuIcon name="shield" size={20} />
              <div>
                <h4>La mesa aún no está instalada</h4>
                <p>Acredite a los miembros, registre el material y emita el acta de instalación.</p>
              </div>
            </div>
          )}

          {selectedMesa.estado === 'INSTALADA' && (
            <div className="cv-form">
              <div className="cv-section-head">
                <div>
                  <h3>Verificar elector</h3>
                  <p>Busque al elector por su DNI para confirmar su identidad y habilitarle el voto.</p>
                </div>
              </div>
              <form className="vt-dni" onSubmit={handleVerificarElector}>
                <input
                  placeholder="DNI del elector (8 dígitos)"
                  aria-label="DNI del elector"
                  inputMode="numeric"
                  value={dniElector}
                  onChange={e => setDniElector(e.target.value)}
                  maxLength={8}
                  required
                />
                <button type="submit" className="cv-btn cv-btn-primary" disabled={loading}>
                  <MenuIcon name="search" size={15} /> Buscar
                </button>
              </form>

              {electorVerificado && (
                <div className={`cq-resultado ${electorVerificado.yaVoto ? 'mal' : 'ok'}`} role="status">
                  <div className="cq-resultado-head">
                    <span className="cq-resultado-icono"><MenuIcon name={electorVerificado.yaVoto ? 'close' : 'check'} size={20} /></span>
                    <div>
                      <strong>{electorVerificado.nombres} {electorVerificado.apellidos}</strong>
                      <span>DNI {electorVerificado.dni}{electorVerificado.yaVoto ? ' · este elector ya votó' : ''}</span>
                    </div>
                  </div>
                  {!electorVerificado.yaVoto && (
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-success" onClick={handleRegistrarAsistencia} disabled={loading}>
                        <MenuIcon name="check" size={15} /> Confirmar identidad y habilitar voto
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {selectedMesa.estado === 'NO_INSTALADA' && (
            <div className="mx-mensaje peligro">
              <MenuIcon name="alert" size={20} />
              <div>
                <h4>La mesa fue declarada no instalada (RN07)</h4>
                <p>Sus electores no pueden votar en ella.</p>
              </div>
            </div>
          )}

          {selectedMesa.estado === 'CERRADA' && (
            <div className="mx-mensaje">
              <MenuIcon name="lock" size={20} />
              <div>
                <h4>El sufragio terminó</h4>
                <p>Continúe con el escrutinio de los votos de la mesa.</p>
              </div>
              <button type="button" className="cv-btn cv-btn-primary" style={{ marginLeft: 'auto', flex: 'none' }} onClick={onIrEscrutinio} disabled={loading || !onIrEscrutinio}>
                <MenuIcon name="table" size={15} /> Ir al escrutinio
              </button>
            </div>
          )}

          {/* CUS13 · impugnaciones de votos del escrutinio */}
          {selectedMesa.estado === 'CERRADA' && onIrImpugnaciones && (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onIrImpugnaciones} disabled={loading}>
                <MenuIcon name="scale" size={15} /> Impugnaciones del escrutinio
              </button>
            </div>
          )}

          {(selectedMesa.estado === 'PENDIENTE' || selectedMesa.estado === 'INSTALADA') && (
            <div className="cv-actions">
              {selectedMesa.estado === 'PENDIENTE' && (
                <button type="button" className="cv-btn cv-btn-primary" onClick={onIrInstalacion} disabled={loading || !onIrInstalacion}>
                  <MenuIcon name="shield" size={15} /> Instalar mesa
                </button>
              )}
              {selectedMesa.estado === 'INSTALADA' && (
                <button type="button" className="cv-btn im-btn-peligro" onClick={onIrCierre} disabled={loading || !onIrCierre}>
                  <MenuIcon name="lock" size={15} /> Ir a cerrar el sufragio
                </button>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
