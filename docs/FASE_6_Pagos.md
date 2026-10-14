# Fase 6 — Pagos y abonos

Implementación local del 13 de octubre de 2026, rama `pruebas-diego`. La fase 6 sigue abierta; esta entrega añade recaudación a los créditos aprobados y no implica publicación en GitHub.

## Qué permite hacer

- Registrar un abono parcial o el saldo completo de una cuota de un crédito vigente.
- Elegir el medio de pago, registrar la boleta/autorización cuando corresponde, indicar responsable y observación opcional.
- Revisar los datos en una confirmación antes de guardar. La fecha/hora de Guatemala y el recibo se asignan en SQL al registrar.
- Buscar por recibo, crédito, cliente, referencia bancaria, medio o estado y filtrar por crédito. Ver todos restablece el listado.
- Consultar el total del plan, pagos efectivos, saldo por cobrar y detalle de cada cuota (pendiente, parcial o pagada).
- Abrir e imprimir un comprobante académico con importe, cinco componentes, fecha/hora, medio, referencia, cliente y responsable. La impresión utiliza el navegador; no es una factura fiscal ni una integración de cobro bancario.
- Editar únicamente la observación del pago. Corregir importes requiere anular y registrar el pago correcto.
- Anular con motivo y responsable, conservando recibo e historial y restableciendo saldo. Un pago anulado deja de generar comisión efectiva.

El registro manual indica que ya se recibió dinero; no cobra tarjetas, no inicia transferencias ni verifica transacciones bancarias externas.

## Reglas que protege SQL

`DetallePago_Insertar` trabaja con una transacción y bloquea el crédito mientras comprueba el saldo y registra el importe. Dos operaciones concurrentes no pueden superar el saldo de la cuota.

Cada abono se reparte proporcionalmente entre capital, interés, manejo, seguro de automóvil y seguro de vida. El procedimiento resuelve los centavos restantes y exige que el desglose sume exactamente el monto recibido. Q25 de manejo pertenece a la cuota completa: no se agregan Q25 por cada abono.

Se rechazan importes no positivos, más de dos decimales desde la API, importes mayores al saldo, cuotas inexistentes, medios desconocidos, referencias bancarias obligatorias ausentes y créditos que no estén vigentes. La pantalla ayuda a evitar errores y SQL vuelve a comprobar las reglas.

Al completar todas las cuotas, el crédito pasa a `LIQUIDADO`. Al anular un pago de ese crédito, vuelve a `VIGENTE` si las reglas de la garantía lo permiten. La anulación se rechaza si el crédito está anulado o si reabrirlo entra en conflicto con otro crédito vigente del mismo vehículo. Una segunda anulación del mismo recibo se rechaza.

No se expone borrado físico de pagos desde la API. El procedimiento SQL `DetallePago_Eliminar` ya actúa como anulación; la pantalla usa explícitamente «Anular pago» para que el operador comprenda el resultado.

La comisión es el porcentaje guardado en el contrato aplicado al abono efectivo, redondeado a centavos. La suma de comisiones procede de los pagos individuales. No se añade al saldo del cliente ni acredita que se haya desembolsado al vendedor.

## Saldos y precisión

El repositorio consulta `Credito_Listar`, `DetalleCuota_Listar` y `DetallePago_Listar` dentro de una transacción de lectura serializable. Para cada cuota resta la suma de pagos no anulados a su total. No realiza consultas directas sobre tablas.

- `saldoPlan`: importe programado menos pagos efectivos; conserva el valor histórico aunque se anule el contrato.
- `saldoPorCobrar`: saldo actual del contrato vigente. Es cero para un crédito anulado o liquidado; no presenta el plan anulado como deuda cobrable.
- `permitePago`: únicamente cuotas con saldo positivo de un crédito vigente.

Estos son saldos actuales, no estados de cuenta a una fecha de corte ni informes de mora. Esas consultas pertenecen al módulo de reportes pendiente.

