# MAGIS-AUTO: instalador de la base de datos, version 1.0

Fecha de preparacion: 8 de octubre de 2026.

## Entrega

`MAGISAUTO_Proyecto_Completo.sql` contiene una instalacion nueva con 25 tablas, 148 procedimientos (incluidos 20 reportes), 2 funciones, relaciones, restricciones, indices, catalogos y parametros.

No contiene clientes, referencias, fiadores, vendedores, vehiculos, creditos, cuotas ni pagos de ejemplo. Se incluye una agencia academica como catalogo inicial. No crea la API, las pantallas ni el inicio de sesion del personal.

Es una ampliacion del modelo del ingeniero conforme a los acuerdos del equipo; NO es una copia literal ni una migracion automatica de MagisV1. No se debe ejecutar el archivo original despues de este instalador.

## Instalacion en SSMS

1. Conectarse al motor SQL Server 2022 o 2025 con una cuenta autorizada para crear bases de datos. Instalar SSMS no instala por si solo el motor.
2. Abrir `MAGISAUTO_Proyecto_Completo.sql`.
3. Revisar la linea `DECLARE @Base sysname=N'MAGISAUTO_Proyecto';`. Si esa base ya existe, elegir otro nombre, por ejemplo `MAGISAUTO_Proyecto_Companero`.
4. Ejecutar TODO el archivo de una sola vez, sin seleccionar fragmentos. No necesita modo SQLCMD.
5. Esperar el resultado con 25 tablas, 148 procedimientos y 20 reportes, seguido de `Instalacion completa. Sin operaciones de ejemplo.`.
6. Actualizar Bases de datos en el Explorador de objetos de SSMS. Las tablas estan en dbo; los procedimientos estan en el esquema api.
7. Ejecutar `VERIFICAR_INSTALACION.sql` seleccionando la base recien creada y ajustando su nombre en la primera linea.

PROTECCIONES: si la base existe, el archivo se detiene sin modificarla. Los objetos se instalan en una transaccion; un error revierte esa instalacion. CREATE DATABASE es independiente: si falla la instalacion posterior, la nueva base vacia queda disponible para inspeccion. No la borra automaticamente. No hay DROP DATABASE, TRUNCATE ni deshabilitacion de restricciones en el instalador.

La base existente de Diego, MAGISAUTO_Proyecto, NO fue modificada al preparar esta entrega. MAGISAUTO_Complemento y MagisV1 tampoco. Este archivo no actualiza automaticamente ninguna de ellas.

## Reglas implementadas

- Codigo de cliente correlativo mediante IDENTITY; puede haber saltos por operaciones revertidas.
- DPI unico de 13 digitos y NIT unico cuando estan presentes. Validacion de formato basica, no comprobacion contra registros oficiales. Clientes y fiadores requieren identificacion, NIT y correo; las referencias no estan obligadas a aportar DPI/NIT. El correo puede compartirse.
- Varios telefonos y direcciones por persona. Tres referencias distintas y completas antes de aprobar; no puede ser el propio cliente.
- VIN/chasis unico de 17 caracteres, marca/linea, anio, precio y placa opcional. Solo vehiculos nuevos. Un indice unico filtrado impide dos creditos VIGENTES para el mismo vehiculo. La mora no cambia un credito a un estado que libere el vehiculo.
- Enganche minimo 20%, admitiendo uno mayor; siempre debe quedar monto por financiar. El minimo se redondea hacia arriba al centavo para no quedar por debajo del porcentaje.
- Plazos 12/24/36/48/60 meses, 60 predeterminado. La aprobacion registra responsable del comite.
- Sistema frances: tasa anual nominal inicial 12.5%, tasa mensual=anual/12, amortizacion sobre saldo programado de capital. Cuota de capital+interes constante salvo ajuste final de centavos. Admite tasa cero.
- Primer vencimiento un mes calendario despues de aprobar. Cada fecha se calcula desde la fecha original: 31 de enero -> ultimo dia de febrero -> 31 de marzo.
- Manejo Q25 por cuota, no por abono. Seguros academicos sobre el monto originalmente financiado: auto 0.15% mensual y vida 0.05% mensual. Condiciones guardadas en cada credito.
- El credito se captura primero como BORRADOR; solo al aprobar se genera el plan definitivo. Las cuotas de borrador se reemplazan por el calculo definitivo. Las condiciones aprobadas no se editan por CRUD.
- Un fiador requerido por defecto. El comite puede indicar cero o una cantidad mayor. Relacion muchos-a-muchos; no se permite que el cliente sea su propio fiador.
- Comision inicial 2% del pago completo, configurable por credito. Se calcula por cada pago efectivo. Al anular, se revierte en los reportes. No se carga al cliente ni se presenta como ya desembolsada al vendedor.
- Depreciacion inicial 15%, seleccionable entre 15% y 20%. Historial de valoraciones. No cambia la deuda ni se aplica periodicamente de forma automatica. Las valoraciones vinculadas a un historial contractual no se editan ni borran: se registra otra.
- Una transaccion paga o abona a una cuota. Distribucion proporcional de los cinco componentes, con reparto de centavos por mayor residuo. Rechaza un importe mayor que el saldo. No implementa pagos extraordinarios a capital ni recalculo por anticipos.
- Comprobante global unico por secuencia; no se reutiliza un numero anulado. Cinco medios de pago codificados. Referencia bancaria obligatoria cuando el catalogo la exige; efectivo no requiere referencia.
- Fecha/hora de movimientos en hora de Guatemala. Los pagos pueden registrarse con fecha historica, pero no futura, anterior a aprobar ni anterior a movimientos ya registrados del mismo credito. Esto evita saldos historicos inconsistentes.
- Mora desde el dia siguiente al vencimiento por el saldo pendiente, sin penalizaciones monetarias adicionales. Cortes por dia completo: pagos hasta las 23:59:59 del dia. Las anulaciones afectan desde su fecha; no borran el historial previo.
- Liquidacion cuando se cubren todas las cuotas, incluidos cargos y seguros. Una anulacion de pago reabre el credito, salvo que su vehiculo ya respalde otro credito activo; en ese caso se rechaza toda la anulacion.
- TotalIntereses=sumatoria del interes del plan. TotalNetoRecaudable=sumatoria de cuotas completas, sin enganche y sin descontar comisiones. Es la interpretacion academica acordada, NO ganancia.

