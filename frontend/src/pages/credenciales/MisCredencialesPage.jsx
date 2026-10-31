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
  const [confirmar, setConfirmar] = useState(null);

  function manejarError(error) {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }

  async function cargar() {
    setProcesos(await apiRequest('/api/credenciales/mias'));
  }

  useEffect(() => {
    (async () => {
      try { await cargar(); } catch (error) { manejarError(error); } finally { setCargando(false); }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const clave = (p, c) => `${p.id}-${c.tipo}-${c.idTitular}`;

  async function generar(p, c) {
    const k = clave(p, c);
    setSaving(k);
    setConfirmar(null);
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
          return (
            <section key={k} className="panel cq-mia" style={{ '--cq-color': tipo.color }}>
              <div className="cq-mia-head">
                <span className="cq-mia-icono"><MenuIcon name="qr" size={20} /></span>
                <div>
                  <h3>{tipo.titulo} <em>{tipo.rf}</em></h3>
                  <p className="muted">{p.nombre} · {c.funcion}{c.numeroMesa ? ` · Mesa ${c.numeroMesa}` : ''}</p>
                </div>
              </div>

              {nueva ? (
                <div className="cq-mia-qr">
                  <TarjetaCredencial credencial={nueva} proceso={p} size={200} />
                  <p className="cq-aviso-once"><MenuIcon name="alert" size={14} /> Descárguelo o imprímalo ahora: este QR no se vuelve a mostrar.</p>
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-primary" onClick={() => descargarPNG(nueva)}><MenuIcon name="download" size={15} /> Descargar PNG</button>
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirCredenciales([nueva], p)}><MenuIcon name="file" size={15} /> Imprimir</button>
                  </div>
                </div>
              ) : (
                <div className="cq-mia-estado">
                  {c.credencial ? (
                    <p><span className="cv-estado votacion">Vigente</span> {numeroCredencial(c.credencial.id)} · generada el {fecha(c.credencial.fechaEmision)} · vence {fecha(c.credencial.fechaExpiracion)}</p>
                  ) : c.apto ? (
                    <p><span className="cv-estado creado">Sin generar</span> Aún no tiene esta credencial.</p>
                  ) : (
                    <p><span className="cv-estado anulado">No disponible</span> {c.motivo}</p>
                  )}
                  <p className="muted">{INDICACIONES[c.tipo]}</p>
                  {!p.admiteEmision && <p className="muted">{p.motivoNoAdmite}</p>}

                  {confirmar === k ? (
                    <div className="cq-confirmar-emision" role="alert">
                      <div>
                        <strong>¿Generar una nueva credencial?</strong>
                        <span>La credencial {numeroCredencial(c.credencial.id)} dejará de valer, incluso si ya la imprimió.</span>
                      </div>
                      <div className="cv-actions">
                        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmar(null)}>Cancelar</button>
                        <button type="button" className="cv-btn cv-btn-primary" disabled={saving === k} onClick={() => generar(p, c)}>Generar nueva</button>
                      </div>
                    </div>
                  ) : puede && (
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-primary" disabled={saving === k}
                        onClick={() => (c.credencial ? setConfirmar(k) : generar(p, c))}>
                        <MenuIcon name={c.credencial ? 'refresh' : 'qr'} size={15} />
                        {saving === k ? 'Generando…' : c.credencial ? 'Perdí mi QR: generar otro' : 'Generar mi credencial'}
                      </button>
                    </div>
                  )}
                </div>
              )}
            </section>
          );
        })}
      </div>
    </div>
  );
}
