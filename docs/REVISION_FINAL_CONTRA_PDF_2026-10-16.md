# Revisión detallada contra el enunciado de MAGIS-AUTO

Fecha: 16 de octubre de 2026. Versión examinada: `5d57fa3e47d8b06dd40d5e46aad76c3fd687c8aa`, rama `pruebas-diego`.

**Revisión histórica previa a las correcciones:** el [cierre técnico posterior](CIERRE_TECNICO_2026-10-16.md) documenta los cambios en mantenimiento, cuotas, resúmenes y devengo. Los hallazgos y conteos de este informe corresponden a la versión examinada, no sustituyen el estado posterior.

## Dictamen

El funcionamiento ensayado es correcto: las 15 suites HTTP/SQL terminaron con **1,205 comprobaciones correctas** y las 26 tablas conservaron sus filas y valores iniciales después de cada suite. No se encontró un fallo funcional en esos casos. La compilación no produjo errores ni advertencias. También se recalculó independientemente el plan existente de la base principal.

**Esto no permite declarar cumplimiento literal del 100% del PDF.** Hay excepciones deliberadas al CRUD por entidad, alcance parcial del mantenimiento de personas/contactos sin expediente, una interpretación pendiente sobre intereses devengados y dos decisiones académicas que deben explicarse. La impresión real del nuevo diseño tampoco está certificada por esta revisión. Los pendientes están enumerados en la sección final, sin ocultarlos bajo el número de pruebas.

Este informe y la corrección del ensayo DOM se preparan localmente. No se publica, fusiona ni prepara la entrega en esta revisión. No se cambiaron las reglas ni el esquema de la base principal.

## Fuente y método

- Fuente completa: `C:\Users\dfern\Downloads\Base de Datos I Proyecto final I.pdf`. Cuatro páginas físicas: portada; contenido/contexto; incisos A–E; continuación de E y desarrollo/consultas/entrega. La numeración impresa del cuerpo es 1–3.
- SHA-256 del PDF: `175acf28315827321976af073e2a0620801fd8061261e14fa6dbb230129f927d`. Se extrajo todo el texto y se inspeccionaron visualmente las páginas físicas 3 y 4 que contienen los requisitos.
- Se contrastaron las definiciones SQL instaladas, columnas, índices, claves y restricciones de `MAGISAUTO_Proyecto_V2` y `MAGISAUTO_ValidacionV2`, además de los controladores, repositorios, modelos y pantallas del commit indicado.
- Las suites se ejecutaron secuencialmente en una copia temporal de los scripts, archivos web y compilación. Su configuración privada apunta exclusivamente a `MAGISAUTO_ValidacionV2`; no se editó la configuración de la aplicación de Diego. Se copiaron también la migración y el catálogo de reportes que requieren los ensayos.
- Los scripts de preparación/limpieza de pruebas usan SQL administrativo en la copia aislada. La aplicación de negocio usa procedimientos desde su API. Estas dos situaciones no se confunden al evaluar el requisito.
- Se compararon huellas SHA-256 de JSON ordenado por clave primaria de las 26 tablas antes y después de cada suite. Los identificadores/recibos pueden tener saltos; no se reiniciaron sus secuencias.
- La suite de Créditos vuelve a aplicar su migración aditiva en la base aislada para comprobar repetibilidad. No la ejecuta en la base principal.
- Los datos financieros de la base principal se leyeron para recalcular el contrato existente; no se escribieron allí datos de prueba.
- Evidencias nuevas: [índice de resultados](evidencias/auditoria-final-2026-10-16/resumen.json), [estructura](evidencias/auditoria-final-2026-10-16/estructura.json), [ejecuciones y conservación](evidencias/auditoria-final-2026-10-16/ejecuciones.json), [cálculos independientes](evidencias/auditoria-final-2026-10-16/calculos-independientes.json). Los resultados detallados por suite están en la misma carpeta.

**Cómo leer los estados:** Comprobado = trazado en código/SQL y respaldado por el ensayo indicado; Interpretación = funciona según una decisión documentada del equipo, sin aceptación del docente acreditada; Parcial = existe una limitación concreta frente al texto literal; Pendiente visual = no hay comprobación nueva de renderizado o impresión real. Ningún estado significa prueba exhaustiva de todas las entradas, equipos o concurrencias posibles.