Los decimales y los identificadores `bigint` se devuelven como texto JSON para evitar pérdida de centavos o números de recibo en JavaScript. El navegador compara importes utilizando centavos enteros y muestra el desglose calculado por SQL.

## Archivos agregados y modificados

| Archivo | Responsabilidad |
|---|---|
| `src/MAGISAUTO.API/Modelos/PagoSolicitud.cs` | Valida importe, cuota, medio, textos y responsables. Contiene también los contratos de observación y anulación. |
| `src/MAGISAUTO.API/Datos/PagoRepositorio.cs` | Consulta pagos/saldos, enriquece nombres y medios, llama a los procedimientos de escritura con parámetros tipados y traduce errores. |
| `src/MAGISAUTO.API/Controllers/PagosController.cs` | Expone las operaciones HTTP del módulo. |
| `src/MAGISAUTO.API/Program.cs` | Registra el repositorio de pagos. |
| `src/MAGISAUTO.API/wwwroot/pagos.html`, `.js`, `.css` | Listado, saldos, captura, confirmación, comprobante, impresión y anulación. |
| Páginas de los módulos existentes | Añaden el enlace a Pagos y abonos. |
| `scripts/Verificar-Pagos.ps1` | Prueba el recorrido con datos propios en la base aislada y retira únicamente esos registros. |

No se modificaron el esquema ni los procedimientos SQL para este módulo. Se reutiliza la revisión 2.1 que ya incorpora la presentación de créditos. No hay otro parche SQL que instalar para habilitar Pagos.

