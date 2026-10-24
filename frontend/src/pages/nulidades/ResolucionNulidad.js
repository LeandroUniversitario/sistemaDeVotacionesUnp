import { svgQR, fecha } from '../credenciales/LectorQR';
import { esc, firmasPleno, imprimir } from '../computo/ActaComputo';

/**
 * CUS15 · Impresiones de nulidades y segunda vuelta: cargo de recepción del recurso,
 * resolución del Pleno con QR (RF100, RF101), oficios a SUNEDU, la Asamblea y el Consejo
 * Universitario (RF102), acta del sorteo que dirime un empate y convocatoria de la segunda
 * vuelta (RN33). El QR de la resolución apunta a /api/publico/nulidad/{token}, que recalcula
 * el SHA-256 de su contenido. Usa el mismo formato de hoja que las actas del CUS14.
 */

export const urlVerificacionNulidad = (token) => `${window.location.origin}/api/publico/nulidad/${token}`;
const pct = (v) => `${Number(v ?? 0).toFixed(2)} %`;

export const CAUSAL = {
  INSTALACION_IRREGULAR: 'Instalación irregular de la mesa',
  FRAUDE_MESA: 'Fraude, cohecho o violencia en la mesa',
  ADMISION_INDEBIDA: 'Admisión de votos de quienes no figuran en el padrón',
  ACTA_NO_AUTENTICA: 'Acta no auténtica o alterada',
  OTRA_CAUSAL: 'Otra causal grave del reglamento',
  FRAUDE: 'Fraude',
  COHECHO: 'Cohecho',
  SOBORNO: 'Soborno',
  INTIMIDACION: 'Intimidación',
  VIOLENCIA: 'Violencia',
  PARTICIPACION_INSUFICIENTE: 'Participación insuficiente (RN31)',
};
export const DESTINATARIO = {
  SUNEDU: 'SUNEDU',
  ASAMBLEA_UNIVERSITARIA: 'Asamblea Universitaria',
  CONSEJO_UNIVERSITARIO: 'Consejo Universitario',
  PORTAL: 'Portal electoral',
  EL_PERUANO: 'Diario oficial El Peruano',
};
const OPCION = { BLANCO: 'Votos en blanco', NULO: 'Votos nulos', IMPUGNADO: 'Impugnados sin resolver' };
const DECISION = { FUNDADA: 'Fundada', INFUNDADA: 'Infundada', IMPROCEDENTE: 'Improcedente', PRESENTADA: 'Pendiente' };

const encabezado = (titulo, subtitulo, sello, token) => `
  <header>
    <div>
      <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
      <h1>${esc(titulo)}</h1>
      <p>${subtitulo}</p>
      ${sello ?? ''}
    </div>
    ${token ? `<div class="qr">${svgQR(urlVerificacionNulidad(token))}Verificación de la resolución</div>` : ''}
  </header>`;

const objeto = (n) => (n.alcance === 'PARCIAL'
  ? `nulidad de la votación de la mesa ${esc(n.numeroMesa ?? n.mesa)}`
  : 'nulidad total de la elección');

