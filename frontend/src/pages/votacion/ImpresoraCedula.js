import { svgQR } from '../credenciales/LectorQR';

/**
 * CUS10 · «ImpresoraCedula» (boundary).
 *   11 imprimirCedula(opción): imprime la cédula con la elección para depositarla en el ánfora (RF70).
 *   12 confirmarImpresion(): la confirma la persona en el TerminalVotacion; si la impresión falla se
 *      reimprime desde la memoria temporal del terminal (CUS10 A2).
 * La cédula no lleva ningún dato del elector. La constancia de participación se imprime aparte, en la mesa.
 */

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

function imprimirHtml(titulo, cuerpo, estilos) {
  // iframe oculto: no abre ventanas que el elector pueda dejar abiertas en el terminal
  const marco = document.createElement('iframe');
  marco.style.cssText = 'position:fixed;right:0;bottom:0;width:0;height:0;border:0;';
  document.body.appendChild(marco);
  const doc = marco.contentDocument;
  doc.open();
  doc.write(`<!doctype html><html lang="es"><head><meta charset="utf-8"><title>${esc(titulo)}</title>
    <style>body{font-family:system-ui,sans-serif;color:#0f172a;margin:24px;} ${estilos}</style></head><body>${cuerpo}</body></html>`);
  doc.close();
  return new Promise((resolve) => {
    setTimeout(() => {
      try {
        marco.contentWindow.focus();
        marco.contentWindow.print();
        resolve(true);
      } catch {
        resolve(false);
      } finally {
        setTimeout(() => marco.remove(), 1000);
      }
    }, 150);
  });
}

/** 11 imprimirCedula(opción) */
export function imprimirCedula({ proceso, mesa, cedula }) {
  const lineas = cedula.map((l) => `
    <div class="linea"><span>${esc(l.cargo)}</span>
      <strong>${l.orden ? `${esc(l.orden)}. ` : ''}${esc(l.opcion)}${l.simbolo ? ` (${esc(l.simbolo)})` : ''}</strong></div>`).join('');
  return imprimirHtml('Cédula de sufragio', `
    <header><span>Universidad Nacional de Piura · Comité Electoral</span><h1>CÉDULA DE SUFRAGIO</h1>
      <span>${esc(proceso)} · Mesa ${esc(mesa)}</span></header>
    ${lineas}
    <footer>Revise que la cédula coincide con su elección, dóblela y deposítela en el ánfora.<br>
      Cédula sin datos del elector · firma del Presidente de mesa: ____________________</footer>`,
  `header{text-align:center;border-bottom:2px solid #0f172a;padding-bottom:8px;margin-bottom:16px}
   header h1{font-size:20px;margin:4px 0}header span{font-size:12px;color:#475569}
   .linea{display:flex;justify-content:space-between;gap:16px;padding:14px 0;border-bottom:1px dashed #94a3b8;font-size:15px}
   .linea strong{font-size:18px}footer{margin-top:24px;font-size:12px;color:#475569;text-align:center;line-height:1.6}`);
}

/** Constancia de participación (la entrega la mesa; no dice por quién votó). */
export function imprimirConstancia(constancia) {
  const url = (token) => `${window.location.origin}/verificar/${token}`;
  const qrs = constancia.cargos.map((c) => `
    <div class="qr"><strong>${esc(c.cargo)}</strong>${svgQR(url(c.token), { title: `Constancia de ${c.cargo}` })}</div>`).join('');
  return imprimirHtml('Constancia de sufragio', `
    <header><span>Universidad Nacional de Piura · CEUNP</span><h1>Constancia de sufragio</h1></header>
    <dl><dt>Proceso</dt><dd>${esc(constancia.proceso)}</dd><dt>Elector</dt><dd>${esc(constancia.elector.nombre)}</dd>
      <dt>DNI</dt><dd>${esc(constancia.elector.dni)}</dd><dt>Mesa</dt><dd>${esc(constancia.mesa.numero)} · ${esc(constancia.mesa.ubicacion)}</dd>
      <dt>Emitida</dt><dd>${esc(new Date(constancia.fechaEmision).toLocaleString('es-PE'))}</dd></dl>
    <div class="qrs">${qrs}</div>
    <p>Acredita la participación del docente en el sufragio. No revela el sentido del voto. Cada QR se verifica en línea.</p>`,
  `header{text-align:center;border-bottom:2px solid #059669;padding-bottom:8px}h1{font-size:18px;margin:4px 0}
   dl{display:grid;grid-template-columns:120px 1fr;gap:6px 12px;margin:16px 0}dt{font-weight:700}dd{margin:0}
   .qrs{display:flex;flex-wrap:wrap;gap:16px}.qr{display:grid;justify-items:center;gap:6px;width:180px;text-align:center}
   .qr svg{width:150px;height:150px}p{font-size:12px;color:#475569}`);
}