## Contexto y objetivo general — páginas físicas 2 y 3

| ID | Punto del enunciado | Resultado y evidencia |
|---|---|---|
| G01 | Aplicación para financiamiento de vehículos nuevos de agencia | Comprobado. Aplicación web con clientes, vehículos, créditos y pagos; `Garantia.EsNuevo` está restringido a 1. |
| G02 | Base relacional para operación comercial y transaccional | Comprobado. 26 tablas, PK/FK activas, transacciones de expedientes, aprobación y pagos. |
| G03 | Control de saldos | Comprobado. `fn_Saldos`, estado de cuenta y reportes distinguen contrato, cobros, saldo, corte y anulación. Suites Pagos/Reportes. |
| G04 | Intereses devengados | Parcial respecto de esa expresión del contexto. Se calculan intereses del plan y cobrados; `Reporte10_Intereses` no calcula un devengo diario/mensual independiente. Ver H03. |
| G05 | Depreciación histórica frente al costo del financiamiento | Comprobado. `Depreciacion`, reportes 16/17 y valoraciones sucesivas con corte. No modifica la deuda. |
| G06 | Garantías cruzadas y control de incentivos | Comprobado en el alcance solicitado: vehículo y fiadores por crédito; comisión sobre pagos efectivos. No implica un motor automático de riesgo ni nómina de comisiones. |

Los párrafos de contexto describen la organización y finalidad educativa. No se usaron como autorización para contactar clientes, operar dinero real o certificar cumplimiento normativo externo. Se revisa el caso académico definido en el PDF.

## A. Clientes y referencias — página física 3

| ID | Requisito | Implementación y comprobación | Estado |
|---|---|---|---|
| A01 | Identificación única de cada cliente | `Persona`, `Deudor`, índices únicos filtrados de DPI/NIT y una persona por rol; altas duplicadas bloqueadas. Clientes y Fiadores. | Comprobado |
| A02 | Código interno correlativo | `CodigoPersona`/`CodigoDeudor` con identidad SQL; la interfaz muestra códigos. Los saltos no invalidan unicidad. | Comprobado |
| A03 | NIT, DPI y nombre completo | Campos y validaciones en `ClienteSolicitud`, `Persona` y expediente; primer nombre/apellido obligatorios, segundos opcionales. | Comprobado |
| A04 | Correo y varios teléfonos | Correo validado; `Telefono` admite filas por persona y correlativo; tipos de contacto y controles de expediente. | Comprobado |
| A05 | Varias direcciones | `Direccion`, tipos, departamento/municipio y detalle; edición transaccional de contactos. | Comprobado |
| A06 | Cliente con múltiples créditos; cada crédito de un cliente | FK obligatoria `Credito.CodigoDeudor`; no hay índice que limite al cliente a un crédito. Relación 1:N. | Comprobado en estructura y flujos de créditos |
| A07 | Tres o más referencias obligatorias | `Credito_Presentar` y `Credito_Aprobar` verifican tres distintas y completas; la aprobación revalida si se retiró una. Un expediente/borrador incompleto sí se puede guardar. | Comprobado con interpretación de borrador; H05 |
| A08 | Nombre, trabajo y relación de cada referencia | `Persona`, `Referencia.LugarTrabajo`, `DetalleReferencia.ParentescoRelacion` y catálogo de tipo; formulario de cliente. | Comprobado |
| A09 | Teléfonos celular/casa/trabajo y direcciones de referencia | Contactos propios por persona, tipos y múltiples filas; mínimo teléfono/dirección al presentar/aprobar. | Comprobado |
| A10 | Referencia vinculada al cliente que la presenta | PK de `DetalleReferencia` y FK; se permite reutilizar una referencia con otro cliente conservando sus datos. No cuenta repetida ni el propio cliente. | Comprobado |
| A11 | Fecha de nacimiento para cumpleaños | Campo obligatorio de cliente, fecha anterior a hoy; alimenta reporte 5. Es necesario para el ejemplo solicitado de carta. | Comprobado |

