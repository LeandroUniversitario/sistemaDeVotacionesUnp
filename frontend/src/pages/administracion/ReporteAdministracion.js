import { fecha } from '../credenciales/LectorQR';
import { esc, imprimir } from '../computo/ActaComputo';

/**
 * CUS18 · Impresiones de la administración: ficha de acceso con la contraseña provisional
 * (4 mostrarUsuario), parámetros vigentes con su historial (9 confirmarCambio, 8 registrarAuditoria)
 * y constancia del respaldo de la base con su huella SHA-256 (13 mostrarRespaldo). Mismo formato
 * de hoja que las actas del CUS14.
 */

export const ROL = {
  ADMIN: 'Administrador del sistema',
  CEUNP: 'Comité Electoral (CEUNP)',
  DOCENTE: 'Docente elector',
  PERSONERO: 'Personero',
  MIEMBRO_MESA: 'Miembro de mesa',
};
export const ROL_CORTO = { ADMIN: 'Admin', CEUNP: 'CEUNP', DOCENTE: 'Docente', PERSONERO: 'Personero', MIEMBRO_MESA: 'Miembro de mesa' };
export const ROL_NOTA = {
  ADMIN: 'Cuentas, parámetros, bitácora y respaldos. Docente opcional.',
  CEUNP: 'Conduce el proceso electoral. Docente opcional.',
  DOCENTE: 'Vota, presenta tachas y consulta sus multas. Requiere docente.',
  PERSONERO: 'Fiscaliza la mesa e impugna. Requiere docente acreditado (CUS05).',
  MIEMBRO_MESA: 'Instala, verifica, cierra y escruta. Requiere docente sorteado (CUS06).',
};
export const ROLES_CON_DOCENTE = ['DOCENTE', 'PERSONERO', 'MIEMBRO_MESA'];
export const GRUPO = {
  MULTAS: { texto: 'Multas', nota: 'UIT, porcentajes y plazo de justificación (RF105, RN35)', icono: 'coins' },
  JORNADA: { texto: 'Jornada electoral', nota: 'Mesas, lugar y horarios (RN06-RN08)', icono: 'calendar' },
  CEUNP: { texto: 'Pleno y plazos del CEUNP', nota: 'Quórum, apelación y segunda vuelta (RN33, RN36)', icono: 'scale' },
  SEGURIDAD: { texto: 'Seguridad del acceso', nota: 'Intentos, bloqueo y contraseñas', icono: 'lock' },
  OTROS: { texto: 'Otros parámetros', nota: 'Sin definición en el catálogo', icono: 'settings' },
};
export const ORIGEN = { PANTALLA: 'Pantalla', RESTAURACION: 'Restauración', BASE_DATOS: 'Directo en la base' };

/** Hora decimal (9.5) como 09:30. */
export const hora = (v) => {
  const n = Number(v);
  if (Number.isNaN(n)) return String(v ?? '');
  const h = Math.floor(n);
  const m = Math.round((n - h) * 60);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
};

