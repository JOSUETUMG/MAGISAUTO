/* Cierre técnico: ejecutar todo en la base MAGISAUTO elegida en SSMS.
No contiene USE ni cambia tablas/datos. Probar primero en MAGISAUTO_ValidacionV2.
Añade tres SP de resumen y actualiza seis SP; puede repetirse.
Requiere la migración 001 y permisos de modificación de procedimientos.
Los importes del resumen se calculan; cuotas y resumen solo cambian en borradores.
Devengo académico mensual por vencimiento, sin cálculo diario. */
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 IF DB_NAME() NOT LIKE N'MAGISAUTO[_]%' THROW 51500,'Seleccione una base MAGISAUTO.',1;
 IF COL_LENGTH('dbo.Credito','FechaPresentacion') IS NULL THROW 51500,'Instale primero la migracion 001.',1;
EXEC(N'CREATE OR ALTER PROCEDURE api.ResumenCredito_Insertar @NumeroCredito varchar(20)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'') THROW 51003,''Solo se modifica el resumen de un borrador.'',1;
  IF EXISTS(SELECT 1 FROM dbo.ResumenCredito WHERE NumeroCredito=@NumeroCredito) THROW 51002,''El resumen ya existe. Use recalcular.'',1; INSERT dbo.ResumenCredito(NumeroCredito,TotalIntereses,TotalNetoRecaudable) SELECT @NumeroCredito,COALESCE(SUM(Interes),0),COALESCE(SUM(Total),0) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.ResumenCredito_Actualizar @NumeroCredito varchar(20)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'') THROW 51003,''Solo se modifica el resumen de un borrador.'',1;
  UPDATE r SET TotalIntereses=x.Intereses,TotalNetoRecaudable=x.Total FROM dbo.ResumenCredito r CROSS APPLY(SELECT COALESCE(SUM(Interes),0) Intereses,COALESCE(SUM(Total),0) Total FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)x WHERE r.NumeroCredito=@NumeroCredito; IF @@ROWCOUNT=0 THROW 51008,''Resumen no encontrado.'',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.ResumenCredito_Eliminar @NumeroCredito varchar(20)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'') THROW 51003,''Solo se modifica el resumen de un borrador.'',1;
  DELETE dbo.ResumenCredito WHERE NumeroCredito=@NumeroCredito; IF @@ROWCOUNT=0 THROW 51008,''Resumen no encontrado.'',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.[DetalleCuota_Insertar] @NumeroCredito varchar(20),

 @Cuota smallint,

 @FechaVencimiento date,

 @Capital decimal(18,2),

 @Interes decimal(18,2)

AS

BEGIN

 SET NOCOUNT ON;

 SET XACT_ABORT ON;

 BEGIN TRY

  BEGIN TRANSACTION;

  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'') THROW 51003,''Solo se modifica este detalle mientras el credito es borrador.'',1;

INSERT dbo.[DetalleCuota]([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) OUTPUT INSERTED.[NumeroCredito],INSERTED.[Cuota] VALUES(@NumeroCredito,@Cuota,@FechaVencimiento,@Capital,@Interes);

  -- Mantener coherente el resumen opcional de la simulación.
  UPDATE r SET TotalIntereses=x.Intereses,TotalNetoRecaudable=x.Total
  FROM dbo.ResumenCredito r CROSS APPLY(SELECT COALESCE(SUM(Interes),0) Intereses,COALESCE(SUM(Total),0) Total
  FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)x WHERE r.NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;

 END TRY

 BEGIN CATCH

  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

  THROW;

 END CATCH;

END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.[DetalleCuota_Actualizar] @NumeroCredito varchar(20),

 @Cuota smallint,

 @FechaVencimiento date,

 @Capital decimal(18,2),

 @Interes decimal(18,2)

AS

BEGIN

 SET NOCOUNT ON;

 SET XACT_ABORT ON;

 BEGIN TRY

  BEGIN TRANSACTION;

  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'') THROW 51003,''Solo se modifica este detalle mientras el credito es borrador.'',1;