Fuentes: `Modelos/ClienteSolicitud.cs`, `Datos/ClienteRepositorio.cs`, `Datos/ContactosPersona.cs`, `Datos/ClienteSqlSesion.cs`, `wwwroot/clientes.*`, consultas integradas y procedimientos de Persona/Deudor/Referencia/DetalleReferencia/Telefono/Direccion.

## B. Vehículos y depreciación — página física 3

| ID | Requisito | Implementación y comprobación | Estado |
|---|---|---|---|
| B01 | VIN/chasis identificado e indexado inequívocamente | VIN único, 17 caracteres y alfabeto admitido; consulta por VIN y rechazo de duplicados. | Comprobado |
| B02 | Marca, línea/modelo y año | PK compuesta de Línea por marca; Garantía referencia marca/línea y conserva año. | Comprobado |
| B03 | Precio al contado en Q | `ValorAgencia decimal(18,2)` positivo; controles de precisión y presentación monetaria. | Comprobado |
| B04 | Placa cuando exista | Placa opcional y única cuando no es nula; formulario la permite. | Comprobado |
| B05 | Código interno según la marca | Hay `CodigoGarantia` correlativo global relacionado con marca/línea; no numeración reiniciada por marca. | Interpretación; H04 |
| B06 | Depreciación inmediata 15%–20% | Parámetro y CHECK; aprobación crea una valoración inicial en la misma transacción que el contrato/plan. | Comprobado |
| B07 | Un único crédito activo por vehículo | Índice único filtrado `UX_Credito_VehiculoActivo`, bloqueos y validación de aprobación. Dos borradores no son dos contratos vigentes. | Comprobado |
| B08 | Conservación histórica de garantía | Valoraciones posteriores, búsqueda y corte; no edición/borrado de valoraciones utilizadas por contratos. Anular pago no puede reabrir un crédito si el auto respalda otro activo. | Comprobado en SQL y suites aplicables |

Fuentes: `Datos/VehiculoRepositorio.cs`, `Datos/ValoracionRepositorio.cs`, modelos/controladores de vehículos y valoraciones, `wwwroot/vehiculos.*`, Garantia/Depreciacion, Credito_Aprobar y DetallePago_Anular.

## C. Créditos, plan y fiadores — página física 3

| ID | Requisito | Implementación y comprobación | Estado |
|---|---|---|---|
| C01 | Número de obligación único | PK de `Credito.NumeroCredito`; duplicados rechazados. | Comprobado |
| C02 | Fecha exacta de aprobación | `datetime2(0)` y responsable; servidor asigna hora de Guatemala y rechaza futuro. | Comprobado |
| C03 | Plazo usual de 60 meses | 60 predeterminado; admite 12/24/36/48/60. El PDF dice comúnmente 60, no exclusivamente 60. | Comprobado |
| C04 | Enganche y monto neto = contado − enganche | Precio contractual guardado, enganche y `vw_CreditoResumen.MontoFinanciado`; valores exactos decimales. El mínimo de 20% es acuerdo adicional. | Comprobado |
| C05 | Una fila por cuota: crédito, correlativo y vencimiento | `DetalleCuota` PK (NumeroCredito,Cuota); fechas mensuales generadas al aprobar. | Comprobado |
| C06 | Desglose: interés, capital, manejo, seguro auto y vida | Capital/interés guardados; vista deriva cargos de condiciones contractuales congeladas. Se muestran en plan. | Comprobado |
| C07 | Manejo Q25 mensuales | CHECK en Parámetro/Crédito; API no admite otro manejo; campo de lectura. | Comprobado |
| C08 | Tasa inicial anual 12.5%, configurable | Configuración con porcentaje visible 12.5/fracción SQL 0.125; nuevas versiones y activación atómica. Los créditos aprobados conservan condiciones. | Comprobado |
| C09 | Intereses calculados sobre saldos | Aprobación calcula interés mensual sobre capital pendiente; amortiza capital y ajusta última cuota. Recalculo independiente del contrato existente. | Comprobado para reglas y casos ensayados |
| C10 | Guardar intereses totales y total neto recaudable | `ResumenCredito`, SUM(Interes) y SUM(Total); total contractual incluye capital/cargos/seguros y excluye enganche. | Comprobado; definición de total documentada |
| C11 | Fiadores opcionales según decisión de riesgos | `FiadoresRequeridos` admite 0 o más; comité representado por responsable declarado; no scoring automático solicitado. | Comprobado |
| C12 | Datos de fiador: DPI, NIT, nombres, teléfono y correo | Persona compartida, expediente de Fiadores; aprobación exige contactos de los fiadores requeridos. | Comprobado |
| C13 | Varios fiadores por crédito y fiador en varios créditos | Tabla puente `CreditoFiador`; PK compuesta, sin unicidad global de fiador; se bloquea ser fiador del propio crédito. | Comprobado en modelo y flujo |

