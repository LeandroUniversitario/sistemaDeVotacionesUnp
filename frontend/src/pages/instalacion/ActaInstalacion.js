import { svgQR, fecha } from '../credenciales/LectorQR';

/**
 * CUS08 · Impresión del Acta de Instalación (RN28).
 * El QR apunta a la verificación pública del acta (/verificar/{token}, portal del CUS17),
 * que recalcula el SHA-256 del contenido y lo compara con la huella guardada.
 */

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const CARGO = { PRESIDENTE: 'Presidente', SECRETARIO: 'Secretario', VOCAL: 'Vocal', SUPLENTE: 'Suplente' };
const MATERIAL = {
  PADRON: 'Padrón de electores',
  ACTAS: 'Actas electorales',
  CEDULAS: 'Cédulas de sufragio',
  CARTEL_CANDIDATOS: 'Cartel de candidatos',
  ANFORA: 'Ánfora',
  CABINA: 'Cabina o cámara secreta',
};
const ESTADO = { CONFORME: 'Conforme', OBSERVADO: 'Observado', NO_RECIBIDO: 'No recibido' };

export const urlVerificacionActa = (token) => `${window.location.origin}/verificar/${token}`;

export function imprimirActaInstalacion(acta, mesa, token) {
  const c = acta.contenido ?? {};
  const miembros = (c.miembros ?? []).map((m) => `<tr>
      <td>${esc(m.docente)}<br><small>DNI ${esc(m.dni)}</small></td>
      <td>${esc(CARGO[m.rol_sorteo] ?? m.rol_sorteo)}${m.titular ? ' (titular)' : ''}</td>
      <td>${m.asistio ? `Presente · ${esc(m.metodo ?? '')} ${esc((m.hora_llegada ?? '').slice(11, 16))}` : 'No asistió'}</td>
      <td>${esc(CARGO[m.rol_instalacion] ?? '—')}</td></tr>`).join('');
  const personeros = (c.personeros ?? []).map((p) => `<tr>
      <td>${esc(p.docente)}<br><small>DNI ${esc(p.dni)}</small></td><td>${esc(p.lista)}</td>
      <td>${esc(p.tipo)}</td><td>${esc((p.hora_llegada ?? '').slice(11, 16))}</td></tr>`).join('');
  const reemplazantes = (c.reemplazantes ?? []).map((r) => `<tr>
      <td>${esc(r.docente)}<br><small>DNI ${esc(r.dni)}</small></td><td>${esc(CARGO[r.cargo] ?? r.cargo)}</td>
      <td>${esc((r.hora_llegada ?? '').slice(11, 16))}</td></tr>`).join('');
  const material = Object.entries(c.material ?? {}).map(([k, v]) =>
    `<tr><td>${esc(MATERIAL[k] ?? k)}</td><td>${esc(ESTADO[v?.estado] ?? v?.estado)}</td><td>${esc(v?.observacion ?? '')}</td></tr>`).join('');
  const firmas = (acta.firmas ?? []).map((f) => `<div class="firma">
      <div class="linea"></div><strong>${esc(f.nombre)}</strong><span>${esc(f.rol)} · DNI ${esc(f.dni)}</span>
      <code>${esc(f.firmaDigital?.slice(0, 24))}…</code></div>`).join('');

  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Acta de Instalación · Mesa ${esc(c.mesa)}</title>
    <style>
      @page { size: A4; margin: 14mm; }
      * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; color: #0f172a; font-size: 9.5pt; }
      header { display: flex; justify-content: space-between; gap: 6mm; border-bottom: .6mm solid #0f172a; padding-bottom: 3mm; }
      header h1 { margin: 0 0 1mm; font-size: 14pt; } header p { margin: 0; color: #334155; }
      .qr { width: 32mm; text-align: center; font-size: 6.5pt; color: #64748b; } .qr svg { width: 32mm; height: 32mm; display: block; }
      h2 { font-size: 10.5pt; margin: 5mm 0 2mm; }
      dl { display: grid; grid-template-columns: repeat(5, 1fr); gap: 2mm; margin: 3mm 0 0; }
      dt { font-size: 7pt; text-transform: uppercase; color: #64748b; } dd { margin: 0; font-weight: 600; }
      table { width: 100%; border-collapse: collapse; } th, td { border: .2mm solid #cbd5e1; padding: 1.5mm 2mm; text-align: left; vertical-align: top; }
      th { background: #f1f5f9; font-size: 8pt; } small { color: #64748b; }
      .firmas { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8mm 6mm; margin-top: 12mm; }
      .firma { display: grid; gap: .8mm; text-align: center; } .firma .linea { border-top: .3mm solid #0f172a; margin-bottom: 1mm; }
      .firma span { font-size: 8pt; color: #334155; } .firma code { font-size: 6.5pt; color: #64748b; }
      footer { margin-top: 8mm; font-size: 7pt; color: #64748b; word-break: break-all; }
    </style></head><body>
    <header>
      <div>
        <p>Universidad Nacional de Piura · Comité Electoral (CEUNP)</p>
        <h1>Acta de Instalación de Mesa de Sufragio</h1>
        <p>${esc(c.proceso)} · Acta N.º ${String(acta.idActa).padStart(6, '0')}</p>
      </div>
      ${token ? `<div class="qr">${svgQR(urlVerificacionActa(token))}Verificación del acta</div>` : ''}
    </header>
    <dl>
      <div><dt>Mesa</dt><dd>${esc(c.mesa)}</dd></div>
      <div><dt>Local</dt><dd>${esc(c.ubicacion ?? mesa?.ubicacion)}</dd></div>
      <div><dt>Hora de instalación</dt><dd>${esc(c.hora_instalacion)}</dd></div>
      <div><dt>Electores de la mesa</dt><dd>${esc(c.total_electores)}</dd></div>
      <div><dt>Cédulas recibidas</dt><dd>${esc(c.cedulas_recibidas)} (firmadas por el presidente)</dd></div>
    </dl>
    <h2>Miembros de mesa</h2>
    <table><thead><tr><th>Miembro</th><th>Sorteado como</th><th>Asistencia</th><th>Cargo en la instalación</th></tr></thead><tbody>${miembros}</tbody></table>
    ${reemplazantes ? `<h2>Reemplazantes de la comunidad universitaria</h2>
    <table><thead><tr><th>Docente</th><th>Cargo que asume</th><th>Hora</th></tr></thead><tbody>${reemplazantes}</tbody></table>` : ''}
    <h2>Personeros presentes</h2>
    ${personeros ? `<table><thead><tr><th>Personero</th><th>Lista</th><th>Tipo</th><th>Hora</th></tr></thead><tbody>${personeros}</tbody></table>` : '<p>No se presentaron personeros.</p>'}
    <h2>Material electoral recibido</h2>
    <table><thead><tr><th>Material</th><th>Estado</th><th>Observación</th></tr></thead><tbody>${material}</tbody></table>
    <h2>Observaciones</h2>
    <p>${esc(c.observaciones ?? 'Ninguna.')}</p>
    <div class="firmas">${firmas}</div>
    <footer>Emitida el ${esc(fecha(acta.fechaEmision))}. Huella SHA-256 del contenido: ${esc(acta.hashIntegridad)}</footer>
    </body></html>`;

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
