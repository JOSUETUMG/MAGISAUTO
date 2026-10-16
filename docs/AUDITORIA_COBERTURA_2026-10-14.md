# Revisión de cobertura por entidad — 14 de octubre de 2026

Actualización del 15 de octubre: consultar el [cierre C05/C06](FASE_6_Cierre_C05_C06.md)
para el alcance implementado, confirmaciones manuales y matriz financiera. Este informe
conserva su diagnóstico histórico; sus pendientes no deben contarse de nuevo sin ese complemento.

Nota posterior: esta auditoría describe el commit base, antes de implementar los siete
catálogos. El [avance posterior y sus pruebas](FASE_6_Catalogos_Auxiliares.md) se documentan
por separado para conservar el alcance histórico de esta revisión.
También se incorpora posteriormente [Parámetros y comisión](FASE_6_Parametros_y_Comision.md)
para los hallazgos C02/C03; esta matriz inicial no se presenta como el estado actual de implementación.

## Alcance y versión

Revisión de `pruebas-diego`, commit base `cf6658a58a085c8d35996c208d69ef615840d8b5`.
El árbol de trabajo estaba limpio al comenzar. Esta entrega añade únicamente este informe
y su [inventario de evidencia estática](evidencias/cobertura-2026-10-14.json).
No modifica aplicación, procedimientos, datos, configuración local, ramas de compañeros ni GitHub.

Objetivo: identificar lo que falta entre SQL, API e interfaz antes de implementar más funciones.
No es una nueva prueba funcional, una auditoría exhaustiva de seguridad ni un cierre de fase.
La instalación y las capturas de Dylan son evidencia adicional de su recorrido, no certificación
de operaciones que todavía no están expuestas en la aplicación.

Referencia de requisitos: PDF del docente «Base de Datos I Proyecto final I.pdf», página
física 4, apartados Desarrollo del proyecto y Módulo de consultas; incisos A–E en páginas
físicas 3–4. Se solicita insertar, actualizar, borrar, listar y buscar por entidad, acceso SQL
mediante procedimientos llamados desde API, interfaces principales y al menos 20 consultas
financieras con explicación de su utilidad. El PDF no obliga a una pantalla separada por tabla.

## Resultado principal

- Las 26 tablas tienen procedimientos de listado y búsqueda. Hay cinco operaciones nominales
  para 25 entidades; `ResumenCredito` solo tiene Listar y Buscar, por su naturaleza derivada.
- Se identificaron 151 definiciones definitivas de procedimientos en el paquete del equipo y
  20 reportes registrados en la API. La presencia del nombre no acredita ejecución o permiso
  para editar cualquier estado: se revisaron también restricciones financieras relevantes.
- Faltan mantenimientos de siete catálogos auxiliares, parámetros del crédito y valoraciones.
  Sus procedimientos ya existen; no es necesario rediseñar las tablas para empezar.
- La comisión específica por crédito está admitida en SQL, pero no se captura ni envía desde
  el formulario/API de Créditos. Actualmente se aplica el valor predeterminado del parámetro activo.
- Personas, contactos, referencias y asignaciones tienen operaciones integradas en expedientes.
  No deben confundirse con cobertura completa de todas sus filas y criterios de consulta.
- Los movimientos financieros requieren distinguir generación automática, actualización limitada
  y anulación. No se recomienda habilitar borrado del historial para llenar una matriz de CRUD.

## Cómo leer la matriz

I = insertar; A = actualizar; E = eliminar; L = listar; B = buscar por criterio.

En SQL, `5 SP` significa que existen las cinco definiciones; no que cualquier cambio esté permitido.
En aplicación, `Sí` identifica una operación trazable en código; no significa nueva prueba aprobada hoy.
`Integrado` significa que se realiza desde otro expediente. `Parcial` identifica un alcance restringido.
`No` significa que no se encontró una ruta y control de interfaz para realizar esa operación.
La columna L/B distingue un selector de apoyo de una consulta de mantenimiento.

## Matriz de las 26 entidades