Los seguros usan tasas mensuales configuradas sobre el monto inicialmente financiado. El PDF exige ambos conceptos pero no fija sus tasas ni esa base; es un acuerdo del proyecto. No se presentan como cotizaciones oficiales. El total recaudable es contractual, no saldo actual, utilidad ni efectivo recibido. Se conserva enganche separado para evitar contarlo dos veces.

Fuentes: `Datos/CreditoRepositorio.cs`, `Datos/ParametroCreditoRepositorio.cs`, `Datos/FiadorRepositorio.cs`, modelos/controladores correspondientes, `wwwroot/creditos.*`, `wwwroot/parametros.*`, `Credito_Aprobar`, `vw_CuotaDesglosada`, `ResumenCredito` y `CreditoFiador_*`.

## D. Vendedores y comisión — página física 3

| ID | Requisito | Implementación y comprobación | Estado |
|---|---|---|---|
| D01 | Código de empleado, DPI, nombre y agencia/región | Vendedor con código único, Persona y Agencia; edición/búsqueda y validaciones. | Comprobado |
| D02 | Un vendedor obligatorio por crédito | FK no nula de Crédito; selección obligatoria. La agencia contractual queda guardada. | Comprobado |
| D03 | Comisión específica pactada por crédito | Campo editable en borrador, porcentaje decimal tipado; no obliga a usar siempre el predeterminado. | Comprobado |
| D04 | Comisión sobre cada pago efectivo, sin anticipo | `vw_PagoDesglosado`: monto efectivo × porcentaje contractual; pago de Q1,000 al 3.25% genera Q32.50; anulaciones revierten comisión efectiva. | Comprobado |
| D05 | Control de incentivos | Reporte 8 separa generado y revertido. No existe desembolso/nómina de comisión al vendedor, que no se confunde con la comisión generada. | Comprobado en el alcance de cálculo; no acredita pago real al vendedor |

## E. Cuotas y recaudación — páginas físicas 3 y 4

| ID | Requisito | Implementación y comprobación | Estado |
|---|---|---|---|
| E01 | Aprobar genera automáticamente cuotas mensuales correlativas | Una transacción genera plan, valoración y resumen; doble aprobación rechazada. | Comprobado |
| E02 | Cuota pertenece exclusivamente a un crédito | FK/PK compuesta; no se reutiliza una cuota sin su número de crédito. | Comprobado |
| E03 | Un pago total o múltiples abonos por cuota | Varias filas de `DetallePago`, desglose proporcional, liquidación y rechazo de sobrepago. | Comprobado |
| E04 | Comprobante de caja único | Identificador/recibo de servidor y restricción única; no se reutilizan recibos anulados. | Comprobado |
| E05 | Fecha y hora del pago | `FechaPago datetime2(0)`; API usa tiempo de procesamiento; SQL impide futuro y movimientos retroactivos incompatibles. | Comprobado |
| E06 | Monto depositado exacto en Q | `Monto decimal(18,2)` almacenado y CHECK de igualdad al desglose; no es solo una suma mostrada en pantalla. | Comprobado |
| E07 | Medio explícitamente codificado | `CodigoTipoPago`, catálogo con los cinco ejemplos (depósito, ACH, tarjetas crédito/débito, efectivo) y mantenimiento. | Comprobado |
| E08 | Referencia bancaria/boleta/autorización | Campo de pago; obligatorio cuando TipoPago.RequiereReferencia es verdadero; efectivo puede no requerirla. | Comprobado |
| E09 | Historial de movimientos | Anulación con motivo/responsable/fecha; conserva monto y componentes; reportes históricos consideran la fecha de anulación. | Comprobado; excepción a borrado físico |

