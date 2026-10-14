# Pagos y abonos: registro de pruebas manuales

Fecha de las operaciones: **13 de octubre de 2026**, hora de Guatemala. Operador: Diego. Rama de trabajo: **pruebas-diego**. Aplicación local: `http://localhost:5164/pagos.html`, base del proyecto `MAGISAUTO_Proyecto_V2`.

Este informe documenta el recorrido realizado por Diego y revisado mediante las capturas del chat. No constituye una nueva ejecución de esos pagos. Las capturas se conservan en [evidencias/pagos-manual-2026-10-13](evidencias/pagos-manual-2026-10-13/). Los identificadores de evidencia de las tablas corresponden a los nombres de archivo de esa carpeta.

La fase 6 continúa abierta. Este es un informe de avance; el PDF acumulado de cierre sigue pendiente hasta completar la fase. La implementación, API, reglas SQL y limitaciones técnicas se explican en [FASE_6_Pagos.md](FASE_6_Pagos.md).

## 1. Preparación y condiciones iniciales

Se indicó reiniciar el proyecto en Visual Studio, abrir Pagos y abonos y seleccionar el crédito. La captura acredita la página funcionando; no muestra el acto de reiniciar Visual Studio.

| Dato | Condición del ensayo |
|---|---|
| Crédito | PRUEBA-CREDITO-01, VIGENTE |
| Cliente | Cliente Editado Prueba |
| Precio al contado / enganche | Q100,000.00 / Q20,000.00, según el crédito aprobado anteriormente |
| Capital financiado | Q80,000.00 |
| Plan | 12 cuotas de Q7,311.63; total Q87,739.56 |
| Cuota usada | 1, vencimiento 2026-11-12 |
| Estado inicial | Sin pagos; cuota 1 PENDIENTE, saldo Q7,311.63 |
| Saldo inicial del crédito | Q87,739.56 |
| Comisión efectiva inicial | Q0.00; porcentaje guardado en el crédito: 2% |

La primera captura muestra el resumen y las primeras cuotas; no muestra las doce filas completas. El plazo de doce meses ya estaba documentado en las pruebas de Créditos. El total del plan excluye el enganche y no equivale al dinero cobrado.

## 2. Registro completo del recorrido