/** 1 / 5 ingresarNulidad: cargo de recepción del recurso con su sustento. */
export function imprimirRecurso(n) {
  imprimir(`Recurso de nulidad N.º ${n.idNulidad}`, `
    ${encabezado(`Recurso de nulidad N.º ${String(n.idNulidad).padStart(5, '0')}`, `${esc(n.proceso)} · ${n.alcance === 'PARCIAL' ? 'Nulidad parcial (Art. 64)' : 'Nulidad total (Art. 65)'}`,
      `<span class="sello">${esc(DECISION[n.estado] ?? n.estado)}</span>`)}
    <dl>
      <div><dt>Presentado</dt><dd>${esc(fecha(n.fechaPresentacion))}</dd></div>
      <div><dt>Objeto</dt><dd>${n.alcance === 'PARCIAL' ? `Mesa ${esc(n.numeroMesa)}` : 'Toda la elección'}</dd></div>
      <div><dt>Causal</dt><dd>${esc(CAUSAL[n.causal] ?? n.causal)}</dd></div>
      <div><dt>Origen</dt><dd>${n.origen === 'PERSONERO' ? `Personero ${esc(n.tipoPersonero?.toLowerCase() ?? '')}` : 'De oficio (CEUNP)'}</dd></div>
    </dl>
    ${n.origen === 'PERSONERO' ? `<p class="texto"><strong>Recurrente:</strong> ${esc(n.personero)}, personero de la ${esc(n.listaPersonero)}.</p>` : ''}
    <h2>Sustento</h2><p class="texto">${esc(n.sustento)}</p>
    ${n.pruebas ? `<h2>Pruebas ofrecidas</h2><p class="texto">${esc(n.pruebas)}</p>` : ''}
    <p class="texto">El recurso se tramita ante el Pleno del CEUNP. Mientras esté pendiente, ${n.alcance === 'PARCIAL' ? 'no se realiza el cómputo general' : 'no se proclaman resultados ni se convoca la segunda vuelta'} (RF94).</p>
    <div class="firmas">
      <div class="firma"><div class="linea"></div><strong>${n.origen === 'PERSONERO' ? esc(n.personero) : 'Presidente del CEUNP'}</strong><span>${n.origen === 'PERSONERO' ? 'Recurrente' : 'De oficio'}</span></div>
      <div class="firma"><div class="linea"></div><strong>Secretario del CEUNP</strong><span>Recibido por: ${esc(n.registradoPor ?? '')}</span></div>
    </div>
    <footer>Emitido el ${esc(fecha(new Date()))}.</footer>`);
}

/** 2-4 / 6-7: resolución del Pleno que declara fundada, infundada o improcedente la nulidad. */
export function imprimirResolucion(n, token) {
  const d = n.documento ?? {};
  const fundada = d.decision === 'FUNDADA';
  const excluidos = (d.votos_excluidos ?? []).map((v) => `<tr><td>${esc(v.cargo)}</td><td>${esc(OPCION[v.opcion] ?? v.lista)}</td><td class="n">${esc(v.votos)}</td></tr>`).join('');
  const p = d.pleno ?? {};
  imprimir(`Resolución ${d.resolucion}`, `
    ${encabezado(`Resolución N.º ${d.resolucion}`, `${esc(d.proceso)} · ${d.vuelta === 'SEGUNDA_VUELTA' ? 'Segunda vuelta' : 'Primera vuelta'}`,
      `<span class="sello ${fundada ? 'nulo' : 'ok'}">Nulidad ${d.alcance === 'PARCIAL' ? 'parcial' : 'total'} · ${esc(DECISION[d.decision] ?? d.decision)}</span>`, token)}
    <dl>
      <div><dt>Fecha</dt><dd>${esc(fecha(d.fecha))}</dd></div>
      <div><dt>Recurso</dt><dd>N.º ${esc(d.id_nulidad)} · ${d.origen === 'PERSONERO' ? 'personero' : 'de oficio'}</dd></div>
      <div><dt>Causal</dt><dd>${esc(CAUSAL[d.causal] ?? d.causal)}</dd></div>
      <div><dt>Votación del Pleno (RN36)</dt><dd>${esc(p.a_favor)} a favor · ${esc(p.en_contra)} en contra de ${esc(p.miembros)}${p.voto_dirimente ? ' · voto dirimente' : ''}</dd></div>
    </dl>
    <p class="texto" style="margin-top:4mm"><strong>VISTO</strong> el recurso de ${objeto({ alcance: d.alcance, mesa: d.mesa })} ${d.origen === 'PERSONERO' && d.personero ? `interpuesto por ${esc(d.personero.nombre)} (DNI ${esc(d.personero.dni)}), personero de la ${esc(d.personero.lista)}` : 'promovido de oficio por el CEUNP'}, por la causal de ${esc((CAUSAL[d.causal] ?? d.causal).toLowerCase())}, con el sustento siguiente: «${esc(d.sustento)}».</p>
    <p class="texto"><strong>CONSIDERANDO:</strong> ${esc(d.fundamento)}</p>
    ${d.participacion ? `<p class="texto">Participación del proceso: ${esc(d.participacion.votaron)} de ${esc(d.participacion.electores)} electores hábiles (${pct(d.participacion.porcentaje)}; mínimo ${pct(d.participacion.quorum_minimo)}).</p>` : ''}
    <p class="texto"><strong>SE RESUELVE:</strong> declarar <strong>${esc((DECISION[d.decision] ?? d.decision).toUpperCase())}</strong> el recurso. ${esc(d.efecto)}</p>
    ${excluidos ? `<h2>Votos de la mesa ${esc(d.mesa)} excluidos del cómputo</h2><table><thead><tr><th>Cargo</th><th>Opción</th><th class="n">Votos</th></tr></thead><tbody>${excluidos}</tbody></table>` : ''}
    ${d.comunicar_a ? `<p class="texto">Comuníquese a ${esc(d.comunicar_a.join(', '))} y publíquese en el portal electoral (RF102).</p>` : ''}
    <p class="texto">La decisión del CEUNP es inapelable (RN36).</p>
    ${firmasPleno()}
    <footer>Huella SHA-256 de la resolución: ${esc(n.hashIntegridad)}${token ? '' : ' · Reimpresión sin QR: el código solo se entrega al emitir la resolución.'}</footer>`);
}

