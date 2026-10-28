import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../../api/apiClient';
import MenuIcon from '../../components/MenuIcon';
import { fecha } from '../credenciales/LectorQR';
import {
  GRUPO, ORIGEN, ROL, ROL_CORTO, ROL_NOTA, ROLES_CON_DOCENTE, bytes, hora, valorLegible,
  imprimirConstanciaRespaldo, imprimirFichaAcceso, imprimirParametros,
} from './ReporteAdministracion';
import '../convocatoria/convocatoria.css';
import '../padron/padron.css';
import '../inscripcion/inscripcion.css';
import '../credenciales/credenciales.css';
import '../instalacion/instalacion.css';
import '../cierre/cierre.css';
import '../impugnaciones/impugnaciones.css';
import '../computo/computo.css';
import '../nulidades/nulidades.css';
import '../multas/multas.css';
import './administracion.css';
import '../mesa/mesa-ejecutivo.css';

/**
 * CUS18 · Administrar usuarios y parámetros — «PantallaAdministrador» (boundary). Actor: Admin.
 *
 * Mensajes del diagrama «colaboration Administrar usuarios y parámetros»:
 *   1 ingresarUsuario() → PantallaAdministrador · 1.1 crearUsuario() GestionarUsuarios     (pestaña Cuentas y roles)
 *   2 verificarDocente() docente · 3 insertarUsuario() Usuario · 4 mostrarUsuario()
 *   5 modificarParametro() → 6 actualizar() actualizarParametros                           (pestaña Parámetros)
 *   7 actualizarParametro() ParametroGlobal · 8 registrarAuditoria() LogAuditoria · 9 confirmarCambio()
 *   10 solicitarRespaldo() → 11 generarRespaldo() respaldarBD                               (pestaña Respaldo)
 *   12 registrarAuditoria() LogAuditoria · 13 mostrarRespaldo()
 *
 * Reglas: siempre queda un administrador activo; las cuentas DOCENTE, PERSONERO y MIEMBRO_MESA se
 * asocian a un docente activo del padrón, una por rol; la cuenta con actividad no se elimina, se
 * desactiva (RN28); toda contraseña asignada por el Admin es provisional. Los parámetros se validan
 * por tipo y rango, los de la jornada no cambian con un proceso en votación y todo cambio exige motivo.
 */

const ROLES = ['ADMIN', 'CEUNP', 'MIEMBRO_MESA', 'PERSONERO', 'DOCENTE'];
const COLOR_ROL = { ADMIN: '#e11d48', CEUNP: '#2563eb', DOCENTE: '#059669', PERSONERO: '#d97706', MIEMBRO_MESA: '#7c3aed' };
const SUFIJO_ROL = { ADMIN: '.admin', CEUNP: '.ceunp', DOCENTE: '', PERSONERO: '.personero', MIEMBRO_MESA: '.mesa' };
const PASOS = [
  { codigo: 'USUARIOS', texto: 'Cuentas y roles', nota: '1-4 crearUsuario · verificarDocente', icono: 'users' },
  { codigo: 'PARAMETROS', texto: 'Parámetros', nota: '5-9 actualizarParametro · historial', icono: 'settings' },
  { codigo: 'RESPALDO', texto: 'Respaldo de la base', nota: '10-13 generarRespaldo · huella', icono: 'download' },
];
const ESTADOS = [
  ['TODAS', 'Todas'], ['ACTIVAS', 'Activas'], ['INACTIVAS', 'Inactivas'], ['BLOQUEADAS', 'Bloqueadas'], ['PROVISIONAL', 'Clave provisional'],
];
const ACCION_BITACORA = {
  CREAR_USUARIO: 'Cuenta creada', ACTUALIZAR_USUARIO: 'Rol o docente modificado', ACTIVAR_USUARIO: 'Cuenta activada',
  DESACTIVAR_USUARIO: 'Cuenta desactivada', RESTABLECER_PASSWORD: 'Contraseña restablecida', DESBLOQUEAR_USUARIO: 'Cuenta desbloqueada',
  LOGIN_SUCCESS: 'Inicio de sesión', LOGIN_FAILED: 'Intento fallido de inicio de sesión',
};
const si = (v) => v === true || v === 1 || v === '1';
const nuevoVacio = { rol: 'DOCENTE', username: '', modoClave: 'GENERAR', password: '' };