| Caso | Acción y datos | Resultado observado | Evidencia |
|---|---|---|---|
| M01. Consulta inicial | Seleccionar PRUEBA-CREDITO-01. | Historial vacío, 0 pagos, VIGENTE, saldo Q87,739.56; cuota 1 PENDIENTE con Q7,311.63. | 01-inicio.png |
| M02. Primer abono | Cuota 1, Q1,000.00, Efectivo en ventanilla, responsable Diego prueba, observación «Primer abono de prueba». Revisar y confirmar. | Recibo 1, pago efectivo, 19:31:48, monto Q1,000.00, comisión Q20.00, referencia no indicada permitida para efectivo. | 02-recibo-1.png |
| M03. Persistencia y consulta | Se pidió cerrar, recargar con F5 y seleccionar nuevamente el crédito. | La siguiente captura muestra 1 pago en el historial con «Todos los créditos»; al seleccionar el crédito se ven cuota 1 PARCIAL, pagado Q1,000.00, saldo de cuota Q6,311.63, saldo del crédito Q86,739.56 y comisión Q20.00. La captura no registra la pulsación de F5, pero sí el registro visible después de la instrucción. | 03-historial-1.png y 04-saldos-abono.png |
| M04. Rechazo de sobrepago | Intentar Q6,311.64 cuando restan Q6,311.63 en la cuota 1. | El formulario mantiene el importe y muestra «El monto debe ser positivo y no superar el saldo de la cuota». No permite pasar a revisar. El historial posterior contiene los recibos válidos; este intento no produjo un recibo visible. Esto acredita la validación de interfaz; la protección HTTP/SQL se probó por separado. | 05-sobrepago.png |
| M05. Completar cuota | Se indicó «Usar saldo completo», conservar Efectivo en ventanilla, responsable Diego prueba y observación «Completo de cuota 1», revisar y confirmar Q6,311.63. | Recibo 2 efectivo, 19:43:03, importe Q6,311.63 y comisión Q126.23. La captura confirma el importe final; no registra el clic del botón de autocompletar. | 06-recibo-2.png |
| M06. Dos abonos en una cuota | Cerrar el comprobante y consultar historial y cuotas. | 2 recibos efectivos para la cuota 1; pagado Q7,311.63, saldo Q0.00 y estado PAGADA. Crédito VIGENTE, saldo por cobrar Q80,427.93 y comisión acumulada Q146.23. Las siguientes cuotas visibles siguen pendientes. | 07-historial-2.png y 08-cuota-pagada.png |
| M07. Editar observación | En recibo 2, guardar «Cuota 1 completada — observación corregida» y abrir el comprobante. | Texto corregido; se conservan número, crédito, cuota, fecha original, medio, Q6,311.63, desglose y comisión Q126.23. No se aportó una captura separada de saldos inmediatamente después de editar. | 09-observacion.png |
| M08. Anular pago | Anular recibo 2, responsable Diego prueba, motivo «Prueba de anulación de pago». | ANULADO · No reduce el saldo. Conserva monto y desglose originales, observación corregida, fecha original y registra anulación 19:45:56, actor y motivo. Su comisión efectiva cambia a Q0.00. | 10-recibo-anulado.png |
| M09. Restaurar saldos | Cerrar recibo anulado y consultar cuotas. | Cuota 1 vuelve a PARCIAL, pagado Q1,000.00, saldo Q6,311.63. Crédito VIGENTE, saldo Q86,739.56, comisión acumulada Q20.00. | 11-saldos-anulacion.png |
| M10. Referencia obligatoria | Capturar Q500.00 para cuota 1, Transferencia ACH, observación «pago con transferencia», responsable Diego prueba; dejar referencia vacía e intentar revisar. | Campo obligatorio marcado y aviso nativo «Completa este campo». No permite continuar. Esto prueba obligatoriedad en navegador, no verificación de una transferencia real. | 12-referencia-obligatoria.png |
| M11. Transferencia con referencia | Completar PRUEBA-ACH-001, revisar y confirmar los Q500.00. | Recibo 3 efectivo, 19:47:59, medio Transferencia ACH, referencia PRUEBA-ACH-001, observación guardada, monto Q500.00 y comisión Q10.00. | 13-recibo-3.png |
| M12. Saldos después de transferencia | Cerrar recibo y revisar tabla. | Pagos efectivos Q1,500.00, cuota 1 PARCIAL con saldo Q5,811.63, saldo del crédito Q86,239.56 y comisión efectiva acumulada Q30.00. | 14-saldos-transferencia.png |
| M13. Buscar referencia | Buscar PRUEBA-ACH-001 con el crédito seleccionado. | 1 coincidencia: recibo 3, cuota 1, Q500.00, Transferencia ACH, EFECTIVO. | 15-busqueda.png |
| M14. Ver todos | Pulsar Ver todos. | Diego confirmó en texto «si aparecen todos» tras indicarle esperar recibos 1 y 3 efectivos y recibo 2 anulado. No hay captura adicional de ese listado completo. | Confirmación textual del chat |
| M15. Vista previa de impresión | Abrir recibo 3 y pulsar Imprimir; destino Guardar como PDF. | Una página; recibo, cliente, crédito, cuota, fecha/hora, medio, referencia, responsable, observación, cinco componentes y Q500.00 completos. Sin menú, botones ni tablas del fondo dentro del área impresa. Encabezado/pie del navegador visibles. | 16-impresion.png |

## 3. Conciliación de los recibos

Todos los importes de esta sección están en quetzales. El desglose original del recibo anulado se conserva como historia y no se suma a los pagos efectivos.

| Concepto | Recibo 1 | Recibo 2 (después anulado) | Recibo 3 |
|---|---:|---:|---:|
| Capital | 860.73 | 5,432.57 | 430.36 |
| Interés | 113.97 | 719.36 | 56.99 |
| Manejo de cuenta | 3.42 | 21.58 | 1.71 |
| Seguro de automóvil | 16.41 | 103.59 | 8.21 |
| Seguro de vida | 5.47 | 34.53 | 2.73 |
| **Monto original** | **1,000.00** | **6,311.63** | **500.00** |
| Comisión al registrarse | 20.00 | 126.23 | 10.00 |
| Comisión efectiva al final | 20.00 | 0.00 | 10.00 |
| Estado final | EFECTIVO | ANULADO | EFECTIVO |

Comprobaciones aritméticas:

