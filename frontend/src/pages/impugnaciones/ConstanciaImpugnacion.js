import { fecha } from '../credenciales/LectorQR';

/**
 * CUS13 · Impresión de la constancia de una impugnación (las tres instancias: impugnación,
 * decisión de la mesa y fallo del CEUNP) y de la relación de impugnaciones de una mesa o proceso.
 */

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const DECISION_MESA = { PENDIENTE: 'Pendiente', ACEPTADA: 'Fundada', RECHAZADA: 'Infundada' };
const DECISION_CEUNP = { PENDIENTE: 'Pendiente', CONFIRMADA: 'Confirmada', MODIFICADA: 'Modificada' };
const SITUACION = { PENDIENTE_MESA: 'Por resolver en mesa', APELABLE: 'Plazo de apelación', EN_APELACION: 'En apelación', FIRME: 'Firme' };

const opcion = (op, lista) => (op === 'LISTA' ? `Lista ${lista ?? ''}` : op === 'BLANCO' ? 'Voto en blanco'
  : op === 'NULO' ? 'Voto nulo' : op === 'IMPUGNADO' ? 'Impugnado (sin asignar)' : '—');

const ESTILOS = `
  @page { size: A4; margin: 14mm; }
  * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; color: #0f172a; font-size: 9.5pt; }
  header { border-bottom: .6mm solid #0f172a; padding-bottom: 3mm; }
  header h1 { margin: 0 0 1mm; font-size: 14pt; } header p { margin: 0; color: #334155; }
  h2 { font-size: 10.5pt; margin: 5mm 0 2mm; }
  dl { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2mm; margin: 2mm 0 0; }
  dt { font-size: 7pt; text-transform: uppercase; color: #64748b; } dd { margin: 0; font-weight: 600; }
  .texto { margin: 2mm 0 0; padding: 2mm 3mm; border-left: .6mm solid #cbd5e1; background: #f8fafc; white-space: pre-wrap; }
  table { width: 100%; border-collapse: collapse; } th, td { border: .2mm solid #cbd5e1; padding: 1.5mm 2mm; text-align: left; vertical-align: top; }
  th { background: #f1f5f9; font-size: 8pt; } small { color: #64748b; }
  .firmas { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8mm 6mm; margin-top: 14mm; }
  .firma { text-align: center; font-size: 8pt; color: #334155; } .firma .linea { border-top: .3mm solid #0f172a; margin-bottom: 1mm; }
  footer { margin-top: 8mm; font-size: 7pt; color: #64748b; }
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

export function imprimirConstanciaImpugnacion(i) {
  const numero = String(i.id).padStart(4, '0');
  const mesa = i.decisionMesa === 'PENDIENTE' ? '<p>Pendiente de resolución. La cédula se cuenta como IMPUGNADA.</p>' : `
    <dl>
      <div><dt>Decisión</dt><dd>${esc(DECISION_MESA[i.decisionMesa])}</dd></div>
      <div><dt>Votación</dt><dd>${esc(i.votosMesaFavor)} a favor · ${esc(i.votosMesaContra)} en contra</dd></div>
      <div><dt>La cédula va a</dt><dd>${esc(opcion(i.opcionMesa, i.listaMesa))}</dd></div>
      <div><dt>Fecha</dt><dd>${esc(fecha(i.fechaDecisionMesa))}</dd></div>
    </dl>
    <p class="texto">${esc(i.fundamentoMesa)}</p>`;
  const apelacion = !i.fechaApelacion ? '' : `
    <h2>3. Apelación ante el CEUNP</h2>
    <dl>
      <div><dt>Apela</dt><dd>${esc(i.apelante)}</dd></div>
      <div><dt>Fecha</dt><dd>${esc(fecha(i.fechaApelacion))}</dd></div>
    </dl>
    <p class="texto">${esc(i.fundamentoApelacion)}</p>`;
  const fallo = i.decisionCeunp === 'PENDIENTE' ? '' : `
    <h2>4. Fallo del CEUNP · Resolución ${esc(i.numeroResolucion)}</h2>
    <dl>
      <div><dt>Fallo</dt><dd>${esc(DECISION_CEUNP[i.decisionCeunp])}</dd></div>
      <div><dt>Pleno</dt><dd>${esc(i.miembrosPleno)} miembros · ${esc(i.votosPlenoFavor)}–${esc(i.votosPlenoContra)}${i.votoDirimente ? ` · dirimente ${i.votoDirimente === 'FAVOR' ? 'a favor' : 'en contra'}` : ''}</dd></div>
      <div><dt>Opción final</dt><dd>${esc(opcion(i.opcionFinal, i.listaFinal))}</dd></div>
      <div><dt>Fecha</dt><dd>${esc(fecha(i.fechaFallo))}</dd></div>
    </dl>
    <p class="texto">${esc(i.fundamentoCeunp)}</p>
    <p><small>RN36: el fallo del CEUNP es inapelable.</small></p>`;

  imprimir(`Impugnación N.º ${numero} · Mesa ${i.numeroMesa}`, `
    <header>
      <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
      <h1>Constancia de impugnación de voto N.º ${numero}</h1>
      <p>Mesa ${esc(i.numeroMesa)}${i.cargo ? ` · ${esc(i.cargo)}` : ''} · situación: ${esc(SITUACION[i.situacion] ?? i.situacion)} · opción vigente: ${esc(opcion(i.opcionVigente, i.listaVigente))}</p>
    </header>
    <h2>1. Impugnación (RN24)</h2>
    <dl>
      <div><dt>Personero</dt><dd>${esc(i.personero)}</dd></div>
      <div><dt>DNI</dt><dd>${esc(i.dniPersonero)}</dd></div>
      <div><dt>Lista</dt><dd>${esc(i.listaPersonero)}</dd></div>
      <div><dt>Presentada</dt><dd>${esc(fecha(i.fechaPresentacion))}</dd></div>
    </dl>
    <p class="texto">${esc(i.motivo)}</p>
    <h2>2. Decisión de la mesa · primera instancia (RN23)</h2>
    ${mesa}
    ${apelacion}
    ${fallo}
    <div class="firmas">
      <div class="firma"><div class="linea"></div>Presidente de mesa</div>
      <div class="firma"><div class="linea"></div>Personero que impugna</div>
      <div class="firma"><div class="linea"></div>${i.decisionCeunp === 'PENDIENTE' ? 'Secretario de mesa' : 'Presidente del CEUNP'}</div>
    </div>
    <footer>Impreso el ${esc(new Date().toLocaleString('es-PE'))} · Sistema de Elecciones Docentes UNP · CUS13</footer>`);
}

export function imprimirRelacionImpugnaciones(origen, lista) {
  const filas = lista.map((i) => `<tr>
      <td>${String(i.id).padStart(4, '0')}</td><td>${esc(i.numeroMesa)}</td>
      <td>${esc(i.personero)}<br><small>${esc(i.listaPersonero)}</small></td><td>${esc(i.motivo)}</td>
      <td>${esc(DECISION_MESA[i.decisionMesa])}${i.decisionMesa !== 'PENDIENTE' ? `<br><small>${esc(i.votosMesaFavor)}–${esc(i.votosMesaContra)}</small>` : ''}</td>
      <td>${i.estado === 'APELADA' ? 'Apelada' : esc(DECISION_CEUNP[i.decisionCeunp])}${i.numeroResolucion ? `<br><small>Res. ${esc(i.numeroResolucion)}</small>` : ''}</td>
      <td>${esc(SITUACION[i.situacion] ?? i.situacion)}<br><small>${esc(opcion(i.opcionVigente, i.listaVigente))}</small></td></tr>`).join('');
  const titulo = origen?.numero ? `Mesa ${origen.numero}` : (origen?.proceso ?? 'Proceso electoral');
  imprimir(`Relación de impugnaciones · ${titulo}`, `
    <header>
      <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
      <h1>Relación de impugnaciones de voto</h1>
      <p>${esc(titulo)}${origen?.ubicacion ? ` · ${esc(origen.ubicacion)}` : ''} · ${lista.length} impugnación(es)</p>
    </header>
    <h2>Impugnaciones y su trámite</h2>
    <table>
      <thead><tr><th>N.º</th><th>Mesa</th><th>Personero</th><th>Motivo</th><th>Mesa (1.ª inst.)</th><th>CEUNP</th><th>Situación</th></tr></thead>
      <tbody>${filas}</tbody>
    </table>
    <footer>Impreso el ${esc(new Date().toLocaleString('es-PE'))} · Sistema de Elecciones Docentes UNP · CUS13</footer>`);
}