## Rutas de la API

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/pagos?criterio=...&numeroCredito=...` | Listado y búsqueda, con filtro opcional por crédito. |
| GET | `/api/pagos/catalogos` | Medios de pago y créditos con su estado. |
| GET | `/api/pagos/credito/{numero}` | Plan y saldos actuales de las cuotas. |
| GET | `/api/pagos/{codigo}` | Comprobante y desglose. |
| POST | `/api/pagos` | Registra pago; responde 201 con el recibo y su desglose. |
| PUT | `/api/pagos/{codigo}/observacion` | Corrige la observación; responde 204. |
| POST | `/api/pagos/{codigo}/anular` | Anula con responsable y motivo; responde 204. |

Ejemplo de pago (solo cuando se esté realizando la prueba manual acordada):

```json
{
  "numeroCredito": "PRUEBA-CREDITO-01",
  "cuota": 1,
  "monto": "1000.00",
  "codigoTipoPago": 5,
  "responsable": "Diego - prueba académica",
  "observacion": "Abono ficticio para validar el proyecto"
}
```

El formulario obtiene los códigos del catálogo; no supone que todos los entornos tengan las mismas descripciones. No acepta desgloses, recibos ni fechas proporcionadas por el navegador como valores de escritura. Las reglas SQL asignan esos campos.

## Pruebas manuales realizadas con Diego

El 13 de octubre de 2026 Diego realizó el recorrido en `MAGISAUTO_Proyecto_V2`. El [informe completo](PRUEBAS_MANUALES_PAGOS_2026-10-13.md) conserva los 15 casos, 16 capturas originales, confirmaciones textuales, desglose de cada recibo, conciliación y pendientes. No se repitieron las operaciones para redactarlo.

Se comprobaron consulta inicial, abono de Q1000, consulta posterior a la indicación de recarga, rechazo de un centavo de sobrepago, completar la cuota con Q6311.63, edición de observación, anulación con restauración de saldos, referencia ACH obligatoria, abono ACH de Q500 con referencia, búsqueda, Ver todos y vista previa de impresión de una página.

Estado final observado: `PRUEBA-CREDITO-01` VIGENTE; recibos 1 y 3 efectivos y recibo 2 anulado; Q1500 pagados, Q5811.63 de saldo en cuota 1 PARCIAL, Q86239.56 por cobrar y Q30 de comisión efectiva. No se borró físicamente el historial. Las pruebas automáticas siguen usando datos propios en otra base.

## Verificación realizada

- Compilación .NET sin errores ni advertencias y sintaxis JavaScript válida. Referencias de controles HTML/JS y enlaces de navegación comprobados.
- **126 comprobaciones HTTP/SQL correctas**. Evidencia: [fase-6-pagos.json](evidencias/fase-6-pagos.json).
- Se usó la misma cuenta limitada de la API en `MAGISAUTO_ValidacionV2`; se verificó que no puede consultar directamente las tablas. La preparación y limpieza administrativa se restringen a registros ficticios propios en esa base.
- Se probaron restricciones HTTP/SQL, cuota/crédito inexistentes, rechazo de pagos en borradores, liquidado y anulado, sobrepagos, los cinco medios, referencias obligatorias, reparto de Q0.01, abonos sucesivos, recibos distintos, precisión y comisión efectiva.
- Se comprobó que enviar capital, fecha o comprobante desde el cuerpo HTTP no sustituye los valores generados por SQL. Editar observación conserva las condiciones financieras.
- Dos peticiones HTTP simultáneas intentando pagar el saldo completo de una cuota produjeron un pago aceptado y otro rechazado, sin saldo negativo.
- Se liquidaron las doce cuotas del contrato ficticio. Anular un abono de Q1000 reabrió el contrato, restableció exactamente ese saldo y conservó recibo, importe, fecha, motivo y responsable de la anulación.
- La comparación anterior/posterior de registros de 15 tablas de validación confirmó que los datos previos quedaron intactos tras retirar el ensayo. Avanzar identidades y la secuencia de recibos es normal. No se ejecutaron pagos sobre `PRUEBA-CREDITO-01` del proyecto.

Para repetir: compilar la API en `src/MAGISAUTO.API/bin/Pagos` y ejecutar en PowerShell 7 `scripts/Verificar-Pagos.ps1 -Credencial <ruta-a-credencial-local>`. Requiere los procedimientos de Créditos 2.1 y permiso administrativo exclusivamente en la base aislada.

**Condición del entorno de ensayo:** el proceso .NET restringido no pudo negociar TLS en Windows (error de credenciales del paquete de seguridad). Se ejecutó el ensayo con `-ConexionLocalSinCifrado`, una opción explícita que solo acepta `tcp:127.0.0.1,1433` y `MAGISAUTO_ValidacionV2`. La opción cambia únicamente la conexión temporal del servidor de prueba y restaura las variables del proceso al iniciarlo. No modifica `appsettings.Local.json`, la conexión del proyecto ni la configuración del servidor SQL. La evidencia registra este modo; no acredita una prueba TLS del módulo.

La pantalla y la vista previa de impresión fueron revisadas manualmente con Diego: ver el informe enlazado. Esta evidencia es independiente de las comprobaciones HTTP/SQL; no acredita impresión física ni guardado de un PDF.

## Límites que deben explicarse

- El recorrido visual principal y la vista previa están documentados. No cubren todos los casos automáticos ni todos los tamaños de pantalla. En el historial algunos importes se parten en dos líneas: mejora visual pendiente.
- Responsables escritos, sin autenticación del personal todavía. No hay integración con bancos o pasarela.
- Sin paginación ni cortes históricos desde esta pantalla. El comprobante consulta el nombre actual del cliente; sus importes y datos financieros proceden del registro de pago.
- No hay reintento automático ni una clave de idempotencia de pagos. Si se pierde la respuesta de una escritura, la pantalla advierte que hay que revisar el historial antes de repetirla; no afirma que el pago falló.
- El operador no cambia la fecha de procesamiento, el reparto o el número de recibo. Los números pueden tener saltos por transacciones fallidas; la unicidad no exige una secuencia sin huecos.
- Reportes, configuración pendiente y revisión del resto de entidades siguen abiertos. El PDF integral de fase 6 se prepara al cerrar la fase.
