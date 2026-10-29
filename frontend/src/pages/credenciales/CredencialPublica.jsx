import { useEffect, useState } from 'react';
import MenuIcon from '../../components/MenuIcon';
import { TIPOS_CREDENCIAL, fecha, numeroCredencial } from './LectorQR';
import '../resultados/resultados.css';
import './credencial-publica.css';

/**
 * CUS07 · Página pública que abre el celular al escanear una credencial QR (sin inicio de sesión).
 *
 * Muestra quién es el titular (nombre, DNI parcial, facultad, categoría), su función en el proceso
 * (elector, cargo en la mesa o personero de una lista), la mesa y si la credencial sigue válida.
 * La consulta no cuenta como lectura en la jornada: eso lo hace el CEUNP o la mesa con el lector.
 */

const RESULTADOS = {
  VALIDA: { clase: 'ok', titulo: 'Credencial válida', icono: 'check' },
  REVOCADA: { clase: 'mal', titulo: 'Credencial revocada', icono: 'close' },
  VENCIDA: { clase: 'aviso', titulo: 'Credencial vencida', icono: 'alert' },
  SIN_DERECHO: { clase: 'mal', titulo: 'El titular ya no tiene derecho', icono: 'alert' },
  NO_REGISTRADA: { clase: 'mal', titulo: 'Credencial no registrada', icono: 'alert' },
  FORMATO_INVALIDO: { clase: 'mal', titulo: 'No es una credencial', icono: 'alert' },
};

const ESTADO_PROCESO = {
  CREADO: 'Convocado', INSCRIPCION: 'Inscripción de listas', VOTACION: 'Votación en curso',
  ESCRUTINIO: 'Escrutinio', CERRADO: 'Cerrado', ANULADO: 'Anulado',
};
const TIPO_PERSONERO = { GENERAL: 'General', ALTERNO: 'Alterno', MESA: 'De mesa' };
const capitalizar = (v) => (v ? String(v).charAt(0) + String(v).slice(1).toLowerCase() : v);

/** Filas «etiqueta: valor» según el tipo de credencial (solo las que tienen dato). */
function datosFuncion(tipo, t) {
  const filas = [];
  if (tipo === 'MIEMBRO_MESA') {
    filas.push(['Cargo en la mesa', t.funcion]);
  } else if (tipo === 'PERSONERO') {
    filas.push(['Función', `Personero ${TIPO_PERSONERO[t.tipoPersonero]?.toLowerCase() ?? ''}`.trim()]);
    filas.push(['Lista que representa', t.lista]);
    filas.push(['Cargo en elección', t.cargo]);
  } else {
    filas.push(['Función', t.funcion]);
  }
  filas.push([tipo === 'PERSONERO' && !t.numeroMesa ? 'Ámbito' : 'Mesa de sufragio',
    t.numeroMesa ? `Mesa ${t.numeroMesa}` : t.ubicacion]);
  if (t.numeroMesa && t.ubicacion) filas.push(['Local / ubicación', t.ubicacion]);
  return filas.filter(([, v]) => v);
}

export default function CredencialPublica() {
  const codigo = decodeURIComponent(window.location.pathname.slice('/credencial/'.length)).replace(/\/+$/, '');
  const [estado, setEstado] = useState({ cargando: true });

  useEffect(() => {
    let activo = true;
    fetch(`/api/publico/credenciales/${encodeURIComponent(codigo)}`)
      .then(async (r) => {
        const data = await r.json().catch(() => null);
        if (!r.ok) throw new Error(data?.detail || data?.message || 'No se pudo consultar la credencial.');
        return data;
      })
      .then((data) => activo && setEstado({ data }))
      .catch((e) => activo && setEstado({ error: e.message === 'Failed to fetch' ? 'No hay conexión con el servidor del sistema electoral.' : e.message }));
    return () => { activo = false; };
  }, [codigo]);

  const { cargando, error, data } = estado;
  const info = data ? RESULTADOS[data.resultado] ?? RESULTADOS.NO_REGISTRADA : null;
  const c = data?.credencial;
  const t = data?.titular;
  const tipo = c ? TIPOS_CREDENCIAL[c.tipo] : null;

  return (
    <div className="rs-portal">
      <header className="rs-portal-top">
        <img src="/escudo-unp.png" alt="Escudo UNP" />
        <div>
          <strong>SICEUNP · Verificación de credencial</strong>
          <span>Universidad Nacional de Piura · Comité Electoral (CEUNP)</span>
        </div>
      </header>

      <main className="cp-main">
        {cargando && <div className="cp-cargando"><div className="spinner" /> Verificando credencial…</div>}
        {error && (
          <div className="cp-estado mal" role="alert">
            <span className="cp-estado-icono"><MenuIcon name="alert" size={22} /></span>
            <div><strong>No se pudo verificar</strong><span>{error}</span></div>
          </div>
        )}

        {data && (
          <>
            <div className={`cp-estado ${info.clase}`} role="status">
              <span className="cp-estado-icono"><MenuIcon name={info.icono} size={22} /></span>
              <div><strong>{info.titulo}</strong><span>{data.mensaje}</span></div>
            </div>

            {t && (
              <article className="cp-tarjeta" style={{ '--cp-color': tipo?.color ?? '#2563eb' }}>
                <header>
                  <span>{tipo?.titulo ?? 'Credencial'}</span>
                  {c && <strong>{numeroCredencial(c.id)}</strong>}
                </header>
                <div className="cp-persona">
                  <div className="cp-avatar" aria-hidden="true">{t.nombre?.charAt(0)}</div>
                  <div>
                    <h1>{t.nombre}</h1>
                    <p>{[t.dni && `DNI ${t.dni}`, capitalizar(t.categoria)].filter(Boolean).join(' · ')}</p>
                    {t.facultad && <p>{t.facultad}</p>}
                  </div>
                </div>
                <dl className="cp-datos">
                  {datosFuncion(c?.tipo, t).map(([etiqueta, valor]) => (
                    <div key={etiqueta}><dt>{etiqueta}</dt><dd>{valor}</dd></div>
                  ))}
                </dl>
              </article>
            )}

            {c && (
              <section className="cp-panel">
                <h2>Datos de la credencial</h2>
                <dl className="cp-datos">
                  <div><dt>Proceso electoral</dt><dd>{data.proceso?.nombre}</dd></div>
                  <div><dt>Etapa del proceso</dt><dd>{ESTADO_PROCESO[data.proceso?.estado] ?? data.proceso?.estado}</dd></div>
                  <div><dt>Estado</dt><dd>{c.estado === 'VIGENTE' ? 'Vigente' : 'Revocada'}</dd></div>
                  <div><dt>Emitida</dt><dd>{fecha(c.fechaEmision)}</dd></div>
                  <div><dt>Vence</dt><dd>{fecha(c.fechaExpiracion)}</dd></div>
                  <div><dt>Número</dt><dd>{numeroCredencial(c.id)}</dd></div>
                </dl>
              </section>
            )}

            <p className="cp-nota">
              <MenuIcon name="shield" size={14} /> Datos consultados en línea al sistema electoral. Por privacidad el DNI se muestra
              parcialmente. Esta consulta no registra asistencia ni voto: el control en la mesa lo hace el personal electoral con su lector.
            </p>
          </>
        )}
      </main>
    </div>
  );
}
