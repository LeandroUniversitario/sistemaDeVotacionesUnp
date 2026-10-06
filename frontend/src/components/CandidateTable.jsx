/**
 * Tabla de candidatos de una lista electoral.
 * Componente de presentación puro: solo recibe datos y los muestra.
 *
 * @param {{ candidates: Array }} props
 */
export default function CandidateTable({ candidates }) {
  if (!candidates.length) return <p className="empty-state">La lista todavía no tiene candidatos.</p>;

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Docente</th>
            <th>Rol en lista</th>
            <th>Estado</th>
          </tr>
        </thead>
        <tbody>
          {candidates.map((candidate) => (
            <tr key={candidate.id}>
              <td>Docente #{candidate.idDocente}</td>
              <td>{candidate.rolEnLista}</td>
              <td>
                <span className={`badge ${candidate.estadoValidacion?.toLowerCase()}`}>
                  {candidate.estadoValidacion}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