| # | Entidad | SQL | I en aplicación | A en aplicación | E en aplicación | L/B en aplicación y límite |
|---|---|---|---|---|---|---|
| 1 | Departamento | 5 SP | No | No | No | Listado en selectores; no mantenimiento ni búsqueda dedicada. |
| 2 | Municipio | 5 SP | No | No | No | Selector filtrado por departamento; no mantenimiento ni búsqueda dedicada. |
| 3 | TipoTelefono | 5 SP | No | No | No | Opciones de contacto; no mantenimiento ni búsqueda dedicada. |
| 4 | TipoDireccion | 5 SP | No | No | No | Opciones de contacto; no mantenimiento ni búsqueda dedicada. |
| 5 | TipoGarantia | 5 SP | No | No | No | Opciones en Vehículos; no mantenimiento ni búsqueda dedicada. |
| 6 | TipoReferencia | 5 SP | No | No | No | Opciones del vínculo de referencia; no mantenimiento ni búsqueda dedicada. |
| 7 | TipoPago | 5 SP | No | No | No | Opciones al registrar pagos; no mantenimiento ni búsqueda dedicada. |
| 8 | Marca | 5 SP | Sí | Sí | Sí, con dependencias protegidas | Ver todos y búsqueda; `index.html`, `/api/catalogos/marcas`. |
| 9 | Linea | 5 SP | Sí | Sí | Sí, con dependencias protegidas | Ver todos, criterio y filtro por marca; `lineas.html`, `/api/catalogos/lineas`. |
| 10 | Agencia | 5 SP | Sí | Sí | Sí, con dependencias protegidas | Ver todos y búsqueda; `agencias.html`, `/api/catalogos/agencias`. |
| 11 | Persona | 5 SP | Integrado en roles y referencias | Integrado; conserva identidad y reglas de otros roles | No hay eliminación de Persona desde la UI | Se leen personas para armar expedientes; no listado/búsqueda global que incluya personas sin rol visible. |
| 12 | Telefono | 5 SP | Integrado en expedientes | Integrado | Integrado: quitar contacto y guardar | Lista por persona; falta consulta global y búsqueda propia por número/tipo. |
| 13 | Direccion | 5 SP | Integrado en expedientes | Integrado | Integrado: quitar contacto y guardar | Lista por persona; falta consulta global y búsqueda propia por ubicación/detalle. |
| 14 | Deudor | 5 SP | Sí, con Persona | Sí, datos del expediente; no reasignación arbitraria de Persona | Sí, rol sin dependencias | Clientes: todos, identidad/nombre/correo/código; `/api/clientes`. |
| 15 | Referencia | 5 SP | Integrado en Clientes | Integrado en una referencia vinculada | No se elimina la ficha: quitar del expediente elimina el vínculo | Selector de referencias existentes y detalle por cliente; sin búsqueda global de fichas ni eliminación de referencias sin vínculos. |
| 16 | DetalleReferencia | 5 SP | Integrado: vincular | Integrado: tipo/relación | Integrado: desvincular | Vínculos por cliente; no consulta global dedicada con criterios propios. |
| 17 | Fiador | 5 SP | Sí | Sí, expediente/rol | Sí, rol sin créditos vinculados | Fiadores: todos y criterio de identidad/nombre/correo/código; `/api/fiadores`. |
| 18 | Vendedor | 5 SP | Sí | Sí | Sí, rol sin créditos vinculados | Vendedores: todos, criterio y agencia; `/api/vendedores`. |
| 19 | Garantia | 5 SP | Sí, vehículo nuevo | Sí, antes de historial contractual aprobado | Sí, sin créditos/valoraciones vinculados | Vehículos: todos, criterio y marca; `/api/vehiculos`. |
| 20 | ParametroCredito | 5 SP | No | No | No | Créditos lee solo configuración activa; no administración/listado completo/búsqueda. |
| 21 | Credito | 5 SP + Presentar/Aprobar/Anular | Sí, borrador | Sí, borrador; falta comisión específica en formulario/API | Borrador: físico; contrato: anulación protegida | Todos y criterio; detalle, plan y reportes; `/api/creditos`. |
| 22 | CreditoFiador | 5 SP | Integrado en borrador | Sustitución del conjunto mediante eliminar/insertar en transacción | Integrado en borrador | Selección/asignaciones por crédito; reporte 18 no equivale a listar todos los vínculos históricos y de borradores. |
| 23 | Depreciacion | 5 SP | Automático al aprobar; no alta manual posterior en UI | No | No | Vehículos cuenta valoraciones; reportes 16/17 usan la última al corte. No hay mantenimiento ni consulta completa del historial. |
| 24 | DetalleCuota | 5 SP | Automático al aprobar | No edición manual en UI | No eliminación manual en UI | Plan/cuotas por crédito y reportes; no mantenimiento global. SQL limita I/A/E manuales a borradores. |
| 25 | DetallePago | 5 SP + Anular | Sí, abonos por cuota | Solo observación | Anulación, no borrado físico | Todos, criterio, crédito y recibo; `/api/pagos`. El SP Eliminar también delega en anulación. |
| 26 | ResumenCredito | Listar/Buscar | Generado al aprobar | No, derivado contractual | No, derivado contractual | Totales mediante crédito/plan/reportes; no endpoint de mantenimiento independiente. |

