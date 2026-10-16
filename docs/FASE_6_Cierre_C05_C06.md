# Cierre del bloque de entidades integradas y excepciones financieras

Fecha: 15 de octubre de 2026. Rama de trabajo: `pruebas-diego`.
Este informe complementa la auditoría histórica del 14 de octubre; no cambia su evidencia base.
Los cambios de consultas integradas y esta documentación siguen locales, sin publicación nueva.

## Resultado y alcance

Se termina el bloque acordado de consultas generales, eliminación controlada y explicación de
operaciones financieras. No requiere migración ni cambios de procedimientos o tablas SQL.
No equivale a afirmar que las 26 entidades tienen cinco botones independientes ni que el docente
ya aceptó las excepciones al CRUD literal. La fase 6 completa conserva los pendientes acotados
al final de este documento.

## Pruebas manuales confirmadas por Diego

Confirmación del usuario en este chat, complementada por capturas; no se presenta como ejecución
automática del navegador:

- Seis consultas: listado, búsqueda, vacíos, recuperación, navegación y cambio de selección.
- Persona 16 / cliente de prueba: DELETE bloqueado, mensaje de dependencia visible, ocho filas
  conservadas. La pausa del depurador ocurrió antes del manejo global de la excepción; al continuar
  se recibió el mensaje previsto en el navegador.
- Referencia vinculada: el usuario confirmó el mismo bloqueo y conservación.
- Ficha desechable REFERENCIA BORRAR: creada desde un cliente, desvinculada y eliminada desde
  Referencias. El usuario confirmó la prueba; no se solicita repetirla.
- Cancelación, ventana estrecha y teclado: confirmados por el usuario.
- El borrado exitoso manual confirmado corresponde a Referencia. Persona sin dependencias tiene
  evidencia automática; no se inventa una ejecución manual adicional.

## Matriz de entidades integradas (C05)

| Entidad | Alta / actualización | Eliminación | Listado y búsqueda / evidencia |
|---|---|---|---|
| Persona | Integrada en expedientes de roles y referencias; reglas compartidas de identidad | Explícita en Personas; FK bloquean contactos y roles | Consulta global, incluso sin rol; ensayo ampliado y confirmación manual |
| Telefono | Integrada en expediente personal | Quitar contacto y guardar expediente | Consulta global por códigos o número; ensayo de consultas |
| Direccion | Integrada en expediente personal | Quitar dirección y guardar expediente | Consulta global por códigos o detalle; ensayo de consultas |
| Referencia | Integrada en Clientes | Quitar del cliente solo desvincula. Eliminar ficha libre es una acción separada | Consulta global incluye fichas sin clientes; borrado libre y bloqueado comprobados |
| DetalleReferencia | Vincular y cambiar relación desde cliente | Desvincular al guardar cliente | Consulta global por códigos o relación |
| CreditoFiador | Asignar/sustituir conjunto en transacción de borrador | Quitar asignación solo en borrador | Consulta global incluye borradores y contratos; ensayos de créditos previos |

Límite explícito: las consultas globales no agregan editores independientes para contactos o
personas que han quedado sin expediente. No se declara mantenimiento universal de toda fila
huérfana. El alcance implementado resuelve las consultas y eliminaciones identificadas; si el
docente exige edición independiente de esas filas, constituye una ampliación concreta, no una
función ya certificada. No se borran dependencias automáticamente para poder eliminar personas.

## Matriz de operaciones financieras (C06)

| Entidad | Generación / alta | Lectura | Actualización permitida | Eliminación / anulación |
|---|---|---|---|---|
| Credito | Crear borrador; presentar y aprobar desde Créditos | Lista, búsqueda, detalle y reportes | Borrador; al aprobar se conservan condiciones | Borrador: eliminación. Contrato: anulación bajo reglas, conservando historial |
| CreditoFiador | Asignaciones del borrador | Detalle y consulta global | Sustituir conjunto transaccionalmente en borrador | Solo en borrador; no se cambia respaldo histórico |
| DetalleCuota | `Credito_Aprobar` genera el plan | Detalle del crédito, plan y reportes | No editor manual en UI. SP manuales solo admiten BORRADOR | SQL rechaza eliminar cuotas de contratos ya aprobados; anular contrato conserva plan |
| DetallePago | Registrar abono con validaciones | Pagos, recibo, estado de cuenta y reportes | `DetallePago_Actualizar` cambia únicamente Observacion | `DetallePago_Anular`; el SP Eliminar delega en anulación. Conserva importe, motivo, actor y fecha |
| ResumenCredito | `Credito_Aprobar` calcula intereses y total contractual | SP Listar/Buscar y reportes | Sin modificación manual independiente | Sin SP de borrado independiente; no representa saldo editable |

