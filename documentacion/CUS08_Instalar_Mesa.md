# CUS08 · Instalar mesa

**Actores:** Miembro de mesa (su propia mesa) y CEUNP (todas; único que declara NO INSTALADA). ADMIN solo consulta.
**Pantalla:** menú «Instalar mesa» (MIEMBRO_MESA) e «Instalación de mesas» (CEUNP, grupo Jornada electoral).
**Requiere:** proceso en VOTACION, mesas con sus 6 miembros sorteados (CUS06); fotocheck QR emitido (CUS07) es opcional.
**Instalación:** en una base ya creada, ejecutar `base-de-datos/09_instalacion_mesa.sql`. `01_crear_base_de_datos.sql` ya lo incluye al final y `02_limpiar_datos_electorales.sql` vacía sus tablas.

## Especificación usada y supuestos
No había una especificación detallada del CUS08. Se tomó la fase 7 de `diagramas/proceso_electoral_docentes_unp.puml` (Art. 45, 48 y 49), RN07 (instalación de 9:00 a 12:00, si no, NO_INSTALADA), RN19 (3 titulares y 3 suplentes), RN28 (actas con huella SHA-256), RN30 y RN35. Supuestos:
- Un suplente presente asume el cargo de un titular ausente, en el orden del sorteo.
- Para instalar deben estar cubiertos presidente, secretario y vocal y recibido el material obligatorio. Los personeros son opcionales.
- La jornada es el día de `fecha_inicio` del proceso. El horario se configura en Parámetros (`INSTALACION_HORA_INICIO`, `INSTALACION_HORA_LIMITE`). `INSTALACION_CONTROL_HORARIO = 0` permite probar a cualquier hora.
- Quien no se acreditó al instalar queda con `asistio = 0` (multa OMISO_MESA).
- Un miembro de mesa solo puede instalar si él mismo está acreditado.

## Flujo (pantalla en 4 pasos)
1. **Miembros:** leer el fotocheck QR (reutiliza `VerificarCredencial` del CUS07: vigente, mismo proceso y misma mesa) o acreditar con DNI (debe coincidir, RN30). También se puede marcar ausente. Se muestra la conformación resultante.
2. **Personeros:** de la mesa y generales o alternos de listas en carrera, con QR o DNI.
3. **Material:** lista de chequeo (`MaterialElectoral`), con los ítems obligatorios marcados con * y observaciones.
4. **Acta:** lista de requisitos y el botón «Instalar mesa y emitir acta». `sp_instalar_mesa` valida todo en una transacción, asigna los cargos, emite el acta y la firman (`firma_acta`) los tres miembros y los personeros. El QR de verificación (`/api/publico/actas/{token}`) se muestra una sola vez, con «Imprimir acta». El CEUNP, vencido el plazo, ve «Declarar mesa NO INSTALADA» con su motivo.

## Base de datos (`09_instalacion_mesa.sql`)
- `mesa_electoral.estado` + `NO_INSTALADA`
- `miembro_mesa`: `hora_acreditacion`, `metodo_acreditacion` (QR/DNI), `rol_instalacion`
- Tablas `instalacion_mesa` (material, observaciones, resultado) y `asistencia_personero_mesa`
- `sp_ventana_instalacion`, `sp_instalar_mesa` (reemplaza a la anterior, misma firma) y `sp_declarar_mesa_no_instalada`
- Bitácora: `ACREDITAR_MIEMBRO_MESA`, `ACREDITAR_PERSONERO_MESA`, `REGISTRAR_MATERIAL_MESA`, `INSTALAR_MESA`, `MESA_NO_INSTALADA`

## Endpoints (`/api/instalacion`)
| Método | Ruta | Rol |
|---|---|---|
| GET | `/procesos` | ADMIN, CEUNP |
| GET | `/mesas?procesoId=` · `/mesas/{id}` | ADMIN, CEUNP, MIEMBRO_MESA (solo su mesa) |
| POST | `/mesas/{id}/acreditar` `{codigo}` | CEUNP, MIEMBRO_MESA |
| POST | `/mesas/{id}/miembros/{idDocente}/asistencia` `{presente, dni}` | CEUNP, MIEMBRO_MESA |
| POST | `/mesas/{id}/personeros/{idPersonero}/asistencia` `{presente, dni}` | CEUNP, MIEMBRO_MESA |
| PUT | `/mesas/{id}/material` `{items, observaciones}` | CEUNP, MIEMBRO_MESA |
| POST | `/mesas/{id}/instalar` | CEUNP, MIEMBRO_MESA |
| POST | `/mesas/{id}/no-instalada` `{motivo}` | CEUNP |

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/instalacion/` (`InstalacionController`, `InstalacionConsulta`, `AcreditarMiembro`, `RegistrarInstalacion`, `MaterialElectoral`, `InstalacionDto`)
- Frontend: `frontend/src/pages/instalacion/` (`InstalacionMesaPage.jsx`, `ActaInstalacion.js`, `instalacion.css`)

## Prueba rápida
1. Ejecutar `09_instalacion_mesa.sql`. Tener el proceso en VOTACION con mesas sorteadas. Fuera del día y del horario de la elección, poner `INSTALACION_CONTROL_HORARIO = 0` en Parámetros.
2. CEUNP: «Credenciales y QR» → Miembros de mesa → emitir el fotocheck del presidente.
3. Entrar como el miembro de mesa (o CEUNP) → «Instalar mesa» → leer el QR o pegar su contenido → acreditar a los demás con DNI → marcar ausente a un titular y acreditar a un suplente (pasa a ejercer el cargo).
4. Material → «Marcar todo» → Guardar → Acta → «Instalar mesa y emitir acta» → «Imprimir acta».
5. Con el control horario en 1 y el plazo vencido, el CEUNP declara otra mesa NO INSTALADA.
