import { useEffect, useId, useRef } from 'react';
import MenuIcon from './MenuIcon';
import './ventana.css';

/**
 * Ventanas estándar del sistema para los flujos de detalle y acción.
 *
 *  · <Modal>  — formulario de acción centrado sobre la pantalla (registrar, resolver, editar…).
 *  · <Drawer> — panel lateral derecho para consultar o gestionar el detalle de una fila o tarjeta.
 *
 * Ambos se cierran con el botón X, la tecla Escape y el clic fuera del panel; bloquean el
 * scroll del fondo mientras están abiertos y devuelven el foco al elemento que los abrió.
 * Se renderizan en el mismo árbol de la pantalla (position: fixed), de modo que conservan
 * los estilos con ámbito de cada módulo (.mx, .mu-shell, .ig-shell…). Pueden apilarse:
 * Escape cierra solo la ventana superior.
 */

const pila = [];
let estiloPrevio = null;

function bloquearFondo() {
  if (pila.length !== 1) return;
  const { body, documentElement } = document;
  const barra = window.innerWidth - documentElement.clientWidth;
  estiloPrevio = { overflow: body.style.overflow, paddingRight: body.style.paddingRight };
  body.style.overflow = 'hidden';
  if (barra > 0) body.style.paddingRight = `${barra}px`;
}

function liberarFondo() {
  if (pila.length !== 0 || !estiloPrevio) return;
  document.body.style.overflow = estiloPrevio.overflow;
  document.body.style.paddingRight = estiloPrevio.paddingRight;
  estiloPrevio = null;
}

const ENFOCABLES = 'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

function VentanaAbierta({ tipo, onCerrar, titulo, subtitulo, extra, ancho, etiqueta, className, children }) {
  const id = useId();
  const idTitulo = `${id}-titulo`;
  const panelRef = useRef(null);
  const cerrarRef = useRef(onCerrar);
  const pulsadoFuera = useRef(false);

  useEffect(() => { cerrarRef.current = onCerrar; }, [onCerrar]);

  useEffect(() => {
    const previo = document.activeElement;
    pila.push(id);
    bloquearFondo();
    const panel = panelRef.current;
    if (panel && !panel.contains(document.activeElement)) panel.focus({ preventScroll: true });

    function alPulsarTecla(e) {
      if (pila[pila.length - 1] !== id) return;
      if (e.key === 'Escape') {
        e.stopPropagation();
        cerrarRef.current?.();
        return;
      }
      if (e.key !== 'Tab' || !panel) return;
      const lista = [...panel.querySelectorAll(ENFOCABLES)].filter((el) => el.offsetParent !== null || el === document.activeElement);
      if (lista.length === 0) { e.preventDefault(); panel.focus(); return; }
      const primero = lista[0];
      const ultimo = lista[lista.length - 1];
      if (e.shiftKey && (document.activeElement === primero || document.activeElement === panel)) {
        e.preventDefault();
        ultimo.focus();
      } else if (!e.shiftKey && document.activeElement === ultimo) {
        e.preventDefault();
        primero.focus();
      }
    }
    document.addEventListener('keydown', alPulsarTecla);

    return () => {
      document.removeEventListener('keydown', alPulsarTecla);
      const i = pila.indexOf(id);
      if (i >= 0) pila.splice(i, 1);
      liberarFondo();
      if (previo && typeof previo.focus === 'function' && document.contains(previo)) previo.focus({ preventScroll: true });
    };
  }, [id]);

  return (
    <div
      className={`vn-velo vn-${tipo}`}
      role="presentation"
      onMouseDown={(e) => { pulsadoFuera.current = e.target === e.currentTarget; }}
      onClick={(e) => {
        if (pulsadoFuera.current && e.target === e.currentTarget) onCerrar?.();
        pulsadoFuera.current = false;
      }}
    >
      <div
        ref={panelRef}
        className={`vn-panel${className ? ` ${className}` : ''}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titulo ? idTitulo : undefined}
        aria-label={titulo ? undefined : etiqueta}
        tabIndex={-1}
        style={{ '--vn-ancho': typeof ancho === 'number' ? `${ancho}px` : ancho }}
      >
        <header className="vn-head">
          <div className="vn-head-texto">
            {titulo && <h2 id={idTitulo}>{titulo}</h2>}
            {subtitulo && <p>{subtitulo}</p>}
          </div>
          {extra && <div className="vn-head-extra">{extra}</div>}
          <button type="button" className="vn-cerrar" onClick={onCerrar} aria-label="Cerrar (Esc)" title="Cerrar (Esc)">
            <MenuIcon name="close" size={18} />
          </button>
        </header>
        <div className="vn-cuerpo">{children}</div>
      </div>
    </div>
  );
}

/**
 * Pestañas o sub-vistas: cuando `valor` (la pestaña activa) cambia y la barra de pestañas quedó
 * fuera de la vista (por ejemplo, al pulsar un botón de una fila al final de la tabla), la trae
 * suavemente a la parte superior del contenedor (la página o el panel lateral) para que el nuevo
 * contenido se vea desde su inicio. No hace nada si la barra ya está a la vista.
 *
 * Con { tambienAbajo: true } también lo hace cuando el elemento quedó por debajo del borde
 * inferior: sirve para los listados maestro-detalle que en pantallas angostas apilan el detalle
 * debajo de la lista (Tachas, Inscripción, Personeros).
 */
export function useMantenerEnVista(valor, { tambienAbajo = false } = {}) {
  const ref = useRef(null);
  const previo = useRef(valor);

  useEffect(() => {
    if (previo.current === valor) return;
    previo.current = valor;
    const el = ref.current;
    if (!el) return;
    const suave = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth';
    const cuerpo = el.closest('.vn-cuerpo');
    if (cuerpo) {
      const delta = el.getBoundingClientRect().top - cuerpo.getBoundingClientRect().top;
      if (delta < 0) cuerpo.scrollBy({ top: delta - 12, behavior: suave });
      return;
    }
    const barra = Math.max(0, document.querySelector('.topbar')?.getBoundingClientRect().bottom ?? 0);
    const delta = el.getBoundingClientRect().top - barra;
    const debajo = tambienAbajo && el.getBoundingClientRect().top > window.innerHeight - 96;
    if (delta < 0 || debajo) window.scrollBy({ top: delta - 12, behavior: suave });
  }, [valor, tambienAbajo]);

  return ref;
}

/** Formulario de acción en una ventana centrada con velo (fixed inset-0). */
export function Modal({ abierto = true, ancho = 640, ...props }) {
  if (!abierto) return null;
  return <VentanaAbierta tipo="modal" ancho={ancho} {...props} />;
}

/** Detalle de una fila o tarjeta en un panel lateral derecho (fixed right-0 top-0 h-full). */
export function Drawer({ abierto = true, ancho = 760, ...props }) {
  if (!abierto) return null;
  return <VentanaAbierta tipo="drawer" ancho={ancho} {...props} />;
}
