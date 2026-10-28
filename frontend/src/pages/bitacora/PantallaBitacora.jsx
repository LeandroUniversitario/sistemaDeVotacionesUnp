import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { fecha } from '../credenciales/LectorQR';
import { ROL_CORTO } from '../administracion/ReporteAdministracion';
import {
  ANOMALIA, CRITICIDAD, ESTADO_CADENA, MODULO, claveLegible, imprimirRegistro, imprimirRegistros, imprimirVerificacion,
  navegador, pares, rolTexto, si, textoFiltros,
} from './ReporteBitacora';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import '../cierre/cierre.css';
import '../impugnaciones/impugnaciones.css';
import '../computo/computo.css';
import '../nulidades/nulidades.css';
import '../multas/multas.css';
import '../administracion/administracion.css';
import './bitacora.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS19 · Consultar bitácora — «PantallaBitacora» (boundary). Actor: Admin. Solo lectura.
 *
 * Mensajes del diagrama «Colaboration Consultar bitácora»:
 *   1 ingresarFiltros(usuario, accion, fecha_inicio, fecha_fin) → PantallaBitacora      (panel de filtros)
 *   2 buscarRegistros(filtros) ConsultarBitacora · 3 validarRolAdministrador(id) Usuario
 *   4 consultar(filtros) LogAuditoria · 5 mostrarRegistros(lista)                       (tabla paginada y resumen)
 *   6 seleccionarRegistro(id_log) → 7 obtenerDetalle(id_log) VerDetalleRegistro
 *   8 consultarDetalle(id_log) LogAuditoria · 9 mostrarDetalleJSON(detalle)             (ficha del registro)
 *
 * Además: verificación de la cadena de sellos SHA-256 (registros alterados, borrados o insertados por
 * fuera del sistema), exportación CSV con los mismos filtros y reportes impresos. Las exportaciones y
 * verificaciones quedan en la propia bitácora. Ningún registro se modifica ni se borra.
 */

const PASOS = [
  { codigo: 'REGISTROS', texto: 'Registros', nota: '1-9 buscarRegistros · mostrarDetalleJSON', icono: 'list' },
  { codigo: 'ANALISIS', texto: 'Resumen de actividad', nota: '5 mostrarRegistros · módulo, día, hora y usuario', icono: 'graph' },
  { codigo: 'INTEGRIDAD', texto: 'Integridad', nota: 'Sello SHA-256 encadenado', icono: 'shield' },
];
const FILTROS_VACIOS = {
  texto: '', idUsuario: '', rol: '', accion: '', modulo: [], criticidad: [], idProceso: '', idDocente: '', ip: '', desde: '', hasta: '',
};
const PERIODOS = [
  ['HOY', 'Hoy'], ['24H', 'Últimas 24 h'], ['7D', '7 días'], ['30D', '30 días'], ['TODO', 'Todo'],
];
const VISTAS = [
  { codigo: 'FALLIDOS', texto: 'Inicios de sesión fallidos', icono: 'lock', filtros: { accion: 'LOGIN_FAILED' } },
  { codigo: 'RELEVANTES', texto: 'Críticas y altas', icono: 'alert', filtros: { criticidad: ['ALTA', 'CRITICA'] } },
  { codigo: 'ADMIN', texto: 'Cambios de administración', icono: 'settings', filtros: { modulo: ['ADMINISTRACION'] } },
  { codigo: 'JORNADA', texto: 'Jornada electoral', icono: 'vote', filtros: { modulo: ['JORNADA'] } },
  { codigo: 'SISTEMA', texto: 'Sin cuenta (sistema o elector)', icono: 'person', filtros: { idUsuario: '0' } },
];
const TAMANOS = [25, 50, 100, 200];
const COLOR_ROL = { ADMIN: '#e11d48', CEUNP: '#2563eb', DOCENTE: '#059669', PERSONERO: '#d97706', MIEMBRO_MESA: '#7c3aed' };

const dosDigitos = (n) => String(n).padStart(2, '0');
const local = (d) => `${d.getFullYear()}-${dosDigitos(d.getMonth() + 1)}-${dosDigitos(d.getDate())}T${dosDigitos(d.getHours())}:${dosDigitos(d.getMinutes())}`;

function periodo(codigo) {
  const ahora = new Date();
  const inicioHoy = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
  switch (codigo) {
    case 'HOY': return { desde: local(inicioHoy), hasta: '' };
    case '24H': return { desde: local(new Date(ahora.getTime() - 86400000)), hasta: '' };
    case '7D': return { desde: local(new Date(inicioHoy.getTime() - 6 * 86400000)), hasta: '' };
    case '30D': return { desde: local(new Date(inicioHoy.getTime() - 29 * 86400000)), hasta: '' };
    default: return { desde: '', hasta: '' };
  }
}

/** Filtros de la pantalla como parámetros de la URL (solo los que tienen valor). */
function consultaUrl(f, extra = {}) {
  const q = new URLSearchParams();
  Object.entries(f).forEach(([k, v]) => {
    const valor = Array.isArray(v) ? v.join(',') : String(v ?? '').trim();
    if (valor) q.set(k, valor);
  });
  Object.entries(extra).forEach(([k, v]) => q.set(k, String(v)));
  return q.toString();
}

const contarFiltros = (f) => Object.entries(f).filter(([, v]) => (Array.isArray(v) ? v.length : String(v ?? '').trim())).length;

function Criticidad({ valor }) {
  const c = CRITICIDAD[valor] ?? CRITICIDAD.MEDIA;
  return <span className="bt-crit" style={{ '--bt-color': c.color }}>{c.texto}</span>;
}

function Modulo({ valor, caso }) {
  const m = MODULO[valor] ?? MODULO.SIN_CLASIFICAR;
  return <span className="bt-mod" style={{ '--bt-color': m.color }}>{m.corto}{caso ? ` · ${caso}` : ''}</span>;
}

