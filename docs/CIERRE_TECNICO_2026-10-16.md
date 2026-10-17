# Correcciones posteriores a la auditoría del PDF

Fecha: 16 de octubre de 2026. Cambios locales sobre `pruebas-diego`, base Git `5d57fa3e47d8b06dd40d5e46aad76c3fd687c8aa`. La publicación se verifica por el hash del commit en la rama remota; este documento registra el contenido y sus comprobaciones.

## Qué se implementó

1. Personas, teléfonos, direcciones y referencias tienen alta, edición y eliminación independientes en **Personas y vínculos**, incluso sin expediente. Se reutilizan los SP existentes. Los catálogos se seleccionan por nombre y el municipio depende del departamento. Se advierte que los datos son compartidos.
2. El servidor conserva claves, DPI existente y persona de cada referencia. Verifica longitudes, fechas, correo, importes y datos obligatorios; las FK conservan las dependencias. La edición compara la versión original bajo transacción para rechazar cambios obsoletos. No permite seleccionar procedimientos arbitrarios.
3. **Cuotas** y **Resúmenes de créditos** se agregan a las consultas globales: ocho consultas en total. Hay listado y búsqueda. Desde Créditos se accede directamente a Cuotas y resúmenes.
4. Las cuotas de **borradores** admiten alta, edición y borrado de simulaciones. El resumen puede crearse, recalcularse o retirarse en borradores; sus importes se calculan desde las cuotas y los cargos del crédito, nunca se escriben a mano. Modificar cuotas o condiciones mantiene coherente el resumen existente.
5. Aprobar reemplaza las cuotas y resumen de simulación por el plan contractual calculado. Los contratos aprobados siguen protegidos. Para eliminar un borrador con detalles, retirar antes su simulación y sus dependencias.
6. El reporte 10 distingue contrato, devengo, cobro, pendiente y anticipos mediante un criterio académico mensual autorizado por Diego al pedir la opción más conveniente y viable.
7. Los formularios nuevos tienen Cancelar/cerrar y cierre superior, bloqueados durante guardado junto con los campos. Los reportes usan página A4 horizontal al imprimir y la carta A4 vertical; las vistas previas de la carta y del reporte 17 fueron comprobadas por Diego tras los ajustes finales.

## Regla de devengo para explicar en la defensa

El interés mensual de una cuota se reconoce completo cuando `FechaVencimiento <= FechaCorte`. No se prorratea diariamente ni se presenta como normativa contable externa. No incluye manejo ni seguros. Los movimientos se consideran hasta terminar el día de corte y las anulaciones en su fecha, usando el historial existente.

| Columna del reporte 10 | Significado |
|---|---|
| InteresesDelContrato | Suma contractual de intereses del plan. |
| InteresesCobrados | Intereses de pagos efectivos al corte, incluidos anticipos. |
| InteresesPendientes | Interés contractual menos cobrado al corte. |
| InteresesDevengados | Interés de cuotas con vencimiento hasta el corte inclusive. |
| DevengadosPorCobrar | Interés pendiente únicamente de cuotas ya vencidas al corte. |
| InteresesPorDevengar | Interés contractual de cuotas que vencen después del corte. |
| InteresesCobradosAnticipados | Interés cobrado de cuotas cuyo vencimiento es posterior al corte. |

Se cumple `Contrato = Devengado + PorDevengar` y `Contrato = Cobrado + Pendiente`. No restar indiscriminadamente todos los cobros del devengo: puede haber anticipos. Una anulación revierte el cobro, no cambia el calendario de reconocimiento del interés.

## Cambios SQL y aplicación

La [migración 002](../database/v2/migraciones/002_Cierre_Tecnico.sql) se ejecuta completa sobre la base elegida; no incluye `USE`. Requiere el modelo V2 y la migración 001 ya instalada (la copia del equipo ya la incluye). Es repetible, transaccional y no modifica tablas ni filas al instalarla.

- Nuevos: `ResumenCredito_Insertar`, `ResumenCredito_Actualizar`, `ResumenCredito_Eliminar`. Solo reciben el crédito; calculan importes, y solo operan sobre borradores.
- Actualizados: `DetalleCuota_Insertar/Actualizar/Eliminar`, `Credito_Actualizar`, `Credito_Aprobar`, `Reporte10_Intereses`.
- Resultado: 26 tablas, **154 procedimientos API**, cuatro vistas y dos funciones. No son 151 procedimientos en una base ya actualizada.
- API nueva: `api/mantenimiento-personas/{entidad}` obtiene el formulario; `POST .../{crear|editar|eliminar}` procesa campos permitidos y versión original. También cubre cuotas/resúmenes, con las restricciones SQL indicadas.
- Archivo auxiliar local: [Aplicar-CierreTecnico.ps1](../scripts/Aplicar-CierreTecnico.ps1) respalda los nueve procedimientos afectados y compara huellas de las 26 tablas dentro de una transacción externa antes de confirmar. Los respaldos quedan en `artifacts/`, no en Git.

La copia `MAGISAUTO_Equipo_2026-10-13.sql` conserva su contenido y huella histórica. Los compañeros deben aplicar 002 a su propia copia y actualizar el código conjuntamente. No deben reinstalar ni borrar su base.

## Evidencias y límites

Resultados nuevos en [evidencias/cierre-tecnico-2026-10-16](evidencias/cierre-tecnico-2026-10-16/). Las suites de escritura usan `MAGISAUTO_ValidacionV2` y retiran solo sus datos temporales. La suite específica compara las 26 tablas antes y después.

