credit_params='''@NumeroCredito varchar(20), @CodigoDeudor int, @CodigoGarantia int,
 @CodigoVendedor int, @Enganche decimal(18,2), @Plazo smallint=60,
 @FiadoresRequeridos smallint=1, @PorcentajeComision decimal(9,6)=NULL,
 @CodigoParametro int=NULL'''
credit_prepare='''
 IF @Plazo NOT IN(12,24,36,48,60) OR @Plazo IS NULL THROW 51100,'Plazo permitido: 12,24,36,48 o 60 meses.',1;
 IF @FiadoresRequeridos IS NULL OR @FiadoresRequeridos<0 THROW 51101,'Indique cuantos fiadores requiere el comite; cero si no requiere.',1;
 DECLARE @Precio decimal(18,2),@Agencia int,@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6),@Minimo decimal(9,6),@Comision decimal(9,6);
 SELECT @Precio=ValorAgencia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia;
 SELECT @Agencia=CodigoAgencia FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor;
 IF @Precio IS NULL OR @Agencia IS NULL THROW 51102,'Vehiculo o vendedor inexistente.',1;
 IF @CodigoParametro IS NULL SELECT @CodigoParametro=CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1;
 SELECT @Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida,@Minimo=EngancheMinimo,@Comision=ComisionPredeterminada FROM dbo.ParametroCredito WITH(HOLDLOCK) WHERE CodigoParametro=@CodigoParametro AND Activo=1;
 IF @Tasa IS NULL THROW 51103,'Se requiere una configuracion activa.',1;
 IF @Enganche IS NULL OR @Enganche<CEILING(@Precio*@Minimo*100)/100 OR @Enganche>=@Precio THROW 51104,'Enganche inferior al minimo o sin monto pendiente por financiar.',1;
 SET @Comision=COALESCE(@PorcentajeComision,@Comision);
 IF @Comision NOT BETWEEN 0 AND 1 THROW 51105,'Comision fuera de rango.',1;
'''
proc('Credito_Insertar',credit_params,credit_prepare+'''
 INSERT dbo.Credito(NumeroCredito,CodigoDeudor,CodigoGarantia,CodigoVendedor,CodigoAgencia,CodigoParametro,Plazo,PrecioContado,Enganche,EngancheMinimo,TasaAnual,ManejoMensual,TasaSeguroAuto,TasaSeguroVida,PorcentajeComision,FiadoresRequeridos)
 VALUES(@NumeroCredito,@CodigoDeudor,@CodigoGarantia,@CodigoVendedor,@Agencia,@CodigoParametro,@Plazo,@Precio,@Enganche,@Minimo,@Tasa,@Manejo,@Auto,@Vida,@Comision,@FiadoresRequeridos);
 SELECT * FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito;
''',True)
proc('Credito_Actualizar',credit_params,'''
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado='BORRADOR') THROW 51106,'Solo se editan las condiciones de un credito borrador.',1;
'''+credit_prepare+'''
 IF EXISTS(SELECT 1 FROM dbo.CreditoFiador cf JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Deudor d ON d.CodigoPersona=f.CodigoPersona WHERE cf.NumeroCredito=@NumeroCredito AND d.CodigoDeudor=@CodigoDeudor) THROW 51107,'El nuevo cliente es fiador de este credito.',1;
 UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL,CodigoDeudor=@CodigoDeudor,CodigoGarantia=@CodigoGarantia,CodigoVendedor=@CodigoVendedor,CodigoAgencia=@Agencia,CodigoParametro=@CodigoParametro,Plazo=@Plazo,PrecioContado=@Precio,Enganche=@Enganche,EngancheMinimo=@Minimo,TasaAnual=@Tasa,ManejoMensual=@Manejo,TasaSeguroAuto=@Auto,TasaSeguroVida=@Vida,PorcentajeComision=@Comision,FiadoresRequeridos=@FiadoresRequeridos WHERE NumeroCredito=@NumeroCredito;
''',True)
proc('Credito_Eliminar','@NumeroCredito varchar(20)',"IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado='BORRADOR') THROW 51108,'Solo se borra un credito borrador sin dependencias. Los aprobados se anulan.',1; DELETE dbo.Credito WHERE NumeroCredito=@NumeroCredito;",True)
proc('Credito_Aprobar','''@NumeroCredito varchar(20),@Responsable nvarchar(100),
 @FechaAprobacion datetime2(0)=NULL,@PorcentajeDepreciacion decimal(9,6)=NULL''','''
 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'') IS NULL THROW 51109,'Indique el responsable del comite.',1;
 SET @FechaAprobacion=COALESCE(@FechaAprobacion,dbo.fn_AhoraGuatemala());
 IF @FechaAprobacion>dbo.fn_AhoraGuatemala() THROW 51110,'La aprobacion no puede estar en el futuro.',1;
 DECLARE @Cliente int,@Vehiculo int,@Plazo smallint,@Fiadores smallint,@Parametro int,@Monto decimal(18,2),@Precio decimal(18,2),@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6);
 SELECT @Cliente=CodigoDeudor,@Vehiculo=CodigoGarantia,@Plazo=Plazo,@Fiadores=FiadoresRequeridos,@Parametro=CodigoParametro,@Monto=PrecioContado-Enganche,@Precio=PrecioContado,@Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida
 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado='BORRADOR';
 IF @Cliente IS NULL THROW 51111,'El credito no existe o ya fue aprobado.',1;
 DECLARE @Vin varchar(17);
 SELECT @Vin=VIN FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo;
 IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo AND Estado='VIGENTE') THROW 51112,'El vehiculo ya respalda un credito activo.',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE CodigoGarantia=@Vehiculo AND FechaAnulacion>@FechaAprobacion) THROW 51113,'La aprobacion no puede preceder la anulacion del contrato anterior.',1;
 IF EXISTS(SELECT 1 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito WHERE c.CodigoGarantia=@Vehiculo AND p.FechaPago>@FechaAprobacion) THROW 51114,'La aprobacion no puede preceder pagos del contrato anterior del vehiculo.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@Cliente AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND p.FechaNacimiento IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=p.CodigoPersona)) THROW 51115,'Complete identificacion, NIT, nacimiento, correo, telefono y direccion del cliente.',1;
 IF (SELECT COUNT(*) FROM dbo.DetalleReferencia dr WITH(HOLDLOCK) JOIN dbo.Referencia r ON r.CodigoReferencia=dr.CodigoReferencia JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor WHERE dr.CodigoDeudor=@Cliente AND r.CodigoPersona<>d.CodigoPersona AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=r.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=r.CodigoPersona))<3 THROW 51116,'Se requieren tres referencias distintas y completas con telefono y direccion.',1;
 IF (SELECT COUNT(*) FROM dbo.CreditoFiador cf WITH(HOLDLOCK) JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona JOIN dbo.Deudor d ON d.CodigoDeudor=@Cliente WHERE cf.NumeroCredito=@NumeroCredito AND f.CodigoPersona<>d.CodigoPersona AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona))<@Fiadores THROW 51117,'Complete la cantidad de fiadores y sus datos obligatorios.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@NumeroCredito AND FechaPresentacion IS NOT NULL) THROW 51127,'Presente la solicitud completa antes de aprobar.',1;
 IF @PorcentajeDepreciacion IS NULL SELECT @PorcentajeDepreciacion=DepreciacionInicial FROM dbo.ParametroCredito WHERE CodigoParametro=@Parametro;
 IF @PorcentajeDepreciacion IS NULL OR @PorcentajeDepreciacion NOT BETWEEN 0.15 AND 0.20 THROW 51118,'La depreciacion inicial debe estar entre 15 y 20 por ciento.',1;
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
  IF @K<0 THROW 51119,'El calculo produjo amortizacion negativa.',1;
  INSERT dbo.DetalleCuota(NumeroCredito,Cuota,FechaVencimiento,Capital,Interes)
  VALUES(@NumeroCredito,@N,DATEADD(month,@N,CONVERT(date,@FechaAprobacion)),@K,@I);
  SET @Saldo=@Saldo-@K; SET @N=@N+1;
 END;
 IF @Saldo<>0 THROW 51120,'El plan no liquida el capital.',1;
 INSERT dbo.Depreciacion(CodigoGarantia,FechaValoracion,ValorOriginal,Porcentaje,Observacion) VALUES(@Vehiculo,CONVERT(date,@FechaAprobacion),@Precio,@PorcentajeDepreciacion,N'Valoracion inicial al aprobar '+@NumeroCredito);
 INSERT dbo.ResumenCredito(NumeroCredito,TotalIntereses,TotalNetoRecaudable)
 SELECT @NumeroCredito,SUM(Interes),SUM(Total) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito;
 UPDATE dbo.Credito SET Estado='VIGENTE',FechaAprobacion=@FechaAprobacion,AprobadoPor=@Responsable WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito ORDER BY Cuota;
''',True)
proc('Credito_Anular','@NumeroCredito varchar(20),@Motivo nvarchar(300),@Responsable nvarchar(100)','''
 IF NULLIF(LTRIM(RTRIM(@Motivo)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Responsable)),N'') IS NULL THROW 51121,'Indique motivo y responsable.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado IN('BORRADOR','VIGENTE')) THROW 51122,'El credito no puede anularse en su estado actual.',1;
 IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND FechaAnulacion IS NULL) THROW 51123,'El credito tiene pagos efectivos: resuelvalos antes de anular.',1;
 UPDATE dbo.Credito SET Estado='ANULADO',FechaAnulacion=dbo.fn_AhoraGuatemala(),MotivoAnulacion=@Motivo,AnuladoPor=@Responsable WHERE NumeroCredito=@NumeroCredito;
''',True)

