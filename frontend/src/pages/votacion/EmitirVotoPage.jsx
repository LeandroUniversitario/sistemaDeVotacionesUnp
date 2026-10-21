import { useCallback, useEffect, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { CodigoQR, fecha, svgQR } from '../credenciales/LectorQR';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import './votacion.css';

const BLANCO = 'BLANCO';
const urlConstancia = (token) => `${window.location.origin}/api/publico/constancias/${token}`;
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

/** Minutos:segundos que le quedan a la autorización de cabina. */
function useCuentaRegresiva(hasta) {
  const [ahora, setAhora] = useState(() => Date.now());
  useEffect(() => {
    if (!hasta) return undefined;
    const timer = setInterval(() => setAhora(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [hasta]);
  if (!hasta) return null;
  return Math.max(0, Math.floor((new Date(hasta).getTime() - ahora) / 1000));
}

/**
 * CUS10 · Emitir voto («Cabina de votación»), según secuencia_emitir_voto.puml.
 *   iniciarVotacion → validarHabilitacion (cabina autorizada en CUS09) → mostrarOpciones →
 *   seleccionarLista (o blanco) → confirmar → registrarVoto → mostrarConstancia
 * El docente se toma de la sesión; la cédula nunca se guarda en el navegador.
 */
export default function EmitirVotoPage({ onSessionExpired }) {
  const [datos, setDatos] = useState(null);
  const [marcas, setMarcas] = useState({});
  const [paso, setPaso] = useState('CEDULA');
  const [resultado, setResultado] = useState(null);
  const [ocupado, setOcupado] = useState(false);
  const [error, setError] = useState('');

  const cargar = useCallback(async (silencioso = false) => {
    try {
      setDatos(await apiRequest('/api/sufragio/cedula'));
      if (!silencioso) setError('');
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
      else if (!silencioso) setError(e.message);
    }
  }, [onSessionExpired]);

  useEffect(() => { cargar(); }, [cargar]);

  const proceso = datos?.procesos?.find((p) => p.estado === 'HABILITADO')
    ?? datos?.procesos?.find((p) => p.estado === 'SIN_AUTORIZACION')
    ?? datos?.procesos?.[0];
  const esperando = paso === 'CEDULA' && proceso?.estado === 'SIN_AUTORIZACION';
  const restante = useCuentaRegresiva(proceso?.estado === 'HABILITADO' ? proceso.autorizacion?.fechaExpiracion : null);

  // Mientras espera que la mesa lo habilite, consulta cada 5 segundos.
  useEffect(() => {
    if (!esperando) return undefined;
    const timer = setInterval(() => cargar(true), 5000);
    return () => clearInterval(timer);
  }, [esperando, cargar]);

  // Si la autorización vence en la cabina, se descarta lo marcado.
  useEffect(() => {
    if (restante === 0 && paso !== 'CONSTANCIA') {
      setMarcas({});
      setPaso('CEDULA');
      setError('Venció el tiempo de su cabina. Vuelva a la mesa para que lo habiliten de nuevo.');
      cargar(true);
    }
  }, [restante, paso, cargar]);

  const cargos = proceso?.cargos ?? [];
  const marcados = cargos.filter((c) => marcas[c.idCargo]).length;

  function marcar(idCargo, opcion) {
    setMarcas((prev) => ({ ...prev, [idCargo]: opcion }));
  }

  function textoMarca(cargo) {
    const marca = marcas[cargo.idCargo];
    if (marca === BLANCO) return 'Voto en blanco';
    const lista = cargo.listas.find((l) => l.idLista === marca);
    return lista ? `${lista.ordenCedula ? `${lista.ordenCedula}. ` : ''}${lista.nombre}` : '—';
  }

  async function emitir() {
    setOcupado(true);
    setError('');
    try {
      const votos = cargos.map((c) => (marcas[c.idCargo] === BLANCO
        ? { cargoId: c.idCargo, tipo: 'BLANCO', listaId: null }
        : { cargoId: c.idCargo, tipo: 'VALIDO', listaId: marcas[c.idCargo] }));
      const r = await apiRequest('/api/sufragio/votar', {
        method: 'POST', body: JSON.stringify({ procesoId: proceso.idProceso, votos }),
      });
      setMarcas({});   // el sentido del voto no queda en pantalla
      setResultado(r);
      setPaso('CONSTANCIA');
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
      else {
        setError(e.message);
        setPaso('CEDULA');
        cargar(true);
      }
    } finally {
      setOcupado(false);
    }
  }

  function terminar() {
    setResultado(null);
    setPaso('CEDULA');
    cargar();
  }

  if (!datos) {
    return <div className="pd-shell vt-cabina">{error ? <div className="alert error">{error}</div> : <div className="spinner" />}</div>;
  }

  if (paso === 'CONSTANCIA' && resultado) {
    return (
      <div className="pd-shell vt-cabina">
        {resultado.error
          ? <div className="vt-aviso"><MenuIcon name="alert" size={18} /><div>{resultado.error}</div></div>
          : <div className="vt-aviso ok"><MenuIcon name="check" size={18} /><div><strong>{resultado.mensaje}</strong>Ya puede salir de la cabina.</div></div>}
        <Constancia constancia={resultado.constancia} />
        <div className="vt-pie">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirConstancia(resultado.constancia)}>
            <MenuIcon name="file" size={15} /> Imprimir constancia
          </button>
          <button type="button" className="cv-btn cv-btn-primary" onClick={terminar}>Terminar</button>
        </div>
      </div>
    );
  }

  return (
    <div className="pd-shell vt-cabina">
      {error && <div className="alert error" role="alert" onClick={() => setError('')}>{error}</div>}

      {!proceso && (
        <div className="vt-aviso info">
          <MenuIcon name="calendar" size={18} />
          <div><strong>No hay elecciones en curso.</strong>Cuando un proceso en el que figura pase a VOTACION, aquí aparecerá su cédula.</div>
        </div>
      )}

      {proceso && (
        <div className="panel cv-form">
          <div className="vt-proceso-head">
            <div>
              <h3>{proceso.proceso}</h3>
              <p className="muted">
                {datos.elector.nombre} · DNI {datos.elector.dni}
                {proceso.mesa && ` · Mesa ${proceso.mesa.numero} (${proceso.mesa.ubicacion})`}
              </p>
            </div>
            {restante != null && (
              <span className={`vt-reloj${restante < 120 ? ' poco' : ''}`} aria-live="polite">
                <MenuIcon name="lock" size={14} /> {Math.floor(restante / 60)}:{String(restante % 60).padStart(2, '0')}
              </span>
            )}
          </div>
          {proceso.estado !== 'HABILITADO' && (
            <div className={`vt-aviso ${proceso.estado === 'VOTO' ? 'ok' : proceso.estado === 'SIN_AUTORIZACION' ? 'info' : ''}`}>
              <MenuIcon name={proceso.estado === 'VOTO' ? 'check' : proceso.estado === 'SIN_AUTORIZACION' ? 'scan' : 'alert'} size={18} />
              <div>
                <strong>{{ VOTO: 'Ya votó', SIN_AUTORIZACION: 'Cabina no habilitada', SIN_MESA: 'Sin mesa', INHABILITADO: 'No habilitado' }[proceso.estado]}</strong>
                {proceso.mensaje}
                {proceso.estado === 'SIN_AUTORIZACION' && ' Esta pantalla se actualizará sola.'}
              </div>
            </div>
          )}
          {proceso.cargosVotados?.length > 0 && (
            <p className="muted">Cargos ya votados: {proceso.cargosVotados.map((c) => c.cargo).join(', ')}.</p>
          )}
          {proceso.estado === 'SIN_AUTORIZACION' && (
            <div><button type="button" className="cv-btn cv-btn-ghost" onClick={() => cargar()}>Ya me habilitaron, actualizar</button></div>
          )}
        </div>
      )}

      {proceso?.estado === 'HABILITADO' && paso === 'CEDULA' && (
        <>
          <div className="vt-progreso">
            <span>Marcó {marcados} de {cargos.length} cargo(s)</span>
            <div className="vt-barra"><b style={{ width: `${cargos.length ? (marcados * 100) / cargos.length : 0}%` }} /></div>
          </div>
          {cargos.map((cargo) => (
            <section key={cargo.idCargo} className={`vt-cargo${marcas[cargo.idCargo] ? ' marcado' : ''}`} aria-label={cargo.cargo}>
              <div className="vt-cargo-head">
                <h4>{cargo.cargo}</h4>
                <span>Marque una opción</span>
              </div>
              <div className="vt-opciones" role="radiogroup" aria-label={`Opciones para ${cargo.cargo}`}>
                {cargo.listas.map((lista, i) => (
                  <button key={lista.idLista} type="button" role="radio" aria-checked={marcas[cargo.idCargo] === lista.idLista}
                    className={`vt-opcion${marcas[cargo.idCargo] === lista.idLista ? ' on' : ''}`}
                    onClick={() => marcar(cargo.idCargo, lista.idLista)}>
                    <span className="vt-orden">{lista.ordenCedula ?? i + 1}</span>
                    {marcas[cargo.idCargo] === lista.idLista && <span className="vt-marca"><MenuIcon name="check" size={18} /></span>}
                    <strong>{lista.nombre}</strong>
                    {lista.simbolo && <small>Símbolo: {lista.simbolo}</small>}
                    {lista.candidatos.length > 0 && (
                      <ul>{lista.candidatos.map((c) => <li key={`${c.rolEnLista}-${c.nombre}`}><em>{c.rolEnLista}:</em> {c.nombre}</li>)}</ul>
                    )}
                  </button>
                ))}
                <button type="button" role="radio" aria-checked={marcas[cargo.idCargo] === BLANCO}
                  className={`vt-opcion blanco${marcas[cargo.idCargo] === BLANCO ? ' on' : ''}`}
                  onClick={() => marcar(cargo.idCargo, BLANCO)}>
                  <span className="vt-orden">—</span>
                  {marcas[cargo.idCargo] === BLANCO && <span className="vt-marca"><MenuIcon name="check" size={18} /></span>}
                  <strong>Voto en blanco</strong>
                  <small>No elige ninguna lista para este cargo.</small>
                </button>
              </div>
              {!cargo.listas.length && <p className="muted">No hay listas admitidas para este cargo: solo puede votar en blanco.</p>}
            </section>
          ))}
          <div className="vt-pie">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setMarcas({})} disabled={!marcados}>Limpiar cédula</button>
            <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('CONFIRMAR')} disabled={marcados < cargos.length}>
              Revisar mi voto
            </button>
          </div>
        </>
      )}

      {proceso?.estado === 'HABILITADO' && paso === 'CONFIRMAR' && (
        <div className="panel cv-form">
          <div className="cv-section-head">
            <div>
              <h3>Confirme su voto</h3>
              <p className="muted">Una vez emitido no se puede cambiar (RN26). Nadie podrá saber por quién votó.</p>
            </div>
          </div>
          <ul className="vt-resumen">
            {cargos.map((c) => <li key={c.idCargo}><span>{c.cargo}</span><strong>{textoMarca(c)}</strong></li>)}
          </ul>
          <div className="vt-pie">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setPaso('CEDULA')} disabled={ocupado}>Corregir</button>
            <button type="button" className="cv-btn cv-btn-success" onClick={emitir} disabled={ocupado}>
              <MenuIcon name="vote" size={16} /> {ocupado ? 'Registrando…' : 'Confirmar y emitir voto'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

/** mostrarConstancia: prueba que el docente votó; no dice por quién. */
function Constancia({ constancia }) {
  return (
    <article className="vt-constancia">
      <header>
        <span>Universidad Nacional de Piura · Comité Electoral (CEUNP)</span>
        <strong>Constancia de sufragio</strong>
      </header>
      <dl>
        <div><dt>Proceso</dt><dd>{constancia.proceso}</dd></div>
        <div><dt>Elector</dt><dd>{constancia.elector.nombre}</dd></div>
        <div><dt>DNI</dt><dd>{constancia.elector.dni}</dd></div>
        <div><dt>Mesa</dt><dd>{constancia.mesa.numero} · {constancia.mesa.ubicacion}</dd></div>
        <div><dt>Emitida</dt><dd>{fecha(constancia.fechaEmision)}</dd></div>
      </dl>
      <div className="vt-qrs">
        {constancia.cargos.map((c) => (
          <div key={c.idCargo} className="vt-qr">
            <strong>{c.cargo}</strong>
            <CodigoQR valor={urlConstancia(c.token)} size={140} titulo={`Constancia de ${c.cargo}`} />
            <code>{c.token.slice(0, 16)}…</code>
          </div>
        ))}
      </div>
      <p className="vt-nota">Cada código QR verifica en línea la participación por ese cargo. El código solo se muestra ahora: imprímalo o guárdelo.</p>
    </article>
  );
}

function imprimirConstancia(constancia) {
  const ventana = window.open('', '_blank', 'width=820,height=900');
  if (!ventana) return;
  const qrs = constancia.cargos.map((c) => `
    <div class="qr"><strong>${esc(c.cargo)}</strong>${svgQR(urlConstancia(c.token), { title: `Constancia de ${c.cargo}` })}
    <code>${esc(c.token)}</code></div>`).join('');
  ventana.document.write(`<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Constancia de sufragio</title>
    <style>
      body { font-family: system-ui, sans-serif; color: #0f172a; margin: 32px; }
      h1 { font-size: 18px; margin: 0; } header { text-align: center; border-bottom: 2px solid #059669; padding-bottom: 10px; }
      dl { display: grid; grid-template-columns: 140px 1fr; gap: 6px 12px; margin: 18px 0; } dt { font-weight: 700; } dd { margin: 0; }
      .qrs { display: flex; flex-wrap: wrap; gap: 16px; } .qr { display: grid; justify-items: center; gap: 6px; width: 200px; text-align: center; }
      .qr svg { width: 160px; height: 160px; } code { font-size: 9px; word-break: break-all; } p { font-size: 12px; color: #475569; }
    </style></head><body>
    <header><span>Universidad Nacional de Piura · CEUNP</span><h1>Constancia de sufragio</h1></header>
    <dl><dt>Proceso</dt><dd>${esc(constancia.proceso)}</dd><dt>Elector</dt><dd>${esc(constancia.elector.nombre)}</dd>
    <dt>DNI</dt><dd>${esc(constancia.elector.dni)}</dd><dt>Mesa</dt><dd>${esc(constancia.mesa.numero)} · ${esc(constancia.mesa.ubicacion)}</dd>
    <dt>Emitida</dt><dd>${esc(fecha(constancia.fechaEmision))}</dd></dl>
    <div class="qrs">${qrs}</div>
    <p>Esta constancia acredita la participación del docente en el sufragio. No revela el sentido del voto.</p>
    <script>window.onload = () => window.print();</script></body></html>`);
  ventana.document.close();
}
