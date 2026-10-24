import { svgQR, fecha } from '../credenciales/LectorQR';

/**
 * CUS14 · Impresiones del cómputo general: verificación previa de mesas y actas (RF89, RF90),
 * consolidado y resultados por mesa (RF92, RF99), acta general de sufragios con QR (RF92),
 * comunicación de la nulidad total (A1, RN34), resolución de proclamación con QR y credencial
 * de la lista ganadora (RF98). El QR apunta a /api/publico/computo/{token}, que recalcula el
 * SHA-256 del contenido.
 */

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
export const urlVerificacionComputo = (token) => `${window.location.origin}/api/publico/computo/${token}`;
const pct = (v) => `${Number(v ?? 0).toFixed(2)} %`;

export const ESTADO_RESULTADO = {
  PENDIENTE: 'Pendiente',
  ELEGIDO: 'Lista ganadora',
  SEGUNDA_VUELTA: 'Segunda vuelta (RN33)',
  SIN_QUORUM: 'Sin quórum (RN31)',
  DESIERTO: 'Desierto',
  EMPATE: 'Empate',
};
export const SITUACION_MESA = {
  HABILITADA: 'Habilitada',
  NO_INSTALADA: 'No instalada',
  ANULADA: 'Anulada',
  SIN_INSTALAR: 'Sin instalar',
  EN_SUFRAGIO: 'Sufragio abierto',
  ESCRUTINIO_PENDIENTE: 'Escrutinio pendiente',
  ACTAS_SIN_ENTREGAR: 'Actas sin entregar',
  ACTAS_INCOMPLETAS: 'Actas incompletas',
  ACTA_NO_AUTENTICA: 'Acta no auténtica',
  ACTA_DUDOSA: 'Acta dudosa',
  IMPUGNACIONES_PENDIENTES: 'Impugnaciones pendientes',
  POR_CALIFICAR: 'Por calificar (A3)',
};
const TIPO_ACTA = { INSTALACION: 'Instalación', SUFRAGIO: 'Sufragio', ESCRUTINIO: 'Escrutinio' };
const TIPO_PERSONERO = { MESA: 'de mesa', GENERAL: 'general', ALTERNO: 'alterno' };

