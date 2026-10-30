import { useState, useEffect, useCallback } from 'react';
import { apiRequest } from '../api/apiClient';
import MenuIcon from '../components/MenuIcon';
import { TarjetaCredencial, descargarPNG, imprimirCredenciales } from './credenciales/LectorQR';
import './credenciales/credenciales.css';

/**
 * CUS07 - Portal del Docente: Mi Pase de Votación QR
 *
 * Muestra el estado electoral del docente autenticado:
 * - Si está habilitado para votar o el motivo por el que no lo está
 * - La(s) mesa(s) asignada(s) con local y aula
 * - Botón para generar/ver su credencial QR de elector
 * - Si fue sorteado como miembro de mesa
 */
export default function MiPaseQRPage({ onSessionExpired }) {
  const [estado, setEstado]   = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);
  const [generando, setGenerando] = useState(null); // idProceso generando
  const [feedback, setFeedback]   = useState(null);
  const [credencialesGeneradas, setCredencialesGeneradas] = useState({}); // idProceso -> data

  const cargar = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await apiRequest('/api/docente/mi-pase');
      setEstado(data);
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [onSessionExpired]);

  useEffect(() => { cargar(); }, [cargar]);

  async function generarPase(idProceso) {
    setGenerando(idProceso);
    setFeedback(null);
    try {
      const data = await apiRequest(`/api/docente/mi-pase/${idProceso}`, { method: 'POST' });
      setCredencialesGeneradas((prev) => ({ ...prev, [idProceso]: data }));
      setFeedback({ type: 'success', text: '¡Pase QR generado exitosamente! Descárgalo o imprímelo a continuación.' });
      await cargar(); // recargar estado
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') onSessionExpired();
      else setFeedback({ type: 'error', text: err.message });
    } finally {
      setGenerando(null);
    }
  }

  if (loading) {
    return (
      <section className="panel">
        <div className="panel-heading"><h2>Mi Pase de Votación QR</h2></div>
        <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-muted)' }}>
          <div className="spinner" style={{ margin: '0 auto 1rem' }} />
          Cargando tu estado electoral...
        </div>
      </section>
    );
  }

  if (error) {
    return (
      <section className="panel">
        <div className="panel-heading"><h2>Mi Pase de Votación QR</h2></div>
        <div className="alert error" style={{ margin: '1.5rem' }}>{error}</div>
        <button className="text-button" onClick={cargar} style={{ margin: '0 1.5rem 1.5rem' }}>Reintentar</button>
      </section>
    );
  }

  if (!estado) return null;

  const habilitado = (estado.habilitadoParaVotar ?? estado.habilitado_para_votar) === 1
    || (estado.habilitadoParaVotar ?? estado.habilitado_para_votar) === true;
  const tieneProcesoActivo = estado.procesos && estado.procesos.length > 0;
  const motivoInhab = estado.motivoInhabilitacion || estado.motivo_inhabilitacion;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>

      {/* Tarjeta de identidad del docente */}
      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Mi Pase de Votación QR</h2>
            <p className="muted">Portal del Elector — CUS07</p>
          </div>
          <button className="text-button" onClick={cargar}>
            <MenuIcon name="refresh" size={15} /> Actualizar
          </button>
        </div>

        <div style={{ padding: '1.5rem' }}>
          {/* Datos personales */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'auto 1fr',
            gap: '1.25rem',
            alignItems: 'center',
            marginBottom: '1.5rem',
            paddingBottom: '1.5rem',
            borderBottom: '1px solid var(--border)',
          }}>
            <div style={{
              width: 64, height: 64, borderRadius: '50%',
              background: 'linear-gradient(135deg, #7c3aed, #a855f7)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: '#fff', fontSize: 28, fontWeight: 700,
              flexShrink: 0,
            }}>
              {(estado.apellidos || '?')[0]}
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 18, color: 'var(--text-main)' }}>
                {estado.apellidos}, {estado.nombres}
              </div>
              <div style={{ color: 'var(--text-muted)', fontSize: 13, marginTop: 2 }}>
                DNI: <strong>{estado.dni}</strong> · {estado.categoria} · {estado.dedicacion}
              </div>
              <div style={{ color: 'var(--text-muted)', fontSize: 13 }}>
                {estado.facultad} — {estado.departamento}
              </div>
            </div>
          </div>

          {/* Estado de habilitación */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            padding: '1rem 1.25rem',
            borderRadius: 10,
            background: habilitado
              ? 'linear-gradient(135deg, rgba(16,185,129,0.12), rgba(5,150,105,0.08))'
              : 'linear-gradient(135deg, rgba(239,68,68,0.12), rgba(220,38,38,0.08))',
            border: `1.5px solid ${habilitado ? 'rgba(16,185,129,0.3)' : 'rgba(239,68,68,0.3)'}`,
          }}>
            <div style={{
              width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
              background: habilitado ? 'rgba(16,185,129,0.2)' : 'rgba(239,68,68,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <MenuIcon name={habilitado ? 'check' : 'alert'} size={22}
                style={{ color: habilitado ? '#10b981' : '#ef4444' }} />
            </div>
            <div>
              <div style={{
                fontWeight: 700, fontSize: 15,
                color: habilitado ? '#10b981' : '#ef4444',
              }}>
                {habilitado ? '✓ Habilitado para votar' : '✗ No habilitado para votar'}
              </div>
              {!habilitado && motivoInhab && (
                <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>
                  <strong>Motivo:</strong> {motivoInhab}
                </div>
              )}
              {habilitado && (
                <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>
                  Estás en el padrón electoral activo.
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Feedback */}
      {feedback && (
        <div className={`alert ${feedback.type}`} style={{ borderRadius: 10 }}>
          {feedback.text}
        </div>
      )}

      {/* Procesos activos con mesas y pases */}
      {tieneProcesoActivo ? (
        estado.procesos.map(proc => {
          const idProc = proc.idProceso ?? proc.id_proceso;
          const estadoProc = proc.estadoProceso ?? proc.estado_proceso;
          const fechaIni = proc.fechaInicio ?? proc.fecha_inicio;
          const numMesa = proc.numeroMesa ?? proc.numero_mesa;
          const locVot = proc.localVotacion ?? proc.local_votacion;
          const miembroRol = proc.esMiembroMesa ?? proc.es_miembro_mesa;
          const tieneCred = proc.tieneCredencialVigente ?? proc.tiene_credencial_vigente;

          return (
            <section key={idProc} className="panel">
              <div className="panel-heading">
                <div>
                  <h2 style={{ fontSize: 16 }}>{proc.proceso}</h2>
                  <p className="muted">
                    Estado: <span style={{ fontWeight: 600 }}>{estadoProc}</span>
                    {fechaIni && ` · ${new Date(fechaIni).toLocaleDateString('es-PE')}`}
                  </p>
                </div>
                <span className={`badge ${
                  estadoProc === 'VOTACION' ? 'badge-green' :
                  estadoProc === 'INSCRIPCION' ? 'badge-blue' : 'badge-gray'
                }`}>
                  {estadoProc}
                </span>
              </div>

              <div style={{ padding: '0 1.5rem 1.5rem', display: 'grid', gap: '1rem' }}>

                {/* Mesa asignada */}
                {numMesa ? (
                  <div style={{
                    display: 'grid', gridTemplateColumns: 'auto 1fr',
                    gap: '1rem', alignItems: 'start',
                    padding: '1rem 1.25rem', borderRadius: 10,
                    background: 'var(--bg-input)', border: '1px solid var(--border)',
                  }}>
                    <div style={{
                      width: 40, height: 40, borderRadius: 8,
                      background: 'rgba(14,165,233,0.15)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <MenuIcon name="table" size={20} style={{ color: '#0ea5e9' }} />
                    </div>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: 14, color: 'var(--text-main)' }}>
                        Mesa Nº {numMesa}
                      </div>
                      {locVot && (
                        <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>
                          📍 {locVot}{proc.aula ? ` — Aula: ${proc.aula}` : ''}
                        </div>
                      )}
                      {miembroRol && (
                        <div style={{
                          marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 6,
                          padding: '3px 10px', borderRadius: 20,
                          background: 'rgba(234,179,8,0.15)', color: '#ca8a04',
                          fontSize: 12, fontWeight: 600,
                        }}>
                          <MenuIcon name="shield" size={13} />
                          Sorteado como miembro de mesa · {miembroRol}
                        </div>
                      )}
                    </div>
                  </div>
                ) : (
                  <div style={{ fontSize: 13, color: 'var(--text-muted)', padding: '0.5rem 0' }}>
                    Mesa aún no asignada para este proceso.
                  </div>
                )}

                {/* Credencial QR */}
                <div style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  flexWrap: 'wrap', gap: '0.75rem',
                  padding: '1rem 1.25rem', borderRadius: 10,
                  background: tieneCred
                    ? 'linear-gradient(135deg, rgba(139,92,246,0.1), rgba(168,85,247,0.06))'
                    : 'var(--bg-input)',
                  border: `1.5px solid ${tieneCred ? 'rgba(139,92,246,0.3)' : 'var(--border)'}`,
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div style={{
                      width: 40, height: 40, borderRadius: 8, flexShrink: 0,
                      background: tieneCred
                        ? 'rgba(139,92,246,0.2)' : 'rgba(107,114,128,0.1)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <MenuIcon name="qr" size={20}
                        style={{ color: tieneCred ? '#8b5cf6' : 'var(--text-muted)' }} />
                    </div>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: 14, color: 'var(--text-main)' }}>
                        Credencial QR de Elector
                      </div>
                      <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>
                        {tieneCred
                          ? '✓ Credencial vigente generada'
                          : habilitado
                            ? 'Aún no generada — puedes solicitarla ahora'
                            : 'No disponible (docente inhabilitado)'}
                      </div>
                    </div>
                  </div>

                  {habilitado && (
                    <button
                      className={tieneCred ? 'text-button' : 'btn-primary'}
                      onClick={() => generarPase(idProc)}
                      disabled={generando === idProc}
                      style={{ whiteSpace: 'nowrap', minWidth: 160 }}
                    >
                      <MenuIcon name="qr" size={15} />
                      {generando === idProc
                        ? 'Generando...'
                        : tieneCred
                          ? 'Regenerar QR'
                          : 'Obtener mi QR'}
                    </button>
                  )}
                </div>

                {/* Tarjeta del QR generado */}
                {credencialesGeneradas[idProc] && (
                  <div style={{
                    marginTop: '1.25rem',
                    padding: '1.5rem',
                    borderRadius: 12,
                    background: '#fff',
                    border: '2px solid #8b5cf6',
                    boxShadow: '0 10px 25px -5px rgba(139, 92, 246, 0.15)',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '1rem',
                  }}>
                    <div style={{ textAlign: 'center' }}>
                      <h3 style={{ margin: 0, color: '#6d28d9', fontSize: '1.1rem', fontWeight: 700 }}>
                        🎉 Tu Pase de Votación QR
                      </h3>
                      <p style={{ margin: '4px 0 0', fontSize: '0.85rem', color: '#6b7280' }}>
                        Descárgalo o imprímelo ahora. Por seguridad criptográfica, el QR solo se genera en este momento.
                      </p>
                    </div>

                    <TarjetaCredencial
                      credencial={credencialesGeneradas[idProc]}
                      proceso={{ nombre: proc.proceso }}
                      size={190}
                    />

                    <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', justifyContent: 'center' }}>
                      <button
                        type="button"
                        className="cv-btn cv-btn-primary"
                        onClick={() => descargarPNG(credencialesGeneradas[idProc])}
                      >
                        <MenuIcon name="download" size={16} /> Descargar imagen (PNG)
                      </button>
                      <button
                        type="button"
                        className="cv-btn cv-btn-ghost"
                        onClick={() => imprimirCredenciales([credencialesGeneradas[idProc]], { nombre: proc.proceso })}
                      >
                        <MenuIcon name="file" size={16} /> Imprimir pase
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </section>
          );
        })
      ) : (
        <section className="panel">
          <div style={{ padding: '2.5rem', textAlign: 'center', color: 'var(--text-muted)' }}>
            <MenuIcon name="calendar" size={40} style={{ opacity: 0.3, marginBottom: 12 }} />
            <p style={{ fontSize: 15, fontWeight: 600, color: 'var(--text-main)', marginBottom: 6 }}>
              Sin procesos electorales activos
            </p>
            <p style={{ fontSize: 13 }}>
              No apareces en el padrón de ningún proceso electoral activo.
              Cuando el CEUNP apruebe el padrón y te incluya, aquí verás tu
              mesa de sufragio y podrás generar tu Pase de Votación QR.
            </p>
          </div>
        </section>
      )}

      {/* Información sobre el proceso QR */}
      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2 style={{ fontSize: 14, fontWeight: 600 }}>¿Cómo usar mi Pase QR?</h2>
          </div>
        </div>
        <div style={{ padding: '0 1.5rem 1.5rem', display: 'grid', gap: '0.75rem' }}>
          {[
            { n: 1, icon: 'qr',     text: 'Genera tu Pase QR haciendo clic en "Obtener mi QR" cuando el proceso esté en estado VOTACION.' },
            { n: 2, icon: 'person', text: 'El día de las elecciones, presenta el QR en tu mesa de sufragio (en pantalla o impreso).' },
            { n: 3, icon: 'scan',   text: 'El Miembro de Mesa escaneará tu código para registrar tu asistencia.' },
            { n: 4, icon: 'vote',   text: 'Pasa a la cabina de votación y ejerce tu voto de forma secreta.' },
          ].map(({ n, icon, text }) => (
            <div key={n} style={{ display: 'flex', gap: '0.75rem', alignItems: 'flex-start' }}>
              <div style={{
                minWidth: 28, height: 28, borderRadius: '50%',
                background: 'rgba(139,92,246,0.15)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 13, fontWeight: 700, color: '#8b5cf6',
              }}>{n}</div>
              <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: 0, paddingTop: 4 }}>{text}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}