proc('DetallePago_Insertar','''@NumeroCredito varchar(20),@Cuota smallint,@Monto decimal(18,2),@CodigoTipoPago int,
 @Responsable nvarchar(100),@ReferenciaBancaria nvarchar(100)=NULL,@FechaPago datetime2(0)=NULL,@Observacion nvarchar(300)=NULL''','''
 IF @Monto IS NULL OR @Monto<=0 THROW 51200,'El abono debe ser positivo.',1;
 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'') IS NULL THROW 51201,'Indique quien registra el pago.',1;
 SET @FechaPago=COALESCE(@FechaPago,dbo.fn_AhoraGuatemala());
 IF @FechaPago>dbo.fn_AhoraGuatemala() THROW 51202,'No se registran pagos futuros.',1;
 DECLARE @Comision decimal(9,6),@Aprobacion datetime2(0),@Requiere bit;
 SELECT @Comision=PorcentajeComision,@Aprobacion=FechaAprobacion FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado='VIGENTE';
 IF @Comision IS NULL THROW 51203,'El credito no esta vigente.',1;
 IF @FechaPago<@Aprobacion THROW 51204,'El pago no puede preceder la aprobacion.',1;
 -- No insertar movimientos retroactivos detras de movimientos ya registrados: preserva saldos historicos.
 IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND (FechaPago>@FechaPago OR FechaAnulacion>@FechaPago)) THROW 51205,'Registre los movimientos del credito en orden cronologico.',1;
 SELECT @Requiere=RequiereReferencia FROM dbo.TipoPago WHERE CodigoTipoPago=@CodigoTipoPago;
 IF @Requiere IS NULL THROW 51206,'Medio de pago inexistente.',1;
 IF @Requiere=1 AND NULLIF(LTRIM(RTRIM(@ReferenciaBancaria)),N'') IS NULL THROW 51207,'Este medio requiere boleta o autorizacion bancaria.',1;
 DECLARE @Pendiente TABLE(Orden int PRIMARY KEY,Saldo decimal(18,2),Centavos bigint,Fraccion decimal(28,12));
 INSERT @Pendiente(Orden,Saldo)
 SELECT x.Orden,x.Importe FROM dbo.vw_CuotaDesglosada q
 OUTER APPLY(SELECT SUM(Capital) Capital,SUM(Interes) Interes,SUM(ManejoCuenta) ManejoCuenta,SUM(SeguroAuto) SeguroAuto,SUM(SeguroVida) SeguroVida FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND Cuota=@Cuota AND FechaAnulacion IS NULL)p
 CROSS APPLY(VALUES(1,q.Capital-ISNULL(p.Capital,0)),(2,q.Interes-ISNULL(p.Interes,0)),(3,q.ManejoCuenta-ISNULL(p.ManejoCuenta,0)),(4,q.SeguroAuto-ISNULL(p.SeguroAuto,0)),(5,q.SeguroVida-ISNULL(p.SeguroVida,0)))x(Orden,Importe)
 WHERE q.NumeroCredito=@NumeroCredito AND q.Cuota=@Cuota;
 DECLARE @Saldo decimal(18,2)=(SELECT SUM(Saldo) FROM @Pendiente);
 IF @Saldo IS NULL THROW 51208,'Cuota inexistente.',1;
 IF @Monto>@Saldo THROW 51209,'El pago supera el saldo pendiente de la cuota. No se registro ningun importe.',1;
 IF @Saldo<=0 THROW 51210,'La cuota ya esta pagada.',1;
 -- Distribucion proporcional en centavos por mayor residuo, con desempate estable.
 UPDATE @Pendiente SET Centavos=CONVERT(bigint,FLOOR((@Monto*100)*(Saldo/@Saldo))),Fraccion=(@Monto*100)*(Saldo/@Saldo)-FLOOR((@Monto*100)*(Saldo/@Saldo));
 DECLARE @Restantes bigint=CONVERT(bigint,@Monto*100)-(SELECT SUM(Centavos) FROM @Pendiente);
 WHILE @Restantes>0
 BEGIN
  DECLARE @Orden int;
  SET @Orden=NULL;
  SELECT TOP(1) @Orden=Orden FROM @Pendiente WHERE Centavos<CONVERT(bigint,Saldo*100) ORDER BY Fraccion DESC,Orden;
  IF @Orden IS NULL THROW 51211,'No se pudo distribuir el abono.',1;
  UPDATE @Pendiente SET Centavos=Centavos+1,Fraccion=-1 WHERE Orden=@Orden;
  SET @Restantes=@Restantes-1;
 END;
 IF EXISTS(SELECT 1 FROM @Pendiente WHERE Centavos<0 OR Centavos>CONVERT(bigint,Saldo*100)) THROW 51212,'Distribucion fuera del saldo de un componente.',1;
 IF (SELECT SUM(Centavos) FROM @Pendiente)<>CONVERT(bigint,@Monto*100) THROW 51219,'El desglose no coincide con el importe recibido.',1;
 INSERT dbo.DetallePago(NumeroCredito,Cuota,FechaPago,CodigoTipoPago,ReferenciaBancaria,Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,RegistradoPor,Observacion)
 SELECT @NumeroCredito,@Cuota,@FechaPago,@CodigoTipoPago,@ReferenciaBancaria,@Monto,
 MAX(CASE WHEN Orden=1 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=2 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=3 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=4 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=5 THEN Centavos/100.0 END),@Responsable,@Observacion FROM @Pendiente;
 DECLARE @Id bigint=SCOPE_IDENTITY();
 IF (SELECT SUM(Total) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)=(SELECT SUM(Monto) FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND FechaAnulacion IS NULL)
 UPDATE dbo.Credito SET Estado='LIQUIDADO' WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_PagoDesglosado WHERE CodigoPago=@Id;
''',True)
proc('DetallePago_Actualizar','@CodigoPago bigint,@Observacion nvarchar(300)','''
 -- Solo anotaciones: una correccion financiera requiere anular y registrar un nuevo pago.
 UPDATE dbo.DetallePago SET Observacion=@Observacion WHERE CodigoPago=@CodigoPago;
 IF @@ROWCOUNT=0 THROW 51213,'Pago inexistente.',1;
''',True)
proc('DetallePago_Anular','@CodigoPago bigint,@Motivo nvarchar(300),@Responsable nvarchar(100)','''
 IF NULLIF(LTRIM(RTRIM(@Motivo)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Responsable)),N'') IS NULL THROW 51214,'Indique motivo y responsable.',1;
 DECLARE @Credito varchar(20),@Garantia int;
 SELECT @Credito=NumeroCredito FROM dbo.DetallePago WHERE CodigoPago=@CodigoPago;
 SELECT @Garantia=CodigoGarantia FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@Credito;
 IF @Credito IS NULL THROW 51215,'Pago inexistente.',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@Credito AND Estado='ANULADO') THROW 51216,'El credito esta anulado.',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Garantia AND NumeroCredito<>@Credito AND Estado='VIGENTE') THROW 51217,'No se puede reabrir: el vehiculo respalda otro credito activo.',1;
 UPDATE dbo.DetallePago SET FechaAnulacion=dbo.fn_AhoraGuatemala(),MotivoAnulacion=@Motivo,AnuladoPor=@Responsable WHERE CodigoPago=@CodigoPago AND FechaAnulacion IS NULL;
 IF @@ROWCOUNT=0 THROW 51218,'El pago ya fue anulado.',1;
 UPDATE dbo.Credito SET Estado='VIGENTE' WHERE NumeroCredito=@Credito;
 SELECT CodigoPago,Comprobante,Monto,Comision AS ComisionRevertida,FechaAnulacion FROM dbo.vw_PagoDesglosado WHERE CodigoPago=@CodigoPago;
''',True)
# Borrado financiero logico con el mismo contrato de auditoria que la anulacion.
proc('DetallePago_Eliminar','@CodigoPago bigint,@Motivo nvarchar(300),@Responsable nvarchar(100)',"EXEC api.DetallePago_Anular @CodigoPago=@CodigoPago,@Motivo=@Motivo,@Responsable=@Responsable;",True)
