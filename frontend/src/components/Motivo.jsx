import MenuIcon from './MenuIcon';
import './motivo.css';

/**
 * Motivo por el que una acción está bloqueada (botón desactivado). Se coloca junto al botón para
 * que el usuario sepa exactamente qué falta, en lugar de un botón gris que "no hace nada".
 * No muestra nada si no hay motivo.
 */
export default function Motivo({ children, className = '' }) {
  if (!children) return null;
  return (
    <p className={`motivo-bloqueo${className ? ` ${className}` : ''}`} role="note">
      <MenuIcon name="info" size={14} />
      <span>{children}</span>
    </p>
  );
}

/** Devuelve el primer motivo que se cumple de una lista [[condición, texto], …], o null. */
export function primerMotivo(lista) {
  const hallado = lista.find(([cond]) => cond);
  return hallado ? hallado[1] : null;
}
