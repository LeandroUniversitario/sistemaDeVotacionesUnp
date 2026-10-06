import { formatDate, formatType } from '../utils/formatters';

/**
 * Tabla de procesos electorales.
 * Componente de presentación puro: solo recibe datos y los muestra.
 *
 * @param {{ processes: Array, loading: boolean }} props
 */
export default function ProcessTable({ processes, loading }) {
  if (loading) return <p className="empty-state">Cargando procesos...</p>;
  if (!processes.length) return <p className="empty-state">Todavía no hay procesos electorales registrados.</p>;

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Proceso</th>
            <th>Tipo</th>
            <th>Inicio</th>
            <th>Fin</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          {processes.map((process) => (
            <tr key={process.id}>
              <td><strong>{process.nombre}</strong></td>
              <td>{formatType(process.tipo)}</td>
              <td>{formatDate(process.fechaInicio)}</td>
              <td>{formatDate(process.fechaFin)}</td>
              <td><span className={`badge ${process.estado?.toLowerCase()}`}>{process.estado}</span></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