function sinTildes(t) {
  return String(t ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

/** Usuario sugerido: inicial del nombre y primer apellido, con el sufijo del rol y un número si ya existe. */
function sugerirUsuario(docente, rol, usuarios) {
  if (!docente) return '';
  const base = `${sinTildes(docente.nombres).charAt(0)}${sinTildes(String(docente.apellidos ?? '').split(/\s+/).slice(0, 2).join(''))}` || 'usuario';
  const existentes = new Set(usuarios.map((u) => u.username.toLowerCase()));
  let candidato = `${base}${SUFIJO_ROL[rol] ?? ''}`;
  for (let n = 2; existentes.has(candidato); n++) candidato = `${base}${SUFIJO_ROL[rol] ?? ''}${n}`;
  return candidato.slice(0, 80);
}

function situacion(u) {
  if (!si(u.activo)) return { clase: 'anulado', texto: 'Inactiva' };
  if (si(u.bloqueada)) return { clase: 'anulado', texto: 'Bloqueada' };
  if (si(u.debeCambiarPassword)) return { clase: 'creado', texto: 'Clave provisional' };
  return { clase: 'votacion', texto: 'Activa' };
}

export default function PantallaAdministrador({ session, onSessionExpired }) {
  const [detalle, setDetalle] = useState(null);
  const [paso, setPaso] = useState('USUARIOS');
  const [cargando, setCargando] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [accion, setAccion] = useState(null);      // NUEVO | EDITAR | CLAVE | DESBLOQUEAR | DESACTIVAR | ACTIVAR | ELIMINAR | PARAMETRO | RESTAURAR | RESPALDO
  const [confirmando, setConfirmando] = useState(false);

  // Cuentas
  const [filtro, setFiltro] = useState({ rol: 'TODOS', estado: 'TODAS', texto: '' });
  const [idUsuario, setIdUsuario] = useState(null);
  const [actividad, setActividad] = useState(null);
  const [nuevo, setNuevo] = useState(nuevoVacio);
  const [docente, setDocente] = useState(null);
  const [verificacion, setVerificacion] = useState(null);
  const [edicion, setEdicion] = useState({ rol: '', docente: null, verificacion: null });
  const [motivoEstado, setMotivoEstado] = useState('');
  const [clave, setClave] = useState({ modo: 'GENERAR', password: '' });
  const [entregada, setEntregada] = useState(null);   // { usuario, clave }: 4 mostrarUsuario, se muestra una sola vez

  // Parámetros
  const [claveParam, setClaveParam] = useState(null);
  const [cambio, setCambio] = useState({ valor: '', motivo: '' });
  const [restauracion, setRestauracion] = useState({ idHistorial: null, motivo: '' });
  const [filtroHistorial, setFiltroHistorial] = useState('TODOS');
  const [historialParam, setHistorialParam] = useState(null);
  const [confirmacion, setConfirmacion] = useState(null);

  // Respaldos
  const [motivoRespaldo, setMotivoRespaldo] = useState('');
  const [verificaciones, setVerificaciones] = useState({});
  const [ultimoRespaldo, setUltimoRespaldo] = useState(null);

  const manejarError = useCallback((error) => {
    if (error.message === 'SESSION_EXPIRED') onSessionExpired?.();
    else setFeedback({ type: 'error', text: error.message });
  }, [onSessionExpired]);

  const cargar = useCallback(async () => {
    const d = await apiRequest('/api/administracion');
    setDetalle(d);
    return d;
  }, []);

  useEffect(() => {
    (async () => {
      try {
        await cargar();
      } catch (e) {
        manejarError(e);
      } finally {
        setCargando(false);
      }
    })();
  }, [cargar, manejarError]);

  // Actividad de la cuenta abierta (bitácora)
  useEffect(() => {
    setActividad(null);
    if (!idUsuario) return;
    (async () => {
      try {
        setActividad(await apiRequest(`/api/administracion/usuarios/${idUsuario}/actividad`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [idUsuario, detalle?.usuarios, manejarError]);

  // Historial completo del parámetro abierto
  useEffect(() => {
    setHistorialParam(null);
    if (!claveParam) return;
    (async () => {
      try {
        setHistorialParam(await apiRequest(`/api/administracion/parametros/${claveParam}/historial`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [claveParam, detalle?.historial, manejarError]);

  // 2 verificarDocente(): al elegir el docente o cambiar el rol de la cuenta nueva
  useEffect(() => {
    setVerificacion(null);
    if (!docente) return;
    (async () => {
      try {
        setVerificacion(await apiRequest(`/api/administracion/docentes/${docente.idDocente}/verificacion?rol=${nuevo.rol}`));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [docente, nuevo.rol, manejarError]);

  // 2 verificarDocente() en la edición de una cuenta
  useEffect(() => {
    if (accion !== 'EDITAR' || !edicion.docente) {
      setEdicion((x) => (x.verificacion ? { ...x, verificacion: null } : x));
      return;
    }
    (async () => {
      try {
        const v = await apiRequest(`/api/administracion/docentes/${edicion.docente.idDocente}/verificacion?rol=${edicion.rol}&idUsuario=${idUsuario}`);
        setEdicion((x) => ({ ...x, verificacion: v }));
      } catch (e) {
        manejarError(e);
      }
    })();
  }, [accion, edicion.docente, edicion.rol, idUsuario, manejarError]);

  function limpiarAccion() {
    setAccion(null);
    setConfirmando(false);
  }

  function irA(codigo) {
    setPaso(codigo);
    limpiarAccion();
    setFeedback(null);
  }

  async function refrescar() {
    try {
      await cargar();
      setFeedback(null);
    } catch (e) {
      manejarError(e);
    }
  }

  async function ejecutar(ruta, metodo, cuerpo, alTerminar) {
    setSaving(true);
    setFeedback(null);
    try {
      const data = await apiRequest(ruta, { method: metodo, body: cuerpo === undefined ? undefined : JSON.stringify(cuerpo) });
      if (data?.detalle) setDetalle(data.detalle);
      setFeedback({ type: 'success', text: data?.mensaje ?? 'Operación realizada.' });
      limpiarAccion();
      alTerminar?.(data);
      return data;
    } catch (e) {
      manejarError(e);
      setConfirmando(false);
      return null;
    } finally {
      setSaving(false);
    }
  }

  // ─── 1-4 Cuentas ─────────────────────────────────────────────────────────

  /** 1 ingresarUsuario → 1.1 crearUsuario · 2 verificarDocente · 3 insertarUsuario · 4 mostrarUsuario. */
  const crearUsuario = () => ejecutar('/api/administracion/usuarios', 'POST', {
    username: nuevo.username.trim(),
    rol: nuevo.rol,
    idDocente: docente?.idDocente ?? null,
    password: nuevo.modoClave === 'ESCRIBIR' ? nuevo.password : null,
    generarClave: nuevo.modoClave === 'GENERAR',
  }, (d) => {
    setEntregada({ usuario: d.usuario, clave: d.claveProvisional });
    setNuevo(nuevoVacio);
    setDocente(null);
  });

  const editarUsuario = () => ejecutar(`/api/administracion/usuarios/${idUsuario}`, 'PUT', {
    rol: edicion.rol, idDocente: edicion.docente?.idDocente ?? null,
  });

  const cambiarEstado = (activo) => ejecutar(`/api/administracion/usuarios/${idUsuario}/estado`, 'POST', {
    activo, motivo: motivoEstado.trim() || null,
  }, () => setMotivoEstado(''));

  const restablecerClave = () => ejecutar(`/api/administracion/usuarios/${idUsuario}/clave`, 'POST', {
    password: clave.modo === 'ESCRIBIR' ? clave.password : null,
  }, (d) => {
    setEntregada({ usuario: d.usuario, clave: d.claveProvisional });
    setClave({ modo: 'GENERAR', password: '' });
  });

  const desbloquear = () => ejecutar(`/api/administracion/usuarios/${idUsuario}/desbloqueo`, 'POST', {});

  const eliminar = () => ejecutar(`/api/administracion/usuarios/${idUsuario}`, 'DELETE', undefined, () => setIdUsuario(null));

  function abrirUsuario(id) {
    setIdUsuario(id === idUsuario ? null : id);
    limpiarAccion();
    setEntregada(null);
  }

  function abrirNuevo() {
    setAccion('NUEVO');
    setConfirmando(false);
    setIdUsuario(null);
    setEntregada(null);
    setNuevo(nuevoVacio);
    setDocente(null);
  }

  // ─── 5-9 Parámetros ──────────────────────────────────────────────────────

  /** 5 modificarParametro → 6 actualizar · 7 actualizarParametro · 8 registrarAuditoria · 9 confirmarCambio. */
  const actualizarParametro = () => ejecutar(`/api/administracion/parametros/${claveParam}`, 'PUT', {
    valor: String(cambio.valor).trim(), motivo: cambio.motivo.trim(),
  }, (d) => {
    setConfirmacion(d.confirmacion);
    setCambio({ valor: '', motivo: '' });
  });

  const restaurarParametro = () => ejecutar(`/api/administracion/parametros/${claveParam}/restauracion`, 'POST', {
    idHistorial: restauracion.idHistorial, motivo: restauracion.motivo.trim(),
  }, (d) => {
    setConfirmacion(d.confirmacion);
    setRestauracion({ idHistorial: null, motivo: '' });
  });

  function abrirParametro(p) {
    setClaveParam(p.clave === claveParam ? null : p.clave);
    setCambio({ valor: p.valor, motivo: '' });
    setRestauracion({ idHistorial: null, motivo: '' });
    setConfirmacion(null);
    limpiarAccion();
  }

  // ─── 10-13 Respaldo ──────────────────────────────────────────────────────

  /** 10 solicitarRespaldo → 11 generarRespaldo · 12 registrarAuditoria · 13 mostrarRespaldo. */
  const generarRespaldo = () => ejecutar('/api/administracion/respaldos', 'POST', { motivo: motivoRespaldo.trim() || null }, (d) => {
    setUltimoRespaldo(d.respaldo);
    setMotivoRespaldo('');
  });

  async function verificarRespaldo(id) {
    setSaving(true);
    setFeedback(null);
    try {
      const d = await apiRequest(`/api/administracion/respaldos/${id}/verificacion`, { method: 'POST', body: '{}' });
      setVerificaciones((v) => ({ ...v, [id]: d.verificacion }));
      setFeedback({ type: d.verificacion.resultado === 'INTEGRO' ? 'success' : 'error', text: d.mensaje });
    } catch (e) {
      manejarError(e);
    } finally {
      setSaving(false);
    }
  }

  async function descargarRespaldo(r) {
    setFeedback(null);
    try {
      const token = sessionStorage.getItem('accessToken');
      const resp = await fetch(`/api/administracion/respaldos/${r.idRespaldo}/archivo`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (resp.status === 401) throw new Error('SESSION_EXPIRED');
      if (!resp.ok) {
        let texto = 'No se pudo descargar el respaldo.';
        try { texto = (await resp.json()).detail ?? texto; } catch { /* sin cuerpo */ }
        throw new Error(texto);
      }
      const url = URL.createObjectURL(await resp.blob());
      const a = document.createElement('a');
      a.href = url;
      a.download = r.nombreArchivo;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 2000);
      setFeedback({ type: 'success', text: `Descargando ${r.nombreArchivo}. La descarga quedó en la bitácora.` });
    } catch (e) {
      manejarError(e);
    }
  }

  // ─── Datos derivados ─────────────────────────────────────────────────────

  const usuariosFiltrados = useMemo(() => {
    const texto = filtro.texto.trim().toLowerCase();
    return (detalle?.usuarios ?? []).filter((u) => (filtro.rol === 'TODOS' || u.rol === filtro.rol)
      && (filtro.estado === 'TODAS'
        || (filtro.estado === 'ACTIVAS' && si(u.activo))
        || (filtro.estado === 'INACTIVAS' && !si(u.activo))
        || (filtro.estado === 'BLOQUEADAS' && si(u.bloqueada))
        || (filtro.estado === 'PROVISIONAL' && si(u.debeCambiarPassword)))
      && (!texto || `${u.username} ${u.docente ?? ''} ${u.dni ?? ''} ${u.facultad ?? ''}`.toLowerCase().includes(texto)));
  }, [detalle, filtro]);

  if (cargando) return <div className="panel"><p className="muted">Cargando la administración del sistema…</p></div>;
  if (!detalle) {
    return (
      <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mu-shell ad-shell mx">
        {feedback && <div className={`alert ${feedback.type}`} role="status">{feedback.text}</div>}
      </div>
    );
  }

  const { resumen, politica, jornada } = detalle;
  const enJornada = jornada.length > 0;
  const seleccionado = detalle.usuarios.find((u) => u.idUsuario === idUsuario) ?? null;
  const parametro = detalle.parametros.find((p) => p.clave === claveParam) ?? null;
  const ultimo = detalle.respaldos[0] ?? null;
  const diasSinRespaldo = ultimo ? Math.floor((Date.now() - new Date(ultimo.fechaFin).getTime()) / 86400000) : null;
  const grupos = Object.keys(GRUPO).filter((g) => detalle.parametros.some((p) => p.grupo === g));
  const historial = filtroHistorial === 'TODOS' ? detalle.historial : detalle.historial.filter((h) => h.clave === filtroHistorial);

  return (
    <div className="pd-shell cq-shell cs-shell ig-shell cp-shell nl-shell mu-shell ad-shell mx">
      <section className="in-head">
        <div className="ad-titulo">
          <span className="cv-label">Administración del sistema</span>
          <strong>{session?.username ?? 'Admin'} · {ROL.ADMIN}</strong>
        </div>
        <div className={`in-plazo ${enJornada ? 'closed' : 'open'}`}>
          <MenuIcon name={enJornada ? 'lock' : 'shield'} size={18} />
          <div>
            <strong>{enJornada ? `Jornada en curso · ${jornada.map((j) => j.nombre).join(', ')}` : 'Sin votación en curso'}</strong>
            <span>{enJornada ? 'Los parámetros de la jornada (mesas, lugar y horarios) no se modifican hasta el cierre.' : 'Todos los parámetros se pueden modificar con su motivo.'} Contraseñas de {politica.passwordMin}+ caracteres · bloqueo tras {politica.intentosMaximos} intentos por {politica.bloqueoMinutos} min.</span>
          </div>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={refrescar} disabled={saving}>
          <MenuIcon name="refresh" size={15} /> Actualizar
        </button>
      </section>

      <div className="pd-tabs cq-tabs mx-pasos cp-pasos nl-pasos ad-pasos" role="tablist" aria-label="Administrar usuarios y parámetros">
        {PASOS.map((p) => {
          const n = p.codigo === 'USUARIOS' ? resumen.total : p.codigo === 'PARAMETROS' ? detalle.parametros.length : detalle.respaldos.length;
          const alerta = (p.codigo === 'USUARIOS' && resumen.bloqueadas > 0) || (p.codigo === 'RESPALDO' && (!ultimo || diasSinRespaldo > 7));
          return (
            <button key={p.codigo} type="button" role="tab" aria-selected={paso === p.codigo}
              className={`pd-tab mx-paso${paso === p.codigo ? ' on' : ''}${alerta ? ' nl-alerta' : ''}`} onClick={() => irA(p.codigo)}>
              <span className="mx-paso-num"><MenuIcon name={p.icono} size={14} /></span>
              <span className="mx-paso-texto"><b>{p.texto}{n ? <em className="nl-cuenta">{n}</em> : null}</b><small>{p.nota}</small></span>
            </button>
          );
        })}
      </div>

      <section className="cq-resumen">
        <div className="cq-kpi" style={{ '--cq-color': '#2563eb' }}>
          <span>Cuentas activas <em>4 mostrarUsuario</em></span>
          <strong>{resumen.activos}<small> / {resumen.total}</small></strong>
          <small>{resumen.inactivos} inactiva(s) · {resumen.sinAcceso} sin ingresar aún</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': resumen.bloqueadas ? '#e11d48' : '#059669' }}>
          <span>Bloqueadas <em>{politica.intentosMaximos} intentos</em></span>
          <strong>{resumen.bloqueadas}</strong>
          <small>{resumen.provisionales} con contraseña provisional</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': '#7c3aed' }}>
          <span>Parámetros <em>8 registrarAuditoria</em></span>
          <strong>{detalle.parametros.length}</strong>
          <small>{detalle.historial.length ? `Último cambio ${fecha(detalle.historial[0].fecha)}` : 'Sin cambios registrados'}</small>
        </div>
        <div className="cq-kpi" style={{ '--cq-color': !ultimo || diasSinRespaldo > 7 ? '#d97706' : '#059669' }}>
          <span>Último respaldo <em>13 mostrarRespaldo</em></span>
          <strong className="cp-etapa">{ultimo ? (diasSinRespaldo === 0 ? 'Hoy' : `Hace ${diasSinRespaldo} día(s)`) : 'Sin respaldo'}</strong>
          <small>{ultimo ? `${bytes(ultimo.tamanoBytes)} · ${ultimo.filas} filas` : 'Genere uno antes de la jornada'}</small>
        </div>
      </section>

      {feedback && <div className={`alert ${feedback.type}`} role="status" onClick={() => setFeedback(null)}>{feedback.text}</div>}

      {/* ── 1-4 Cuentas y roles ── */}
      {paso === 'USUARIOS' && (
        <>
          {entregada && (
            <div className="panel cv-form ad-entrega" role="alert">
              <div className="cv-section-head">
                <div>
                  <h3>4 mostrarUsuario · contraseña provisional de «{entregada.usuario.username}»</h3>
                  <p className="muted">Entréguela al titular de la cuenta. Se muestra solo ahora: el sistema guarda únicamente su cifrado (BCrypt) y pedirá cambiarla al primer ingreso.</p>
                </div>
                <div className="cs-acciones-head">
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => navigator.clipboard?.writeText(entregada.clave)}>
                    <MenuIcon name="key" size={15} /> Copiar
                  </button>
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => imprimirFichaAcceso(entregada.usuario, entregada.clave, politica, session?.username)}>
                    <MenuIcon name="file" size={15} /> Imprimir ficha de acceso
                  </button>
                </div>
              </div>
              <div className="ad-clave">
                <div><span>Usuario</span><strong>{entregada.usuario.username}</strong></div>
                <div><span>Rol</span><strong>{ROL[entregada.usuario.rol]}</strong></div>
                <div><span>Docente</span><strong>{entregada.usuario.docente ?? '—'}</strong></div>
                <div className="ad-clave-valor"><span>Contraseña provisional</span><code>{entregada.clave}</code></div>
              </div>
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setEntregada(null)}>Ya la entregué · ocultar</button>
              </div>
            </div>
          )}

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>1 ingresarUsuario · cuentas del sistema</h3>
                <p className="muted">Cada cuenta tiene un rol. Las de docente, personero y miembro de mesa se asocian a un docente activo del padrón (una cuenta por rol). Las acciones quedan en la bitácora con su autor.</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={abrirNuevo}>
                  <MenuIcon name="plus" size={15} /> Nueva cuenta
                </button>
              </div>
            </div>

            {accion === 'NUEVO' && (
              <FormNuevaCuenta
                nuevo={nuevo} setNuevo={setNuevo} docente={docente} setDocente={setDocente} verificacion={verificacion}
                usuarios={detalle.usuarios} politica={politica} saving={saving}
                confirmando={confirmando} setConfirmando={setConfirmando} onCancelar={limpiarAccion} onConfirmar={crearUsuario}
                onError={manejarError}
              />
            )}

            <section className="ad-roles">
              <button type="button" className={`ad-rol${filtro.rol === 'TODOS' ? ' on' : ''}`} style={{ '--ad-color': '#0f172a' }}
                onClick={() => setFiltro((f) => ({ ...f, rol: 'TODOS' }))}>
                <span>Todas</span><strong>{resumen.total}</strong>
              </button>
              {ROLES.map((r) => (
                <button key={r} type="button" className={`ad-rol${filtro.rol === r ? ' on' : ''}`} style={{ '--ad-color': COLOR_ROL[r] }}
                  onClick={() => setFiltro((f) => ({ ...f, rol: f.rol === r ? 'TODOS' : r }))}>
                  <span>{ROL_CORTO[r]}</span><strong>{resumen.porRol[r] ?? 0}</strong>
                </button>
              ))}
            </section>
            <div className="mu-filtros">
              <div className="cq-chips" role="group" aria-label="Estado de la cuenta">
                {ESTADOS.map(([v, t]) => (
                  <button key={v} type="button" className={`cq-chip${filtro.estado === v ? ' on' : ''}`} onClick={() => setFiltro((f) => ({ ...f, estado: v }))}>{t}</button>
                ))}
              </div>
              <label className="mu-buscar">
                <MenuIcon name="search" size={14} />
                <input value={filtro.texto} onChange={(e) => setFiltro((f) => ({ ...f, texto: e.target.value }))} placeholder="Usuario, docente, DNI o facultad" aria-label="Buscar cuenta" />
              </label>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th>Usuario</th><th>Rol</th><th>Docente</th><th>Situación</th><th>Último acceso</th><th /></tr></thead>
                <tbody>
                  {usuariosFiltrados.map((u) => {
                    const s = situacion(u);
                    return (
                      <tr key={u.idUsuario} className={u.idUsuario === idUsuario ? 'ad-fila-on' : ''}>
                        <td><strong>{u.username}</strong>{u.idUsuario === detalle.idAdmin && <em className="ad-yo">usted</em>}
                          <small className="pd-sub">Creada {fecha(u.fechaCreacion)}{u.creadoPor ? ` por ${u.creadoPor}` : ''}</small></td>
                        <td><span className="ad-rol-pill" style={{ '--ad-color': COLOR_ROL[u.rol] }}>{ROL_CORTO[u.rol] ?? u.rol}</span></td>
                        <td>{u.docente ? <>{u.docente}<small className="pd-sub">DNI {u.dni} · {u.facultad}</small></> : <span className="muted">Sin docente</span>}</td>
                        <td><span className={`cv-estado ${s.clase}`}>{s.texto}</span>
                          {si(u.activo) && Number(u.intentosFallidos) > 0 && !si(u.bloqueada) && <small className="pd-sub">{u.intentosFallidos} intento(s) fallido(s)</small>}</td>
                        <td>{u.ultimoAcceso ? fecha(u.ultimoAcceso) : <span className="muted">Nunca</span>}</td>
                        <td className="n">
                          <button type="button" className="cv-btn cv-btn-soft" onClick={() => abrirUsuario(u.idUsuario)}>
                            <MenuIcon name={u.idUsuario === idUsuario ? 'close' : 'edit'} size={14} /> {u.idUsuario === idUsuario ? 'Cerrar' : 'Gestionar'}
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                  {usuariosFiltrados.length === 0 && <tr><td colSpan={6} className="muted">Ninguna cuenta coincide con el filtro.</td></tr>}
                </tbody>
              </table>
            </div>
          </div>

          {seleccionado && (
            <FichaCuenta
              u={seleccionado} propia={seleccionado.idUsuario === detalle.idAdmin} actividad={actividad} politica={politica}
              accion={accion} setAccion={(a) => { setAccion(a); setConfirmando(false); }} confirmando={confirmando} setConfirmando={setConfirmando} saving={saving}
              edicion={edicion} setEdicion={setEdicion} motivoEstado={motivoEstado} setMotivoEstado={setMotivoEstado}
              clave={clave} setClave={setClave} admin={session?.username}
              onEditar={editarUsuario} onEstado={cambiarEstado} onClave={restablecerClave} onDesbloquear={desbloquear} onEliminar={eliminar}
              onCancelar={limpiarAccion} onCerrar={() => { setIdUsuario(null); limpiarAccion(); }} onError={manejarError}
            />
          )}
        </>
      )}

      {/* ── 5-9 Parámetros ── */}
      {paso === 'PARAMETROS' && (
        <>
          {enJornada && (
            <div className="mx-mensaje aviso" role="note">
              <MenuIcon name="lock" size={18} />
              <div><h4>Jornada electoral en curso</h4><p>Con un proceso en votación no se cambian los parámetros de la jornada (electores por mesa, lugar y horarios): rigen para todas las mesas hasta el cierre del sufragio.</p></div>
            </div>
          )}
          {confirmacion && (
            <div className="mx-mensaje info ad-confirmado" role="status">
              <MenuIcon name="check" size={18} />
              <div>
                <h4>9 confirmarCambio · {confirmacion.etiqueta}</h4>
                <p><s>{confirmacion.valorAnterior}</s> → <strong>{confirmacion.valorNuevo}</strong> · registrado en el historial (N.º {confirmacion.idHistorial}) y en la bitácora el {fecha(confirmacion.fecha)}.</p>
              </div>
            </div>
          )}

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>5 modificarParametro · parámetros del reglamento y del sistema</h3>
                <p className="muted">Elija un parámetro para modificarlo. El sistema valida el tipo y el rango (7 actualizarParametro), exige el motivo y guarda el valor anterior, el nuevo, el usuario y la fecha (8 registrarAuditoria). Los cambios no alteran las multas ya determinadas: cada multa guarda la UIT y el porcentaje con que se calculó.</p>
              </div>
              <div className="cs-acciones-head">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirParametros(detalle.parametros, detalle.historial, jornada)}>
                  <MenuIcon name="file" size={15} /> Imprimir parámetros
                </button>
              </div>
            </div>

            {grupos.map((g) => (
              <div key={g} className="ad-grupo">
                <h4><MenuIcon name={GRUPO[g].icono} size={15} /> {GRUPO[g].texto} <small>{GRUPO[g].nota}</small></h4>
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Parámetro</th><th className="n">Valor vigente</th><th>Rango</th><th>Último cambio</th><th /></tr></thead>
                    <tbody>
                      {detalle.parametros.filter((p) => p.grupo === g).map((p) => (
                        <tr key={p.clave} className={p.clave === claveParam ? 'ad-fila-on' : ''}>
                          <td><strong>{p.etiqueta}</strong><small className="pd-sub"><code>{p.clave}</code>{p.referencia ? ` · ${p.referencia}` : ''}</small></td>
                          <td className="n"><strong className="ad-valor">{valorLegible(p)}</strong>{p.tipo === 'HORA' && <small className="pd-sub">valor {p.valor}</small>}</td>
                          <td>{rango(p)}{si(p.bloqueoJornada) && <small className="pd-sub">{si(p.bloqueado) ? '🔒 bloqueado: votación en curso' : 'Se bloquea durante la votación'}</small>}</td>
                          <td>{p.fechaUltimoCambio ? <>{fecha(p.fechaUltimoCambio)}<small className="pd-sub">{p.modificadoPor ?? 'directo en la base'} · {p.cambios} cambio(s)</small></> : <span className="muted">Sin cambios</span>}</td>
                          <td className="n">
                            <button type="button" className="cv-btn cv-btn-soft" onClick={() => abrirParametro(p)}>
                              <MenuIcon name={p.clave === claveParam ? 'close' : 'edit'} size={14} /> {p.clave === claveParam ? 'Cerrar' : 'Modificar'}
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ))}
          </div>

          {parametro && (
            <FichaParametro
              p={parametro} parametros={detalle.parametros} historial={historialParam} cambio={cambio} setCambio={setCambio}
              restauracion={restauracion} setRestauracion={setRestauracion}
              accion={accion} setAccion={(a) => { setAccion(a); setConfirmando(false); }} confirmando={confirmando} setConfirmando={setConfirmando}
              saving={saving} onActualizar={actualizarParametro} onRestaurar={restaurarParametro} onCancelar={limpiarAccion}
              onCerrar={() => { setClaveParam(null); limpiarAccion(); }}
            />
          )}

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>8 registrarAuditoria · historial de cambios</h3>
                <p className="muted">Los últimos {detalle.historial.length} cambios. El historial no se modifica ni se borra; también registra los cambios hechos directamente en la base de datos.</p>
              </div>
              <div className="cs-acciones-head">
                <select className="ad-select" value={filtroHistorial} onChange={(e) => setFiltroHistorial(e.target.value)} aria-label="Filtrar por parámetro">
                  <option value="TODOS">Todos los parámetros</option>
                  {detalle.parametros.map((p) => <option key={p.clave} value={p.clave}>{p.etiqueta}</option>)}
                </select>
              </div>
            </div>
            <TablaHistorial filas={historial} parametros={detalle.parametros} />
          </div>
        </>
      )}

      {/* ── 10-13 Respaldo de la base de datos ── */}
      {paso === 'RESPALDO' && (
        <>
          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>10 solicitarRespaldo · copia completa de la base de datos</h3>
                <p className="muted">El sistema lee la base de forma consistente (sin detener la votación) y genera un archivo .sql con todas las tablas y sus datos, funciones, vistas, procedimientos y triggers (11 generarRespaldo). Registra el archivo con su huella SHA-256 en la bitácora (12 registrarAuditoria). Contiene datos personales y contraseñas cifradas: descárguelo y guárdelo en un medio seguro.</p>
              </div>
            </div>
            {accion !== 'RESPALDO' ? (
              <div className="cv-actions cp-izq">
                <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={() => { setAccion('RESPALDO'); setConfirmando(false); }}>
                  <MenuIcon name="download" size={15} /> Generar respaldo
                </button>
              </div>
            ) : (
              <form className="ig-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
                <div className="ig-grid">
                  <label className="cv-field nl-ancho">
                    <span className="cv-label">Motivo (opcional)</span>
                    <input maxLength={300} value={motivoRespaldo} disabled={saving} placeholder="Ej.: antes de la jornada electoral, cierre del cómputo…"
                      onChange={(e) => { setMotivoRespaldo(e.target.value); setConfirmando(false); }} />
                  </label>
                </div>
                {!confirmando ? (
                  <div className="cv-actions">
                    <button type="button" className="cv-btn cv-btn-ghost" onClick={limpiarAccion}>Cancelar</button>
                    <button type="submit" className="cv-btn cv-btn-primary" disabled={saving}><MenuIcon name="download" size={15} /> Generar</button>
                  </div>
                ) : (
                  <div className="cq-confirmar-emision" role="alert">
                    <div>
                      <strong>¿Generar ahora el respaldo completo de la base?</strong>
                      <span>11 generarRespaldo: se guarda en la carpeta «{detalle.directorioRespaldos}» del servidor y queda registrado con su huella.</span>
                    </div>
                    <div className="cv-actions">
                      <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                      <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={generarRespaldo}>
                        <MenuIcon name="check" size={15} /> {saving ? 'Generando…' : 'Confirmar'}
                      </button>
                    </div>
                  </div>
                )}
              </form>
            )}

            {ultimoRespaldo && (
              <div className="ad-respaldo" role="status">
                <h4>13 mostrarRespaldo · {ultimoRespaldo.nombreArchivo}</h4>
                <div className="mu-parametros">
                  <div><span>Tablas</span><strong>{ultimoRespaldo.tablas}</strong><small>{ultimoRespaldo.filas} filas</small></div>
                  <div><span>Vistas</span><strong>{ultimoRespaldo.vistas}</strong><small>consultas y reportes</small></div>
                  <div><span>Rutinas</span><strong>{ultimoRespaldo.rutinas}</strong><small>funciones y procedimientos</small></div>
                  <div><span>Triggers</span><strong>{ultimoRespaldo.disparadores}</strong><small>reglas de la base</small></div>
                  <div><span>Tamaño</span><strong>{bytes(ultimoRespaldo.tamanoBytes)}</strong><small>{ultimoRespaldo.duracionSeg ?? 0} s</small></div>
                </div>
                <dl className="nl-texto"><div><dt>Huella SHA-256</dt><dd className="cp-hash">{ultimoRespaldo.hashSha256}</dd></div></dl>
                <div className="cv-actions cp-izq">
                  <button type="button" className="cv-btn cv-btn-primary" onClick={() => descargarRespaldo(ultimoRespaldo)}><MenuIcon name="download" size={15} /> Descargar</button>
                  <button type="button" className="cv-btn cv-btn-ghost" disabled={saving} onClick={() => verificarRespaldo(ultimoRespaldo.idRespaldo)}><MenuIcon name="shield" size={15} /> Verificar integridad</button>
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirConstanciaRespaldo(ultimoRespaldo, verificaciones[ultimoRespaldo.idRespaldo])}><MenuIcon name="file" size={15} /> Imprimir constancia</button>
                </div>
              </div>
            )}
          </div>

          <div className="panel cv-form">
            <div className="cv-section-head">
              <div>
                <h3>Respaldos generados</h3>
                <p className="muted">{detalle.respaldos.length} respaldo(s). «Verificar integridad» recalcula la huella SHA-256 del archivo y la compara con la registrada: si no coincide, el archivo fue modificado y no debe usarse.</p>
              </div>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th>N.º</th><th>Archivo</th><th>Contenido</th><th>Huella SHA-256</th><th>Integridad</th><th /></tr></thead>
                <tbody>
                  {detalle.respaldos.map((r) => {
                    const v = verificaciones[r.idRespaldo];
                    return (
                      <tr key={r.idRespaldo}>
                        <td>{r.idRespaldo}</td>
                        <td><strong>{r.nombreArchivo}</strong><small className="pd-sub">{fecha(r.fechaFin)} · {r.username}{r.motivo ? ` · ${r.motivo}` : ''}</small></td>
                        <td>{r.tablas} tablas · {r.filas} filas<small className="pd-sub">{r.vistas} vistas · {r.rutinas} rutinas · {r.disparadores} triggers · {bytes(r.tamanoBytes)}</small></td>
                        <td><code className="ad-hash" title={r.hashSha256}>{r.hashSha256.slice(0, 16)}…</code></td>
                        <td>{!v ? <span className="muted">Sin verificar</span>
                          : <span className={`cv-estado ${v.resultado === 'INTEGRO' ? 'votacion' : 'anulado'}`}>{v.resultado === 'INTEGRO' ? 'Íntegro' : v.resultado === 'ALTERADO' ? 'Alterado' : 'No encontrado'}</span>}</td>
                        <td className="n ad-acciones">
                          <button type="button" className="cv-btn cv-btn-soft" onClick={() => descargarRespaldo(r)} title="Descargar"><MenuIcon name="download" size={14} /></button>
                          <button type="button" className="cv-btn cv-btn-soft" disabled={saving} onClick={() => verificarRespaldo(r.idRespaldo)} title="Verificar integridad"><MenuIcon name="shield" size={14} /></button>
                          <button type="button" className="cv-btn cv-btn-soft" onClick={() => imprimirConstanciaRespaldo(r, v)} title="Imprimir constancia"><MenuIcon name="file" size={14} /></button>
                        </td>
                      </tr>
                    );
                  })}
                  {detalle.respaldos.length === 0 && <tr><td colSpan={6} className="muted">Aún no se generó ningún respaldo.</td></tr>}
                </tbody>
              </table>
            </div>
          </div>

          <div className="mx-mensaje info" role="note">
            <MenuIcon name="info" size={18} />
            <div>
              <h4>Cómo restaurar un respaldo</h4>
              <p>Verifique primero su integridad. En phpMyAdmin elija la base <strong>elecciones_unp</strong> y use «Importar» con el archivo, o ejecute <code>mysql -u root elecciones_unp &lt; archivo.sql</code>. La restauración reemplaza las tablas, vistas y rutinas por las del respaldo; los triggers se crean al final para que las reglas no rechacen la carga.</p>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

function rango(p) {
  if (p.minimo == null && p.maximo == null) return <span className="muted">—</span>;
  if (p.tipo === 'TEXTO') return `${Math.round(p.minimo ?? 0)} a ${Math.round(p.maximo)} caracteres`;
  if (p.tipo === 'INDICADOR') return '1 sí · 0 no';
  if (p.tipo === 'HORA') return `${hora(p.minimo)} a ${hora(p.maximo)}`;
  return `${Number(p.minimo)} a ${Number(p.maximo)}${p.unidad ? ` ${p.unidad}` : ''}`;
}

// ─── 1 ingresarUsuario · formulario de la cuenta nueva ──────────────────────

function FormNuevaCuenta({ nuevo, setNuevo, docente, setDocente, verificacion, usuarios, politica, saving, confirmando, setConfirmando, onCancelar, onConfirmar, onError }) {
  const requiere = ROLES_CON_DOCENTE.includes(nuevo.rol);
  const errorDocente = verificacion?.error ?? null;
  const claveValida = nuevo.modoClave === 'GENERAR'
    || (nuevo.password.length >= politica.passwordMin && /[A-Za-z]/.test(nuevo.password) && /[0-9]/.test(nuevo.password));
  const usuarioValido = /^[A-Za-z0-9._-]{3,80}$/.test(nuevo.username.trim());
  const duplicado = usuarios.some((u) => u.username.toLowerCase() === nuevo.username.trim().toLowerCase());
  const listo = usuarioValido && !duplicado && claveValida && (!requiere || docente) && !errorDocente && (!docente || verificacion);

  const cambiar = (campo, valor) => { setNuevo((n) => ({ ...n, [campo]: valor })); setConfirmando(false); };

  function elegirDocente(d) {
    setDocente(d);
    setConfirmando(false);
    if (d) setNuevo((n) => ({ ...n, username: sugerirUsuario(d, n.rol, usuarios) }));
  }

  function elegirRol(r) {
    setNuevo((n) => ({ ...n, rol: r, username: docente && (!n.username || n.username === sugerirUsuario(docente, n.rol, usuarios)) ? sugerirUsuario(docente, r, usuarios) : n.username }));
    setConfirmando(false);
  }

  return (
    <form className="ig-form ad-form" onSubmit={(e) => { e.preventDefault(); if (listo) setConfirmando(true); }}>
      <h4>1.1 crearUsuario · nueva cuenta</h4>
      <div className="ad-roles-elegir" role="radiogroup" aria-label="Rol de la cuenta">
        {ROLES.map((r) => (
          <button key={r} type="button" role="radio" aria-checked={nuevo.rol === r} className={`ad-rol-op${nuevo.rol === r ? ' on' : ''}`}
            style={{ '--ad-color': COLOR_ROL[r] }} disabled={saving} onClick={() => elegirRol(r)}>
            <strong>{ROL[r]}</strong><small>{ROL_NOTA[r]}</small>
          </button>
        ))}
      </div>

      <SelectorDocente
        titulo={`2 verificarDocente · docente del padrón${requiere ? '' : ' (opcional)'}`} docente={docente} onElegir={elegirDocente}
        verificacion={verificacion} requerido={requiere} disabled={saving} onError={onError}
      />

      <div className="ig-grid">
        <label className="cv-field">
          <span className="cv-label">Nombre de usuario</span>
          <input required minLength={3} maxLength={80} value={nuevo.username} disabled={saving} autoComplete="off" placeholder="Ej.: jperez.mesa"
            onChange={(e) => cambiar('username', e.target.value)} />
          {nuevo.username && !usuarioValido && <small className="cv-error">Letras, números, punto, guion y guion bajo (3 a 80).</small>}
          {duplicado && <small className="cv-error">Ese nombre de usuario ya existe.</small>}
        </label>
        <div className="cv-field ad-ancho2">
          <span className="cv-label">Contraseña inicial</span>
          <div className="cq-chips" role="radiogroup" aria-label="Contraseña">
            <button type="button" className={`cq-chip${nuevo.modoClave === 'GENERAR' ? ' on' : ''}`} onClick={() => cambiar('modoClave', 'GENERAR')}>Generar provisional segura</button>
            <button type="button" className={`cq-chip${nuevo.modoClave === 'ESCRIBIR' ? ' on' : ''}`} onClick={() => cambiar('modoClave', 'ESCRIBIR')}>Escribirla</button>
          </div>
          {nuevo.modoClave === 'ESCRIBIR' && (
            <>
              <input type="text" autoComplete="new-password" maxLength={72} value={nuevo.password} disabled={saving} placeholder={`Al menos ${politica.passwordMin} caracteres con letras y números`}
                onChange={(e) => cambiar('password', e.target.value)} />
              {nuevo.password && !claveValida && <small className="cv-error">Debe tener {politica.passwordMin}+ caracteres y combinar letras y números.</small>}
            </>
          )}
          <small className="muted">En ambos casos es provisional: el titular la cambia al primer ingreso.</small>
        </div>
      </div>

      {!confirmando ? (
        <div className="cv-actions">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
          <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !listo}><MenuIcon name="plus" size={15} /> Crear cuenta</button>
        </div>
      ) : (
        <div className="cq-confirmar-emision" role="alert">
          <div>
            <strong>¿Crear la cuenta «{nuevo.username.trim()}» con el rol {ROL[nuevo.rol]}?</strong>
            <span>3 insertarUsuario{docente ? `: asociada a ${docente.docente} (DNI ${docente.dni})` : ': sin docente asociado'}. {nuevo.modoClave === 'GENERAR' ? 'El sistema genera la contraseña provisional y la muestra una sola vez.' : 'La contraseña escrita queda como provisional.'}</span>
          </div>
          <div className="cv-actions">
            <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
            <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onConfirmar}><MenuIcon name="check" size={15} /> {saving ? 'Creando…' : 'Confirmar'}</button>
          </div>
        </div>
      )}
    </form>
  );
}

// ─── 2 verificarDocente · búsqueda en el padrón ─────────────────────────────

function SelectorDocente({ titulo, docente, onElegir, verificacion, requerido, disabled, onError }) {
  const [q, setQ] = useState('');
  const [resultados, setResultados] = useState([]);
  const [buscando, setBuscando] = useState(false);

  useEffect(() => {
    if (docente || q.trim().length < 2) {
      setResultados([]);
      return undefined;
    }
    const t = setTimeout(async () => {
      setBuscando(true);
      try {
        setResultados(await apiRequest(`/api/administracion/docentes?q=${encodeURIComponent(q.trim())}`));
      } catch (e) {
        onError(e);
      } finally {
        setBuscando(false);
      }
    }, 300);
    return () => clearTimeout(t);
  }, [q, docente, onError]);

  return (
    <div className="ad-docente">
      <span className="cv-label">{titulo}</span>
      {!docente ? (
        <>
          <label className="mu-buscar ad-buscar">
            <MenuIcon name="search" size={14} />
            <input value={q} disabled={disabled} onChange={(e) => setQ(e.target.value)} placeholder="DNI, apellidos o nombres del docente" aria-label="Buscar docente" />
          </label>
          {requerido && <small className="muted">Este rol requiere asociar la cuenta a un docente activo del padrón.</small>}
          {buscando && <small className="muted">Buscando…</small>}
          {resultados.length > 0 && (
            <ul className="ad-resultados">
              {resultados.map((d) => (
                <li key={d.idDocente}>
                  <button type="button" onClick={() => { onElegir(d); setQ(''); }}>
                    <strong>{d.docente}</strong>
                    <small>DNI {d.dni} · {d.facultad} · {d.estado.toLowerCase()}{d.cuentas ? ` · cuentas: ${d.cuentas}` : ' · sin cuentas'}</small>
                  </button>
                </li>
              ))}
            </ul>
          )}
          {!buscando && q.trim().length >= 2 && resultados.length === 0 && <small className="muted">Ningún docente coincide.</small>}
        </>
      ) : (
        <div className={`ad-verificacion ${verificacion?.error ? 'error' : verificacion?.advertencia ? 'aviso' : verificacion ? 'ok' : ''}`}>
          <div className="ad-verificacion-head">
            <div>
              <strong>{docente.docente}</strong>
              <small>DNI {docente.dni} · {docente.facultad}{verificacion?.departamento ? ` · ${verificacion.departamento}` : ''} · {docente.categoria?.toLowerCase()}</small>
            </div>
            <button type="button" className="cv-btn cv-btn-ghost" disabled={disabled} onClick={() => onElegir(null)}>Cambiar docente</button>
          </div>
          {!verificacion ? <small className="muted">Verificando…</small> : (
            <>
              <dl className="ad-datos">
                <div><dt>Estado</dt><dd>{verificacion.estado ?? '—'}{verificacion.habilitadoParaVotar === false || verificacion.habilitadoParaVotar === 0 ? ' · no habilitado para votar' : ''}</dd></div>
                <div><dt>Cuentas</dt><dd>{verificacion.cuentas ?? 'Ninguna'}</dd></div>
                <div><dt>Mesa (CUS06)</dt><dd>{verificacion.mesas ?? '—'}</dd></div>
                <div><dt>Personero (CUS05)</dt><dd>{verificacion.personerias ?? '—'}</dd></div>
              </dl>
              {verificacion.error && <p className="ad-msg error"><MenuIcon name="close" size={14} /> {verificacion.error.replace(/^CUS18:\s*/, '')}</p>}
              {!verificacion.error && verificacion.advertencia && <p className="ad-msg aviso"><MenuIcon name="alert" size={14} /> {verificacion.advertencia}</p>}
              {!verificacion.error && !verificacion.advertencia && <p className="ad-msg ok"><MenuIcon name="check" size={14} /> El docente cumple las reglas para este rol.</p>}
            </>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Ficha de la cuenta: editar, estado, contraseña, desbloqueo y eliminación ─

function FichaCuenta({
  u, propia, actividad, politica, accion, setAccion, confirmando, setConfirmando, saving, edicion, setEdicion, motivoEstado, setMotivoEstado,
  clave, setClave, admin, onEditar, onEstado, onClave, onDesbloquear, onEliminar, onCancelar, onCerrar, onError,
}) {
  const s = situacion(u);
  const activo = si(u.activo);
  const conIntentos = si(u.bloqueada) || Number(u.intentosFallidos) > 0;
  const eliminable = Number(u.actividad) === 0 && !propia;
  const requiere = ROLES_CON_DOCENTE.includes(edicion.rol);
  const sinCambios = edicion.rol === u.rol && (edicion.docente?.idDocente ?? null) === (u.idDocente ?? null);
  const claveValida = clave.modo === 'GENERAR'
    || (clave.password.length >= politica.passwordMin && /[A-Za-z]/.test(clave.password) && /[0-9]/.test(clave.password));

  function abrirEdicion() {
    setEdicion({ rol: u.rol, docente: u.idDocente ? { idDocente: u.idDocente, docente: u.docente, dni: u.dni, facultad: u.facultad, categoria: u.categoria } : null, verificacion: null });
    setAccion('EDITAR');
  }

  const confirmar = (texto, nota, onOk, peligro) => (
    <div className="cq-confirmar-emision" role="alert">
      <div><strong>{texto}</strong><span>{nota}</span></div>
      <div className="cv-actions">
        <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
        <button type="button" className={`cv-btn ${peligro ? 'cv-btn-danger' : 'cv-btn-success'}`} disabled={saving} onClick={onOk}>
          <MenuIcon name="check" size={15} /> {saving ? 'Guardando…' : 'Confirmar'}
        </button>
      </div>
    </div>
  );

  return (
    <div className="panel cv-form ad-ficha">
      <div className="cv-section-head">
        <div>
          <h3>4 mostrarUsuario · {u.username} <span className={`cv-estado ${s.clase}`}>{s.texto}</span></h3>
          <p className="muted">{ROL[u.rol]}{u.docente ? ` · ${u.docente} (DNI ${u.dni})` : ' · sin docente asociado'}{propia ? ' · es su propia cuenta' : ''}</p>
        </div>
        <div className="cs-acciones-head">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={() => imprimirFichaAcceso(u, null, politica, admin)}><MenuIcon name="file" size={15} /> Imprimir ficha</button>
          <button type="button" className="cv-btn cv-btn-ghost" onClick={onCerrar}><MenuIcon name="close" size={15} /> Cerrar</button>
        </div>
      </div>

      <dl className="mx-datos cp-meta">
        <div><dt>Creada</dt><dd>{fecha(u.fechaCreacion)}{u.creadoPor ? ` · ${u.creadoPor}` : ''}</dd></div>
        <div><dt>Último acceso</dt><dd>{u.ultimoAcceso ? fecha(u.ultimoAcceso) : 'Nunca ingresó'}</dd></div>
        <div><dt>Intentos fallidos</dt><dd>{u.intentosFallidos}{si(u.bloqueada) ? ` · bloqueada hasta ${fecha(u.bloqueadoHasta)}` : ''}</dd></div>
        <div><dt>Último cambio</dt><dd>{u.fechaActualizacion ? fecha(u.fechaActualizacion) : '—'}{u.motivoEstado ? ` · ${u.motivoEstado}` : ''}</dd></div>
        <div><dt>Contraseña</dt><dd>{si(u.debeCambiarPassword) ? 'Provisional: debe cambiarla al ingresar' : 'Elegida por el titular'}</dd></div>
        <div><dt>Actividad en la bitácora</dt><dd>{u.actividad} acción(es)</dd></div>
        {u.facultad && <div><dt>Facultad</dt><dd>{u.facultad}{u.departamento ? ` · ${u.departamento}` : ''}</dd></div>}
        {u.email && <div><dt>Correo</dt><dd>{u.email}</dd></div>}
      </dl>

      {!accion || !['EDITAR', 'CLAVE', 'DESBLOQUEAR', 'DESACTIVAR', 'ACTIVAR', 'ELIMINAR'].includes(accion) ? (
        <div className="cv-actions cp-izq ad-botones">
          <button type="button" className="cv-btn cv-btn-primary" disabled={saving} onClick={abrirEdicion}><MenuIcon name="edit" size={15} /> Editar rol o docente</button>
          <button type="button" className="cv-btn cv-btn-ghost" disabled={saving || propia} onClick={() => setAccion('CLAVE')} title={propia ? 'Cambie su propia contraseña en «Configuración»' : ''}>
            <MenuIcon name="key" size={15} /> Restablecer contraseña
          </button>
          {conIntentos && <button type="button" className="cv-btn cv-btn-ghost" disabled={saving} onClick={() => setAccion('DESBLOQUEAR')}><MenuIcon name="lock" size={15} /> Desbloquear</button>}
          {activo
            ? <button type="button" className="cv-btn cv-btn-ghost" disabled={saving || propia} onClick={() => setAccion('DESACTIVAR')}><MenuIcon name="close" size={15} /> Desactivar</button>
            : <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={() => setAccion('ACTIVAR')}><MenuIcon name="check" size={15} /> Activar</button>}
          <button type="button" className="cv-btn cv-btn-danger" disabled={saving || !eliminable} onClick={() => setAccion('ELIMINAR')}
            title={eliminable ? '' : propia ? 'No puede eliminar su propia cuenta' : 'Tiene actividad registrada: desactívela (RN28)'}>
            <MenuIcon name="trash" size={15} /> Eliminar
          </button>
        </div>
      ) : null}
      {propia && !accion && <p className="muted cp-nota">Su propia cuenta no se desactiva, ni se elimina ni cambia de rol. Su contraseña se cambia en «Configuración».</p>}
      {!eliminable && !propia && !accion && <p className="muted cp-nota">La cuenta tiene actividad en la bitácora: no se elimina, se desactiva para conservar quién hizo cada acción (RN28).</p>}

      {accion === 'EDITAR' && (
        <form className="ig-form ad-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>Editar rol o docente de «{u.username}»</h4>
          <div className="ad-roles-elegir" role="radiogroup" aria-label="Rol">
            {ROLES.map((r) => (
              <button key={r} type="button" role="radio" aria-checked={edicion.rol === r} className={`ad-rol-op${edicion.rol === r ? ' on' : ''}`}
                style={{ '--ad-color': COLOR_ROL[r] }} disabled={saving || (propia && r !== u.rol)}
                onClick={() => { setEdicion((x) => ({ ...x, rol: r })); setConfirmando(false); }}>
                <strong>{ROL[r]}</strong><small>{ROL_NOTA[r]}</small>
              </button>
            ))}
          </div>
          <SelectorDocente
            titulo={`2 verificarDocente · docente asociado${requiere ? '' : ' (opcional)'}`} docente={edicion.docente}
            onElegir={(d) => { setEdicion((x) => ({ ...x, docente: d, verificacion: null })); setConfirmando(false); }}
            verificacion={edicion.verificacion} requerido={requiere} disabled={saving} onError={onError}
          />
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="submit" className="cv-btn cv-btn-primary"
                disabled={saving || sinCambios || (requiere && !edicion.docente) || !!edicion.verificacion?.error || (edicion.docente && !edicion.verificacion)}>
                <MenuIcon name="check" size={15} /> Guardar cambios
              </button>
            </div>
          ) : confirmar(
            `¿Guardar los cambios de «${u.username}»?`,
            `${edicion.rol !== u.rol ? `Rol: ${ROL[u.rol]} → ${ROL[edicion.rol]}. ` : ''}${(edicion.docente?.idDocente ?? null) !== (u.idDocente ?? null) ? `Docente: ${edicion.docente?.docente ?? 'ninguno'}. ` : ''}Rige en su próximo inicio de sesión.`,
            onEditar,
          )}
        </form>
      )}

      {accion === 'CLAVE' && (
        <div className="ig-form ad-form">
          <h4>Restablecer la contraseña de «{u.username}»</h4>
          <div className="cq-chips" role="radiogroup" aria-label="Contraseña">
            <button type="button" className={`cq-chip${clave.modo === 'GENERAR' ? ' on' : ''}`} onClick={() => { setClave({ modo: 'GENERAR', password: '' }); setConfirmando(false); }}>Generar provisional segura</button>
            <button type="button" className={`cq-chip${clave.modo === 'ESCRIBIR' ? ' on' : ''}`} onClick={() => { setClave((c) => ({ ...c, modo: 'ESCRIBIR' })); setConfirmando(false); }}>Escribirla</button>
          </div>
          {clave.modo === 'ESCRIBIR' && (
            <label className="cv-field ad-campo">
              <span className="cv-label">Contraseña provisional</span>
              <input type="text" autoComplete="new-password" maxLength={72} value={clave.password} disabled={saving}
                placeholder={`Al menos ${politica.passwordMin} caracteres con letras y números`}
                onChange={(e) => { setClave((c) => ({ ...c, password: e.target.value })); setConfirmando(false); }} />
              {clave.password && !claveValida && <small className="cv-error">Debe tener {politica.passwordMin}+ caracteres y combinar letras y números.</small>}
            </label>
          )}
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="button" className="cv-btn cv-btn-primary" disabled={saving || !claveValida} onClick={() => setConfirmando(true)}><MenuIcon name="key" size={15} /> Restablecer</button>
            </div>
          ) : confirmar(`¿Restablecer la contraseña de «${u.username}»?`, 'La contraseña actual deja de valer, se levanta el bloqueo y deberá elegir una nueva al ingresar.', onClave)}
        </div>
      )}

      {accion === 'DESBLOQUEAR' && (
        <div className="ig-form ad-form">
          {confirmar(`¿Desbloquear «${u.username}»?`, `Tiene ${u.intentosFallidos} intento(s) fallido(s)${si(u.bloqueada) ? ` y está bloqueada hasta ${fecha(u.bloqueadoHasta)}` : ''}. Los intentos vuelven a cero; la contraseña no cambia.`, onDesbloquear)}
          {!confirmando && (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="button" className="cv-btn cv-btn-primary" onClick={() => setConfirmando(true)}><MenuIcon name="lock" size={15} /> Desbloquear</button>
            </div>
          )}
        </div>
      )}

      {(accion === 'DESACTIVAR' || accion === 'ACTIVAR') && (
        <form className="ig-form ad-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
          <h4>{accion === 'DESACTIVAR' ? `Desactivar «${u.username}»` : `Activar «${u.username}»`}</h4>
          <label className="cv-field ad-campo">
            <span className="cv-label">Motivo{accion === 'DESACTIVAR' ? '' : ' (opcional)'}</span>
            <textarea rows={2} maxLength={300} value={motivoEstado} disabled={saving} required={accion === 'DESACTIVAR'} minLength={accion === 'DESACTIVAR' ? 10 : undefined}
              placeholder={accion === 'DESACTIVAR' ? 'Ej.: concluyó su función de miembro de mesa; cese del docente…' : 'Ej.: vuelve a integrar el CEUNP'}
              onChange={(e) => { setMotivoEstado(e.target.value); setConfirmando(false); }} />
            {accion === 'DESACTIVAR' && motivoEstado.trim().length > 0 && motivoEstado.trim().length < 10 && <small className="cv-error">Al menos 10 caracteres.</small>}
          </label>
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="submit" className={`cv-btn ${accion === 'DESACTIVAR' ? 'cv-btn-danger' : 'cv-btn-success'}`}
                disabled={saving || (accion === 'DESACTIVAR' && motivoEstado.trim().length < 10)}>
                <MenuIcon name={accion === 'DESACTIVAR' ? 'close' : 'check'} size={15} /> {accion === 'DESACTIVAR' ? 'Desactivar' : 'Activar'}
              </button>
            </div>
          ) : confirmar(
            accion === 'DESACTIVAR' ? `¿Desactivar la cuenta «${u.username}»?` : `¿Activar la cuenta «${u.username}»?`,
            accion === 'DESACTIVAR' ? 'No podrá iniciar sesión. Su historia en la bitácora se conserva y se puede reactivar.' : 'Podrá volver a iniciar sesión con su contraseña actual.',
            () => onEstado(accion === 'ACTIVAR'), accion === 'DESACTIVAR',
          )}
        </form>
      )}

      {accion === 'ELIMINAR' && (
        <div className="ig-form ad-form">
          {confirmar(`¿Eliminar definitivamente la cuenta «${u.username}»?`, 'No tiene actividad registrada, por eso se puede eliminar. Esta acción no se puede deshacer; la eliminación queda en la bitácora.', onEliminar, true)}
          {!confirmando && (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
              <button type="button" className="cv-btn cv-btn-danger" onClick={() => setConfirmando(true)}><MenuIcon name="trash" size={15} /> Eliminar</button>
            </div>
          )}
        </div>
      )}

      <div className="ad-actividad">
        <div>
          <h4>Administración de la cuenta</h4>
          {!actividad ? <p className="muted">Cargando…</p> : actividad.administracion.length === 0 ? <p className="muted">Sin cambios registrados.</p> : (
            <ul>{actividad.administracion.map((a) => (
              <li key={a.idLog}><strong>{ACCION_BITACORA[a.accion] ?? a.accion}</strong><small>{fecha(a.fechaHora)} · {a.realizadoPor ?? '—'}{detalleLog(a)}</small></li>
            ))}</ul>
          )}
        </div>
        <div>
          <h4>Últimas acciones del usuario</h4>
          {!actividad ? <p className="muted">Cargando…</p> : actividad.acciones.length === 0 ? <p className="muted">Sin actividad registrada.</p> : (
            <ul>{actividad.acciones.map((a) => (
              <li key={a.idLog}><strong>{ACCION_BITACORA[a.accion] ?? a.accion.replaceAll('_', ' ').toLowerCase()}</strong><small>{fecha(a.fechaHora)}{a.proceso ? ` · ${a.proceso}` : ''}{a.ipOrigen ? ` · ${a.ipOrigen}` : ''}</small></li>
            ))}</ul>
          )}
        </div>
      </div>
    </div>
  );
}

function detalleLog(a) {
  try {
    const d = JSON.parse(a.detalleJson ?? '{}');
    if (a.accion === 'ACTUALIZAR_USUARIO' && d.rol_anterior !== d.rol_nuevo) return ` · ${d.rol_anterior} → ${d.rol_nuevo}`;
    if (a.accion === 'CREAR_USUARIO') return ` · ${d.rol}`;
    if (d.motivo) return ` · ${d.motivo}`;
  } catch { /* detalle no JSON */ }
  return '';
}

// ─── 5-9 Ficha del parámetro: modificar y restaurar ─────────────────────────

function FichaParametro({ p, parametros, historial, cambio, setCambio, restauracion, setRestauracion, accion, setAccion, confirmando, setConfirmando, saving, onActualizar, onRestaurar, onCancelar, onCerrar }) {
  const bloqueado = si(p.bloqueado);
  const valor = String(cambio.valor ?? '').trim();
  const errorLocal = validarLocal(p, valor, parametros);
  const igual = valor === String(p.valor);
  const motivoOk = cambio.motivo.trim().length >= 10;
  const uit = Number(parametros.find((x) => x.clave === 'UIT')?.valor ?? 0);
  const previa = p.clave === 'UIT' || p.clave.endsWith('_PCT');
  const restaurable = (historial ?? []).filter((h) => h.valorAnterior != null);
  const elegido = restaurable.find((h) => h.idHistorial === restauracion.idHistorial);

  const set = (campo, v) => { setCambio((c) => ({ ...c, [campo]: v })); setConfirmando(false); };

  return (
    <div className="panel cv-form ad-ficha">
      <div className="cv-section-head">
        <div>
          <h3>5 modificarParametro · {p.etiqueta}</h3>
          <p className="muted"><code>{p.clave}</code> · {p.descripcion}{p.referencia ? ` · ${p.referencia}` : ''}</p>
        </div>
        <div className="cs-acciones-head">
          <button type="button" className="cv-btn cv-btn-ghost" onClick={onCerrar}><MenuIcon name="close" size={15} /> Cerrar</button>
        </div>
      </div>

      <div className="mu-parametros ad-param-datos">
        <div><span>Valor vigente</span><strong>{valorLegible(p)}</strong><small>{p.tipo === 'HORA' ? `valor ${p.valor}` : p.tipo.toLowerCase()}</small></div>
        <div><span>Rango permitido</span><strong className="ad-rango">{rango(p)}</strong><small>7 actualizarParametro</small></div>
        <div><span>Durante la votación</span><strong className="ad-rango">{si(p.bloqueoJornada) ? 'Bloqueado' : 'Editable'}</strong><small>{bloqueado ? 'Hay un proceso en votación' : 'Sin restricción ahora'}</small></div>
        <div><span>Cambios</span><strong>{p.cambios}</strong><small>{p.fechaUltimoCambio ? fecha(p.fechaUltimoCambio) : 'nunca'}</small></div>
      </div>

      {bloqueado ? (
        <div className="mx-mensaje aviso" role="note"><MenuIcon name="lock" size={18} /><div><p>Hay un proceso en votación: este parámetro de la jornada no se puede cambiar hasta el cierre del sufragio.</p></div></div>
      ) : accion !== 'RESTAURAR' && (
        <form className="ig-form ad-form" onSubmit={(e) => { e.preventDefault(); if (!errorLocal && !igual && motivoOk) { setAccion('PARAMETRO'); setConfirmando(true); } }}>
          <h4>6 actualizar · nuevo valor</h4>
          <div className="ig-grid">
            <label className="cv-field">
              <span className="cv-label">Nuevo valor{p.unidad ? ` (${p.unidad})` : ''}</span>
              {p.tipo === 'INDICADOR' ? (
                <select value={valor} disabled={saving} onChange={(e) => set('valor', e.target.value)}>
                  <option value="1">1 · Sí</option>
                  <option value="0">0 · No</option>
                </select>
              ) : p.tipo === 'TEXTO' ? (
                <input value={cambio.valor} maxLength={Number(p.maximo ?? 255)} disabled={saving} onChange={(e) => set('valor', e.target.value)} />
              ) : (
                <input type="number" inputMode="decimal" step={p.tipo === 'ENTERO' ? 1 : p.tipo === 'HORA' ? 0.25 : 0.01}
                  min={p.minimo ?? undefined} max={p.maximo ?? undefined} value={cambio.valor} disabled={saving} onChange={(e) => set('valor', e.target.value)} />
              )}
              {p.tipo === 'HORA' && valor && !errorLocal && <small className="muted">= {hora(valor)} h</small>}
              {errorLocal && <small className="cv-error">{errorLocal}</small>}
              {igual && !errorLocal && <small className="muted">Es el valor vigente.</small>}
            </label>
            {previa && !errorLocal && (
              <div className="cv-field ad-previa">
                <span className="cv-label">Vista previa de las multas</span>
                <PreviaMultas parametros={parametros} clave={p.clave} valor={valor} uit={uit} />
              </div>
            )}
            <label className="cv-field nl-ancho">
              <span className="cv-label">Motivo del cambio</span>
              <textarea rows={2} maxLength={500} value={cambio.motivo} disabled={saving} placeholder="Ej.: Resolución N.º 012-2026-CEUNP actualiza el plazo; nueva UIT 2027 (D.S.)…"
                onChange={(e) => set('motivo', e.target.value)} />
              {cambio.motivo.trim().length > 0 && !motivoOk && <small className="cv-error">Al menos 10 caracteres.</small>}
            </label>
          </div>
          {!confirmando ? (
            <div className="cv-actions">
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setCambio({ valor: p.valor, motivo: '' })}>Descartar</button>
              <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || !!errorLocal || igual || !motivoOk}><MenuIcon name="check" size={15} /> Actualizar</button>
            </div>
          ) : (
            <div className="cq-confirmar-emision" role="alert">
              <div>
                <strong>¿Cambiar «{p.etiqueta}» de {valorLegible(p)} a {valorLegible(p, valor)}?</strong>
                <span>7 actualizarParametro · 8 registrarAuditoria: rige desde ahora para todo el sistema y queda en el historial con su motivo.</span>
              </div>
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onActualizar}><MenuIcon name="check" size={15} /> {saving ? 'Guardando…' : 'Confirmar'}</button>
              </div>
            </div>
          )}
        </form>
      )}

      <div className="ad-grupo">
        <h4><MenuIcon name="refresh" size={15} /> Historial de «{p.etiqueta}» <small>restaure el valor que tenía antes de un cambio</small></h4>
        {!historial ? <p className="muted">Cargando…</p> : (
          <TablaHistorial filas={historial} parametros={parametros} conParametro={false}
            onRestaurar={bloqueado ? null : (h) => { setRestauracion({ idHistorial: h.idHistorial, motivo: '' }); setAccion('RESTAURAR'); }}
            activo={accion === 'RESTAURAR' ? restauracion.idHistorial : null} />
        )}
        {accion === 'RESTAURAR' && elegido && (
          <form className="ig-form ad-form" onSubmit={(e) => { e.preventDefault(); setConfirmando(true); }}>
            <h4>Restaurar {valorLegible(p, elegido.valorAnterior)} (valor anterior al cambio N.º {elegido.idHistorial})</h4>
            <label className="cv-field ad-campo">
              <span className="cv-label">Motivo de la restauración</span>
              <textarea rows={2} maxLength={500} value={restauracion.motivo} disabled={saving} placeholder="Ej.: se revierte el cambio por error de digitación"
                onChange={(e) => { setRestauracion((r) => ({ ...r, motivo: e.target.value })); setConfirmando(false); }} />
            </label>
            {String(elegido.valorAnterior) === String(p.valor) && <small className="cv-error">Ese es el valor vigente.</small>}
            {!confirmando ? (
              <div className="cv-actions">
                <button type="button" className="cv-btn cv-btn-ghost" onClick={onCancelar}>Cancelar</button>
                <button type="submit" className="cv-btn cv-btn-primary" disabled={saving || restauracion.motivo.trim().length < 10 || String(elegido.valorAnterior) === String(p.valor)}>
                  <MenuIcon name="refresh" size={15} /> Restaurar
                </button>
              </div>
            ) : (
              <div className="cq-confirmar-emision" role="alert">
                <div>
                  <strong>¿Volver «{p.etiqueta}» a {valorLegible(p, elegido.valorAnterior)}?</strong>
                  <span>El valor vigente {valorLegible(p)} se reemplaza; la restauración queda en el historial como un cambio más.</span>
                </div>
                <div className="cv-actions">
                  <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmando(false)}>Volver</button>
                  <button type="button" className="cv-btn cv-btn-success" disabled={saving} onClick={onRestaurar}><MenuIcon name="check" size={15} /> {saving ? 'Restaurando…' : 'Confirmar'}</button>
                </div>
              </div>
            )}
          </form>
        )}
      </div>
    </div>
  );
}

/** Misma validación que fn_validar_parametro, para avisar antes de enviar. */
function validarLocal(p, v, parametros) {
  if (v === '') return 'Indique un valor.';
  if (p.tipo === 'TEXTO') {
    if (p.minimo != null && v.length < p.minimo) return `Al menos ${Math.round(p.minimo)} caracteres.`;
    if (p.maximo != null && v.length > p.maximo) return `Hasta ${Math.round(p.maximo)} caracteres.`;
    return null;
  }
  if (p.tipo === 'INDICADOR') return ['0', '1'].includes(v) ? null : 'Solo 1 (sí) o 0 (no).';
  if (p.tipo === 'ENTERO' && !/^[0-9]+$/.test(v)) return 'Debe ser un número entero.';
  if (['DECIMAL', 'HORA'].includes(p.tipo) && !/^[0-9]+(\.[0-9]{1,4})?$/.test(v)) return 'Debe ser un número positivo (punto decimal).';
  const n = Number(v);
  if (p.minimo != null && n < p.minimo) return `No puede ser menor que ${p.tipo === 'HORA' ? hora(p.minimo) : Number(p.minimo)}.`;
  if (p.maximo != null && n > p.maximo) return `No puede ser mayor que ${p.tipo === 'HORA' ? hora(p.maximo) : Number(p.maximo)}.`;
  const otra = (c) => Number(parametros.find((x) => x.clave === c)?.valor);
  if (p.clave === 'INSTALACION_HORA_INICIO' && n >= otra('INSTALACION_HORA_LIMITE')) return `Debe ser anterior a la hora límite (${hora(otra('INSTALACION_HORA_LIMITE'))}).`;
  if (p.clave === 'INSTALACION_HORA_LIMITE' && n <= otra('INSTALACION_HORA_INICIO')) return `Debe ser posterior a la hora de inicio (${hora(otra('INSTALACION_HORA_INICIO'))}).`;
  return null;
}

function PreviaMultas({ parametros, clave, valor, uit }) {
  const val = (c) => (c === clave ? Number(valor) : Number(parametros.find((x) => x.clave === c)?.valor ?? 0));
  const base = clave === 'UIT' ? Number(valor) : uit;
  const soles = (n) => `S/ ${n.toLocaleString('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  return (
    <div className="ad-previa-multas">
      <div><span>Elector omiso ({val('MULTA_ELECTOR_OMISO_PCT')} %)</span><strong>{soles(base * val('MULTA_ELECTOR_OMISO_PCT') / 100)}</strong></div>
      <div><span>Miembro de mesa ({val('MULTA_MIEMBRO_MESA_OMISO_PCT')} %)</span><strong>{soles(base * val('MULTA_MIEMBRO_MESA_OMISO_PCT') / 100)}</strong></div>
    </div>
  );
}

function TablaHistorial({ filas, parametros, conParametro = true, onRestaurar, activo }) {
  const def = (c) => parametros.find((p) => p.clave === c);
  return (
    <div className="table-wrap">
      <table>
        <thead><tr><th>Fecha</th>{conParametro && <th>Parámetro</th>}<th>Cambio</th><th>Motivo</th><th>Usuario</th>{onRestaurar && <th />}</tr></thead>
        <tbody>
          {filas.map((h) => (
            <tr key={h.idHistorial} className={h.idHistorial === activo ? 'ad-fila-on' : ''}>
              <td>{fecha(h.fecha)}<small className="pd-sub">N.º {h.idHistorial}</small></td>
              {conParametro && <td><strong>{h.etiqueta}</strong><small className="pd-sub"><code>{h.clave}</code></small></td>}
              <td className="ad-cambio"><s>{h.valorAnterior == null ? '—' : valorLegible(def(h.clave), h.valorAnterior)}</s> → <strong>{valorLegible(def(h.clave), h.valorNuevo)}</strong></td>
              <td>{h.motivo}</td>
              <td>{h.username ?? <span className="muted">—</span>}<small className="pd-sub">{ORIGEN[h.origen] ?? h.origen}{h.ip ? ` · ${h.ip}` : ''}</small></td>
              {onRestaurar && (
                <td className="n">{h.valorAnterior != null && (
                  <button type="button" className="cv-btn cv-btn-soft" onClick={() => onRestaurar(h)} title="Restaurar el valor anterior a este cambio">
                    <MenuIcon name="refresh" size={14} /> Restaurar
                  </button>
                )}</td>
              )}
            </tr>
          ))}
          {filas.length === 0 && <tr><td colSpan={onRestaurar ? 6 : 5} className="muted">Sin cambios registrados.</td></tr>}
        </tbody>
      </table>
    </div>
  );
}