/** 8 registrarComunicacion('SUNEDU, AU, CU'): un oficio por destinatario (RF102, Art. 66). */
export function imprimirOficios(n, destinos) {
  const d = n.documento ?? {};
  const lista = destinos?.length ? destinos : ['SUNEDU', 'ASAMBLEA_UNIVERSITARIA', 'CONSEJO_UNIVERSITARIO'];
  imprimir(`Oficios · Resolución ${d.resolucion}`, lista.map((x) => {
    const c = (n.comunicaciones ?? []).find((y) => y.destinatario === x);
    return `<section class="hoja">
    ${encabezado(c?.documento ? `Oficio ${c.documento}` : 'Oficio', esc(d.proceso), '<span class="sello nulo">Comunicación de nulidad</span>')}
    <p style="margin-top:6mm">Piura, ${esc(fecha(c?.fechaEnvio ?? new Date()))}</p>
    <p><strong>Señores:</strong><br>${esc(DESTINATARIO[x] ?? x)}<br>Presente.-</p>
    <p class="texto"><strong>Asunto:</strong> comunica la Resolución N.º ${esc(d.resolucion)} del Comité Electoral.</p>
    <p class="texto">Tengo el agrado de dirigirme a ustedes para comunicarles que el Pleno del Comité Electoral de la Universidad Nacional de Piura, en sesión del ${esc(fecha(d.fecha))}, declaró <strong>${esc((DECISION[d.decision] ?? '').toUpperCase())}</strong> la ${objeto({ alcance: d.alcance, mesa: d.mesa })} del proceso «${esc(d.proceso)}», por la causal de ${esc((CAUSAL[d.causal] ?? d.causal ?? '').toLowerCase())}.</p>
    <p class="texto">${esc(d.efecto)}</p>
    <p class="texto">Se adjunta copia de la resolución, cuya autenticidad puede verificarse con su huella SHA-256: <code>${esc(n.hashIntegridad)}</code>.</p>
    <p>Atentamente,</p>
    ${firmasPleno()}
  </section>`;
  }).join(''));
}

