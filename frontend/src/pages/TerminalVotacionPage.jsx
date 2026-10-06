import { useState, useEffect } from 'react';
import { apiRequest } from '../api/apiClient';

export default function TerminalVotacionPage({ procesoId, cargoId }) {
  const [listas, setListas] = useState([]);
  const [seleccion, setSeleccion] = useState(null); // { tipo: 'VALIDO'|'BLANCO'|'NULO', listaId?: num }
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState('ELEGIR'); // ELEGIR, CONFIRMAR, IMPRIMIENDO, FIN
  const [feedback, setFeedback] = useState(null);

  useEffect(() => {
    // Si no tenemos ids, usaremos valores por defecto de demostración
    loadListas();
  }, []);

  async function loadListas() {
    try {
      setLoading(true);
      // Asumiremos que existe un endpoint /api/procesos/1/listas
      // Para efectos de UI, si falla mockearemos la respuesta
      const data = await apiRequest(`/api/procesos/${procesoId || 1}/listas`).catch(() => [
        { id: 1, nombre: 'Docentes Unidos', simbolo: 'DU', candidatoRector: 'Juan Pérez' },
        { id: 2, nombre: 'Innovación Académica', simbolo: 'IA', candidatoRector: 'María García' }
      ]);
      setListas(Array.isArray(data) && data.length > 0 ? data : [
        { id: 1, nombre: 'Docentes Unidos', simbolo: 'DU', candidatoRector: 'Juan Pérez' },
        { id: 2, nombre: 'Innovación Académica', simbolo: 'IA', candidatoRector: 'María García' }
      ]);
    } finally {
      setLoading(false);
    }
  }

  function handleSeleccionar(tipo, listaId = null) {
    setSeleccion({ tipo, listaElegidaId: listaId });
  }

  function handleConfirmar() {
    if (!seleccion) return;
    setStep('CONFIRMAR');
  }

  async function emitirVoto() {
    setLoading(true);
    try {
      await apiRequest('/api/votos', {
        method: 'POST',
        body: JSON.stringify({
          procesoId: procesoId || 1,
          cargoId: cargoId || 1,
          tipo: seleccion.tipo,
          listaElegidaId: seleccion.listaElegidaId
        })
      });
      setStep('IMPRIMIENDO');
      setTimeout(() => setStep('FIN'), 3000);
    } catch (error) {
      setFeedback('Error emitiendo voto: ' + error.message);
      setStep('ELEGIR');
    } finally {
      setLoading(false);
    }
  }

  if (step === 'IMPRIMIENDO') {
    return (
      <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: '#0a192f', color: '#fff', textAlign: 'center' }}>
        <div>
          <div className="auth-icon-circle" style={{ margin: '0 auto', background: '#fff', color: '#0a192f' }}>
            <span style={{ fontSize: '32px' }}>🖨️</span>
          </div>
          <h2 style={{ marginTop: '20px' }}>Imprimiendo su cédula de votación...</h2>
          <p>Por favor, recoja la cédula impresa y deposítela en el ánfora.</p>
        </div>
      </div>
    );
  }

  if (step === 'FIN') {
    return (
      <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: '#e4f7ee', color: '#237b55', textAlign: 'center' }}>
        <div>
          <h2>¡Su voto ha sido registrado!</h2>
          <p>Puede salir de la cámara secreta.</p>
          <button className="primary-small" onClick={() => { setStep('ELEGIR'); setSeleccion(null); }}>Nuevo Elector (Admin Test)</button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: '40px', maxWidth: '800px', margin: '0 auto' }}>
      <header style={{ borderBottom: '2px solid #1769aa', paddingBottom: '10px', marginBottom: '30px' }}>
        <h1 style={{ color: '#073d70' }}>Cámara Secreta</h1>
        <p className="muted">Elecciones Docentes UNP - Seleccione su opción de voto</p>
      </header>

      {feedback && <div className="alert error">{feedback}</div>}

      {step === 'ELEGIR' && (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
            {listas.map(lista => (
              <div 
                key={lista.id}
                onClick={() => handleSeleccionar('VALIDO', lista.id)}
                style={{
                  border: seleccion?.listaElegidaId === lista.id ? '3px solid #1769aa' : '1px solid #cbd6e3',
                  borderRadius: '12px', padding: '20px', cursor: 'pointer',
                  background: seleccion?.listaElegidaId === lista.id ? '#e5f2ff' : '#fff',
                  textAlign: 'center', transition: 'all 0.2s'
                }}
              >
                <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#1769aa' }}>{lista.simbolo}</div>
                <h3 style={{ margin: '10px 0' }}>{lista.nombre}</h3>
                <p className="muted">Rector: {lista.candidatoRector || 'Candidato'}</p>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', gap: '20px', marginTop: '30px', justifyContent: 'center' }}>
            <button 
              className={seleccion?.tipo === 'BLANCO' ? 'primary-small' : 'secondary-button'} 
              style={{ padding: '15px 30px', fontSize: '1.1rem' }}
              onClick={() => handleSeleccionar('BLANCO')}
            >
              Voto en Blanco
            </button>
            <button 
              className={seleccion?.tipo === 'NULO' ? 'primary-small' : 'secondary-button'} 
              style={{ padding: '15px 30px', fontSize: '1.1rem', background: seleccion?.tipo === 'NULO' ? '#ae2b35' : undefined }}
              onClick={() => handleSeleccionar('NULO')}
            >
              Voto Nulo
            </button>
          </div>

          <div style={{ marginTop: '50px', textAlign: 'right' }}>
            <button 
              className="primary-small" 
              style={{ padding: '15px 40px', fontSize: '1.2rem' }}
              disabled={!seleccion}
              onClick={handleConfirmar}
            >
              Siguiente
            </button>
          </div>
        </>
      )}

      {step === 'CONFIRMAR' && (
        <div className="panel" style={{ textAlign: 'center', padding: '40px' }}>
          <h2>Confirme su voto</h2>
          <div style={{ margin: '30px 0', fontSize: '1.5rem', fontWeight: 'bold', color: '#073d70' }}>
            {seleccion.tipo === 'VALIDO' && (() => {
              const L = listas.find(l => l.id === seleccion.listaElegidaId);
              return L ? `Lista: ${L.nombre}` : 'Lista seleccionada';
            })()}
            {seleccion.tipo === 'BLANCO' && 'VOTO EN BLANCO'}
            {seleccion.tipo === 'NULO' && 'VOTO NULO'}
          </div>
          <div style={{ display: 'flex', gap: '20px', justifyContent: 'center' }}>
            <button className="secondary-button" onClick={() => setStep('ELEGIR')} disabled={loading}>Corregir</button>
            <button className="primary-small" onClick={emitirVoto} disabled={loading}>Confirmar Voto</button>
          </div>
        </div>
      )}
    </div>
  );
}
