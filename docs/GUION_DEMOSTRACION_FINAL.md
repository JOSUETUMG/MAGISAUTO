# Recorrido breve para presentar MAGIS-AUTO

Ayuda opcional de 7 a 10 minutos; no es un requisito adicional atribuido al docente.

## Antes de presentar

- Confirmar que la aplicación usa **MAGISAUTO_Entrega_Final** y que se instaló la muestra 2026-10-16-v1. Preparar el archivo no significa que esté cargado.
- Ejecutar `database/final/VERIFICAR_INSTALACION.sql` antes de hacer movimientos.
- Usar corte **16/10/2026**; para períodos, **01/06/2026 a 16/10/2026**. No cambiar el reloj.
- Tener SQL final, documentación y manual disponibles. No mostrar archivos de conexión ni claves.
- Ensayar escrituras con registros nuevos identificables; conservar los seis casos de referencia. Las operaciones cambian los conteos y resultados de la muestra.

## Recorrido

| Paso | Mostrar | Explicar |
| --- | --- | --- |
| Objetivo | Menú principal | Vehículos, expedientes, créditos, pagos y reportes. |
| Expediente | Ana Lucía Morales López | Datos personales, contactos, tres referencias y fiador. Los roles comparten la ficha personal. |
| Vehículo | Toyota Corolla de MGA-2026-001 | VIN, marca, línea y valoración posterior. La valoración no reduce la deuda. |
| Crédito | MGA-2026-001 | Precio Q150,000, enganche Q30,000, financiamiento Q120,000, plazo 24 meses. Desglose de cuotas y pagos al día al corte. |
| Pagos | MGA-2026-002 y MGA-2026-005 | Abono parcial de Carlos; pago anulado de Sofía, con motivo e historial conservado. |
| Reportes | Mora, intereses y estado de cuenta | María, MGA-2026-003, presenta atraso. José, MGA-2026-004, tiene cobro anticipado. Devengado, cobrado y futuro por separado. |
| Borrador | MGA-2026-006 de Luis | Todavía no tiene cuotas aprobadas. Mostrar Cancelar y explicar protección por dependencias. |
| Exportación | Impresión, CSV y carta de cumpleaños de octubre | La carta se prepara para imprimir y no se envía automáticamente. |

## Respuestas para la defensa

- **Procesamiento:** procedimientos almacenados; la API valida entradas y usa permisos limitados.
- **Cuota:** amortización sobre saldo, tasa mensual y plazo; se agregan manejo y seguros. La última cuota ajusta capital restante.
- **Devengo:** criterio académico mensual al vencimiento, sin prorrateo diario. Cobros previos aparecen como anticipos.
- **Anulación:** conserva recibo, motivo, fecha y responsable; conserva historial. Eliminar definitivamente un pago anulado sí lo retira de reportes históricos.
- **Migración 002:** actualización para instalaciones anteriores; el SQL final integra su funcionalidad.
- **Inventario:** 26 tablas, 154 procedimientos API, cuatro vistas, dos funciones y 20 reportes. Muestra inicial: 350 filas.

Ensayar en la computadora de presentación después de cargar los datos y reiniciar la aplicación. Las decisiones del equipo no equivalen a aprobación expresa del docente.

Actualización CRUD 003: ya instalada en la copia final de Diego, según evidencia de SSMS. Para demostrar valoraciones previas usar un vehículo libre y una fila temporal. Conservar el pago anulado de Sofía; el borrado físico se verificó con datos aislados.
