# CRUD de entrega: valoraciones previas y pagos anulados

## Referencia al enunciado

El PDF pide insertar, actualizar, borrar, listar y buscar por entidad; las operaciones de aplicación deben pasar por API y procedimientos almacenados. Se completan dos recorridos; se mantienen las restricciones de dependencias y estados válidos.

## Cambios

- Valoraciones: registrar antes de aprobar un crédito, consultar, buscar, editar y borrar. Al existir historial aprobado del vehículo, las valoraciones permanecen protegidas. Se pueden agregar seguimientos. La aprobación sigue generando su valoración contractual. No se puede trasladar una valoración existente a otro vehículo.
- Pagos: conservar Anular y agregar Eliminar definitivamente solo para un registro ya anulado. Un pago efectivo devuelve conflicto (409); un registro inexistente devuelve 404. El borrado es físico. La confirmación explica que desaparece también de recibos y reportes de cortes anteriores a la anulación. No altera saldos ni comisión efectiva actuales, porque el pago ya estaba anulado; sí altera la evidencia histórica.
- PUT de pagos continúa limitado a observación. Corregir importes o medio requiere anular y registrar otro pago. No se ofrece edición arbitraria de contratos aprobados.
- El endpoint DELETE /api/pagos/{codigo} llama a api.DetallePago_Eliminar. No hay SQL de negocio directo desde la interfaz. Este procedimiento ya no es un alias de Anular; los clientes deben usar la operación Anular explícita.

## Pruebas y estado

75 comprobaciones HTTP/SQL correctas en MAGISAUTO_ValidacionV2, con TLS activado. Incluyen el ciclo de crédito, CRUD de valoración previa, protección contractual, bloqueo de eliminación de pago efectivo, borrado físico del anulado, segundo borrado 404 y conservación de saldo/comisión. Los registros previos del ensayo se conservaron. Las identidades y la secuencia pueden avanzar durante el ensayo; no se promete continuidad sin saltos.

13 comprobaciones DOM con API simulada: visibilidad, cancelación sin petición, confirmación histórica, bigint sin pérdida, bloqueo durante envío, rechazo de doble envío, cierre y actualización del listado, alta y cancelación de valoración previa. No equivalen a inspección visual real del navegador.

Compilación correcta sin errores ni advertencias. Instalador consolidado: 163 bloques sintácticos correctos. Evidencias en docs/evidencias/crud-entrega-2026-10-18.

**Migración 003 instalada en MAGISAUTO_Entrega_Final.** Confirmación aportada por Diego: SSMS muestra «CRUD de entrega instalado» y la base final. Esta evidencia es una ejecución administrativa del usuario, no una ejecución de la cuenta de revisión.

### Confirmaciones manuales del 18/10/2026

- Diego confirmó crear, editar y eliminar la valoración temporal del vehículo 7 (Nissan Versa), conservando el vehículo. La confirmación fue textual después del recorrido guiado.
- La captura del recibo 9 de Sofía muestra el botón Eliminar definitivamente y el estado anulado por Q1,000.00.
- La confirmación de borrado identifica el recibo 9 y MGA-2026-005 y advierte la pérdida irreversible del historial, incluso en cortes anteriores.
- Después de cancelar, la captura del historial conserva los nueve pagos y el recibo 9 como ANULADO. No se ejecutó el borrado físico sobre este ejemplo final; esa operación se probó en validación aislada.
- Las capturas se conservan en docs/evidencias/crud-entrega-2026-10-18/manual/. No se vuelve a afirmar un conteo completo de 350 filas mediante estas capturas: muestran los nueve pagos y el usuario confirma el retiro de su valoración temporal.
- Se corrigió la presentación de importes para impedir saltos dentro de las cantidades. Este ajuste posterior todavía no tiene confirmación visual del usuario.

## Instrucciones para otras copias existentes (ya realizado en la de Diego)

Detener la aplicación, abrir database/v2/migraciones/003_CRUD_Entrega.sql en SSMS como administrador, seleccionar MAGISAUTO_Entrega_Final y ejecutar TODO con F5. Debe mostrar «CRUD de entrega instalado». Solo sustituye tres procedimientos, en una transacción; no ejecuta operaciones sobre los registros. Reiniciar la aplicación y recargar el navegador.

Para una computadora nueva usar MAGISAUTO_Final.sql, que ya integra 001, 002 y 003. No reinstalar ni volver a cargar la muestra sobre la base existente. Se mantienen solo dos bases activas: final y validación.

## Manual y demostración

Mostrar CRUD de valoración en un vehículo libre usando una fila desechable. En un recibo anulado, Eliminar definitivamente ofrece una confirmación con Cancelar. Conservar el recibo 9 de Sofía para el ejemplo del reporte de anulaciones; el borrado completo ya se probó con datos temporales aislados. No se afirma aceptación del docente para todos los estados restringidos.

Cambios locales, sin commit ni push de esta actualización.