| Ensayo | Comprobaciones correctas |
|---|---:|
| Cierre técnico: mantenimiento, simulaciones, bloqueos, cortes y detección de base sin actualizar | 61 |
| Créditos, incluyendo reemplazo de simulación al aprobar | 59 |
| Veinte reportes y devengo con pagos anulados | 140 |
| Ocho consultas globales y eliminaciones protegidas | 106 |
| Pagos y abonos | 126 |
| Bloqueos SQL de cuotas/resúmenes aprobados | 12 |
| **Total HTTP/SQL de esta revisión** | **504** |

No sumar los 1,205 ensayos de la auditoría anterior como si todos fueran escenarios nuevos. Se amplían y repiten únicamente suites relacionadas con estos cambios. Las comprobaciones DOM y de formato se registran separadas en sus JSON; no son impresión real.

Compilación final: cero errores y advertencias. Ensayos adicionales: **201 DOM de diseño/reportes, 30 DOM del mantenimiento y 15 de formato monetario**. El ensayo DOM de mantenimiento no escribe datos. El cierre técnico comprueba el aviso de migración pendiente sustituyendo temporalmente el reporte 10 solo en la base aislada y restaurándolo en `finally`.

### Confirmaciones manuales posteriores (16 de octubre)

- **Migración principal:** Diego ejecutó 002 desde SSMS. Su captura muestra `MAGISAUTO_Proyecto_V2` y `Cierre técnico instalado`. Sustituye el bloqueo previo de la cuenta limitada; no se ampliaron sus permisos. Esta confirmación procede de la captura del usuario, no de un nuevo inventario SQL automático sobre la principal.
- **Reporte 10:** captura al corte 16/10/2026 para PRUEBA-CREDITO-01: contrato Q5,519.56, cobrado Q170.96, pendiente Q5,348.60, devengado Q0.00, devengado por cobrar Q0.00, por devengar Q5,519.56 y cobrado anticipado Q170.96. Coherente con el primer vencimiento 12/11/2026 y el criterio mensual.
- **Carta:** captura final de vista previa con texto completo, arriba y en una sola página. No acredita salida física en papel ni envío por correo.
- **Reporte 17:** captura inicial con todas las columnas. Tras ajustar encabezados sin partir palabras y ocultar la instrucción de desplazamiento al imprimir, Diego confirmó que también pasó. Esta última confirmación es textual; no se recibió otra captura del reporte ajustado.
- El fallo previo `ERR_CONNECTION_TIMED_OUT` del navegador integrado queda como limitación histórica, superada para estas comprobaciones mediante evidencia del navegador de Diego. No se extrapola a todas las impresoras ni a todos los reportes.

Registro estructurado: [confirmaciones manuales](evidencias/cierre-tecnico-2026-10-16/confirmaciones-manuales.json). Las capturas originales se compartieron en el chat; este registro no las incorpora como archivos publicados.

## Qué debe actualizar cada compañero

**Dylan:** aplicar 002 a su copia, documentar los tres SP nuevos, los seis modificados, el total 154, la regla de devengo y la diferencia entre simulación y contrato aprobado. No cambia el diagrama de tablas. La regla de devengo es un acuerdo académico explícito.

**Josué:** capturar el diseño actual de Personas y vínculos → Agregar/Editar/Eliminar; los selectores de contactos; Cuotas y Resúmenes en borrador; protección de aprobados; reporte 10 y sus notas; Cancelar/cerrar. Las capturas antiguas siguen sirviendo como evidencia histórica, pero no muestran estos recorridos.

## Interpretaciones que se conservan y estado de instalación

- El código de vehículo sigue siendo único global, relacionado con su marca y línea. No se inventa un contador por marca que el PDF no define expresamente. No afirmar aceptación del docente que no se tiene.
- Un borrador incompleto es preparación; presentar y aprobar exige tres referencias completas. No se aprueba un expediente incompleto.
- Los pagos se anulan y los contratos aprobados conservan historial. Cubrir CRUD en estados válidos no significa permitir modificar cualquier fila en cualquier estado. Esta distinción debe explicarse al docente; no se certifica su aceptación académica.
- Base aislada actualizada y ensayada. Migración principal confirmada por Diego en SSMS, y reporte 10 comprobado en la aplicación; ver evidencia manual anterior.
- Manuales finales de compañeros y paquete de entrega todavía no revisados en este cierre. No se declara aceptación académica del docente.

## Coordinación para la entrega

- **Josué:** manual de usuario, capturas actuales y evidencia de los recorridos y pruebas que documenta. Incluir navegación, formularios, validaciones, cancelación, bloqueos por dependencias, reportes e impresión. Actualizar su código y aplicar 002 en su copia antes de tomar las capturas nuevas. No se encontró otra responsabilidad de entrega asignada a él en los documentos revisados.
- **Dylan:** documentación técnica de la base y procedimientos, incluyendo los cambios de 002 y la regla de devengo.
- **Pendiente del equipo:** recibir y revisar ambos documentos, y comprobar el paquete final contra el PDF. Publicar código no sustituye esa revisión.

## Revisión previa a publicación

Compilación repetida: cero errores y advertencias; sintaxis JavaScript y revisión de espacios Git correctas. La repetición adicional de MantenimientoDOM agotó la espera al no estar disponible el servidor de pruebas. Su arranque posterior fue rechazado por la política de aprobación de esta sesión. No se registra una nueva aprobación DOM: las 30 comprobaciones citadas corresponden al ensayo anterior conservado.
