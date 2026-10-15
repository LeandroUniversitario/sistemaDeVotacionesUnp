import { useCallback, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { EscanerQR, TIPOS_CREDENCIAL, fecha, numeroCredencial } from './LectorQR';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import './credenciales.css';

const RESULTADOS = {
  VALIDA: { clase: 'ok', titulo: 'Credencial válida', icono: 'check' },
  REVOCADA: { clase: 'mal', titulo: 'Credencial revocada', icono: 'close' },
  VENCIDA: { clase: 'mal', titulo: 'Credencial vencida', icono: 'close' },
  SIN_DERECHO: { clase: 'mal', titulo: 'El titular ya no tiene derecho', icono: 'alert' },
  NO_REGISTRADA: { clase: 'mal', titulo: 'Credencial no registrada', icono: 'alert' },
  FORMATO_INVALIDO: { clase: 'mal', titulo: 'No es una credencial', icono: 'alert' },
};

/**
 * CUS07 · Lectura de credenciales QR en la jornada (CEUNP y miembros de mesa).
 * Cada lectura se comprueba en el servidor y queda en la bitácora.
 */
export default function VerificarCredencialPanel({ onSessionExpired }) {
  const [verificando, setVerificando] = useState(false);
  const [resultado, setResultado] = useState(null);
  const [lecturas, setLecturas] = useState([]);
  const [error, setError] = useState('');

  const verificar = useCallback(async (codigo) => {
    setVerificando(true);
    setError('');
    try {
      const data = await apiRequest('/api/credenciales/verificar', { method: 'POST', body: JSON.stringify({ codigo }) });
      setResultado(data);
      setLecturas((prev) => [{ hora: new Date(), ...data }, ...prev].slice(0, 15));
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
      else setError(e.message);
    } finally {
      setVerificando(false);
    }
  }, [onSessionExpired]);

  const info = resultado ? RESULTADOS[resultado.resultado] ?? RESULTADOS.NO_REGISTRADA : null;
  const t = resultado?.titular;

  return (
    <div className="cq-verificar">
      <div className="panel cv-form">
        <div className="cv-section-head">
          <div>
            <h3>Verificar credencial QR</h3>
            <p className="muted">Lea el pase de votación, el fotocheck del miembro de mesa o la credencial del personero.</p>
          </div>
        </div>
        <EscanerQR onCodigo={verificar} deshabilitado={verificando} />
        {error && <div className="alert error" role="alert">{error}</div>}

        {resultado && (
          <div className={`cq-resultado ${info.clase}`} role="status" aria-live="polite">
            <div className="cq-resultado-head">
              <span className="cq-resultado-icono"><MenuIcon name={info.icono} size={22} /></span>
              <div>
                <strong>{info.titulo}</strong>
                <span>{resultado.mensaje}</span>
              </div>
            </div>
            {t && (
              <div className="cq-titular">
                <div className="in-avatar">{t.nombre.charAt(0)}</div>
                <div className="in-cand-body">
                  <strong>{t.nombre}</strong>
                  <span>DNI {t.dni} · {t.categoria} · {t.facultad ?? '—'}</span>
                  <span>{t.funcion}{t.numeroMesa ? ` · Mesa ${t.numeroMesa} (${t.ubicacion})` : t.ubicacion ? ` · ${t.ubicacion}` : ''}</span>
                </div>
              </div>
            )}
            {t?.observaciones?.length > 0 && (
              <ul className="cq-obs">{t.observaciones.map((o) => <li key={o}>{o}</li>)}</ul>
            )}
            {resultado.credencial && (
              <dl className="cq-meta">
                <div><dt>Tipo</dt><dd>{TIPOS_CREDENCIAL[resultado.credencial.tipo]?.titulo}</dd></div>
                <div><dt>Credencial</dt><dd>{numeroCredencial(resultado.credencial.id)}</dd></div>
                <div><dt>Proceso</dt><dd>{resultado.proceso?.nombre}</dd></div>
                <div><dt>Emitida</dt><dd>{fecha(resultado.credencial.fechaEmision)}</dd></div>
                <div><dt>Vence</dt><dd>{fecha(resultado.credencial.fechaExpiracion)}</dd></div>
                <div><dt>Lecturas válidas</dt><dd>{resultado.credencial.usos}</dd></div>
              </dl>
            )}
          </div>
        )}
      </div>

      {lecturas.length > 0 && (
        <div className="panel cv-form">
          <h3 className="cq-h3">Últimas lecturas de esta sesión</h3>
          <ul className="cq-lecturas">
            {lecturas.map((l, i) => (
              <li key={`${l.hora.getTime()}-${i}`} className={l.valida ? 'ok' : 'mal'}>
                <span>{l.hora.toLocaleTimeString('es-PE')}</span>
                <strong>{l.titular?.nombre ?? '—'}</strong>
                <em>{RESULTADOS[l.resultado]?.titulo ?? l.resultado}</em>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
