import React, { useState } from 'react';
import './index.css';

// Mockup data based on UML Use Cases defined previously
const actorRoles = [
  { id: 'admin', label: '👤 Administrador' },
  { id: 'comite', label: '⚖️ CEUNP' },
  { id: 'elector', label: '🎓 Docente Elector' },
  { id: 'miembro_mesa', label: '🪑 Miembro de Mesa' },
  { id: 'lista', label: '⭐ Lista / Candidato' },
  { id: 'personero', label: '👁️ Personero' }
];

const mockupsData = {
  admin: {
    title: 'Panel de Administrador',
    desc: 'Gestión y configuración del padrón general de la universidad.',
    actions: [
      { id: 'UC6', title: 'Gestionar Padrón Docente', desc: 'Registrar, actualizar o dar de baja docentes en la base de datos de la UNP.', icon: '👥' },
      { id: 'CONF', title: 'Configuración de Sistema', desc: 'Ajustes globales de seguridad, base de datos y auditoría del sistema.', icon: '⚙️' }
    ]
  },
  comite: {
    title: 'Panel del CEUNP',
    desc: 'Supervisión, configuración y ejecución de las etapas del proceso electoral.',
    actions: [
      { id: 'UC3', title: 'Crear Proceso Electoral', desc: 'Configurar cronograma, cargos, quórum mínimo (60%) y posibles segundas vueltas.', icon: '📅' },
      { id: 'UC2', title: 'Validar Listas', desc: 'Revisar inscripciones de fórmulas (Rector + Vicerrectores) y aprobar o rechazar.', icon: '✅' },
      { id: 'UC12', title: 'Resolver Tachas', desc: 'Atender cuestionamientos escritos contra candidatos presentados por docentes del padrón.', icon: '⚖️' },
      { id: 'UC13', title: 'Acreditar Personeros', desc: 'Validar y otorgar credenciales a personeros generales y de mesa propuestos por las listas.', icon: '👁️' },
      { id: 'UC7', title: 'Sortear Mesa Electoral', desc: 'Ejecutar algoritmo de sorteo de 6 miembros por mesa (3 titulares, 3 suplentes).', icon: '🎲' },
      { id: 'UC_QUORUM', title: 'Monitoreo de Quórum', desc: 'Panel en tiempo real para visualizar porcentaje de participación (Vista SQL).', icon: '📈' },
      { id: 'UC_MULTA', title: 'Gestión de Multas (RN35)', desc: 'Generar cobros automáticos a omisos al sufragio (2.5% UIT) y omisos a mesa (3% UIT).', icon: '💰' }
    ]
  },
  elector: {
    title: 'Portal del Elector',
    desc: 'Módulo estrictamente confidencial para ejercer el derecho a voto.',
    actions: [
      { id: 'INFO', title: 'Descargar Pase QR (RF62)', desc: 'Verificar local de votación y descargar QR de acceso de uso único.', icon: '📱' },
      { id: 'UC5', title: 'Emitir Voto por Lista', desc: 'Ingresar a la cabina, escanear Pase QR y elegir una fórmula. Voto anónimo garantizado.', icon: '🗳️' },
      { id: 'UC11', title: 'Descargar Constancia', desc: 'Obtener constancia digital tras haber emitido el voto correctamente.', icon: '📄' }
    ]
  },
  miembro_mesa: {
    title: 'Gestor de Mesa Electoral',
    desc: 'Panel exclusivo para el Presidente, Secretario y Vocal de Mesa.',
    actions: [
      { id: 'INST', title: 'Instalación de Mesa (RF56)', desc: 'Acreditar identidad escaneando el Fotocheck QR de Miembro de Mesa.', icon: '🪑' },
      { id: 'SCAN', title: 'Escanear Elector (RF62)', desc: 'Pistola lectora: Validar QR del docente, registrar asistencia y habilitar cabina secreta.', icon: '🔍' },
      { id: 'UC8', title: 'Escrutinio y Actas (RF52)', desc: 'Cierre de votación y generación de Actas (Instalación, Sufragio, Escrutinio) con QR SHA-256.', icon: '📊' }
    ]
  },
  lista: {
    title: 'Portal de la Lista Electoral',
    desc: 'Gestión de postulaciones (fórmulas completas) a cargos de la UNP.',
    actions: [
      { id: 'UC1', title: 'Inscribir Lista de Candidatos', desc: 'Inscribir fórmula completa subiendo Planes de Gobierno y Hojas de Vida públicas (RN15).', icon: '📝' },
      { id: 'STATE', title: 'Estado de Lista', desc: 'Seguimiento del proceso de validación o resolución de tachas.', icon: '🔍' }
    ]
  },
  personero: {
    title: 'Portal del Personero',
    desc: 'Módulo de fiscalización y auditoría del proceso electoral.',
    actions: [
      { id: 'CRED', title: 'Acreditarse en Mesa (RF51)', desc: 'Identificarse ante los miembros de mesa usando su Credencial QR digital.', icon: '📱' },
      { id: 'UC9', title: 'Impugnar Votos / Actas', desc: 'Registrar observaciones sobre eventos anómalos durante el escrutinio de una mesa.', icon: '🛑' },
      { id: 'AUDIT', title: 'Auditar Hash de Actas (RF52)', desc: 'Escanear QR de actas electorales físicas para validar criptográficamente (SHA-256) los resultados.', icon: '🔐' }
    ]
  }
};