/** Acta del sorteo del Pleno que dirime un empate (pase a la segunda vuelta o empate en ella). */
export function imprimirActaSorteo(proceso, cargo) {
  const d = cargo.dirimencia ?? {};
  const empatadas = (d.listasEmpatadas ?? []).map((l) => `<tr class="${(d.listasElegidas ?? []).includes(l.id_lista) ? 'gana' : ''}"><td>${esc(l.lista)}</td><td class="n">${esc(l.votos)}</td><td>${(d.listasElegidas ?? []).includes(l.id_lista) ? 'Elegida por sorteo' : '—'}</td></tr>`).join('');
  const pase = d.motivo === 'PASE_A_SEGUNDA_VUELTA';
  imprimir(`Sorteo · ${cargo.cargo}`, `
    ${encabezado(`Resolución N.º ${d.numeroResolucion}`, `${esc(proceso.nombre)} · ${esc(cargo.cargo)}`,
      `<span class="sello">${pase ? 'Sorteo del pase a la segunda vuelta' : 'Sorteo del empate en segunda vuelta'}</span>`)}
    <dl>
      <div><dt>Fecha</dt><dd>${esc(fecha(d.fecha))}</dd></div>
      <div><dt>Miembros del Pleno</dt><dd>${esc(d.miembrosPleno)}</dd></div>
      <div><dt>Cupos sorteados</dt><dd>${esc(d.cupos)}</dd></div>
      <div><dt>Semilla pública</dt><dd>${esc(d.semilla)}</dd></div>
    </dl>
    <p class="texto" style="margin-top:4mm">${pase
      ? `Las listas siguientes empataron en votos por ${esc(d.cupos)} cupo(s) de la segunda vuelta (RN33).`
      : 'Las listas finalistas empataron en la segunda vuelta (RF97).'} Ante los personeros presentes, el Pleno anunció la semilla del sorteo y el sistema ordenó las listas por la huella SHA-256 de «semilla | cargo | lista», de modo que cualquiera puede repetirlo y verificarlo.</p>
    <table><thead><tr><th>Lista empatada</th><th class="n">Votos</th><th>Resultado</th></tr></thead><tbody>${empatadas}</tbody></table>
    ${d.fundamento ? `<h2>Fundamento</h2><p class="texto">${esc(d.fundamento)}</p>` : ''}
    <p class="texto"><strong>SE RESUELVE:</strong> ${pase ? 'que pasen a la segunda vuelta las listas elegidas por sorteo.' : 'proclamar a la lista elegida por sorteo como ganadora del cargo.'}</p>
    ${firmasPleno()}
    <footer>Huella SHA-256 del sorteo: ${esc(d.hashIntegridad)}</footer>`);
}

/** 10-15 convocarSegundaVuelta / mostrarSegundaVuelta: convocatoria con las listas finalistas. */
export function imprimirConvocatoriaSegunda(proceso, sv) {
  const filas = (sv.listasFinalistas ?? []).map((l) => `<tr><td>${esc(l.cargo)}</td><td>${l.ordenCedula != null ? `${esc(l.ordenCedula)}. ` : ''}${esc(l.lista)}</td><td class="n">${esc(l.candidatos)}</td></tr>`).join('');
  imprimir(`Convocatoria · ${sv.nombre}`, `
    ${encabezado('Convocatoria a segunda vuelta', `${esc(sv.nombre)} · proceso N.º ${esc(sv.id)}`, '<span class="sello ok">Segunda vuelta (RN33)</span>')}
    <dl>
      <div><dt>Primera vuelta</dt><dd>${esc(proceso.nombre)}</dd></div>
      <div><dt>Votación</dt><dd>${esc(fecha(sv.fechaInicio))} al ${esc(fecha(sv.fechaFin))}</dd></div>
      <div><dt>Padrón</dt><dd>${esc(sv.padron)} electores</dd></div>
      <div><dt>Estado</dt><dd>${esc(sv.estado)}</dd></div>
    </dl>
    <p class="texto" style="margin-top:4mm">El Comité Electoral de la Universidad Nacional de Piura, visto el cómputo oficial de la primera vuelta del ${esc(fecha(proceso.fechaComputo))}, en el que ninguna lista superó el porcentaje mínimo de votos válidos, convoca a segunda vuelta entre las dos listas más votadas de cada cargo, con el mismo padrón electoral (RN33).</p>
    <table><thead><tr><th>Cargo</th><th>Lista finalista</th><th class="n">Candidatos</th></tr></thead><tbody>${filas}</tbody></table>
    <p class="texto">Gana la lista que obtenga la mitad más uno de los votos válidos. La preparación (mesas, miembros y cédula) continúa en Convocatoria y cronograma.</p>
    ${firmasPleno()}
    <footer>Emitida el ${esc(fecha(new Date()))}.</footer>`);
}
