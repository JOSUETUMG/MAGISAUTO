-- Cambiar el nombre si se eligio otro al instalar. Diagnostico administrativo de solo lectura.
USE [MAGISAUTO_Proyecto];
GO
SELECT DB_NAME() AS BaseActual;
SELECT COUNT(*) AS TablasEsperadas25 FROM sys.tables WHERE is_ms_shipped=0;
SELECT COUNT(*) AS ProcedimientosEsperados148 FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api');
SELECT COUNT(*) AS ReportesEsperados20 FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api') AND name LIKE N'Reporte%';
SELECT name,is_disabled,is_not_trusted FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1;
SELECT name,is_disabled FROM sys.indexes WHERE is_disabled=1 AND object_id IN(SELECT object_id FROM sys.tables WHERE is_ms_shipped=0);
EXEC api.ParametroCredito_Listar;
EXEC api.TipoPago_Listar;
SELECT (SELECT COUNT_BIG(*) FROM dbo.Persona) Personas,
       (SELECT COUNT_BIG(*) FROM dbo.Deudor) Clientes,
       (SELECT COUNT_BIG(*) FROM dbo.Fiador) Fiadores,
       (SELECT COUNT_BIG(*) FROM dbo.Garantia) Vehiculos,
       (SELECT COUNT_BIG(*) FROM dbo.Credito) Creditos,
       (SELECT COUNT_BIG(*) FROM dbo.DetalleCuota) Cuotas,
       (SELECT COUNT_BIG(*) FROM dbo.DetallePago) Pagos;
-- Al terminar la instalacion inicial, todas estas cantidades deben ser cero.
