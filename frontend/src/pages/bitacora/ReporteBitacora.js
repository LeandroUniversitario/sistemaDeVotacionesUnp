import { fecha } from '../credenciales/LectorQR';
import { esc, imprimir } from '../computo/ActaComputo';
import { ROL } from '../administracion/ReporteAdministracion';

/**
 * CUS19 · Etiquetas de la bitácora e impresiones: reporte de los registros filtrados
 * (5 mostrarRegistros), ficha de un registro con su detalle JSON (9 mostrarDetalleJSON) y
 * constancia de la verificación de la cadena de sellos. Mismo formato de hoja que las actas del CUS14.
 */

export const MODULO = {
  SEGURIDAD: { texto: 'Seguridad del acceso', corto: 'Seguridad', color: '#e11d48', icono: 'lock' },
  ADMINISTRACION: { texto: 'Administración del sistema', corto: 'Administración', color: '#7c3aed', icono: 'settings' },
  PREPARACION: { texto: 'Preparación del proceso', corto: 'Preparación', color: '#2563eb', icono: 'calendar' },
  JORNADA: { texto: 'Jornada electoral', corto: 'Jornada', color: '#0d9488', icono: 'vote' },
  ESCRUTINIO: { texto: 'Escrutinio', corto: 'Escrutinio', color: '#0891b2', icono: 'table' },
  RECURSOS: { texto: 'Impugnaciones y nulidades', corto: 'Recursos', color: '#ea580c', icono: 'scale' },
  RESULTADOS: { texto: 'Cómputo y resultados', corto: 'Resultados', color: '#059669', icono: 'trophy' },
  MULTAS: { texto: 'Omisos y multas', corto: 'Multas', color: '#d97706', icono: 'coins' },
  SIN_CLASIFICAR: { texto: 'Sin clasificar', corto: 'Sin clasificar', color: '#64748b', icono: 'info' },
};
export const CRITICIDAD = {
  BAJA: { texto: 'Baja', color: '#64748b', nota: 'Operación habitual' },
  MEDIA: { texto: 'Media', color: '#2563eb', nota: 'Cambia datos del proceso' },
  ALTA: { texto: 'Alta', color: '#d97706', nota: 'Decisión o cambio sensible' },
  CRITICA: { texto: 'Crítica', color: '#e11d48', nota: 'Irreversible o afecta el resultado' },
};
export const ANOMALIA = {
  CONTENIDO_ALTERADO: 'Contenido alterado',
  ENLACE_ROTO: 'Enlace roto (registro faltante o insertado)',
  SIN_SELLO: 'Sin sello',
  FINAL_ELIMINADO: 'Registros finales eliminados',
};
export const ESTADO_CADENA = {
  INTEGRA: { texto: 'Íntegra', clase: 'votacion' },
  ALTERADA: { texto: 'Alterada', clase: 'anulado' },
  VACIA: { texto: 'Vacía', clase: 'creado' },
};

export const si = (v) => v === true || v === 1 || v === '1';
export const rolTexto = (r) => (r ? (ROL[r] ?? r) : 'Sin cuenta');

/** Navegador y sistema a partir del user-agent. */
export function navegador(ua) {
  if (!ua) return null;
  const nav = /Edg\//.test(ua) ? 'Edge' : /OPR\//.test(ua) ? 'Opera' : /Firefox\//.test(ua) ? 'Firefox'
    : /Chrome\//.test(ua) ? 'Chrome' : /Safari\//.test(ua) ? 'Safari' : /curl|Postman|Java|python/i.test(ua) ? 'Cliente técnico' : 'Otro';
  const so = /Windows/.test(ua) ? 'Windows' : /Android/.test(ua) ? 'Android' : /iPhone|iPad/.test(ua) ? 'iOS'
    : /Mac OS X/.test(ua) ? 'macOS' : /Linux/.test(ua) ? 'Linux' : '';
  return so ? `${nav} · ${so}` : nav;
}