La búsqueda en varios módulos se realiza en C# sobre filas recibidas por SP Listar.
No existe SQL directo por ello, pero no debe documentarse falsamente que esos recorridos llaman
al SP Buscar. Marcas, Líneas y Agencias sí seleccionan Listar/Buscar en sus repositorios.
Para nuevos mantenimientos, preferir explícitamente los SP existentes Listar y Buscar.

## Hallazgos y criterio de cierre

### C01 — Siete catálogos auxiliares sin mantenimiento completo

Departamento, Municipio, TipoTelefono, TipoDireccion, TipoGarantia, TipoReferencia y TipoPago.
Se consumen en `ClienteRepositorio.Catalogos`, `FiadorRepositorio.Catalogos`,
`VehiculoRepositorio.Catalogos` y `PagoRepositorio.Catalogos`, pero los controladores actuales
no exponen su alta, edición, eliminación o búsqueda de mantenimiento.

Cierre: cada catálogo permite I/A/E/L/B por API y UI usando SP con nombres permitidos y
parámetros tipados. Verificar claves compuestas de Municipio, descripciones inválidas, claves
duplicadas, inexistentes y rechazo de borrado con dependencias. TipoPago debe exponer y probar
`RequiereReferencia`; cambiarlo afecta las validaciones de futuros pagos.
No abrir una ruta que acepte nombres libres de tablas o procedimientos.

### C02 — Parámetros configurables solo en SQL

El formulario de Créditos muestra la configuración activa, pero no permite administrar
`ParametroCredito`. Los cinco SP ya existen. Debe distinguirse tasa porcentual visible de la
fracción almacenada (por ejemplo, 12.5% = 0.125), conservando precisión decimal.

Cierre: I/A/E/L/B de configuraciones, activación coherente y mensajes ante dependencias.
Cambiar la configuración para futuros créditos no debe reescribir contratos aprobados.
Antes de ofrecer cambio de configuración activa, verificar su restricción y diseñar una operación
atómica si hacen falta dos actualizaciones; no dejar una ventana sin configuración por un fallo.
No alterar SP ni contratos para resolverlo sin una revisión y prueba específica.

### C03 — Comisión específica por crédito no capturable

`Credito_Insertar` y `Credito_Actualizar` admiten `@PorcentajeComision` opcional.
`CreditoSolicitud` no contiene ese campo; `CreditoRepositorio.Guardar` no lo envía y
`creditos.js` solo lo muestra como parte de las condiciones. Por tanto, desde la aplicación
siempre se usa el valor predeterminado de la configuración.

El inciso D pide pactar un porcentaje específico por crédito. El cálculo sobre pagos efectivos
ya existe; el faltante es elegirlo desde la aplicación. No confundir esto con recalcular
comisiones de contratos aprobados ni con desembolsar comisiones al vendedor.

Cierre: permitir comisión válida en borradores, enviarla tipada al SP, mostrarla al reabrir y
conservarla al editar otros campos. Probar dos créditos con porcentajes distintos, pago y
anulación, y rechazo de modificación tras aprobar. Conservar el valor predeterminado como
ayuda inicial. En principio puede resolverse con el contrato SQL existente.

### C04 — Historial de valoraciones sin mantenimiento accesible

`VehiculoRepositorio.Listar` lee Depreciacion para contar registros. Aprobar crea la valoración
inicial; los reportes consultan la última al corte. No hay una ruta para registrar una valoración
posterior ni una pantalla con todo el historial y sus búsquedas.