const ESTILOS = `
  @page { size: A4; margin: 14mm; }
  * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; color: #0f172a; font-size: 9.5pt; }
  section.hoja + section.hoja { break-before: page; }
  header { display: flex; justify-content: space-between; gap: 6mm; border-bottom: .6mm solid #0f172a; padding-bottom: 3mm; }
  header h1 { margin: 0 0 1mm; font-size: 14pt; } header p { margin: 0; color: #334155; }
  .sello { display: inline-block; margin-top: 1.5mm; padding: .6mm 2.5mm; border: .3mm solid #0f172a; border-radius: 1mm; font-size: 8pt; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; }
  .sello.nulo { color: #be123c; border-color: #be123c; } .sello.ok { color: #047857; border-color: #047857; }
  .qr { width: 32mm; text-align: center; font-size: 6.5pt; color: #64748b; } .qr svg { width: 32mm; height: 32mm; display: block; }
  h2 { font-size: 10.5pt; margin: 5mm 0 2mm; }
  dl { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2mm; margin: 3mm 0 0; }
  dt { font-size: 7pt; text-transform: uppercase; color: #64748b; } dd { margin: 0; font-weight: 600; }
  table { width: 100%; border-collapse: collapse; } th, td { border: .2mm solid #cbd5e1; padding: 1.5mm 2mm; text-align: left; vertical-align: top; }
  th { background: #f1f5f9; font-size: 8pt; } td.n, th.n { text-align: right; font-variant-numeric: tabular-nums; }
  tr.total td { font-weight: 700; background: #f8fafc; } tr.gana td { background: #ecfdf5; font-weight: 700; } small { color: #64748b; }
  p.texto { line-height: 1.6; text-align: justify; }
  .firmas { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8mm 6mm; margin-top: 16mm; }
  .firma { display: grid; gap: .8mm; text-align: center; } .firma .linea { border-top: .3mm solid #0f172a; margin-bottom: 1mm; }
  .firma span { font-size: 8pt; color: #334155; }
  .credencial { margin: 10mm auto 0; max-width: 150mm; padding: 10mm 12mm; border: 1mm double #0f172a; text-align: center; }
  .credencial h1 { font-size: 18pt; margin: 2mm 0 4mm; letter-spacing: .03em; } .credencial h2 { font-size: 13pt; margin: 4mm 0 2mm; }
  .credencial .codigo { display: inline-block; margin-top: 4mm; padding: 1.5mm 4mm; border: .3mm solid #0f172a; font: 700 11pt ui-monospace, monospace; letter-spacing: .12em; }
  .credencial table { margin-top: 4mm; text-align: left; }
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

const encabezado = (titulo, subtitulo, sello, token) => `
  <header>
    <div>
      <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
      <h1>${esc(titulo)}</h1>
      <p>${subtitulo}</p>
      ${sello ?? ''}
    </div>
    ${token ? `<div class="qr">${svgQR(urlVerificacionComputo(token))}Verificación del documento</div>` : ''}
  </header>`;

const firmasPleno = (presidente) => `
  <div class="firmas">
    <div class="firma"><div class="linea"></div><strong>${esc(presidente || 'Presidente del CEUNP')}</strong><span>Presidente del CEUNP</span></div>
    <div class="firma"><div class="linea"></div><strong>Secretario del CEUNP</strong><span>Secretario</span></div>
    <div class="firma"><div class="linea"></div><strong>Miembro del CEUNP</strong><span>Vocal</span></div>
  </div>`;

/** Pasos 1-3 (RF89, RF90): relación de mesas instaladas y no instaladas y de sus actas. */
export function imprimirVerificacionPrevia(detalle) {
  const p = detalle.proceso;
  const actas = detalle.actas ?? [];
  const filas = (detalle.mesas ?? []).map((m) => {
    const propias = actas.filter((a) => a.idMesa === m.idMesa);
    const textoActas = propias.length
      ? propias.map((a) => `${esc(TIPO_ACTA[a.tipo] ?? a.tipo)}: ${a.integra ? 'íntegra' : 'ALTERADA'}${a.comprobacion ? ` · ${a.comprobacion === 'AUTENTICA' ? 'auténtica' : 'NO auténtica'}` : a.dudosa ? ' · dudosa' : ''}`).join('<br>')
      : '—';
    return `<tr><td>${esc(m.numeroMesa)}<br><small>${esc(m.ubicacion)}</small></td><td>${esc(m.estado)}</td>
      <td>${m.fechaEntrega ? `Entregada ${esc(fecha(m.fechaEntrega))}<br><small>Cargo ${esc(m.codigoCargo)}</small>` : esc(m.estadoEscrutinio ?? '—')}</td>
      <td>${textoActas}</td><td>${esc(SITUACION_MESA[m.situacion] ?? m.situacion)}${m.calificacion ? `<br><small>${esc(m.calificacion)} · ${esc(m.resolucionCalificacion ?? '')}</small>` : ''}</td></tr>`;
  }).join('');
  const r = detalle.resumenMesas ?? {};
  imprimir(`Verificación previa · ${p.nombre}`, `
    ${encabezado('Verificación previa al cómputo general', `${esc(p.nombre)} · ${esc(p.estado)}`)}
    <dl>
      <div><dt>Mesas</dt><dd>${esc(r.total)}</dd></div>
      <div><dt>Habilitadas</dt><dd>${esc(r.habilitadas)}</dd></div>
      <div><dt>No instaladas · anuladas</dt><dd>${esc(r.noInstaladas)} · ${esc(r.anuladas)}</dd></div>
      <div><dt>Actas entregadas</dt><dd>${esc(r.entregadas)} mesa(s)</dd></div>
    </dl>
    <h2>Mesas y actas recibidas</h2>
    <table><thead><tr><th>Mesa</th><th>Estado</th><th>Entrega (RF87)</th><th>Actas (huella SHA-256)</th><th>Situación</th></tr></thead><tbody>${filas}</tbody></table>
    ${(detalle.bloqueos ?? []).length ? `<h2>Pendientes antes del cómputo</h2><ul>${detalle.bloqueos.map((b) => `<li>${esc(b)}</li>`).join('')}</ul>` : ''}
    <footer>Emitida el ${esc(fecha(new Date()))}.</footer>`);
}

function tablaCargo(c) {
  const filas = (c.opciones ?? []).map((o) => `<tr class="${c.id_lista_ganadora === o.id_lista && c.estado_resultado === 'ELEGIDO' ? 'gana' : ''}">
      <td>${o.orden != null ? `${esc(o.orden)}. ` : ''}${esc(o.lista)}</td><td class="n">${esc(o.votos)}</td><td class="n">${pct(o.porcentaje)}</td><td class="n">${esc(o.posicion ?? '')}</td></tr>`).join('');
  return `<h2>${esc(c.cargo)} <small>· ${esc(ESTADO_RESULTADO[c.estado_resultado] ?? c.estado_resultado)}${c.lista_ganadora ? `: ${esc(c.lista_ganadora)}` : ''}</small></h2>
    <dl>
      <div><dt>Electores hábiles</dt><dd>${esc(c.electores)}</dd></div>
      <div><dt>Votaron</dt><dd>${esc(c.votaron)} (${pct(c.participacion)})</dd></div>
      <div><dt>Quórum</dt><dd>${c.alcanza_quorum ? 'Alcanzado' : 'No alcanzado'}</dd></div>
      <div><dt>Mínimo para ganar</dt><dd>más del ${pct(c.porcentaje_minimo)} de válidos</dd></div>
    </dl>
    <table style="margin-top:2mm"><thead><tr><th>Lista</th><th class="n">Votos</th><th class="n">% de válidos</th><th class="n">Puesto</th></tr></thead>
    <tbody>${filas}
      <tr class="total"><td>Votos válidos</td><td class="n">${esc(c.validos)}</td><td class="n">100.00 %</td><td></td></tr>
      <tr><td>Votos en blanco</td><td class="n">${esc(c.blancos)}</td><td></td><td></td></tr>
      <tr><td>Votos nulos</td><td class="n">${esc(c.nulos)}</td><td></td><td></td></tr>
      <tr class="total"><td>Votos emitidos</td><td class="n">${esc(c.emitidos)}</td><td></td><td></td></tr>
    </tbody></table>`;
}

/** 12 emitirActaGeneral(totales): acta general de sufragios docentes (RF92) con su QR. */
export function imprimirActaGeneral(computo, token) {
  const a = computo.acta ?? {};
  const nula = a.resultado === 'NULIDAD_TOTAL';
  const personeros = (a.sesion?.personeros ?? []).map((x) => `<tr><td>${esc(x.personero)}<br><small>DNI ${esc(x.dni)}</small></td><td>${esc(x.lista)}</td><td>${esc(TIPO_PERSONERO[x.tipo] ?? x.tipo)}</td></tr>`).join('');
  const mesas = (a.detalle_mesas ?? []).map((m) => `<tr><td>${esc(m.mesa)}</td><td>${esc(m.ubicacion)}</td><td>${esc(SITUACION_MESA[m.situacion] ?? m.situacion)}${m.calificacion ? ` · ${esc(m.calificacion)}${m.resolucion ? ` (${esc(m.resolucion)})` : ''}` : ''}</td>
      <td class="n">${esc(m.electores)}</td><td class="n">${esc(m.votaron ?? '—')}</td><td>${esc(m.codigo_entrega ?? '—')}</td></tr>`).join('');
  imprimir(`Acta General de Sufragios · ${a.proceso}`, `
    ${encabezado('Acta General de Sufragios Docentes', `${esc(a.proceso)} · ${a.vuelta === 'SEGUNDA_VUELTA' ? 'Segunda vuelta' : 'Primera vuelta'}`,
      `<span class="sello ${nula ? 'nulo' : 'ok'}">${nula ? 'Nulidad total (RN31)' : 'Elección válida'}</span>`, token)}
    <dl>
      <div><dt>Lugar de la sesión</dt><dd>${esc(a.sesion?.lugar)}</dd></div>
      <div><dt>Inicio de la sesión</dt><dd>${esc(fecha(a.sesion?.inicio))}</dd></div>
      <div><dt>Cómputo</dt><dd>${esc(fecha(a.fecha_computo))}</dd></div>
      <div><dt>Miembros del CEUNP</dt><dd>${esc(a.sesion?.miembros_ceunp)}</dd></div>
      <div><dt>Mesas computadas</dt><dd>${esc(a.mesas?.computadas)} de ${esc(a.mesas?.total)}</dd></div>
      <div><dt>No instaladas · anuladas</dt><dd>${esc(a.mesas?.no_instaladas)} · ${esc(a.mesas?.anuladas)}</dd></div>
      <div><dt>Actas verificadas</dt><dd>${esc(a.actas_verificadas)} (${esc(a.actas_dudosas)} dudosa/s)</dd></div>
      <div><dt>Participación</dt><dd>${pct(a.participacion?.porcentaje)} · mínimo ${pct(a.participacion?.quorum_minimo)}</dd></div>
    </dl>
    ${nula ? `<p class="texto"><strong>A1:</strong> la participación de ${pct(a.participacion?.porcentaje)} (${esc(a.participacion?.votaron)} de ${esc(a.participacion?.electores)} electores hábiles) no superó el ${pct(a.participacion?.quorum_minimo)} exigido. Se declara la nulidad total de la elección (RN31, RN34) y se comunica a ${esc((a.comunicar_a ?? []).join(', '))}.</p>` : ''}
    ${(a.cargos ?? []).map(tablaCargo).join('')}
    <h2>Detalle de mesas</h2>
    <table><thead><tr><th>Mesa</th><th>Local</th><th>Situación</th><th class="n">Electores</th><th class="n">Votaron</th><th>Cargo de entrega</th></tr></thead><tbody>${mesas}</tbody></table>
    <h2>Personeros presentes en la sesión (RF91)</h2>
    ${personeros ? `<table><thead><tr><th>Personero</th><th>Lista</th><th>Tipo</th></tr></thead><tbody>${personeros}</tbody></table>` : '<p>No asistieron personeros (asistencia facultativa).</p>'}
    ${firmasPleno()}
    <footer>Huella SHA-256 del contenido: ${esc(computo.hashIntegridad)}${token ? '' : ' · Reimpresión sin QR: el código solo se entrega al emitir el acta.'}</footer>`);
}

/** A1 (RN34): comunicación de la nulidad total a SUNEDU, la Asamblea y el Consejo Universitario. */
export function imprimirComunicacionNulidad(computo, proceso) {
  const a = computo.acta ?? {};
  const destinos = a.comunicar_a?.length ? a.comunicar_a : ['SUNEDU', 'Asamblea Universitaria', 'Consejo Universitario'];
  imprimir(`Comunicación de nulidad · ${a.proceso}`, destinos.map((d) => `<section class="hoja">
    ${encabezado('Comunicación de nulidad de la elección', esc(a.proceso), '<span class="sello nulo">Nulidad total</span>')}
    <p style="margin-top:6mm">Piura, ${esc(fecha(a.fecha_computo))}</p>
    <p><strong>Señores:</strong><br>${esc(d)}<br>Presente.-</p>
    <p class="texto">El Comité Electoral de la Universidad Nacional de Piura comunica que, en la sesión de cómputo general realizada en ${esc(a.sesion?.lugar)}, se verificó que en el proceso «${esc(a.proceso)}» votaron ${esc(a.participacion?.votaron)} de ${esc(a.participacion?.electores)} electores hábiles, una participación de ${pct(a.participacion?.porcentaje)} que no supera el ${pct(a.participacion?.quorum_minimo)} exigido.</p>
    <p class="texto">En consecuencia, conforme a RN31 y RN34, el CEUNP declaró la <strong>nulidad total de la elección</strong>. ${esc(proceso?.motivoAnulacion ?? '')}</p>
    <p class="texto">Se adjunta el Acta General de Sufragios, cuya autenticidad puede verificarse con su huella SHA-256: <code>${esc(computo.hashIntegridad)}</code>.</p>
    <p>Atentamente,</p>
    ${firmasPleno()}
  </section>`).join(''));
}

/** 16-17 acreditarGanadora / listaAcreditada: resolución de proclamación (RF98) con su QR. */
export function imprimirResolucionProclamacion(computo, token) {
  const r = computo.proclamacion ?? {};
  const proclamados = (r.proclamados ?? []).map((x) => `<h2>${esc(x.cargo)}: ${esc(x.lista)}</h2>
    <p>${esc(x.votos)} votos válidos (${pct(x.porcentaje)}) · Credencial ${esc(x.codigo_credencial)}</p>
    <table><thead><tr><th>Cargo en la lista</th><th>Candidato</th><th>DNI</th></tr></thead><tbody>
      ${(x.candidatos ?? []).map((c) => `<tr><td>${esc(c.rol)}</td><td>${esc(c.nombre)}</td><td>${esc(c.dni)}</td></tr>`).join('') || '<tr><td colspan="3">—</td></tr>'}
    </tbody></table>`).join('');
  const sin = (r.sin_proclamar ?? []).map((x) => `<li>${esc(x.cargo)}: ${esc(ESTADO_RESULTADO[x.estado_resultado] ?? x.estado_resultado)}</li>`).join('');
  imprimir(`Resolución ${r.resolucion}`, `
    ${encabezado(`Resolución N.º ${r.resolucion}`, `${esc(r.proceso)} · Proclamación de resultados`, '<span class="sello ok">Proclamación (RF98)</span>', token)}
    <dl>
      <div><dt>Fecha</dt><dd>${esc(fecha(r.fecha))}</dd></div>
      <div><dt>Presidente del CEUNP</dt><dd>${esc(r.presidente_ceunp)}</dd></div>
      <div><dt>Miembros del Pleno</dt><dd>${esc(r.miembros_pleno)}</dd></div>
      <div><dt>Cargos proclamados</dt><dd>${esc((r.proclamados ?? []).length)}</dd></div>
    </dl>
    <p class="texto" style="margin-top:4mm"><strong>VISTO</strong> el Acta General de Sufragios Docentes (huella ${esc(r.hash_acta_general)}), y <strong>CONSIDERANDO</strong> que las listas que se indican superaron el porcentaje mínimo de votos válidos exigido; el Comité Electoral, en sesión del Pleno, <strong>RESUELVE</strong> proclamar y acreditar como ganadoras a:</p>
    ${proclamados || '<p>Ningún cargo tiene lista ganadora.</p>'}
    ${sin ? `<h2>Cargos sin proclamar</h2><ul>${sin}</ul>` : ''}
    ${r.fundamento ? `<h2>Fundamento</h2><p class="texto">${esc(r.fundamento)}</p>` : ''}
    ${firmasPleno(r.presidente_ceunp)}
    <footer>Huella SHA-256 de la resolución: ${esc(computo.hashProclamacion)}${token ? '' : ' · Reimpresión sin QR: el código solo se entrega al emitir la resolución.'}</footer>`);
}

/** RF98: credencial de la lista ganadora de un cargo. */
export function imprimirCredencial(computo, proclamado) {
  const r = computo.proclamacion ?? {};
  const x = (r.proclamados ?? []).find((p) => p.id_cargo === proclamado.idCargo) ?? {};
  imprimir(`Credencial ${proclamado.codigoCredencial}`, `
    <div class="credencial">
      <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
      <h1>CREDENCIAL</h1>
      <p>El Comité Electoral, por Resolución N.º ${esc(r.resolucion)}, acredita a la</p>
      <h2>${esc(proclamado.lista)}</h2>
      <p>como lista ganadora para el cargo de <strong>${esc(proclamado.cargo)}</strong> del proceso «${esc(r.proceso)}», con ${esc(proclamado.votos)} votos válidos (${pct(proclamado.porcentajeValidos)}).</p>
      <table><thead><tr><th>Cargo en la lista</th><th>Integrante</th><th>DNI</th></tr></thead><tbody>
        ${(x.candidatos ?? []).map((c) => `<tr><td>${esc(c.rol)}</td><td>${esc(c.nombre)}</td><td>${esc(c.dni)}</td></tr>`).join('') || '<tr><td colspan="3">—</td></tr>'}
      </tbody></table>
      <span class="codigo">${esc(proclamado.codigoCredencial)}</span>
      <p><small>Piura, ${esc(fecha(proclamado.fechaProclamacion))}</small></p>
      ${firmasPleno(r.presidente_ceunp)}
    </div>`);
}

/** RF99: resultados por mesa y consolidado del proceso. */
export function imprimirResultadosMesa(proceso, filas, consolidado) {
  const mesas = [...new Set(filas.map((f) => f.numeroMesa))];
  const cuerpo = mesas.map((m) => {
    const propias = filas.filter((f) => f.numeroMesa === m);
    return `<tr><td rowspan="${propias.length}"><strong>${esc(m)}</strong></td>${propias.map((f, i) => `${i ? '<tr>' : ''}<td>${esc(f.cargo)}</td><td>${esc(f.lista)}</td><td class="n">${esc(f.votos)}</td></tr>`).join('')}`;
  }).join('');
  const totales = (consolidado ?? []).map((c) => `<h2>${esc(c.cargo)} <small>· ${esc(c.mesasComputables)} mesa(s)</small></h2>
    <table><thead><tr><th>Lista</th><th class="n">Votos</th><th class="n">%</th></tr></thead><tbody>
    ${(c.listas ?? []).map((l) => `<tr><td>${esc(l.lista)}</td><td class="n">${esc(l.votos)}</td><td class="n">${pct(l.porcentaje)}</td></tr>`).join('')}
    <tr><td>Votos en blanco</td><td class="n">${esc(c.blancos)}</td><td></td></tr><tr><td>Votos nulos</td><td class="n">${esc(c.nulos)}</td><td></td></tr>
    ${c.impugnados ? `<tr><td>Impugnados sin resolver</td><td class="n">${esc(c.impugnados)}</td><td></td></tr>` : ''}
    <tr class="total"><td>Votos emitidos</td><td class="n">${esc(c.emitidos)}</td><td></td></tr></tbody></table>`).join('');
  imprimir(`Resultados por mesa · ${proceso.nombre}`, `
    ${encabezado('Resultados por mesa y consolidado', `${esc(proceso.nombre)} · ${esc(proceso.estado)}`)}
    ${totales}
    <h2>Resultados por mesa (actas de escrutinio de las mesas no anuladas)</h2>
    <table><thead><tr><th>Mesa</th><th>Cargo</th><th>Opción</th><th class="n">Votos</th></tr></thead><tbody>${cuerpo || '<tr><td colspan="4">Sin actas de escrutinio.</td></tr>'}</tbody></table>
    <footer>Emitido el ${esc(fecha(new Date()))}.</footer>`);
}