UPDATE dbo.[DetalleCuota] SET [FechaVencimiento]=@FechaVencimiento,[Capital]=@Capital,[Interes]=@Interes WHERE [NumeroCredito]=@NumeroCredito AND [Cuota]=@Cuota; IF @@ROWCOUNT=0 THROW 51008,''Registro no encontrado.'',1;

  -- Mantener coherente el resumen opcional de la simulación.
  UPDATE r SET TotalIntereses=x.Intereses,TotalNetoRecaudable=x.Total
  FROM dbo.ResumenCredito r CROSS APPLY(SELECT COALESCE(SUM(Interes),0) Intereses,COALESCE(SUM(Total),0) Total
  FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)x WHERE r.NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;

 END TRY

 BEGIN CATCH

  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

  THROW;

 END CATCH;

END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.[DetalleCuota_Eliminar] @NumeroCredito varchar(20),

 @Cuota smallint

AS

BEGIN

 SET NOCOUNT ON;

 SET XACT_ABORT ON;

 BEGIN TRY

  BEGIN TRANSACTION;

  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'') THROW 51003,''Solo se modifica este detalle mientras el credito es borrador.'',1;

DELETE dbo.[DetalleCuota] WHERE [NumeroCredito]=@NumeroCredito AND [Cuota]=@Cuota; IF @@ROWCOUNT=0 THROW 51008,''Registro no encontrado.'',1;

  -- Mantener coherente el resumen opcional de la simulación.
  UPDATE r SET TotalIntereses=x.Intereses,TotalNetoRecaudable=x.Total
  FROM dbo.ResumenCredito r CROSS APPLY(SELECT COALESCE(SUM(Interes),0) Intereses,COALESCE(SUM(Total),0) Total
  FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)x WHERE r.NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;

 END TRY

 BEGIN CATCH

  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

  THROW;

 END CATCH;

END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.[Credito_Aprobar] @NumeroCredito varchar(20),@Responsable nvarchar(100),

 @FechaAprobacion datetime2(0)=NULL,@PorcentajeDepreciacion decimal(9,6)=NULL

AS

