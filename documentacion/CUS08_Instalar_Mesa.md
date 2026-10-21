# CUS08 · Instalar mesa

**Actor:** Presidente de mesa (el CEUNP supervisa, declara NO INSTALADA y evalúa la nulidad; ADMIN solo consulta) · **Pantalla:** menú «Instalar mesa» (MIEMBRO_MESA) e «Instalación de mesas» (CEUNP)
**Caso de negocio:** CUN07 Instalar mesa de sufragio · **Módulo:** M08 (RF56 a RF60) · **Reglas:** RN07, RN19, RN28, RN30, RN35
**Requiere:** proceso en VOTACION, mesas con sus 6 miembros sorteados (CUS06), fotocheck QR emitido (CUS07) y personeros acreditados (CUS05).
**Instalación:** en una base ya creada, ejecutar `base-de-datos/09_instalacion_mesa.sql`. `01_crear_base_de_datos.sql` ya lo incluye al final y `02_limpiar_datos_electorales.sql` vacía sus tablas.

## Correspondencia con el diagrama de colaboración («Colaboracion - Instalar mesa», `diagramas/Sistema De Elecciones.mdl`)

| Mensaje del diagrama | Frontend | Backend |
|---|---|---|
| 1 `escanearCredencialQR(token)` | `InstalacionMesaPage.escanearCredencialQR` (lector `EscanerQR` del CUS07: pistola o cámara) | `POST /api/instalacion/mesas/{id}/llegada` `{codigo}` |
| 2 `registrarLlegada(token)` | — | `RegistrarLlegadaMiembro.registrarLlegada` (valida con `VerificarCredencial` del CUS07: vigente, mismo proceso, misma mesa) |
| 3 `actualizarAsistencia(id_docente, hora_llegada)` | — | `RegistrarLlegadaMiembro.actualizarAsistencia` → `miembro_mesa.asistio`, `hora_acreditacion`, `metodo_acreditacion` |
| 4 `mostrarMiembroPresente()` | Resultado de la lectura, conformación y tabla de miembros | La respuesta trae el detalle de la mesa |
| 5 `ingresarMaterial(padron, actas, cedulas, anfora, cabina)` | Paso 3: estado de cada material, cantidad de cédulas, firma de cédulas | `PUT /api/instalacion/mesas/{id}/material` |
| 6 `verificarMaterial(datos)` | — | `VerificarMaterial.verificarMaterial` |
| 7 `registrarMaterial(id_mesa, estado_material)` | — | `VerificarMaterial.registrarMaterial` → `instalacion_mesa` |
| 8 `mostrarEstadoMaterial()` | Estado del material y requisitos | La respuesta trae el detalle de la mesa |
| 9 `confirmarInstalacion()` | Paso 4: «Instalar mesa y emitir acta» → «Confirmar instalación» | `POST /api/instalacion/mesas/{id}/instalar` |
| 10 `instalarMesa(id_mesa)` | — | `InstalarMesa.instalarMesa` → `sp_instalar_mesa` |
| 11 `[antes de 12:00] actualizarEstado('INSTALADA', hora_instalacion)` | — | `sp_instalar_mesa` (horario con `sp_ventana_instalacion`) → `mesa_electoral` |
| 12 `insertarActa('INSTALACION', hash)` | — | `sp_instalar_mesa` → `sp_emitir_acta` → `acta_electoral` (+ `firma_acta`) |
| 13 `mostrarActaInstalacion()` | `ActaVista`: datos, firmas, QR de verificación e «Imprimir acta» (`ActaInstalacion.js`) | La respuesta trae el acta y el token del QR, que se entrega una sola vez |

### Cambios que conviene hacer en el diagrama
- El mensaje 7 se guarda en `instalacion_mesa`, que tiene una fila por mesa y amplía MesaElectoral: material, cédulas, observaciones y resultado. No se guarda en columnas de `mesa_electoral` porque el registro se congela al instalar (trigger `trg_instalacion_bu`) y además guarda la evaluación de nulidad (RF60).
- El mensaje 5 debe incluir el cartel de candidatos (RF57): `ingresarMaterial(padron, actas, cedulas, cartel, anfora, cabina)`.

## Flujos alternos (CUN07)
- **Sin QR:** la llegada se registra con el DNI, que debe coincidir con el del docente (RN30). También se puede marcar al miembro como ausente.
- **Falta un titular:** asume el cargo el primer suplente presente, según el orden del sorteo. La conformación se ve en vivo en la pantalla.
- **Faltan titulares y suplentes:** se registra a otro integrante de la comunidad universitaria (tabla `reemplazo_mesa`). Debe ser un docente ACTIVO identificado con su DNI, que no sea miembro de una mesa del proceso, ni candidato (RN20), ni personero.
- **Personeros:** el presidente recibe sus credenciales (CUN07, paso 4) con QR o DNI. Su presencia es opcional y los presentes firman el acta.
- **Pasadas las 12:00 (RF58):** `InstalarMesa.vigilarPlazo` ejecuta cada minuto `sp_marcar_mesas_no_instaladas`, y también se ejecuta al consultar. La mesa queda NO_INSTALADA, sus electores ya no pueden votar y los miembros que no llegaron quedan como inasistentes (RN35). El CEUNP también puede declararla NO INSTALADA con un motivo.
- **Evaluación de nulidad (RF60):** el CEUNP ve el aviso en el menú (contador) y en la pantalla, y registra una sola vez si PROCEDE o NO_PROCEDE la nulidad, con su fundamento.