## Operaciones de la API

Todas las entidades tienen procedimientos `api.<Entidad>_Insertar`, `_Actualizar`, `_Eliminar`, `_Listar` y `_Buscar`.

Usar parametros con nombre. `_Buscar` admite un criterio de texto que busca sobre todas las columnas convertidas a texto. Las consultas basicas no estan paginadas: esta entrega esta orientada al volumen del proyecto academico.

Operaciones adicionales:
- `api.Credito_Aprobar`: verifica referencias, contactos, fiadores y disponibilidad; genera cuotas y valoracion en una transaccion.
- `api.Credito_Anular`: conserva el contrato y requiere resolver los pagos efectivos primero.
- `api.DetallePago_Anular`: revierte el pago mediante fecha/motivo/responsable, conserva comprobante y devuelve comision revertida.

Restricciones deliberadas del CRUD:
- Creditos: editar o borrar fisicamente solo BORRADORES; el borrado exige que no existan dependencias.
- Cuotas y asignaciones de fiadores: editar o borrar solo durante BORRADOR.
- Pagos: actualizar solo su observacion. Corregir importes o cuota mediante anulacion y nuevo registro. `DetallePago_Eliminar` realiza la misma anulacion auditada; no elimina fisicamente el comprobante.
- Garantias con credito aprobado: conservar sus datos historicos. Los catalogos utilizados no se borran si una FK los referencia.
- Los roles cliente/fiador/vendedor y las referencias no se reasignan a una persona distinta mediante actualizar.

Debe explicarse al ingeniero que borrar pagos se interpreta como anulacion, por conservacion del historial. Si exige un DELETE fisico para toda entidad, ese criterio requiere su aclaracion; esta entrega no oculta esa diferencia. Tambien queda documentada la interpretacion de total neto recaudable.

Seguridad: se crea el rol `magis_api`, con permiso EXECUTE en api y denegacion de SELECT/INSERT/UPDATE/DELETE directo en dbo. La API debe usar una cuenta de privilegios limitados perteneciente a ese rol, no sysadmin/db_owner. Este instalador no crea logins ni guarda contrasenas. Un administrador configura el usuario local al conectar la API. Los nombres de responsable quedan registrados, pero sin inicio de sesion no prueban la identidad de quien los escribio.

Los scripts de instalacion y verificacion se ejecutan administrativamente en SSMS; las operaciones de la aplicacion se haran solo desde la API mediante procedimientos.

## Catalogos incluidos

Departamentos/municipios iniciales: cabeceras de Jalapa y Jutiapa (no es el catalogo completo de Guatemala). Marcas/lineas iniciales: Toyota/Corolla, Hyundai/Accent, Kia/Soluto, Nissan/Versa, Suzuki/Swift. Tipos de telefono, direccion, referencia, garantia y los cinco medios de pago. Agencia academica Jalapa y una configuracion activa de parametros. Los catalogos se amplian con sus procedimientos.

## Cambios frente al archivo del ingeniero

Se conservan los conceptos Persona, Deudor, Garantia, Credito, DetalleCuota, DetallePago, Vendedor y catalogos. Se normaliza el nombre DPI en lugar de IdentificcionNacional; VIN reemplaza la duplicacion chasis/VIN/serie. El precio se llama ValorAgencia. DetalleReferencia vincula referencias con el cliente, no con cada credito. Se agregan Agencia, Fiador, CreditoFiador, ParametroCredito y Depreciacion. Los importes usan decimal, los pagos tienen identificador global y desglose, y los contratos guardan condiciones historicas.

No se importan las operaciones de clase, ni se requiere el complemento MagisNew/MagisFILL para instalar esta version.

## Reportes

Los movimientos del periodo muestran cobros y anulaciones del propio periodo por separado; una anulacion de un pago de otro mes puede producir un movimiento neto negativo. Los saldos a corte muestran la situacion historica de cada dia. Los nombres y descripciones de catalogos son sus valores actuales, no un historial de cambios de nombre.

