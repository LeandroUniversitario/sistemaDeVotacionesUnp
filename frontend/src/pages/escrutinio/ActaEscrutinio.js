import { svgQR, fecha } from '../credenciales/LectorQR';
import { urlVerificacionActa } from '../instalacion/ActaInstalacion';

/**
 * CUS12 · Impresión del Acta de Escrutinio (RF85, RN28): los tres ejemplares para el CEUNP,
 * la ONPE y el local de votación (RF86), la copia simple para los personeros y el cargo de
 * entrega al CEUNP (RF87). El QR apunta a la verificación pública del acta
 * (/api/publico/actas/{token}), que recalcula el SHA-256 del contenido.
 */

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const CARGO = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal' };
const ORIGEN = { TITULAR: 'titular', SUPLENTE: 'suplente', REEMPLAZANTE: 'reemplazante' };
export const EJEMPLARES = ['CEUNP', 'ONPE', 'Local de votación'];

const ESTILOS = `
  @page { size: A4; margin: 14mm; }
  * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; color: #0f172a; font-size: 9.5pt; }
  section.hoja + section.hoja { break-before: page; }
  header { display: flex; justify-content: space-between; gap: 6mm; border-bottom: .6mm solid #0f172a; padding-bottom: 3mm; }
  header h1 { margin: 0 0 1mm; font-size: 14pt; } header p { margin: 0; color: #334155; }
  .ejemplar { display: inline-block; margin-top: 1.5mm; padding: .6mm 2.5mm; border: .3mm solid #0f172a; border-radius: 1mm; font-size: 8pt; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; }
  .observada { color: #b45309; border-color: #b45309; margin-left: 2mm; }
  .qr { width: 32mm; text-align: center; font-size: 6.5pt; color: #64748b; } .qr svg { width: 32mm; height: 32mm; display: block; }
  h2 { font-size: 10.5pt; margin: 5mm 0 2mm; }
  dl { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2mm; margin: 3mm 0 0; }
  dt { font-size: 7pt; text-transform: uppercase; color: #64748b; } dd { margin: 0; font-weight: 600; }
  table { width: 100%; border-collapse: collapse; } th, td { border: .2mm solid #cbd5e1; padding: 1.5mm 2mm; text-align: left; vertical-align: top; }
  th { background: #f1f5f9; font-size: 8pt; } td.n, th.n { text-align: right; font-variant-numeric: tabular-nums; }
  tr.total td { font-weight: 700; background: #f8fafc; } small { color: #64748b; }
  .firmas { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8mm 6mm; margin-top: 12mm; }
  .firma { display: grid; gap: .8mm; text-align: center; } .firma .linea { border-top: .3mm solid #0f172a; margin-bottom: 1mm; }
  .firma span { font-size: 8pt; color: #334155; } .firma code { font-size: 6.5pt; color: #64748b; }
  footer { margin-top: 8mm; font-size: 7pt; color: #64748b; word-break: break-all; }
`;

