import { useCallback, useEffect, useRef, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { imprimirCedula } from './ImpresoraCedula';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import './votacion.css';

const BLANCO = 'BLANCO';
const CLAVE_TERMINAL = 'siceunp.terminalVotacion';

function leerTerminal() {
  try { return JSON.parse(localStorage.getItem(CLAVE_TERMINAL)) ?? null; } catch { return null; }
}
function guardarTerminal(valor) {
  try {
    if (valor) localStorage.setItem(CLAVE_TERMINAL, JSON.stringify(valor));
    else localStorage.removeItem(CLAVE_TERMINAL);
  } catch { /* sin almacenamiento: se vuelve a conectar al recargar */ }
}

function FotoCandidato({ lista }) {
  const [error, setError] = useState(false);
  const rector = lista.candidatos.find((c) => c.rolEnLista === 'RECTOR') ?? lista.candidatos[0];
  if (rector?.urlFoto && !error) {
    return <img className="vt-foto grande" src={rector.urlFoto} alt={`Candidato: ${rector.nombre}`} onError={() => setError(true)} />;
  }
  return <div className="vt-foto vt-foto-vacia grande" aria-hidden="true">{lista.simbolo ?? lista.nombre.charAt(0)}</div>;
}

/**
 * CUS10 · «TerminalVotacion» (equipo de la cabina). El docente NO inicia sesión: el equipo queda
 * abierto con la cuenta de la mesa y solo vota quien el Secretario habilitó (7 habilitarTerminal()).
 *   8 elegirOpcion() → 9 registrarVoto(opción) → 11 imprimirCedula(opción) → 12 confirmarImpresion()
 *   → 13 liberarTerminal(): la elección se borra de la memoria y el terminal vuelve a quedar libre.
 * El terminal nunca recibe ni envía datos del elector (RF69) y no conserva el voto (RNF07).
 */
export default function TerminalVotacion({ onSessionExpired }) {
  const [config, setConfig] = useState(leerTerminal);
  const [mesas, setMesas] = useState([]);
  const [formulario, setFormulario] = useState({ idMesa: '', nombre: 'Cabina 1' });
  const [estado, setEstado] = useState(null);
  const [habilitacion, setHabilitacion] = useState(null);   // memoria temporal: token y cédula
  const [marcas, setMarcas] = useState({});
  const [paso, setPaso] = useState('ESPERA');                 // ESPERA, ELEGIR, CONFIRMAR, IMPRESION
  const [impresion, setImpresion] = useState(null);           // cédula a imprimir (sin datos del elector)
  const [ocupado, setOcupado] = useState(false);
  const [error, setError] = useState('');
  const pasoRef = useRef(paso);
  pasoRef.current = paso;

  const fallo = useCallback((e) => {
    if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setError(e.message);
  }, [onSessionExpired]);

  useEffect(() => {
    if (config) return;
    apiRequest('/api/sufragio/mesas').then((data) => {
      setMesas(data);
      const instalada = data.find((m) => m.estado === 'INSTALADA') ?? data[0];
      if (instalada) setFormulario((f) => ({ ...f, idMesa: String(instalada.id) }));
    }).catch(fallo);
  }, [config, fallo]);

  const consultar = useCallback(async () => {
    if (!config || pasoRef.current !== 'ESPERA') return;
    try {
      const r = await apiRequest(`/api/sufragio/terminales/${config.idTerminal}`);
      setEstado(r);
      if (r.estado === 'HABILITADO' && r.token && pasoRef.current === 'ESPERA') {
        setHabilitacion({ idHabilitacion: r.idHabilitacion, token: r.token, cargos: r.cargos });
        setMarcas({});
        setError('');
        setPaso('ELEGIR');
      }
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') onSessionExpired?.();
      else setError(e.message);
    }
  }, [config, onSessionExpired]);

  // Mientras está libre, el terminal espera que la mesa lo habilite.
  useEffect(() => {
    if (!config || paso !== 'ESPERA') return undefined;
    consultar();
    const timer = setInterval(consultar, 3000);
    return () => clearInterval(timer);
  }, [config, paso, consultar]);

  async function conectar(event) {
    event.preventDefault();
    setOcupado(true);
    setError('');
    try {
      const r = await apiRequest('/api/sufragio/terminales', {
        method: 'POST', body: JSON.stringify({ idMesa: Number(formulario.idMesa), nombre: formulario.nombre }),
      });
      const nuevo = { idTerminal: r.terminal.id, nombre: r.terminal.nombre, mesa: r.mesa.numero };
      guardarTerminal(nuevo);
      setConfig(nuevo);
    } catch (e) {
      fallo(e);
    } finally {
      setOcupado(false);
    }
  }

  function desconectar() {
    guardarTerminal(null);
    setConfig(null);
    setEstado(null);
  }

  const cargos = habilitacion?.cargos ?? [];
  const marcados = cargos.filter((c) => marcas[c.idCargo]).length;

  function textoMarca(cargo) {
    const marca = marcas[cargo.idCargo];
    if (marca === BLANCO) return 'VOTO EN BLANCO';
    const lista = cargo.listas.find((l) => l.idLista === marca);
    return lista ? `${lista.ordenCedula ? `${lista.ordenCedula}. ` : ''}${lista.nombre}` : '—';
  }

  /** 9 registrarVoto(opción): la habilitación y la opción, sin datos del elector. */
  async function emitir() {
    setOcupado(true);
    setError('');
    try {
      const votos = cargos.map((c) => (marcas[c.idCargo] === BLANCO
        ? { cargoId: c.idCargo, tipo: 'BLANCO', listaId: null }
        : { cargoId: c.idCargo, tipo: 'VALIDO', listaId: marcas[c.idCargo] }));
      const r = await apiRequest(`/api/sufragio/terminales/${config.idTerminal}/voto`, {
        method: 'POST', body: JSON.stringify({ idHabilitacion: habilitacion.idHabilitacion, token: habilitacion.token, votos }),
      });
      setHabilitacion(null);       // la habilitación ya se consumió
      setMarcas({});
      setImpresion(r);             // memoria temporal hasta confirmar la impresión (A2)
      setPaso('IMPRESION');
      imprimirCedula(r);           // 11 imprimirCedula(opción)
    } catch (e) {
      if (e.message === 'SESSION_EXPIRED') { onSessionExpired?.(); return; }
      // A5: se revirtió todo; si la habilitación ya no vale, el terminal vuelve a esperar
      setError(`${e.message} No se registró ningún voto ni se imprimió cédula. Avise al Presidente de mesa.`);
      if (/habilitaci/i.test(e.message)) {
        setHabilitacion(null);
        setMarcas({});
        setPaso('ESPERA');
      } else {
        setPaso('ELEGIR');
      }
    } finally {
      setOcupado(false);
    }
  }

  /** 12 confirmarImpresion() → 13 liberarTerminal(): borra la elección de la memoria. */
  async function confirmarImpresion() {
    setOcupado(true);
    setImpresion(null);
    try {
      await apiRequest(`/api/sufragio/terminales/${config.idTerminal}/liberar`, { method: 'POST' });
    } catch (e) {
      fallo(e);
    } finally {
      setOcupado(false);
      setPaso('ESPERA');
    }
  }

  // ─── Configuración del equipo ──────────────────────────────────────────
  if (!config) {
    return (
      <div className="pd-shell vt-cabina">
        <form className="panel cv-form" onSubmit={conectar}>
          <div className="cv-section-head">
            <div>
              <h3>Conectar este equipo como terminal de votación</h3>
              <p className="muted">Hágalo en el equipo de la cabina. Luego el elector no inicia sesión: el Secretario lo habilita desde «Verificar elector».</p>
            </div>
          </div>
          {error && <div className="alert error">{error}</div>}
          <div className="vt-dni">
            <select value={formulario.idMesa} onChange={(e) => setFormulario({ ...formulario, idMesa: e.target.value })} aria-label="Mesa">
              {!mesas.length && <option value="">No tiene mesas asignadas</option>}
              {mesas.map((m) => <option key={m.id} value={m.id}>Mesa {m.numero} · {m.estado}</option>)}
            </select>
            <input value={formulario.nombre} maxLength={40} aria-label="Nombre del terminal"
              onChange={(e) => setFormulario({ ...formulario, nombre: e.target.value })} />
            <button type="submit" className="cv-btn cv-btn-primary" disabled={ocupado || !formulario.idMesa || !formulario.nombre.trim()}>
              <MenuIcon name="check" size={15} /> Conectar terminal
            </button>
          </div>
        </form>
      </div>
    );
  }

  const cabecera = (
    <div className="vt-proceso-head panel">
      <div>
        <h3>{config.nombre} · Mesa {config.mesa}</h3>
        <p className="muted">{estado?.mesa?.proceso ?? 'Terminal de votación'}</p>
      </div>
      {paso === 'ESPERA' && (
        <button type="button" className="cv-btn cv-btn-ghost vt-mini" onClick={desconectar}>Desconectar terminal</button>
      )}
    </div>
  );

  // ─── 11-13 Impresión de la cédula ───────────────────────────────────────
  if (paso === 'IMPRESION' && impresion) {
    return (
      <div className="pd-shell vt-cabina">
        {cabecera}
        <div className="panel cv-form vt-kiosco">
          <div className="vt-aviso ok"><MenuIcon name="check" size={20} /><div><strong>Su voto fue registrado.</strong>{impresion.mensaje}</div></div>
          <ul className="vt-resumen">
            {impresion.cedula.map((l) => <li key={l.cargo}><span>{l.cargo}</span><strong>{l.orden ? `${l.orden}. ` : ''}{l.opcion}</strong></li>)}
          </ul>
          <p className="muted">¿Salió bien impresa su cédula y coincide con su elección?</p>
          <div className="vt-pie">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirCedula(impresion)} disabled={ocupado}>
              <MenuIcon name="file" size={15} /> Reimprimir cédula
            </button>
            <button type="button" className="cv-btn cv-btn-success" onClick={confirmarImpresion} disabled={ocupado}>
              <MenuIcon name="check" size={16} /> Sí, retiré mi cédula
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─── Espera ─────────────────────────────────────────────────────────────
  if (paso === 'ESPERA') {
    const fuera = estado?.estado === 'FUERA_DE_SERVICIO';
    return (
      <div className="pd-shell vt-cabina">
        {cabecera}
        {error && <div className="alert error" role="alert" onClick={() => setError('')}>{error}</div>}
        <div className={`panel vt-espera${fuera ? ' fuera' : ''}`}>
          <MenuIcon name={fuera ? 'lock' : 'vote'} size={44} />
          <h2>{fuera ? 'Terminal fuera de servicio' : estado?.estado === 'EN_USO' ? 'Habilitación en uso' : 'Terminal libre'}</h2>
          <p>
            {fuera ? 'La mesa marcó este terminal como fuera de servicio.'
              : estado?.estado === 'EN_USO' ? estado.mensaje
                : estado?.motivoMesa ?? 'Acérquese a la mesa con su DNI y su pase QR. El Secretario habilitará este terminal para usted.'}
          </p>
        </div>
      </div>
    );
  }

  // ─── 8 elegirOpcion() y confirmación ─────────────────────────────────────
  return (
    <div className="pd-shell vt-cabina">
      {cabecera}
      {error && <div className="alert error" role="alert" onClick={() => setError('')}>{error}</div>}

      {paso === 'ELEGIR' && (
        <>
          <div className="vt-progreso">
            <span>Marcó {marcados} de {cargos.length} cargo(s)</span>
            <div className="vt-barra"><b style={{ width: `${cargos.length ? (marcados * 100) / cargos.length : 0}%` }} /></div>
          </div>
          {cargos.map((cargo) => (
            <section key={cargo.idCargo} className={`vt-cargo${marcas[cargo.idCargo] ? ' marcado' : ''}`} aria-label={cargo.cargo}>
              <div className="vt-cargo-head"><h4>{cargo.cargo}</h4><span>Marque una opción</span></div>
              <div className="vt-opciones" role="radiogroup" aria-label={`Opciones para ${cargo.cargo}`}>
                {cargo.listas.map((lista, i) => (
                  <button key={lista.idLista} type="button" role="radio" aria-checked={marcas[cargo.idCargo] === lista.idLista}
                    className={`vt-opcion${marcas[cargo.idCargo] === lista.idLista ? ' on' : ''}`}
                    onClick={() => setMarcas((m) => ({ ...m, [cargo.idCargo]: lista.idLista }))}>
                    <span className="vt-orden">{lista.ordenCedula ?? i + 1}</span>
                    {marcas[cargo.idCargo] === lista.idLista && <span className="vt-marca"><MenuIcon name="check" size={18} /></span>}
                    <div className="vt-opcion-cuerpo">
                      <FotoCandidato lista={lista} />
                      <div>
                        <strong>{lista.nombre}</strong>
                        {lista.simbolo && <small>Símbolo: {lista.simbolo}</small>}
                        {lista.candidatos.length > 0 && (
                          <ul>{lista.candidatos.map((c) => <li key={`${c.rolEnLista}-${c.nombre}`}><em>{c.rolEnLista.replaceAll('_', ' ').toLowerCase()}:</em> {c.nombre}</li>)}</ul>
                        )}
                      </div>
                    </div>
                  </button>
                ))}
                <button type="button" role="radio" aria-checked={marcas[cargo.idCargo] === BLANCO}
                  className={`vt-opcion blanco${marcas[cargo.idCargo] === BLANCO ? ' on' : ''}`}
                  onClick={() => setMarcas((m) => ({ ...m, [cargo.idCargo]: BLANCO }))}>
                  <span className="vt-orden">—</span>
                  {marcas[cargo.idCargo] === BLANCO && <span className="vt-marca"><MenuIcon name="check" size={18} /></span>}
                  <strong>Voto en blanco</strong>
                  <small>No elige ninguna lista para este cargo.</small>
                </button>
              </div>
            </section>
          ))}
          <div className="vt-pie">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setMarcas({})} disabled={!marcados}>Limpiar</button>
            <button type="button" className="cv-btn cv-btn-primary" onClick={() => setPaso('CONFIRMAR')} disabled={marcados < cargos.length}>
              Continuar
            </button>
          </div>
        </>
      )}

      {paso === 'CONFIRMAR' && (
        <div className="panel cv-form vt-kiosco">
          <div className="cv-section-head">
            <div>
              <h3>Confirme su elección</h3>
              <p className="muted">Puede corregirla ahora (A1). Una vez confirmada, es definitiva y se imprimirá su cédula.</p>
            </div>
          </div>
          <ul className="vt-resumen">
            {cargos.map((c) => <li key={c.idCargo}><span>{c.cargo}</span><strong>{textoMarca(c)}</strong></li>)}
          </ul>
          <div className="vt-pie">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setPaso('ELEGIR')} disabled={ocupado}>Corregir</button>
            <button type="button" className="cv-btn cv-btn-success" onClick={emitir} disabled={ocupado}>
              <MenuIcon name="vote" size={16} /> {ocupado ? 'Registrando…' : 'Confirmar voto'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
