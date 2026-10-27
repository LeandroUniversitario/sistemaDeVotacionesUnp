import { svgQR, fecha } from '../credenciales/LectorQR';
import { esc, imprimir, ESTADO_RESULTADO } from '../computo/ActaComputo';

/**
 * CUS17 · Impresiones de la consulta de resultados y de la verificación de actas: resultados
 * generales por cargo (RF99), resultados por mesa, constancia de verificación de un documento
 * (RF55) y hoja de cotejo del ejemplar físico con el documento digital. Usa el mismo formato de
 * hoja que las actas del CUS14.
 *
 * Todos los QR del sistema apuntan a /verificar/{token}, la página pública de verificación, que
 * consulta /api/publico/verificacion/{token} y recalcula el SHA-256 del documento.
 */

export const urlVerificacion = (codigo) => `${window.location.origin}/verificar/${codigo}`;
export const urlResultados = (idProceso) => `${window.location.origin}/resultados${idProceso ? `?proceso=${idProceso}` : ''}`;
export const pct = (v) => `${Number(v ?? 0).toFixed(2)} %`;

export const TIPO_DOCUMENTO = {
  ACTA_INSTALACION: 'Acta de instalación',
  ACTA_SUFRAGIO: 'Acta de sufragio',
  ACTA_ESCRUTINIO: 'Acta de escrutinio',
  COMPUTO_GENERAL: 'Acta general de cómputo',
  PROCLAMACION: 'Resolución de proclamación',
  RESOLUCION_NULIDAD: 'Resolución de nulidad',
  RESOLUCION_MULTAS: 'Resolución de multas',
  CONSTANCIA_VOTO: 'Constancia de voto',
};
export const RESULTADO_VERIFICACION = {
  AUTENTICA: { clase: 'ok', titulo: 'Documento auténtico', icono: 'check', sello: 'ok' },
  ALTERADA: { clase: 'mal', titulo: 'Documento alterado', icono: 'alert', sello: 'nulo' },
  ANULADA: { clase: 'aviso', titulo: 'Documento íntegro sin efecto', icono: 'info', sello: 'nulo' },
  NO_ENCONTRADA: { clase: 'mal', titulo: 'Documento no encontrado', icono: 'close', sello: 'nulo' },
};
export const METODO = { TOKEN: 'Código QR', HUELLA: 'Huella SHA-256' };
export const ESTADO_COTEJO = { CONFORME: 'Conforme', OBSERVADO: 'Discrepancia reportada', ATENDIDO: 'Atendido por el CEUNP' };
export const DECISION_COTEJO = { ACLARADA: 'Aclarada', FUNDADA: 'Fundada: procede la revisión' };
export const ROL_USUARIO = {
  DOCENTE: 'Docente elector', PERSONERO: 'Personero', MIEMBRO_MESA: 'Miembro de mesa', CEUNP: 'CEUNP', ADMIN: 'Administrador',
};

const encabezado = (titulo, subtitulo, sello, qr, pie) => `
  <header>
    <div>
      <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
      <h1>${esc(titulo)}</h1>
      <p>${subtitulo}</p>
      ${sello ?? ''}
    </div>
    ${qr ? `<div class="qr">${svgQR(qr)}${esc(pie ?? 'Verificación')}</div>` : ''}
  </header>`;

const vuelta = (tipo) => (tipo === 'SEGUNDA_VUELTA' ? 'Segunda vuelta' : 'Primera vuelta');