Fuentes: `Datos/PagoRepositorio.cs`, `Modelos/PagoSolicitud.cs`, `Controllers/PagosController.cs`, `wwwroot/pagos.*`, DetallePago_Insertar/Actualizar/Eliminar/Anular y fn_Saldos.

## Desarrollo: aplicación, API, SQL y CRUD — página física 4

| ID | Requisito | Resultado |
|---|---|---|
| T01 | Aplicación web y/o móvil | Web ASP.NET Core con 13 páginas. El PDF no exige además una aplicación móvil. |
| T02 | Interfaz para clientes, garantías, emisión y pagos | Existen los cuatro recorridos y sus suites funcionales actuales. |
| T03 | Operaciones de base solo mediante procedimientos | Comandos de la API revisados con `CommandType.StoredProcedure`; helpers llaman procedimientos de listas internas. No se encontró SQL textual de negocio ejecutado por la API. |
| T04 | Llamadas a procedimientos únicamente desde APIs | El navegador usa rutas HTTP; la conexión está en servidor. Scripts de instalación/prueba son herramientas administrativas separadas, no un acceso SQL desde la interfaz. |
| T05 | Insertar/actualizar/borrar por entidad | **Parcial en lectura literal**. 25 tablas tienen los cinco nombres de SP; ResumenCredito solo Listar/Buscar. Las operaciones financieras y el mantenimiento sin expediente tienen límites descritos abajo. |
| T06 | Listar todas las filas y buscar por criterio | Catálogos y seis consultas integradas cubiertos. Cuotas y resúmenes se consultan integrados por crédito/reportes, no en mantenimientos globales independientes. No se afirma un explorador universal de todas las tablas. |
| T07 | Consultar todos los catálogos | Marcas, líneas, agencias, siete auxiliares, parámetros y roles; búsquedas y listados comprobados. |

### Matriz actual de las 26 entidades

I/A/E = insertar/actualizar/eliminar. Las operaciones integradas se realizan al guardar un expediente. Tener SP nominales no significa que toda fila y todo estado sean editables.

