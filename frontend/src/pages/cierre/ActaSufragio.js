import { svgQR, fecha } from '../credenciales/LectorQR';
import { urlVerificacionActa } from '../instalacion/ActaInstalacion';

/**
 * CUS11 · Impresión del Acta de Sufragio (RF76, RN28) y de la lista NO VOTÓ (RF75).
 * El QR apunta a la verificación pública del acta (/verificar/{token}, portal del CUS17),
 * que recalcula el SHA-256 del contenido y lo compara con la huella guardada.
 */

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const CARGO = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal' };
const ORIGEN = { TITULAR: 'titular', SUPLENTE: 'suplente', REEMPLAZANTE: 'reemplazante' };

const ESTILOS = `
  @page { size: A4; margin: 14mm; }
  * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; color: #0f172a; font-size: 9.5pt; }
  header { display: flex; justify-content: space-between; gap: 6mm; border-bottom: .6mm solid #0f172a; padding-bottom: 3mm; }
  header h1 { margin: 0 0 1mm; font-size: 14pt; } header p { margin: 0; color: #334155; }
  .qr { width: 32mm; text-align: center; font-size: 6.5pt; color: #64748b; } .qr svg { width: 32mm; height: 32mm; display: block; }
  h2 { font-size: 10.5pt; margin: 5mm 0 2mm; }
  dl { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2mm; margin: 3mm 0 0; }
  dt { font-size: 7pt; text-transform: uppercase; color: #64748b; } dd { margin: 0; font-weight: 600; }
  table { width: 100%; border-collapse: collapse; } th, td { border: .2mm solid #cbd5e1; padding: 1.5mm 2mm; text-align: left; vertical-align: top; }
  th { background: #f1f5f9; font-size: 8pt; } small { color: #64748b; }
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

function filasNoVoto(lista) {
  return lista.map((e, i) => `<tr><td>${i + 1}</td><td>${esc(e.docente ?? e.nombre)}</td><td>${esc(e.dni)}</td>
    <td>${e.asistio === true || e.asistio === 1 ? 'Asistió y no votó' : 'No asistió'}</td><td><strong>NO VOTÓ</strong></td></tr>`).join('');
}

export function imprimirActaSufragio(acta, token) {
  const c = acta.contenido ?? {};
  const miembros = (c.miembros ?? []).map((m) => `<tr>
      <td>${esc(m.docente)}<br><small>DNI ${esc(m.dni)}</small></td><td>${esc(CARGO[m.cargo] ?? m.cargo)} (${esc(ORIGEN[m.origen] ?? m.origen)})</td></tr>`).join('');
  const firmas = (acta.firmas ?? []).map((f) => `<div class="firma">
      <div class="linea"></div><strong>${esc(f.nombre)}</strong><span>${esc(f.rol)} · DNI ${esc(f.dni)}</span>
      <code>${esc(f.firmaDigital?.slice(0, 24))}…</code></div>`).join('');
  const diferencia = c.diferencia_lista_fisica;

  imprimir(`Acta de Sufragio · Mesa ${c.mesa}`, `
    <header>
      <div>
        <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
        <h1>Acta de Sufragio</h1>
        <p>${esc(c.proceso)} · Mesa ${esc(c.mesa)} · Acta N.º ${String(acta.idActa).padStart(6, '0')}</p>
      </div>
      ${token ? `<div class="qr">${svgQR(urlVerificacionActa(token))}Verificación del acta</div>` : ''}
    </header>
    <dl>
      <div><dt>Local</dt><dd>${esc(c.ubicacion)}</dd></div>
      <div><dt>Hora de instalación</dt><dd>${esc(c.hora_instalacion ?? '—')}</dd></div>
      <div><dt>Hora de cierre</dt><dd>${esc(c.hora_cierre)}${c.cierre_anticipado ? ' (votaron todos)' : ''}</dd></div>
      <div><dt>Electores hábiles</dt><dd>${esc(c.total_electores)}</dd></div>
      <div><dt>Electores que votaron</dt><dd>${esc(c.electores_que_votaron)}</dd></div>
      <div><dt>Electores que no votaron</dt><dd>${esc(c.electores_que_no_votaron)}${c.asistieron_sin_votar ? ` (${esc(c.asistieron_sin_votar)} asistieron)` : ''}</dd></div>
      <div><dt>Cédulas recibidas</dt><dd>${esc(c.cedulas_recibidas ?? '—')}</dd></div>
      <div><dt>Cédulas no utilizadas</dt><dd>${esc(c.cedulas_no_utilizadas)}</dd></div>
      ${c.firmas_lista_fisica != null ? `<div><dt>Firmas en la lista física</dt><dd>${esc(c.firmas_lista_fisica)}${diferencia ? ` (diferencia ${diferencia > 0 ? '+' : ''}${esc(diferencia)})` : ''}</dd></div>` : ''}
    </dl>
    <h2>Miembros de mesa en funciones</h2>
    <table><thead><tr><th>Miembro</th><th>Cargo</th></tr></thead><tbody>${miembros}</tbody></table>
    <h2>Electores que no votaron (RF75)</h2>
    ${(c.no_votaron ?? []).length ? `<table><thead><tr><th>N.º</th><th>Elector</th><th>DNI</th><th>Asistencia</th><th>Marca</th></tr></thead><tbody>${filasNoVoto(c.no_votaron)}</tbody></table>` : '<p>Votaron todos los electores.</p>'}
    <h2>Observaciones</h2>
    <p>${esc(c.observaciones ?? 'Ninguna.')}</p>
    <div class="firmas">${firmas}</div>
    <footer>Emitida el ${esc(fecha(acta.fechaEmision))}. Huella SHA-256 del contenido: ${esc(acta.hashIntegridad)}</footer>`);
}

/** RF75: lista de electores con la marca NO VOTÓ, para adjuntar al padrón de la mesa. */
export function imprimirListaNoVoto(mesa, lista) {
  imprimir(`Lista NO VOTÓ · Mesa ${mesa.numero}`, `
    <header>
      <div>
        <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
        <h1>Electores que no votaron</h1>
        <p>${esc(mesa.proceso)} · Mesa ${esc(mesa.numero)} · ${esc(mesa.ubicacion)}</p>
      </div>
    </header>
    ${lista.length ? `<table><thead><tr><th>N.º</th><th>Elector</th><th>DNI</th><th>Asistencia</th><th>Marca</th></tr></thead><tbody>${filasNoVoto(lista)}</tbody></table>` : '<p>Votaron todos los electores.</p>'}
    <footer>Impresa el ${esc(fecha(new Date().toISOString()))}.</footer>`);
}