### Justificación para la documentación y defensa

Las cuotas y el resumen son resultados del contrato aprobado. Editarlos directamente podría
desajustar pagos, saldos y reportes. El sistema cambia las condiciones mientras es borrador y
genera esos resultados al aprobar. Una corrección financiera de pago se realiza anulando el
movimiento y registrando otro, conservando trazabilidad. La existencia de SP manuales de cuotas
no autoriza su uso sobre contratos aprobados.

El requisito académico de CRUD por entidad debe explicarse con esta matriz. Las excepciones son
decisiones técnicas documentadas; no se atribuye al docente una aprobación que no consta.

## Evidencia técnica y límites

| Evidencia | Qué acredita | Situación |
|---|---|---|
| [Consultas y eliminación](evidencias/fase-6-consultas-integradas-eliminacion.json) | 86 comprobaciones: consultas, borrado libre, protección por las seis dependencias de Persona y vínculos de Referencia; 26 tablas conservadas | Ejecutadas antes de este cierre; incluye las 69 iniciales, no sumar ambas |
| [Créditos](evidencias/fase-6-creditos.json) | 57 comprobaciones: aprobación/plan, totales, impedir edición/borrado de contrato, anulación conserva cuotas | Evidencia histórica revisada, no reejecutada hoy |
| [Pagos](evidencias/fase-6-pagos.json) | 126 comprobaciones: edición solo de observación, anulaciones, saldos y conservación de plan | Evidencia histórica revisada, no reejecutada hoy |
| [Excepciones financieras](evidencias/fase-6-excepciones-financieras.json) | Bloqueos SQL directos de DetalleCuota Insertar/Actualizar/Eliminar; Resumen sin SP mutadores; 26 tablas conservadas | Nuevo ensayo del 15 de octubre, 9 comprobaciones |

Nuevo ensayo: `scripts/Verificar-ExcepcionesFinancieras.ps1`, solo en
`MAGISAUTO_ValidacionV2`. El contrato disponible con aprobación e historial está **LIQUIDADO**.
Los tres SP devuelven 51003; el código SQL revisado aplica la misma condición `Estado='BORRADOR'`
a todos los demás estados. No se afirma haber ensayado hoy cada estado por separado.
Cada intento va dentro de una transacción externa reversible. No hubo cambios persistentes.
La cuenta administrativa del ensayo SQL no sustituye las pruebas HTTP con cuenta limitada de
los módulos. El resumen se contrastó con las definiciones y el inventario de procedimientos;
no se trata como fallo el que no tenga operaciones manuales de escritura.

## Impacto en el equipo

- **Dylan:** incorporar la matriz y explicar los procedimientos existentes de eliminación,
  aprobación y anulación. No reinstalar base ni ejecutar una migración para este bloque.
- **Josué:** actualizar capturas de Personas y vínculos, cancelación, errores por dependencias
  y borrado libre; reflejar las pruebas manuales confirmadas. La conexión de su aplicación fue
  confirmada por Diego; no equivale a una prueba completa de todos los módulos en su equipo.
- **Diego:** implementación y verificaciones de este bloque terminadas en el alcance descrito.
  Queda publicación e integración como tarea distinta; no se modifica `main` ni ramas ajenas.

## Lista acotada para terminar la fase 6

No repetir las pruebas confirmadas de consultas, parámetros, valoraciones y eliminación.

1. **C07 / Reportes:** cerrar en un único recorrido teclado, ventana estrecha y cambio rápido de
   filtros. Hay 20 reportes con pruebas funcionales previas, pero las capturas no acreditan esos
   tres puntos. El código descarta respuestas obsoletas; revisión estática no equivale a ensayo
   visual. Revisar también el espacio superior de la carta ya señalado en el informe de reportes.
2. **Mejora de mora y diseño, actualización del 16 de octubre:** implementada con detalle por
   rango y acceso a plan; las acciones de las 20 consultas y el diseño común se documentan en
   [Diseño y acciones de Reportes](FASE_6_Diseno_y_Acciones_Reportes.md). Pruebas de lógica
   aprobadas; queda el recorrido visual final indicado allí, no más desarrollo de esa mejora.
3. **Entrega:** publicar los cambios locales autorizados, integrar manual y documentación SQL
   de compañeros y hacer una comprobación de arranque y recorrido desde su copia actualizada.

Los puntos anteriores son el remanente documentado; esta revisión no certifica ausencia absoluta
de defectos ni sustituye la aceptación académica. El PDF final de cierre corresponde después de
resolverlos. Las mejoras nuevas que no respondan a un fallo o requisito se separarán de esta fase.