Cierre: consultar historial por vehículo/fecha y registrar nuevas valoraciones. La edición y
eliminación deben respetar el bloqueo SQL cuando el vehículo tiene historial contractual.
Probar rechazo de fecha futura, restricciones de importe/porcentaje y conservación del historial.
Comprobar que cambia el reporte de garantía al corte correspondiente y no cambia la deuda.
No introducir depreciación periódica automática: no es un requisito definido.

### C05 — Cobertura parcial de personas, contactos y vínculos

No hace falta rehacer Clientes/Fiadores. Primero completar las consultas que permitan demostrar
listado y criterio para las entidades integradas, incluyendo filas no accesibles desde un rol.
Ejemplo concreto: quitar una referencia borra `DetalleReferencia`, no `Referencia` ni `Persona`.
Esto es correcto para no borrar datos compartidos, pero no cubre la eliminación controlada
de una ficha de referencia sin dependencias.

Cierre: matriz de casos por cada entidad integrada y consultas faltantes accesibles. Si se añade
eliminación de personas/referencias sin uso, debe ser explícita, confirmar dependencias y respetar
las FK. No introducir borrado en cascada ni limpieza automática de personas compartidas.
La sustitución de fiadores debe seguir siendo transaccional y limitada al borrador.

### C06 — Excepciones financieras al CRUD literal

No es un hallazgo de que los pagos deban borrarse: la aplicación ya anula preservando historial.
Cuotas y resumen se generan al aprobar. Los procedimientos manuales de DetalleCuota existen,
pero solo admiten borradores; no están expuestos como edición financiera desde la pantalla.

Cierre: documentar generación, lectura, actualización permitida y anulación por entidad,
probar los bloqueos y explicar al docente las excepciones. Las decisiones internas no acreditan
aceptación del docente. No añadir edición de totales derivados o cuotas aprobadas solo para
marcar cinco casillas como completas.

También siguen como interpretaciones a justificar: total neto recaudable sin enganche,
correlativo global de vehículo asociado a marca y alcance de intereses contractuales frente
a devengo contable. No se implementará contabilidad de devengo sin definir su regla.

### C07 — Veinte reportes integrados; cobertura visual todavía parcial

Las 20 definiciones tienen propósito y filtros y se invocan desde `ReportesController` y
`ReporteRepositorio`. El catálogo incluye los siete ejemplos del enunciado. Existe carta
individual imprimible; no requiere envío de correos para ese alcance.

Cierre pendiente: teclado, pantalla estrecha, cambios rápidos de filtros/respuestas tardías y
ajustes visuales registrados. La ampliación «Ver detalle» de Mora por rangos es una mejora
acordada, no un requisito literal adicional para alcanzar el mínimo de veinte consultas.

## Evidencia revisada y límites

Se contrastaron las definiciones finales `CREATE OR ALTER` del instalador del equipo con
`database/v2/entrega/inventario.json`, los doce controladores, repositorios, modelos de entrada
y archivos de interfaz. Se revisaron todas las construcciones de comandos SQL de la API:
usan `CommandType.StoredProcedure`. Los nombres dinámicos provienen de código interno,
no de un parámetro libre de tabla suministrado por el navegador. Esto es una revisión estática,
no prueba de todos los permisos o entradas posibles.

| Evidencia previa | Comprobaciones guardadas | Alcance |
|---|---:|---|
| fase-6-marcas.json | 28 | Marcas HTTP/SQL |
| fase-6-lineas.json | 42 | Líneas HTTP/SQL |
| fase-6-agencias.json | 34 | Agencias HTTP/SQL |
| fase-6-vendedores.json | 59 | Vendedores HTTP/SQL |
| fase-6-clientes.json | 62 | Clientes HTTP/SQL |
| fase-6-fiadores.json | 70 | Fiadores HTTP/SQL |
| fase-6-vehiculos.json | 80 | Vehículos HTTP/SQL |
| fase-6-creditos.json | 57 | Créditos HTTP/SQL |
| fase-6-pagos.json | 126 | Pagos HTTP/SQL |
| fase-6-reportes.json | 134 | Reportes HTTP/SQL |
| fase-6-reportes-formato.json | 15 | Formato, sin navegador |
| paquete-equipo.json | 60 | Ensayo de instalación y API en copia aislada |

