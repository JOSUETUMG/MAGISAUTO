/* Verificador de la muestra de entrega 2026-10-16-v1. Seleccionar MAGISAUTO_Entrega_Final.
Solo consultas; se espera la muestra sin movimientos adicionales. */
SET NOCOUNT ON;
IF DB_NAME()<>N'MAGISAUTO_Entrega_Final' THROW 52600,'Seleccione MAGISAUTO_Entrega_Final.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'MAGISAUTO_DatosEntrega' AND CONVERT(nvarchar(100),value)=N'2026-10-16-v1') THROW 52600,'Falta instalar la muestra coherente.',1;
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api'))<>154 THROW 52601,'Inventario de procedimientos incorrecto.',1;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1) OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE is_disabled=1 OR is_not_trusted=1) THROW 52601,'Restricciones sin validar.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Agencia])<>2 THROW 52701,'Conteo inesperado en Agencia.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Credito])<>6 THROW 52701,'Conteo inesperado en Credito.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[CreditoFiador])<>5 THROW 52701,'Conteo inesperado en CreditoFiador.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Departamento])<>2 THROW 52701,'Conteo inesperado en Departamento.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Depreciacion])<>6 THROW 52701,'Conteo inesperado en Depreciacion.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetalleCuota])<>144 THROW 52701,'Conteo inesperado en DetalleCuota.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetallePago])<>9 THROW 52701,'Conteo inesperado en DetallePago.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetalleReferencia])<>18 THROW 52701,'Conteo inesperado en DetalleReferencia.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Deudor])<>6 THROW 52701,'Conteo inesperado en Deudor.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Direccion])<>29 THROW 52701,'Conteo inesperado en Direccion.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Fiador])<>3 THROW 52701,'Conteo inesperado en Fiador.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Garantia])<>8 THROW 52701,'Conteo inesperado en Garantia.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Linea])<>5 THROW 52701,'Conteo inesperado en Linea.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Marca])<>5 THROW 52701,'Conteo inesperado en Marca.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Municipio])<>2 THROW 52701,'Conteo inesperado en Municipio.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[ParametroCredito])<>1 THROW 52701,'Conteo inesperado en ParametroCredito.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Persona])<>29 THROW 52701,'Conteo inesperado en Persona.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Referencia])<>18 THROW 52701,'Conteo inesperado en Referencia.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[ResumenCredito])<>5 THROW 52701,'Conteo inesperado en ResumenCredito.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Telefono])<>29 THROW 52701,'Conteo inesperado en Telefono.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoDireccion])<>3 THROW 52701,'Conteo inesperado en TipoDireccion.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoGarantia])<>1 THROW 52701,'Conteo inesperado en TipoGarantia.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoPago])<>5 THROW 52701,'Conteo inesperado en TipoPago.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoReferencia])<>4 THROW 52701,'Conteo inesperado en TipoReferencia.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoTelefono])<>3 THROW 52701,'Conteo inesperado en TipoTelefono.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Vendedor])<>2 THROW 52701,'Conteo inesperado en Vendedor.',1;
-- Comprobar la coherencia financiera y los casos, no solo la cantidad de filas.
IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.ResumenCredito r ON r.NumeroCredito=c.NumeroCredito CROSS APPLY(SELECT SUM(Interes) I,SUM(Total) T,SUM(Capital) K FROM dbo.vw_CuotaDesglosada q WHERE q.NumeroCredito=c.NumeroCredito)x WHERE r.TotalIntereses<>x.I OR r.TotalNetoRecaudable<>x.T OR x.K<>c.PrecioContado-c.Enganche) THROW 52702,'Resumen o capital incoherente.',1;
IF EXISTS(SELECT 1 FROM dbo.Credito WHERE FechaPresentacion>FechaAprobacion) THROW 52702,'Presentacion posterior a aprobacion.',1;
IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE FechaAnulacion<FechaPago OR Monto<>Capital+Interes+ManejoCuenta+SeguroAuto+SeguroVida) THROW 52702,'Pago incoherente.',1;
IF EXISTS(SELECT 1 FROM dbo.fn_Saldos('20261016') WHERE NumeroCredito='MGA-2026-001' AND FechaVencimiento<='20261016' AND SaldoPendiente>0) THROW 52702,'El caso al dia presenta atraso.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.fn_Saldos('20261016') WHERE NumeroCredito='MGA-2026-002' AND Cuota=2 AND SaldoPendiente>0 AND SaldoPendiente<Total) THROW 52702,'Falta abono parcial.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.fn_Saldos('20261016') WHERE NumeroCredito='MGA-2026-003' AND FechaVencimiento<'20261016' AND SaldoPendiente>0) THROW 52702,'Falta caso de mora.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.DetallePago p JOIN dbo.DetalleCuota q ON q.NumeroCredito=p.NumeroCredito AND q.Cuota=p.Cuota WHERE p.NumeroCredito='MGA-2026-004' AND p.FechaPago<q.FechaVencimiento) THROW 52702,'Falta anticipo.',1;
IF (SELECT COUNT(*) FROM dbo.DetallePago WHERE FechaAnulacion IS NOT NULL)<>1 THROW 52702,'Falta la anulacion.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito='MGA-2026-006' AND Estado='BORRADOR') THROW 52702,'Falta el borrador.',1;
IF EXISTS(SELECT 1 FROM dbo.Persona WHERE PrimerNombre LIKE '%Prueba%' OR PrimerApellido LIKE '%prueba%') THROW 52702,'Persisten nombres de prueba anteriores.',1;


