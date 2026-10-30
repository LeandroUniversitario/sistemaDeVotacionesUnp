/**
 * Catálogo oficial de Facultades y Departamentos Académicos de la UNP
 * sincronizado con la base de datos electoral.
 */

export const FACULTADES = [
  { id: 1, nombre: 'Facultad de Agronomía' },
  { id: 2, nombre: 'Facultad de Arquitectura y Urbanismo' },
  { id: 3, nombre: 'Facultad de Ciencias' },
  { id: 4, nombre: 'Facultad de Ciencias Administrativas' },
  { id: 5, nombre: 'Facultad de Ciencias Contables y Financieras' },
  { id: 6, nombre: 'Facultad de Ciencias de la Salud' },
  { id: 7, nombre: 'Facultad de Ciencias Sociales y Educación' },
  { id: 8, nombre: 'Facultad de Derecho y Ciencias Políticas' },
  { id: 9, nombre: 'Facultad de Economía' },
  { id: 10, nombre: 'Facultad de Ingeniería Civil' },
  { id: 11, nombre: 'Facultad de Ingeniería de Minas' },
  { id: 12, nombre: 'Facultad de Ingeniería Industrial' },
  { id: 13, nombre: 'Facultad de Ingeniería Pesquera' },
  { id: 14, nombre: 'Facultad de Zootecnia' },
];

export const DEPARTAMENTOS = [
  { id: 1, idFacultad: 1, nombre: 'Agronomía y Fitotécnia' },
  { id: 2, idFacultad: 1, nombre: 'Ingeniería Agrícola' },
  { id: 3, idFacultad: 1, nombre: 'Sanidad Vegetal' },
  { id: 4, idFacultad: 1, nombre: 'Suelos' },
  { id: 5, idFacultad: 1, nombre: 'Morfofisiología Vegetal' },
  { id: 6, idFacultad: 2, nombre: 'Arquitectura' },
  { id: 7, idFacultad: 2, nombre: 'Urbanismo' },
  { id: 8, idFacultad: 3, nombre: 'Matemática' },
  { id: 9, idFacultad: 3, nombre: 'Física' },
  { id: 10, idFacultad: 3, nombre: 'Estadística' },
  { id: 11, idFacultad: 3, nombre: 'Ciencias Biológicas' },
  { id: 12, idFacultad: 3, nombre: 'Ingeniería Electrónica y Telecomunicaciones' },
  { id: 13, idFacultad: 4, nombre: 'Administración General' },
  { id: 14, idFacultad: 4, nombre: 'Administración Aplicada' },
  { id: 15, idFacultad: 5, nombre: 'Contabilidad General' },
  { id: 16, idFacultad: 5, nombre: 'Contabilidad Aplicada' },
  { id: 17, idFacultad: 5, nombre: 'Finanzas, Tributación y Auditoría' },
  { id: 18, idFacultad: 6, nombre: 'Materno Infantil' },
  { id: 19, idFacultad: 6, nombre: 'Morfofisiología Humana' },
  { id: 20, idFacultad: 6, nombre: 'Clínico Quirúrgico' },
  { id: 21, idFacultad: 6, nombre: 'Salud Pública' },
  { id: 22, idFacultad: 6, nombre: 'Enfermería Materno Perinatal' },
  { id: 23, idFacultad: 6, nombre: 'Enfermería del Adulto' },
  { id: 24, idFacultad: 7, nombre: 'Educación' },
  { id: 25, idFacultad: 7, nombre: 'Ciencias Sociales' },
  { id: 26, idFacultad: 7, nombre: 'Ciencias de la Comunicación' },
  { id: 27, idFacultad: 8, nombre: 'Derecho' },
  { id: 28, idFacultad: 8, nombre: 'Ciencias Políticas' },
  { id: 29, idFacultad: 9, nombre: 'Economía' },
  { id: 30, idFacultad: 10, nombre: 'Ingeniería Civil' },
  { id: 31, idFacultad: 10, nombre: 'Ingeniería Sanitaria y Medio Ambiente' },
  { id: 32, idFacultad: 11, nombre: 'Ingeniería de Minas' },
  { id: 33, idFacultad: 11, nombre: 'Ingeniería de Petróleo' },
  { id: 34, idFacultad: 11, nombre: 'Ingeniería Geológica' },
  { id: 35, idFacultad: 11, nombre: 'Ingeniería Química' },
  { id: 36, idFacultad: 11, nombre: 'Ingeniería Ambiental y Seguridad Industrial' },
  { id: 37, idFacultad: 12, nombre: 'Ingeniería Industrial' },
  { id: 38, idFacultad: 12, nombre: 'Ingeniería Informática' },
  { id: 39, idFacultad: 12, nombre: 'Agroindustria e Industrias Alimentarias' },
  { id: 40, idFacultad: 12, nombre: 'Investigación de Operaciones' },
  { id: 41, idFacultad: 12, nombre: 'Ingeniería Mecatrónica' },
  { id: 42, idFacultad: 13, nombre: 'Ingeniería Pesquera' },
  { id: 43, idFacultad: 14, nombre: 'Producción Animal' },
  { id: 44, idFacultad: 14, nombre: 'Salud Animal' },
];

export function getFacultadNombre(id) {
  if (!id) return 'No asignada';
  const f = FACULTADES.find(item => item.id === Number(id));
  return f ? f.nombre : `Facultad #${id}`;
}

export function getDepartamentoNombre(id) {
  if (!id) return 'No asignado';
  const d = DEPARTAMENTOS.find(item => item.id === Number(id));
  return d ? d.nombre : `Departamento #${id}`;
}

export function getDepartamentosPorFacultad(idFacultad) {
  if (!idFacultad) return [];
  return DEPARTAMENTOS.filter(d => d.idFacultad === Number(idFacultad));
}