/** 6 mostrarResultados(): resultados generales por cargo, con la participación y la proclamación. */
export function imprimirResultados(detalle) {
  const p = detalle.proceso;
  const nulo = p.resultado === 'NULIDAD_TOTAL';
  const cargos = detalle.cargos.map((c) => `
    <h2>${esc(c.cargo)} · ${esc(ESTADO_RESULTADO[c.estadoResultado] ?? c.estadoResultado)}</h2>
    <table>
      <thead><tr><th class="n">N.º</th><th>Lista</th><th class="n">Votos</th><th class="n">% válidos</th></tr></thead>
      <tbody>
        ${c.listas.map((l) => `<tr class="${l.ganadora ? 'gana' : ''}"><td class="n">${l.posicion ?? ''}</td>
          <td>${esc(l.lista)}${l.formula ? `<br><small>${esc(l.formula)}</small>` : ''}</td>
          <td class="n">${l.votos}</td><td class="n">${pct(l.porcentajeValidos)}</td></tr>`).join('')}
        <tr class="total"><td></td><td>Votos válidos</td><td class="n">${c.validos}</td><td class="n">100.00 %</td></tr>
        <tr><td></td><td>Votos en blanco</td><td class="n">${c.blancos}</td><td></td></tr>
        <tr><td></td><td>Votos nulos</td><td class="n">${c.nulos}</td><td></td></tr>
        <tr class="total"><td></td><td>Votos emitidos</td><td class="n">${c.emitidos}</td><td></td></tr>
      </tbody>
    </table>
    <p><small>Participación ${pct(c.participacionPct)} (${c.votaron ?? 0} de ${c.electoresHabiles ?? 0} electores hábiles).
      ${c.listaGanadora ? `Lista ganadora: <strong>${esc(c.listaGanadora)}</strong>${c.codigoCredencial ? ` · credencial ${esc(c.codigoCredencial)}` : ''}.` : ''}</small></p>`).join('');
  imprimir(`Resultados · ${p.proceso}`, `
    <section class="hoja">
      ${encabezado('Resultados de la elección', `${esc(p.proceso)} · ${vuelta(p.tipo)}`,
        `<span class="sello ${nulo ? 'nulo' : 'ok'}">${nulo ? 'Nulidad total' : 'Elección válida'}</span>`,
        urlResultados(p.idProceso), 'Resultados en el portal')}
      <dl>
        <div><dt>Electores hábiles</dt><dd>${p.electoresHabiles ?? '—'}</dd></div>
        <div><dt>Votaron</dt><dd>${p.votaron ?? '—'}</dd></div>
        <div><dt>Participación</dt><dd>${pct(p.participacionPct)} (mínimo ${pct(p.quorumMinimo)})</dd></div>
        <div><dt>${p.numeroResolucion ? 'Resolución de proclamación' : 'Cómputo'}</dt><dd>${esc(p.numeroResolucion ?? fecha(p.fechaComputo))}</dd></div>
      </dl>
      ${cargos}
      <footer>RF99 · Publicado ${esc(fecha(p.fechaPublicacion ?? p.fechaComputo))}. Consulta impresa el ${esc(fecha(new Date()))}. Las actas de cada mesa se verifican con su QR en ${esc(urlVerificacion('…'))}.</footer>
    </section>`);
}

/** 5 devolverResultados(): resultados por mesa de un cargo. */
export function imprimirResultadosMesas(detalle, idCargo) {
  const p = detalle.proceso;
  const cargo = detalle.cargos.find((c) => c.idCargo === idCargo) ?? detalle.cargos[0];
  if (!cargo) return;
  const columnas = [...cargo.listas.map((l) => ({ clave: `LISTA-${l.idLista}`, titulo: l.lista })),
    { clave: 'BLANCO', titulo: 'Blanco' }, { clave: 'NULO', titulo: 'Nulo' }];
  const filas = detalle.mesas.map((m) => {
    const c = m.cargos.find((x) => x.idCargo === cargo.idCargo);
    const valor = (k) => c?.opciones.find((o) => (o.opcion === 'LISTA' ? `LISTA-${o.idLista}` : o.opcion) === k)?.votos ?? 0;
    return `<tr><td>${esc(m.numeroMesa)}${m.estadoMesa === 'ANULADA' ? ' <small>(anulada)</small>' : ''}</td>
      <td class="n">${m.votaron ?? '—'} / ${m.electores ?? '—'}</td>
      ${columnas.map((k) => `<td class="n">${valor(k.clave)}</td>`).join('')}<td class="n"><strong>${c?.total ?? 0}</strong></td></tr>`;
  }).join('');
  imprimir(`Resultados por mesa · ${p.proceso}`, `
    <section class="hoja">
      ${encabezado('Resultados por mesa', `${esc(p.proceso)} · ${esc(cargo.cargo)}`, '', urlResultados(p.idProceso), 'Resultados en el portal')}
      <h2>${esc(cargo.cargo)}</h2>
      <table>
        <thead><tr><th>Mesa</th><th class="n">Votaron</th>${columnas.map((k) => `<th class="n">${esc(k.titulo)}</th>`).join('')}<th class="n">Total</th></tr></thead>
        <tbody>${filas}</tbody>
      </table>
      <footer>RF99 · Cifras del acta de escrutinio de cada mesa (con las impugnaciones resueltas) o, en el cierre sin CUS12, del conteo de la urna.</footer>
    </section>`);
}

