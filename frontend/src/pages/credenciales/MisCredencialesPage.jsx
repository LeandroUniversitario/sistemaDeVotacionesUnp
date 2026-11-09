import { useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { TIPOS_CREDENCIAL, TarjetaCredencial, descargarPNG, fecha, imprimirCredenciales, numeroCredencial } from './LectorQR';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../personeros/personeros.css';
import './credenciales.css';

const INDICACIONES = {
  ELECTOR: 'Muéstrelo al secretario de su mesa para que verifique su identidad antes de votar.',
  MIEMBRO_MESA: 'Preséntelo al instalar la mesa para acreditar que fue sorteado como miembro.',
  PERSONERO: 'Preséntelo al presidente de mesa para acreditarse y fiscalizar.',
};

/**
 * CUS07 · Credenciales propias del docente (pase de votación, fotocheck, credencial de personero).
 * El QR se muestra solo al generarlo; si se pierde, se vuelve a generar y el anterior deja de valer.
 */
export default function MisCredencialesPage({ foco = 'ELECTOR', onSessionExpired }) {
  const [procesos, setProcesos] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(null);
  const [feedback, setFeedback] = useState(null);
  const [generadas, setGeneradas] = useState({});   // clave → credencial recién generada (con QR)
  const [solicitudes, setSolicitudes] = useState({}); // clave → solicitud info
  const [modalSolicitud, setModalSolicitud] = useState(null); // { p, c }
  const [motivoSolicitud, setMotivoSolicitud] = useState('Extravío de credencial QR / Requiere nueva emisión oficial');
  const [enviandoSolicitud, setEnviandoSolicitud] = useState(false);

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  async function cargar() {
    const lista = await apiRequest('/api/credenciales/mias');
    setProcesos(lista);
    // Cargar si tienen solicitudes pendientes
    const solMap = {};
    for (const p of lista) {
      for (const c of (p.credenciales || [])) {
        const k = `${p.id}-${c.tipo}-${c.idTitular}`;
        try {
          const resp = await apiRequest(`/api/credenciales/solicitud-vigente?idProceso=${p.id}&tipo=${c.tipo}`);
          if (resp && resp.tieneSolicitud) {
            solMap[k] = resp.solicitud;
          }
        } catch {
          // Ignorar
        }
      }
    }
    setSolicitudes(solMap);
  }

  useEffect(() => {
    (async () => {
      try { await cargar(); } catch (error) { manejarError(error); } finally { setCargando(false); }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const clave = (p, c) => `${p.id}-${c.tipo}-${c.idTitular}`;

  async function enviarSolicitudRegeneracion() {
    if (!modalSolicitud) return;
    const { p, c } = modalSolicitud;
    setEnviandoSolicitud(true);
    setFeedback(null);
    try {
      const resp = await apiRequest('/api/credenciales/solicitar-regeneracion', {
        method: 'POST',
        body: JSON.stringify({
          idProceso: p.id,
          tipo: c.tipo,
          idTitular: c.idTitular,
          motivo: motivoSolicitud,
        }),
      });
      setFeedback({ type: 'success', text: resp.mensaje || 'Solicitud enviada al CEUNP exitosamente.' });
      setModalSolicitud(null);
      await cargar();
    } catch (error) {
      manejarError(error);
    } finally {
      setEnviandoSolicitud(false);
    }
  }

  async function generar(p, c) {
    const k = clave(p, c);
    setSaving(k);
    setFeedback(null);
    try {
      const data = await apiRequest('/api/credenciales/mias', {
        method: 'POST',
        body: JSON.stringify({ idProceso: p.id, tipo: c.tipo, idTitular: c.idTitular }),
      });
      setGeneradas((prev) => ({ ...prev, [k]: data }));
      await cargar();
    } catch (error) {
      manejarError(error);
    } finally {
      setSaving(null);
    }
  }

  if (cargando) return <p className="empty-state">Cargando…</p>;

  // Filtrar estrictamente por el foco de la pantalla (PERSONERO, MIEMBRO_MESA o ELECTOR)
  // para evitar duplicar el Pase de votación en pantallas especializadas
  const credenciales = procesos
    .flatMap((p) => p.credenciales.map((c) => ({ p, c })))
    .filter(({ c }) => (foco ? c.tipo === foco : true));

  if (credenciales.length === 0) {
    return (
      <div className="panel cv-placeholder">
        <span className="cv-placeholder-icon"><MenuIcon name="qr" size={28} /></span>
        <h2>No tiene {foco === 'PERSONERO' ? 'credencial de personero' : foco === 'MIEMBRO_MESA' ? 'fotocheck de miembro de mesa' : 'credenciales'} disponible(s)</h2>
        <p className="muted">
          {foco === 'PERSONERO'
            ? 'Aparece cuando el CEUNP acredita su designación como personero de una lista.'
            : foco === 'MIEMBRO_MESA'
              ? 'Aparece cuando sale sorteado como miembro de mesa en un proceso electoral.'
              : 'Aparecen cuando figura en el padrón definitivo de un proceso en curso.'}
        </p>
      </div>
    );
  }

  return (
    <div className="pd-shell cq-shell">
      {feedback && <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>}

      <div className="cq-mias">
        {credenciales.map(({ p, c }) => {
          const k = clave(p, c);
          const nueva = generadas[k];
          const tipo = TIPOS_CREDENCIAL[c.tipo];
          const puede = p.admiteEmision && c.apto;
          const sol = solicitudes[k];
          const tieneSolPendiente = sol && sol.estado === 'PENDIENTE';
          const credencialAMostrar = nueva || (c.credencial?.qr ? { ...c, ...c.credencial } : null);

          return (
            <section key={k} className="panel cq-mia" style={{ '--cq-color': tipo.color }}>
              <div className="cq-mia-head">
                <span className="cq-mia-icono"><MenuIcon name="qr" size={20} /></span>
                <div>
                  <h3>{tipo.titulo} <em>{tipo.rf}</em></h3>
                  <p className="muted">{p.nombre} · {c.funcion}{c.numeroMesa ? ` · Mesa ${c.numeroMesa}` : ''}</p>
                </div>
              </div>

              {/* Si hay QR (recién generado o vigente en base de datos), mostrarlo de forma permanente */}
              {credencialAMostrar ? (
                <div className="cq-mia-qr">
                  <TarjetaCredencial credencial={credencialAMostrar} proceso={p} size={200} />
                  <p className="cq-aviso-once">
                    <MenuIcon name="shield" size={14} /> Credencial oficial emitida por el CEUNP para la jornada electoral.
                  </p>
                  <div className="cv-actions" style={{ justifyContent: 'center', marginBottom: 12 }}>
                    <button type="button" className="cv-btn cv-btn-primary" onClick={() => descargarPNG(credencialAMostrar)}>
                      <MenuIcon name="download" size={15} /> Descargar PNG
                    </button>
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirCredenciales([credencialAMostrar], p)}>
                      <MenuIcon name="file" size={15} /> Imprimir
                    </button>
                  </div>

                  {tieneSolPendiente ? (
                    <div style={{
                      padding: '8px 12px', borderRadius: 8,
                      background: '#fffbeb', border: '1px solid #fef3c7',
                      color: '#92400e', fontSize: 13, display: 'inline-flex', alignItems: 'center', gap: 6,
                    }}>
                      <MenuIcon name="clock" size={14} />
                      Solicitud de nuevo QR enviada al CEUNP (Pendiente de aprobación).
                    </div>
                  ) : (
                    <div style={{ textAlign: 'center', marginTop: 8 }}>
                      <button
                        type="button"
                        className="cv-btn cv-btn-ghost"
                        onClick={() => {
                          setMotivoSolicitud(`Extravío de ${tipo.titulo} / Requiere nueva emisión oficial`);
                          setModalSolicitud({ p, c });
                        }}
                        style={{ fontSize: 13 }}
                      >
                        <MenuIcon name="refresh" size={14} /> Solicitar nuevo QR al CEUNP
                      </button>
                    </div>
                  )}
                </div>
              ) : (
                <div className="cq-mia-estado">
                  {c.credencial ? (
                    <p><span className="cv-estado votacion">Vigente</span> {numeroCredencial(c.credencial.id)} · generada el {fecha(c.credencial.fechaEmision)} · vence {fecha(c.credencial.fechaExpiracion)}</p>
                  ) : c.apto ? (
                    <p><span className="cv-estado creado">Sin generar</span> Aún no tiene esta credencial emitida por el CEUNP.</p>
                  ) : (
                    <p><span className="cv-estado anulado">No disponible</span> {c.motivo}</p>
                  )}
                  <p className="muted">{INDICACIONES[c.tipo]}</p>
                  {!p.admiteEmision && <p className="muted">{p.motivoNoAdmite}</p>}

                  {tieneSolPendiente ? (
                    <div style={{
                      padding: '8px 12px', borderRadius: 8,
                      background: '#fffbeb', border: '1px solid #fef3c7',
                      color: '#92400e', fontSize: 13, display: 'inline-flex', alignItems: 'center', gap: 6,
                    }}>
                      <MenuIcon name="clock" size={14} />
                      Solicitud enviada al CEUNP el {new Date(sol.fechaSolicitud || sol.fecha_solicitud).toLocaleDateString('es-PE')} (Pendiente).
                    </div>
                  ) : puede && (
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-primary" disabled={saving === k}
                        onClick={() => generar(p, c)}>
                        <MenuIcon name="qr" size={15} />
                        {saving === k ? 'Generando…' : 'Generar mi credencial'}
                      </button>
                    </div>
                  )}
                </div>
              )}
            </section>
          );
        })}
      </div>

      {/* Modal para solicitar nuevo QR al CEUNP */}
      {modalSolicitud && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 9999, padding: '1rem',
        }}>
          <div style={{
            background: '#fff', borderRadius: 14, maxWidth: 480, width: '100%',
            padding: '1.5rem', boxShadow: '0 20px 25px -5px rgba(0,0,0,0.2)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
              <div style={{ width: 40, height: 40, borderRadius: '50%', background: '#ede9fe', color: '#7c3aed', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <MenuIcon name="refresh" size={20} />
              </div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', fontWeight: 700, color: 'var(--text-main)' }}>
                Solicitar nuevo QR al CEUNP
              </h3>
            </div>
            <p style={{ fontSize: '.88rem', color: 'var(--text-muted)', lineHeight: 1.5, marginBottom: 16 }}>
              Solicitud de regeneración para <strong>{TIPOS_CREDENCIAL[modalSolicitud.c.tipo].titulo}</strong>. El Comité Electoral evaluará la solicitud y emitirá una nueva credencial con un nuevo QR oficial.
            </p>
            <div style={{ marginBottom: 16 }}>
              <label style={{ display: 'block', fontSize: '.84rem', fontWeight: 600, color: 'var(--text-main)', marginBottom: 6 }}>
                Motivo de la solicitud:
              </label>
              <textarea
                rows={3}
                value={motivoSolicitud}
                onChange={(e) => setMotivoSolicitud(e.target.value)}
                placeholder="Indique el motivo por el cual requiere un nuevo QR..."
                style={{
                  width: '100%', padding: '8px 12px', borderRadius: 8,
                  border: '1px solid var(--border)', fontSize: '.88rem',
                  fontFamily: 'inherit', resize: 'vertical', boxSizing: 'border-box',
                }}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <button
                type="button"
                className="cv-btn cv-btn-ghost"
                onClick={() => setModalSolicitud(null)}
                disabled={enviandoSolicitud}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="cv-btn cv-btn-primary"
                onClick={enviarSolicitudRegeneracion}
                disabled={enviandoSolicitud || !motivoSolicitud.trim()}
              >
                {enviandoSolicitud ? 'Enviando…' : 'Enviar solicitud al CEUNP'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
