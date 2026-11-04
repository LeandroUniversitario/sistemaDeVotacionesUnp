import { Component } from 'react';
import './error-boundary.css';

/**
 * Atrapa los errores de render para que un fallo en una pantalla no deje toda la aplicación en blanco.
 * También cubre el caso típico tras actualizar el sistema: el navegador pide un módulo de una versión
 * anterior que ya no existe ("Failed to fetch dynamically imported module").
 *
 * @param {{ children: any, compacto?: boolean, onInicio?: function }} props
 *   compacto: se muestra dentro del panel (una sola sección falló) en lugar de pantalla completa.
 *   onInicio: acción del botón "Volver al inicio" (por defecto recarga la app sin la sección).
 */
export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    // eslint-disable-next-line no-console
    console.error('[SICEUNP] Error de interfaz:', error, info?.componentStack);
  }

  reintentar = () => this.setState({ error: null });

  inicio = () => {
    if (this.props.onInicio) {
      this.setState({ error: null });
      this.props.onInicio();
    } else {
      window.location.href = window.location.pathname;
    }
  };

  render() {
    const { error } = this.state;
    if (!error) return this.props.children;

    const moduloViejo = /dynamically imported module|Importing a module script failed|error loading dynamically/i
      .test(String(error?.message ?? ''));
    const titulo = moduloViejo ? 'El sistema se actualizó' : 'No se pudo mostrar esta pantalla';
    const texto = moduloViejo
      ? 'Hay una versión más reciente de SICEUNP. Recargue la página para continuar.'
      : 'Ocurrió un error inesperado al dibujar la vista. Sus datos no se perdieron: puede reintentar o volver al inicio.';

    return (
      <div className={`error-boundary${this.props.compacto ? ' compacto' : ''}`} role="alert">
        <div className="error-boundary-card">
          <div className="error-boundary-icono" aria-hidden="true">!</div>
          <h2>{titulo}</h2>
          <p>{texto}</p>
          {!moduloViejo && error?.message && <code className="error-boundary-detalle">{String(error.message)}</code>}
          <div className="error-boundary-acciones">
            {moduloViejo ? (
              <button type="button" className="btn-primary" onClick={() => window.location.reload()}>Recargar</button>
            ) : (
              <>
                <button type="button" className="btn-ghost" onClick={this.reintentar}>Reintentar</button>
                <button type="button" className="btn-primary" onClick={this.inicio}>Volver al inicio</button>
              </>
            )}
          </div>
        </div>
      </div>
    );
  }
}