| N.º | Procedimiento | Para que sirve |
|---|---|---|
| 1 | `api.Reporte01_CreditosEmitidos` | Mide colocacion bruta por periodo; muestra anulaciones por separado, sin ocultar que el credito fue emitido. |
| 2 | `api.Reporte02_CarteraMora` | Determina creditos con cuotas vencidas pendientes al corte, incorporando abonos y anulaciones historicas. |
| 3 | `api.Reporte03_PagosPorMedio` | Compara uso de los cinco medios de pago y distingue ingresos y reversiones del periodo. |
| 4 | `api.Reporte04_VentasVendedor` | Clasifica vendedores por capital colocado en creditos no anulados al cierre del periodo. |
| 5 | `api.Reporte05_Cumpleaneros` | Lista clientes cumpleaneros y genera el texto individual de su carta, sin enviar correos automaticamente. |
| 6 | `api.Reporte06_EstadoCuenta` | Entrega resumen por credito, cuotas y movimientos del cliente hasta una fecha. |
| 7 | `api.Reporte07_PlanPagos` | Muestra todas las cuotas del contrato y su desglose; el saldo al corte es nulo si el contrato no estaba vigente al corte. |
| 8 | `api.Reporte08_Comisiones` | Audita la comision generada y revertida por vendedor; no afirma que haya sido desembolsada al vendedor. |
| 9 | `api.Reporte09_CapitalPendiente` | Mide cuanto capital se ha recuperado y cuanto falta recuperar por credito. |
| 10 | `api.Reporte10_Intereses` | Compara los intereses proyectados del plan con los cobrados; no confunde proyeccion con devengo contable. |
| 11 | `api.Reporte11_ProximosVencimientos` | Prepara la cobranza de cuotas pendientes que vencen dentro del horizonte indicado. |
| 12 | `api.Reporte12_AbonosParciales` | Localiza cuotas que recibieron abonos pero todavia no estan liquidadas. |
| 13 | `api.Reporte13_CreditosMarcaLinea` | Compara la colocacion por marca y linea de vehiculo, excluyendo anulaciones al cierre. |
| 14 | `api.Reporte14_CarteraAgenciaRegion` | Compara cartera y mora por agencia y region; cuenta cada credito una sola vez. |
| 15 | `api.Reporte15_MoraRangos` | Clasifica cada credito por su cuota pendiente mas antigua y suma su deuda vencida. |
| 16 | `api.Reporte16_GarantiaContraCapital` | Compara la ultima valoracion conocida al corte con el capital pendiente, sin modificar la deuda. |
| 17 | `api.Reporte17_DepreciacionCostoFinanciamiento` | Relaciona precio, depreciacion y desembolso contractual del cliente. Los cargos no se presentan como ganancia neta. |
| 18 | `api.Reporte18_CreditosFiador` | Identifica la exposicion de cada fiador. Un mismo credito puede aparecer con distintos fiadores y no debe sumarse como cartera global. |
| 19 | `api.Reporte19_RecaudacionComponentes` | Separa los componentes cobrados y resta las anulaciones ocurridas durante el periodo. |
| 20 | `api.Reporte20_PagosAnulados` | Permite auditar las anulaciones, sus responsables y los importes y comisiones revertidos. |

El reporte de cumpleaneros devuelve una carta por cliente; no envia correos automaticamente. Los reportes de comisiones no constituyen un modulo de desembolso de comisiones.

## Validacion realizada y limites

- ScriptDom de Microsoft: 153 bloques/modulos analizados, cero errores sintacticos.
- DacFx de Microsoft, modelo SQL Server 2022: 188 objetos agregados, cero mensajes de validacion del modelo (incluye resolucion de referencias entre tablas, columnas y procedimientos).
- SQL Server local: 75 planes con combinaciones de cinco montos, tres tasas (incluida cero) y cinco plazos; se verificaron capital, cantidad de cuotas, vencimientos y cuota base constante.
- SQL Server local: 1000 distribuciones de pagos, incluidos pagos completos y de un centavo; todas sumaron el monto y respetaron el saldo de cada componente.
- Esas dos pruebas ejecutaron bloques extraidos de las operaciones financieras usando solo variables de tabla; NO instalaron procedimientos ni guardaron operaciones en bases del usuario.
- No se ejecuto la instalacion completa ni una prueba integral de todos los procedimientos: la cuenta disponible carece de CREATE DATABASE y la autenticacion de Windows desde el entorno de herramientas no estuvo disponible.
- Por tanto, la entrega tiene validacion sintactica, del modelo y de los calculos, pero todavia requiere la prueba integral en una instalacion nueva. No debe describirse como sistema ya probado de extremo a extremo.

## Trabajo individual en Git

Cada integrante puede instalar esta misma base local y desarrollar el sistema completo en su rama. Una rama de Git no crea ni aisla una base SQL Server. Los cambios futuros deben acompanarse de scripts versionados. El codigo de Diego se mantiene en pruebas-diego.
