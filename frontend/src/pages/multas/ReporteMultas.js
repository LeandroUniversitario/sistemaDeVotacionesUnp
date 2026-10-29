import { svgQR, fecha } from '../credenciales/LectorQR';
import { esc, firmasPleno, imprimir } from '../computo/ActaComputo';
import { urlPublica } from '../../lib/urlPublica';

/**
 * CUS16 · Impresiones de omisos y multas: reporte de omisos (RF103, RF104), resolución del
 * Pleno que determina las multas con QR (RN35, RN36), cédulas de notificación a cada docente,
 * resolución del descargo (RF106) y reporte de gestión por mesa (RF107). El QR de la resolución
 * apunta a /verificar/{token} (portal del CUS17), que recalcula el SHA-256 de su contenido. Usa el mismo
 * formato de hoja que las actas del CUS14 y las resoluciones del CUS15.
 */

export const urlVerificacionMultas = (token) => urlPublica(`/verificar/${token}`);
export const soles = (v) => `S/ ${Number(v ?? 0).toLocaleString('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const pct = (v) => `${Number(v ?? 0).toFixed(2)} %`;

export const MOTIVO = {
  OMISO_VOTACION: 'Omisión al sufragio',
  OMISO_MESA: 'Inasistencia a la mesa',
};
export const MOTIVO_BASE = {
  OMISO_VOTACION: 'Art. 68 · RF103',
  OMISO_MESA: 'Art. 67 · RF104',
};
export const ROL = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal', SUPLENTE: 'Suplente' };
export const ESTADO_MULTA = {
  PENDIENTE: 'Pendiente',
  PAGADA: 'Pagada',
  JUSTIFICADA: 'Justificada',
  EXONERADA: 'Exonerada',
};
export const CAUSAL_DESCARGO = {
  SALUD: 'Enfermedad o atención médica',
  DUELO: 'Fallecimiento de un familiar',
  COMISION_SERVICIO: 'Comisión de servicio',
  LICENCIA: 'Licencia o vacaciones',
  CASO_FORTUITO: 'Caso fortuito o fuerza mayor',
  FALLECIMIENTO: 'Fallecimiento del docente',
  ERROR_PADRON: 'Error en el padrón o la mesa',
  OTRA: 'Otra causa que admita el CEUNP',
};
export const MEDIO = {
  CORREO_INSTITUCIONAL: 'Correo institucional',
  CEDULA_PERSONAL: 'Cédula personal',
  PORTAL_ELECTORAL: 'Portal electoral',
};

const encabezado = (titulo, subtitulo, sello, token) => `
  <header>
    <div>
      <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
      <h1>${esc(titulo)}</h1>
      <p>${subtitulo}</p>
      ${sello ?? ''}
    </div>
    ${token ? `<div class="qr">${svgQR(urlVerificacionMultas(token))}Verificación de la resolución</div>` : ''}
  </header>`;

const filaOmiso = (o, i, conEstado) => `<tr>
  <td class="n">${i + 1}</td><td>${esc(o.dni)}</td><td>${esc(o.docente)}<br><small>${esc(o.facultad ?? '')}</small></td>
  <td>${esc(MOTIVO[o.motivo] ?? o.motivo)}${o.rolMesa ?? o.rol ? ` · ${esc(ROL[o.rolMesa ?? o.rol] ?? o.rolMesa ?? o.rol)}` : ''}${o.asistioSinVotar === true || o.asistio_sin_votar === 'true' ? '<br><small>Asistió y no votó</small>' : ''}</td>
  <td>${esc(o.numeroMesa ?? o.mesa ?? '—')}</td>
  <td class="n">${soles(o.monto ?? o.montoEstimado)}</td>
  ${conEstado ? `<td>${esc(ESTADO_MULTA[o.estadoPago] ?? o.estadoPago ?? '')}</td>` : ''}