export default function PantallaBitacora({ session, onSessionExpired }) {
  const [base, setBase] = useState(null);
  const [paso, setPaso] = useState('REGISTROS');
  const [cargando, setCargando] = useState(true);
  const [buscando, setBuscando] = useState(false);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);

  // 1 ingresarFiltros: borrador del formulario y filtros aplicados en la última búsqueda
  const [borrador, setBorrador] = useState(FILTROS_VACIOS);
  const [aplicados, setAplicados] = useState(FILTROS_VACIOS);
  const [masFiltros, setMasFiltros] = useState(false);
  const [pagina, setPagina] = useState(0);
  const [tamano, setTamano] = useState(25);
  const [orden, setOrden] = useState('DESC');
  const [resultado, setResultado] = useState(null);

  // 6-9 detalle del registro
  const [idLog, setIdLog] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [vistaJson, setVistaJson] = useState('LEGIBLE');

  // Integridad
  const [confirmando, setConfirmando] = useState(false);
  const [verificacion, setVerificacion] = useState(null);

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const cargarBase = useCallback(async () => {
    const d = await apiRequest('/api/bitacora');
    setBase(d);
    return d;
  }, []);

  useEffect(() => {
    (async () => {
      try {
        await cargarBase();
      } catch (e) {
        manejarError(e);
      } finally {
        setCargando(false);
      }
    })();
  }, [cargarBase, manejarError]);

  // 2 buscarRegistros(filtros) → 3 validarRolAdministrador → 4 consultar → 5 mostrarRegistros(lista)
  const buscar = useCallback(async () => {
    setBuscando(true);
    try {
      setResultado(await apiRequest(`/api/bitacora/registros?${consultaUrl(aplicados, { pagina, tamano, orden })}`));
    } catch (e) {
      manejarError(e);
    } finally {
      setBuscando(false);
    }
  }, [aplicados, pagina, tamano, orden, manejarError]);

  useEffect(() => {
    if (base) buscar();
  }, [base, buscar]);

  // 6 seleccionarRegistro(id_log) → 7 obtenerDetalle → 8 consultarDetalle → 9 mostrarDetalleJSON
  useEffect(() => {
    setDetalle(null);
    if (!idLog) return;
    (async () => {
      try {
        setDetalle(await apiRequest(`/api/bitacora/registros/${idLog}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idLog, manejarError]);

  function aplicar(nuevos) {
    setBorrador(nuevos);
    setAplicados(nuevos);
    setPagina(0);
    setFeedback(null);
  }

  /** Aplica un filtro sobre los datos de un registro o del resumen y vuelve a la tabla. */
  function filtrarPor(cambio) {
    aplicar({ ...FILTROS_VACIOS, ...cambio });
    setPaso('REGISTROS');
    setIdLog(null);
  }

  function alternar(campo, valor) {
    const actual = aplicados[campo];
    aplicar({ ...borrador, [campo]: actual.includes(valor) ? actual.filter((x) => x !== valor) : [...actual, valor] });
  }

  async function refrescar() {
    try {
      setFeedback(null);
      await cargarBase();
      await buscar();
    } catch (e) {
      manejarError(e);
    }
  }

  async function exportar() {
    setSaving(true);
    setFeedback(null);
    try {
      const token = sessionStorage.getItem('accessToken');
      const resp = await fetch(`/api/bitacora/exportacion?${consultaUrl(aplicados, { orden })}`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (resp.status === 401) throw new Error('SESSION_EXPIRED');
      if (!resp.ok) {
        let texto = 'No se pudo exportar la bitácora.';
        try { texto = (await resp.json()).detail ?? texto; } catch { /* sin cuerpo */ }
        throw new Error(texto);
      }
      const nombre = /filename="?([^";]+)"?/.exec(resp.headers.get('Content-Disposition') ?? '')?.[1] ?? 'bitacora.csv';
      const registros = resp.headers.get('X-Registros');
      const truncado = resp.headers.get('X-Truncado') === 'true';
      const url = URL.createObjectURL(await resp.blob());
      const a = document.createElement('a');
      a.href = url;
      a.download = nombre;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 2000);
      setFeedback({
        type: truncado ? 'error' : 'success',
        text: truncado
          ? `Se exportaron los primeros ${registros} registros (límite BITACORA_EXPORTACION_MAX). Acote los filtros para obtener el resto. La exportación quedó en la bitácora.`
          : `Se exportaron ${registros} registro(s) a ${nombre}. La exportación quedó en la bitácora.`,
      });
      await cargarBase();
    } catch (e) {
      manejarError(e);
    } finally {
      setSaving(false);
    }
  }

  async function verificar() {
    setSaving(true);
    setFeedback(null);
    try {
      const d = await apiRequest('/api/bitacora/verificacion', { method: 'POST', body: '{}' });
      setVerificacion(d.verificacion);
      setBase((b) => ({ ...b, cadena: d.cadena }));
      setFeedback({ type: d.verificacion.estado === 'ALTERADA' ? 'error' : 'success', text: d.mensaje });
      setConfirmando(false);
      buscar();
    } catch (e) {
      manejarError(e);
    } finally {
      setSaving(false);
    }
  }

  function descargarJson() {
    const x = detalle.registro;
    const contenido = JSON.stringify({
      idLog: x.idLog, fechaHora: x.fechaHora, accion: x.accion, usuario: x.username, rol: x.rol, idDocente: x.idDocente,
      idProceso: x.idProceso, ipOrigen: x.ipOrigen, userAgent: x.userAgent, detalle: detalle.detalle ?? x.detalleJson,
      hashAnterior: x.hashAnterior, hashRegistro: x.hashRegistro,
    }, null, 2);
    const url = URL.createObjectURL(new Blob([contenido], { type: 'application/json' }));
    const a = document.createElement('a');
    a.href = url;
    a.download = `registro_bitacora_${x.idLog}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  }

  const accionesPorModulo = useMemo(() => {
    const grupos = {};
    (base?.acciones ?? []).forEach((a) => { (grupos[a.modulo] ??= []).push(a); });
    return grupos;
  }, [base]);

  if (cargando) return <div className="panel"><p className="muted">Cargando la bitácora de auditoría…</p></div>;
  if (!base) {
    return (
      <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mu-shell ad-shell bt-shell mx">
        {feedback && <div className={`alert ${feedback.type}`} role="status">{feedback.text}</div>}
      </div>
    );
  }

  const { cadena, alertas } = base;
  const ultima = cadena.ultimaVerificacion;
  let ultimaDetalle = null;
  try { ultimaDetalle = ultima ? JSON.parse(ultima.detalleJson) : null; } catch { /* detalle no legible */ }
  const estadoCadena = verificacion?.estado ?? ultimaDetalle?.resultado ?? null;
  const resumen = resultado?.resumen;
  const relevantes = (resumen?.porCriticidad ?? []).filter((c) => ['ALTA', 'CRITICA'].includes(c.valor)).reduce((s, c) => s + Number(c.total), 0);
  const nFiltros = contarFiltros(aplicados);
  const filtrosTexto = textoFiltros(resultado?.filtros, base.acciones, base.usuarios, base.procesos);
  const periodoActivo = PERIODOS.find(([c]) => {
    const p = periodo(c);
    return c === 'TODO' ? !aplicados.desde && !aplicados.hasta : aplicados.desde === p.desde && !aplicados.hasta;
  })?.[0];

  return (
    <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mu-shell ad-shell bt-shell mx">
      <section className="in-head">
        <div className="ad-titulo">
          <span className="cv-label">Bitácora de auditoría · solo lectura</span>
          <strong>{session?.username ?? 'Admin'} · Administrador del sistema</strong>
        </div>
        <div className={`in-plazo ${estadoCadena === 'ALTERADA' ? 'closed' : 'open'}`}>
          <MenuIcon name={estadoCadena === 'ALTERADA' ? 'alert' : 'lock'} size={18} />
          <div>
            <strong>
              {estadoCadena ? `Cadena de sellos ${ESTADO_CADENA[estadoCadena]?.texto.toLowerCase() ?? estadoCadena}` : 'Cadena de sellos sin verificar'}
              {ultima && !verificacion ? ` · verificada ${fecha(ultima.fechaHora)}` : ''}
            </strong>
            <span>
              {Number(cadena.sello?.totalRegistros ?? 0).toLocaleString('es-PE')} registros sellados desde {fecha(cadena.sello?.fechaInicio)} ·
              {' '}Los registros no se modifican ni se borran; los votos nunca revelan la opción elegida (RNF05).
            </span>
          </div>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving || buscando}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      <div className="pd-tabs cq-tabs mx-pasos cp-pasos nl-pasos ad-pasos" role="tablist" aria-label="Consultar bitácora">
        {PASOS.map((p) => {
          const n = p.codigo === 'REGISTROS' ? resultado?.total : null;
          const alerta = p.codigo === 'INTEGRIDAD' && (estadoCadena === 'ALTERADA' || Number(cadena.sinSello) > 0);
          return (
            <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
              className={`pd-tab mx-paso${paso === p.codigo ? ' on' : ''}${alerta ? ' nl-alerta' : ''}`} onClick={() => { setPaso(p.codigo); setFeedback(null); }}>
              <span className="mx-paso-num"><MenuIcon name={p.icono} size={14} /></span>
              <span className="mx-paso-texto"><b>{p.texto}{n ? <em className="nl-cuenta">{Number(n).toLocaleString('es-PE')}</em> : null}</b><small>{p.nota}</small></span>
            </button>
          );
        })}
      </div>

      <section className="cq-resumen">
        <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
          <span>Registros <em>5 mostrarRegistros</em></span>
          <strong>{resultado ? Number(resultado.total).toLocaleString('es-PE') : '…'}<small> / {Number(cadena.sello?.totalRegistros ?? 0).toLocaleString('es-PE')}</small></strong>
          <small>{nFiltros ? `${nFiltros} filtro(s) aplicado(s)` : 'Toda la bitácora'}{resumen?.ultimo ? ` · último ${fecha(resumen.ultimo)}` : ''}</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': relevantes ? '#d97706' : '#059669' }}>
          <span>Críticas y altas <em>criticidad</em></span>
          <strong>{resumen ? relevantes.toLocaleString('es-PE') : '…'}</strong>
          <small>{resumen ? `${resumen.usuarios} cuenta(s) · ${resumen.sinCuenta ?? 0} sin cuenta` : 'En el resultado filtrado'}</small>
        </div>
        <button type="button" className={`cq-kpi${aplicados.accion === 'LOGIN_FAILED' ? ' on' : ''}`} style={{ '--cq-color': Number(alertas.fallidos) ? '#e11d48' : '#059669' }}
          onClick={() => filtrarPor({ accion: 'LOGIN_FAILED', ...periodo('24H') })} title="Ver los inicios de sesión fallidos de las últimas 24 horas">
          <span>Inicios fallidos <em>24 horas</em></span>
          <strong>{Number(alertas.fallidos ?? 0)}</strong>
          <small>{Number(alertas.ingresos ?? 0)} ingreso(s) correcto(s) · {Number(alertas.criticas ?? 0)} acción(es) crítica(s)</small>
        </button>
        <button type="button" className="cq-kpi" style={{ '--cq-color': estadoCadena === 'ALTERADA' ? '#e11d48' : estadoCadena === 'INTEGRA' ? '#059669' : '#d97706' }}
          onClick={() => setPaso('INTEGRIDAD')} title="Verificar la integridad de la bitácora">
          <span>Integridad <em>SHA-256</em></span>
          <strong className="cp-etapa">{estadoCadena ? ESTADO_CADENA[estadoCadena]?.texto ?? estadoCadena : 'Sin verificar'}</strong>
          <small>{ultima ? `${Number(ultima.registrosDespues ?? 0)} registro(s) nuevos desde la verificación` : 'Verifique la cadena de sellos'}</small>
        </button>
      </section>

      {feedback && <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>}

      {/* ── 1-9 Registros ── */}
      {paso === 'REGISTROS' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>1 ingresarFiltros · buscar en la bitácora</h3>
                <p className="muted">Combine usuario, acción y rango de fechas (2 buscarRegistros). Cada búsqueda vuelve a validar que su cuenta sea de administrador activo (3 validarRolAdministrador).</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost" disabled={saving || !resultado?.total} onClick={exportar}
                  title={`Hasta ${Number(base.exportacionMax).toLocaleString('es-PE')} registros con los filtros aplicados`}>
                  <MenuIcon name="download" size={15} /> {saving ? 'Exportando…' : 'Exportar CSV'}
                </button>
                <button type="button" className="cv-btn cv-btn-ghost" disabled={!resultado?.registros?.length}
                  onClick={() => imprimirRegistros(resultado, filtrosTexto, session?.username)}>
                  <MenuIcon name="file" size={15} /> Imprimir reporte
                </button>
              </div>
            </div>

            <div className="bt-vistas" role="group" aria-label="Vistas rápidas">
              {VISTAS.map((v) => (
                <button key={v.codigo} type="button" className="bt-vista" onClick={() => filtrarPor(v.filtros)}>
                  <MenuIcon name={v.icono} size={14} /> {v.texto}
                </button>
              ))}
            </div>

            <form className="ig-form" onSubmit={(e) => { e.preventDefault(); aplicar(borrador); }}>
              <div className="bt-filtros">
                <label className="cv-field bt-ancho2">
                  <span className="cv-label">Buscar</span>
                  <input value={borrador.texto} maxLength={120} placeholder="Acción, usuario, docente, DNI, proceso, IP, detalle o #N.º"
                    onChange={(e) => setBorrador((f) => ({ ...f, texto: e.target.value }))} />
                </label>
                <label className="cv-field">
                  <span className="cv-label">Usuario</span>
                  <select value={borrador.idUsuario} onChange={(e) => setBorrador((f) => ({ ...f, idUsuario: e.target.value }))}>
                    <option value="">Todas las cuentas</option>
                    <option value="0">Sin cuenta (sistema o elector)</option>
                    {base.usuarios.map((u) => (
                      <option key={u.idUsuario} value={u.idUsuario}>{u.username} · {ROL_CORTO[u.rol] ?? u.rol} ({u.total})</option>
                    ))}
                  </select>
                </label>
                <label className="cv-field">
                  <span className="cv-label">Acción</span>
                  <select value={borrador.accion} onChange={(e) => setBorrador((f) => ({ ...f, accion: e.target.value }))}>
                    <option value="">Todas las acciones</option>
                    {Object.keys(MODULO).filter((m) => accionesPorModulo[m]).map((m) => (
                      <optgroup key={m} label={MODULO[m].texto}>
                        {accionesPorModulo[m].map((a) => (
                          <option key={a.codigo} value={a.codigo}>{a.etiqueta}{Number(a.total) ? ` (${a.total})` : ''}</option>
                        ))}
                      </optgroup>
                    ))}
                  </select>
                </label>
                <label className="cv-field">
                  <span className="cv-label">Fecha inicial</span>
                  <input type="datetime-local" value={borrador.desde} max={borrador.hasta || undefined}
                    onChange={(e) => setBorrador((f) => ({ ...f, desde: e.target.value }))} />
                </label>
                <label className="cv-field">
                  <span className="cv-label">Fecha final</span>
                  <input type="datetime-local" value={borrador.hasta} min={borrador.desde || undefined}
                    onChange={(e) => setBorrador((f) => ({ ...f, hasta: e.target.value }))} />
                </label>
                {masFiltros && (
                  <>
                    <label className="cv-field">
                      <span className="cv-label">Rol de la cuenta</span>
                      <select value={borrador.rol} onChange={(e) => setBorrador((f) => ({ ...f, rol: e.target.value }))}>
                        <option value="">Todos los roles</option>
                        {['ADMIN', 'CEUNP', 'MIEMBRO_MESA', 'PERSONERO', 'DOCENTE'].map((r) => <option key={r} value={r}>{rolTexto(r)}</option>)}
                        <option value="SIN_CUENTA">Sin cuenta</option>
                      </select>
                    </label>
                    <label className="cv-field">
                      <span className="cv-label">Proceso electoral</span>
                      <select value={borrador.idProceso} onChange={(e) => setBorrador((f) => ({ ...f, idProceso: e.target.value }))}>
                        <option value="">Todos los procesos</option>
                        {base.procesos.map((p) => <option key={p.idProceso} value={p.idProceso}>{p.nombre} · {p.estado} ({p.total})</option>)}
                      </select>
                    </label>
                    <label className="cv-field">
                      <span className="cv-label">IP de origen</span>
                      <input value={borrador.ip} maxLength={45} placeholder="Ej.: 192.168.1." inputMode="decimal"
                        onChange={(e) => setBorrador((f) => ({ ...f, ip: e.target.value.replace(/[^0-9A-Fa-f:.]/g, '') }))} />
                    </label>
                    <label className="cv-field">
                      <span className="cv-label">N.º de docente referido</span>
                      <input value={borrador.idDocente} inputMode="numeric" placeholder="Desde el detalle de un registro"
                        onChange={(e) => setBorrador((f) => ({ ...f, idDocente: e.target.value.replace(/\D/g, '') }))} />
                    </label>
                  </>
                )}
              </div>

              <div className="bt-chips-fila">
                <span className="cv-label">Periodo</span>
                <div className="cq-chips" role="group" aria-label="Periodo">
                  {PERIODOS.map(([c, t]) => (
                    <button key={c} type="button" className={`cq-chip${periodoActivo === c ? ' on' : ''}`}
                      onClick={() => aplicar({ ...borrador, ...periodo(c) })}>{t}</button>
                  ))}
                </div>
              </div>
              <div className="bt-chips-fila">
                <span className="cv-label">Módulo</span>
                <div className="cq-chips" role="group" aria-label="Módulo">
                  {Object.entries(MODULO).filter(([m]) => m !== 'SIN_CLASIFICAR' || accionesPorModulo.SIN_CLASIFICAR).map(([m, d]) => (
                    <button key={m} type="button" className={`cq-chip bt-chip${aplicados.modulo.includes(m) ? ' on' : ''}`} style={{ '--bt-color': d.color }}
                      onClick={() => alternar('modulo', m)}>{d.corto}</button>
                  ))}
                </div>
              </div>
              <div className="bt-chips-fila">
                <span className="cv-label">Criticidad</span>
                <div className="cq-chips" role="group" aria-label="Criticidad">
                  {Object.entries(CRITICIDAD).map(([c, d]) => (
                    <button key={c} type="button" className={`cq-chip bt-chip${aplicados.criticidad.includes(c) ? ' on' : ''}`} style={{ '--bt-color': d.color }}
                      onClick={() => alternar('criticidad', c)} title={d.nota}>{d.texto}</button>
                  ))}
                </div>
              </div>

              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setMasFiltros((m) => !m)}>
                  <MenuIcon name="filter" size={15} /> {masFiltros ? 'Menos filtros' : 'Más filtros'}
                </button>
                <button type="button" className="cv-btn cv-btn-ghost" disabled={!nFiltros && !contarFiltros(borrador)} onClick={() => aplicar(FILTROS_VACIOS)}>
                  <MenuIcon name="close" size={15} /> Limpiar
                </button>
                <button type="submit" className="cv-btn cv-btn-primary" disabled={buscando}>
                  <MenuIcon name="search" size={15} /> {buscando ? 'Buscando…' : 'Buscar'}
                </button>
              </div>
            </form>
          </div>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>5 mostrarRegistros · {resultado ? `${Number(resultado.total).toLocaleString('es-PE')} registro(s)` : 'buscando…'}</h3>
                <p className="muted">{filtrosTexto} · elija un registro para ver su detalle (6 seleccionarRegistro).</p>
              </div>
              <div className="cs-acciones-head">
                <select className="ad-select" value={orden} onChange={(e) => { setOrden(e.target.value); setPagina(0); }} aria-label="Orden">
                  <option value="DESC">Más recientes primero</option>
                  <option value="ASC">Más antiguos primero</option>
                </select>
                <select className="ad-select" value={tamano} onChange={(e) => { setTamano(Number(e.target.value)); setPagina(0); }} aria-label="Registros por página">
                  {TAMANOS.map((t) => <option key={t} value={t}>{t} por página</option>)}
                </select>
              </div>
            </div>

            <div className={`table-wrap bt-tabla${buscando ? ' bt-cargando' : ''}`}>
              <table>
                <thead><tr><th className="n">N.º</th><th>Fecha y hora</th><th>Acción</th><th>Usuario</th><th>Referido a</th><th>IP / navegador</th><th /></tr></thead>
                <tbody>
                  {(resultado?.registros ?? []).map((x) => (
                    <tr key={x.idLog} className={`bt-fila${x.idLog === idLog ? ' ad-fila-on' : ''}`} onClick={() => setIdLog(x.idLog === idLog ? null : x.idLog)}>
                      <td className="n"><code>{x.idLog}</code></td>
                      <td className="bt-fecha">{fecha(x.fechaHora)}</td>
                      <td>
                        <strong>{x.etiqueta}</strong>
                        <small className="pd-sub bt-etiquetas"><Criticidad valor={x.criticidad} /><Modulo valor={x.modulo} caso={x.casoUso} />{!si(x.catalogada) && <code>{x.accion}</code>}</small>
                      </td>
                      <td>
                        {x.username
                          ? <><strong>{x.username}</strong><small className="pd-sub"><span className="ad-rol-pill" style={{ '--ad-color': COLOR_ROL[x.rol] ?? '#64748b' }}>{ROL_CORTO[x.rol] ?? x.rol}</span></small></>
                          : <span className="muted">Sin cuenta</span>}
                      </td>
                      <td>
                        {x.docente ? <>{x.docente}<small className="pd-sub">DNI {x.dniDocente}</small></> : null}
                        {x.proceso ? <small className="pd-sub">{x.proceso}</small> : null}
                        {!x.docente && !x.proceso && <span className="muted">—</span>}
                      </td>
                      <td>{x.ipOrigen ? <code>{x.ipOrigen}</code> : <span className="muted">—</span>}{x.userAgent && <small className="pd-sub">{navegador(x.userAgent)}</small>}</td>
                      <td className="n">
                        <button type="button" className="cv-btn cv-btn-soft" onClick={(e) => { e.stopPropagation(); setIdLog(x.idLog === idLog ? null : x.idLog); }}>
                          <MenuIcon name={x.idLog === idLog ? 'close' : 'eye'} size={14} /> {x.idLog === idLog ? 'Cerrar' : 'Ver'}
                        </button>
                      </td>
                    </tr>
                  ))}
                  {resultado && resultado.registros.length === 0 && (
                    <tr><td colSpan={7} className="bt-vacio">
                      <MenuIcon name="search" size={18} />
                      <div><strong>No se encontraron registros</strong><span>Ningún registro coincide con los filtros aplicados. Amplíe el periodo o quite filtros.</span></div>
                      {nFiltros > 0 && <button type="button" className="cv-btn cv-btn-ghost" onClick={() => aplicar(FILTROS_VACIOS)}>Quitar filtros</button>}
                    </td></tr>
                  )}
                </tbody>
              </table>
            </div>

            {resultado && resultado.paginas > 1 && (
              <div className="bt-paginas">
                <span className="muted">Registros {(resultado.pagina * resultado.tamano + 1).toLocaleString('es-PE')}–{Math.min((resultado.pagina + 1) * resultado.tamano, resultado.total).toLocaleString('es-PE')} de {Number(resultado.total).toLocaleString('es-PE')}</span>
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-ghost" disabled={resultado.pagina === 0 || buscando} onClick={() => setPagina(0)}>« Primera</button>
                  <button type="button" className="cv-btn cv-btn-ghost" disabled={resultado.pagina === 0 || buscando} onClick={() => setPagina(resultado.pagina - 1)}>‹ Anterior</button>
                  <span className="bt-pagina">Página {resultado.pagina + 1} de {resultado.paginas}</span>
                  <button type="button" className="cv-btn cv-btn-ghost" disabled={resultado.pagina >= resultado.paginas - 1 || buscando} onClick={() => setPagina(resultado.pagina + 1)}>Siguiente ›</button>
                  <button type="button" className="cv-btn cv-btn-ghost" disabled={resultado.pagina >= resultado.paginas - 1 || buscando} onClick={() => setPagina(resultado.paginas - 1)}>Última »</button>
                </div>
              </div>
            )}
          </div>

          {idLog && (
            <FichaRegistro
              d={detalle} idLog={idLog} vista={vistaJson} setVista={setVistaJson} admin={session?.username}
              onIr={setIdLog} onCerrar={() => setIdLog(null)} onFiltrar={filtrarPor} onDescargar={descargarJson}
            />
          )}
        </>
      )}

      {/* ── 5 Resumen de actividad ── */}
      {paso === 'ANALISIS' && (
        <Analisis resumen={resumen} alertas={alertas} filtrosTexto={filtrosTexto} nFiltros={nFiltros} onFiltrar={filtrarPor}
          onQuitar={() => aplicar(FILTROS_VACIOS)} />
      )}

      {/* ── Integridad: cadena de sellos SHA-256 ── */}
      {paso === 'INTEGRIDAD' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Integridad de la bitácora · sello SHA-256 encadenado</h3>
                <p className="muted">Al registrarse, cada acción guarda el SHA-256 de su contenido unido al sello del registro anterior. Verificar recalcula todos los sellos en orden: un registro modificado, eliminado o insertado por fuera del sistema rompe la cadena desde ese punto. La verificación queda en la bitácora.</p>
              </div>
            </div>
            <dl className="mx-datos cp-meta bt-sello">
              <div><dt>Registros sellados</dt><dd>{Number(cadena.sello?.totalRegistros ?? 0).toLocaleString('es-PE')}</dd></div>
              <div><dt>Último registro</dt><dd>{cadena.sello?.ultimoIdLog ? `N.º ${cadena.sello.ultimoIdLog}` : '—'}</dd></div>
              <div><dt>Inicio de la cadena</dt><dd>{fecha(cadena.sello?.fechaInicio)}</dd></div>
              <div><dt>Registros sin sello</dt><dd className={Number(cadena.sinSello) ? 'bt-mal' : ''}>{cadena.sinSello}</dd></div>
              <div className="bt-ancho4"><dt>Sello vigente</dt><dd><code className="ad-hash">{cadena.sello?.ultimoHash ?? '—'}</code></dd></div>
            </dl>
            {!confirmando ? (
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => setConfirmando(true)}>
                  <MenuIcon name="shield" size={15} /> Verificar integridad
                </button>
              </div>
            ) : (
              <div className="cq-confirmar-emision" role="alert">
                <div>
                  <strong>¿Verificar ahora los {Number(cadena.sello?.totalRegistros ?? 0).toLocaleString('es-PE')} registros de la bitácora?</strong>
                  <span>Se recalcula el sello de cada registro; con muchos registros puede tardar unos segundos. No modifica la bitácora: solo agrega el registro de la verificación.</span>
                </div>
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                  <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={verificar}>
                    <MenuIcon name="check" size={15} /> {saving ? 'Verificando…' : 'Confirmar'}
                  </button>
                </div>
              </div>
            )}

            {verificacion && (
              <div className={`bt-verificacion ${verificacion.estado === 'ALTERADA' ? 'mal' : 'ok'}`} role="status">
                <div className="bt-verificacion-head">
                  <div>
                    <h4>{verificacion.estado === 'INTEGRA' ? 'Bitácora íntegra' : verificacion.estado === 'VACIA' ? 'Bitácora vacía' : 'Bitácora alterada'}</h4>
                    <small>Verificación N.º {verificacion.idLog} · {fecha(verificacion.fecha)} · {verificacion.duracionMs} ms</small>
                  </div>
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirVerificacion(verificacion, cadena, session?.username)}>
                    <MenuIcon name="file" size={15} /> Imprimir constancia
                  </button>
                </div>
                <div className="mu-parametros">
                  <div><span>Registros</span><strong>{Number(verificacion.registros).toLocaleString('es-PE')}</strong><small>recalculados</small></div>
                  <div><span>Anomalías</span><strong>{verificacion.anomalias}</strong><small>{verificacion.primerIdAnomalo ? `desde el N.º ${verificacion.primerIdAnomalo}` : 'ninguna'}</small></div>
                  <div><span>Sello final</span><strong><code className="ad-hash">{verificacion.hashFinal ? `${verificacion.hashFinal.slice(0, 16)}…` : '—'}</code></strong><small>SHA-256</small></div>
                </div>
                {verificacion.detalle?.length > 0 && (
                  <div className="table-wrap">
                    <table>
                      <thead><tr><th className="n">Registro</th><th>Anomalía</th><th>Acción</th><th>Fecha</th><th>Explicación</th><th /></tr></thead>
                      <tbody>
                        {verificacion.detalle.map((a) => (
                          <tr key={`${a.idLog}-${a.tipo}`}>
                            <td className="n"><code>{a.idLog}</code></td>
                            <td><span className="cv-estado anulado">{ANOMALIA[a.tipo] ?? a.tipo}</span></td>
                            <td>{a.accion ?? '—'}</td>
                            <td>{fecha(a.fecha)}</td>
                            <td><small>{a.detalle}</small></td>
                            <td className="n">
                              {a.tipo !== 'FINAL_ELIMINADO' && (
                                <button type="button" className="cv-btn cv-btn-soft" onClick={() => { setPaso('REGISTROS'); setIdLog(a.idLog); }}>
                                  <MenuIcon name="eye" size={14} /> Ver
                                </button>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}
          </div>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Verificaciones anteriores</h3>
                <p className="muted">Cada verificación es también un registro de la bitácora (VERIFICAR_BITACORA).</p>
              </div>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th className="n">N.º</th><th>Fecha</th><th>Administrador</th><th>Resultado</th><th className="n">Registros</th><th>Primer anómalo</th></tr></thead>
                <tbody>
                  {cadena.verificaciones.map((v) => {
                    let d = {};
                    try { d = JSON.parse(v.detalleJson) ?? {}; } catch { /* sin detalle */ }
                    const e = ESTADO_CADENA[d.resultado];
                    return (
                      <tr key={v.idLog}>
                        <td className="n"><code>{v.idLog}</code></td>
                        <td>{fecha(v.fechaHora)}</td>
                        <td>{v.username ?? '—'}{v.ipOrigen && <small className="pd-sub">{v.ipOrigen}</small>}</td>
                        <td><span className={`cv-estado ${e?.clase ?? 'creado'}`}>{e?.texto ?? d.resultado ?? '—'}</span></td>
                        <td className="n">{d.registros ?? '—'}</td>
                        <td>{d.primer_registro_anomalo ?? '—'}</td>
                      </tr>
                    );
                  })}
                  {cadena.verificaciones.length === 0 && <tr><td colSpan={6} className="muted">Aún no se ha verificado la bitácora.</td></tr>}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

/** 6 seleccionarRegistro → 9 mostrarDetalleJSON: ficha del registro con su detalle, su sello y su contexto. */
function FichaRegistro({ d, idLog, vista, setVista, admin, onIr, onCerrar, onFiltrar, onDescargar }) {
  if (!d || d.registro.idLog !== idLog) {
    return <div className="panel cv-form ad-ficha"><p className="muted">7 obtenerDetalle · cargando el registro N.º {idLog}…</p></div>;
  }
  const x = d.registro;
  const selloOk = si(x.contenidoIntegro) && si(x.enlaceValido);
  const filas = d.detalle != null ? pares(d.detalle) : [];
  const textoJson = d.detalle != null ? JSON.stringify(d.detalle, null, 2) : (x.detalleJson ?? '');

  return (
    <div className="panel cv-form ad-ficha bt-ficha">
      <div className="cv-section-head">
        <div>
          <h3>9 mostrarDetalleJSON · registro N.º {x.idLog} <span className={`cv-estado ${selloOk ? 'votacion' : 'anulado'}`}>{selloOk ? 'Sello válido' : 'Sello no válido'}</span></h3>
          <p className="muted">{x.etiqueta} · {fecha(x.fechaHora)}{x.descripcionAccion ? ` · ${x.descripcionAccion}` : ''}</p>
        </div>
        <div className="cs-acciones-head">
          <button type="button" className="cv-btn cv-btn-ghost" disabled={!x.idAnterior} onClick={() => onIr(x.idAnterior)} title="Registro anterior de la cadena">‹ N.º {x.idAnterior ?? '—'}</button>
          <button type="button" className="cv-btn cv-btn-ghost" disabled={!x.idSiguiente} onClick={() => onIr(x.idSiguiente)} title="Registro siguiente de la cadena">N.º {x.idSiguiente ?? '—'} ›</button>
          <button type="button" className="cv-btn cv-btn-ghost" onClick={onCerrar}><MenuIcon name="close" size={15} /> Cerrar</button>
        </div>
      </div>

      <dl className="mx-datos cp-meta">
        <div><dt>Acción</dt><dd>{x.etiqueta}<small className="pd-sub"><code>{x.accion}</code></small></dd></div>
        <div><dt>Módulo y criticidad</dt><dd className="bt-etiquetas"><Modulo valor={x.modulo} caso={x.casoUso} /><Criticidad valor={x.criticidad} /></dd></div>
        <div><dt>Usuario</dt><dd>{x.username ? <>{x.username}<small className="pd-sub">{rolTexto(x.rol)}{x.usuarioDocente ? ` · ${x.usuarioDocente}` : ''}</small></> : 'Sin cuenta (sistema o elector)'}</dd></div>
        <div><dt>Fecha y hora</dt><dd>{fecha(x.fechaHora)}</dd></div>
        <div><dt>Docente referido</dt><dd>{x.docente ? <>{x.docente}<small className="pd-sub">DNI {x.dniDocente} · N.º {x.idDocente}</small></> : '—'}</dd></div>
        <div><dt>Proceso</dt><dd>{x.proceso ?? '—'}</dd></div>
        <div><dt>IP de origen</dt><dd>{x.ipOrigen ? <code>{x.ipOrigen}</code> : '—'}</dd></div>
        <div><dt>Navegador</dt><dd>{navegador(x.userAgent) ?? '—'}{x.userAgent && <small className="pd-sub bt-ua" title={x.userAgent}>{x.userAgent}</small>}</dd></div>
      </dl>

      {x.accion === 'EMITIR_VOTO' && (
        <div className="mx-mensaje info" role="note">
          <MenuIcon name="lock" size={18} />
          <div><h4>Secreto del voto (RNF05)</h4><p>El registro solo dice que el docente votó por el cargo; la opción elegida nunca se guarda en la bitácora.</p></div>
        </div>
      )}

      <div className="bt-json">
        <div className="bt-json-head">
          <h4>Detalle registrado <small>detalle_json</small></h4>
          <div className="cq-chips" role="group" aria-label="Vista del detalle">
            <button type="button" className={`cq-chip${vista === 'LEGIBLE' ? ' on' : ''}`} onClick={() => setVista('LEGIBLE')}>Legible</button>
            <button type="button" className={`cq-chip${vista === 'JSON' ? ' on' : ''}`} onClick={() => setVista('JSON')}>JSON</button>
          </div>
        </div>
        {!x.detalleJson ? <p className="muted">El registro no tiene detalle.</p>
          : !si(d.detalleValido) ? <pre className="bt-pre">{x.detalleJson}</pre>
            : vista === 'JSON' ? <pre className="bt-pre">{textoJson}</pre>
              : (
                <table className="bt-pares">
                  <tbody>{filas.map(([k, v]) => <tr key={k}><th>{claveLegible(k)}</th><td>{v == null || v === '' ? <span className="muted">—</span> : String(v)}</td></tr>)}</tbody>
                </table>
              )}
      </div>

      <div className="bt-hashes">
        <div><span>Sello anterior</span><code>{x.hashAnterior ?? '—'}</code><small className={si(x.enlaceValido) ? 'bt-bien' : 'bt-mal'}>{si(x.enlaceValido) ? '✓ enlazado al registro anterior' : '✗ no coincide con el registro anterior'}</small></div>
        <div><span>Sello del registro</span><code>{x.hashRegistro ?? '—'}</code><small className={si(x.contenidoIntegro) ? 'bt-bien' : 'bt-mal'}>{si(x.contenidoIntegro) ? '✓ el contenido no cambió' : `✗ recalculado: ${x.hashCalculado?.slice(0, 16)}…`}</small></div>
      </div>

      <div className="cv-actions cp-izq ad-botones">
        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => navigator.clipboard?.writeText(textoJson)} disabled={!x.detalleJson}><MenuIcon name="key" size={15} /> Copiar JSON</button>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={onDescargar}><MenuIcon name="download" size={15} /> Descargar JSON</button>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirRegistro(d, admin)}><MenuIcon name="file" size={15} /> Imprimir ficha</button>
        <button type="button" className="cv-btn cv-btn-soft" onClick={() => onFiltrar({ accion: x.accion })}><MenuIcon name="filter" size={14} /> Misma acción</button>
        {x.idUsuario != null && <button type="button" className="cv-btn cv-btn-soft" onClick={() => onFiltrar({ idUsuario: String(x.idUsuario) })}><MenuIcon name="user" size={14} /> Acciones de {x.username} ({x.accionesUsuario})</button>}
        {x.idProceso != null && <button type="button" className="cv-btn cv-btn-soft" onClick={() => onFiltrar({ idProceso: String(x.idProceso) })}><MenuIcon name="calendar" size={14} /> Mismo proceso ({x.accionesProceso})</button>}
        {x.idDocente != null && <button type="button" className="cv-btn cv-btn-soft" onClick={() => onFiltrar({ idDocente: String(x.idDocente) })}><MenuIcon name="person" size={14} /> Sobre el mismo docente</button>}
        {x.ipOrigen && <button type="button" className="cv-btn cv-btn-soft" onClick={() => onFiltrar({ ip: x.ipOrigen })}><MenuIcon name="search" size={14} /> Misma IP</button>}
      </div>

      <div className="ad-actividad">
        <div>
          <h4>{x.idUsuario != null ? `${x.username}: 30 minutos antes y después` : 'Registros vecinos de la cadena'}</h4>
          <ul>
            {d.contexto.map((c) => (
              <li key={c.idLog} style={{ borderLeftColor: CRITICIDAD[c.criticidad]?.color }}>
                <button type="button" className="bt-enlace" onClick={() => onIr(c.idLog)}>
                  <strong>N.º {c.idLog} · {c.etiqueta}</strong>
                  <small>{fecha(c.fechaHora)}{c.username && x.idUsuario == null ? ` · ${c.username}` : ''}{c.proceso ? ` · ${c.proceso}` : ''}</small>
                </button>
              </li>
            ))}
            {d.contexto.length === 0 && <li><small>Sin otras acciones en ese intervalo.</small></li>}
          </ul>
        </div>
        <div>
          <h4>Sobre el mismo docente</h4>
          <ul>
            {d.mismoDocente.map((c) => (
              <li key={c.idLog} style={{ borderLeftColor: CRITICIDAD[c.criticidad]?.color }}>
                <button type="button" className="bt-enlace" onClick={() => onIr(c.idLog)}>
                  <strong>N.º {c.idLog} · {c.etiqueta}</strong>
                  <small>{fecha(c.fechaHora)}{c.username ? ` · ${c.username}` : ''}{c.proceso ? ` · ${c.proceso}` : ''}</small>
                </button>
              </li>
            ))}
            {d.mismoDocente.length === 0 && <li><small>{x.idDocente ? 'Sin otros registros del docente.' : 'El registro no se refiere a un docente.'}</small></li>}
          </ul>
        </div>
      </div>
    </div>
  );
}

/** Barras horizontales con su total; al pulsar una, filtra los registros. */
function Barras({ filas, etiqueta, color, onClick }) {
  const max = Math.max(1, ...filas.map((f) => Number(f.total)));
  return (
    <ul className="bt-barras">
      {filas.map((f, i) => (
        <li key={i}>
          <button type="button" onClick={() => onClick?.(f)} disabled={!onClick}>
            <span className="bt-barra-texto">{etiqueta(f)}</span>
            <span className="bt-barra"><span style={{ width: `${(Number(f.total) / max) * 100}%`, background: color(f) }} /></span>
            <strong>{Number(f.total).toLocaleString('es-PE')}</strong>
          </button>
        </li>
      ))}
      {filas.length === 0 && <li className="muted">Sin datos.</li>}
    </ul>
  );
}

/** 5 mostrarRegistros: resumen del resultado filtrado (módulo, criticidad, acciones, cuentas, día y hora). */
function Analisis({ resumen, alertas, filtrosTexto, nFiltros, onFiltrar, onQuitar }) {
  if (!resumen) return <div className="panel"><p className="muted">Calculando el resumen…</p></div>;
  const dias = [...(resumen.porDia ?? [])].reverse();
  const maxDia = Math.max(1, ...dias.map((d) => Number(d.total)));
  const horas = Array.from({ length: 24 }, (_, h) => Number(resumen.porHora?.find((x) => Number(x.hora) === h)?.total ?? 0));
  const maxHora = Math.max(1, ...horas);
  const fueraHorario = horas.reduce((s, n, h) => s + (h < 7 || h >= 20 ? n : 0), 0);

  return (
    <>
      <div className="panel cv-form">
        <div className="cv-section-head">
          <div>
            <h3>Resumen de actividad · {Number(resumen.total).toLocaleString('es-PE')} registro(s)</h3>
            <p className="muted">{filtrosTexto}{resumen.primero ? ` · del ${fecha(resumen.primero)} al ${fecha(resumen.ultimo)}` : ''} · pulse una barra para ver esos registros.</p>
          </div>
          {nFiltros > 0 && <div className="cs-acciones-head"><button type="button" className="cv-btn cv-btn-ghost" onClick={onQuitar}><MenuIcon name="close" size={15} /> Ver toda la bitácora</button></div>}
        </div>
        <div className="mu-parametros bt-cifras">
          <div><span>Cuentas</span><strong>{resumen.usuarios}</strong><small>{resumen.sinCuenta ?? 0} registro(s) sin cuenta</small></div>
          <div><span>Procesos</span><strong>{resumen.procesos}</strong><small>con actividad</small></div>
          <div><span>IP distintas</span><strong>{resumen.ips}</strong><small>direcciones de origen</small></div>
          <div><span>Fuera de horario</span><strong>{fueraHorario}</strong><small>antes de 07:00 o desde 20:00</small></div>
        </div>
        <div className="bt-graficos">
          <div>
            <h4>Por módulo</h4>
            <Barras filas={resumen.porModulo} etiqueta={(f) => MODULO[f.valor]?.texto ?? f.valor} color={(f) => MODULO[f.valor]?.color ?? '#64748b'}
              onClick={(f) => onFiltrar({ modulo: [f.valor] })} />
          </div>
          <div>
            <h4>Por criticidad</h4>
            <Barras filas={[...resumen.porCriticidad].sort((a, b) => Object.keys(CRITICIDAD).indexOf(b.valor) - Object.keys(CRITICIDAD).indexOf(a.valor))}
              etiqueta={(f) => `${CRITICIDAD[f.valor]?.texto ?? f.valor} · ${CRITICIDAD[f.valor]?.nota ?? ''}`} color={(f) => CRITICIDAD[f.valor]?.color ?? '#64748b'}
              onClick={(f) => onFiltrar({ criticidad: [f.valor] })} />
          </div>
          <div>
            <h4>Acciones más frecuentes</h4>
            <Barras filas={resumen.topAcciones} etiqueta={(f) => f.etiqueta} color={(f) => CRITICIDAD[f.criticidad]?.color ?? '#2563eb'}
              onClick={(f) => onFiltrar({ accion: f.accion })} />
          </div>
          <div>
            <h4>Cuentas con más actividad</h4>
            <Barras filas={resumen.topUsuarios} etiqueta={(f) => `${f.username}${f.rol ? ` · ${ROL_CORTO[f.rol] ?? f.rol}` : ''}`}
              color={(f) => COLOR_ROL[f.rol] ?? '#64748b'} onClick={(f) => onFiltrar({ idUsuario: f.idUsuario == null ? '0' : String(f.idUsuario) })} />
          </div>
        </div>
      </div>

      <div className="panel cv-form">
        <div className="cv-section-head">
          <div>
            <h3>Actividad por día</h3>
            <p className="muted">Hasta 31 días con registros. Lo ámbar son acciones de criticidad alta o crítica.</p>
          </div>
        </div>
        <div className="bt-dias" role="img" aria-label="Registros por día">
          {dias.map((d) => (
            <button key={d.dia} type="button" className="bt-dia" title={`${d.dia}: ${d.total} registro(s), ${d.relevantes} alta(s) o crítica(s)`}
              onClick={() => onFiltrar({ desde: `${d.dia}T00:00`, hasta: `${d.dia}T23:59` })}>
              <span className="bt-dia-barra" style={{ height: `${(Number(d.total) / maxDia) * 100}%` }}>
                <span style={{ height: `${Number(d.total) ? (Number(d.relevantes) / Number(d.total)) * 100 : 0}%` }} />
              </span>
              <small>{String(d.dia).slice(8, 10)}/{String(d.dia).slice(5, 7)}</small>
              <b>{d.total}</b>
            </button>
          ))}
          {dias.length === 0 && <p className="muted">Sin registros.</p>}
        </div>
        <h4 className="bt-subtitulo">Actividad por hora del día</h4>
        <div className="bt-horas" role="img" aria-label="Registros por hora del día">
          {horas.map((n, h) => (
            <div key={h} className={`bt-hora${h < 7 || h >= 20 ? ' fuera' : ''}`} title={`${String(h).padStart(2, '0')}:00 · ${n} registro(s)`}>
              <span style={{ height: `${(n / maxHora) * 100}%` }} />
              <small>{h % 3 === 0 ? String(h).padStart(2, '0') : ''}</small>
            </div>
          ))}
        </div>
      </div>

      <div className="panel cv-form">
        <div className="cv-section-head">
          <div>
            <h3>Alertas de seguridad · últimas 24 horas</h3>
            <p className="muted">Independientes de los filtros. Al superar los intentos permitidos la cuenta se bloquea temporalmente (parámetros de seguridad del CUS18).</p>
          </div>
        </div>
        <div className="table-wrap">
          <table>
            <thead><tr><th>Cuenta</th><th className="n">Intentos fallidos</th><th className="n">IP distintas</th><th>Último intento</th><th>Situación</th><th /></tr></thead>
            <tbody>
              {alertas.cuentasConFallos.map((c) => (
                <tr key={c.idUsuario ?? 'x'}>
                  <td><strong>{c.username ?? 'Usuario inexistente'}</strong></td>
                  <td className="n">{c.fallidos}</td>
                  <td className="n">{c.ips}</td>
                  <td>{fecha(c.ultimo)}</td>
                  <td><span className={`cv-estado ${si(c.bloqueada) ? 'anulado' : 'creado'}`}>{si(c.bloqueada) ? 'Bloqueada' : 'Sin bloqueo'}</span></td>
                  <td className="n">
                    {c.idUsuario != null && (
                      <button type="button" className="cv-btn cv-btn-soft" onClick={() => onFiltrar({ idUsuario: String(c.idUsuario), accion: 'LOGIN_FAILED' })}>
                        <MenuIcon name="eye" size={14} /> Ver intentos
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {alertas.cuentasConFallos.length === 0 && <tr><td colSpan={6} className="muted">Sin inicios de sesión fallidos en las últimas 24 horas.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