- Cada columna de cinco componentes suma el monto original de su recibo.
- Antes de anular, recibos 1 + 2 completaron exactamente Q7,311.63: capital Q6,293.30, interés Q833.33, manejo Q25.00, seguro auto Q120.00 y vida Q40.00. No se cobró Q25 de manejo por cada abono.
- Tras anular el recibo 2, solo el recibo 1 reducía el saldo: Q87,739.56 − Q1,000.00 = Q86,739.56.
- Al registrar el recibo 3, pagos efectivos = Q1,000.00 + Q500.00 = Q1,500.00; saldo cuota 1 = Q7,311.63 − Q1,500.00 = Q5,811.63; saldo del crédito = Q87,739.56 − Q1,500.00 = Q86,239.56.
- Comisión final = Q20.00 + Q0.00 + Q10.00 = Q30.00. La comisión anulada no reduce el saldo del cliente ni representa un desembolso al vendedor.

## 4. Estado que se conserva para continuar

No se eliminaron físicamente los recibos de estas pruebas. Los tres pertenecen a la cuota 1 de PRUEBA-CREDITO-01 y permanecen en el historial. El recibo 2 está anulado; los recibos 1 y 3 son efectivos. El crédito sigue VIGENTE, con Q86,239.56 por cobrar y cuota 1 PARCIAL. Este estado corresponde a la última captura, no a una consulta posterior en vivo de SQL.

No volver a ejecutar estos pasos desde el inicio suponiendo que el crédito está sin pagos: primero revisar su estado actual. Los números de recibo son asignados por SQL y no deben forzarse ni suponerse iguales en otra base.

## 5. Qué se verificó y qué no

**Comprobado manualmente:** las operaciones M01–M15 con los matices de evidencia indicados. «Ver todos» cuenta con confirmación textual; impresión cuenta con vista previa, no con un PDF guardado ni impresión física. No se demuestra en esta prueba el procesamiento de dinero en un banco: se registraron datos ficticios recibidos por la aplicación.

**Comprobado automáticamente antes de este recorrido:** 126 comprobaciones HTTP/SQL en MAGISAUTO_ValidacionV2, documentadas en [fase-6-pagos.json](evidencias/fase-6-pagos.json). Incluyen concurrencia, los cinco medios, centavos, liquidación completa, reapertura por anulación y conservación de registros previos. No son 126 pruebas nuevas por actualizar este informe. El ensayo aislado empleó la opción local sin TLS por la limitación del entorno, sin cambiar la conexión privada del proyecto.

**No probado manualmente aquí:** liquidación de las doce cuotas y reapertura de un crédito liquidado, dos operadores simultáneos, todos los medios distintos de efectivo/ACH, cancelar confirmaciones, doble anulación, error de red tras guardar, búsqueda por cada uno de los demás campos y los casos restantes de protección HTTP/SQL. Mantienen el alcance automático que corresponda, sin atribuirles capturas inexistentes.

**Observación visual pendiente:** en las capturas del historial, el ancho de la columna Monto parte algunos importes en dos líneas (por ejemplo Q500.00). Los comprobantes y la tabla de cuotas muestran los importes completos. Es una mejora de presentación pendiente; en este trabajo de documentación no se modificó la interfaz ni se ocultó esta observación.

**Pendientes del proyecto:** módulo de consultas y reportes en la aplicación, configuración y comisión negociada por crédito según alcance pendiente, auditoría completa de entidades/requisitos y PDF de cierre de fase 6. Los 20 reportes SQL existentes deben integrarse y explicarse; no se declaran disponibles en una pantalla todavía.

## 6. Aclaración del ingeniero y siguiente trabajo

En la captura compartida por Diego, el ingeniero enfatiza usar SP para todo el trabajo SQL y disponer de un módulo de consultas con la mayor cantidad de consultas que puedan crear. Esto refuerza la prioridad de consultas/reportes después de Pagos; no confirma las interpretaciones pendientes sobre total neto recaudable, código de vehículo o excepciones de borrado financiero.

No se fija un número adicional de consultas a partir de ese mensaje. Se mantiene el requisito documentado de 20 reportes del enunciado y la revisión de su utilidad. El siguiente trabajo será integrar consultas a través de procedimientos almacenados, con filtros, resultados y explicación de cada reporte.

## 7. Publicación y entrega

Este informe y sus capturas se preparan para publicarse junto con los cambios acumulados de la fase 6 en **pruebas-diego**. El resultado de publicación se acredita con el identificador del commit y la comprobación de la referencia remota; preparar el documento o crear un commit local no demuestra un push exitoso.

Git comparte código, scripts y evidencia documental. No contiene la base instalada, sus registros de negocio ni credenciales. El equipo debe seguir el README para preparar su propia conexión y base. La base de Diego conserva los pagos manuales descritos, sin que publicarlos como evidencia inserte pagos en otras máquinas.