BEGIN

 SET NOCOUNT ON;

 SET XACT_ABORT ON;

 BEGIN TRY

  BEGIN TRANSACTION;



 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'''') IS NULL THROW 51109,''Indique el responsable del comite.'',1;

 SET @FechaAprobacion=COALESCE(@FechaAprobacion,dbo.fn_AhoraGuatemala());

 IF @FechaAprobacion>dbo.fn_AhoraGuatemala() THROW 51110,''La aprobacion no puede estar en el futuro.'',1;

 DECLARE @Cliente int,@Vehiculo int,@Plazo smallint,@Fiadores smallint,@Parametro int,@Monto decimal(18,2),@Precio decimal(18,2),@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6);

 SELECT @Cliente=CodigoDeudor,@Vehiculo=CodigoGarantia,@Plazo=Plazo,@Fiadores=FiadoresRequeridos,@Parametro=CodigoParametro,@Monto=PrecioContado-Enganche,@Precio=PrecioContado,@Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida

 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'';

 IF @Cliente IS NULL THROW 51111,''El credito no existe o ya fue aprobado.'',1;

 DECLARE @Vin varchar(17);

 SELECT @Vin=VIN FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo;

 IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo AND Estado=''VIGENTE'') THROW 51112,''El vehiculo ya respalda un credito activo.'',1;

 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE CodigoGarantia=@Vehiculo AND FechaAnulacion>@FechaAprobacion) THROW 51113,''La aprobacion no puede preceder la anulacion del contrato anterior.'',1;

 IF EXISTS(SELECT 1 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito WHERE c.CodigoGarantia=@Vehiculo AND p.FechaPago>@FechaAprobacion) THROW 51114,''La aprobacion no puede preceder pagos del contrato anterior del vehiculo.'',1;

 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@Cliente AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND p.FechaNacimiento IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=p.CodigoPersona)) THROW 51115,''Complete identificacion, NIT, nacimiento, correo, telefono y direccion del cliente.'',1;

 IF (SELECT COUNT(*) FROM dbo.DetalleReferencia dr WITH(HOLDLOCK) JOIN dbo.Referencia r ON r.CodigoReferencia=dr.CodigoReferencia JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor WHERE dr.CodigoDeudor=@Cliente AND r.CodigoPersona<>d.CodigoPersona AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=r.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=r.CodigoPersona))<3 THROW 51116,''Se requieren tres referencias distintas y completas con telefono y direccion.'',1;

 IF (SELECT COUNT(*) FROM dbo.CreditoFiador cf WITH(HOLDLOCK) JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona JOIN dbo.Deudor d ON d.CodigoDeudor=@Cliente WHERE cf.NumeroCredito=@NumeroCredito AND f.CodigoPersona<>d.CodigoPersona AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona))<@Fiadores THROW 51117,''Complete la cantidad de fiadores y sus datos obligatorios.'',1;

 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@NumeroCredito AND FechaPresentacion IS NOT NULL) THROW 51127,''Presente la solicitud completa antes de aprobar.'',1;

 IF @PorcentajeDepreciacion IS NULL SELECT @PorcentajeDepreciacion=DepreciacionInicial FROM dbo.ParametroCredito WHERE CodigoParametro=@Parametro;

 IF @PorcentajeDepreciacion IS NULL OR @PorcentajeDepreciacion NOT BETWEEN 0.15 AND 0.20 THROW 51118,''La depreciacion inicial debe estar entre 15 y 20 por ciento.'',1;

 -- Las cuotas capturadas para un borrador son una simulacion; se recalculan al aprobar.

 DELETE dbo.DetalleCuota WHERE NumeroCredito=@NumeroCredito;

 DECLARE @r decimal(18,12)=@Tasa/12.0,@Factor decimal(18,12),@PagoBase decimal(18,2),@Saldo decimal(18,2)=@Monto,@I decimal(18,2),@K decimal(18,2),@N smallint=1;

 IF @r=0 SET @PagoBase=ROUND(@Monto/@Plazo,2);

 ELSE BEGIN SET @Factor=POWER(CONVERT(decimal(18,12),1+@r),-@Plazo); SET @PagoBase=ROUND((@Monto*@r)/(1-@Factor),2); END;

 WHILE @N<=@Plazo

 BEGIN

  SET @I=ROUND(@Saldo*@r,2);

  SET @K=CASE WHEN @N=@Plazo THEN @Saldo ELSE @PagoBase-@I END;

  IF @K>@Saldo SET @K=@Saldo;

  IF @K<0 THROW 51119,''El calculo produjo amortizacion negativa.'',1;

  INSERT dbo.DetalleCuota(NumeroCredito,Cuota,FechaVencimiento,Capital,Interes)

  VALUES(@NumeroCredito,@N,DATEADD(month,@N,CONVERT(date,@FechaAprobacion)),@K,@I);

  SET @Saldo=@Saldo-@K; SET @N=@N+1;

 END;

 IF @Saldo<>0 THROW 51120,''El plan no liquida el capital.'',1;

 INSERT dbo.Depreciacion(CodigoGarantia,FechaValoracion,ValorOriginal,Porcentaje,Observacion) VALUES(@Vehiculo,CONVERT(date,@FechaAprobacion),@Precio,@PorcentajeDepreciacion,N''Valoracion inicial al aprobar ''+@NumeroCredito);

 DELETE dbo.ResumenCredito WHERE NumeroCredito=@NumeroCredito;
 INSERT dbo.ResumenCredito(NumeroCredito,TotalIntereses,TotalNetoRecaudable)

 SELECT @NumeroCredito,SUM(Interes),SUM(Total) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito;

 UPDATE dbo.Credito SET Estado=''VIGENTE'',FechaAprobacion=@FechaAprobacion,AprobadoPor=@Responsable WHERE NumeroCredito=@NumeroCredito;

 SELECT * FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito;

 SELECT * FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito ORDER BY Cuota;



  COMMIT TRANSACTION;

 END TRY

 BEGIN CATCH

  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

  THROW;

 END CATCH;

END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.[Credito_Actualizar] @NumeroCredito varchar(20), @CodigoDeudor int, @CodigoGarantia int,

 @CodigoVendedor int, @Enganche decimal(18,2), @Plazo smallint=60,

 @FiadoresRequeridos smallint=1, @PorcentajeComision decimal(9,6)=NULL,

 @CodigoParametro int=NULL

AS

BEGIN

 SET NOCOUNT ON;

 SET XACT_ABORT ON;

 BEGIN TRY

  BEGIN TRANSACTION;



 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''BORRADOR'') THROW 51106,''Solo se editan las condiciones de un credito borrador.'',1;



 IF @Plazo NOT IN(12,24,36,48,60) OR @Plazo IS NULL THROW 51100,''Plazo permitido: 12,24,36,48 o 60 meses.'',1;

 IF @FiadoresRequeridos IS NULL OR @FiadoresRequeridos<0 THROW 51101,''Indique cuantos fiadores requiere el comite; cero si no requiere.'',1;

 DECLARE @Precio decimal(18,2),@Agencia int,@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6),@Minimo decimal(9,6),@Comision decimal(9,6);

 SELECT @Precio=ValorAgencia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia;

 SELECT @Agencia=CodigoAgencia FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor;

 IF @Precio IS NULL OR @Agencia IS NULL THROW 51102,''Vehiculo o vendedor inexistente.'',1;

 IF @CodigoParametro IS NULL SELECT @CodigoParametro=CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1;

 SELECT @Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida,@Minimo=EngancheMinimo,@Comision=ComisionPredeterminada FROM dbo.ParametroCredito WITH(HOLDLOCK) WHERE CodigoParametro=@CodigoParametro AND Activo=1;

 IF @Tasa IS NULL THROW 51103,''Se requiere una configuracion activa.'',1;

 IF @Enganche IS NULL OR @Enganche<CEILING(@Precio*@Minimo*100)/100 OR @Enganche>=@Precio THROW 51104,''Enganche inferior al minimo o sin monto pendiente por financiar.'',1;

 SET @Comision=COALESCE(@PorcentajeComision,@Comision);

 IF @Comision NOT BETWEEN 0 AND 1 THROW 51105,''Comision fuera de rango.'',1;



 IF EXISTS(SELECT 1 FROM dbo.CreditoFiador cf JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Deudor d ON d.CodigoPersona=f.CodigoPersona WHERE cf.NumeroCredito=@NumeroCredito AND d.CodigoDeudor=@CodigoDeudor) THROW 51107,''El nuevo cliente es fiador de este credito.'',1;

 UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL,CodigoDeudor=@CodigoDeudor,CodigoGarantia=@CodigoGarantia,CodigoVendedor=@CodigoVendedor,CodigoAgencia=@Agencia,CodigoParametro=@CodigoParametro,Plazo=@Plazo,PrecioContado=@Precio,Enganche=@Enganche,EngancheMinimo=@Minimo,TasaAnual=@Tasa,ManejoMensual=@Manejo,TasaSeguroAuto=@Auto,TasaSeguroVida=@Vida,PorcentajeComision=@Comision,FiadoresRequeridos=@FiadoresRequeridos WHERE NumeroCredito=@NumeroCredito;



  -- Las condiciones pueden cambiar los cargos de una simulación existente.
  UPDATE r SET TotalIntereses=x.Intereses,TotalNetoRecaudable=x.Total
  FROM dbo.ResumenCredito r CROSS APPLY(SELECT COALESCE(SUM(Interes),0) Intereses,COALESCE(SUM(Total),0) Total
  FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)x WHERE r.NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;

 END TRY

 BEGIN CATCH

  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

  THROW;

 END CATCH;

END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.Reporte10_Intereses @FechaCorte date=NULL
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala()));
 IF @FechaCorte=''99991231'' THROW 51301,''Fecha de corte fuera de rango.'',1;
 -- Criterio académico mensual: se reconoce el interés al vencer la cuota.
 -- El cobro no determina el devengo; un anticipo se muestra por separado.
 SELECT NumeroCredito,
 SUM(Interes) InteresesDelContrato,
 SUM(Interes-InteresPendiente) InteresesCobrados,
 SUM(InteresPendiente) InteresesPendientes,
 SUM(CASE WHEN FechaVencimiento<=@FechaCorte THEN Interes ELSE CONVERT(decimal(18,2),0) END) InteresesDevengados,
 SUM(CASE WHEN FechaVencimiento<=@FechaCorte THEN InteresPendiente ELSE CONVERT(decimal(18,2),0) END) DevengadosPorCobrar,
 SUM(CASE WHEN FechaVencimiento>@FechaCorte THEN Interes ELSE CONVERT(decimal(18,2),0) END) InteresesPorDevengar,
 SUM(CASE WHEN FechaVencimiento>@FechaCorte THEN Interes-InteresPendiente ELSE CONVERT(decimal(18,2),0) END) InteresesCobradosAnticipados
 FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito ORDER BY NumeroCredito;
END;');
 COMMIT TRANSACTION;
 SELECT DB_NAME() BaseActualizada,N'Cierre técnico instalado' Resultado;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