</tr>`;

/** 1 solicitarReporteOmisos(): relación de omisos con el monto vigente (o de las multas generadas). */
export function imprimirReporteOmisos(detalle) {
  const p = detalle.proceso;
  const par = detalle.parametros ?? {};
  const generadas = detalle.multas?.length > 0;
  const filas = generadas ? detalle.multas : detalle.omisos;
  const votacion = filas.filter((o) => o.motivo === 'OMISO_VOTACION');
  const mesa = filas.filter((o) => o.motivo === 'OMISO_MESA');
  const total = filas.reduce((s, o) => s + Number(o.monto ?? o.montoEstimado ?? 0), 0);
  const tabla = (lista) => (lista.length
    ? `<table><thead><tr><th class="n">N.º</th><th>DNI</th><th>Docente</th><th>Motivo</th><th>Mesa</th><th class="n">Multa</th>${generadas ? '<th>Estado</th>' : ''}</tr></thead>
       <tbody>${lista.map((o, i) => filaOmiso(o, i, generadas)).join('')}</tbody></table>`
    : '<p class="texto">Sin omisos.</p>');
  imprimir(`Reporte de omisos · ${p.nombre}`, `
    ${encabezado('Reporte de omisos y multas', `${esc(p.nombre)} · ${p.tipo === 'SEGUNDA_VUELTA' ? 'Segunda vuelta' : 'Primera vuelta'}`,
      `<span class="sello">${detalle.reporte?.estado === 'RESUELTO' ? `Resolución ${esc(detalle.reporte.numeroResolucion)}` : generadas ? 'Multas generadas · sin resolución' : 'Vista previa'}</span>`)}
    <dl>
      <div><dt>UIT de referencia</dt><dd>${soles(generadas ? detalle.reporte?.uitReferencia : par.uit)}</dd></div>
      <div><dt>Omisos al sufragio (2.5 %)</dt><dd>${votacion.length}</dd></div>
      <div><dt>Miembros inasistentes (3 %)</dt><dd>${mesa.length}</dd></div>
      <div><dt>Monto total</dt><dd>${soles(total)}</dd></div>
    </dl>
    ${detalle.participacion ? `<p class="texto" style="margin-top:4mm">Participación: ${esc(detalle.participacion.votaron)} de ${esc(detalle.participacion.electoresHabiles)} electores hábiles (${pct(detalle.participacion.participacionPct)}). No figuran los electores de las mesas que no se instalaron, porque no pudieron votar (RF58).</p>` : ''}
    <h2>Miembros titulares de mesa que no asistieron (Art. 67 · RF104)</h2>${tabla(mesa)}
    <h2>Docentes que no votaron (Art. 68 · RF103)</h2>${tabla(votacion)}
    <p class="texto">El sistema determina las multas; no las cobra. Todo lo no previsto lo resuelve el CEUNP (RN40).</p>
    ${firmasPleno()}
    <footer>Emitido el ${esc(fecha(new Date()))}.</footer>`);
}

/** 7 mostrarReporteMultas(): resolución del Pleno que determina las multas, con QR. */
export function imprimirResolucionMultas(r, token) {
  const d = r.documento ?? {};
  const multas = d.multas ?? [];
  const votacion = multas.filter((m) => m.motivo === 'OMISO_VOTACION');
  const mesa = multas.filter((m) => m.motivo === 'OMISO_MESA');
  const tabla = (lista) => (lista.length
    ? `<table><thead><tr><th class="n">N.º</th><th>DNI</th><th>Docente</th><th>Mesa</th><th class="n">%</th><th class="n">Multa</th></tr></thead><tbody>${lista.map((m, i) => `<tr><td class="n">${i + 1}</td><td>${esc(m.dni)}</td><td>${esc(m.docente)}<br><small>${esc(m.facultad)}${m.rol ? ` · ${esc(ROL[m.rol] ?? m.rol)}` : ''}${m.asistio_sin_votar === 'true' ? ' · asistió y no votó' : ''}</small></td><td>${esc(m.mesa ?? '—')}</td><td class="n">${esc(m.porcentaje)}</td><td class="n">${soles(m.monto)}</td></tr>`).join('')}</tbody></table>`
    : '<p class="texto">Ninguno.</p>');
  imprimir(`Resolución ${d.resolucion}`, `
    ${encabezado(`Resolución N.º ${d.resolucion}`, `${esc(d.proceso)} · ${d.vuelta === 'SEGUNDA_VUELTA' ? 'Segunda vuelta' : 'Primera vuelta'}`,
      '<span class="sello nulo">Determinación de multas (RN35)</span>', token)}
    <dl>
      <div><dt>Fecha</dt><dd>${esc(fecha(d.fecha))}</dd></div>
      <div><dt>Pleno (RN36)</dt><dd>${esc(d.pleno?.miembros)} miembros · quórum ${esc(d.pleno?.quorum)}</dd></div>
      <div><dt>UIT</dt><dd>${soles(d.uit)}</dd></div>
      <div><dt>Monto total</dt><dd>${soles(d.monto_total)}</dd></div>
    </dl>
    <p class="texto" style="margin-top:4mm"><strong>VISTO</strong> el reporte de omisos del proceso «${esc(d.proceso)}»${d.participacion ? `, en el que votaron ${esc(d.participacion.votaron)} de ${esc(d.participacion.electores)} electores hábiles (${pct(d.participacion.porcentaje)})` : ''}.</p>
    <p class="texto"><strong>CONSIDERANDO:</strong> ${esc(d.fundamento)} El artículo 67 sanciona al miembro de mesa que no asiste con el ${esc(d.porcentaje_miembro)} % de la UIT (${soles(d.monto_miembro)}) y el artículo 68 al docente que no vota con el ${esc(d.porcentaje_elector)} % de la UIT (${soles(d.monto_elector)}).</p>
    <p class="texto"><strong>SE RESUELVE:</strong> determinar ${esc(d.omisos_mesa)} multa(s) por inasistencia a la mesa y ${esc(d.omisos_votacion)} por omisión al sufragio, por un total de ${soles(d.monto_total)}, según la relación siguiente, y notificarlas a los docentes. El docente puede presentar su justificación al CEUNP (Disp. Final 2.ª y 5.ª).</p>
    <h2>Miembros titulares de mesa que no asistieron</h2>${tabla(mesa)}
    <h2>Docentes que no votaron</h2>${tabla(votacion)}
    <p class="texto">${esc(d.nota ?? '')}</p>
    ${firmasPleno()}
    <footer>Huella SHA-256 de la resolución: ${esc(r.hashIntegridad)}${token ? '' : ' · Reimpresión sin QR: el código solo se entrega al emitir la resolución.'}</footer>`);
}

/** Notificación de la multa: una cédula por docente. */
export function imprimirNotificaciones(proceso, reporte, multas, plazo, token) {
  const hojas = multas.map((m) => `<section class="hoja">
    ${encabezado(`Cédula de notificación · multa N.º ${String(m.idMulta).padStart(5, '0')}`, esc(proceso.nombre), `<span class="sello nulo">${esc(MOTIVO[m.motivo])}</span>`, token)}
    <p style="margin-top:6mm">Piura, ${esc(fecha(m.fechaNotificacion ?? new Date()))}</p>
    <p><strong>Señor(a) docente:</strong><br>${esc(m.docente)} · DNI ${esc(m.dni)}<br>${esc(m.facultad)}${m.departamento ? ` · ${esc(m.departamento)}` : ''}${m.email ? `<br>${esc(m.email)}` : ''}</p>
    <p class="texto">Por Resolución N.º ${esc(reporte.numeroResolucion)} del ${esc(fecha(reporte.fechaResolucion))}, el Comité Electoral determinó a su nombre una multa por <strong>${esc((MOTIVO[m.motivo] ?? '').toLowerCase())}</strong>${m.motivo === 'OMISO_MESA' ? `, como ${esc((ROL[m.rolMesa] ?? 'miembro').toLowerCase())} titular de la mesa ${esc(m.numeroMesa)}` : m.numeroMesa ? ` en la mesa ${esc(m.numeroMesa)}` : ''} (${esc(MOTIVO_BASE[m.motivo])}).</p>
    <dl>
      <div><dt>UIT de referencia</dt><dd>${soles(m.uitReferencia)}</dd></div>
      <div><dt>Porcentaje</dt><dd>${esc(m.porcentajeUit)} %</dd></div>
      <div><dt>Monto</dt><dd>${soles(m.monto)}</dd></div>
      <div><dt>Estado</dt><dd>${esc(ESTADO_MULTA[m.estadoPago] ?? m.estadoPago)}</dd></div>
    </dl>
    <p class="texto" style="margin-top:4mm">Si tuvo un impedimento justificado, puede presentar su justificación con los documentos que la sustenten ante el CEUNP${plazo > 0 ? ` dentro de los ${esc(plazo)} días siguientes a esta notificación` : ''} (Disp. Final 2.ª y 5.ª). El pago se realiza en Tesorería de la Universidad; el sistema electoral no cobra la multa.</p>
    <div class="firmas">
      <div class="firma"><div class="linea"></div><strong>Secretario del CEUNP</strong><span>Notificador</span></div>
      <div class="firma"><div class="linea"></div><strong>${esc(m.docente)}</strong><span>Recibí conforme · fecha y hora</span></div>
      <div class="firma"><div class="linea"></div><strong>${esc(m.medioNotificacion ? MEDIO[m.medioNotificacion] : 'Medio de notificación')}</strong><span>${esc(m.documentoNotificacion ?? '')}</span></div>
    </div>
    <footer>Huella SHA-256 de la resolución: ${esc(reporte.hashIntegridad)}</footer>
  </section>`).join('');
  imprimir(`Notificaciones · ${proceso.nombre}`, hojas || '<p>No hay multas por notificar.</p>');
}

/** 9 justificar() / 11 confirmar(): resolución del CEUNP sobre el descargo de una multa. */
export function imprimirDescargo(m, j) {
  const exoneracion = j.tipo === 'EXONERACION';
  const admitida = j.decision === 'ADMITIDA';
  imprimir(`Resolución ${j.numeroResolucion}`, `
    ${encabezado(`Resolución N.º ${j.numeroResolucion}`, `${esc(m.proceso)} · multa N.º ${String(m.idMulta).padStart(5, '0')}`,
      `<span class="sello ${admitida ? 'ok' : 'nulo'}">${exoneracion ? 'Exoneración de oficio (RN40)' : `Justificación ${admitida ? 'admitida' : 'denegada'} (RF106)`}</span>`)}
    <dl>
      <div><dt>Fecha</dt><dd>${esc(fecha(j.fechaResolucion))}</dd></div>
      <div><dt>Docente</dt><dd>${esc(m.docente)} · ${esc(m.dni)}</dd></div>
      <div><dt>Multa</dt><dd>${esc(MOTIVO[m.motivo])} · ${soles(m.monto)}</dd></div>
      <div><dt>Pleno (RN36)</dt><dd>${esc(j.miembrosPleno)} miembros</dd></div>
    </dl>
    <p class="texto" style="margin-top:4mm"><strong>VISTO</strong> ${exoneracion ? 'de oficio el caso' : `el escrito presentado el ${esc(fecha(j.fechaPresentacion))}`} de ${esc(m.docente)}, por la causal de ${esc((CAUSAL_DESCARGO[j.causal] ?? j.causal).toLowerCase())}: «${esc(j.sustento)}»${j.documento ? `, con el documento ${esc(j.documento)}` : ''}.</p>
    <p class="texto"><strong>CONSIDERANDO:</strong> ${esc(j.fundamento)}</p>
    <p class="texto"><strong>SE RESUELVE:</strong> ${exoneracion ? 'exonerar al docente de la multa, por tratarse de un caso no previsto en el reglamento (RN40).'
      : admitida ? 'declarar ADMITIDA la justificación; la multa queda justificada y no es exigible.'
      : 'declarar DENEGADA la justificación; la multa se mantiene pendiente de pago.'}</p>
    <p class="texto">La decisión del CEUNP es inapelable (RN36).</p>
    ${firmasPleno()}
    <footer>Emitida el ${esc(fecha(new Date()))}.</footer>`);
}

/** RF107: reporte de gestión (participación por mesa, mesas instaladas, incidencias, tiempos y actas). */
export function imprimirReporteGestion(detalle, tiempo) {
  const p = detalle.proceso;
  const rm = detalle.resumenMesas;
  const filas = (detalle.gestion ?? []).map((m) => {
    const part = m.electores ? (m.votaron * 100) / m.electores : 0;
    return `<tr><td>${esc(m.numeroMesa)}<br><small>${esc(m.ubicacion)}</small></td><td>${m.horaInstalacion ? esc(fecha(m.horaInstalacion)) : 'No instalada'}</td>
      <td class="n">${esc(m.votaron)} / ${esc(m.electores)}</td><td class="n">${pct(part)}</td><td class="n">${esc(m.titularesPresentes)} / ${esc(Number(m.titularesPresentes) + Number(m.titularesAusentes))}</td>
      <td class="n">${esc(m.incidencias)}</td><td class="n">${esc(tiempo(m.atencionPromedioSeg))}</td><td class="n">${esc(m.actasEmitidas)} / 3</td>
      <td>${m.fechaEntrega ? esc(fecha(m.fechaEntrega)) : '—'}</td></tr>`;
  }).join('');
  const inc = (detalle.incidencias ?? []).map((i) => `<tr><td>${esc(i.tipo.replaceAll('_', ' ').toLowerCase())}</td><td class="n">${esc(i.total)}</td></tr>`).join('');
  imprimir(`Reporte de gestión · ${p.nombre}`, `
    ${encabezado('Reporte de gestión de la jornada', esc(p.nombre), '<span class="sello">RF107</span>')}
    <dl>
      <div><dt>Mesas instaladas</dt><dd>${esc(rm.instaladas)} de ${esc(rm.total)}</dd></div>
      <div><dt>Participación</dt><dd>${pct(detalle.participacion?.participacionPct)}</dd></div>
      <div><dt>Actas entregadas</dt><dd>${esc(rm.actasEntregadas)} de ${esc(rm.total)}</dd></div>
      <div><dt>Incidencias</dt><dd>${esc((detalle.incidencias ?? []).reduce((s, i) => s + Number(i.total), 0))}</dd></div>
    </dl>
    <h2>Participación y funcionamiento por mesa</h2>
    <table><thead><tr><th>Mesa</th><th>Instalación</th><th class="n">Votaron</th><th class="n">Part.</th><th class="n">Titulares</th><th class="n">Incid.</th><th class="n">Atención</th><th class="n">Actas</th><th>Entrega al CEUNP</th></tr></thead><tbody>${filas}</tbody></table>
    <h2>Incidencias por tipo</h2>
    ${inc ? `<table><thead><tr><th>Tipo</th><th class="n">Total</th></tr></thead><tbody>${inc}</tbody></table>` : '<p class="texto">Sin incidencias registradas.</p>'}
    <footer>Emitido el ${esc(fecha(new Date()))}. Tiempo de atención: promedio entre la verificación del elector y la emisión de su voto.</footer>`);
}