function imprimir(titulo, cuerpo) {
  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><title>${esc(titulo)}</title><style>${ESTILOS}</style></head><body>${cuerpo}</body></html>`;
  const iframe = document.createElement('iframe');
  iframe.setAttribute('aria-hidden', 'true');
  iframe.style.cssText = 'position:fixed;right:0;bottom:0;width:0;height:0;border:0;';
  document.body.appendChild(iframe);
  const doc = iframe.contentWindow.document;
  doc.open();
  doc.write(html);
  doc.close();
  setTimeout(() => {
    iframe.contentWindow.focus();
    iframe.contentWindow.print();
    setTimeout(() => iframe.remove(), 1000);
  }, 250);
}

function tablaResultados(r) {
  const filas = (r.opciones ?? []).map((o) => `<tr>
      <td>${o.opcion === 'LISTA' ? `${o.orden != null ? `${esc(o.orden)}. ` : ''}${esc(o.nombre)}` : esc(o.nombre)}</td>
      <td class="n">${esc(o.manual)}</td><td class="n">${o.opcion === 'IMPUGNADO' ? '—' : esc(o.digital)}</td>
      <td class="n">${o.opcion === 'IMPUGNADO' || !o.diferencia ? '0' : `${o.diferencia > 0 ? '+' : ''}${esc(o.diferencia)}`}</td></tr>`).join('');
  return `<h2>${esc(r.cargo)} <small>· votaron ${esc(r.votantes)}</small></h2>
    <table><thead><tr><th>Opción</th><th class="n">Votos (cédula física)</th><th class="n">Conteo digital</th><th class="n">Diferencia</th></tr></thead>
    <tbody>${filas}<tr class="total"><td>Total de votos emitidos</td><td class="n">${esc(r.total)}</td><td class="n">${esc(r.total_digital)}</td><td></td></tr></tbody></table>`;
}

function hojaActa(acta, token, ejemplar) {
  const c = acta.contenido ?? {};
  const miembros = (c.miembros ?? []).map((m) => `<tr>
      <td>${esc(m.docente)}<br><small>DNI ${esc(m.dni)}</small></td><td>${esc(CARGO[m.cargo] ?? m.cargo)} (${esc(ORIGEN[m.origen] ?? m.origen)})</td></tr>`).join('');
  const firmas = (acta.firmas ?? []).map((f) => `<div class="firma">
      <div class="linea"></div><strong>${esc(f.nombre)}</strong><span>${esc(f.rol)} · DNI ${esc(f.dni)}</span>
      <code>${esc(f.firmaDigital?.slice(0, 24))}…</code></div>`).join('');
  const impugnaciones = (c.impugnaciones ?? []).map((i) => `<tr><td>${esc(i.id)}</td><td>${esc(i.cargo)}</td>
      <td>${esc(i.personero)}<br><small>${esc(i.lista)}</small></td><td>${esc(i.motivo)}</td><td>${esc(i.estado)}</td></tr>`).join('');
  const cedulas = [
    c.cedulas_sobrantes_destruidas ? `A1: se retiraron al azar y destruyeron sin abrir ${esc(c.cedulas_sobrantes_destruidas)} cédula(s) sobrante(s).` : '',
    c.cedulas_faltantes ? `A2: faltaron ${esc(c.cedulas_faltantes)} cédula(s).` : '',
    c.observacion_cedulas ? esc(c.observacion_cedulas) : '',
  ].filter(Boolean).join(' ');

  return `<section class="hoja">
    <header>
      <div>
        <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
        <h1>Acta de Escrutinio</h1>
        <p>${esc(c.proceso)} · Mesa ${esc(c.mesa)} · Acta N.º ${String(acta.idActa).padStart(6, '0')}</p>
        <span class="ejemplar">${esc(ejemplar)}</span>${c.observada ? '<span class="ejemplar observada">Observada</span>' : ''}
      </div>
      ${token ? `<div class="qr">${svgQR(urlVerificacionActa(token))}Verificación del acta</div>` : ''}
    </header>
    <dl>
      <div><dt>Local</dt><dd>${esc(c.ubicacion)}</dd></div>
      <div><dt>Inicio del escrutinio</dt><dd>${esc(c.hora_inicio)}</dd></div>
      <div><dt>Fin del escrutinio</dt><dd>${esc(c.hora_fin)}</dd></div>
      <div><dt>Electores que votaron</dt><dd>${esc(c.electores_que_votaron)}</dd></div>
      <div><dt>Cédulas en el ánfora</dt><dd>${esc(c.cedulas_contadas)}</dd></div>
      <div><dt>Cédulas escrutadas</dt><dd>${esc(c.cedulas_escrutadas)}</dd></div>
      <div><dt>Recuentos</dt><dd>${esc(c.recuentos)}</dd></div>
      <div><dt>Conciliación</dt><dd>${c.conteo_coincide_digital ? 'Coincide con el conteo digital' : 'Prevalece la cédula física (RF84)'}</dd></div>
    </dl>
    ${cedulas ? `<p><strong>Cédulas:</strong> ${cedulas}</p>` : ''}
    ${(c.resultados ?? []).map(tablaResultados).join('')}
    ${impugnaciones ? `<h2>Votos impugnados (A4)</h2><table><thead><tr><th>N.º</th><th>Cargo</th><th>Personero</th><th>Motivo</th><th>Estado</th></tr></thead><tbody>${impugnaciones}</tbody></table>` : ''}
    <h2>Miembros de mesa en funciones</h2>
    <table><thead><tr><th>Miembro</th><th>Cargo</th></tr></thead><tbody>${miembros}</tbody></table>
    <h2>Observaciones</h2>
    <p>${esc(c.observaciones ?? 'Ninguna.')}</p>
    <div class="firmas">${firmas}</div>
    <footer>Emitida el ${esc(fecha(acta.fechaEmision))}. Huella SHA-256 del contenido: ${esc(acta.hashIntegridad)}</footer>
  </section>`;
}

/** RF86: los tres ejemplares del acta (CEUNP, ONPE y local de votación), uno por página. */
export function imprimirActaEscrutinio(acta, token) {
  const c = acta.contenido ?? {};
  imprimir(`Acta de Escrutinio · Mesa ${c.mesa}`, EJEMPLARES.map((e) => hojaActa(acta, token, `Ejemplar ${e}`)).join(''));
}

/** RF86: copia simple para el personero que la solicite. */
export function imprimirCopiaPersonero(acta, token) {
  const c = acta.contenido ?? {};
  imprimir(`Copia del Acta de Escrutinio · Mesa ${c.mesa}`, hojaActa(acta, token, 'Copia simple para personero'));
}

/** RF87: cargo de entrega al CEUNP de las actas, el padrón y el material de la mesa. */
export function imprimirCargoEntrega(mesa, registro, acta) {
  const si = (v) => v === true || v === 1;
  imprimir(`Cargo de entrega · Mesa ${mesa.numero}`, `
    <header>
      <div>
        <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
        <h1>Cargo de entrega de actas y material</h1>
        <p>${esc(mesa.proceso)} · Mesa ${esc(mesa.numero)} · ${esc(mesa.ubicacion)}</p>
        <span class="ejemplar">Cargo N.º ${esc(registro.codigoCargo)}</span>
      </div>
    </header>
    <dl>
      <div><dt>Fecha de entrega</dt><dd>${esc(fecha(registro.fechaEntrega))}</dd></div>
      <div><dt>Recibe por el CEUNP</dt><dd>${esc(registro.recibidoPor)}</dd></div>
      <div><dt>Acta de escrutinio</dt><dd>N.º ${String(acta?.idActa ?? '').padStart(6, '0')}${acta?.contenido?.observada ? ' (observada)' : ''}</dd></div>
      <div><dt>Registró</dt><dd>${esc(registro.entregadoPor ?? '—')}</dd></div>
    </dl>
    <h2>Se entrega</h2>
    <table><thead><tr><th>Documento o material</th><th>Entregado</th></tr></thead><tbody>
      ${EJEMPLARES.map((e) => `<tr><td>Acta electoral (instalación, sufragio y escrutinio) · ejemplar ${esc(e)}</td><td>Sí</td></tr>`).join('')}
      <tr><td>Copias simples para personeros</td><td>${esc(registro.copiasPersoneros ?? 0)}</td></tr>
      <tr><td>Padrón de la mesa con la lista de firmas</td><td>${si(registro.entregaPadron) ? 'Sí' : 'No'}</td></tr>
      <tr><td>Material electoral (ánfora, cédulas no utilizadas, útiles)</td><td>${si(registro.entregaMaterial) ? 'Sí' : 'No'}</td></tr>
    </tbody></table>
    ${registro.observacionEntrega ? `<h2>Observación</h2><p>${esc(registro.observacionEntrega)}</p>` : ''}
    <div class="firmas">
      <div class="firma"><div class="linea"></div><strong>Presidente de mesa</strong><span>Entrega</span></div>
      <div class="firma"><div class="linea"></div><strong>${esc(registro.recibidoPor)}</strong><span>Recibe por el CEUNP</span></div>
    </div>
    <footer>Huella del acta de escrutinio: ${esc(acta?.hashIntegridad ?? '—')}</footer>`);
}
