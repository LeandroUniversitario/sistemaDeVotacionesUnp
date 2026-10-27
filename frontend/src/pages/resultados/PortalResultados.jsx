import MenuIcon from '../../components/MenuIcon';
import PantallaResultados from './PantallaResultados';
import './resultados.css';

/**
 * CUS17 · Portal público de resultados y verificación de actas (sin inicio de sesión).
 * Es el destino de los QR del sistema: /verificar/{token} verifica el documento al abrirse;
 * /resultados?proceso={id} abre los resultados publicados de ese proceso (RF99, RF55).
 */
export default function PortalResultados() {
  const ruta = window.location.pathname;
  const codigo = ruta.startsWith('/verificar/') ? decodeURIComponent(ruta.slice('/verificar/'.length)) : null;
  const proceso = new URLSearchParams(window.location.search).get('proceso');
  const iniciarSesion = () => { window.location.href = '/'; };

  return (
    <div className="rs-portal">
      <header className="rs-portal-top">
        <img src="/escudo-unp.png" alt="Escudo UNP" />
        <div>
          <strong>SICEUNP · Portal electoral</strong>
          <span>Universidad Nacional de Piura · Comité Electoral (CEUNP)</span>
        </div>
        <button type="button" className="cv-btn cv-btn-ghost" onClick={iniciarSesion}>
          <MenuIcon name="login" size={15} /> Iniciar sesión
        </button>
      </header>
      <main className="rs-portal-main">
        <h1>Consultar resultados y verificar actas</h1>
        <p>Resultados oficiales publicados por el CEUNP y verificación de la autenticidad de cualquier acta o resolución con su código QR.</p>
        <PantallaResultados publico codigoInicial={codigo} procesoInicial={proceso} onIniciarSesion={iniciarSesion} />
      </main>
    </div>
  );
}