function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [dni, setDni] = useState('');
  const [password, setPassword] = useState('');
  
  // Dashboard state to simulate actor switching
  const [activeActor, setActiveActor] = useState('admin');

  const handleLogin = (e) => {
    e.preventDefault();
    if (dni === 'admin' && password === '123') {
      setIsLoggedIn(true);
    } else {
      alert("Credenciales incorrectas. (Pista: Usa 'admin' / '123')");
    }
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    setDni('');
    setPassword('');
  };

  // 1. RENDERIZADO DEL LOGIN
  if (!isLoggedIn) {
    return (
      <>
        <div className="bg-shape shape-1"></div>
        <div className="bg-shape shape-2"></div>
        
        <main className="login-container">
          <header className="login-header">
            <div className="unp-logo">UNP</div>
            <h1>Sistema de Elecciones</h1>
            <p>Acceso Seguro al Portal Institucional</p>
          </header>

          <form onSubmit={handleLogin}>
            <div className="form-group">
              <input 
                type="text" 
                id="dni" 
                className="form-input" 
                placeholder="DNI / Usuario"
                value={dni}
                onChange={(e) => setDni(e.target.value)}
                required 
              />
              <label htmlFor="dni" className="form-label">Usuario ("admin")</label>
            </div>

            <div className="form-group">
              <input 
                type="password" 
                id="password" 
                className="form-input" 
                placeholder="Contraseña"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required 
              />
              <label htmlFor="password" className="form-label">Contraseña ("123")</label>
            </div>

            <button type="submit" className="submit-btn">
              Ingresar al Sistema
            </button>
          </form>
        </main>
      </>
    );
  }

  // 2. RENDERIZADO DEL DASHBOARD MULTI-ROL
  const currentPanel = mockupsData[activeActor];

  return (
    <>
      {/* Fondo mantenido en el dashboard */}
      <div className="bg-shape shape-1" style={{ opacity: 0.4 }}></div>
      <div className="bg-shape shape-2" style={{ opacity: 0.3 }}></div>

      <div className="dashboard-layout">
        
        {/* Barra Lateral / Selector de Actor */}
        <aside className="sidebar">
          <div className="sidebar-header">
            <div className="unp-logo" style={{ width: 48, height: 48, fontSize: 18, marginBottom: 12, boxShadow: 'none' }}>UNP</div>
            <h2 style={{ fontSize: 18, fontWeight: 600 }}>Simulador de Vistas</h2>
            <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>Cambiar Rol (RUP)</p>
          </div>

          <nav className="sidebar-menu">
            {actorRoles.map(actor => (
              <button 
                key={actor.id}
                className={`menu-item ${activeActor === actor.id ? 'active' : ''}`}
                onClick={() => setActiveActor(actor.id)}
              >
                {actor.label}
              </button>
            ))}
            
            <button className="menu-item logout-btn" onClick={handleLogout}>
              🚪 Cerrar Sesión
            </button>
          </nav>
        </aside>

        {/* Contenido Principal (Maqueta) */}
        <main className="main-content">
          <header className="dashboard-header">
            <h2 key={`title-${activeActor}`}>{currentPanel.title}</h2>
            <p key={`desc-${activeActor}`}>{currentPanel.desc}</p>
          </header>

          <div className="cards-grid">
            {currentPanel.actions.map((action, index) => (
              <div key={action.id} className="action-card">
                <div className="card-icon">{action.icon}</div>
                <h3>{action.title}</h3>
                <p>{action.desc}</p>
              </div>
            ))}
          </div>
        </main>
      </div>
    </>
  );
}

export default App;
