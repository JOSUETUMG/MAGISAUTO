/* 003 - CRUD de valoraciones previas y borrado fisico de pagos anulados.
Ejecutar completo. No modifica datos ni agrega tablas. Conserva 154 SP API.
Primero validar en MAGISAUTO_ValidacionV2. Aplicar luego en la base final.
*/
SET NOCOUNT ON; SET XACT_ABORT ON;
IF DB_NAME() NOT IN (N'MAGISAUTO_Entrega_Final',N'MAGISAUTO_ValidacionV2') THROW 51510,'Seleccione la base final o la base de validacion.',1;
IF OBJECT_ID(N'api.ResumenCredito_Insertar') IS NULL THROW 51510,'Falta el cierre tecnico 002.',1;
BEGIN TRY
 BEGIN TRANSACTION;
EXEC(N'CREATE OR ALTER PROCEDURE api.DetallePago_Eliminar @CodigoPago bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @Anulado datetime2(0), @Existe bit=0;
  SELECT @Existe=1,@Anulado=FechaAnulacion FROM dbo.DetallePago WITH(UPDLOCK,HOLDLOCK) WHERE CodigoPago=@CodigoPago;
  IF @Existe=0 THROW 51213,''El pago no existe.'',1;
  IF @Anulado IS NULL THROW 51219,''Anule primero el pago. No se puede eliminar un pago efectivo.'',1;
  -- El borrado fisico elimina tambien la evidencia para cortes historicos.
  -- No cambia saldos efectivos ni estado: el movimiento ya estaba anulado.
  DELETE dbo.DetallePago WHERE CodigoPago=@CodigoPago;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.[Depreciacion_Actualizar] @CodigoDepreciacion int,

 @CodigoGarantia int,

 @FechaValoracion date,

 @ValorOriginal decimal(18,2),

 @Porcentaje decimal(9,6),

 @Observacion nvarchar(300)

AS

BEGIN

 SET NOCOUNT ON;

 SET XACT_ABORT ON;

 BEGIN TRY

  BEGIN TRANSACTION;
  DECLARE @VehiculoActual int,@VehiculoBloqueado int;
  SELECT @VehiculoActual=CodigoGarantia FROM dbo.Depreciacion WHERE CodigoDepreciacion=@CodigoDepreciacion;
  IF @VehiculoActual IS NULL THROW 51008,''Registro no encontrado.'',1;
  -- Mismo bloqueo que la aprobacion: no permitir editar mientras se aprueba.
  SELECT @VehiculoBloqueado=CodigoGarantia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@VehiculoActual;
  IF @CodigoGarantia<>@VehiculoActual THROW 51014,''No se puede trasladar una valoracion a otro vehiculo.'',1;


  IF @FechaValoracion>CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51006,''La valoracion no puede estar en el futuro.'',1;IF EXISTS(SELECT 1 FROM dbo.Depreciacion d JOIN dbo.Credito c ON c.CodigoGarantia=d.CodigoGarantia WHERE d.CodigoDepreciacion=@CodigoDepreciacion AND c.FechaAprobacion IS NOT NULL) THROW 51014,''La valoracion forma parte del historial; registre una nueva valoracion.'',1;

UPDATE dbo.[Depreciacion] SET [CodigoGarantia]=@CodigoGarantia,[FechaValoracion]=@FechaValoracion,[ValorOriginal]=@ValorOriginal,[Porcentaje]=@Porcentaje,[Observacion]=@Observacion WHERE [CodigoDepreciacion]=@CodigoDepreciacion; IF @@ROWCOUNT=0 THROW 51008,''Registro no encontrado.'',1;

  COMMIT TRANSACTION;

 END TRY

 BEGIN CATCH

  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

  THROW;

 END CATCH;

END;');
EXEC(N'CREATE OR ALTER PROCEDURE api.[Depreciacion_Eliminar] @CodigoDepreciacion int

AS

BEGIN

 SET NOCOUNT ON;

 SET XACT_ABORT ON;

 BEGIN TRY

  BEGIN TRANSACTION;
  DECLARE @VehiculoActual int,@VehiculoBloqueado int;
  SELECT @VehiculoActual=CodigoGarantia FROM dbo.Depreciacion WHERE CodigoDepreciacion=@CodigoDepreciacion;
  IF @VehiculoActual IS NULL THROW 51008,''Registro no encontrado.'',1;
  -- Mismo bloqueo que la aprobacion: no permitir editar mientras se aprueba.
  SELECT @VehiculoBloqueado=CodigoGarantia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@VehiculoActual;


  IF EXISTS(SELECT 1 FROM dbo.Depreciacion d JOIN dbo.Credito c ON c.CodigoGarantia=d.CodigoGarantia WHERE d.CodigoDepreciacion=@CodigoDepreciacion AND c.FechaAprobacion IS NOT NULL) THROW 51014,''La valoracion forma parte del historial; registre una nueva valoracion.'',1;

DELETE dbo.[Depreciacion] WHERE [CodigoDepreciacion]=@CodigoDepreciacion; IF @@ROWCOUNT=0 THROW 51008,''Registro no encontrado.'',1;

  COMMIT TRANSACTION;

 END TRY

 BEGIN CATCH

  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

  THROW;

 END CATCH;

END;');
 COMMIT;
 SELECT DB_NAME() BaseActualizada,N'CRUD de entrega instalado' Resultado;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
