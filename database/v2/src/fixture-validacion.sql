-- Exclusivamente datos ficticios para el ensayo aislado. No forma parte del instalador.
IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino de validacion incorrecto.',1;
IF EXISTS(SELECT 1 FROM dbo.Persona) OR EXISTS(SELECT 1 FROM dbo.Credito) THROW 52001,'La validacion requiere operaciones vacias.',1;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @i int=1,@persona int,@deudor int,@vendedor int,@fiador int,@ref int,@garantia int;
 WHILE @i<=6
 BEGIN
  DECLARE @dpi varchar(13)=CONCAT('999999999999',@i),@nit varchar(20)=CONCAT('PRUEBA-',@i),@nombre nvarchar(64)=CONCAT(N'Persona ficticia ',@i);
  EXEC api.Persona_Insertar @DPI=@dpi,@NIT=@nit,@PrimerNombre=@nombre,@PrimerApellido=N'Validacion',@FechaNacimiento='19900101',@CorreoElectronico=N'prueba@example.invalid';
  SELECT @persona=CodigoPersona FROM dbo.Persona WHERE DPI=@dpi;
  EXEC api.Telefono_Insertar @CodigoPersona=@persona,@Correlativo=1,@CodigoTipoTelefono=1,@Numero='00000000';
  EXEC api.Direccion_Insertar @CodigoPersona=@persona,@Correlativo=1,@CodigoTipoDireccion=1,@CodigoDepartamento=21,@CodigoMunicipio=1,@Detalle=N'Direccion ficticia de ensayo';
  IF @i=1 BEGIN EXEC api.Deudor_Insertar @CodigoPersona=@persona; SELECT @deudor=CodigoDeudor FROM dbo.Deudor WHERE CodigoPersona=@persona; END;
  IF @i=2 BEGIN EXEC api.Vendedor_Insertar @CodigoEmpleado='ENSAYO',@CodigoPersona=@persona,@CodigoAgencia=1; SELECT @vendedor=CodigoVendedor FROM dbo.Vendedor WHERE CodigoPersona=@persona; END;
  IF @i=3 BEGIN EXEC api.Fiador_Insertar @CodigoPersona=@persona; SELECT @fiador=CodigoFiador FROM dbo.Fiador WHERE CodigoPersona=@persona; END;
  IF @i>=4 BEGIN
   EXEC api.Referencia_Insertar @CodigoPersona=@persona,@LugarTrabajo=N'Lugar ficticio';
   SELECT @ref=CodigoReferencia FROM dbo.Referencia WHERE CodigoPersona=@persona;
   EXEC api.DetalleReferencia_Insertar @CodigoDeudor=@deudor,@CodigoReferencia=@ref,@CodigoTipoReferencia=2,@ParentescoRelacion=N'Amistad de ensayo';
  END;
  SET @i+=1;
 END;
 EXEC api.Garantia_Insertar @VIN='TEST0000000000001',@CodigoMarca=1,@CodigoLinea=1,@Anio=2020,@ValorAgencia=100000,@CodigoTipoGarantia=1,@EsNuevo=1;
 SELECT @garantia=CodigoGarantia FROM dbo.Garantia WHERE VIN='TEST0000000000001';
 EXEC api.Credito_Insertar @NumeroCredito='PRUEBA-01',@CodigoDeudor=@deudor,@CodigoGarantia=@garantia,@CodigoVendedor=@vendedor,@Enganche=20000,@Plazo=12;
 EXEC api.CreditoFiador_Insertar @NumeroCredito='PRUEBA-01',@CodigoFiador=@fiador;
 EXEC api.Credito_Presentar @NumeroCredito='PRUEBA-01',@Responsable=N'Ensayo';
 EXEC api.Credito_Aprobar @NumeroCredito='PRUEBA-01',@Responsable=N'Comite ficticio de ensayo',@FechaAprobacion='20200131';
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