Todas estas filas tienen resultados guardados correctos; no se ejecutaron de nuevo hoy.
No sumar regresiones repetidas como casos únicos. El archivo histórico
`fase-6-agencias-interfaz.json` indica Fallido y cero comprobaciones: no acredita validación
visual automática. La documentación posterior registra pruebas manuales por separado.
Reportes también conserva el límite del intento automático y el recorrido manual posterior.

La cuenta limitada probada en el entorno de Diego no es equivalente a la conexión de Windows
propietaria de LocalDB usada por Dylan. Su funcionamiento local no demuestra permisos mínimos
de producción. No se cambia aquí esa conexión ni se declara resuelto el control de acceso del
personal. Inicio de sesión, despliegue público y aplicación móvil adicional no son entregables
explícitos del PDF para esta aplicación web.

## Orden de trabajo propuesto a partir de la revisión

| Orden | Bloque | Cambio previsto | Impacto esperado en el equipo |
|---|---|---|---|
| 1 | Catálogos auxiliares (C01) | API, interfaz y pruebas; reutilizar SP existentes | Dylan conserva explicación SQL si no cambian definiciones; Josué añade pruebas/manual del módulo. |
| 2 | Parámetros y comisión (C02/C03) | API/UI; comprobar atomicidad y condiciones históricas | Documentar cualquier SP nuevo antes de integrarlo; repetir pruebas de créditos/pagos afectadas. |
| 3 | Valoraciones (C04) | API/UI e historial con bloqueos | Nuevas pruebas de cortes y manual; mantener reglas SQL actuales salvo cambio justificado. |
| 4 | Entidades integradas (C05/C06) | Consultas y operaciones controladas que falten; explicación de excepciones | Revisar solo las entidades afectadas, sin rehacer todos los expedientes. |
| 5 | Reportes y cierre (C07) | Ajustes visuales, mejora de mora, integración, documentación final | Actualizar capturas después de estabilizar las pantallas y ensayar la defensa. |

No se da por implementado ninguno de esos cambios con este informe.
La estimación anterior del 85% sigue siendo aproximada; esta matriz no convierte la presencia
de SP o el número de pantallas en un porcentaje exacto de aceptación académica.

## Registro para no desactualizar innecesariamente a Dylan y Josué

Para cada bloque implementado, registrar al terminar:

| Campo | Qué anotar |
|---|---|
| Versión base y final | Commits reales del bloque; no inventar el commit antes de crearlo. |
| Archivos cambiados | Rutas y propósito. |
| SQL | Objetos agregados/modificados/eliminados, o «sin cambios SQL». |
| Instalación | Migración concreta y orden, o «no requiere actualizar la base». |
| Documentación de Dylan | Secciones que necesitan revisión; lo demás sigue vigente. |
| Trabajo de Josué | Casos a repetir, nuevas capturas y cambios en el manual. |
| Evidencia | Qué se verificó realmente y qué quedó pendiente. |

Registro de esta revisión: base `cf6658a`; nuevos archivos de auditoría; sin cambios SQL ni
migración; no requiere actualizar bases ni detener tareas de compañeros. Esta documentación
es local hasta una publicación posterior autorizada. No se fusionan ni publican ramas aquí.

## Fuentes para reproducir la revisión

- [Inventario estático con líneas SQL, rutas y hashes](evidencias/cobertura-2026-10-14.json).
- [SQL del paquete revisado](../database/equipo/MAGISAUTO_Equipo_2026-10-13.sql).
- [Inventario SQL v2.1](../database/v2/entrega/inventario.json).
- [Controladores](../src/MAGISAUTO.API/Controllers), [repositorios](../src/MAGISAUTO.API/Datos),
  [modelos de entrada](../src/MAGISAUTO.API/Modelos) e [interfaz](../src/MAGISAUTO.API/wwwroot).
- [Decisiones e interpretaciones](DECISIONES_REVISION_PDF.md).
- [Avances por fase y actualizaciones históricas](INFORMES_POR_FASE.md).
- [Pruebas manuales de reportes](PRUEBAS_MANUALES_REPORTES_2026-10-13.md) y
  [pruebas manuales de pagos](PRUEBAS_MANUALES_PAGOS_2026-10-13.md).

Los hashes y líneas corresponden a la versión base revisada. Después de editar código deben
regenerarse o conservarse explícitamente como evidencia histórica; no representan una consulta
en tiempo real a las computadoras de los compañeros.