/** Valor del parámetro legible: hora, sí/no o número con su unidad. */
export function valorLegible(p, valor = p?.valor) {
  if (valor == null || valor === '') return '—';
  switch (p?.tipo) {
    case 'HORA': return `${hora(valor)} h`;
    case 'INDICADOR': return String(valor) === '1' ? 'Sí' : 'No';
    case 'TEXTO': return String(valor);
    default:
      if (p?.unidad === 'S/') return `S/ ${Number(valor).toLocaleString('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
      return `${valor}${p?.unidad ? ` ${p.unidad}` : ''}`;
  }
}

export const bytes = (n) => {
  const v = Number(n ?? 0);
  if (v < 1024) return `${v} B`;
  if (v < 1024 * 1024) return `${(v / 1024).toFixed(1)} KB`;
  return `${(v / 1024 / 1024).toFixed(2)} MB`;
};

const encabezado = (titulo, subtitulo, sello) => `
  <header>
    <div>
      <p>Universidad Nacional de Piura · Sistema de Elecciones Docentes (SICEUNP)</p>
      <h1>${esc(titulo)}</h1>
      <p>${subtitulo}</p>
      ${sello ?? ''}
    </div>
  </header>`;

const firmas = (izq, der) => `
  <div class="firmas" style="grid-template-columns: repeat(2, 1fr);">
    <div class="firma"><div class="linea"></div><strong>${esc(izq)}</strong><span>Entrega</span></div>
    <div class="firma"><div class="linea"></div><strong>${esc(der)}</strong><span>Recibe</span></div>
  </div>`;

/** 4 mostrarUsuario(): ficha que el Admin entrega al titular de la cuenta con su contraseña provisional. */
export function imprimirFichaAcceso(u, clave, politica, admin) {
  imprimir(`Ficha de acceso · ${u.username}`, `
    <section class="hoja">
      ${encabezado('Ficha de acceso al sistema', `Cuenta ${esc(u.username)} · ${esc(ROL[u.rol] ?? u.rol)}`,
        `<span class="sello ${u.activo ? 'ok' : 'nulo'}">${u.activo ? 'Cuenta activa' : 'Cuenta inactiva'}</span>`)}
      <dl>
        <div><dt>Usuario</dt><dd>${esc(u.username)}</dd></div>
        <div><dt>Rol</dt><dd>${esc(ROL[u.rol] ?? u.rol)}</dd></div>
        <div><dt>Docente</dt><dd>${u.docente ? `${esc(u.docente)}<br><small>DNI ${esc(u.dni)}</small>` : '—'}</dd></div>
        <div><dt>Facultad</dt><dd>${esc(u.facultad ?? '—')}</dd></div>
      </dl>
      ${clave ? `
      <div class="credencial">
        <p>Contraseña provisional</p>
        <span class="codigo">${esc(clave)}</span>
        <p class="texto" style="margin-top:4mm;text-align:center">Al primer ingreso el sistema le pedirá elegir una contraseña nueva de al menos
          ${esc(politica?.passwordMin ?? 8)} caracteres. Tras ${esc(politica?.intentosMaximos ?? 5)} intentos fallidos la cuenta se bloquea
          ${esc(politica?.bloqueoMinutos ?? 15)} minutos.</p>
      </div>` : '<p class="texto">La contraseña no se imprime: el titular la eligió al ingresar. Si la olvidó, el administrador la restablece.</p>'}
      <h2>Condiciones de uso</h2>
      <p class="texto">La cuenta es personal e intransferible. Toda acción queda registrada en la bitácora de auditoría con el usuario,
        la fecha y la dirección de origen (RN28). No comparta la contraseña ni deje la sesión abierta en equipos de uso común.</p>
      ${firmas(admin || 'Administrador del sistema', u.docente || u.username)}
      <footer>Emitida el ${esc(fecha(new Date()))} · cuenta creada el ${esc(fecha(u.fechaCreacion))}${u.creadoPor ? ` por ${esc(u.creadoPor)}` : ''}</footer>
    </section>`);
}

/** Parámetros vigentes agrupados y los últimos cambios del historial. */
export function imprimirParametros(parametros, historial, jornada) {
  const grupos = Object.keys(GRUPO).filter((g) => parametros.some((p) => p.grupo === g));
  imprimir('Parámetros del sistema', `
    <section class="hoja">
      ${encabezado('Parámetros vigentes del sistema', `${parametros.length} parámetros · ${jornada?.length ? 'jornada electoral en curso' : 'sin votación en curso'}`)}
      ${grupos.map((g) => `
        <h2>${esc(GRUPO[g].texto)} <small>· ${esc(GRUPO[g].nota)}</small></h2>
        <table><thead><tr><th>Parámetro</th><th>Clave</th><th class="n">Valor</th><th>Rango</th><th>Norma</th><th>Último cambio</th></tr></thead>
          <tbody>${parametros.filter((p) => p.grupo === g).map((p) => `<tr>
            <td>${esc(p.etiqueta)}${Number(p.bloqueoJornada) ? '<br><small>Bloqueado durante la votación</small>' : ''}</td>
            <td><small>${esc(p.clave)}</small></td><td class="n">${esc(valorLegible(p))}</td>
            <td>${p.minimo != null ? `${esc(p.tipo === 'HORA' ? hora(p.minimo) : p.minimo)} a ${esc(p.tipo === 'HORA' ? hora(p.maximo) : p.maximo)}` : '—'}</td>
            <td>${esc(p.referencia ?? '—')}</td>
            <td>${p.fechaUltimoCambio ? `${esc(fecha(p.fechaUltimoCambio))}<br><small>${esc(p.modificadoPor ?? 'en la base')}</small>` : '—'}</td>
          </tr>`).join('')}</tbody></table>`).join('')}
      <h2>Últimos cambios (historial)</h2>
      ${historial.length ? `<table><thead><tr><th>Fecha</th><th>Parámetro</th><th>Anterior</th><th>Nuevo</th><th>Motivo</th><th>Usuario</th></tr></thead>
        <tbody>${historial.map((h) => `<tr><td>${esc(fecha(h.fecha))}</td><td>${esc(h.etiqueta)}</td><td>${esc(h.valorAnterior ?? '—')}</td>
          <td><strong>${esc(h.valorNuevo)}</strong></td><td>${esc(h.motivo ?? '')}</td><td>${esc(h.username ?? ORIGEN[h.origen])}</td></tr>`).join('')}</tbody></table>`
        : '<p class="texto">Sin cambios registrados.</p>'}
      <footer>Impreso el ${esc(fecha(new Date()))}</footer>
    </section>`);
}

/** 13 mostrarRespaldo(): constancia del respaldo con su huella SHA-256 (y la última verificación). */
export function imprimirConstanciaRespaldo(r, verificacion) {
  const v = verificacion?.idRespaldo === r.idRespaldo ? verificacion : null;
  imprimir(`Constancia de respaldo · ${r.nombreArchivo}`, `
    <section class="hoja">
      ${encabezado('Constancia de respaldo de la base de datos', `N.º ${esc(r.idRespaldo)} · ${esc(r.nombreArchivo)}`,
        v ? `<span class="sello ${v.resultado === 'INTEGRO' ? 'ok' : 'nulo'}">${v.resultado === 'INTEGRO' ? 'Archivo íntegro' : v.resultado === 'ALTERADO' ? 'Archivo alterado' : 'Archivo no encontrado'}</span>` : '')}
      <dl>
        <div><dt>Generado</dt><dd>${esc(fecha(r.fechaFin))}</dd></div>
        <div><dt>Por</dt><dd>${esc(r.username)}</dd></div>
        <div><dt>Duración</dt><dd>${esc(r.duracionSeg ?? 0)} s</dd></div>
        <div><dt>Tamaño</dt><dd>${esc(bytes(r.tamanoBytes))}</dd></div>
        <div><dt>Tablas</dt><dd>${esc(r.tablas)}</dd></div>
        <div><dt>Filas</dt><dd>${esc(r.filas)}</dd></div>
        <div><dt>Vistas y rutinas</dt><dd>${esc(r.vistas)} · ${esc(r.rutinas)}</dd></div>
        <div><dt>Triggers</dt><dd>${esc(r.disparadores)}</dd></div>
      </dl>
      ${r.motivo ? `<h2>Motivo</h2><p class="texto">${esc(r.motivo)}</p>` : ''}
      <h2>Huella SHA-256 del archivo</h2>
      <p class="texto" style="font-family:ui-monospace,monospace;word-break:break-all">${esc(r.hashSha256)}</p>
      ${v ? `<p class="texto">Verificado el ${esc(fecha(v.fecha))}: huella recalculada ${esc(v.hashCalculado ?? '—')}.</p>` : ''}
      <h2>Restauración</h2>
      <p class="texto">En phpMyAdmin elija la base <strong>elecciones_unp</strong> y use «Importar» con este archivo, o ejecute
        <code>mysql -u root elecciones_unp &lt; ${esc(r.nombreArchivo)}</code>. Antes compruebe que la huella del archivo coincide
        con la de esta constancia («Verificar integridad» en la pantalla). La restauración reemplaza las tablas, vistas y rutinas.</p>
      ${firmas(r.username, 'Custodio del respaldo')}
      <footer>Impresa el ${esc(fecha(new Date()))}</footer>
    </section>`);
}