| Entidad | I/A/E en aplicación | Listar y buscar | Límite explícito |
|---|---|---|---|
| Departamento | Sí/Sí/Sí | Auxiliares | Borrado bloqueado con dependencias. |
| Municipio | Sí/Sí/Sí | Auxiliares y filtro de departamento | Clave compuesta; no reasignación arbitraria de identidad. |
| TipoTelefono | Sí/Sí/Sí | Auxiliares | Dependencias protegidas. |
| TipoDireccion | Sí/Sí/Sí | Auxiliares | Dependencias protegidas. |
| TipoGarantia | Sí/Sí/Sí | Auxiliares | Dependencias protegidas. |
| TipoReferencia | Sí/Sí/Sí | Auxiliares | Dependencias protegidas. |
| TipoPago | Sí/Sí/Sí | Auxiliares | Dependencias protegidas; cambios en requisito bancario aplican a próximos pagos. |
| Marca | Sí/Sí/Sí | Marcas | No elimina líneas dependientes. |
| Linea | Sí/Sí/Sí | Líneas | Clave por marca; vehículos protegen borrado. |
| Agencia | Sí/Sí/Sí | Agencias | Vendedores/créditos protegen borrado. |
| Persona | I/A integradas; E explícita | Consulta global de Personas | Sin editor independiente para una ficha que quedó sin expediente; FK protege contactos/roles. |
| Telefono | I/A/E integradas | Consulta global | Sin mantenimiento independiente de contacto de persona sin expediente. |
| Direccion | I/A/E integradas | Consulta global | Mismo límite de acceso al mantenimiento por expediente. |
| Deudor | Sí/Sí/Sí | Clientes | Eliminar rol no elimina persona; dependencias bloquean. |
| Referencia | I/A en Clientes; E explícita | Consulta global | Quitar del cliente desvincula; no borra ficha ni contactos. Ficha libre sin editor independiente. |
| DetalleReferencia | I/A/E en Clientes | Consulta global | Puede compartir la ficha sin sobrescribirla al vincularla. |
| Fiador | Sí/Sí/Sí | Fiadores | Eliminar rol no elimina persona; créditos protegen. |
| Vendedor | Sí/Sí/Sí | Vendedores | Dependencias y datos compartidos protegidos. |
| Garantia | Sí/Sí/Sí con restricciones | Vehículos | Historial contractual protege datos; dependencias impiden borrar. |
| ParametroCredito | Sí/Sí/Sí con restricciones | Parámetros | Solo editar/eliminar versión libre e inactiva; activar es transaccional. |
| Credito | Borrador I/A/E; contrato anulación | Créditos y reportes | No se borran ni reescriben contratos aprobados. |
| CreditoFiador | Asignar/sustituir/quitar en borrador | Consulta global y crédito | Respaldo aprobado se conserva. |
| Depreciacion | Inicial automática, posteriores I; A/E restringidas | Historial por vehículo, API y reportes | Valoración contractual protegida; API de alta posterior exige historial aprobado. |
| DetalleCuota | Generación automática; sin editor manual | Plan y detalle por crédito; SQL Listar/Buscar | SP I/A/E solo admiten borrador; no son CRUD libre expuesto en UI. |
| DetallePago | I; A de observación; E como anulación | Pagos, filtros y reportes | No cambia importe/contrato después de registrar; no borrado físico. |
| ResumenCredito | Generado al aprobar; sin A/E manual | Integrado en crédito/reportes; SQL Listar/Buscar | No existen SP Insertar/Actualizar/Eliminar propios. |

El PDF no exige cinco botones independientes por tabla. Sin embargo, tampoco concede expresamente las excepciones financieras o de filas sin expediente. La matriz permite explicar exactamente qué sí se hace; no sustituye la aceptación del docente.

## Veinte consultas y razón de uso — página física 4

Hay 20 definiciones en `Datos/CatalogoReportes.cs`, con procedimiento, utilidad, filtros, secciones y advertencias. Las 20 se ejecutaron por API y se compararon con su salida SQL, incluidos valores, nulos, fechas y número de tablas. La comparación API–SP verifica transporte/representación; no es por sí sola una demostración matemática independiente de toda consulta.

| # | Consulta y finalidad | Filtros principales | Acción contextual |
|---|---|---|---|
| 1 | Créditos emitidos: volumen de colocación del período | Desde/hasta | Ver plan; exportar/imprimir |
| 2 | Cartera en mora: identificar deuda vencida y días de atraso | Corte/días mínimos | Ver plan |
| 3 | Pagos por medio: comparar uso y movimiento neto por medio | Desde/hasta | Exportar/imprimir agregado |
| 4 | Ventas por vendedor: comparar capital colocado | Desde/hasta | Exportar/imprimir agregado |
| 5 | Cumpleañeros: carta individual por cliente | Mes/año | Ver e imprimir carta; no enviar correos |
| 6 | Estado de cuenta: contratos, cuotas y movimientos del cliente | Cliente/corte | Ver plan y leer registro |
| 7 | Plan por crédito: desglose completo y saldos al corte | Crédito/corte | Leer registro ancho; exportar/imprimir |
| 8 | Comisiones: generado y revertido por vendedor | Desde/hasta | Exportar/imprimir; no desembolsar comisión |
| 9 | Capital pendiente: capital recuperado y por recuperar | Corte | Ver plan |
| 10 | Intereses del contrato: plan frente a cobrado/pendiente | Corte | Ver plan; no devengo contable |
| 11 | Próximos vencimientos: preparar cobranza | Corte/horizonte | Ver plan |
| 12 | Abonos parciales: localizar cuotas aún no liquidadas | Corte | Ver plan |
| 13 | Créditos por marca/línea: comparar colocación | Desde/hasta | Exportar/imprimir agregado |
| 14 | Cartera por agencia/región: comparar cartera y mora | Corte | Leer registro si es ancho |
| 15 | Mora por rangos: clasificar cada crédito una sola vez | Corte | Ver créditos del rango y luego plan |
| 16 | Garantía frente al capital: detectar cobertura insuficiente | Corte | Ver plan/leer registro |
| 17 | Depreciación y costo: relacionar precio, valor y desembolso | Corte | Ver plan/leer registro |
| 18 | Créditos por fiador: exposición de cada codeudor | Corte | Ver plan; advierte duplicidad entre fiadores |
| 19 | Recaudación por componentes: capital, interés y cargos netos | Desde/hasta | Exportar/imprimir agregado |
| 20 | Pagos anulados: auditoría de reversión, motivo y responsable | Desde/hasta | Ver plan/leer registro |

