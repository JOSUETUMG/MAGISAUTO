# Decisiones de la revisión del enunciado

Fecha: 11 de octubre de 2026. Aprobadas por Diego para continuar el proyecto en pruebas-diego.

Este documento fija las decisiones del equipo; no representa una aprobación del ingeniero. Complementa los documentos históricos de fases 2 a 6. Distingue las reglas ya implementadas en SQL de las pendientes del recorrido de solicitudes.

## Total neto recaudable

Se interpreta como el total contractual que se espera cobrar mediante las cuotas del financiamiento, una vez descontado el enganche del precio para obtener el capital financiado:

**Total neto recaudable = capital financiado + intereses del plan + manejo del plan + seguro de automóvil del plan + seguro de vida del plan.**

Equivale a sumar los totales de todas las cuotas. El enganche se muestra por separado y no se vuelve a sumar. Las comisiones se informan por separado: no reducen la obligación del cliente. Este total no es utilidad, saldo pendiente ni dinero ya cobrado. Los reportes deben distinguir el total contractual, los cobros efectivos y el saldo pendiente; una anulación conserva el resumen histórico y se identifica por el estado del crédito.

Ejemplo ilustrativo, no simulación de la tasa acordada: capital Q80,000, intereses totales Q20,000, manejo Q1,500 y seguros totales Q9,600 producen un total contractual de Q111,100. El enganche de Q20,000 permanece separado.

Estado: ya implementado por Credito_Aprobar, que guarda SUM(Interes) y SUM(Total) en ResumenCredito. Falta presentarlo con esta explicación en las pantallas y reportes de la aplicación.

## Eliminación y anulación

Se conserva la eliminación física de catálogos y borradores cuando no tienen dependencias. Los créditos aprobados y pagos registrados se anulan mediante los procedimientos existentes, con motivo, responsable declarado y fecha, conservando su historial. No se añaden borrados en cascada del historial financiero. El crédito no puede anularse mientras tenga pagos efectivos sin resolver; los reportes deben respetar las anulaciones.

ResumenCredito se genera al aprobar y se consulta, sin captura o modificación manual de sus totales.

Estado: política ya implementada en SQL; pendiente de exponer en los módulos financieros. El PDF solicita Insert/Update/Delete por entidad: la anulación y el resumen derivado son excepciones deliberadas que deben explicarse en la entrega. La decisión interna queda tomada; no se afirma que la interpretación literal del requisito esté validada por el docente.

## Código interno de vehículo

Se conserva CodigoGarantia, correlativo global existente, junto con CodigoMarca, CodigoLinea y el VIN único. No se añade otro correlativo por marca. En las pantallas se mostrarán código interno, marca, línea y VIN como datos distintos. Los saltos del correlativo no son errores ni representan vehículos faltantes.

Estado: implementado en el esquema. El texto «según la marca» se interpreta como identificación del vehículo asociada a su marca, sin reiniciar la numeración por marca. Si el docente exige expresamente una secuencia independiente, se revisará ese requisito; no se presenta esta lectura como confirmación del docente.

## Borrador y solicitud completa: tres referencias

Se permite guardar un expediente incompleto como borrador para completarlo por etapas. No se presenta como solicitud completa ni lista para evaluación hasta tener al menos tres referencias distintas del cliente y entre sí, con nombre completo, lugar de trabajo, relación, teléfono y dirección. Se permite registrar varios teléfonos y direcciones y distinguir sus tipos.

El paso de presentar la solicitud deberá validar estas condiciones en un procedimiento almacenado llamado por la API; la pantalla explicará qué datos faltan. La aprobación repetirá la validación por si el expediente cambió desde su presentación. No basta con deshabilitar un botón en el navegador.

Estado actual: SQL exige las tres referencias completas al aprobar. Todavía no existe un paso independiente de presentación de solicitud en la API o interfaz. Su validación previa queda como requisito pendiente del módulo de clientes/créditos; este acuerdo no cambia automáticamente el comportamiento de la base instalada ni agrega estados nuevos.

Casos de aceptación para ese módulo:

- Un borrador con dos referencias se guarda, pero no se presenta como solicitud completa.
- Repetir una referencia o usar al cliente como referencia no satisface el mínimo.
- Tres referencias con datos incompletos no permiten presentar la solicitud.
- Tres referencias distintas y completas satisfacen esta parte del expediente; las demás validaciones del crédito siguen siendo obligatorias.
- Si después se pierde una referencia obligatoria, la aprobación se bloquea hasta completar el expediente.

## Alcance de esta actualización

Se documentan decisiones y criterios de aceptación. No se modifican datos, procedimientos, el instalador SQL ni el estado de los créditos. El informe PDF de cierre de fase deberá incluir estas decisiones y distinguir los pendientes de implementación.
