# Separar presentación de aprobación sin alterar los estados contractuales existentes.
proc('Credito_Presentar','@NumeroCredito varchar(20), @Responsable nvarchar(100)','''
 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'') IS NULL THROW 51124,'Indique quien presenta la solicitud.',1;
 DECLARE @Cliente int;
 SELECT @Cliente=CodigoDeudor FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado='BORRADOR';
 IF @Cliente IS NULL THROW 51125,'Solo se presenta un credito borrador.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Persona p WITH(HOLDLOCK) ON p.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@Cliente AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND p.FechaNacimiento IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WITH(HOLDLOCK) WHERE t.CodigoPersona=p.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WITH(HOLDLOCK) WHERE x.CodigoPersona=p.CodigoPersona)) THROW 51115,'Complete identificacion, NIT, nacimiento, correo, telefono y direccion del cliente.',1;
 IF (SELECT COUNT(*) FROM dbo.DetalleReferencia dr WITH(HOLDLOCK) JOIN dbo.Referencia r WITH(HOLDLOCK) ON r.CodigoReferencia=dr.CodigoReferencia JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor WHERE dr.CodigoDeudor=@Cliente AND r.CodigoPersona<>d.CodigoPersona AND EXISTS(SELECT 1 FROM dbo.Telefono t WITH(HOLDLOCK) WHERE t.CodigoPersona=r.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WITH(HOLDLOCK) WHERE x.CodigoPersona=r.CodigoPersona))<3 THROW 51116,'Se requieren tres referencias distintas y completas con telefono y direccion.',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@NumeroCredito AND FechaPresentacion IS NOT NULL) THROW 51126,'La solicitud ya esta presentada. Puede revisarla y aprobarla.',1;
 UPDATE dbo.Credito SET FechaPresentacion=dbo.fn_AhoraGuatemala(),PresentadoPor=LTRIM(RTRIM(@Responsable)) WHERE NumeroCredito=@NumeroCredito;
''',True)

parts[-1] = '\n'.join(line.rstrip() for line in parts[-1].splitlines())