Los siete ejemplos del enunciado están incluidos. Los resultados ofrecen Volver a filtros e impresión; tablas con filas permiten CSV. Se mantienen los cortes al abrir plan/rango. La comisión es sobre pagos efectivos, las anulaciones se consideran en su fecha, y una valoración no recalcula el préstamo. La tabla de fiadores no debe sumarse como cartera global porque puede repetir créditos.

## Comprobaciones nuevas y anteriores

| Suite ejecutada en esta revisión | Comprobaciones correctas |
|---|---:|
| Marcas | 28 |
| Líneas | 42 |
| Agencias | 34 |
| Vendedores | 59 |
| Clientes | 62 |
| Fiadores | 70 |
| Vehículos | 80 |
| Catálogos auxiliares | 242 |
| Parámetros y comisión | 134 |
| Créditos | 57 |
| Pagos | 126 |
| Reportes | 134 |
| Valoraciones | 42 |
| Consultas integradas y eliminación | 86 |
| Excepciones financieras | 9 |
| **Total HTTP/SQL de estas suites** | **1,205** |

Son comprobaciones, no 1,205 escenarios independientes: algunas suites repiten disponibilidad, validaciones y reglas compartidas. No se suman las evidencias históricas del mismo ensayo como si fueran pruebas adicionales nuevas.

- **Cálculo independiente: 39 comprobaciones** sobre el único contrato aprobado disponible en la base principal. Precio Q100,000, enganche Q20,000, capital Q80,000 y 12 cuotas. Se recalcularon interés, amortización, vencimientos, seguros, Q25 de manejo y suma del resumen con aritmética decimal. No demuestra todas las combinaciones de plazo/tasa; las 75 simulaciones de plan y 1,000 de reparto guardadas en `database/v2/entrega/validacion-calculos.json` son evidencia histórica separada.
- **Formato de reportes: 15 comprobaciones nuevas**, sin navegador.
- **DOM: 198 comprobaciones correctas en la reejecución.** El primer intento falló por un selector del ensayo que exigía `/identidad.css` exacto. La aplicación usa `/identidad.css?v=20261016-2` desde la corrección de caché. Se corrigió el ensayo para comprobar la ruta de la hoja de estilos sin rechazar su versión. El resultado nuevo se conserva en [diseno-dom.json](evidencias/auditoria-final-2026-10-16/diseno-dom.json); no se reutiliza el archivo antiguo. Estas comprobaciones no acreditan renderizado ni impresión reales.
- **Visual:** la captura aportada por Diego confirma el nombre MAGISAUTO blanco y legible, paleta y menú en Marcas; indicó que era el único defecto observado. No acredita por sí sola impresión ni todas las ventanas en todos los anchos. El intento nuevo del navegador integrado a localhost:5164 devolvió `ERR_CONNECTION_REFUSED`; no se obtuvo una vista previa nueva de impresión.
- **Estructura:** columnas, restricciones y FK coinciden entre principal/validación. Las 157 definiciones coinciden quitando espacios finales. Los índices tienen la misma estructura; siete nombres generados automáticamente difieren sin cambiar la regla. No hay CHECK ni FK deshabilitadas.
- **Paquete del equipo:** su archivo SQL conserva la huella publicada `3ffb46fe7a42c9bd468c7fb703c3a9476285afbcd2242d7de418e3ebdbc61a3a`. No se reinstaló el paquete en otra máquina durante esta revisión; el ensayo previo de instalación se conserva como evidencia anterior.

