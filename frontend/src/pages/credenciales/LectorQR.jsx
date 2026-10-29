import { useEffect, useMemo, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { encodeQR, qrToSvg } from '../../lib/qrcode';
import { qrSoloEnEstaPC, urlPublica } from '../../lib/urlPublica';
import MenuIcon from '../../components/MenuIcon';

/**
 * CUS07 · «LectorQR» (boundary).
 *
 *   6 renderizarQR(token_hash)   → CodigoQR / TarjetaCredencial dibujan el QR en el navegador
 *   7 mostrarCredencialLista()   → ListaCredencialesQR muestra en PantallaCredenciales lo emitido
 *
 * El QR se genera aquí mismo (lib/qrcode.js): el token nunca se envía a servicios externos.
 * Lleva la URL de la página pública /credencial/{código}: al escanearlo con un celular se ven
 * los datos del titular y si la credencial sigue vigente. La pistola lectora lee la misma URL
 * y el servidor extrae el código SICEUNP-…
 * También incluye la lectura de credenciales (pistola lectora o cámara) para verificarlas.
 */

export const TIPOS_CREDENCIAL = {
  ELECTOR: { titulo: 'Pase de votación', corto: 'Electores', color: '#2563eb', rf: 'RF62' },
  MIEMBRO_MESA: { titulo: 'Fotocheck de miembro de mesa', corto: 'Miembros de mesa', color: '#d97706', rf: 'RF56' },
  PERSONERO: { titulo: 'Credencial de personero', corto: 'Personeros', color: '#059669', rf: 'RF51' },
};

const fmtFecha = new Intl.DateTimeFormat('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
export const fecha = (v) => (v ? fmtFecha.format(new Date(v)) : '—');
export const numeroCredencial = (id) => `N.º ${String(id).padStart(6, '0')}`;

/** Contenido del QR: URL pública con el código SICEUNP (el «|» se cambia por «-» para la URL). */
export const urlCredencial = (qr) => urlPublica(`/credencial/${String(qr).replace(/\|/g, '-')}`);

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

/** 6: renderizarQR — SVG del código (nivel de corrección M: tolera manchas o pliegues). */
export function svgQR(valor, opciones = {}) {
  return qrToSvg(encodeQR(valor, 'M'), { margin: 4, ...opciones });
}

export function CodigoQR({ valor, size = 180, titulo = 'Código QR de la credencial' }) {
  const svg = useMemo(() => svgQR(valor, { title: titulo }), [valor, titulo]);
  return (
    <div className="cq-qr" style={{ width: size, height: size }} role="img" aria-label={titulo}
      // El SVG lo arma qrToSvg solo con rectángulos; el título va escapado.
      dangerouslySetInnerHTML={{ __html: svg }} />
  );
}

/** Credencial con los datos que se imprimen junto al QR. */
export function TarjetaCredencial({ credencial, proceso, size = 168 }) {
  const tipo = TIPOS_CREDENCIAL[credencial.tipo];
  return (
    <article className="cq-card" style={{ '--cq-color': tipo.color }}>
      <header>
        <span>Universidad Nacional de Piura · CEUNP</span>
        <strong>{tipo.titulo}</strong>
      </header>
      <CodigoQR valor={urlCredencial(credencial.qr)} size={size} titulo={`${tipo.titulo} de ${credencial.nombre}`} />
      <div className="cq-card-body">
        <strong>{credencial.nombre}</strong>
        <span>DNI {credencial.dni} · {credencial.funcion}</span>
        {credencial.numeroMesa && <span>Mesa {credencial.numeroMesa} · {credencial.ubicacion}</span>}
        {!credencial.numeroMesa && credencial.ubicacion && <span>{credencial.ubicacion}</span>}
      </div>
      <footer>
        <span>{proceso?.nombre}</span>
        <span>{numeroCredencial(credencial.idCredencial)} · vence {fecha(credencial.fechaExpiracion)}</span>
      </footer>
    </article>
  );
}

/** PNG del QR (para guardar en el celular o enviar a imprimir). */
export function descargarPNG(credencial, escala = 10) {
  const qr = encodeQR(urlCredencial(credencial.qr), 'M');
  const margen = 4;
  const lado = (qr.size + margen * 2) * escala;
  const canvas = document.createElement('canvas');
  canvas.width = lado;
  canvas.height = lado;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, lado, lado);
  ctx.fillStyle = '#0f172a';
  qr.modules.forEach((fila, y) => fila.forEach((oscuro, x) => {
    if (oscuro) ctx.fillRect((x + margen) * escala, (y + margen) * escala, escala, escala);
  }));
  const a = document.createElement('a');
  a.href = canvas.toDataURL('image/png');
  a.download = `credencial-${credencial.tipo.toLowerCase()}-${credencial.dni}-${credencial.idCredencial}.png`;
  document.body.appendChild(a);
  a.click();
  a.remove();
}

/** Imprime las credenciales (9 por hoja A4) desde un iframe oculto: no lo bloquea el navegador. */
export function imprimirCredenciales(credenciales, proceso) {
  const tarjetas = credenciales.map((c) => {
    const tipo = TIPOS_CREDENCIAL[c.tipo];
    return `<article style="--c:${tipo.color}">
      <header><span>Universidad Nacional de Piura · CEUNP</span><strong>${esc(tipo.titulo)}</strong></header>
      <div class="qr">${svgQR(urlCredencial(c.qr))}</div>
      <div class="body"><strong>${esc(c.nombre)}</strong><span>DNI ${esc(c.dni)} · ${esc(c.funcion)}</span>
      ${c.numeroMesa ? `<span>Mesa ${esc(c.numeroMesa)} · ${esc(c.ubicacion)}</span>` : c.ubicacion ? `<span>${esc(c.ubicacion)}</span>` : ''}</div>
      <footer><span>${esc(proceso?.nombre)}</span><span>${numeroCredencial(c.idCredencial)} · vence ${esc(fecha(c.fechaExpiracion))}</span></footer>
    </article>`;
  }).join('');
  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Credenciales QR · ${esc(proceso?.nombre)}</title>
    <style>
      @page { size: A4; margin: 10mm; }
      * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; color: #0f172a; }
      main { display: grid; grid-template-columns: repeat(3, 1fr); gap: 4mm; }
      article { display: flex; flex-direction: column; align-items: center; height: 88mm; padding: 0 0 3mm; border: 0.3mm dashed #94a3b8; border-radius: 3mm; overflow: hidden; break-inside: avoid; text-align: center; }
      header { width: 100%; padding: 2mm; background: var(--c); color: #fff; display: grid; gap: .5mm; }
      header span { font-size: 6.5pt; opacity: .9; } header strong { font-size: 8.5pt; }
      .qr { width: 40mm; height: 40mm; margin: 2mm 0 1mm; } .qr svg { width: 100%; height: 100%; display: block; }
      .body { display: grid; gap: .6mm; padding: 0 3mm; } .body strong { font-size: 8.5pt; } .body span { font-size: 7pt; color: #334155; }
      footer { margin-top: auto; display: grid; gap: .4mm; font-size: 6pt; color: #64748b; padding: 0 3mm; }
    </style></head><body><main>${tarjetas}</main></body></html>`;

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

const VISTA_PREVIA = 60;

/**
 * 7: mostrarCredencialLista() — credenciales recién emitidas. Es la ÚNICA vez que se ven
 * sus QR: el sistema solo guarda la huella SHA-256 del token.
 */
export function ListaCredencialesQR({ resultado, proceso, onCerrar }) {
  const { emitidas, rechazadas } = resultado;
  const [guardado, setGuardado] = useState(false);
  const [confirmarCierre, setConfirmarCierre] = useState(false);
  const cerrarRef = useRef(null);

  useEffect(() => { cerrarRef.current?.focus(); }, []);

  function imprimir() {
    imprimirCredenciales(emitidas, proceso);
    setGuardado(true);
  }

  function cerrar() {
    if (emitidas.length > 0 && !guardado && !confirmarCierre) {
      setConfirmarCierre(true);
      return;
    }
    onCerrar();
  }

  // Portal: el modal no debe quedar dentro del layout (el sidebar lo taparía)
  return createPortal(
    <div className="cq-overlay" role="dialog" aria-modal="true" aria-labelledby="cq-emitidas-titulo">
      <div className="cq-modal">
        <div className="cq-modal-head">
          <div>
            <h3 id="cq-emitidas-titulo">{resultado.mensaje}</h3>
            <p className="muted">Imprima o descargue ahora: por seguridad los códigos QR no se vuelven a mostrar. Si se pierde uno, vuelva a emitirlo (el anterior queda revocado).</p>
            {qrSoloEnEstaPC() && (
              <p className="cv-error"><MenuIcon name="alert" size={14} /> Estos QR apuntan a {new URL(urlPublica('/')).host}: un celular no podrá abrirlos. Configure VITE_URL_PUBLICA en frontend/.env.local (vea .env.example).</p>
            )}
          </div>
          <button type="button" ref={cerrarRef} className="cv-icon-btn" aria-label="Cerrar" onClick={cerrar}><MenuIcon name="close" size={18} /></button>
        </div>

        {rechazadas.length > 0 && (
          <details className="cq-rechazos" open={emitidas.length === 0}>
            <summary>{rechazadas.length} no emitida(s)</summary>
            <ul>{rechazadas.map((r) => <li key={r.idTitular}>{r.motivo}</li>)}</ul>
          </details>
        )}

        {emitidas.length > 0 && (
          <>
            <div className="cq-modal-actions">
              <button type="button" className="cv-btn cv-btn-primary" onClick={imprimir}>
                <MenuIcon name="file" size={15} /> Imprimir {emitidas.length > 1 ? `las ${emitidas.length} credenciales` : 'la credencial'}
              </button>
              {emitidas.length === 1 && (
                <button type="button" className="cv-btn cv-btn-ghost" onClick={() => { descargarPNG(emitidas[0]); setGuardado(true); }}>
                  <MenuIcon name="download" size={15} /> Descargar PNG
                </button>
              )}
            </div>
            <div className="cq-grid">
              {emitidas.slice(0, VISTA_PREVIA).map((c) => (
                <div key={c.idCredencial} className="cq-grid-item">
                  <TarjetaCredencial credencial={c} proceso={proceso} size={150} />
                  {c.reemplazaAnterior && <span className="cq-nota">Reemplaza a la credencial anterior (revocada)</span>}
                  {emitidas.length > 1 && (
                    <button type="button" className="cv-btn cv-btn-ghost cq-mini" onClick={() => descargarPNG(c)}>
                      <MenuIcon name="download" size={13} /> PNG
                    </button>
                  )}
                </div>
              ))}
            </div>
            {emitidas.length > VISTA_PREVIA && (
              <p className="muted cq-mas">… y {emitidas.length - VISTA_PREVIA} credencial(es) más: se incluyen todas al imprimir.</p>
            )}
          </>
        )}

        {confirmarCierre && (
          <div className="cq-confirmar" role="alert">
            <span><MenuIcon name="alert" size={16} /> Aún no imprime ni descarga los QR. Si cierra, tendrá que volver a emitirlos.</span>
            <div>
              <button type="button" className="cv-btn cv-btn-ghost" onClick={() => setConfirmarCierre(false)}>Volver</button>
              <button type="button" className="cv-btn tc-btn-danger ps-danger" onClick={onCerrar}>Cerrar de todos modos</button>
            </div>
          </div>
        )}
      </div>
    </div>,
    document.body,
  );
}

/**
 * Lectura de un QR: la pistola lectora «escribe» el contenido y un Enter en el campo;
 * si el navegador tiene BarcodeDetector (Chrome/Edge en Android, macOS, ChromeOS) también
 * se puede usar la cámara.
 */
export function EscanerQR({ onCodigo, deshabilitado }) {
  const [codigo, setCodigo] = useState('');
  const [camara, setCamara] = useState(false);
  const [errorCamara, setErrorCamara] = useState('');
  const inputRef = useRef(null);
  const videoRef = useRef(null);
  const onCodigoRef = useRef(onCodigo);
  onCodigoRef.current = onCodigo;
  const soportaCamara = typeof window !== 'undefined' && 'BarcodeDetector' in window && navigator.mediaDevices?.getUserMedia;

  useEffect(() => { inputRef.current?.focus(); }, []);

  useEffect(() => {
    if (!camara) return undefined;
    let stream;
    let timer;
    let activo = true;
    (async () => {
      try {
        const detector = new window.BarcodeDetector({ formats: ['qr_code'] });
        stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
        if (!activo) return;
        videoRef.current.srcObject = stream;
        await videoRef.current.play();
        const leer = async () => {
          if (!activo) return;
          try {
            const [hallado] = await detector.detect(videoRef.current);
            if (hallado?.rawValue) {
              setCamara(false);
              onCodigoRef.current(hallado.rawValue);
              return;
            }
          } catch { /* cuadro no listo */ }
          timer = setTimeout(leer, 250);
        };
        leer();
      } catch (e) {
        setErrorCamara(e?.name === 'NotAllowedError' ? 'Permiso de cámara denegado.' : 'No se pudo abrir la cámara.');
        setCamara(false);
      }
    })();
    return () => {
      activo = false;
      clearTimeout(timer);
      stream?.getTracks().forEach((t) => t.stop());
    };
  }, [camara]);

  function enviar(event) {
    event.preventDefault();
    if (!codigo.trim()) return;
    onCodigo(codigo.trim());
    setCodigo('');
    inputRef.current?.focus();
  }

  return (
    <div className="cq-escaner">
      <form className="in-search-row" onSubmit={enviar}>
        <input ref={inputRef} value={codigo} autoComplete="off" spellCheck={false} maxLength={300}
          placeholder="Escanee con la pistola lectora o pegue el contenido del QR"
          aria-label="Contenido del código QR" onChange={(e) => setCodigo(e.target.value)} />
        <button type="submit" className="cv-btn cv-btn-primary" disabled={deshabilitado || !codigo.trim()}>
          <MenuIcon name="check" size={15} /> Verificar
        </button>
        {soportaCamara && (
          <button type="button" className="cv-btn cv-btn-ghost" onClick={() => { setErrorCamara(''); setCamara((v) => !v); }}>
            <MenuIcon name="scan" size={15} /> {camara ? 'Cerrar cámara' : 'Usar cámara'}
          </button>
        )}
      </form>
      {errorCamara && <p className="cv-error">{errorCamara}</p>}
      {camara && (
        <div className="cq-video">
          <video ref={videoRef} muted playsInline />
          <span className="cq-mira" aria-hidden="true" />
        </div>
      )}
    </div>
  );
}