-- Los cortes reproducen la muestra, sin cambiar el reloj del equipo.
EXEC api.Reporte01_CreditosEmitidos @Desde='20260601',@Hasta='20261016';
EXEC api.Reporte02_CarteraMora @FechaCorte='20261016',@DiasMinimos=1;
EXEC api.Reporte03_PagosPorMedio @Desde='20260601',@Hasta='20261016';
EXEC api.Reporte04_VentasVendedor @Desde='20260601',@Hasta='20261016';
EXEC api.Reporte05_Cumpleaneros @Mes=10,@Anio=2026;
EXEC api.Reporte06_EstadoCuenta @CodigoDeudor=1,@FechaCorte='20261016';
EXEC api.Reporte07_PlanPagos @NumeroCredito='MGA-2026-001',@FechaCorte='20261016';
EXEC api.Reporte08_Comisiones @Desde='20260601',@Hasta='20261016';
EXEC api.Reporte09_CapitalPendiente @FechaCorte='20261016';
EXEC api.Reporte10_Intereses @FechaCorte='20261016';
EXEC api.Reporte11_ProximosVencimientos @FechaCorte='20261016',@Dias=30;
EXEC api.Reporte12_AbonosParciales @FechaCorte='20261016';
EXEC api.Reporte13_CreditosMarcaLinea @Desde='20260601',@Hasta='20261016';
EXEC api.Reporte14_CarteraAgenciaRegion @FechaCorte='20261016';
EXEC api.Reporte15_MoraRangos @FechaCorte='20261016';
EXEC api.Reporte16_GarantiaContraCapital @FechaCorte='20261016';
EXEC api.Reporte17_DepreciacionCostoFinanciamiento @FechaCorte='20261016';
EXEC api.Reporte18_CreditosFiador @FechaCorte='20261016';
EXEC api.Reporte19_RecaudacionComponentes @Desde='20260601',@Hasta='20261016';
EXEC api.Reporte20_PagosAnulados @Desde='20260601',@Hasta='20261016';

SELECT N'Verificacion de datos de entrega correcta' Resultado,DB_NAME() Base,20 ReportesEjecutados,350 Filas,6 Creditos,144 Cuotas,9 Pagos;
