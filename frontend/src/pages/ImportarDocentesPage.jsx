import { useState, useRef } from 'react';
import MenuIcon from '../components/MenuIcon';

/**
 * Página de importación masiva de docentes.
 * Permite subir un archivo Excel (.xlsx) o CSV con el padrón oficial de la UNP.
 * El backend hace UPSERT por DNI: actualiza si existe, inserta si es nuevo.
 */
export default function ImportarDocentesPage({ onImportSuccess }) {
  const [dragging, setDragging] = useState(false);
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [resultado, setResultado] = useState(null);
  const [error, setError] = useState(null);
  const inputRef = useRef();

  const COLUMNAS = ['DNI', 'Nombres', 'Apellidos', 'Categoría', 'Dedicación', 'Estado', 'Facultad', 'Departamento'];

  function handleDrop(e) {
    e.preventDefault();
    setDragging(false);
    const dropped = e.dataTransfer.files[0];
    if (dropped) setFile(dropped);
  }

  async function handleImportar() {
    if (!file) return;
    setLoading(true);
    setResultado(null);
    setError(null);

    const form = new FormData();
    form.append('archivo', file);

    try {
      const token = sessionStorage.getItem('accessToken');
      const resp = await fetch('/api/docentes/importar', {
        method: 'POST',
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        },
        body: form,
      });
      const data = await resp.json();
      if (!resp.ok) throw new Error(data.error || data.detail || data.message || 'Error en la importación');
      setResultado(data);
      if (onImportSuccess) onImportSuccess();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="importar-docentes-layout">
      <div className="panel" style={{ marginBottom: '20px' }}>
        <div className="panel-heading">
          <div>
            <h2>Importar Padrón de Docentes</h2>
            <p className="muted">Carga masiva por Excel (.xlsx) o CSV. El sistema actualiza si el DNI existe o inserta si es nuevo.</p>
          </div>
        </div>

        {/* Formato requerido */}
        <div style={{ background: '#e5f2ff', border: '1px solid #bdd9f7', borderRadius: '8px', padding: '14px 18px', marginBottom: '20px' }}>
          <strong style={{ color: '#073d70' }}>Formato requerido del archivo:</strong>
          <div style={{ overflowX: 'auto', marginTop: '10px' }}>
            <table style={{ borderCollapse: 'collapse', fontSize: '0.82rem', width: '100%' }}>
              <thead>
                <tr style={{ background: '#073d70', color: 'white' }}>
                  {COLUMNAS.map(c => <th key={c} style={{ padding: '6px 12px', textAlign: 'left' }}>{c}</th>)}
                </tr>
              </thead>
              <tbody>
                <tr style={{ background: '#f5f8fc' }}>
                  <td style={{ padding: '6px 12px' }}>03681234</td>
                  <td style={{ padding: '6px 12px' }}>Juan Carlos</td>
                  <td style={{ padding: '6px 12px' }}>Mendoza Pérez</td>
                  <td style={{ padding: '6px 12px' }}>PRINCIPAL</td>
                  <td style={{ padding: '6px 12px' }}>DE</td>
                  <td style={{ padding: '6px 12px' }}>ACTIVO</td>
                  <td style={{ padding: '6px 12px' }}>Facultad de Ingeniería Industrial</td>
                  <td style={{ padding: '6px 12px' }}>Ingeniería Informática</td>
                </tr>
                <tr>
                  <td style={{ padding: '6px 12px' }}>41258963</td>
                  <td style={{ padding: '6px 12px' }}>María Elena</td>
                  <td style={{ padding: '6px 12px' }}>Ruiz Delgado</td>
                  <td style={{ padding: '6px 12px' }}>ASOCIADO</td>
                  <td style={{ padding: '6px 12px' }}>TC</td>
                  <td style={{ padding: '6px 12px' }}>LICENCIA</td>
                  <td style={{ padding: '6px 12px' }}>Facultad de Ciencias</td>
                  <td style={{ padding: '6px 12px' }}>Matemáticas</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* Drop Zone */}
        <div
          onDragOver={e => { e.preventDefault(); setDragging(true); }}
          onDragLeave={() => setDragging(false)}
          onDrop={handleDrop}
          onClick={() => inputRef.current.click()}
          style={{
            border: `2px dashed ${dragging ? '#1769aa' : '#cbd6e3'}`,
            borderRadius: '12px',
            padding: '40px 20px',
            textAlign: 'center',
            cursor: 'pointer',
            background: dragging ? '#e5f2ff' : '#f9fbfd',
            transition: 'all 0.2s',
            marginBottom: '20px',
          }}
        >
          <input
            ref={inputRef}
            type="file"
            accept=".xlsx,.xls,.csv"
            style={{ display: 'none' }}
            onChange={e => setFile(e.target.files[0])}
          />
          <div style={{ fontSize: '2.5rem', marginBottom: '8px' }}>📂</div>
          {file ? (
            <div>
              <strong style={{ color: '#073d70' }}>{file.name}</strong>
              <p className="muted" style={{ margin: '4px 0 0' }}>{(file.size / 1024).toFixed(1)} KB — listo para importar</p>
            </div>
          ) : (
            <div>
              <p style={{ margin: 0, fontWeight: 600, color: '#364358' }}>Arrastra tu archivo aquí o haz clic para seleccionar</p>
              <p className="muted" style={{ margin: '4px 0 0' }}>Formatos soportados: .xlsx, .xls, .csv</p>
            </div>
          )}
        </div>

        {error && <div className="alert error" role="alert">{error}</div>}

        <div className="form-actions">
          {file && (
            <button className="secondary-button" onClick={() => { setFile(null); setResultado(null); }}>
              Cancelar
            </button>
          )}
          <button
            className="primary-small"
            style={{ padding: '13px 30px', fontSize: '1rem' }}
            disabled={!file || loading}
            onClick={handleImportar}
          >
            {loading ? 'Importando...' : '⬆ Importar Padrón'}
          </button>
        </div>
      </div>

      {/* Resultado */}
      {resultado && (
        <div className="panel">
          <h3 style={{ marginBottom: '20px', color: '#237b55' }}>✅ Importación completada</h3>
          <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(3, 1fr)' }}>
            <article className="stat-card">
              <span className="stat-icon green">N</span>
              <div>
                <strong style={{ fontSize: '1.6rem' }}>{resultado.insertados}</strong>
                <span>Docentes nuevos registrados</span>
              </div>
            </article>
            <article className="stat-card">
              <span className="stat-icon blue">A</span>
              <div>
                <strong style={{ fontSize: '1.6rem' }}>{resultado.actualizados}</strong>
                <span>Docentes actualizados</span>
              </div>
            </article>
            <article className="stat-card">
              <span className="stat-icon amber">T</span>
              <div>
                <strong style={{ fontSize: '1.6rem' }}>{resultado.total}</strong>
                <span>Total procesados</span>
              </div>
            </article>
          </div>

          {resultado.errores?.length > 0 && (
            <div style={{ marginTop: '20px' }}>
              <h4 style={{ color: '#ae2b35', marginBottom: '10px' }}>⚠ Filas con errores ({resultado.errores.length})</h4>
              <div style={{ maxHeight: '200px', overflowY: 'auto', background: '#fff5f5', borderRadius: '8px', padding: '12px' }}>
                {resultado.errores.map((e, i) => (
                  <p key={i} style={{ margin: '4px 0', fontSize: '0.82rem', color: '#ae2b35' }}>• {e}</p>
                ))}
              </div>
            </div>
          )}

          <button className="primary-small" style={{ marginTop: '20px' }} onClick={() => { setFile(null); setResultado(null); }}>
            Nueva importación
          </button>
        </div>
      )}
    </div>
  );
}