/** 11 mostrarAutenticidad(): constancia de la verificación de un documento. */
export function imprimirConstanciaVerificacion(v, codigo) {
  const r = RESULTADO_VERIFICACION[v.resultado] ?? RESULTADO_VERIFICACION.NO_ENCONTRADA;
  imprimir(`Verificación N.º ${v.idVerificacion}`, `
    <section class="hoja">
      ${encabezado('Constancia de verificación de documento', `N.º ${String(v.idVerificacion).padStart(6, '0')} · ${esc(fecha(new Date()))}`,
        `<span class="sello ${r.sello}">${esc(r.titulo)}</span>`, codigo ? urlVerificacion(codigo) : null, 'Volver a verificar')}
      <dl>
        <div><dt>Documento</dt><dd>${esc(TIPO_DOCUMENTO[v.tipoDocumento] ?? '—')}</dd></div>
        <div><dt>Proceso</dt><dd>${esc(v.proceso ?? '—')}</dd></div>
        <div><dt>Mesa</dt><dd>${esc(v.numeroMesa ?? '—')}</dd></div>
        <div><dt>Emitido</dt><dd>${esc(fecha(v.fechaEmision))}</dd></div>
        <div><dt>Estado</dt><dd>${esc(v.estado ?? '—')}</dd></div>
        <div><dt>Resolución</dt><dd>${esc(v.numeroResolucion ?? '—')}</dd></div>
        <div><dt>Verificado por</dt><dd>${esc(METODO[v.metodo] ?? '—')}</dd></div>
        <div><dt>Veces verificado</dt><dd>${v.vecesVerificado ?? 0}</dd></div>
      </dl>
      <h2>10 recalcularHash()</h2>
      <table>
        <tr><th>Huella registrada al emitir</th><td><code>${esc(v.hashGuardado ?? '—')}</code></td></tr>
        <tr><th>Huella recalculada ahora</th><td><code>${esc(v.hashRecalculado ?? '—')}</code></td></tr>
        <tr><th>Resultado</th><td><strong>${esc(r.titulo)}</strong> · ${esc(v.mensaje)}</td></tr>
      </table>
      ${v.cifras?.length ? `<h2>Cifras del documento digital</h2><table><thead><tr><th>Grupo</th><th>Concepto</th><th class="n">Cifra</th></tr></thead>
        <tbody>${v.cifras.map((c) => `<tr><td>${esc(c.grupo)}</td><td>${esc(c.etiqueta)}</td><td class="n">${c.digital}</td></tr>`).join('')}</tbody></table>` : ''}
      <footer>RF52 · RF55 · La huella SHA-256 se calcula sobre el contenido del documento digital. Si no coincide con la registrada, el documento fue alterado.</footer>
    </section>`);
}

/** Hoja del cotejo del ejemplar físico con el documento digital. */
export function imprimirCotejo(k) {
  const lineas = k.cifras ?? k.lineas ?? [];
  imprimir(`Cotejo N.º ${k.idCotejo}`, `
    <section class="hoja">
      ${encabezado('Cotejo del acta física con la digital', `N.º ${String(k.idCotejo).padStart(5, '0')} · ${esc(k.proceso ?? '')}`,
        `<span class="sello ${k.estado === 'CONFORME' ? 'ok' : 'nulo'}">${esc(ESTADO_COTEJO[k.estado] ?? k.estado)}</span>`)}
      <dl>
        <div><dt>Documento</dt><dd>${esc(TIPO_DOCUMENTO[k.tipoDocumento] ?? k.tipoDocumento)}</dd></div>
        <div><dt>Mesa</dt><dd>${esc(k.numeroMesa ?? '—')}</dd></div>
        <div><dt>Registrado por</dt><dd>${esc(k.registradoPor ?? k.username ?? '—')} · ${esc(ROL_USUARIO[k.rol] ?? k.rol ?? '')}${k.listaPersonero ? ` (${esc(k.listaPersonero)})` : ''}</dd></div>
        <div><dt>Fecha</dt><dd>${esc(fecha(k.fecha))}</dd></div>
      </dl>
      <table>
        <thead><tr><th>Grupo</th><th>Concepto</th><th class="n">Documento digital</th><th class="n">Ejemplar físico</th><th>¿Coincide?</th></tr></thead>
        <tbody>${lineas.map((l) => `<tr${l.coincide ? '' : ' style="background:#fff1f2;font-weight:700"'}><td>${esc(l.grupo)}</td><td>${esc(l.etiqueta)}</td>
          <td class="n">${l.digital}</td><td class="n">${l.fisico}</td><td>${l.coincide ? 'Sí' : '<strong>No</strong>'}</td></tr>`).join('')}</tbody>
      </table>
      ${k.observacion ? `<h2>Discrepancia reportada</h2><p class="texto">${esc(k.observacion)}</p>` : ''}
      ${k.respuesta ? `<h2>Respuesta del CEUNP · ${esc(DECISION_COTEJO[k.decision] ?? k.decision)}</h2><p class="texto">${esc(k.respuesta)}</p>
        <p><small>${esc(k.atendidoPor ?? '')} · ${esc(fecha(k.fechaRespuesta))}</small></p>` : ''}
      <footer>Huella del documento: ${esc(k.hashIntegridad ?? '')} · ${k.contenidoIntegro ? 'íntegra' : 'NO coincide con el contenido'}.</footer>
    </section>`);
}