## Reglas de la instalación (`sp_instalar_mesa`, en una sola transacción)
- El proceso está en VOTACION y la mesa en PENDIENTE.
- Es el día de `fecha_inicio` del proceso, entre `INSTALACION_HORA_INICIO` y `INSTALACION_HORA_LIMITE` (por defecto 9 y 12).
- La mesa tiene sus 6 miembros sorteados y los tres cargos están cubiertos (titular, suplente o reemplazante).
- Se recibió todo el material (RF57), se indicó la cantidad de cédulas y el presidente firmó las cédulas.
- Si se cumple todo, el acta (RF59) guarda la hora, el estado del material, las cédulas recibidas, los miembros, reemplazantes y personeros y las observaciones, con su huella SHA-256. La firman los tres que ejercen los cargos y los personeros presentes.
- Entre los miembros instala el **presidente en funciones**. El CEUNP siempre puede instalar.

Para probar fuera del día de la elección, ponga `INSTALACION_CONTROL_HORARIO = 0` en Parámetros. En ese caso tampoco se marcan mesas automáticamente.

## Endpoints (`/api/instalacion`)
| Método | Ruta | Rol |
|---|---|---|
| GET | `/procesos` · `/alertas` | ADMIN, CEUNP |
| GET | `/mesas?procesoId=` · `/mesas/{id}` | ADMIN, CEUNP, MIEMBRO_MESA (solo su mesa) |
| POST | `/mesas/{id}/llegada` `{codigo}` | CEUNP, MIEMBRO_MESA |
| POST | `/mesas/{id}/miembros/{idDocente}/asistencia` · `/personeros/{idPersonero}/asistencia` `{presente, dni}` | CEUNP, MIEMBRO_MESA |
| POST / DELETE | `/mesas/{id}/reemplazantes` `{cargo, dni}` · `/reemplazantes/{cargo}` | CEUNP, MIEMBRO_MESA presente |
| PUT | `/mesas/{id}/material` `{items:{PADRON:{estado,observacion},…}, cedulasRecibidas, cedulasFirmadas, observaciones}` | CEUNP, MIEMBRO_MESA presente |
| POST | `/mesas/{id}/instalar` | CEUNP, presidente en funciones |
| POST | `/mesas/{id}/no-instalada` `{motivo}` · `/mesas/{id}/evaluacion-nulidad` `{decision, fundamento}` | CEUNP |

## Base de datos (`09_instalacion_mesa.sql`)
- `mesa_electoral.estado` + `NO_INSTALADA`. `miembro_mesa` + `hora_acreditacion`, `metodo_acreditacion`, `rol_instalacion`.
- Tablas `instalacion_mesa`, `asistencia_personero_mesa` y `reemplazo_mesa`.
- `sp_ventana_instalacion`, `sp_instalar_mesa` (reemplaza a la anterior, misma firma), `sp_declarar_mesa_no_instalada`, `sp_marcar_mesas_no_instaladas` y `sp_evaluar_nulidad_mesa`.
- Parámetros: `INSTALACION_HORA_INICIO`, `INSTALACION_HORA_LIMITE` e `INSTALACION_CONTROL_HORARIO`.
- Bitácora: `VERIFICAR_CREDENCIAL`, `REGISTRAR_LLEGADA_MIEMBRO`, `RECIBIR_CREDENCIAL_PERSONERO`, `REGISTRAR_REEMPLAZANTE_MESA`, `VERIFICAR_MATERIAL_MESA`, `INSTALAR_MESA`, `MESA_NO_INSTALADA` y `EVALUAR_NULIDAD_MESA`.

## Archivos
- Backend: `backend/src/main/java/pe/unp/elecciones/electoral/instalacion/` (`InstalacionController`, `RegistrarLlegadaMiembro`, `VerificarMaterial`, `InstalarMesa`, `InstalacionConsulta`, `MaterialElectoral`, `InstalacionDto`, `InstalacionConfig`)
- Frontend: `frontend/src/pages/instalacion/` (`InstalacionMesaPage.jsx`, «PantallaInstalacion»; `ActaInstalacion.js`; `instalacion.css`)

## Prueba rápida
1. Ejecutar `09_instalacion_mesa.sql`. Tener el proceso en VOTACION y las mesas sorteadas. Fuera del horario, poner `INSTALACION_CONTROL_HORARIO = 0`.
2. CEUNP: en «Credenciales y QR», emitir los fotochecks de los miembros de la mesa.
3. Presidente: en «Instalar mesa», escanear su fotocheck y el de los demás, o registrarlos con DNI. Marcar ausente a un titular y ver que asume un suplente. Si no quedan suplentes, «Registrar reemplazante».
4. En el paso 3, pulsar «Todo conforme», indicar la cantidad de cédulas, marcar «El presidente firmó las cédulas en el reverso» y pulsar «Verificar y registrar material».
5. En el paso 4, pulsar «Instalar mesa y emitir acta», confirmar y luego «Imprimir acta». El QR abre `/api/publico/actas/{token}`, que verifica la huella.
6. Con `INSTALACION_CONTROL_HORARIO = 1` y la hora límite vencida, las mesas pendientes pasan solas a NO INSTALADA. El CEUNP ve el aviso, entra a la mesa y registra la evaluación de nulidad.
