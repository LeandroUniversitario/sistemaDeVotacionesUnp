import { useState, useMemo } from 'react';

/**
 * Tabla del padrón de docentes con buscador en tiempo real,
 * filtros por categoría y estado, y paginación rápida.
 */
export default function TeacherTable({ teachers = [], loading = false }) {
  const [search, setSearch] = useState('');
  const [categoriaFilter, setCategoriaFilter] = useState('TODAS');
  const [estadoFilter, setEstadoFilter] = useState('TODOS');
  const [page, setPage] = useState(1);
  const pageSize = 15;

  // Filtrado reactivo en memoria
  const filteredTeachers = useMemo(() => {
    return teachers.filter((t) => {
      const fullText = `${t.nombres || ''} ${t.apellidos || ''} ${t.dni || ''}`.toLowerCase();
      const matchSearch = fullText.includes(search.toLowerCase().trim());
      const matchCat = categoriaFilter === 'TODAS' || t.categoria === categoriaFilter;
      const matchEst = estadoFilter === 'TODOS' || t.estado === estadoFilter;
      return matchSearch && matchCat && matchEst;
    });
  }, [teachers, search, categoriaFilter, estadoFilter]);

  // Reset a la página 1 cuando cambia algún filtro
  const totalPages = Math.ceil(filteredTeachers.length / pageSize) || 1;
  const currentPage = Math.min(page, totalPages);

  const paginatedTeachers = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredTeachers.slice(start, start + pageSize);
  }, [filteredTeachers, currentPage, pageSize]);

  if (loading) return <p className="empty-state">Cargando docentes...</p>;

  return (
    <div>
      {/* Barra de Filtros y Búsqueda */}
      <div style={{
        display: 'flex',
        flexWrap: 'wrap',
        gap: '12px',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '16px',
        background: '#f8fafc',
        padding: '12px 16px',
        borderRadius: '10px',
        border: '1px solid #e2e8f0'
      }}>
        {/* Buscador */}
        <div style={{ flex: '1 1 240px', minWidth: '200px' }}>
          <input
            type="text"
            placeholder="🔍 Buscar por DNI, nombres o apellidos..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            style={{ margin: 0 }}
          />
        </div>

        {/* Filtro Categoría */}
        <div style={{ flex: '0 0 160px' }}>
          <select
            value={categoriaFilter}
            onChange={(e) => { setCategoriaFilter(e.target.value); setPage(1); }}
            style={{ margin: 0 }}
          >
            <option value="TODAS">Todas las categorías</option>
            <option value="PRINCIPAL">PRINCIPAL</option>
            <option value="ASOCIADO">ASOCIADO</option>
            <option value="AUXILIAR">AUXILIAR</option>
          </select>
        </div>

        {/* Filtro Estado */}
        <div style={{ flex: '0 0 160px' }}>
          <select
            value={estadoFilter}
            onChange={(e) => { setEstadoFilter(e.target.value); setPage(1); }}
            style={{ margin: 0 }}
          >
            <option value="TODOS">Todos los estados</option>
            <option value="ACTIVO">ACTIVO</option>
            <option value="LICENCIA">LICENCIA</option>
            <option value="SUSPENDIDO">SUSPENDIDO</option>
            <option value="INACTIVO">INACTIVO</option>
          </select>
        </div>
      </div>

      {/* Contador de registros */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px', fontSize: '0.85rem', color: '#64748b' }}>
        <span>Mostrando <strong>{filteredTeachers.length}</strong> de <strong>{teachers.length}</strong> docentes</span>
        {totalPages > 1 && (
          <span>Página {currentPage} de {totalPages}</span>
        )}
      </div>

      {/* Tabla de Docentes */}
      {!filteredTeachers.length ? (
        <p className="empty-state">No se encontraron docentes con los criterios seleccionados.</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Docente</th>
                <th>DNI</th>
                <th>Categoría</th>
                <th>Dedicación</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              {paginatedTeachers.map((teacher) => (
                <tr key={teacher.id || teacher.dni}>
                  <td><strong>{teacher.apellidos}, {teacher.nombres}</strong></td>
                  <td><code>{teacher.dni}</code></td>
                  <td>{teacher.categoria}</td>
                  <td>{teacher.dedicacion}</td>
                  <td>
                    <span className={`badge ${teacher.estado?.toLowerCase()}`}>
                      {teacher.estado}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Paginación */}
      {totalPages > 1 && (
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
          <button
            className="secondary-button"
            disabled={currentPage === 1}
            onClick={() => setPage((p) => Math.max(p - 1, 1))}
            style={{ padding: '6px 14px', fontSize: '0.85rem' }}
          >
            ◀ Anterior
          </button>
          <button
            className="secondary-button"
            disabled={currentPage === totalPages}
            onClick={() => setPage((p) => Math.min(p + 1, totalPages))}
            style={{ padding: '6px 14px', fontSize: '0.85rem' }}
          >
            Siguiente ▶
          </button>
        </div>
      )}
    </div>
  );
}