## Hallazgos y decisiones antes de cerrar

| ID | Prioridad y situación | Qué falta y criterio concreto |
|---|---|---|
| H01 | Alta para aceptación académica: CRUD financiero literal | El PDF pide I/A/E por entidad. ResumenCredito carece de SP mutadores, DetalleCuota no tiene edición manual en UI y pagos/contratos usan anulación. Presentar la matriz al docente o ajustar el alcance que exija. No habilitar borrado de historial solo para llenar casillas. |
| H02 | Media: mantenimiento fuera de expedientes | Personas, teléfonos, direcciones y referencias sin un expediente accesible pueden consultarse, pero no tienen editor independiente. Si se exige mantenimiento de cualquier fila, falta cubrir ese recorrido. No confundir consulta global con CRUD universal. |
| H03 | Media: significado de intereses devengados | El contexto los menciona; el sistema implementa intereses contractuales y cobrados. Aclarar si basta ese alcance o si se requiere devengo por fecha con una regla definida. No se inventó una regla contable. |
| H04 | Interpretación: código de vehículo “según la marca” | Código global relacionado con marca, no contador por marca. Decisión del equipo ya documentada; falta aceptación externa si se exige lectura estricta. |
| H05 | Interpretación: mínimo de referencias al tramitar | Se permite guardar preparación incompleta, pero presentar/aprobar exige tres completas. Explicarlo como borrador; no afirmar que se aprueban clientes incompletos. |
| H06 | Verificación visual pendiente acotada | Vista previa de impresión del reporte más ancho, carta y navegación de ventanas en ancho reducido. La lógica DOM no sustituye el navegador real; no repetir las pruebas CRUD ya aprobadas. |
| H07 | Documentación histórica frente a entrega actual | Algunos documentos dicen 25 tablas, cambios locales o funciones pendientes porque describen una fase anterior. Conservar el historial, pero usar este estado actual y documentación vigente para la defensa. Manual final de Josué y versión final SQL de Dylan no se han recibido/revisado aquí. |
| H08 | Ensayo desactualizado encontrado | Se corrigió el selector de identidad en `Verificar-DisenoDOM.cjs`. Es una corrección del ensayo; no un defecto nuevo de negocio ni un cambio SQL. |

H01–H05 no son errores de cálculo descubiertos por una prueba fallida; son diferencias de alcance/interpretación que siguen importando aunque pasen las suites. Las decisiones previas de Diego no se presentan como aprobación del catedrático.

## Entrega, puntuación y cierre del alcance del PDF

- Fecha indicada: **17 de octubre de 2026**. Es un dato del enunciado, no una confirmación de recepción ni de plataforma de entrega.
- Trabajo individual o grupo de hasta tres, formado por el catedrático. En esta conversación se mencionan Diego, Dylan y Josué; no se verifica administrativamente la integración del grupo.
- Puntuación indicada: **20 puntos de zona y 15 de examen final**. No se calcula una nota a partir de las pruebas.
- La candidatura al congreso del **31 de octubre de 2026** corresponde al mejor proyecto; no añade por sí sola una función obligatoria.
- El PDF no especifica login, aplicación móvil adicional, despliegue público, motor automático de riesgo, envío real de felicitaciones ni nómina de comisiones. No se convierten en pendientes inventados.
- Tampoco se atribuye a este PDF un formato obligatorio de manual, portada o documentación de SQL que no aparece en sus páginas. Esos documentos son trabajo acordado por el equipo y deben revisarse como tales.

**Siguiente decisión:** resolver la aceptación o alcance de H01–H05 y completar la comprobación visual acotada de H06. Después se revisan los documentos finales del equipo y la entrega. Esta auditoría no publica cambios ni declara aprobado el proyecto por el docente.