/** Detalle JSON como pares legibles (claves con guion bajo → texto). */
export function pares(obj, prefijo = '') {
  if (obj == null || typeof obj !== 'object') return [[prefijo || 'valor', obj]];
  return Object.entries(obj).flatMap(([k, v]) => {
    const clave = prefijo ? `${prefijo} › ${k}` : k;
    if (v && typeof v === 'object' && !Array.isArray(v)) return pares(v, clave);
    return [[clave, Array.isArray(v) ? v.map((x) => (typeof x === 'object' ? JSON.stringify(x) : x)).join(', ') : v]];
  });
}

export const claveLegible = (k) => String(k).replace(/_/g, ' ').replace(/^id /, 'N.º ').replace(/\bid\b/g, 'N.º');

const encabezado = (titulo, subtitulo, sello) => `
  <header>
    <div>
      <p>Universidad Nacional de Piura · Sistema de Elecciones Docentes (SICEUNP)</p>
      <h1>${esc(titulo)}</h1>
      <p>${subtitulo}</p>
      ${sello ?? ''}
    </div>
  </header>`;

/** Texto de los filtros aplicados para el encabezado del reporte. */
export function textoFiltros(f, acciones, usuarios, procesos) {
  if (!f) return 'Sin filtros';
  const partes = [];
  if (f.texto) partes.push(`texto «${f.texto}»`);
  if (f.idUsuario != null) partes.push(`usuario ${Number(f.idUsuario) === 0 ? 'sin cuenta' : (usuarios?.find((u) => u.idUsuario === Number(f.idUsuario))?.username ?? `#${f.idUsuario}`)}`);
  if (f.rol) partes.push(`rol ${f.rol === 'SIN_CUENTA' ? 'sin cuenta' : rolTexto(f.rol)}`);
  if (f.accion) partes.push(`acción ${acciones?.find((a) => a.codigo === f.accion)?.etiqueta ?? f.accion}`);
  if (f.modulo) partes.push(`módulo ${f.modulo.split(',').map((m) => MODULO[m]?.corto ?? m).join(', ')}`);
  if (f.criticidad) partes.push(`criticidad ${f.criticidad.split(',').map((c) => CRITICIDAD[c]?.texto ?? c).join(', ')}`);
  if (f.idProceso) partes.push(`proceso ${procesos?.find((p) => p.idProceso === Number(f.idProceso))?.nombre ?? `#${f.idProceso}`}`);
  if (f.idDocente) partes.push(`docente #${f.idDocente}`);
  if (f.ip) partes.push(`IP ${f.ip}`);
  if (f.desde) partes.push(`desde ${fecha(f.desde)}`);
  if (f.hasta) partes.push(`hasta ${fecha(f.hasta)}`);
  return partes.length ? partes.join(' · ') : 'Sin filtros';
}

/** 5 mostrarRegistros(): la página de registros filtrados con el resumen. */
export function imprimirRegistros(resultado, filtrosTexto, admin) {
  const r = resultado.resumen;
  imprimir('Reporte de la bitácora de auditoría', `
    <section class="hoja">
      ${encabezado('Reporte de la bitácora de auditoría', `${esc(filtrosTexto)} · ${esc(resultado.total)} registro(s)`)}
      ${r ? `<dl>
        <div><dt>Registros</dt><dd>${esc(r.total)}</dd></div>
        <div><dt>Cuentas distintas</dt><dd>${esc(r.usuarios)}${Number(r.sinCuenta) ? ` · ${esc(r.sinCuenta)} sin cuenta` : ''}</dd></div>
        <div><dt>Desde</dt><dd>${esc(fecha(r.primero))}</dd></div>
        <div><dt>Hasta</dt><dd>${esc(fecha(r.ultimo))}</dd></div>
      </dl>
      <h2>Por criticidad y módulo</h2>
      <p class="texto">${(r.porCriticidad ?? []).map((c) => `${esc(CRITICIDAD[c.valor]?.texto ?? c.valor)}: ${esc(c.total)}`).join(' · ')}<br>
        ${(r.porModulo ?? []).map((m) => `${esc(MODULO[m.valor]?.corto ?? m.valor)}: ${esc(m.total)}`).join(' · ')}</p>` : ''}
      <h2>Registros (página ${esc(resultado.pagina + 1)} de ${esc(resultado.paginas)}, ${resultado.orden === 'ASC' ? 'del más antiguo' : 'del más reciente'})</h2>
      <table><thead><tr><th class="n">N.º</th><th>Fecha y hora</th><th>Acción</th><th>Usuario</th><th>Referido a</th><th>IP</th></tr></thead>
        <tbody>${resultado.registros.map((x) => `<tr>
          <td class="n">${esc(x.idLog)}</td><td>${esc(fecha(x.fechaHora))}</td>
          <td>${esc(x.etiqueta)}<br><small>${esc(x.accion)} · ${esc(CRITICIDAD[x.criticidad]?.texto ?? x.criticidad)}</small></td>
          <td>${esc(x.username ?? 'Sin cuenta')}${x.rol ? `<br><small>${esc(rolTexto(x.rol))}</small>` : ''}</td>
          <td>${esc([x.docente, x.proceso].filter(Boolean).join(' · ') || '—')}</td><td>${esc(x.ipOrigen ?? '—')}</td>
        </tr>`).join('')}</tbody></table>
      <p class="texto">La bitácora es de solo lectura: ningún registro se modifica ni se borra. Cada registro lleva un sello SHA-256
        encadenado al anterior que permite comprobar que la información no fue alterada (RN28).</p>
      <footer>Impreso el ${esc(fecha(new Date()))} por ${esc(admin ?? 'el administrador')}</footer>
    </section>`);
}

/** 9 mostrarDetalleJSON(): ficha de un registro con su detalle y su sello. */
export function imprimirRegistro(d, admin) {
  const x = d.registro;
  const filas = d.detalle != null ? pares(d.detalle) : [];
  imprimir(`Registro N.º ${x.idLog} de la bitácora`, `
    <section class="hoja">
      ${encabezado(`Registro N.º ${x.idLog} de la bitácora`, `${esc(x.etiqueta)} · ${esc(fecha(x.fechaHora))}`,
        `<span class="sello ${si(x.contenidoIntegro) && si(x.enlaceValido) ? 'ok' : 'nulo'}">${si(x.contenidoIntegro) && si(x.enlaceValido) ? 'Sello válido' : 'Sello no válido'}</span>`)}
      <dl>
        <div><dt>Acción</dt><dd>${esc(x.etiqueta)}<br><small>${esc(x.accion)}</small></dd></div>
        <div><dt>Módulo</dt><dd>${esc(MODULO[x.modulo]?.texto ?? x.modulo)}${x.casoUso ? ` · ${esc(x.casoUso)}` : ''}</dd></div>
        <div><dt>Criticidad</dt><dd>${esc(CRITICIDAD[x.criticidad]?.texto ?? x.criticidad)}</dd></div>
        <div><dt>Usuario</dt><dd>${esc(x.username ?? 'Sin cuenta')}${x.rol ? `<br><small>${esc(rolTexto(x.rol))}</small>` : ''}</dd></div>
        <div><dt>Docente referido</dt><dd>${esc(x.docente ?? '—')}${x.dniDocente ? `<br><small>DNI ${esc(x.dniDocente)}</small>` : ''}</dd></div>
        <div><dt>Proceso</dt><dd>${esc(x.proceso ?? '—')}</dd></div>
        <div><dt>IP de origen</dt><dd>${esc(x.ipOrigen ?? '—')}</dd></div>
        <div><dt>Navegador</dt><dd>${esc(navegador(x.userAgent) ?? '—')}</dd></div>
      </dl>
      ${x.descripcionAccion ? `<p class="texto">${esc(x.descripcionAccion)}</p>` : ''}
      <h2>Detalle registrado</h2>
      ${filas.length ? `<table><tbody>${filas.map(([k, v]) => `<tr><th>${esc(claveLegible(k))}</th><td>${esc(v ?? '—')}</td></tr>`).join('')}</tbody></table>`
        : `<p class="texto">${x.detalleJson ? esc(x.detalleJson) : 'Sin detalle.'}</p>`}
      <h2>Sello SHA-256</h2>
      <p class="texto" style="font-family:ui-monospace,monospace;word-break:break-all">
        Anterior: ${esc(x.hashAnterior ?? '—')}<br>Registro: ${esc(x.hashRegistro ?? '—')}<br>Recalculado: ${esc(x.hashCalculado ?? '—')}</p>
      <p class="texto">Contenido ${si(x.contenidoIntegro) ? 'sin cambios desde que se registró' : 'ALTERADO después de registrarse'} ·
        enlace con el registro anterior ${si(x.enlaceValido) ? 'correcto' : 'ROTO'}.</p>
      <footer>Impreso el ${esc(fecha(new Date()))} por ${esc(admin ?? 'el administrador')}</footer>
    </section>`);
}

/** Constancia de la verificación de la cadena de sellos. */
export function imprimirVerificacion(v, cadena, admin) {
  const ok = v.estado === 'INTEGRA';
  imprimir('Constancia de verificación de la bitácora', `
    <section class="hoja">
      ${encabezado('Constancia de verificación de la bitácora', `Registro de verificación N.º ${esc(v.idLog)} · ${esc(fecha(v.fecha))}`,
        `<span class="sello ${ok ? 'ok' : 'nulo'}">${ok ? 'Bitácora íntegra' : v.estado === 'VACIA' ? 'Bitácora vacía' : 'Bitácora alterada'}</span>`)}
      <dl>
        <div><dt>Registros verificados</dt><dd>${esc(v.registros)}</dd></div>
        <div><dt>Anomalías</dt><dd>${esc(v.anomalias)}</dd></div>
        <div><dt>Primer registro anómalo</dt><dd>${esc(v.primerIdAnomalo ?? '—')}</dd></div>
        <div><dt>Inicio de la cadena</dt><dd>${esc(fecha(cadena?.sello?.fechaInicio))}</dd></div>
      </dl>
      <h2>Sello final de la cadena</h2>
      <p class="texto" style="font-family:ui-monospace,monospace;word-break:break-all">${esc(v.hashFinal ?? '—')}</p>
      ${v.detalle?.length ? `<h2>Anomalías encontradas</h2>
        <table><thead><tr><th class="n">Registro</th><th>Tipo</th><th>Acción</th><th>Fecha</th><th>Detalle</th></tr></thead>
        <tbody>${v.detalle.map((a) => `<tr><td class="n">${esc(a.idLog)}</td><td>${esc(ANOMALIA[a.tipo] ?? a.tipo)}</td>
          <td>${esc(a.accion ?? '—')}</td><td>${esc(fecha(a.fecha))}</td><td>${esc(a.detalle)}</td></tr>`).join('')}</tbody></table>` : ''}
      <h2>Método</h2>
      <p class="texto">Cada registro de la bitácora guarda el SHA-256 de su contenido (usuario, docente, proceso, acción, IP,
        navegador, fecha y detalle) unido al sello del registro anterior. La verificación recalcula todos los sellos en orden y
        compara el último con el sello vigente. Un registro modificado, eliminado o insertado por fuera del sistema rompe la cadena
        desde ese punto.</p>
      <div class="firmas" style="grid-template-columns: 1fr;">
        <div class="firma"><div class="linea"></div><strong>${esc(admin ?? 'Administrador del sistema')}</strong><span>Administrador del sistema</span></div>
      </div>
      <footer>Impresa el ${esc(fecha(new Date()))}</footer>
    </section>`);
}
