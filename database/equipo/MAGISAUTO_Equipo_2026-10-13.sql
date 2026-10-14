/* MAGIS-AUTO - COPIA ACADEMICA PARA EL EQUIPO - 2026-10-13
Fuente: MAGISAUTO_Proyecto_V2. Datos ficticios confirmados por Diego.
26 tablas, 151 procedimientos, 4 vistas, 2 funciones y 81 filas.
Incluye recibos 1 y 3 efectivos y recibo 2 anulado. No incluye logins ni claves.
Ejecutar TODO en SSMS, como administrador local. Sin modo SQLCMD.
Cambiar solamente @Base para instalar con otro nombre NUEVO.
Si la base existe, se detiene. Nunca ejecutar fragmentos de este archivo.
CREATE DATABASE queda fuera de la transaccion; si hay error puede quedar
una base nueva vacia. No elimina ni reemplaza ninguna base existente.
Esta copia es una fotografia, no una sincronizacion con la base de Diego.
*/
USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Base sysname=N'MAGISAUTO_Equipo';
IF @Base IS NULL OR @Base NOT LIKE N'MAGISAUTO[_]%' OR @Base LIKE N'%[^A-Za-z0-9_]%' COLLATE Latin1_General_100_BIN2
 THROW 52500,'Use un nombre nuevo MAGISAUTO_... con letras, numeros y guion bajo.',1;
IF DB_ID(@Base) IS NOT NULL THROW 52500,'La base ya existe. No se modifico. Elija otro nombre.',1;
DECLARE @Crear nvarchar(max)=N'CREATE DATABASE '+QUOTENAME(@Base)+N';';
EXEC sys.sp_executesql @Crear;
DECLARE @Carga nvarchar(max)=N'USE '+QUOTENAME(@Base)+N'; SET XACT_ABORT ON; BEGIN TRY BEGIN TRANSACTION;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;
EXEC(N''CREATE SCHEMA api AUTHORIZATION dbo;'');

CREATE TABLE dbo.[Departamento](
 [CodigoDepartamento] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_Departamento] PRIMARY KEY ([CodigoDepartamento])
);

CREATE TABLE dbo.[Municipio](
 [CodigoDepartamento] int NOT NULL REFERENCES dbo.Departamento(CodigoDepartamento),
 [CodigoMunicipio] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_Municipio] PRIMARY KEY ([CodigoDepartamento],[CodigoMunicipio])
);

CREATE TABLE dbo.[TipoTelefono](
 [CodigoTipoTelefono] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_TipoTelefono] PRIMARY KEY ([CodigoTipoTelefono])
);

CREATE TABLE dbo.[TipoDireccion](
 [CodigoTipoDireccion] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_TipoDireccion] PRIMARY KEY ([CodigoTipoDireccion])
);

CREATE TABLE dbo.[TipoGarantia](
 [CodigoTipoGarantia] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_TipoGarantia] PRIMARY KEY ([CodigoTipoGarantia])
);

CREATE TABLE dbo.[TipoReferencia](
 [CodigoTipoReferencia] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_TipoReferencia] PRIMARY KEY ([CodigoTipoReferencia])
);

CREATE TABLE dbo.[TipoPago](
 [CodigoTipoPago] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 [RequiereReferencia] bit NOT NULL,
 CONSTRAINT [PK_TipoPago] PRIMARY KEY ([CodigoTipoPago])
);

CREATE TABLE dbo.[Marca](
 [CodigoMarca] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_Marca] PRIMARY KEY ([CodigoMarca])
);

CREATE TABLE dbo.[Linea](
 [CodigoMarca] int NOT NULL REFERENCES dbo.Marca(CodigoMarca),
 [CodigoLinea] int NOT NULL,
 [Descripcion] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0),
 CONSTRAINT [PK_Linea] PRIMARY KEY ([CodigoMarca],[CodigoLinea])
);

CREATE TABLE dbo.[Agencia](
 [CodigoAgencia] int IDENTITY(1,1) NOT NULL,
 [Nombre] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Nombre)))>0),
 [Region] nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Region)))>0),
 CONSTRAINT [PK_Agencia] PRIMARY KEY ([CodigoAgencia])
);

CREATE TABLE dbo.[Persona](
 [CodigoPersona] int IDENTITY(1,1) NOT NULL,
 [DPI] varchar(13) NULL CHECK(DPI IS NULL OR (LEN(DPI)=13 AND DPI NOT LIKE ''%[^0-9]%'' COLLATE Latin1_General_100_BIN2)),
 [NIT] varchar(20) NULL CHECK(NIT IS NULL OR LEN(LTRIM(RTRIM(NIT)))>0),
 [PrimerNombre] nvarchar(64) NOT NULL CHECK(LEN(LTRIM(RTRIM(PrimerNombre)))>0),
 [SegundoNombre] nvarchar(64) NULL,
 [PrimerApellido] nvarchar(64) NOT NULL CHECK(LEN(LTRIM(RTRIM(PrimerApellido)))>0),
 [SegundoApellido] nvarchar(64) NULL,
 [FechaNacimiento] date NULL,
 [Genero] char(1) NULL CHECK(Genero IN (''M'',''F'',''O'')),
 [CorreoElectronico] nvarchar(254) NULL CHECK(CorreoElectronico IS NULL OR CorreoElectronico LIKE ''%_@_%._%''),
 CONSTRAINT [PK_Persona] PRIMARY KEY ([CodigoPersona])
);

CREATE UNIQUE INDEX UX_Persona_DPI ON dbo.Persona(DPI) WHERE DPI IS NOT NULL; CREATE UNIQUE INDEX UX_Persona_NIT ON dbo.Persona(NIT) WHERE NIT IS NOT NULL;

CREATE TABLE dbo.[Telefono](
 [CodigoPersona] int NOT NULL REFERENCES dbo.Persona(CodigoPersona),
 [Correlativo] smallint NOT NULL CHECK(Correlativo>0),
 [CodigoTipoTelefono] int NOT NULL REFERENCES dbo.TipoTelefono(CodigoTipoTelefono),
 [Numero] varchar(32) NOT NULL CHECK(LEN(LTRIM(RTRIM(Numero)))>=8),
 CONSTRAINT [PK_Telefono] PRIMARY KEY ([CodigoPersona],[Correlativo])
);

CREATE TABLE dbo.[Direccion](
 [CodigoPersona] int NOT NULL REFERENCES dbo.Persona(CodigoPersona),
 [Correlativo] smallint NOT NULL CHECK(Correlativo>0),
 [CodigoTipoDireccion] int NOT NULL REFERENCES dbo.TipoDireccion(CodigoTipoDireccion),
 [CodigoDepartamento] int NOT NULL,
 [CodigoMunicipio] int NOT NULL,
 [Detalle] nvarchar(300) NOT NULL CHECK(LEN(LTRIM(RTRIM(Detalle)))>0),
 CONSTRAINT [PK_Direccion] PRIMARY KEY ([CodigoPersona],[Correlativo]),
 CONSTRAINT FK_Direccion_Municipio FOREIGN KEY(CodigoDepartamento,CodigoMunicipio) REFERENCES dbo.Municipio(CodigoDepartamento,CodigoMunicipio)
);

CREATE TABLE dbo.[Deudor](
 [CodigoDeudor] int IDENTITY(1,1) NOT NULL,
 [CodigoPersona] int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona),
 CONSTRAINT [PK_Deudor] PRIMARY KEY ([CodigoDeudor])
);

CREATE TABLE dbo.[Referencia](
 [CodigoReferencia] int IDENTITY(1,1) NOT NULL,
 [CodigoPersona] int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona),
 [LugarTrabajo] nvarchar(200) NOT NULL CHECK(LEN(LTRIM(RTRIM(LugarTrabajo)))>0),
 CONSTRAINT [PK_Referencia] PRIMARY KEY ([CodigoReferencia])
);

CREATE TABLE dbo.[DetalleReferencia](
 [CodigoDeudor] int NOT NULL REFERENCES dbo.Deudor(CodigoDeudor),
 [CodigoReferencia] int NOT NULL REFERENCES dbo.Referencia(CodigoReferencia),
 [CodigoTipoReferencia] int NOT NULL REFERENCES dbo.TipoReferencia(CodigoTipoReferencia),
 [ParentescoRelacion] nvarchar(100) NOT NULL CHECK(LEN(LTRIM(RTRIM(ParentescoRelacion)))>0),
 CONSTRAINT [PK_DetalleReferencia] PRIMARY KEY ([CodigoDeudor],[CodigoReferencia])
);

CREATE TABLE dbo.[Fiador](
 [CodigoFiador] int IDENTITY(1,1) NOT NULL,
 [CodigoPersona] int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona),
 CONSTRAINT [PK_Fiador] PRIMARY KEY ([CodigoFiador])
);

CREATE TABLE dbo.[Vendedor](
 [CodigoVendedor] int IDENTITY(1,1) NOT NULL,
 [CodigoEmpleado] varchar(30) NOT NULL UNIQUE CHECK(LEN(LTRIM(RTRIM(CodigoEmpleado)))>0),
 [CodigoPersona] int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona),
 [CodigoAgencia] int NOT NULL REFERENCES dbo.Agencia(CodigoAgencia),
 CONSTRAINT [PK_Vendedor] PRIMARY KEY ([CodigoVendedor])
);

CREATE TABLE dbo.[Garantia](
 [CodigoGarantia] int IDENTITY(1,1) NOT NULL,
 [VIN] varchar(17) NOT NULL UNIQUE CHECK(LEN(VIN)=17 AND VIN NOT LIKE ''%[^0-9A-HJ-NPR-Z]%'' COLLATE Latin1_General_100_BIN2),
 [CodigoMarca] int NOT NULL,
 [CodigoLinea] int NOT NULL,
 [Anio] smallint NOT NULL CHECK(Anio BETWEEN 1886 AND 2100),
 [ValorAgencia] decimal(18,2) NOT NULL CHECK(ValorAgencia>0),
 [Placa] varchar(20) NULL CHECK(Placa IS NULL OR LEN(LTRIM(RTRIM(Placa)))>0),
 [CodigoTipoGarantia] int NOT NULL REFERENCES dbo.TipoGarantia(CodigoTipoGarantia),
 [EsNuevo] bit NOT NULL DEFAULT 1 CHECK(EsNuevo=1),
 CONSTRAINT [PK_Garantia] PRIMARY KEY ([CodigoGarantia]),
 CONSTRAINT FK_Garantia_Linea FOREIGN KEY(CodigoMarca,CodigoLinea) REFERENCES dbo.Linea(CodigoMarca,CodigoLinea)
);

CREATE UNIQUE INDEX UX_Garantia_Placa ON dbo.Garantia(Placa) WHERE Placa IS NOT NULL;

CREATE TABLE dbo.[ParametroCredito](
 [CodigoParametro] int IDENTITY(1,1) NOT NULL,
 [Nombre] nvarchar(100) NOT NULL,
 [Activo] bit NOT NULL,
 [TasaAnual] decimal(9,6) NOT NULL CHECK(TasaAnual BETWEEN 0 AND 1),
 [ManejoMensual] decimal(18,2) NOT NULL CHECK(ManejoMensual=25),
 [TasaSeguroAuto] decimal(9,6) NOT NULL CHECK(TasaSeguroAuto>0 AND TasaSeguroAuto<=1),
 [TasaSeguroVida] decimal(9,6) NOT NULL CHECK(TasaSeguroVida>0 AND TasaSeguroVida<=1),
 [EngancheMinimo] decimal(9,6) NOT NULL CHECK(EngancheMinimo>=0.20 AND EngancheMinimo<1),
 [ComisionPredeterminada] decimal(9,6) NOT NULL CHECK(ComisionPredeterminada BETWEEN 0 AND 1),
 [DepreciacionInicial] decimal(9,6) NOT NULL CHECK(DepreciacionInicial BETWEEN 0.15 AND 0.20),
 CONSTRAINT [PK_ParametroCredito] PRIMARY KEY ([CodigoParametro])
);

CREATE UNIQUE INDEX UX_Parametro_Activo ON dbo.ParametroCredito(Activo) WHERE Activo=1;

CREATE TABLE dbo.[Credito](
 [NumeroCredito] varchar(20) NOT NULL CHECK(LEN(LTRIM(RTRIM(NumeroCredito)))>0),
 [CodigoDeudor] int NOT NULL REFERENCES dbo.Deudor(CodigoDeudor),
 [CodigoGarantia] int NOT NULL REFERENCES dbo.Garantia(CodigoGarantia),
 [CodigoVendedor] int NOT NULL REFERENCES dbo.Vendedor(CodigoVendedor),
 [CodigoAgencia] int NOT NULL REFERENCES dbo.Agencia(CodigoAgencia),
 [CodigoParametro] int NOT NULL REFERENCES dbo.ParametroCredito(CodigoParametro),
 [Plazo] smallint NOT NULL DEFAULT 60 CHECK(Plazo IN(12,24,36,48,60)),
 [PrecioContado] decimal(18,2) NOT NULL CHECK(PrecioContado>0),
 [Enganche] decimal(18,2) NOT NULL,
 [EngancheMinimo] decimal(9,6) NOT NULL CHECK(EngancheMinimo>=0.20 AND EngancheMinimo<1),
 [TasaAnual] decimal(9,6) NOT NULL CHECK(TasaAnual BETWEEN 0 AND 1),
 [ManejoMensual] decimal(18,2) NOT NULL CHECK(ManejoMensual=25),
 [TasaSeguroAuto] decimal(9,6) NOT NULL CHECK(TasaSeguroAuto>0 AND TasaSeguroAuto<=1),
 [TasaSeguroVida] decimal(9,6) NOT NULL CHECK(TasaSeguroVida>0 AND TasaSeguroVida<=1),
 [PorcentajeComision] decimal(9,6) NOT NULL CHECK(PorcentajeComision BETWEEN 0 AND 1),
 [FiadoresRequeridos] smallint NOT NULL CHECK(FiadoresRequeridos>=0),
 [Estado] varchar(10) NOT NULL DEFAULT ''BORRADOR'' CHECK(Estado IN(''BORRADOR'',''VIGENTE'',''LIQUIDADO'',''ANULADO'')),
 [FechaAprobacion] datetime2(0) NULL,
 [AprobadoPor] nvarchar(100) NULL,
 [FechaPresentacion] datetime2(0) NULL,
 [PresentadoPor] nvarchar(100) NULL,
 [FechaAnulacion] datetime2(0) NULL,
 [MotivoAnulacion] nvarchar(300) NULL,
 [AnuladoPor] nvarchar(100) NULL,
 CONSTRAINT [PK_Credito] PRIMARY KEY ([NumeroCredito]),
 CONSTRAINT CK_Credito_Enganche CHECK(Enganche>=CEILING(PrecioContado*EngancheMinimo*100)/100 AND Enganche<PrecioContado),
 CONSTRAINT CK_Credito_Estado CHECK((Estado=''BORRADOR'' AND FechaAprobacion IS NULL) OR (Estado IN(''VIGENTE'',''LIQUIDADO'') AND FechaAprobacion IS NOT NULL AND AprobadoPor IS NOT NULL) OR (Estado=''ANULADO'' AND FechaAnulacion IS NOT NULL AND MotivoAnulacion IS NOT NULL AND AnuladoPor IS NOT NULL))
);

CREATE UNIQUE INDEX UX_Credito_VehiculoActivo ON dbo.Credito(CodigoGarantia) WHERE Estado=''VIGENTE'';

CREATE INDEX IX_Credito_Deudor ON dbo.Credito(CodigoDeudor,FechaAprobacion); CREATE INDEX IX_Credito_Vendedor ON dbo.Credito(CodigoVendedor,FechaAprobacion);

CREATE TABLE dbo.[CreditoFiador](
 [NumeroCredito] varchar(20) NOT NULL REFERENCES dbo.Credito(NumeroCredito),
 [CodigoFiador] int NOT NULL REFERENCES dbo.Fiador(CodigoFiador),
 CONSTRAINT [PK_CreditoFiador] PRIMARY KEY ([NumeroCredito],[CodigoFiador])
);

CREATE TABLE dbo.[Depreciacion](
 [CodigoDepreciacion] int IDENTITY(1,1) NOT NULL,
 [CodigoGarantia] int NOT NULL REFERENCES dbo.Garantia(CodigoGarantia),
 [FechaValoracion] date NOT NULL,
 [ValorOriginal] decimal(18,2) NOT NULL CHECK(ValorOriginal>0),
 [Porcentaje] decimal(9,6) NOT NULL CHECK(Porcentaje BETWEEN 0.15 AND 0.20),
 [Observacion] nvarchar(300) NOT NULL CHECK(LEN(LTRIM(RTRIM(Observacion)))>0),
 CONSTRAINT [PK_Depreciacion] PRIMARY KEY ([CodigoDepreciacion])
);

CREATE INDEX IX_Depreciacion_Historial ON dbo.Depreciacion(CodigoGarantia,FechaValoracion DESC,CodigoDepreciacion DESC);

CREATE TABLE dbo.[DetalleCuota](
 [NumeroCredito] varchar(20) NOT NULL REFERENCES dbo.Credito(NumeroCredito),
 [Cuota] smallint NOT NULL CHECK(Cuota BETWEEN 1 AND 60),
 [FechaVencimiento] date NOT NULL,
 [Capital] decimal(18,2) NOT NULL CHECK(Capital>=0),
 [Interes] decimal(18,2) NOT NULL CHECK(Interes>=0),
 CONSTRAINT [PK_DetalleCuota] PRIMARY KEY ([NumeroCredito],[Cuota])
);

CREATE INDEX IX_Cuota_Vencimiento ON dbo.DetalleCuota(FechaVencimiento,NumeroCredito) INCLUDE(Capital,Interes);

CREATE SEQUENCE dbo.SecComprobante AS bigint START WITH 1 INCREMENT BY 1;

CREATE TABLE dbo.[DetallePago](
 [CodigoPago] bigint IDENTITY(1,1) NOT NULL,
 [Comprobante] bigint NOT NULL UNIQUE DEFAULT(NEXT VALUE FOR dbo.SecComprobante),
 [NumeroCredito] varchar(20) NOT NULL,
 [Cuota] smallint NOT NULL,
 [FechaPago] datetime2(0) NOT NULL,
 [CodigoTipoPago] int NOT NULL REFERENCES dbo.TipoPago(CodigoTipoPago),
 [ReferenciaBancaria] nvarchar(100) NULL,
 [Monto] decimal(18,2) NOT NULL CHECK(Monto>0),
 [Capital] decimal(18,2) NOT NULL CHECK(Capital>=0),
 [Interes] decimal(18,2) NOT NULL CHECK(Interes>=0),
 [ManejoCuenta] decimal(18,2) NOT NULL CHECK(ManejoCuenta>=0),
 [SeguroAuto] decimal(18,2) NOT NULL CHECK(SeguroAuto>=0),
 [SeguroVida] decimal(18,2) NOT NULL CHECK(SeguroVida>=0),
 [RegistradoPor] nvarchar(100) NOT NULL CHECK(LEN(LTRIM(RTRIM(RegistradoPor)))>0),
 [FechaAnulacion] datetime2(0) NULL,
 [MotivoAnulacion] nvarchar(300) NULL,
 [AnuladoPor] nvarchar(100) NULL,
 [Observacion] nvarchar(300) NULL,
 CONSTRAINT [PK_DetallePago] PRIMARY KEY ([CodigoPago]),
 CONSTRAINT FK_Pago_Cuota FOREIGN KEY(NumeroCredito,Cuota) REFERENCES dbo.DetalleCuota(NumeroCredito,Cuota),
 CONSTRAINT CK_Pago_Desglose CHECK(Monto=Capital+Interes+ManejoCuenta+SeguroAuto+SeguroVida),
 CONSTRAINT CK_Pago_Anulacion CHECK((FechaAnulacion IS NULL AND MotivoAnulacion IS NULL AND AnuladoPor IS NULL) OR (FechaAnulacion IS NOT NULL AND FechaAnulacion>=FechaPago AND MotivoAnulacion IS NOT NULL AND AnuladoPor IS NOT NULL))
);

CREATE INDEX IX_Pago_Cuota ON dbo.DetallePago(NumeroCredito,Cuota,FechaPago) INCLUDE(Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,FechaAnulacion);

CREATE TABLE dbo.[ResumenCredito](
 [NumeroCredito] varchar(20) NOT NULL REFERENCES dbo.Credito(NumeroCredito),
 [TotalIntereses] decimal(18,2) NOT NULL CHECK(TotalIntereses>=0),
 [TotalNetoRecaudable] decimal(18,2) NOT NULL CHECK(TotalNetoRecaudable>=0),
 CONSTRAINT [PK_ResumenCredito] PRIMARY KEY ([NumeroCredito])
);

EXEC(N''CREATE VIEW dbo.vw_CreditoResumen AS
 SELECT c.*,CONVERT(decimal(18,2),c.PrecioContado-c.Enganche) AS MontoFinanciado,
 r.TotalIntereses,r.TotalNetoRecaudable
 FROM dbo.Credito c LEFT JOIN dbo.ResumenCredito r ON r.NumeroCredito=c.NumeroCredito;'');

EXEC(N''CREATE VIEW dbo.vw_CuotaDesglosada AS
 SELECT q.*,c.ManejoMensual AS ManejoCuenta,s.SeguroAuto,s.SeguroVida,
 CONVERT(decimal(18,2),q.Capital+q.Interes+c.ManejoMensual+s.SeguroAuto+s.SeguroVida) AS Total
 FROM dbo.DetalleCuota q JOIN dbo.Credito c ON c.NumeroCredito=q.NumeroCredito
 CROSS APPLY(SELECT CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroAuto,2)) SeguroAuto,
 CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroVida,2)) SeguroVida)s;'');

EXEC(N''CREATE VIEW dbo.vw_PagoDesglosado AS
 SELECT p.*,c.PorcentajeComision,
 CONVERT(decimal(18,2),ROUND(p.Monto*c.PorcentajeComision,2)) AS Comision
 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito;'');

EXEC(N''CREATE VIEW dbo.vw_DepreciacionCalculada AS
 SELECT d.*,CONVERT(decimal(18,2),ROUND(d.ValorOriginal*(1-d.Porcentaje),2)) AS ValorDepreciado
 FROM dbo.Depreciacion d;'');

INSERT dbo.Departamento VALUES(21,N''Jalapa''),(22,N''Jutiapa''); INSERT dbo.Municipio VALUES(21,1,N''Jalapa''),(22,1,N''Jutiapa'');

INSERT dbo.TipoTelefono VALUES(1,N''Celular''),(2,N''Casa''),(3,N''Trabajo'');

INSERT dbo.TipoDireccion VALUES(1,N''Particular''),(2,N''Trabajo''),(3,N''Otra'');

INSERT dbo.TipoGarantia VALUES(1,N''Vehiculo nuevo de agencia'');

INSERT dbo.TipoReferencia VALUES(1,N''Familiar''),(2,N''Amistad''),(3,N''Laboral''),(4,N''Otra'');

INSERT dbo.Marca VALUES(1,N''Toyota''),(2,N''Hyundai''),(3,N''Kia''),(4,N''Nissan''),(5,N''Suzuki'');

INSERT dbo.Linea VALUES(1,1,N''Corolla''),(2,1,N''Accent''),(3,1,N''Soluto''),(4,1,N''Versa''),(5,1,N''Swift'');

INSERT dbo.TipoPago VALUES(1,N''Deposito bancario'',1),(2,N''Transferencia ACH'',1),(3,N''Tarjeta de credito'',1),(4,N''Tarjeta de debito'',1),(5,N''Efectivo en ventanilla'',0);

INSERT dbo.Agencia(Nombre,Region) VALUES(N''Agencia academica Jalapa'',N''Oriente'');

INSERT dbo.ParametroCredito(Nombre,Activo,TasaAnual,ManejoMensual,TasaSeguroAuto,TasaSeguroVida,EngancheMinimo,ComisionPredeterminada,DepreciacionInicial) VALUES(N''Condiciones academicas iniciales'',1,0.125,25,0.0015,0.0005,0.20,0.02,0.15);

EXEC(N''CREATE FUNCTION dbo.fn_AhoraGuatemala() RETURNS datetime2(0) AS BEGIN RETURN CONVERT(datetime2(0),SYSUTCDATETIME() AT TIME ZONE ''''UTC'''' AT TIME ZONE ''''Central America Standard Time''''); END;'');

EXEC(N''CREATE FUNCTION dbo.fn_Saldos(@FechaCorte date) RETURNS TABLE AS RETURN
 SELECT q.*,c.CodigoDeudor,c.CodigoGarantia,c.CodigoVendedor,c.CodigoAgencia,
 q.Total-ISNULL(p.Monto,0) AS SaldoPendiente,
 q.Capital-ISNULL(p.Capital,0) AS CapitalPendiente,
 q.Interes-ISNULL(p.Interes,0) AS InteresPendiente,
 q.ManejoCuenta-ISNULL(p.ManejoCuenta,0) AS ManejoPendiente,
 q.SeguroAuto-ISNULL(p.SeguroAuto,0) AS AutoPendiente,
 q.SeguroVida-ISNULL(p.SeguroVida,0) AS VidaPendiente
 FROM dbo.vw_CuotaDesglosada q JOIN dbo.Credito c ON c.NumeroCredito=q.NumeroCredito
 OUTER APPLY(SELECT SUM(Monto) Monto,SUM(Capital) Capital,SUM(Interes) Interes,SUM(ManejoCuenta) ManejoCuenta,SUM(SeguroAuto) SeguroAuto,SUM(SeguroVida) SeguroVida
 FROM dbo.DetallePago p WHERE p.NumeroCredito=q.NumeroCredito AND p.Cuota=q.Cuota
 AND p.FechaPago<DATEADD(day,1,CONVERT(datetime2,@FechaCorte))
 AND(p.FechaAnulacion IS NULL OR p.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte))))p
 WHERE c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@FechaCorte))
 AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte)));'');

EXEC(N''CREATE PROCEDURE api.[Departamento_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Departamento] ORDER BY [CodigoDepartamento];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Departamento_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Departamento] WHERE CONVERT(nvarchar(4000),[CodigoDepartamento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDepartamento];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Departamento_Insertar] @CodigoDepartamento int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Departamento]([CodigoDepartamento],[Descripcion]) OUTPUT INSERTED.[CodigoDepartamento] VALUES(@CodigoDepartamento,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Departamento_Actualizar] @CodigoDepartamento int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Departamento] SET [Descripcion]=@Descripcion WHERE [CodigoDepartamento]=@CodigoDepartamento; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Departamento_Eliminar] @CodigoDepartamento int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Departamento] WHERE [CodigoDepartamento]=@CodigoDepartamento; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Municipio_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Municipio] ORDER BY [CodigoDepartamento],[CodigoMunicipio];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Municipio_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Municipio] WHERE CONVERT(nvarchar(4000),[CodigoDepartamento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoMunicipio]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDepartamento],[CodigoMunicipio];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Municipio_Insertar] @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Municipio]([CodigoDepartamento],[CodigoMunicipio],[Descripcion]) OUTPUT INSERTED.[CodigoDepartamento],INSERTED.[CodigoMunicipio] VALUES(@CodigoDepartamento,@CodigoMunicipio,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Municipio_Actualizar] @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Municipio] SET [Descripcion]=@Descripcion WHERE [CodigoDepartamento]=@CodigoDepartamento AND [CodigoMunicipio]=@CodigoMunicipio; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Municipio_Eliminar] @CodigoDepartamento int,
 @CodigoMunicipio int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Municipio] WHERE [CodigoDepartamento]=@CodigoDepartamento AND [CodigoMunicipio]=@CodigoMunicipio; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoTelefono_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoTelefono] ORDER BY [CodigoTipoTelefono];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoTelefono_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoTelefono] WHERE CONVERT(nvarchar(4000),[CodigoTipoTelefono]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoTelefono];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoTelefono_Insertar] @CodigoTipoTelefono int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoTelefono]([CodigoTipoTelefono],[Descripcion]) OUTPUT INSERTED.[CodigoTipoTelefono] VALUES(@CodigoTipoTelefono,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoTelefono_Actualizar] @CodigoTipoTelefono int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoTelefono] SET [Descripcion]=@Descripcion WHERE [CodigoTipoTelefono]=@CodigoTipoTelefono; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoTelefono_Eliminar] @CodigoTipoTelefono int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoTelefono] WHERE [CodigoTipoTelefono]=@CodigoTipoTelefono; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoDireccion_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoDireccion] ORDER BY [CodigoTipoDireccion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoDireccion_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoDireccion] WHERE CONVERT(nvarchar(4000),[CodigoTipoDireccion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoDireccion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoDireccion_Insertar] @CodigoTipoDireccion int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoDireccion]([CodigoTipoDireccion],[Descripcion]) OUTPUT INSERTED.[CodigoTipoDireccion] VALUES(@CodigoTipoDireccion,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoDireccion_Actualizar] @CodigoTipoDireccion int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoDireccion] SET [Descripcion]=@Descripcion WHERE [CodigoTipoDireccion]=@CodigoTipoDireccion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoDireccion_Eliminar] @CodigoTipoDireccion int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoDireccion] WHERE [CodigoTipoDireccion]=@CodigoTipoDireccion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoGarantia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoGarantia] ORDER BY [CodigoTipoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoGarantia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoGarantia] WHERE CONVERT(nvarchar(4000),[CodigoTipoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoGarantia_Insertar] @CodigoTipoGarantia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoGarantia]([CodigoTipoGarantia],[Descripcion]) OUTPUT INSERTED.[CodigoTipoGarantia] VALUES(@CodigoTipoGarantia,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoGarantia_Actualizar] @CodigoTipoGarantia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoGarantia] SET [Descripcion]=@Descripcion WHERE [CodigoTipoGarantia]=@CodigoTipoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoGarantia_Eliminar] @CodigoTipoGarantia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoGarantia] WHERE [CodigoTipoGarantia]=@CodigoTipoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoReferencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoReferencia] ORDER BY [CodigoTipoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoReferencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoReferencia] WHERE CONVERT(nvarchar(4000),[CodigoTipoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoReferencia_Insertar] @CodigoTipoReferencia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoReferencia]([CodigoTipoReferencia],[Descripcion]) OUTPUT INSERTED.[CodigoTipoReferencia] VALUES(@CodigoTipoReferencia,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoReferencia_Actualizar] @CodigoTipoReferencia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoReferencia] SET [Descripcion]=@Descripcion WHERE [CodigoTipoReferencia]=@CodigoTipoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoReferencia_Eliminar] @CodigoTipoReferencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoReferencia] WHERE [CodigoTipoReferencia]=@CodigoTipoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoPago_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoPago] ORDER BY [CodigoTipoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoPago_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoPago] WHERE CONVERT(nvarchar(4000),[CodigoTipoPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[RequiereReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoPago_Insertar] @CodigoTipoPago int,
 @Descripcion nvarchar(128),
 @RequiereReferencia bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoPago]([CodigoTipoPago],[Descripcion],[RequiereReferencia]) OUTPUT INSERTED.[CodigoTipoPago] VALUES(@CodigoTipoPago,@Descripcion,@RequiereReferencia);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoPago_Actualizar] @CodigoTipoPago int,
 @Descripcion nvarchar(128),
 @RequiereReferencia bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoPago] SET [Descripcion]=@Descripcion,[RequiereReferencia]=@RequiereReferencia WHERE [CodigoTipoPago]=@CodigoTipoPago; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[TipoPago_Eliminar] @CodigoTipoPago int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoPago] WHERE [CodigoTipoPago]=@CodigoTipoPago; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Marca_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Marca] ORDER BY [CodigoMarca];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Marca_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Marca] WHERE CONVERT(nvarchar(4000),[CodigoMarca]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoMarca];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Marca_Insertar] @CodigoMarca int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Marca]([CodigoMarca],[Descripcion]) OUTPUT INSERTED.[CodigoMarca] VALUES(@CodigoMarca,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Marca_Actualizar] @CodigoMarca int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Marca] SET [Descripcion]=@Descripcion WHERE [CodigoMarca]=@CodigoMarca; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Marca_Eliminar] @CodigoMarca int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Marca] WHERE [CodigoMarca]=@CodigoMarca; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Linea_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Linea] ORDER BY [CodigoMarca],[CodigoLinea];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Linea_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Linea] WHERE CONVERT(nvarchar(4000),[CodigoMarca]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoLinea]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoMarca],[CodigoLinea];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Linea_Insertar] @CodigoMarca int,
 @CodigoLinea int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Linea]([CodigoMarca],[CodigoLinea],[Descripcion]) OUTPUT INSERTED.[CodigoMarca],INSERTED.[CodigoLinea] VALUES(@CodigoMarca,@CodigoLinea,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Linea_Actualizar] @CodigoMarca int,
 @CodigoLinea int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Linea] SET [Descripcion]=@Descripcion WHERE [CodigoMarca]=@CodigoMarca AND [CodigoLinea]=@CodigoLinea; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Linea_Eliminar] @CodigoMarca int,
 @CodigoLinea int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Linea] WHERE [CodigoMarca]=@CodigoMarca AND [CodigoLinea]=@CodigoLinea; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Agencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Agencia] ORDER BY [CodigoAgencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Agencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Agencia] WHERE CONVERT(nvarchar(4000),[CodigoAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Nombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Region]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoAgencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Agencia_Insertar] @Nombre nvarchar(128),
 @Region nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Agencia]([Nombre],[Region]) OUTPUT INSERTED.[CodigoAgencia] AS Id VALUES(@Nombre,@Region);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Agencia_Actualizar] @CodigoAgencia int,
 @Nombre nvarchar(128),
 @Region nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Agencia] SET [Nombre]=@Nombre,[Region]=@Region WHERE [CodigoAgencia]=@CodigoAgencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Agencia_Eliminar] @CodigoAgencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Agencia] WHERE [CodigoAgencia]=@CodigoAgencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Persona_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Persona] ORDER BY [CodigoPersona];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Persona_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Persona] WHERE CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[DPI]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[NIT]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PrimerNombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SegundoNombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PrimerApellido]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SegundoApellido]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaNacimiento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Genero]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CorreoElectronico]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPersona];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Persona_Insertar] @DPI varchar(13) = NULL,
 @NIT varchar(20) = NULL,
 @PrimerNombre nvarchar(64),
 @SegundoNombre nvarchar(64) = NULL,
 @PrimerApellido nvarchar(64),
 @SegundoApellido nvarchar(64) = NULL,
 @FechaNacimiento date = NULL,
 @Genero char(1) = NULL,
 @CorreoElectronico nvarchar(254) = NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF @FechaNacimiento>=CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51001,''''La fecha de nacimiento debe ser anterior a hoy.'''',1;
INSERT dbo.[Persona]([DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) OUTPUT INSERTED.[CodigoPersona] AS Id VALUES(@DPI,@NIT,@PrimerNombre,@SegundoNombre,@PrimerApellido,@SegundoApellido,@FechaNacimiento,@Genero,@CorreoElectronico);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Persona_Actualizar] @CodigoPersona int,
 @DPI varchar(13) = NULL,
 @NIT varchar(20) = NULL,
 @PrimerNombre nvarchar(64),
 @SegundoNombre nvarchar(64) = NULL,
 @PrimerApellido nvarchar(64),
 @SegundoApellido nvarchar(64) = NULL,
 @FechaNacimiento date = NULL,
 @Genero char(1) = NULL,
 @CorreoElectronico nvarchar(254) = NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF @FechaNacimiento>=CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51001,''''La fecha de nacimiento debe ser anterior a hoy.'''',1;IF EXISTS(SELECT 1 FROM dbo.Deudor WHERE CodigoPersona=@CodigoPersona) AND (@DPI IS NULL OR @NIT IS NULL OR @CorreoElectronico IS NULL OR @FechaNacimiento IS NULL) THROW 51009,''''No quite datos obligatorios de un cliente.'''',1; IF EXISTS(SELECT 1 FROM dbo.Fiador WHERE CodigoPersona=@CodigoPersona) AND (@DPI IS NULL OR @NIT IS NULL OR @CorreoElectronico IS NULL) THROW 51010,''''No quite datos obligatorios de un fiador.'''',1; IF EXISTS(SELECT 1 FROM dbo.Vendedor WHERE CodigoPersona=@CodigoPersona) AND @DPI IS NULL THROW 51011,''''El vendedor requiere DPI.'''',1;
UPDATE dbo.[Persona] SET [DPI]=@DPI,[NIT]=@NIT,[PrimerNombre]=@PrimerNombre,[SegundoNombre]=@SegundoNombre,[PrimerApellido]=@PrimerApellido,[SegundoApellido]=@SegundoApellido,[FechaNacimiento]=@FechaNacimiento,[Genero]=@Genero,[CorreoElectronico]=@CorreoElectronico WHERE [CodigoPersona]=@CodigoPersona; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Persona_Eliminar] @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Persona] WHERE [CodigoPersona]=@CodigoPersona; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Telefono_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Telefono] ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Telefono_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Telefono] WHERE CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Correlativo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoTelefono]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Numero]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Telefono_Insertar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoTelefono int,
 @Numero varchar(32)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Telefono]([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) OUTPUT INSERTED.[CodigoPersona],INSERTED.[Correlativo] VALUES(@CodigoPersona,@Correlativo,@CodigoTipoTelefono,@Numero);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Telefono_Actualizar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoTelefono int,
 @Numero varchar(32)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Telefono] SET [CodigoTipoTelefono]=@CodigoTipoTelefono,[Numero]=@Numero WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Telefono_Eliminar] @CodigoPersona int,
 @Correlativo smallint
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Telefono] WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Direccion_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Direccion] ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Direccion_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Direccion] WHERE CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Correlativo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoDireccion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoDepartamento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoMunicipio]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Detalle]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Direccion_Insertar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoDireccion int,
 @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Detalle nvarchar(300)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Direccion]([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) OUTPUT INSERTED.[CodigoPersona],INSERTED.[Correlativo] VALUES(@CodigoPersona,@Correlativo,@CodigoTipoDireccion,@CodigoDepartamento,@CodigoMunicipio,@Detalle);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Direccion_Actualizar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoDireccion int,
 @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Detalle nvarchar(300)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Direccion] SET [CodigoTipoDireccion]=@CodigoTipoDireccion,[CodigoDepartamento]=@CodigoDepartamento,[CodigoMunicipio]=@CodigoMunicipio,[Detalle]=@Detalle WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Direccion_Eliminar] @CodigoPersona int,
 @Correlativo smallint
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Direccion] WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Deudor_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Deudor] ORDER BY [CodigoDeudor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Deudor_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Deudor] WHERE CONVERT(nvarchar(4000),[CodigoDeudor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDeudor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Deudor_Insertar] @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL AND FechaNacimiento IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;
INSERT dbo.[Deudor]([CodigoPersona]) OUTPUT INSERTED.[CodigoDeudor] AS Id VALUES(@CodigoPersona);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Deudor_Actualizar] @CodigoDeudor int,
 @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL AND FechaNacimiento IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;IF EXISTS(SELECT 1 FROM dbo.Deudor WHERE CodigoDeudor=@CodigoDeudor AND CodigoPersona<>@CodigoPersona) THROW 51013,''''No se cambia la identidad de un rol; registre otro si corresponde.'''',1;
UPDATE dbo.[Deudor] SET [CodigoPersona]=@CodigoPersona WHERE [CodigoDeudor]=@CodigoDeudor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Deudor_Eliminar] @CodigoDeudor int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Deudor] WHERE [CodigoDeudor]=@CodigoDeudor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Referencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Referencia] ORDER BY [CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Referencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Referencia] WHERE CONVERT(nvarchar(4000),[CodigoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[LugarTrabajo]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Referencia_Insertar] @CodigoPersona int,
 @LugarTrabajo nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Referencia]([CodigoPersona],[LugarTrabajo]) OUTPUT INSERTED.[CodigoReferencia] AS Id VALUES(@CodigoPersona,@LugarTrabajo);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Referencia_Actualizar] @CodigoReferencia int,
 @CodigoPersona int,
 @LugarTrabajo nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Referencia WHERE CodigoReferencia=@CodigoReferencia AND CodigoPersona<>@CodigoPersona) THROW 51015,''''No cambie la persona de una referencia; registre otra referencia.'''',1;
UPDATE dbo.[Referencia] SET [CodigoPersona]=@CodigoPersona,[LugarTrabajo]=@LugarTrabajo WHERE [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Referencia_Eliminar] @CodigoReferencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Referencia] WHERE [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleReferencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[DetalleReferencia] ORDER BY [CodigoDeudor],[CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleReferencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[DetalleReferencia] WHERE CONVERT(nvarchar(4000),[CodigoDeudor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ParentescoRelacion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDeudor],[CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleReferencia_Insertar] @CodigoDeudor int,
 @CodigoReferencia int,
 @CodigoTipoReferencia int,
 @ParentescoRelacion nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Referencia r ON r.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@CodigoDeudor AND r.CodigoReferencia=@CodigoReferencia) THROW 51002,''''El cliente no puede ser su propia referencia.'''',1;
INSERT dbo.[DetalleReferencia]([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) OUTPUT INSERTED.[CodigoDeudor],INSERTED.[CodigoReferencia] VALUES(@CodigoDeudor,@CodigoReferencia,@CodigoTipoReferencia,@ParentescoRelacion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleReferencia_Actualizar] @CodigoDeudor int,
 @CodigoReferencia int,
 @CodigoTipoReferencia int,
 @ParentescoRelacion nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Referencia r ON r.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@CodigoDeudor AND r.CodigoReferencia=@CodigoReferencia) THROW 51002,''''El cliente no puede ser su propia referencia.'''',1;
UPDATE dbo.[DetalleReferencia] SET [CodigoTipoReferencia]=@CodigoTipoReferencia,[ParentescoRelacion]=@ParentescoRelacion WHERE [CodigoDeudor]=@CodigoDeudor AND [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleReferencia_Eliminar] @CodigoDeudor int,
 @CodigoReferencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[DetalleReferencia] WHERE [CodigoDeudor]=@CodigoDeudor AND [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Fiador_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Fiador] ORDER BY [CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Fiador_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Fiador] WHERE CONVERT(nvarchar(4000),[CodigoFiador]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Fiador_Insertar] @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;
INSERT dbo.[Fiador]([CodigoPersona]) OUTPUT INSERTED.[CodigoFiador] AS Id VALUES(@CodigoPersona);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Fiador_Actualizar] @CodigoFiador int,
 @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;IF EXISTS(SELECT 1 FROM dbo.Fiador WHERE CodigoFiador=@CodigoFiador AND CodigoPersona<>@CodigoPersona) THROW 51013,''''No se cambia la identidad de un rol; registre otro si corresponde.'''',1;
UPDATE dbo.[Fiador] SET [CodigoPersona]=@CodigoPersona WHERE [CodigoFiador]=@CodigoFiador; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Fiador_Eliminar] @CodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Fiador] WHERE [CodigoFiador]=@CodigoFiador; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Vendedor_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Vendedor] ORDER BY [CodigoVendedor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Vendedor_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Vendedor] WHERE CONVERT(nvarchar(4000),[CodigoVendedor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoEmpleado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoVendedor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Vendedor_Insertar] @CodigoEmpleado varchar(30),
 @CodigoPersona int,
 @CodigoAgencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;
INSERT dbo.[Vendedor]([CodigoEmpleado],[CodigoPersona],[CodigoAgencia]) OUTPUT INSERTED.[CodigoVendedor] AS Id VALUES(@CodigoEmpleado,@CodigoPersona,@CodigoAgencia);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Vendedor_Actualizar] @CodigoVendedor int,
 @CodigoEmpleado varchar(30),
 @CodigoPersona int,
 @CodigoAgencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;IF EXISTS(SELECT 1 FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor AND CodigoPersona<>@CodigoPersona) THROW 51013,''''No se cambia la identidad de un rol; registre otro si corresponde.'''',1;
UPDATE dbo.[Vendedor] SET [CodigoEmpleado]=@CodigoEmpleado,[CodigoPersona]=@CodigoPersona,[CodigoAgencia]=@CodigoAgencia WHERE [CodigoVendedor]=@CodigoVendedor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Vendedor_Eliminar] @CodigoVendedor int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Vendedor] WHERE [CodigoVendedor]=@CodigoVendedor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Garantia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Garantia] ORDER BY [CodigoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Garantia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Garantia] WHERE CONVERT(nvarchar(4000),[CodigoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[VIN]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoMarca]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoLinea]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Anio]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ValorAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Placa]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[EsNuevo]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Garantia_Insertar] @VIN varchar(17),
 @CodigoMarca int,
 @CodigoLinea int,
 @Anio smallint,
 @ValorAgencia decimal(18,2),
 @Placa varchar(20) = NULL,
 @CodigoTipoGarantia int,
 @EsNuevo bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Garantia]([VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) OUTPUT INSERTED.[CodigoGarantia] AS Id VALUES(@VIN,@CodigoMarca,@CodigoLinea,@Anio,@ValorAgencia,@Placa,@CodigoTipoGarantia,@EsNuevo);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Garantia_Actualizar] @CodigoGarantia int,
 @VIN varchar(17),
 @CodigoMarca int,
 @CodigoLinea int,
 @Anio smallint,
 @ValorAgencia decimal(18,2),
 @Placa varchar(20) = NULL,
 @CodigoTipoGarantia int,
 @EsNuevo bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia AND FechaAprobacion IS NOT NULL) THROW 51005,''''La garantia tiene historial contractual: conserve sus datos.'''',1;
UPDATE dbo.[Garantia] SET [VIN]=@VIN,[CodigoMarca]=@CodigoMarca,[CodigoLinea]=@CodigoLinea,[Anio]=@Anio,[ValorAgencia]=@ValorAgencia,[Placa]=@Placa,[CodigoTipoGarantia]=@CodigoTipoGarantia,[EsNuevo]=@EsNuevo WHERE [CodigoGarantia]=@CodigoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Garantia_Eliminar] @CodigoGarantia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Garantia] WHERE [CodigoGarantia]=@CodigoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[ParametroCredito_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[ParametroCredito] ORDER BY [CodigoParametro];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[ParametroCredito_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[ParametroCredito] WHERE CONVERT(nvarchar(4000),[CodigoParametro]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Nombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Activo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaAnual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoMensual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[EngancheMinimo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ComisionPredeterminada]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[DepreciacionInicial]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoParametro];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[ParametroCredito_Insertar] @Nombre nvarchar(100),
 @Activo bit,
 @TasaAnual decimal(9,6),
 @ManejoMensual decimal(18,2),
 @TasaSeguroAuto decimal(9,6),
 @TasaSeguroVida decimal(9,6),
 @EngancheMinimo decimal(9,6),
 @ComisionPredeterminada decimal(9,6),
 @DepreciacionInicial decimal(9,6)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[ParametroCredito]([Nombre],[Activo],[TasaAnual],[ManejoMensual],[TasaSeguroAuto],[TasaSeguroVida],[EngancheMinimo],[ComisionPredeterminada],[DepreciacionInicial]) OUTPUT INSERTED.[CodigoParametro] AS Id VALUES(@Nombre,@Activo,@TasaAnual,@ManejoMensual,@TasaSeguroAuto,@TasaSeguroVida,@EngancheMinimo,@ComisionPredeterminada,@DepreciacionInicial);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[ParametroCredito_Actualizar] @CodigoParametro int,
 @Nombre nvarchar(100),
 @Activo bit,
 @TasaAnual decimal(9,6),
 @ManejoMensual decimal(18,2),
 @TasaSeguroAuto decimal(9,6),
 @TasaSeguroVida decimal(9,6),
 @EngancheMinimo decimal(9,6),
 @ComisionPredeterminada decimal(9,6),
 @DepreciacionInicial decimal(9,6)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[ParametroCredito] SET [Nombre]=@Nombre,[Activo]=@Activo,[TasaAnual]=@TasaAnual,[ManejoMensual]=@ManejoMensual,[TasaSeguroAuto]=@TasaSeguroAuto,[TasaSeguroVida]=@TasaSeguroVida,[EngancheMinimo]=@EngancheMinimo,[ComisionPredeterminada]=@ComisionPredeterminada,[DepreciacionInicial]=@DepreciacionInicial WHERE [CodigoParametro]=@CodigoParametro; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[ParametroCredito_Eliminar] @CodigoParametro int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[ParametroCredito] WHERE [CodigoParametro]=@CodigoParametro; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_CreditoResumen] ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_CreditoResumen] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoDeudor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoVendedor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoParametro]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Plazo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PrecioContado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Enganche]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[EngancheMinimo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaAnual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoMensual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PorcentajeComision]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FiadoresRequeridos]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Estado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaAprobacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[AprobadoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaPresentacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PresentadoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[MotivoAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[AnuladoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[MontoFinanciado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalIntereses]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalNetoRecaudable]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[CreditoFiador_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[CreditoFiador] ORDER BY [NumeroCredito],[CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[CreditoFiador_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[CreditoFiador] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoFiador]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito],[CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[CreditoFiador_Insertar] @NumeroCredito varchar(20),
 @CodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.Deudor d ON d.CodigoDeudor=c.CodigoDeudor JOIN dbo.Fiador f ON f.CodigoPersona=d.CodigoPersona WHERE c.NumeroCredito=@NumeroCredito AND f.CodigoFiador=@CodigoFiador) THROW 51004,''''El cliente no puede ser fiador de su propio credito.'''',1;
INSERT dbo.[CreditoFiador]([NumeroCredito],[CodigoFiador]) OUTPUT INSERTED.[NumeroCredito],INSERTED.[CodigoFiador] VALUES(@NumeroCredito,@CodigoFiador);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[CreditoFiador_Actualizar] @NumeroCredito varchar(20),
 @CodigoFiador int, @NuevoCodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.Deudor d ON d.CodigoDeudor=c.CodigoDeudor JOIN dbo.Fiador f ON f.CodigoPersona=d.CodigoPersona WHERE c.NumeroCredito=@NumeroCredito AND f.CodigoFiador=@CodigoFiador) THROW 51004,''''El cliente no puede ser fiador de su propio credito.'''',1;
DECLARE @Anterior int=@CodigoFiador; SET @CodigoFiador=@NuevoCodigoFiador;IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.Deudor d ON d.CodigoDeudor=c.CodigoDeudor JOIN dbo.Fiador f ON f.CodigoPersona=d.CodigoPersona WHERE c.NumeroCredito=@NumeroCredito AND f.CodigoFiador=@CodigoFiador) THROW 51004,''''El cliente no puede ser fiador de su propio credito.'''',1; UPDATE dbo.[CreditoFiador] SET [CodigoFiador]=@NuevoCodigoFiador WHERE [NumeroCredito]=@NumeroCredito AND [CodigoFiador]=@Anterior; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[CreditoFiador_Eliminar] @NumeroCredito varchar(20),
 @CodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;
DELETE dbo.[CreditoFiador] WHERE [NumeroCredito]=@NumeroCredito AND [CodigoFiador]=@CodigoFiador; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Depreciacion_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_DepreciacionCalculada] ORDER BY [CodigoDepreciacion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Depreciacion_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_DepreciacionCalculada] WHERE CONVERT(nvarchar(4000),[CodigoDepreciacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaValoracion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ValorOriginal]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Porcentaje]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Observacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ValorDepreciado]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDepreciacion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Depreciacion_Insertar] @CodigoGarantia int,
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
  IF @FechaValoracion>CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51006,''''La valoracion no puede estar en el futuro.'''',1;
INSERT dbo.[Depreciacion]([CodigoGarantia],[FechaValoracion],[ValorOriginal],[Porcentaje],[Observacion]) OUTPUT INSERTED.[CodigoDepreciacion] AS Id VALUES(@CodigoGarantia,@FechaValoracion,@ValorOriginal,@Porcentaje,@Observacion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Depreciacion_Actualizar] @CodigoDepreciacion int,
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
  IF @FechaValoracion>CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51006,''''La valoracion no puede estar en el futuro.'''',1;IF EXISTS(SELECT 1 FROM dbo.Depreciacion d JOIN dbo.Credito c ON c.CodigoGarantia=d.CodigoGarantia WHERE d.CodigoDepreciacion=@CodigoDepreciacion AND c.FechaAprobacion IS NOT NULL) THROW 51014,''''La valoracion forma parte del historial; registre una nueva valoracion.'''',1;
UPDATE dbo.[Depreciacion] SET [CodigoGarantia]=@CodigoGarantia,[FechaValoracion]=@FechaValoracion,[ValorOriginal]=@ValorOriginal,[Porcentaje]=@Porcentaje,[Observacion]=@Observacion WHERE [CodigoDepreciacion]=@CodigoDepreciacion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Depreciacion_Eliminar] @CodigoDepreciacion int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Depreciacion d JOIN dbo.Credito c ON c.CodigoGarantia=d.CodigoGarantia WHERE d.CodigoDepreciacion=@CodigoDepreciacion AND c.FechaAprobacion IS NOT NULL) THROW 51014,''''La valoracion forma parte del historial; registre una nueva valoracion.'''',1;
DELETE dbo.[Depreciacion] WHERE [CodigoDepreciacion]=@CodigoDepreciacion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleCuota_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_CuotaDesglosada] ORDER BY [NumeroCredito],[Cuota];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleCuota_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_CuotaDesglosada] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Cuota]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaVencimiento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Capital]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Interes]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoCuenta]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Total]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito],[Cuota];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleCuota_Insertar] @NumeroCredito varchar(20),
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
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;
INSERT dbo.[DetalleCuota]([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) OUTPUT INSERTED.[NumeroCredito],INSERTED.[Cuota] VALUES(@NumeroCredito,@Cuota,@FechaVencimiento,@Capital,@Interes);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleCuota_Actualizar] @NumeroCredito varchar(20),
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
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;
UPDATE dbo.[DetalleCuota] SET [FechaVencimiento]=@FechaVencimiento,[Capital]=@Capital,[Interes]=@Interes WHERE [NumeroCredito]=@NumeroCredito AND [Cuota]=@Cuota; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetalleCuota_Eliminar] @NumeroCredito varchar(20),
 @Cuota smallint
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;
DELETE dbo.[DetalleCuota] WHERE [NumeroCredito]=@NumeroCredito AND [Cuota]=@Cuota; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetallePago_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_PagoDesglosado] ORDER BY [CodigoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetallePago_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_PagoDesglosado] WHERE CONVERT(nvarchar(4000),[CodigoPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Comprobante]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Cuota]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ReferenciaBancaria]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Monto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Capital]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Interes]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoCuenta]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[RegistradoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[MotivoAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[AnuladoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Observacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PorcentajeComision]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Comision]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[ResumenCredito_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[ResumenCredito] ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[ResumenCredito_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[ResumenCredito] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalIntereses]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalNetoRecaudable]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Insertar] @NumeroCredito varchar(20), @CodigoDeudor int, @CodigoGarantia int,
 @CodigoVendedor int, @Enganche decimal(18,2), @Plazo smallint=60,
 @FiadoresRequeridos smallint=1, @PorcentajeComision decimal(9,6)=NULL,
 @CodigoParametro int=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF @Plazo NOT IN(12,24,36,48,60) OR @Plazo IS NULL THROW 51100,''''Plazo permitido: 12,24,36,48 o 60 meses.'''',1;
 IF @FiadoresRequeridos IS NULL OR @FiadoresRequeridos<0 THROW 51101,''''Indique cuantos fiadores requiere el comite; cero si no requiere.'''',1;
 DECLARE @Precio decimal(18,2),@Agencia int,@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6),@Minimo decimal(9,6),@Comision decimal(9,6);
 SELECT @Precio=ValorAgencia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia;
 SELECT @Agencia=CodigoAgencia FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor;
 IF @Precio IS NULL OR @Agencia IS NULL THROW 51102,''''Vehiculo o vendedor inexistente.'''',1;
 IF @CodigoParametro IS NULL SELECT @CodigoParametro=CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1;
 SELECT @Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida,@Minimo=EngancheMinimo,@Comision=ComisionPredeterminada FROM dbo.ParametroCredito WITH(HOLDLOCK) WHERE CodigoParametro=@CodigoParametro AND Activo=1;
 IF @Tasa IS NULL THROW 51103,''''Se requiere una configuracion activa.'''',1;
 IF @Enganche IS NULL OR @Enganche<CEILING(@Precio*@Minimo*100)/100 OR @Enganche>=@Precio THROW 51104,''''Enganche inferior al minimo o sin monto pendiente por financiar.'''',1;
 SET @Comision=COALESCE(@PorcentajeComision,@Comision);
 IF @Comision NOT BETWEEN 0 AND 1 THROW 51105,''''Comision fuera de rango.'''',1;

 INSERT dbo.Credito(NumeroCredito,CodigoDeudor,CodigoGarantia,CodigoVendedor,CodigoAgencia,CodigoParametro,Plazo,PrecioContado,Enganche,EngancheMinimo,TasaAnual,ManejoMensual,TasaSeguroAuto,TasaSeguroVida,PorcentajeComision,FiadoresRequeridos)
 VALUES(@NumeroCredito,@CodigoDeudor,@CodigoGarantia,@CodigoVendedor,@Agencia,@CodigoParametro,@Plazo,@Precio,@Enganche,@Minimo,@Tasa,@Manejo,@Auto,@Vida,@Comision,@FiadoresRequeridos);
 SELECT * FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Actualizar] @NumeroCredito varchar(20), @CodigoDeudor int, @CodigoGarantia int,
 @CodigoVendedor int, @Enganche decimal(18,2), @Plazo smallint=60,
 @FiadoresRequeridos smallint=1, @PorcentajeComision decimal(9,6)=NULL,
 @CodigoParametro int=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51106,''''Solo se editan las condiciones de un credito borrador.'''',1;

 IF @Plazo NOT IN(12,24,36,48,60) OR @Plazo IS NULL THROW 51100,''''Plazo permitido: 12,24,36,48 o 60 meses.'''',1;
 IF @FiadoresRequeridos IS NULL OR @FiadoresRequeridos<0 THROW 51101,''''Indique cuantos fiadores requiere el comite; cero si no requiere.'''',1;
 DECLARE @Precio decimal(18,2),@Agencia int,@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6),@Minimo decimal(9,6),@Comision decimal(9,6);
 SELECT @Precio=ValorAgencia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia;
 SELECT @Agencia=CodigoAgencia FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor;
 IF @Precio IS NULL OR @Agencia IS NULL THROW 51102,''''Vehiculo o vendedor inexistente.'''',1;
 IF @CodigoParametro IS NULL SELECT @CodigoParametro=CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1;
 SELECT @Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida,@Minimo=EngancheMinimo,@Comision=ComisionPredeterminada FROM dbo.ParametroCredito WITH(HOLDLOCK) WHERE CodigoParametro=@CodigoParametro AND Activo=1;
 IF @Tasa IS NULL THROW 51103,''''Se requiere una configuracion activa.'''',1;
 IF @Enganche IS NULL OR @Enganche<CEILING(@Precio*@Minimo*100)/100 OR @Enganche>=@Precio THROW 51104,''''Enganche inferior al minimo o sin monto pendiente por financiar.'''',1;
 SET @Comision=COALESCE(@PorcentajeComision,@Comision);
 IF @Comision NOT BETWEEN 0 AND 1 THROW 51105,''''Comision fuera de rango.'''',1;

 IF EXISTS(SELECT 1 FROM dbo.CreditoFiador cf JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Deudor d ON d.CodigoPersona=f.CodigoPersona WHERE cf.NumeroCredito=@NumeroCredito AND d.CodigoDeudor=@CodigoDeudor) THROW 51107,''''El nuevo cliente es fiador de este credito.'''',1;
 UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL,CodigoDeudor=@CodigoDeudor,CodigoGarantia=@CodigoGarantia,CodigoVendedor=@CodigoVendedor,CodigoAgencia=@Agencia,CodigoParametro=@CodigoParametro,Plazo=@Plazo,PrecioContado=@Precio,Enganche=@Enganche,EngancheMinimo=@Minimo,TasaAnual=@Tasa,ManejoMensual=@Manejo,TasaSeguroAuto=@Auto,TasaSeguroVida=@Vida,PorcentajeComision=@Comision,FiadoresRequeridos=@FiadoresRequeridos WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Eliminar] @NumeroCredito varchar(20)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51108,''''Solo se borra un credito borrador sin dependencias. Los aprobados se anulan.'''',1; DELETE dbo.Credito WHERE NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Aprobar] @NumeroCredito varchar(20),@Responsable nvarchar(100),
 @FechaAprobacion datetime2(0)=NULL,@PorcentajeDepreciacion decimal(9,6)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51109,''''Indique el responsable del comite.'''',1;
 SET @FechaAprobacion=COALESCE(@FechaAprobacion,dbo.fn_AhoraGuatemala());
 IF @FechaAprobacion>dbo.fn_AhoraGuatemala() THROW 51110,''''La aprobacion no puede estar en el futuro.'''',1;
 DECLARE @Cliente int,@Vehiculo int,@Plazo smallint,@Fiadores smallint,@Parametro int,@Monto decimal(18,2),@Precio decimal(18,2),@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6);
 SELECT @Cliente=CodigoDeudor,@Vehiculo=CodigoGarantia,@Plazo=Plazo,@Fiadores=FiadoresRequeridos,@Parametro=CodigoParametro,@Monto=PrecioContado-Enganche,@Precio=PrecioContado,@Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida
 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''';
 IF @Cliente IS NULL THROW 51111,''''El credito no existe o ya fue aprobado.'''',1;
 DECLARE @Vin varchar(17);
 SELECT @Vin=VIN FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo;
 IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo AND Estado=''''VIGENTE'''') THROW 51112,''''El vehiculo ya respalda un credito activo.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE CodigoGarantia=@Vehiculo AND FechaAnulacion>@FechaAprobacion) THROW 51113,''''La aprobacion no puede preceder la anulacion del contrato anterior.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito WHERE c.CodigoGarantia=@Vehiculo AND p.FechaPago>@FechaAprobacion) THROW 51114,''''La aprobacion no puede preceder pagos del contrato anterior del vehiculo.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@Cliente AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND p.FechaNacimiento IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=p.CodigoPersona)) THROW 51115,''''Complete identificacion, NIT, nacimiento, correo, telefono y direccion del cliente.'''',1;
 IF (SELECT COUNT(*) FROM dbo.DetalleReferencia dr WITH(HOLDLOCK) JOIN dbo.Referencia r ON r.CodigoReferencia=dr.CodigoReferencia JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor WHERE dr.CodigoDeudor=@Cliente AND r.CodigoPersona<>d.CodigoPersona AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=r.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=r.CodigoPersona))<3 THROW 51116,''''Se requieren tres referencias distintas y completas con telefono y direccion.'''',1;
 IF (SELECT COUNT(*) FROM dbo.CreditoFiador cf WITH(HOLDLOCK) JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona JOIN dbo.Deudor d ON d.CodigoDeudor=@Cliente WHERE cf.NumeroCredito=@NumeroCredito AND f.CodigoPersona<>d.CodigoPersona AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona))<@Fiadores THROW 51117,''''Complete la cantidad de fiadores y sus datos obligatorios.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@NumeroCredito AND FechaPresentacion IS NOT NULL) THROW 51127,''''Presente la solicitud completa antes de aprobar.'''',1;
 IF @PorcentajeDepreciacion IS NULL SELECT @PorcentajeDepreciacion=DepreciacionInicial FROM dbo.ParametroCredito WHERE CodigoParametro=@Parametro;
 IF @PorcentajeDepreciacion IS NULL OR @PorcentajeDepreciacion NOT BETWEEN 0.15 AND 0.20 THROW 51118,''''La depreciacion inicial debe estar entre 15 y 20 por ciento.'''',1;
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
  IF @K<0 THROW 51119,''''El calculo produjo amortizacion negativa.'''',1;
  INSERT dbo.DetalleCuota(NumeroCredito,Cuota,FechaVencimiento,Capital,Interes)
  VALUES(@NumeroCredito,@N,DATEADD(month,@N,CONVERT(date,@FechaAprobacion)),@K,@I);
  SET @Saldo=@Saldo-@K; SET @N=@N+1;
 END;
 IF @Saldo<>0 THROW 51120,''''El plan no liquida el capital.'''',1;
 INSERT dbo.Depreciacion(CodigoGarantia,FechaValoracion,ValorOriginal,Porcentaje,Observacion) VALUES(@Vehiculo,CONVERT(date,@FechaAprobacion),@Precio,@PorcentajeDepreciacion,N''''Valoracion inicial al aprobar ''''+@NumeroCredito);
 INSERT dbo.ResumenCredito(NumeroCredito,TotalIntereses,TotalNetoRecaudable)
 SELECT @NumeroCredito,SUM(Interes),SUM(Total) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito;
 UPDATE dbo.Credito SET Estado=''''VIGENTE'''',FechaAprobacion=@FechaAprobacion,AprobadoPor=@Responsable WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito ORDER BY Cuota;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Anular] @NumeroCredito varchar(20),@Motivo nvarchar(300),@Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NULLIF(LTRIM(RTRIM(@Motivo)),N'''''''') IS NULL OR NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51121,''''Indique motivo y responsable.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado IN(''''BORRADOR'''',''''VIGENTE'''')) THROW 51122,''''El credito no puede anularse en su estado actual.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND FechaAnulacion IS NULL) THROW 51123,''''El credito tiene pagos efectivos: resuelvalos antes de anular.'''',1;
 UPDATE dbo.Credito SET Estado=''''ANULADO'''',FechaAnulacion=dbo.fn_AhoraGuatemala(),MotivoAnulacion=@Motivo,AnuladoPor=@Responsable WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetallePago_Insertar] @NumeroCredito varchar(20),@Cuota smallint,@Monto decimal(18,2),@CodigoTipoPago int,
 @Responsable nvarchar(100),@ReferenciaBancaria nvarchar(100)=NULL,@FechaPago datetime2(0)=NULL,@Observacion nvarchar(300)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF @Monto IS NULL OR @Monto<=0 THROW 51200,''''El abono debe ser positivo.'''',1;
 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51201,''''Indique quien registra el pago.'''',1;
 SET @FechaPago=COALESCE(@FechaPago,dbo.fn_AhoraGuatemala());
 IF @FechaPago>dbo.fn_AhoraGuatemala() THROW 51202,''''No se registran pagos futuros.'''',1;
 DECLARE @Comision decimal(9,6),@Aprobacion datetime2(0),@Requiere bit;
 SELECT @Comision=PorcentajeComision,@Aprobacion=FechaAprobacion FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''VIGENTE'''';
 IF @Comision IS NULL THROW 51203,''''El credito no esta vigente.'''',1;
 IF @FechaPago<@Aprobacion THROW 51204,''''El pago no puede preceder la aprobacion.'''',1;
 -- No insertar movimientos retroactivos detras de movimientos ya registrados: preserva saldos historicos.
 IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND (FechaPago>@FechaPago OR FechaAnulacion>@FechaPago)) THROW 51205,''''Registre los movimientos del credito en orden cronologico.'''',1;
 SELECT @Requiere=RequiereReferencia FROM dbo.TipoPago WHERE CodigoTipoPago=@CodigoTipoPago;
 IF @Requiere IS NULL THROW 51206,''''Medio de pago inexistente.'''',1;
 IF @Requiere=1 AND NULLIF(LTRIM(RTRIM(@ReferenciaBancaria)),N'''''''') IS NULL THROW 51207,''''Este medio requiere boleta o autorizacion bancaria.'''',1;
 DECLARE @Pendiente TABLE(Orden int PRIMARY KEY,Saldo decimal(18,2),Centavos bigint,Fraccion decimal(28,12));
 INSERT @Pendiente(Orden,Saldo)
 SELECT x.Orden,x.Importe FROM dbo.vw_CuotaDesglosada q
 OUTER APPLY(SELECT SUM(Capital) Capital,SUM(Interes) Interes,SUM(ManejoCuenta) ManejoCuenta,SUM(SeguroAuto) SeguroAuto,SUM(SeguroVida) SeguroVida FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND Cuota=@Cuota AND FechaAnulacion IS NULL)p
 CROSS APPLY(VALUES(1,q.Capital-ISNULL(p.Capital,0)),(2,q.Interes-ISNULL(p.Interes,0)),(3,q.ManejoCuenta-ISNULL(p.ManejoCuenta,0)),(4,q.SeguroAuto-ISNULL(p.SeguroAuto,0)),(5,q.SeguroVida-ISNULL(p.SeguroVida,0)))x(Orden,Importe)
 WHERE q.NumeroCredito=@NumeroCredito AND q.Cuota=@Cuota;
 DECLARE @Saldo decimal(18,2)=(SELECT SUM(Saldo) FROM @Pendiente);
 IF @Saldo IS NULL THROW 51208,''''Cuota inexistente.'''',1;
 IF @Monto>@Saldo THROW 51209,''''El pago supera el saldo pendiente de la cuota. No se registro ningun importe.'''',1;
 IF @Saldo<=0 THROW 51210,''''La cuota ya esta pagada.'''',1;
 -- Distribucion proporcional en centavos por mayor residuo, con desempate estable.
 UPDATE @Pendiente SET Centavos=CONVERT(bigint,FLOOR((@Monto*100)*(Saldo/@Saldo))),Fraccion=(@Monto*100)*(Saldo/@Saldo)-FLOOR((@Monto*100)*(Saldo/@Saldo));
 DECLARE @Restantes bigint=CONVERT(bigint,@Monto*100)-(SELECT SUM(Centavos) FROM @Pendiente);
 WHILE @Restantes>0
 BEGIN
  DECLARE @Orden int;
  SET @Orden=NULL;
  SELECT TOP(1) @Orden=Orden FROM @Pendiente WHERE Centavos<CONVERT(bigint,Saldo*100) ORDER BY Fraccion DESC,Orden;
  IF @Orden IS NULL THROW 51211,''''No se pudo distribuir el abono.'''',1;
  UPDATE @Pendiente SET Centavos=Centavos+1,Fraccion=-1 WHERE Orden=@Orden;
  SET @Restantes=@Restantes-1;
 END;
 IF EXISTS(SELECT 1 FROM @Pendiente WHERE Centavos<0 OR Centavos>CONVERT(bigint,Saldo*100)) THROW 51212,''''Distribucion fuera del saldo de un componente.'''',1;
 IF (SELECT SUM(Centavos) FROM @Pendiente)<>CONVERT(bigint,@Monto*100) THROW 51219,''''El desglose no coincide con el importe recibido.'''',1;
 INSERT dbo.DetallePago(NumeroCredito,Cuota,FechaPago,CodigoTipoPago,ReferenciaBancaria,Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,RegistradoPor,Observacion)
 SELECT @NumeroCredito,@Cuota,@FechaPago,@CodigoTipoPago,@ReferenciaBancaria,@Monto,
 MAX(CASE WHEN Orden=1 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=2 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=3 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=4 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=5 THEN Centavos/100.0 END),@Responsable,@Observacion FROM @Pendiente;
 DECLARE @Id bigint=SCOPE_IDENTITY();
 IF (SELECT SUM(Total) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)=(SELECT SUM(Monto) FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND FechaAnulacion IS NULL)
 UPDATE dbo.Credito SET Estado=''''LIQUIDADO'''' WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_PagoDesglosado WHERE CodigoPago=@Id;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetallePago_Actualizar] @CodigoPago bigint,@Observacion nvarchar(300)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 -- Solo anotaciones: una correccion financiera requiere anular y registrar un nuevo pago.
 UPDATE dbo.DetallePago SET Observacion=@Observacion WHERE CodigoPago=@CodigoPago;
 IF @@ROWCOUNT=0 THROW 51213,''''Pago inexistente.'''',1;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetallePago_Anular] @CodigoPago bigint,@Motivo nvarchar(300),@Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NULLIF(LTRIM(RTRIM(@Motivo)),N'''''''') IS NULL OR NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51214,''''Indique motivo y responsable.'''',1;
 DECLARE @Credito varchar(20),@Garantia int;
 SELECT @Credito=NumeroCredito FROM dbo.DetallePago WHERE CodigoPago=@CodigoPago;
 SELECT @Garantia=CodigoGarantia FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@Credito;
 IF @Credito IS NULL THROW 51215,''''Pago inexistente.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@Credito AND Estado=''''ANULADO'''') THROW 51216,''''El credito esta anulado.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Garantia AND NumeroCredito<>@Credito AND Estado=''''VIGENTE'''') THROW 51217,''''No se puede reabrir: el vehiculo respalda otro credito activo.'''',1;
 UPDATE dbo.DetallePago SET FechaAnulacion=dbo.fn_AhoraGuatemala(),MotivoAnulacion=@Motivo,AnuladoPor=@Responsable WHERE CodigoPago=@CodigoPago AND FechaAnulacion IS NULL;
 IF @@ROWCOUNT=0 THROW 51218,''''El pago ya fue anulado.'''',1;
 UPDATE dbo.Credito SET Estado=''''VIGENTE'''' WHERE NumeroCredito=@Credito;
 SELECT CodigoPago,Comprobante,Monto,Comision AS ComisionRevertida,FechaAnulacion FROM dbo.vw_PagoDesglosado WHERE CodigoPago=@CodigoPago;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[DetallePago_Eliminar] @CodigoPago bigint,@Motivo nvarchar(300),@Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  EXEC api.DetallePago_Anular @CodigoPago=@CodigoPago,@Motivo=@Motivo,@Responsable=@Responsable;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Credito_Presentar] @NumeroCredito varchar(20), @Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;

 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51124,''''Indique quien presenta la solicitud.'''',1;
 DECLARE @Cliente int;
 SELECT @Cliente=CodigoDeudor FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''';
 IF @Cliente IS NULL THROW 51125,''''Solo se presenta un credito borrador.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Persona p WITH(HOLDLOCK) ON p.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@Cliente AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND p.FechaNacimiento IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WITH(HOLDLOCK) WHERE t.CodigoPersona=p.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WITH(HOLDLOCK) WHERE x.CodigoPersona=p.CodigoPersona)) THROW 51115,''''Complete identificacion, NIT, nacimiento, correo, telefono y direccion del cliente.'''',1;
 IF (SELECT COUNT(*) FROM dbo.DetalleReferencia dr WITH(HOLDLOCK) JOIN dbo.Referencia r WITH(HOLDLOCK) ON r.CodigoReferencia=dr.CodigoReferencia JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor WHERE dr.CodigoDeudor=@Cliente AND r.CodigoPersona<>d.CodigoPersona AND EXISTS(SELECT 1 FROM dbo.Telefono t WITH(HOLDLOCK) WHERE t.CodigoPersona=r.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WITH(HOLDLOCK) WHERE x.CodigoPersona=r.CodigoPersona))<3 THROW 51116,''''Se requieren tres referencias distintas y completas con telefono y direccion.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@NumeroCredito AND FechaPresentacion IS NOT NULL) THROW 51126,''''La solicitud ya esta presentada. Puede revisarla y aprobarla.'''',1;
 UPDATE dbo.Credito SET FechaPresentacion=dbo.fn_AhoraGuatemala(),PresentadoPor=LTRIM(RTRIM(@Responsable)) WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte01_CreditosEmitidos] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;
 SELECT c.NumeroCredito,c.FechaAprobacion,c.CodigoDeudor,c.CodigoVendedor,c.PrecioContado,c.Enganche,c.MontoFinanciado,c.Plazo,c.TotalIntereses,c.TotalNetoRecaudable,c.Estado,c.FechaAnulacion
 FROM dbo.vw_CreditoResumen c WHERE c.FechaAprobacion>=@Desde AND c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) ORDER BY c.FechaAprobacion,c.NumeroCredito;
 SELECT COUNT(*) CreditosEmitidos,SUM(MontoFinanciado) CapitalColocadoBruto FROM dbo.vw_CreditoResumen WHERE FechaAprobacion>=@Desde AND FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta));

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte02_CarteraMora] @FechaCorte date=NULL,@DiasMinimos int=1
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;
 IF @DiasMinimos<1 OR @DiasMinimos IS NULL THROW 51302,''''Los dias minimos deben ser al menos uno.'''',1;
 SELECT NumeroCredito,CodigoDeudor,MIN(FechaVencimiento) PrimerVencimientoPendiente,MAX(DATEDIFF(day,FechaVencimiento,@FechaCorte)) DiasMora,SUM(SaldoPendiente) TotalVencidoPendiente,COUNT(*) CuotasVencidas
 FROM dbo.fn_Saldos(@FechaCorte) WHERE FechaVencimiento<@FechaCorte AND SaldoPendiente>0 GROUP BY NumeroCredito,CodigoDeudor HAVING MAX(DATEDIFF(day,FechaVencimiento,@FechaCorte))>=@DiasMinimos ORDER BY DiasMora DESC,TotalVencidoPendiente DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte03_PagosPorMedio] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;WITH Movimiento AS(
 SELECT CodigoTipoPago,Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,1 Recibido FROM dbo.vw_PagoDesglosado WHERE FechaPago>=@Desde AND FechaPago<DATEADD(day,1,CONVERT(datetime2,@Hasta))
 UNION ALL
 SELECT CodigoTipoPago,-Monto,-Capital,-Interes,-ManejoCuenta,-SeguroAuto,-SeguroVida,0 FROM dbo.vw_PagoDesglosado WHERE FechaAnulacion>=@Desde AND FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)))

 SELECT t.CodigoTipoPago,t.Descripcion,SUM(CASE WHEN m.Recibido=1 THEN 1 ELSE 0 END) PagosRecibidos,SUM(CASE WHEN m.Recibido=1 THEN m.Monto ELSE 0 END) ImporteRecibido,SUM(CASE WHEN m.Recibido=0 THEN -m.Monto ELSE 0 END) ImporteAnulado,SUM(m.Monto) MovimientoNeto
 FROM Movimiento m JOIN dbo.TipoPago t ON t.CodigoTipoPago=m.CodigoTipoPago GROUP BY t.CodigoTipoPago,t.Descripcion ORDER BY PagosRecibidos DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte04_VentasVendedor] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;
 SELECT v.CodigoVendedor,v.CodigoEmpleado,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Vendedor,COUNT(*) Creditos,SUM(c.MontoFinanciado) CapitalColocado
 FROM dbo.vw_CreditoResumen c JOIN dbo.Vendedor v ON v.CodigoVendedor=c.CodigoVendedor JOIN dbo.Persona p ON p.CodigoPersona=v.CodigoPersona
 WHERE c.FechaAprobacion>=@Desde AND c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@Hasta)))
 GROUP BY v.CodigoVendedor,v.CodigoEmpleado,p.PrimerNombre,p.SegundoNombre,p.PrimerApellido,p.SegundoApellido ORDER BY CapitalColocado DESC,Creditos DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte05_Cumpleaneros] @Mes int,@Anio int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  
 IF @Mes NOT BETWEEN 1 AND 12 OR @Anio NOT BETWEEN 1900 AND 9998 OR @Mes IS NULL OR @Anio IS NULL THROW 51303,''''Mes o anio invalido.'''',1;
 SELECT d.CodigoDeudor,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Cliente,p.FechaNacimiento,p.CorreoElectronico,@Anio-YEAR(p.FechaNacimiento) EdadQueCumple,
 CONCAT(N''''Estimado/a '''',CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido),N'''': en MAGIS-AUTO le deseamos un feliz cumpleanos. Que este nuevo anio de vida le traiga salud y buenos momentos. Gracias por su confianza. Atentamente, equipo MAGIS-AUTO.'''') CartaFelicitacion
 FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE MONTH(p.FechaNacimiento)=@Mes AND YEAR(p.FechaNacimiento)<=@Anio ORDER BY DAY(p.FechaNacimiento),d.CodigoDeudor;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte06_EstadoCuenta] @CodigoDeudor int,@FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor WHERE CodigoDeudor=@CodigoDeudor) THROW 51304,''''Cliente inexistente.'''',1;
 SELECT NumeroCredito,SUM(Total) TotalPlan,SUM(Total-SaldoPendiente) PagadoAlCorte,SUM(SaldoPendiente) SaldoTotal,SUM(CapitalPendiente) SaldoCapital,SUM(CASE WHEN FechaVencimiento<@FechaCorte THEN SaldoPendiente ELSE 0 END) VencidoPendiente FROM dbo.fn_Saldos(@FechaCorte) WHERE CodigoDeudor=@CodigoDeudor GROUP BY NumeroCredito;
 SELECT * FROM dbo.fn_Saldos(@FechaCorte) WHERE CodigoDeudor=@CodigoDeudor ORDER BY NumeroCredito,Cuota;
 SELECT p.*,CASE WHEN p.FechaAnulacion IS NULL OR p.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte)) THEN 1 ELSE 0 END VigenteAlCorte FROM dbo.vw_PagoDesglosado p JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=p.NumeroCredito WHERE c.CodigoDeudor=@CodigoDeudor AND p.FechaPago<DATEADD(day,1,CONVERT(datetime2,@FechaCorte)) ORDER BY p.FechaPago,p.CodigoPago;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte07_PlanPagos] @NumeroCredito varchar(20),@FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito) THROW 51305,''''Credito inexistente.'''',1;
 SELECT c.NumeroCredito,c.Estado,c.FechaAprobacion,c.Plazo,c.PrecioContado,c.Enganche,c.MontoFinanciado,c.TasaAnual,c.TotalIntereses,c.TotalNetoRecaudable FROM dbo.vw_CreditoResumen c WHERE NumeroCredito=@NumeroCredito;
 SELECT q.*,s.SaldoPendiente,s.CapitalPendiente FROM dbo.vw_CuotaDesglosada q LEFT JOIN dbo.fn_Saldos(@FechaCorte)s ON s.NumeroCredito=q.NumeroCredito AND s.Cuota=q.Cuota WHERE q.NumeroCredito=@NumeroCredito ORDER BY q.Cuota;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte08_Comisiones] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;
 WITH Mov AS(
 SELECT p.NumeroCredito,p.Comision Generada,CONVERT(decimal(18,2),0) Revertida FROM dbo.vw_PagoDesglosado p WHERE p.FechaPago>=@Desde AND p.FechaPago<DATEADD(day,1,CONVERT(datetime2,@Hasta))
 UNION ALL SELECT p.NumeroCredito,0,p.Comision FROM dbo.vw_PagoDesglosado p WHERE p.FechaAnulacion>=@Desde AND p.FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)))
 SELECT v.CodigoVendedor,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Vendedor,SUM(m.Generada) ComisionGenerada,SUM(m.Revertida) ComisionRevertida,SUM(m.Generada-m.Revertida) ComisionNeta
 FROM Mov m JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=m.NumeroCredito JOIN dbo.Vendedor v ON v.CodigoVendedor=c.CodigoVendedor JOIN dbo.Persona p ON p.CodigoPersona=v.CodigoPersona GROUP BY v.CodigoVendedor,p.PrimerNombre,p.SegundoNombre,p.PrimerApellido,p.SegundoApellido ORDER BY ComisionNeta DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte09_CapitalPendiente] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT NumeroCredito,CodigoDeudor,SUM(Capital) CapitalFinanciado,SUM(Capital-CapitalPendiente) CapitalRecuperado,SUM(CapitalPendiente) CapitalPendiente FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito,CodigoDeudor ORDER BY CapitalPendiente DESC;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte10_Intereses] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT NumeroCredito,SUM(Interes) InteresesDelContrato,SUM(Interes-InteresPendiente) InteresesCobrados,SUM(InteresPendiente) InteresesPendientes FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito ORDER BY NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte11_ProximosVencimientos] @FechaCorte date=NULL,@Dias int=30
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;IF @Dias NOT BETWEEN 1 AND 365 OR @Dias IS NULL THROW 51306,''''Horizonte permitido: 1 a 365 dias.'''',1; SELECT * FROM dbo.fn_Saldos(@FechaCorte) WHERE SaldoPendiente>0 AND FechaVencimiento>=@FechaCorte AND FechaVencimiento<=DATEADD(day,@Dias,@FechaCorte) ORDER BY FechaVencimiento,NumeroCredito,Cuota;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte12_AbonosParciales] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT NumeroCredito,Cuota,FechaVencimiento,Total,Total-SaldoPendiente Pagado,SaldoPendiente FROM dbo.fn_Saldos(@FechaCorte) WHERE SaldoPendiente>0 AND SaldoPendiente<Total ORDER BY FechaVencimiento,NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte13_CreditosMarcaLinea] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;SELECT m.CodigoMarca,m.Descripcion Marca,l.CodigoLinea,l.Descripcion Linea,COUNT(*) Creditos,SUM(c.MontoFinanciado) CapitalFinanciado FROM dbo.vw_CreditoResumen c JOIN dbo.Garantia g ON g.CodigoGarantia=c.CodigoGarantia JOIN dbo.Marca m ON m.CodigoMarca=g.CodigoMarca JOIN dbo.Linea l ON l.CodigoMarca=g.CodigoMarca AND l.CodigoLinea=g.CodigoLinea WHERE c.FechaAprobacion>=@Desde AND c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@Hasta))) GROUP BY m.CodigoMarca,m.Descripcion,l.CodigoLinea,l.Descripcion ORDER BY CapitalFinanciado DESC;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte14_CarteraAgenciaRegion] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT a.CodigoAgencia,a.Nombre,a.Region,COUNT(DISTINCT s.NumeroCredito) CreditosConSaldo,SUM(s.CapitalPendiente) CapitalPendiente,SUM(s.SaldoPendiente) SaldoContractual,SUM(CASE WHEN s.FechaVencimiento<@FechaCorte THEN s.SaldoPendiente ELSE 0 END) Vencido FROM dbo.fn_Saldos(@FechaCorte)s JOIN dbo.Agencia a ON a.CodigoAgencia=s.CodigoAgencia WHERE s.SaldoPendiente>0 GROUP BY a.CodigoAgencia,a.Nombre,a.Region ORDER BY CapitalPendiente DESC;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte15_MoraRangos] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;WITH Mora AS(SELECT NumeroCredito,MAX(DATEDIFF(day,FechaVencimiento,@FechaCorte)) Dias,SUM(SaldoPendiente) Vencido FROM dbo.fn_Saldos(@FechaCorte) WHERE FechaVencimiento<@FechaCorte AND SaldoPendiente>0 GROUP BY NumeroCredito),R AS(SELECT *,CASE WHEN Dias<=30 THEN ''''01-30'''' WHEN Dias<=60 THEN ''''31-60'''' WHEN Dias<=90 THEN ''''61-90'''' ELSE ''''91 o mas'''' END Rango FROM Mora) SELECT Rango,COUNT(*) Creditos,SUM(Vencido) VencidoPendiente FROM R GROUP BY Rango ORDER BY MIN(Dias);
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte16_GarantiaContraCapital] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;WITH S AS(SELECT NumeroCredito,SUM(CapitalPendiente) CapitalPendiente FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito) SELECT c.NumeroCredito,g.VIN,c.PrecioContado,v.FechaValoracion,v.ValorDepreciado,s.CapitalPendiente,v.ValorDepreciado-s.CapitalPendiente MargenGarantia,CASE WHEN v.ValorDepreciado<s.CapitalPendiente THEN 1 ELSE 0 END GarantiaInsuficiente FROM S s JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=s.NumeroCredito JOIN dbo.Garantia g ON g.CodigoGarantia=c.CodigoGarantia OUTER APPLY(SELECT TOP(1) d.FechaValoracion,d.ValorDepreciado FROM dbo.vw_DepreciacionCalculada d WHERE d.CodigoGarantia=c.CodigoGarantia AND d.FechaValoracion<=@FechaCorte ORDER BY d.FechaValoracion DESC,d.CodigoDepreciacion DESC)v ORDER BY MargenGarantia;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte17_DepreciacionCostoFinanciamiento] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT c.NumeroCredito,c.PrecioContado,c.Enganche,c.MontoFinanciado,c.TotalIntereses,c.TotalNetoRecaudable,c.TotalNetoRecaudable-c.MontoFinanciado CostoFinanciamientoYCargos,c.Enganche+c.TotalNetoRecaudable DesembolsoTotalCliente,v.FechaValoracion,v.ValorDepreciado,c.PrecioContado-v.ValorDepreciado PerdidaValorEstimada FROM dbo.vw_CreditoResumen c OUTER APPLY(SELECT TOP(1) d.FechaValoracion,d.ValorDepreciado FROM dbo.vw_DepreciacionCalculada d WHERE d.CodigoGarantia=c.CodigoGarantia AND d.FechaValoracion<=@FechaCorte ORDER BY d.FechaValoracion DESC,d.CodigoDepreciacion DESC)v WHERE c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@FechaCorte)) AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte))) ORDER BY c.NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte18_CreditosFiador] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;WITH S AS(SELECT NumeroCredito,SUM(CapitalPendiente) CapitalPendiente,SUM(SaldoPendiente) SaldoTotal FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito) SELECT f.CodigoFiador,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Fiador,c.NumeroCredito,s.CapitalPendiente,s.SaldoTotal,COUNT(*) OVER(PARTITION BY f.CodigoFiador) CreditosRespaldados FROM dbo.CreditoFiador cf JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=cf.NumeroCredito JOIN S s ON s.NumeroCredito=c.NumeroCredito WHERE s.SaldoTotal>0 ORDER BY f.CodigoFiador,c.NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte19_RecaudacionComponentes] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;WITH Movimiento AS(
 SELECT CodigoTipoPago,Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,1 Recibido FROM dbo.vw_PagoDesglosado WHERE FechaPago>=@Desde AND FechaPago<DATEADD(day,1,CONVERT(datetime2,@Hasta))
 UNION ALL
 SELECT CodigoTipoPago,-Monto,-Capital,-Interes,-ManejoCuenta,-SeguroAuto,-SeguroVida,0 FROM dbo.vw_PagoDesglosado WHERE FechaAnulacion>=@Desde AND FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)))
SELECT COALESCE(SUM(Capital),0) CapitalNeto,COALESCE(SUM(Interes),0) InteresesNetos,COALESCE(SUM(ManejoCuenta),0) ManejoNeto,COALESCE(SUM(SeguroAuto),0) SeguroAutoNeto,COALESCE(SUM(SeguroVida),0) SeguroVidaNeto,COALESCE(SUM(Monto),0) MovimientoNeto FROM Movimiento;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

EXEC(N''CREATE PROCEDURE api.[Reporte20_PagosAnulados] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;SELECT CodigoPago,Comprobante,NumeroCredito,Cuota,FechaPago,FechaAnulacion,Monto,Comision ComisionRevertida,MotivoAnulacion,AnuladoPor FROM dbo.vw_PagoDesglosado WHERE FechaAnulacion>=@Desde AND FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) ORDER BY FechaAnulacion,CodigoPago;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');

CREATE ROLE magis_api AUTHORIZATION dbo; GRANT EXECUTE ON SCHEMA::api TO magis_api; DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::dbo TO magis_api;

IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>26 THROW 51400,''Inventario de tablas incompleto.'',1; IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api''))<>151 THROW 51401,''Inventario de procedimientos incompleto.'',1;































SELECT (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api'')) Procedimientos,(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api'') AND name LIKE N''Reporte%'') Reportes;

-- Definiciones vigentes capturadas de la base fuente.
EXEC(N''CREATE OR ALTER FUNCTION dbo.fn_AhoraGuatemala() RETURNS datetime2(0) AS BEGIN RETURN CONVERT(datetime2(0),SYSUTCDATETIME() AT TIME ZONE ''''UTC'''' AT TIME ZONE ''''Central America Standard Time''''); END;'');
EXEC(N''CREATE OR ALTER FUNCTION dbo.fn_Saldos(@FechaCorte date) RETURNS TABLE AS RETURN
 SELECT q.*,c.CodigoDeudor,c.CodigoGarantia,c.CodigoVendedor,c.CodigoAgencia,
 q.Total-ISNULL(p.Monto,0) AS SaldoPendiente,
 q.Capital-ISNULL(p.Capital,0) AS CapitalPendiente,
 q.Interes-ISNULL(p.Interes,0) AS InteresPendiente,
 q.ManejoCuenta-ISNULL(p.ManejoCuenta,0) AS ManejoPendiente,
 q.SeguroAuto-ISNULL(p.SeguroAuto,0) AS AutoPendiente,
 q.SeguroVida-ISNULL(p.SeguroVida,0) AS VidaPendiente
 FROM dbo.vw_CuotaDesglosada q JOIN dbo.Credito c ON c.NumeroCredito=q.NumeroCredito
 OUTER APPLY(SELECT SUM(Monto) Monto,SUM(Capital) Capital,SUM(Interes) Interes,SUM(ManejoCuenta) ManejoCuenta,SUM(SeguroAuto) SeguroAuto,SUM(SeguroVida) SeguroVida
 FROM dbo.DetallePago p WHERE p.NumeroCredito=q.NumeroCredito AND p.Cuota=q.Cuota
 AND p.FechaPago<DATEADD(day,1,CONVERT(datetime2,@FechaCorte))
 AND(p.FechaAnulacion IS NULL OR p.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte))))p
 WHERE c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@FechaCorte))
 AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte)));'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Agencia_Actualizar] @CodigoAgencia int,
 @Nombre nvarchar(128),
 @Region nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Agencia] SET [Nombre]=@Nombre,[Region]=@Region WHERE [CodigoAgencia]=@CodigoAgencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Agencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Agencia] WHERE CONVERT(nvarchar(4000),[CodigoAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Nombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Region]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoAgencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Agencia_Eliminar] @CodigoAgencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Agencia] WHERE [CodigoAgencia]=@CodigoAgencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Agencia_Insertar] @Nombre nvarchar(128),
 @Region nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Agencia]([Nombre],[Region]) OUTPUT INSERTED.[CodigoAgencia] AS Id VALUES(@Nombre,@Region);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Agencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Agencia] ORDER BY [CodigoAgencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Actualizar] @NumeroCredito varchar(20), @CodigoDeudor int, @CodigoGarantia int,
 @CodigoVendedor int, @Enganche decimal(18,2), @Plazo smallint=60,
 @FiadoresRequeridos smallint=1, @PorcentajeComision decimal(9,6)=NULL,
 @CodigoParametro int=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51106,''''Solo se editan las condiciones de un credito borrador.'''',1;

 IF @Plazo NOT IN(12,24,36,48,60) OR @Plazo IS NULL THROW 51100,''''Plazo permitido: 12,24,36,48 o 60 meses.'''',1;
 IF @FiadoresRequeridos IS NULL OR @FiadoresRequeridos<0 THROW 51101,''''Indique cuantos fiadores requiere el comite; cero si no requiere.'''',1;
 DECLARE @Precio decimal(18,2),@Agencia int,@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6),@Minimo decimal(9,6),@Comision decimal(9,6);
 SELECT @Precio=ValorAgencia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia;
 SELECT @Agencia=CodigoAgencia FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor;
 IF @Precio IS NULL OR @Agencia IS NULL THROW 51102,''''Vehiculo o vendedor inexistente.'''',1;
 IF @CodigoParametro IS NULL SELECT @CodigoParametro=CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1;
 SELECT @Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida,@Minimo=EngancheMinimo,@Comision=ComisionPredeterminada FROM dbo.ParametroCredito WITH(HOLDLOCK) WHERE CodigoParametro=@CodigoParametro AND Activo=1;
 IF @Tasa IS NULL THROW 51103,''''Se requiere una configuracion activa.'''',1;
 IF @Enganche IS NULL OR @Enganche<CEILING(@Precio*@Minimo*100)/100 OR @Enganche>=@Precio THROW 51104,''''Enganche inferior al minimo o sin monto pendiente por financiar.'''',1;
 SET @Comision=COALESCE(@PorcentajeComision,@Comision);
 IF @Comision NOT BETWEEN 0 AND 1 THROW 51105,''''Comision fuera de rango.'''',1;

 IF EXISTS(SELECT 1 FROM dbo.CreditoFiador cf JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Deudor d ON d.CodigoPersona=f.CodigoPersona WHERE cf.NumeroCredito=@NumeroCredito AND d.CodigoDeudor=@CodigoDeudor) THROW 51107,''''El nuevo cliente es fiador de este credito.'''',1;
 UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL,CodigoDeudor=@CodigoDeudor,CodigoGarantia=@CodigoGarantia,CodigoVendedor=@CodigoVendedor,CodigoAgencia=@Agencia,CodigoParametro=@CodigoParametro,Plazo=@Plazo,PrecioContado=@Precio,Enganche=@Enganche,EngancheMinimo=@Minimo,TasaAnual=@Tasa,ManejoMensual=@Manejo,TasaSeguroAuto=@Auto,TasaSeguroVida=@Vida,PorcentajeComision=@Comision,FiadoresRequeridos=@FiadoresRequeridos WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Anular] @NumeroCredito varchar(20),@Motivo nvarchar(300),@Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NULLIF(LTRIM(RTRIM(@Motivo)),N'''''''') IS NULL OR NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51121,''''Indique motivo y responsable.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado IN(''''BORRADOR'''',''''VIGENTE'''')) THROW 51122,''''El credito no puede anularse en su estado actual.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND FechaAnulacion IS NULL) THROW 51123,''''El credito tiene pagos efectivos: resuelvalos antes de anular.'''',1;
 UPDATE dbo.Credito SET Estado=''''ANULADO'''',FechaAnulacion=dbo.fn_AhoraGuatemala(),MotivoAnulacion=@Motivo,AnuladoPor=@Responsable WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Aprobar] @NumeroCredito varchar(20),@Responsable nvarchar(100),
 @FechaAprobacion datetime2(0)=NULL,@PorcentajeDepreciacion decimal(9,6)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51109,''''Indique el responsable del comite.'''',1;
 SET @FechaAprobacion=COALESCE(@FechaAprobacion,dbo.fn_AhoraGuatemala());
 IF @FechaAprobacion>dbo.fn_AhoraGuatemala() THROW 51110,''''La aprobacion no puede estar en el futuro.'''',1;
 DECLARE @Cliente int,@Vehiculo int,@Plazo smallint,@Fiadores smallint,@Parametro int,@Monto decimal(18,2),@Precio decimal(18,2),@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6);
 SELECT @Cliente=CodigoDeudor,@Vehiculo=CodigoGarantia,@Plazo=Plazo,@Fiadores=FiadoresRequeridos,@Parametro=CodigoParametro,@Monto=PrecioContado-Enganche,@Precio=PrecioContado,@Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida
 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''';
 IF @Cliente IS NULL THROW 51111,''''El credito no existe o ya fue aprobado.'''',1;
 DECLARE @Vin varchar(17);
 SELECT @Vin=VIN FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo;
 IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Vehiculo AND Estado=''''VIGENTE'''') THROW 51112,''''El vehiculo ya respalda un credito activo.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE CodigoGarantia=@Vehiculo AND FechaAnulacion>@FechaAprobacion) THROW 51113,''''La aprobacion no puede preceder la anulacion del contrato anterior.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito WHERE c.CodigoGarantia=@Vehiculo AND p.FechaPago>@FechaAprobacion) THROW 51114,''''La aprobacion no puede preceder pagos del contrato anterior del vehiculo.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@Cliente AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND p.FechaNacimiento IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=p.CodigoPersona)) THROW 51115,''''Complete identificacion, NIT, nacimiento, correo, telefono y direccion del cliente.'''',1;
 IF (SELECT COUNT(*) FROM dbo.DetalleReferencia dr WITH(HOLDLOCK) JOIN dbo.Referencia r ON r.CodigoReferencia=dr.CodigoReferencia JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor WHERE dr.CodigoDeudor=@Cliente AND r.CodigoPersona<>d.CodigoPersona AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=r.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WHERE x.CodigoPersona=r.CodigoPersona))<3 THROW 51116,''''Se requieren tres referencias distintas y completas con telefono y direccion.'''',1;
 IF (SELECT COUNT(*) FROM dbo.CreditoFiador cf WITH(HOLDLOCK) JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona JOIN dbo.Deudor d ON d.CodigoDeudor=@Cliente WHERE cf.NumeroCredito=@NumeroCredito AND f.CodigoPersona<>d.CodigoPersona AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WHERE t.CodigoPersona=p.CodigoPersona))<@Fiadores THROW 51117,''''Complete la cantidad de fiadores y sus datos obligatorios.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@NumeroCredito AND FechaPresentacion IS NOT NULL) THROW 51127,''''Presente la solicitud completa antes de aprobar.'''',1;
 IF @PorcentajeDepreciacion IS NULL SELECT @PorcentajeDepreciacion=DepreciacionInicial FROM dbo.ParametroCredito WHERE CodigoParametro=@Parametro;
 IF @PorcentajeDepreciacion IS NULL OR @PorcentajeDepreciacion NOT BETWEEN 0.15 AND 0.20 THROW 51118,''''La depreciacion inicial debe estar entre 15 y 20 por ciento.'''',1;
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
  IF @K<0 THROW 51119,''''El calculo produjo amortizacion negativa.'''',1;
  INSERT dbo.DetalleCuota(NumeroCredito,Cuota,FechaVencimiento,Capital,Interes)
  VALUES(@NumeroCredito,@N,DATEADD(month,@N,CONVERT(date,@FechaAprobacion)),@K,@I);
  SET @Saldo=@Saldo-@K; SET @N=@N+1;
 END;
 IF @Saldo<>0 THROW 51120,''''El plan no liquida el capital.'''',1;
 INSERT dbo.Depreciacion(CodigoGarantia,FechaValoracion,ValorOriginal,Porcentaje,Observacion) VALUES(@Vehiculo,CONVERT(date,@FechaAprobacion),@Precio,@PorcentajeDepreciacion,N''''Valoracion inicial al aprobar ''''+@NumeroCredito);
 INSERT dbo.ResumenCredito(NumeroCredito,TotalIntereses,TotalNetoRecaudable)
 SELECT @NumeroCredito,SUM(Interes),SUM(Total) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito;
 UPDATE dbo.Credito SET Estado=''''VIGENTE'''',FechaAprobacion=@FechaAprobacion,AprobadoPor=@Responsable WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito ORDER BY Cuota;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_CreditoResumen] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoDeudor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoVendedor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoParametro]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Plazo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PrecioContado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Enganche]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[EngancheMinimo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaAnual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoMensual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PorcentajeComision]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FiadoresRequeridos]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Estado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaAprobacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[AprobadoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[MotivoAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[AnuladoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[MontoFinanciado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalIntereses]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalNetoRecaudable]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Eliminar] @NumeroCredito varchar(20)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51108,''''Solo se borra un credito borrador sin dependencias. Los aprobados se anulan.'''',1; DELETE dbo.Credito WHERE NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Insertar] @NumeroCredito varchar(20), @CodigoDeudor int, @CodigoGarantia int,
 @CodigoVendedor int, @Enganche decimal(18,2), @Plazo smallint=60,
 @FiadoresRequeridos smallint=1, @PorcentajeComision decimal(9,6)=NULL,
 @CodigoParametro int=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF @Plazo NOT IN(12,24,36,48,60) OR @Plazo IS NULL THROW 51100,''''Plazo permitido: 12,24,36,48 o 60 meses.'''',1;
 IF @FiadoresRequeridos IS NULL OR @FiadoresRequeridos<0 THROW 51101,''''Indique cuantos fiadores requiere el comite; cero si no requiere.'''',1;
 DECLARE @Precio decimal(18,2),@Agencia int,@Tasa decimal(9,6),@Manejo decimal(18,2),@Auto decimal(9,6),@Vida decimal(9,6),@Minimo decimal(9,6),@Comision decimal(9,6);
 SELECT @Precio=ValorAgencia FROM dbo.Garantia WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia;
 SELECT @Agencia=CodigoAgencia FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor;
 IF @Precio IS NULL OR @Agencia IS NULL THROW 51102,''''Vehiculo o vendedor inexistente.'''',1;
 IF @CodigoParametro IS NULL SELECT @CodigoParametro=CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1;
 SELECT @Tasa=TasaAnual,@Manejo=ManejoMensual,@Auto=TasaSeguroAuto,@Vida=TasaSeguroVida,@Minimo=EngancheMinimo,@Comision=ComisionPredeterminada FROM dbo.ParametroCredito WITH(HOLDLOCK) WHERE CodigoParametro=@CodigoParametro AND Activo=1;
 IF @Tasa IS NULL THROW 51103,''''Se requiere una configuracion activa.'''',1;
 IF @Enganche IS NULL OR @Enganche<CEILING(@Precio*@Minimo*100)/100 OR @Enganche>=@Precio THROW 51104,''''Enganche inferior al minimo o sin monto pendiente por financiar.'''',1;
 SET @Comision=COALESCE(@PorcentajeComision,@Comision);
 IF @Comision NOT BETWEEN 0 AND 1 THROW 51105,''''Comision fuera de rango.'''',1;

 INSERT dbo.Credito(NumeroCredito,CodigoDeudor,CodigoGarantia,CodigoVendedor,CodigoAgencia,CodigoParametro,Plazo,PrecioContado,Enganche,EngancheMinimo,TasaAnual,ManejoMensual,TasaSeguroAuto,TasaSeguroVida,PorcentajeComision,FiadoresRequeridos)
 VALUES(@NumeroCredito,@CodigoDeudor,@CodigoGarantia,@CodigoVendedor,@Agencia,@CodigoParametro,@Plazo,@Precio,@Enganche,@Minimo,@Tasa,@Manejo,@Auto,@Vida,@Comision,@FiadoresRequeridos);
 SELECT * FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_CreditoResumen] ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Credito_Presentar] @NumeroCredito varchar(20), @Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;

 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51124,''''Indique quien presenta la solicitud.'''',1;
 DECLARE @Cliente int;
 SELECT @Cliente=CodigoDeudor FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''';
 IF @Cliente IS NULL THROW 51125,''''Solo se presenta un credito borrador.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Persona p WITH(HOLDLOCK) ON p.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@Cliente AND p.DPI IS NOT NULL AND p.NIT IS NOT NULL AND p.CorreoElectronico IS NOT NULL AND p.FechaNacimiento IS NOT NULL AND EXISTS(SELECT 1 FROM dbo.Telefono t WITH(HOLDLOCK) WHERE t.CodigoPersona=p.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WITH(HOLDLOCK) WHERE x.CodigoPersona=p.CodigoPersona)) THROW 51115,''''Complete identificacion, NIT, nacimiento, correo, telefono y direccion del cliente.'''',1;
 IF (SELECT COUNT(*) FROM dbo.DetalleReferencia dr WITH(HOLDLOCK) JOIN dbo.Referencia r WITH(HOLDLOCK) ON r.CodigoReferencia=dr.CodigoReferencia JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor WHERE dr.CodigoDeudor=@Cliente AND r.CodigoPersona<>d.CodigoPersona AND EXISTS(SELECT 1 FROM dbo.Telefono t WITH(HOLDLOCK) WHERE t.CodigoPersona=r.CodigoPersona) AND EXISTS(SELECT 1 FROM dbo.Direccion x WITH(HOLDLOCK) WHERE x.CodigoPersona=r.CodigoPersona))<3 THROW 51116,''''Se requieren tres referencias distintas y completas con telefono y direccion.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@NumeroCredito AND FechaPresentacion IS NOT NULL) THROW 51126,''''La solicitud ya esta presentada. Puede revisarla y aprobarla.'''',1;
 UPDATE dbo.Credito SET FechaPresentacion=dbo.fn_AhoraGuatemala(),PresentadoPor=LTRIM(RTRIM(@Responsable)) WHERE NumeroCredito=@NumeroCredito;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[CreditoFiador_Actualizar] @NumeroCredito varchar(20),
 @CodigoFiador int, @NuevoCodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.Deudor d ON d.CodigoDeudor=c.CodigoDeudor JOIN dbo.Fiador f ON f.CodigoPersona=d.CodigoPersona WHERE c.NumeroCredito=@NumeroCredito AND f.CodigoFiador=@CodigoFiador) THROW 51004,''''El cliente no puede ser fiador de su propio credito.'''',1;
DECLARE @Anterior int=@CodigoFiador; SET @CodigoFiador=@NuevoCodigoFiador;IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.Deudor d ON d.CodigoDeudor=c.CodigoDeudor JOIN dbo.Fiador f ON f.CodigoPersona=d.CodigoPersona WHERE c.NumeroCredito=@NumeroCredito AND f.CodigoFiador=@CodigoFiador) THROW 51004,''''El cliente no puede ser fiador de su propio credito.'''',1; UPDATE dbo.[CreditoFiador] SET [CodigoFiador]=@NuevoCodigoFiador WHERE [NumeroCredito]=@NumeroCredito AND [CodigoFiador]=@Anterior; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[CreditoFiador_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[CreditoFiador] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoFiador]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito],[CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[CreditoFiador_Eliminar] @NumeroCredito varchar(20),
 @CodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;
DELETE dbo.[CreditoFiador] WHERE [NumeroCredito]=@NumeroCredito AND [CodigoFiador]=@CodigoFiador; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[CreditoFiador_Insertar] @NumeroCredito varchar(20),
 @CodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.Deudor d ON d.CodigoDeudor=c.CodigoDeudor JOIN dbo.Fiador f ON f.CodigoPersona=d.CodigoPersona WHERE c.NumeroCredito=@NumeroCredito AND f.CodigoFiador=@CodigoFiador) THROW 51004,''''El cliente no puede ser fiador de su propio credito.'''',1;
INSERT dbo.[CreditoFiador]([NumeroCredito],[CodigoFiador]) OUTPUT INSERTED.[NumeroCredito],INSERTED.[CodigoFiador] VALUES(@NumeroCredito,@CodigoFiador);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[CreditoFiador_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[CreditoFiador] ORDER BY [NumeroCredito],[CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Departamento_Actualizar] @CodigoDepartamento int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Departamento] SET [Descripcion]=@Descripcion WHERE [CodigoDepartamento]=@CodigoDepartamento; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Departamento_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Departamento] WHERE CONVERT(nvarchar(4000),[CodigoDepartamento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDepartamento];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Departamento_Eliminar] @CodigoDepartamento int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Departamento] WHERE [CodigoDepartamento]=@CodigoDepartamento; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Departamento_Insertar] @CodigoDepartamento int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Departamento]([CodigoDepartamento],[Descripcion]) OUTPUT INSERTED.[CodigoDepartamento] VALUES(@CodigoDepartamento,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Departamento_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Departamento] ORDER BY [CodigoDepartamento];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Depreciacion_Actualizar] @CodigoDepreciacion int,
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
  IF @FechaValoracion>CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51006,''''La valoracion no puede estar en el futuro.'''',1;IF EXISTS(SELECT 1 FROM dbo.Depreciacion d JOIN dbo.Credito c ON c.CodigoGarantia=d.CodigoGarantia WHERE d.CodigoDepreciacion=@CodigoDepreciacion AND c.FechaAprobacion IS NOT NULL) THROW 51014,''''La valoracion forma parte del historial; registre una nueva valoracion.'''',1;
UPDATE dbo.[Depreciacion] SET [CodigoGarantia]=@CodigoGarantia,[FechaValoracion]=@FechaValoracion,[ValorOriginal]=@ValorOriginal,[Porcentaje]=@Porcentaje,[Observacion]=@Observacion WHERE [CodigoDepreciacion]=@CodigoDepreciacion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Depreciacion_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_DepreciacionCalculada] WHERE CONVERT(nvarchar(4000),[CodigoDepreciacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaValoracion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ValorOriginal]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Porcentaje]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Observacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ValorDepreciado]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDepreciacion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Depreciacion_Eliminar] @CodigoDepreciacion int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Depreciacion d JOIN dbo.Credito c ON c.CodigoGarantia=d.CodigoGarantia WHERE d.CodigoDepreciacion=@CodigoDepreciacion AND c.FechaAprobacion IS NOT NULL) THROW 51014,''''La valoracion forma parte del historial; registre una nueva valoracion.'''',1;
DELETE dbo.[Depreciacion] WHERE [CodigoDepreciacion]=@CodigoDepreciacion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Depreciacion_Insertar] @CodigoGarantia int,
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
  IF @FechaValoracion>CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51006,''''La valoracion no puede estar en el futuro.'''',1;
INSERT dbo.[Depreciacion]([CodigoGarantia],[FechaValoracion],[ValorOriginal],[Porcentaje],[Observacion]) OUTPUT INSERTED.[CodigoDepreciacion] AS Id VALUES(@CodigoGarantia,@FechaValoracion,@ValorOriginal,@Porcentaje,@Observacion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Depreciacion_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_DepreciacionCalculada] ORDER BY [CodigoDepreciacion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleCuota_Actualizar] @NumeroCredito varchar(20),
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
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;
UPDATE dbo.[DetalleCuota] SET [FechaVencimiento]=@FechaVencimiento,[Capital]=@Capital,[Interes]=@Interes WHERE [NumeroCredito]=@NumeroCredito AND [Cuota]=@Cuota; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleCuota_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_CuotaDesglosada] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Cuota]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaVencimiento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Capital]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Interes]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoCuenta]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Total]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito],[Cuota];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleCuota_Eliminar] @NumeroCredito varchar(20),
 @Cuota smallint
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;
DELETE dbo.[DetalleCuota] WHERE [NumeroCredito]=@NumeroCredito AND [Cuota]=@Cuota; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleCuota_Insertar] @NumeroCredito varchar(20),
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
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica este detalle mientras el credito es borrador.'''',1;
INSERT dbo.[DetalleCuota]([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) OUTPUT INSERTED.[NumeroCredito],INSERTED.[Cuota] VALUES(@NumeroCredito,@Cuota,@FechaVencimiento,@Capital,@Interes);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleCuota_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_CuotaDesglosada] ORDER BY [NumeroCredito],[Cuota];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetallePago_Actualizar] @CodigoPago bigint,@Observacion nvarchar(300)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 -- Solo anotaciones: una correccion financiera requiere anular y registrar un nuevo pago.
 UPDATE dbo.DetallePago SET Observacion=@Observacion WHERE CodigoPago=@CodigoPago;
 IF @@ROWCOUNT=0 THROW 51213,''''Pago inexistente.'''',1;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetallePago_Anular] @CodigoPago bigint,@Motivo nvarchar(300),@Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF NULLIF(LTRIM(RTRIM(@Motivo)),N'''''''') IS NULL OR NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51214,''''Indique motivo y responsable.'''',1;
 DECLARE @Credito varchar(20),@Garantia int;
 SELECT @Credito=NumeroCredito FROM dbo.DetallePago WHERE CodigoPago=@CodigoPago;
 SELECT @Garantia=CodigoGarantia FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@Credito;
 IF @Credito IS NULL THROW 51215,''''Pago inexistente.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=@Credito AND Estado=''''ANULADO'''') THROW 51216,''''El credito esta anulado.'''',1;
 IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@Garantia AND NumeroCredito<>@Credito AND Estado=''''VIGENTE'''') THROW 51217,''''No se puede reabrir: el vehiculo respalda otro credito activo.'''',1;
 UPDATE dbo.DetallePago SET FechaAnulacion=dbo.fn_AhoraGuatemala(),MotivoAnulacion=@Motivo,AnuladoPor=@Responsable WHERE CodigoPago=@CodigoPago AND FechaAnulacion IS NULL;
 IF @@ROWCOUNT=0 THROW 51218,''''El pago ya fue anulado.'''',1;
 UPDATE dbo.Credito SET Estado=''''VIGENTE'''' WHERE NumeroCredito=@Credito;
 SELECT CodigoPago,Comprobante,Monto,Comision AS ComisionRevertida,FechaAnulacion FROM dbo.vw_PagoDesglosado WHERE CodigoPago=@CodigoPago;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetallePago_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[vw_PagoDesglosado] WHERE CONVERT(nvarchar(4000),[CodigoPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Comprobante]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Cuota]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ReferenciaBancaria]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Monto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Capital]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Interes]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoCuenta]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[RegistradoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[MotivoAnulacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[AnuladoPor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Observacion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PorcentajeComision]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Comision]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetallePago_Eliminar] @CodigoPago bigint,@Motivo nvarchar(300),@Responsable nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  EXEC api.DetallePago_Anular @CodigoPago=@CodigoPago,@Motivo=@Motivo,@Responsable=@Responsable;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetallePago_Insertar] @NumeroCredito varchar(20),@Cuota smallint,@Monto decimal(18,2),@CodigoTipoPago int,
 @Responsable nvarchar(100),@ReferenciaBancaria nvarchar(100)=NULL,@FechaPago datetime2(0)=NULL,@Observacion nvarchar(300)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
 IF @Monto IS NULL OR @Monto<=0 THROW 51200,''''El abono debe ser positivo.'''',1;
 IF NULLIF(LTRIM(RTRIM(@Responsable)),N'''''''') IS NULL THROW 51201,''''Indique quien registra el pago.'''',1;
 SET @FechaPago=COALESCE(@FechaPago,dbo.fn_AhoraGuatemala());
 IF @FechaPago>dbo.fn_AhoraGuatemala() THROW 51202,''''No se registran pagos futuros.'''',1;
 DECLARE @Comision decimal(9,6),@Aprobacion datetime2(0),@Requiere bit;
 SELECT @Comision=PorcentajeComision,@Aprobacion=FechaAprobacion FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''VIGENTE'''';
 IF @Comision IS NULL THROW 51203,''''El credito no esta vigente.'''',1;
 IF @FechaPago<@Aprobacion THROW 51204,''''El pago no puede preceder la aprobacion.'''',1;
 -- No insertar movimientos retroactivos detras de movimientos ya registrados: preserva saldos historicos.
 IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND (FechaPago>@FechaPago OR FechaAnulacion>@FechaPago)) THROW 51205,''''Registre los movimientos del credito en orden cronologico.'''',1;
 SELECT @Requiere=RequiereReferencia FROM dbo.TipoPago WHERE CodigoTipoPago=@CodigoTipoPago;
 IF @Requiere IS NULL THROW 51206,''''Medio de pago inexistente.'''',1;
 IF @Requiere=1 AND NULLIF(LTRIM(RTRIM(@ReferenciaBancaria)),N'''''''') IS NULL THROW 51207,''''Este medio requiere boleta o autorizacion bancaria.'''',1;
 DECLARE @Pendiente TABLE(Orden int PRIMARY KEY,Saldo decimal(18,2),Centavos bigint,Fraccion decimal(28,12));
 INSERT @Pendiente(Orden,Saldo)
 SELECT x.Orden,x.Importe FROM dbo.vw_CuotaDesglosada q
 OUTER APPLY(SELECT SUM(Capital) Capital,SUM(Interes) Interes,SUM(ManejoCuenta) ManejoCuenta,SUM(SeguroAuto) SeguroAuto,SUM(SeguroVida) SeguroVida FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND Cuota=@Cuota AND FechaAnulacion IS NULL)p
 CROSS APPLY(VALUES(1,q.Capital-ISNULL(p.Capital,0)),(2,q.Interes-ISNULL(p.Interes,0)),(3,q.ManejoCuenta-ISNULL(p.ManejoCuenta,0)),(4,q.SeguroAuto-ISNULL(p.SeguroAuto,0)),(5,q.SeguroVida-ISNULL(p.SeguroVida,0)))x(Orden,Importe)
 WHERE q.NumeroCredito=@NumeroCredito AND q.Cuota=@Cuota;
 DECLARE @Saldo decimal(18,2)=(SELECT SUM(Saldo) FROM @Pendiente);
 IF @Saldo IS NULL THROW 51208,''''Cuota inexistente.'''',1;
 IF @Monto>@Saldo THROW 51209,''''El pago supera el saldo pendiente de la cuota. No se registro ningun importe.'''',1;
 IF @Saldo<=0 THROW 51210,''''La cuota ya esta pagada.'''',1;
 -- Distribucion proporcional en centavos por mayor residuo, con desempate estable.
 UPDATE @Pendiente SET Centavos=CONVERT(bigint,FLOOR((@Monto*100)*(Saldo/@Saldo))),Fraccion=(@Monto*100)*(Saldo/@Saldo)-FLOOR((@Monto*100)*(Saldo/@Saldo));
 DECLARE @Restantes bigint=CONVERT(bigint,@Monto*100)-(SELECT SUM(Centavos) FROM @Pendiente);
 WHILE @Restantes>0
 BEGIN
  DECLARE @Orden int;
  SET @Orden=NULL;
  SELECT TOP(1) @Orden=Orden FROM @Pendiente WHERE Centavos<CONVERT(bigint,Saldo*100) ORDER BY Fraccion DESC,Orden;
  IF @Orden IS NULL THROW 51211,''''No se pudo distribuir el abono.'''',1;
  UPDATE @Pendiente SET Centavos=Centavos+1,Fraccion=-1 WHERE Orden=@Orden;
  SET @Restantes=@Restantes-1;
 END;
 IF EXISTS(SELECT 1 FROM @Pendiente WHERE Centavos<0 OR Centavos>CONVERT(bigint,Saldo*100)) THROW 51212,''''Distribucion fuera del saldo de un componente.'''',1;
 IF (SELECT SUM(Centavos) FROM @Pendiente)<>CONVERT(bigint,@Monto*100) THROW 51219,''''El desglose no coincide con el importe recibido.'''',1;
 INSERT dbo.DetallePago(NumeroCredito,Cuota,FechaPago,CodigoTipoPago,ReferenciaBancaria,Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,RegistradoPor,Observacion)
 SELECT @NumeroCredito,@Cuota,@FechaPago,@CodigoTipoPago,@ReferenciaBancaria,@Monto,
 MAX(CASE WHEN Orden=1 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=2 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=3 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=4 THEN Centavos/100.0 END),MAX(CASE WHEN Orden=5 THEN Centavos/100.0 END),@Responsable,@Observacion FROM @Pendiente;
 DECLARE @Id bigint=SCOPE_IDENTITY();
 IF (SELECT SUM(Total) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)=(SELECT SUM(Monto) FROM dbo.DetallePago WHERE NumeroCredito=@NumeroCredito AND FechaAnulacion IS NULL)
 UPDATE dbo.Credito SET Estado=''''LIQUIDADO'''' WHERE NumeroCredito=@NumeroCredito;
 SELECT * FROM dbo.vw_PagoDesglosado WHERE CodigoPago=@Id;

  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetallePago_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[vw_PagoDesglosado] ORDER BY [CodigoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleReferencia_Actualizar] @CodigoDeudor int,
 @CodigoReferencia int,
 @CodigoTipoReferencia int,
 @ParentescoRelacion nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Referencia r ON r.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@CodigoDeudor AND r.CodigoReferencia=@CodigoReferencia) THROW 51002,''''El cliente no puede ser su propia referencia.'''',1;
UPDATE dbo.[DetalleReferencia] SET [CodigoTipoReferencia]=@CodigoTipoReferencia,[ParentescoRelacion]=@ParentescoRelacion WHERE [CodigoDeudor]=@CodigoDeudor AND [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleReferencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[DetalleReferencia] WHERE CONVERT(nvarchar(4000),[CodigoDeudor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ParentescoRelacion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDeudor],[CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleReferencia_Eliminar] @CodigoDeudor int,
 @CodigoReferencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[DetalleReferencia] WHERE [CodigoDeudor]=@CodigoDeudor AND [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleReferencia_Insertar] @CodigoDeudor int,
 @CodigoReferencia int,
 @CodigoTipoReferencia int,
 @ParentescoRelacion nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Referencia r ON r.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@CodigoDeudor AND r.CodigoReferencia=@CodigoReferencia) THROW 51002,''''El cliente no puede ser su propia referencia.'''',1;
INSERT dbo.[DetalleReferencia]([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) OUTPUT INSERTED.[CodigoDeudor],INSERTED.[CodigoReferencia] VALUES(@CodigoDeudor,@CodigoReferencia,@CodigoTipoReferencia,@ParentescoRelacion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[DetalleReferencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[DetalleReferencia] ORDER BY [CodigoDeudor],[CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Deudor_Actualizar] @CodigoDeudor int,
 @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL AND FechaNacimiento IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;IF EXISTS(SELECT 1 FROM dbo.Deudor WHERE CodigoDeudor=@CodigoDeudor AND CodigoPersona<>@CodigoPersona) THROW 51013,''''No se cambia la identidad de un rol; registre otro si corresponde.'''',1;
UPDATE dbo.[Deudor] SET [CodigoPersona]=@CodigoPersona WHERE [CodigoDeudor]=@CodigoDeudor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Deudor_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Deudor] WHERE CONVERT(nvarchar(4000),[CodigoDeudor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDeudor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Deudor_Eliminar] @CodigoDeudor int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Deudor] WHERE [CodigoDeudor]=@CodigoDeudor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Deudor_Insertar] @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL AND FechaNacimiento IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;
INSERT dbo.[Deudor]([CodigoPersona]) OUTPUT INSERTED.[CodigoDeudor] AS Id VALUES(@CodigoPersona);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Deudor_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Deudor] ORDER BY [CodigoDeudor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Direccion_Actualizar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoDireccion int,
 @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Detalle nvarchar(300)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Direccion] SET [CodigoTipoDireccion]=@CodigoTipoDireccion,[CodigoDepartamento]=@CodigoDepartamento,[CodigoMunicipio]=@CodigoMunicipio,[Detalle]=@Detalle WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Direccion_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Direccion] WHERE CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Correlativo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoDireccion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoDepartamento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoMunicipio]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Detalle]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Direccion_Eliminar] @CodigoPersona int,
 @Correlativo smallint
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Direccion] WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Direccion_Insertar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoDireccion int,
 @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Detalle nvarchar(300)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Direccion]([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) OUTPUT INSERTED.[CodigoPersona],INSERTED.[Correlativo] VALUES(@CodigoPersona,@Correlativo,@CodigoTipoDireccion,@CodigoDepartamento,@CodigoMunicipio,@Detalle);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Direccion_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Direccion] ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Fiador_Actualizar] @CodigoFiador int,
 @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;IF EXISTS(SELECT 1 FROM dbo.Fiador WHERE CodigoFiador=@CodigoFiador AND CodigoPersona<>@CodigoPersona) THROW 51013,''''No se cambia la identidad de un rol; registre otro si corresponde.'''',1;
UPDATE dbo.[Fiador] SET [CodigoPersona]=@CodigoPersona WHERE [CodigoFiador]=@CodigoFiador; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Fiador_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Fiador] WHERE CONVERT(nvarchar(4000),[CodigoFiador]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Fiador_Eliminar] @CodigoFiador int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Fiador] WHERE [CodigoFiador]=@CodigoFiador; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Fiador_Insertar] @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;
INSERT dbo.[Fiador]([CodigoPersona]) OUTPUT INSERTED.[CodigoFiador] AS Id VALUES(@CodigoPersona);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Fiador_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Fiador] ORDER BY [CodigoFiador];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Garantia_Actualizar] @CodigoGarantia int,
 @VIN varchar(17),
 @CodigoMarca int,
 @CodigoLinea int,
 @Anio smallint,
 @ValorAgencia decimal(18,2),
 @Placa varchar(20) = NULL,
 @CodigoTipoGarantia int,
 @EsNuevo bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia AND FechaAprobacion IS NOT NULL) THROW 51005,''''La garantia tiene historial contractual: conserve sus datos.'''',1;
UPDATE dbo.[Garantia] SET [VIN]=@VIN,[CodigoMarca]=@CodigoMarca,[CodigoLinea]=@CodigoLinea,[Anio]=@Anio,[ValorAgencia]=@ValorAgencia,[Placa]=@Placa,[CodigoTipoGarantia]=@CodigoTipoGarantia,[EsNuevo]=@EsNuevo WHERE [CodigoGarantia]=@CodigoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Garantia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Garantia] WHERE CONVERT(nvarchar(4000),[CodigoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[VIN]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoMarca]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoLinea]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Anio]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ValorAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Placa]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[EsNuevo]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Garantia_Eliminar] @CodigoGarantia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Garantia] WHERE [CodigoGarantia]=@CodigoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Garantia_Insertar] @VIN varchar(17),
 @CodigoMarca int,
 @CodigoLinea int,
 @Anio smallint,
 @ValorAgencia decimal(18,2),
 @Placa varchar(20) = NULL,
 @CodigoTipoGarantia int,
 @EsNuevo bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Garantia]([VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) OUTPUT INSERTED.[CodigoGarantia] AS Id VALUES(@VIN,@CodigoMarca,@CodigoLinea,@Anio,@ValorAgencia,@Placa,@CodigoTipoGarantia,@EsNuevo);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Garantia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Garantia] ORDER BY [CodigoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Linea_Actualizar] @CodigoMarca int,
 @CodigoLinea int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Linea] SET [Descripcion]=@Descripcion WHERE [CodigoMarca]=@CodigoMarca AND [CodigoLinea]=@CodigoLinea; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Linea_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Linea] WHERE CONVERT(nvarchar(4000),[CodigoMarca]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoLinea]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoMarca],[CodigoLinea];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Linea_Eliminar] @CodigoMarca int,
 @CodigoLinea int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Linea] WHERE [CodigoMarca]=@CodigoMarca AND [CodigoLinea]=@CodigoLinea; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Linea_Insertar] @CodigoMarca int,
 @CodigoLinea int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Linea]([CodigoMarca],[CodigoLinea],[Descripcion]) OUTPUT INSERTED.[CodigoMarca],INSERTED.[CodigoLinea] VALUES(@CodigoMarca,@CodigoLinea,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Linea_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Linea] ORDER BY [CodigoMarca],[CodigoLinea];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Marca_Actualizar] @CodigoMarca int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Marca] SET [Descripcion]=@Descripcion WHERE [CodigoMarca]=@CodigoMarca; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Marca_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Marca] WHERE CONVERT(nvarchar(4000),[CodigoMarca]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoMarca];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Marca_Eliminar] @CodigoMarca int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Marca] WHERE [CodigoMarca]=@CodigoMarca; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Marca_Insertar] @CodigoMarca int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Marca]([CodigoMarca],[Descripcion]) OUTPUT INSERTED.[CodigoMarca] VALUES(@CodigoMarca,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Marca_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Marca] ORDER BY [CodigoMarca];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Municipio_Actualizar] @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Municipio] SET [Descripcion]=@Descripcion WHERE [CodigoDepartamento]=@CodigoDepartamento AND [CodigoMunicipio]=@CodigoMunicipio; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Municipio_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Municipio] WHERE CONVERT(nvarchar(4000),[CodigoDepartamento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoMunicipio]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoDepartamento],[CodigoMunicipio];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Municipio_Eliminar] @CodigoDepartamento int,
 @CodigoMunicipio int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Municipio] WHERE [CodigoDepartamento]=@CodigoDepartamento AND [CodigoMunicipio]=@CodigoMunicipio; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Municipio_Insertar] @CodigoDepartamento int,
 @CodigoMunicipio int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Municipio]([CodigoDepartamento],[CodigoMunicipio],[Descripcion]) OUTPUT INSERTED.[CodigoDepartamento],INSERTED.[CodigoMunicipio] VALUES(@CodigoDepartamento,@CodigoMunicipio,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Municipio_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Municipio] ORDER BY [CodigoDepartamento],[CodigoMunicipio];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[ParametroCredito_Actualizar] @CodigoParametro int,
 @Nombre nvarchar(100),
 @Activo bit,
 @TasaAnual decimal(9,6),
 @ManejoMensual decimal(18,2),
 @TasaSeguroAuto decimal(9,6),
 @TasaSeguroVida decimal(9,6),
 @EngancheMinimo decimal(9,6),
 @ComisionPredeterminada decimal(9,6),
 @DepreciacionInicial decimal(9,6)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[ParametroCredito] SET [Nombre]=@Nombre,[Activo]=@Activo,[TasaAnual]=@TasaAnual,[ManejoMensual]=@ManejoMensual,[TasaSeguroAuto]=@TasaSeguroAuto,[TasaSeguroVida]=@TasaSeguroVida,[EngancheMinimo]=@EngancheMinimo,[ComisionPredeterminada]=@ComisionPredeterminada,[DepreciacionInicial]=@DepreciacionInicial WHERE [CodigoParametro]=@CodigoParametro; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[ParametroCredito_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[ParametroCredito] WHERE CONVERT(nvarchar(4000),[CodigoParametro]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Nombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Activo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaAnual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ManejoMensual]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroAuto]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TasaSeguroVida]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[EngancheMinimo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[ComisionPredeterminada]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[DepreciacionInicial]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoParametro];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[ParametroCredito_Eliminar] @CodigoParametro int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[ParametroCredito] WHERE [CodigoParametro]=@CodigoParametro; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[ParametroCredito_Insertar] @Nombre nvarchar(100),
 @Activo bit,
 @TasaAnual decimal(9,6),
 @ManejoMensual decimal(18,2),
 @TasaSeguroAuto decimal(9,6),
 @TasaSeguroVida decimal(9,6),
 @EngancheMinimo decimal(9,6),
 @ComisionPredeterminada decimal(9,6),
 @DepreciacionInicial decimal(9,6)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[ParametroCredito]([Nombre],[Activo],[TasaAnual],[ManejoMensual],[TasaSeguroAuto],[TasaSeguroVida],[EngancheMinimo],[ComisionPredeterminada],[DepreciacionInicial]) OUTPUT INSERTED.[CodigoParametro] AS Id VALUES(@Nombre,@Activo,@TasaAnual,@ManejoMensual,@TasaSeguroAuto,@TasaSeguroVida,@EngancheMinimo,@ComisionPredeterminada,@DepreciacionInicial);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[ParametroCredito_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[ParametroCredito] ORDER BY [CodigoParametro];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Persona_Actualizar] @CodigoPersona int,
 @DPI varchar(13) = NULL,
 @NIT varchar(20) = NULL,
 @PrimerNombre nvarchar(64),
 @SegundoNombre nvarchar(64) = NULL,
 @PrimerApellido nvarchar(64),
 @SegundoApellido nvarchar(64) = NULL,
 @FechaNacimiento date = NULL,
 @Genero char(1) = NULL,
 @CorreoElectronico nvarchar(254) = NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF @FechaNacimiento>=CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51001,''''La fecha de nacimiento debe ser anterior a hoy.'''',1;IF EXISTS(SELECT 1 FROM dbo.Deudor WHERE CodigoPersona=@CodigoPersona) AND (@DPI IS NULL OR @NIT IS NULL OR @CorreoElectronico IS NULL OR @FechaNacimiento IS NULL) THROW 51009,''''No quite datos obligatorios de un cliente.'''',1; IF EXISTS(SELECT 1 FROM dbo.Fiador WHERE CodigoPersona=@CodigoPersona) AND (@DPI IS NULL OR @NIT IS NULL OR @CorreoElectronico IS NULL) THROW 51010,''''No quite datos obligatorios de un fiador.'''',1; IF EXISTS(SELECT 1 FROM dbo.Vendedor WHERE CodigoPersona=@CodigoPersona) AND @DPI IS NULL THROW 51011,''''El vendedor requiere DPI.'''',1;
UPDATE dbo.[Persona] SET [DPI]=@DPI,[NIT]=@NIT,[PrimerNombre]=@PrimerNombre,[SegundoNombre]=@SegundoNombre,[PrimerApellido]=@PrimerApellido,[SegundoApellido]=@SegundoApellido,[FechaNacimiento]=@FechaNacimiento,[Genero]=@Genero,[CorreoElectronico]=@CorreoElectronico WHERE [CodigoPersona]=@CodigoPersona; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Persona_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Persona] WHERE CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[DPI]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[NIT]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PrimerNombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SegundoNombre]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[PrimerApellido]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[SegundoApellido]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[FechaNacimiento]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Genero]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CorreoElectronico]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPersona];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Persona_Eliminar] @CodigoPersona int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Persona] WHERE [CodigoPersona]=@CodigoPersona; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Persona_Insertar] @DPI varchar(13) = NULL,
 @NIT varchar(20) = NULL,
 @PrimerNombre nvarchar(64),
 @SegundoNombre nvarchar(64) = NULL,
 @PrimerApellido nvarchar(64),
 @SegundoApellido nvarchar(64) = NULL,
 @FechaNacimiento date = NULL,
 @Genero char(1) = NULL,
 @CorreoElectronico nvarchar(254) = NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF @FechaNacimiento>=CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51001,''''La fecha de nacimiento debe ser anterior a hoy.'''',1;
INSERT dbo.[Persona]([DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) OUTPUT INSERTED.[CodigoPersona] AS Id VALUES(@DPI,@NIT,@PrimerNombre,@SegundoNombre,@PrimerApellido,@SegundoApellido,@FechaNacimiento,@Genero,@CorreoElectronico);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Persona_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Persona] ORDER BY [CodigoPersona];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Referencia_Actualizar] @CodigoReferencia int,
 @CodigoPersona int,
 @LugarTrabajo nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF EXISTS(SELECT 1 FROM dbo.Referencia WHERE CodigoReferencia=@CodigoReferencia AND CodigoPersona<>@CodigoPersona) THROW 51015,''''No cambie la persona de una referencia; registre otra referencia.'''',1;
UPDATE dbo.[Referencia] SET [CodigoPersona]=@CodigoPersona,[LugarTrabajo]=@LugarTrabajo WHERE [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Referencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Referencia] WHERE CONVERT(nvarchar(4000),[CodigoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[LugarTrabajo]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Referencia_Eliminar] @CodigoReferencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Referencia] WHERE [CodigoReferencia]=@CodigoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Referencia_Insertar] @CodigoPersona int,
 @LugarTrabajo nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Referencia]([CodigoPersona],[LugarTrabajo]) OUTPUT INSERTED.[CodigoReferencia] AS Id VALUES(@CodigoPersona,@LugarTrabajo);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Referencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Referencia] ORDER BY [CodigoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte01_CreditosEmitidos] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;
 SELECT c.NumeroCredito,c.FechaAprobacion,c.CodigoDeudor,c.CodigoVendedor,c.PrecioContado,c.Enganche,c.MontoFinanciado,c.Plazo,c.TotalIntereses,c.TotalNetoRecaudable,c.Estado,c.FechaAnulacion
 FROM dbo.vw_CreditoResumen c WHERE c.FechaAprobacion>=@Desde AND c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) ORDER BY c.FechaAprobacion,c.NumeroCredito;
 SELECT COUNT(*) CreditosEmitidos,SUM(MontoFinanciado) CapitalColocadoBruto FROM dbo.vw_CreditoResumen WHERE FechaAprobacion>=@Desde AND FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta));

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte02_CarteraMora] @FechaCorte date=NULL,@DiasMinimos int=1
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;
 IF @DiasMinimos<1 OR @DiasMinimos IS NULL THROW 51302,''''Los dias minimos deben ser al menos uno.'''',1;
 SELECT NumeroCredito,CodigoDeudor,MIN(FechaVencimiento) PrimerVencimientoPendiente,MAX(DATEDIFF(day,FechaVencimiento,@FechaCorte)) DiasMora,SUM(SaldoPendiente) TotalVencidoPendiente,COUNT(*) CuotasVencidas
 FROM dbo.fn_Saldos(@FechaCorte) WHERE FechaVencimiento<@FechaCorte AND SaldoPendiente>0 GROUP BY NumeroCredito,CodigoDeudor HAVING MAX(DATEDIFF(day,FechaVencimiento,@FechaCorte))>=@DiasMinimos ORDER BY DiasMora DESC,TotalVencidoPendiente DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte03_PagosPorMedio] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;WITH Movimiento AS(
 SELECT CodigoTipoPago,Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,1 Recibido FROM dbo.vw_PagoDesglosado WHERE FechaPago>=@Desde AND FechaPago<DATEADD(day,1,CONVERT(datetime2,@Hasta))
 UNION ALL
 SELECT CodigoTipoPago,-Monto,-Capital,-Interes,-ManejoCuenta,-SeguroAuto,-SeguroVida,0 FROM dbo.vw_PagoDesglosado WHERE FechaAnulacion>=@Desde AND FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)))

 SELECT t.CodigoTipoPago,t.Descripcion,SUM(CASE WHEN m.Recibido=1 THEN 1 ELSE 0 END) PagosRecibidos,SUM(CASE WHEN m.Recibido=1 THEN m.Monto ELSE 0 END) ImporteRecibido,SUM(CASE WHEN m.Recibido=0 THEN -m.Monto ELSE 0 END) ImporteAnulado,SUM(m.Monto) MovimientoNeto
 FROM Movimiento m JOIN dbo.TipoPago t ON t.CodigoTipoPago=m.CodigoTipoPago GROUP BY t.CodigoTipoPago,t.Descripcion ORDER BY PagosRecibidos DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte04_VentasVendedor] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;
 SELECT v.CodigoVendedor,v.CodigoEmpleado,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Vendedor,COUNT(*) Creditos,SUM(c.MontoFinanciado) CapitalColocado
 FROM dbo.vw_CreditoResumen c JOIN dbo.Vendedor v ON v.CodigoVendedor=c.CodigoVendedor JOIN dbo.Persona p ON p.CodigoPersona=v.CodigoPersona
 WHERE c.FechaAprobacion>=@Desde AND c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@Hasta)))
 GROUP BY v.CodigoVendedor,v.CodigoEmpleado,p.PrimerNombre,p.SegundoNombre,p.PrimerApellido,p.SegundoApellido ORDER BY CapitalColocado DESC,Creditos DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte05_Cumpleaneros] @Mes int,@Anio int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  
 IF @Mes NOT BETWEEN 1 AND 12 OR @Anio NOT BETWEEN 1900 AND 9998 OR @Mes IS NULL OR @Anio IS NULL THROW 51303,''''Mes o anio invalido.'''',1;
 SELECT d.CodigoDeudor,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Cliente,p.FechaNacimiento,p.CorreoElectronico,@Anio-YEAR(p.FechaNacimiento) EdadQueCumple,
 CONCAT(N''''Estimado/a '''',CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido),N'''': en MAGIS-AUTO le deseamos un feliz cumpleanos. Que este nuevo anio de vida le traiga salud y buenos momentos. Gracias por su confianza. Atentamente, equipo MAGIS-AUTO.'''') CartaFelicitacion
 FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE MONTH(p.FechaNacimiento)=@Mes AND YEAR(p.FechaNacimiento)<=@Anio ORDER BY DAY(p.FechaNacimiento),d.CodigoDeudor;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte06_EstadoCuenta] @CodigoDeudor int,@FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Deudor WHERE CodigoDeudor=@CodigoDeudor) THROW 51304,''''Cliente inexistente.'''',1;
 SELECT NumeroCredito,SUM(Total) TotalPlan,SUM(Total-SaldoPendiente) PagadoAlCorte,SUM(SaldoPendiente) SaldoTotal,SUM(CapitalPendiente) SaldoCapital,SUM(CASE WHEN FechaVencimiento<@FechaCorte THEN SaldoPendiente ELSE 0 END) VencidoPendiente FROM dbo.fn_Saldos(@FechaCorte) WHERE CodigoDeudor=@CodigoDeudor GROUP BY NumeroCredito;
 SELECT * FROM dbo.fn_Saldos(@FechaCorte) WHERE CodigoDeudor=@CodigoDeudor ORDER BY NumeroCredito,Cuota;
 SELECT p.*,CASE WHEN p.FechaAnulacion IS NULL OR p.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte)) THEN 1 ELSE 0 END VigenteAlCorte FROM dbo.vw_PagoDesglosado p JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=p.NumeroCredito WHERE c.CodigoDeudor=@CodigoDeudor AND p.FechaPago<DATEADD(day,1,CONVERT(datetime2,@FechaCorte)) ORDER BY p.FechaPago,p.CodigoPago;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte07_PlanPagos] @NumeroCredito varchar(20),@FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.vw_CreditoResumen WHERE NumeroCredito=@NumeroCredito) THROW 51305,''''Credito inexistente.'''',1;
 SELECT c.NumeroCredito,c.Estado,c.FechaAprobacion,c.Plazo,c.PrecioContado,c.Enganche,c.MontoFinanciado,c.TasaAnual,c.TotalIntereses,c.TotalNetoRecaudable FROM dbo.vw_CreditoResumen c WHERE NumeroCredito=@NumeroCredito;
 SELECT q.*,s.SaldoPendiente,s.CapitalPendiente FROM dbo.vw_CuotaDesglosada q LEFT JOIN dbo.fn_Saldos(@FechaCorte)s ON s.NumeroCredito=q.NumeroCredito AND s.Cuota=q.Cuota WHERE q.NumeroCredito=@NumeroCredito ORDER BY q.Cuota;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte08_Comisiones] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;
 WITH Mov AS(
 SELECT p.NumeroCredito,p.Comision Generada,CONVERT(decimal(18,2),0) Revertida FROM dbo.vw_PagoDesglosado p WHERE p.FechaPago>=@Desde AND p.FechaPago<DATEADD(day,1,CONVERT(datetime2,@Hasta))
 UNION ALL SELECT p.NumeroCredito,0,p.Comision FROM dbo.vw_PagoDesglosado p WHERE p.FechaAnulacion>=@Desde AND p.FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)))
 SELECT v.CodigoVendedor,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Vendedor,SUM(m.Generada) ComisionGenerada,SUM(m.Revertida) ComisionRevertida,SUM(m.Generada-m.Revertida) ComisionNeta
 FROM Mov m JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=m.NumeroCredito JOIN dbo.Vendedor v ON v.CodigoVendedor=c.CodigoVendedor JOIN dbo.Persona p ON p.CodigoPersona=v.CodigoPersona GROUP BY v.CodigoVendedor,p.PrimerNombre,p.SegundoNombre,p.PrimerApellido,p.SegundoApellido ORDER BY ComisionNeta DESC;

  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte09_CapitalPendiente] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT NumeroCredito,CodigoDeudor,SUM(Capital) CapitalFinanciado,SUM(Capital-CapitalPendiente) CapitalRecuperado,SUM(CapitalPendiente) CapitalPendiente FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito,CodigoDeudor ORDER BY CapitalPendiente DESC;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte10_Intereses] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT NumeroCredito,SUM(Interes) InteresesDelContrato,SUM(Interes-InteresPendiente) InteresesCobrados,SUM(InteresPendiente) InteresesPendientes FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito ORDER BY NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte11_ProximosVencimientos] @FechaCorte date=NULL,@Dias int=30
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;IF @Dias NOT BETWEEN 1 AND 365 OR @Dias IS NULL THROW 51306,''''Horizonte permitido: 1 a 365 dias.'''',1; SELECT * FROM dbo.fn_Saldos(@FechaCorte) WHERE SaldoPendiente>0 AND FechaVencimiento>=@FechaCorte AND FechaVencimiento<=DATEADD(day,@Dias,@FechaCorte) ORDER BY FechaVencimiento,NumeroCredito,Cuota;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte12_AbonosParciales] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT NumeroCredito,Cuota,FechaVencimiento,Total,Total-SaldoPendiente Pagado,SaldoPendiente FROM dbo.fn_Saldos(@FechaCorte) WHERE SaldoPendiente>0 AND SaldoPendiente<Total ORDER BY FechaVencimiento,NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte13_CreditosMarcaLinea] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;SELECT m.CodigoMarca,m.Descripcion Marca,l.CodigoLinea,l.Descripcion Linea,COUNT(*) Creditos,SUM(c.MontoFinanciado) CapitalFinanciado FROM dbo.vw_CreditoResumen c JOIN dbo.Garantia g ON g.CodigoGarantia=c.CodigoGarantia JOIN dbo.Marca m ON m.CodigoMarca=g.CodigoMarca JOIN dbo.Linea l ON l.CodigoMarca=g.CodigoMarca AND l.CodigoLinea=g.CodigoLinea WHERE c.FechaAprobacion>=@Desde AND c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@Hasta))) GROUP BY m.CodigoMarca,m.Descripcion,l.CodigoLinea,l.Descripcion ORDER BY CapitalFinanciado DESC;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte14_CarteraAgenciaRegion] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT a.CodigoAgencia,a.Nombre,a.Region,COUNT(DISTINCT s.NumeroCredito) CreditosConSaldo,SUM(s.CapitalPendiente) CapitalPendiente,SUM(s.SaldoPendiente) SaldoContractual,SUM(CASE WHEN s.FechaVencimiento<@FechaCorte THEN s.SaldoPendiente ELSE 0 END) Vencido FROM dbo.fn_Saldos(@FechaCorte)s JOIN dbo.Agencia a ON a.CodigoAgencia=s.CodigoAgencia WHERE s.SaldoPendiente>0 GROUP BY a.CodigoAgencia,a.Nombre,a.Region ORDER BY CapitalPendiente DESC;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte15_MoraRangos] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;WITH Mora AS(SELECT NumeroCredito,MAX(DATEDIFF(day,FechaVencimiento,@FechaCorte)) Dias,SUM(SaldoPendiente) Vencido FROM dbo.fn_Saldos(@FechaCorte) WHERE FechaVencimiento<@FechaCorte AND SaldoPendiente>0 GROUP BY NumeroCredito),R AS(SELECT *,CASE WHEN Dias<=30 THEN ''''01-30'''' WHEN Dias<=60 THEN ''''31-60'''' WHEN Dias<=90 THEN ''''61-90'''' ELSE ''''91 o mas'''' END Rango FROM Mora) SELECT Rango,COUNT(*) Creditos,SUM(Vencido) VencidoPendiente FROM R GROUP BY Rango ORDER BY MIN(Dias);
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte16_GarantiaContraCapital] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;WITH S AS(SELECT NumeroCredito,SUM(CapitalPendiente) CapitalPendiente FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito) SELECT c.NumeroCredito,g.VIN,c.PrecioContado,v.FechaValoracion,v.ValorDepreciado,s.CapitalPendiente,v.ValorDepreciado-s.CapitalPendiente MargenGarantia,CASE WHEN v.ValorDepreciado<s.CapitalPendiente THEN 1 ELSE 0 END GarantiaInsuficiente FROM S s JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=s.NumeroCredito JOIN dbo.Garantia g ON g.CodigoGarantia=c.CodigoGarantia OUTER APPLY(SELECT TOP(1) d.FechaValoracion,d.ValorDepreciado FROM dbo.vw_DepreciacionCalculada d WHERE d.CodigoGarantia=c.CodigoGarantia AND d.FechaValoracion<=@FechaCorte ORDER BY d.FechaValoracion DESC,d.CodigoDepreciacion DESC)v ORDER BY MargenGarantia;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte17_DepreciacionCostoFinanciamiento] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;SELECT c.NumeroCredito,c.PrecioContado,c.Enganche,c.MontoFinanciado,c.TotalIntereses,c.TotalNetoRecaudable,c.TotalNetoRecaudable-c.MontoFinanciado CostoFinanciamientoYCargos,c.Enganche+c.TotalNetoRecaudable DesembolsoTotalCliente,v.FechaValoracion,v.ValorDepreciado,c.PrecioContado-v.ValorDepreciado PerdidaValorEstimada FROM dbo.vw_CreditoResumen c OUTER APPLY(SELECT TOP(1) d.FechaValoracion,d.ValorDepreciado FROM dbo.vw_DepreciacionCalculada d WHERE d.CodigoGarantia=c.CodigoGarantia AND d.FechaValoracion<=@FechaCorte ORDER BY d.FechaValoracion DESC,d.CodigoDepreciacion DESC)v WHERE c.FechaAprobacion<DATEADD(day,1,CONVERT(datetime2,@FechaCorte)) AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte))) ORDER BY c.NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte18_CreditosFiador] @FechaCorte date=NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala())); IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;WITH S AS(SELECT NumeroCredito,SUM(CapitalPendiente) CapitalPendiente,SUM(SaldoPendiente) SaldoTotal FROM dbo.fn_Saldos(@FechaCorte) GROUP BY NumeroCredito) SELECT f.CodigoFiador,CONCAT(p.PrimerNombre,N'''' '''',p.SegundoNombre,N'''' '''',p.PrimerApellido,N'''' '''',p.SegundoApellido) Fiador,c.NumeroCredito,s.CapitalPendiente,s.SaldoTotal,COUNT(*) OVER(PARTITION BY f.CodigoFiador) CreditosRespaldados FROM dbo.CreditoFiador cf JOIN dbo.Fiador f ON f.CodigoFiador=cf.CodigoFiador JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona JOIN dbo.vw_CreditoResumen c ON c.NumeroCredito=cf.NumeroCredito JOIN S s ON s.NumeroCredito=c.NumeroCredito WHERE s.SaldoTotal>0 ORDER BY f.CodigoFiador,c.NumeroCredito;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte19_RecaudacionComponentes] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;WITH Movimiento AS(
 SELECT CodigoTipoPago,Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,1 Recibido FROM dbo.vw_PagoDesglosado WHERE FechaPago>=@Desde AND FechaPago<DATEADD(day,1,CONVERT(datetime2,@Hasta))
 UNION ALL
 SELECT CodigoTipoPago,-Monto,-Capital,-Interes,-ManejoCuenta,-SeguroAuto,-SeguroVida,0 FROM dbo.vw_PagoDesglosado WHERE FechaAnulacion>=@Desde AND FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)))
SELECT COALESCE(SUM(Capital),0) CapitalNeto,COALESCE(SUM(Interes),0) InteresesNetos,COALESCE(SUM(ManejoCuenta),0) ManejoNeto,COALESCE(SUM(SeguroAuto),0) SeguroAutoNeto,COALESCE(SUM(SeguroVida),0) SeguroVidaNeto,COALESCE(SUM(Monto),0) MovimientoNeto FROM Movimiento;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Reporte20_PagosAnulados] @Desde date,@Hasta date
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF @Desde IS NULL OR @Hasta IS NULL OR @Desde>@Hasta OR @Hasta=''''99991231'''' THROW 51300,''''Periodo de fechas invalido.'''',1;SELECT CodigoPago,Comprobante,NumeroCredito,Cuota,FechaPago,FechaAnulacion,Monto,Comision ComisionRevertida,MotivoAnulacion,AnuladoPor FROM dbo.vw_PagoDesglosado WHERE FechaAnulacion>=@Desde AND FechaAnulacion<DATEADD(day,1,CONVERT(datetime2,@Hasta)) ORDER BY FechaAnulacion,CodigoPago;
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[ResumenCredito_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[ResumenCredito] WHERE CONVERT(nvarchar(4000),[NumeroCredito]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalIntereses]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[TotalNetoRecaudable]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[ResumenCredito_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[ResumenCredito] ORDER BY [NumeroCredito];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Telefono_Actualizar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoTelefono int,
 @Numero varchar(32)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[Telefono] SET [CodigoTipoTelefono]=@CodigoTipoTelefono,[Numero]=@Numero WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Telefono_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Telefono] WHERE CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Correlativo]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoTipoTelefono]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Numero]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Telefono_Eliminar] @CodigoPersona int,
 @Correlativo smallint
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Telefono] WHERE [CodigoPersona]=@CodigoPersona AND [Correlativo]=@Correlativo; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Telefono_Insertar] @CodigoPersona int,
 @Correlativo smallint,
 @CodigoTipoTelefono int,
 @Numero varchar(32)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[Telefono]([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) OUTPUT INSERTED.[CodigoPersona],INSERTED.[Correlativo] VALUES(@CodigoPersona,@Correlativo,@CodigoTipoTelefono,@Numero);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Telefono_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Telefono] ORDER BY [CodigoPersona],[Correlativo];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoDireccion_Actualizar] @CodigoTipoDireccion int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoDireccion] SET [Descripcion]=@Descripcion WHERE [CodigoTipoDireccion]=@CodigoTipoDireccion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoDireccion_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoDireccion] WHERE CONVERT(nvarchar(4000),[CodigoTipoDireccion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoDireccion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoDireccion_Eliminar] @CodigoTipoDireccion int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoDireccion] WHERE [CodigoTipoDireccion]=@CodigoTipoDireccion; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoDireccion_Insertar] @CodigoTipoDireccion int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoDireccion]([CodigoTipoDireccion],[Descripcion]) OUTPUT INSERTED.[CodigoTipoDireccion] VALUES(@CodigoTipoDireccion,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoDireccion_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoDireccion] ORDER BY [CodigoTipoDireccion];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoGarantia_Actualizar] @CodigoTipoGarantia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoGarantia] SET [Descripcion]=@Descripcion WHERE [CodigoTipoGarantia]=@CodigoTipoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoGarantia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoGarantia] WHERE CONVERT(nvarchar(4000),[CodigoTipoGarantia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoGarantia_Eliminar] @CodigoTipoGarantia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoGarantia] WHERE [CodigoTipoGarantia]=@CodigoTipoGarantia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoGarantia_Insertar] @CodigoTipoGarantia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoGarantia]([CodigoTipoGarantia],[Descripcion]) OUTPUT INSERTED.[CodigoTipoGarantia] VALUES(@CodigoTipoGarantia,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoGarantia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoGarantia] ORDER BY [CodigoTipoGarantia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoPago_Actualizar] @CodigoTipoPago int,
 @Descripcion nvarchar(128),
 @RequiereReferencia bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoPago] SET [Descripcion]=@Descripcion,[RequiereReferencia]=@RequiereReferencia WHERE [CodigoTipoPago]=@CodigoTipoPago; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoPago_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoPago] WHERE CONVERT(nvarchar(4000),[CodigoTipoPago]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[RequiereReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoPago_Eliminar] @CodigoTipoPago int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoPago] WHERE [CodigoTipoPago]=@CodigoTipoPago; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoPago_Insertar] @CodigoTipoPago int,
 @Descripcion nvarchar(128),
 @RequiereReferencia bit
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoPago]([CodigoTipoPago],[Descripcion],[RequiereReferencia]) OUTPUT INSERTED.[CodigoTipoPago] VALUES(@CodigoTipoPago,@Descripcion,@RequiereReferencia);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoPago_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoPago] ORDER BY [CodigoTipoPago];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoReferencia_Actualizar] @CodigoTipoReferencia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoReferencia] SET [Descripcion]=@Descripcion WHERE [CodigoTipoReferencia]=@CodigoTipoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoReferencia_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoReferencia] WHERE CONVERT(nvarchar(4000),[CodigoTipoReferencia]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoReferencia_Eliminar] @CodigoTipoReferencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoReferencia] WHERE [CodigoTipoReferencia]=@CodigoTipoReferencia; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoReferencia_Insertar] @CodigoTipoReferencia int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoReferencia]([CodigoTipoReferencia],[Descripcion]) OUTPUT INSERTED.[CodigoTipoReferencia] VALUES(@CodigoTipoReferencia,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoReferencia_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoReferencia] ORDER BY [CodigoTipoReferencia];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoTelefono_Actualizar] @CodigoTipoTelefono int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
UPDATE dbo.[TipoTelefono] SET [Descripcion]=@Descripcion WHERE [CodigoTipoTelefono]=@CodigoTipoTelefono; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoTelefono_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[TipoTelefono] WHERE CONVERT(nvarchar(4000),[CodigoTipoTelefono]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[Descripcion]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoTipoTelefono];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoTelefono_Eliminar] @CodigoTipoTelefono int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[TipoTelefono] WHERE [CodigoTipoTelefono]=@CodigoTipoTelefono; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoTelefono_Insertar] @CodigoTipoTelefono int,
 @Descripcion nvarchar(128)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
INSERT dbo.[TipoTelefono]([CodigoTipoTelefono],[Descripcion]) OUTPUT INSERTED.[CodigoTipoTelefono] VALUES(@CodigoTipoTelefono,@Descripcion);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[TipoTelefono_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[TipoTelefono] ORDER BY [CodigoTipoTelefono];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Vendedor_Actualizar] @CodigoVendedor int,
 @CodigoEmpleado varchar(30),
 @CodigoPersona int,
 @CodigoAgencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;IF EXISTS(SELECT 1 FROM dbo.Vendedor WHERE CodigoVendedor=@CodigoVendedor AND CodigoPersona<>@CodigoPersona) THROW 51013,''''No se cambia la identidad de un rol; registre otro si corresponde.'''',1;
UPDATE dbo.[Vendedor] SET [CodigoEmpleado]=@CodigoEmpleado,[CodigoPersona]=@CodigoPersona,[CodigoAgencia]=@CodigoAgencia WHERE [CodigoVendedor]=@CodigoVendedor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Vendedor_Buscar] @Criterio nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  IF NULLIF(LTRIM(RTRIM(@Criterio)),N'''''''') IS NULL THROW 51007,''''Indique un criterio de busqueda.'''',1; SELECT * FROM dbo.[Vendedor] WHERE CONVERT(nvarchar(4000),[CodigoVendedor]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoEmpleado]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoPersona]) LIKE N''''%''''+@Criterio+N''''%'''' OR CONVERT(nvarchar(4000),[CodigoAgencia]) LIKE N''''%''''+@Criterio+N''''%'''' ORDER BY [CodigoVendedor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Vendedor_Eliminar] @CodigoVendedor int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  
DELETE dbo.[Vendedor] WHERE [CodigoVendedor]=@CodigoVendedor; IF @@ROWCOUNT=0 THROW 51008,''''Registro no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Vendedor_Insertar] @CodigoEmpleado varchar(30),
 @CodigoPersona int,
 @CodigoAgencia int
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND DPI IS NOT NULL) THROW 51012,''''Complete los datos obligatorios de la persona antes de asignar este rol.'''',1;
INSERT dbo.[Vendedor]([CodigoEmpleado],[CodigoPersona],[CodigoAgencia]) OUTPUT INSERTED.[CodigoVendedor] AS Id VALUES(@CodigoEmpleado,@CodigoPersona,@CodigoAgencia);
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER PROCEDURE api.[Vendedor_Listar] 
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  
  SELECT * FROM dbo.[Vendedor] ORDER BY [CodigoVendedor];
  
 END TRY
 BEGIN CATCH
  
  THROW;
 END CATCH;
END;'');
EXEC(N''CREATE OR ALTER VIEW dbo.vw_CreditoResumen AS
 SELECT c.*,CONVERT(decimal(18,2),c.PrecioContado-c.Enganche) AS MontoFinanciado,
 r.TotalIntereses,r.TotalNetoRecaudable
 FROM dbo.Credito c LEFT JOIN dbo.ResumenCredito r ON r.NumeroCredito=c.NumeroCredito;'');
EXEC(N''CREATE OR ALTER VIEW dbo.vw_CuotaDesglosada AS
 SELECT q.*,c.ManejoMensual AS ManejoCuenta,s.SeguroAuto,s.SeguroVida,
 CONVERT(decimal(18,2),q.Capital+q.Interes+c.ManejoMensual+s.SeguroAuto+s.SeguroVida) AS Total
 FROM dbo.DetalleCuota q JOIN dbo.Credito c ON c.NumeroCredito=q.NumeroCredito
 CROSS APPLY(SELECT CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroAuto,2)) SeguroAuto,
 CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroVida,2)) SeguroVida)s;'');
EXEC(N''CREATE OR ALTER VIEW dbo.vw_DepreciacionCalculada AS
 SELECT d.*,CONVERT(decimal(18,2),ROUND(d.ValorOriginal*(1-d.Porcentaje),2)) AS ValorDepreciado
 FROM dbo.Depreciacion d;'');
EXEC(N''CREATE OR ALTER VIEW dbo.vw_PagoDesglosado AS
 SELECT p.*,c.PorcentajeComision,
 CONVERT(decimal(18,2),ROUND(p.Monto*c.PorcentajeComision,2)) AS Comision
 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito;'');
-- Sustituir catálogos iniciales por la fotografía exacta de las 26 tablas.
ALTER TABLE dbo.[Agencia] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Credito] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[CreditoFiador] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Departamento] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Depreciacion] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DetalleCuota] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DetallePago] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DetalleReferencia] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Deudor] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Direccion] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Fiador] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Garantia] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Linea] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Marca] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Municipio] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[ParametroCredito] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Persona] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Referencia] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[ResumenCredito] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Telefono] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoDireccion] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoGarantia] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoPago] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoReferencia] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoTelefono] NOCHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Vendedor] NOCHECK CONSTRAINT ALL;
DELETE FROM dbo.[Agencia];
DELETE FROM dbo.[Credito];
DELETE FROM dbo.[CreditoFiador];
DELETE FROM dbo.[Departamento];
DELETE FROM dbo.[Depreciacion];
DELETE FROM dbo.[DetalleCuota];
DELETE FROM dbo.[DetallePago];
DELETE FROM dbo.[DetalleReferencia];
DELETE FROM dbo.[Deudor];
DELETE FROM dbo.[Direccion];
DELETE FROM dbo.[Fiador];
DELETE FROM dbo.[Garantia];
DELETE FROM dbo.[Linea];
DELETE FROM dbo.[Marca];
DELETE FROM dbo.[Municipio];
DELETE FROM dbo.[ParametroCredito];
DELETE FROM dbo.[Persona];
DELETE FROM dbo.[Referencia];
DELETE FROM dbo.[ResumenCredito];
DELETE FROM dbo.[Telefono];
DELETE FROM dbo.[TipoDireccion];
DELETE FROM dbo.[TipoGarantia];
DELETE FROM dbo.[TipoPago];
DELETE FROM dbo.[TipoReferencia];
DELETE FROM dbo.[TipoTelefono];
DELETE FROM dbo.[Vendedor];
SET IDENTITY_INSERT dbo.[Agencia] ON;
INSERT INTO dbo.[Agencia] ([CodigoAgencia],[Nombre],[Region]) VALUES (1,N''Agencia academica Jalapa'',N''Oriente'');
SET IDENTITY_INSERT dbo.[Agencia] OFF;
DBCC CHECKIDENT (''dbo.Agencia'', RESEED, 12) WITH NO_INFOMSGS;
INSERT INTO dbo.[Credito] ([NumeroCredito],[CodigoDeudor],[CodigoGarantia],[CodigoVendedor],[CodigoAgencia],[CodigoParametro],[Plazo],[PrecioContado],[Enganche],[EngancheMinimo],[TasaAnual],[ManejoMensual],[TasaSeguroAuto],[TasaSeguroVida],[PorcentajeComision],[FiadoresRequeridos],[Estado],[FechaAprobacion],[AprobadoPor],[FechaAnulacion],[MotivoAnulacion],[AnuladoPor],[FechaPresentacion],[PresentadoPor]) VALUES (N''PRUEBA-CREDITO-01'',6,14,16,1,1,12,100000.00,20000.00,0.200000,0.125000,25.00,0.001500,0.000500,0.020000,1,N''VIGENTE'',CONVERT(datetime2,N''2026-10-12T16:21:54.0000000'',126),N''Diego - prueba académica'',NULL,NULL,NULL,CONVERT(datetime2,N''2026-10-12T16:21:11.0000000'',126),N''Diego - prueba académica'');
INSERT INTO dbo.[CreditoFiador] ([NumeroCredito],[CodigoFiador]) VALUES (N''PRUEBA-CREDITO-01'',4);
INSERT INTO dbo.[Departamento] ([CodigoDepartamento],[Descripcion]) VALUES (21,N''Jalapa'');
INSERT INTO dbo.[Departamento] ([CodigoDepartamento],[Descripcion]) VALUES (22,N''Jutiapa'');
SET IDENTITY_INSERT dbo.[Depreciacion] ON;
INSERT INTO dbo.[Depreciacion] ([CodigoDepreciacion],[CodigoGarantia],[FechaValoracion],[ValorOriginal],[Porcentaje],[Observacion]) VALUES (2,14,CONVERT(date,N''2026-10-12'',23),100000.00,0.150000,N''Valoracion inicial al aprobar PRUEBA-CREDITO-01'');
SET IDENTITY_INSERT dbo.[Depreciacion] OFF;
DBCC CHECKIDENT (''dbo.Depreciacion'', RESEED, 2) WITH NO_INFOMSGS;
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',1,CONVERT(date,N''2026-11-12'',23),6293.30,833.33);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',2,CONVERT(date,N''2026-12-12'',23),6358.85,767.78);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',3,CONVERT(date,N''2027-01-12'',23),6425.09,701.54);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',4,CONVERT(date,N''2027-02-12'',23),6492.02,634.61);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',5,CONVERT(date,N''2027-03-12'',23),6559.64,566.99);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',6,CONVERT(date,N''2027-04-12'',23),6627.97,498.66);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',7,CONVERT(date,N''2027-05-12'',23),6697.01,429.62);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',8,CONVERT(date,N''2027-06-12'',23),6766.77,359.86);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',9,CONVERT(date,N''2027-07-12'',23),6837.26,289.37);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',10,CONVERT(date,N''2027-08-12'',23),6908.48,218.15);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',11,CONVERT(date,N''2027-09-12'',23),6980.45,146.18);
INSERT INTO dbo.[DetalleCuota] ([NumeroCredito],[Cuota],[FechaVencimiento],[Capital],[Interes]) VALUES (N''PRUEBA-CREDITO-01'',12,CONVERT(date,N''2027-10-12'',23),7053.16,73.47);
SET IDENTITY_INSERT dbo.[DetallePago] ON;
INSERT INTO dbo.[DetallePago] ([CodigoPago],[Comprobante],[NumeroCredito],[Cuota],[FechaPago],[CodigoTipoPago],[ReferenciaBancaria],[Monto],[Capital],[Interes],[ManejoCuenta],[SeguroAuto],[SeguroVida],[RegistradoPor],[FechaAnulacion],[MotivoAnulacion],[AnuladoPor],[Observacion]) VALUES (1,1,N''PRUEBA-CREDITO-01'',1,CONVERT(datetime2,N''2026-10-13T19:31:48.0000000'',126),5,NULL,1000.00,860.73,113.97,3.42,16.41,5.47,N''Diego prueba'',NULL,NULL,NULL,N''Cuota 1'');
INSERT INTO dbo.[DetallePago] ([CodigoPago],[Comprobante],[NumeroCredito],[Cuota],[FechaPago],[CodigoTipoPago],[ReferenciaBancaria],[Monto],[Capital],[Interes],[ManejoCuenta],[SeguroAuto],[SeguroVida],[RegistradoPor],[FechaAnulacion],[MotivoAnulacion],[AnuladoPor],[Observacion]) VALUES (2,2,N''PRUEBA-CREDITO-01'',1,CONVERT(datetime2,N''2026-10-13T19:43:03.0000000'',126),5,NULL,6311.63,5432.57,719.36,21.58,103.59,34.53,N''Diego prueba'',CONVERT(datetime2,N''2026-10-13T19:45:56.0000000'',126),N''Prueba de anulación de pago'',N''Diego prueba'',N''Cuota 1 completada — observación corregida'');
INSERT INTO dbo.[DetallePago] ([CodigoPago],[Comprobante],[NumeroCredito],[Cuota],[FechaPago],[CodigoTipoPago],[ReferenciaBancaria],[Monto],[Capital],[Interes],[ManejoCuenta],[SeguroAuto],[SeguroVida],[RegistradoPor],[FechaAnulacion],[MotivoAnulacion],[AnuladoPor],[Observacion]) VALUES (3,3,N''PRUEBA-CREDITO-01'',1,CONVERT(datetime2,N''2026-10-13T19:47:59.0000000'',126),2,N''PRUEBA-ACH-001'',500.00,430.36,56.99,1.71,8.21,2.73,N''DIego prueba'',NULL,NULL,NULL,N''pago con transferencia'');
SET IDENTITY_INSERT dbo.[DetallePago] OFF;
DBCC CHECKIDENT (''dbo.DetallePago'', RESEED, 3) WITH NO_INFOMSGS;
INSERT INTO dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (6,5,1,N''Casado'');
INSERT INTO dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (6,6,1,N''Casada'');
INSERT INTO dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (6,7,2,N''Soltero'');
SET IDENTITY_INSERT dbo.[Deudor] ON;
INSERT INTO dbo.[Deudor] ([CodigoDeudor],[CodigoPersona]) VALUES (6,16);
SET IDENTITY_INSERT dbo.[Deudor] OFF;
DBCC CHECKIDENT (''dbo.Deudor'', RESEED, 12) WITH NO_INFOMSGS;
INSERT INTO dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (16,1,1,21,1,N''Dirección ficticia de prueba'');
INSERT INTO dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (17,1,1,21,1,N''ddfsfes'');
INSERT INTO dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (18,1,1,21,1,N''dfesdfea'');
INSERT INTO dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (19,1,2,21,1,N''ajkdkad'');
INSERT INTO dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (32,1,1,21,1,N''Zona 1'');
SET IDENTITY_INSERT dbo.[Fiador] ON;
INSERT INTO dbo.[Fiador] ([CodigoFiador],[CodigoPersona]) VALUES (4,32);
SET IDENTITY_INSERT dbo.[Fiador] OFF;
DBCC CHECKIDENT (''dbo.Fiador'', RESEED, 4) WITH NO_INFOMSGS;
SET IDENTITY_INSERT dbo.[Garantia] ON;
INSERT INTO dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (14,N''PRUEBA00000000001'',4,1,2026,100000.00,NULL,1,1);
SET IDENTITY_INSERT dbo.[Garantia] OFF;
DBCC CHECKIDENT (''dbo.Garantia'', RESEED, 14) WITH NO_INFOMSGS;
INSERT INTO dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (1,1,N''Corolla'');
INSERT INTO dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (2,1,N''Accent'');
INSERT INTO dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (3,1,N''Soluto'');
INSERT INTO dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (4,1,N''Versa'');
INSERT INTO dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (5,1,N''Swift'');
INSERT INTO dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (1,N''Toyota'');
INSERT INTO dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (2,N''Hyundai'');
INSERT INTO dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (3,N''Kia'');
INSERT INTO dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (4,N''Nissan'');
INSERT INTO dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (5,N''Suzuki'');
INSERT INTO dbo.[Municipio] ([CodigoDepartamento],[CodigoMunicipio],[Descripcion]) VALUES (21,1,N''Jalapa'');
INSERT INTO dbo.[Municipio] ([CodigoDepartamento],[CodigoMunicipio],[Descripcion]) VALUES (22,1,N''Jutiapa'');
SET IDENTITY_INSERT dbo.[ParametroCredito] ON;
INSERT INTO dbo.[ParametroCredito] ([CodigoParametro],[Nombre],[Activo],[TasaAnual],[ManejoMensual],[TasaSeguroAuto],[TasaSeguroVida],[EngancheMinimo],[ComisionPredeterminada],[DepreciacionInicial]) VALUES (1,N''Condiciones academicas iniciales'',1,0.125000,25.00,0.001500,0.000500,0.200000,0.020000,0.150000);
SET IDENTITY_INSERT dbo.[ParametroCredito] OFF;
DBCC CHECKIDENT (''dbo.ParametroCredito'', RESEED, 1) WITH NO_INFOMSGS;
SET IDENTITY_INSERT dbo.[Persona] ON;
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (6,N''9990000000001'',NULL,N''Prueba'',NULL,N''Diego'',NULL,NULL,NULL,NULL);
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (16,N''9990000000002'',N''PRUEBA-CLIENTE-01'',N''Cliente'',N''Editado'',N''Prueba'',NULL,CONVERT(date,N''1998-08-15'',23),NULL,N''cliente.prueba@example.com'');
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (17,NULL,NULL,N''papa'',NULL,N''prueba'',NULL,NULL,NULL,NULL);
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (18,NULL,NULL,N''mama'',NULL,N''prueba'',NULL,NULL,NULL,NULL);
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (19,NULL,NULL,N''jose'',NULL,N''coño'',NULL,NULL,NULL,NULL);
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (29,N''9990000000003'',N''PRUEBA-FIADOR-01'',N''Fiador'',N''Editado'',N''Prueba'',NULL,NULL,NULL,N''fiador.prueba@example.com'');
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (31,N''9990000000011'',NULL,N''Vendedor'',NULL,N''Credito'',NULL,NULL,NULL,NULL);
INSERT INTO dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (32,N''9990000000012'',N''PRUEBA-FIADOR-02'',N''Fiador'',NULL,N''Credito'',NULL,NULL,NULL,N''fiador.credito@example.com'');
SET IDENTITY_INSERT dbo.[Persona] OFF;
DBCC CHECKIDENT (''dbo.Persona'', RESEED, 32) WITH NO_INFOMSGS;
SET IDENTITY_INSERT dbo.[Referencia] ON;
INSERT INTO dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (5,17,N''Hospital'');
INSERT INTO dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (6,18,N''Muni'');
INSERT INTO dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (7,19,N''Banco'');
SET IDENTITY_INSERT dbo.[Referencia] OFF;
DBCC CHECKIDENT (''dbo.Referencia'', RESEED, 11) WITH NO_INFOMSGS;
INSERT INTO dbo.[ResumenCredito] ([NumeroCredito],[TotalIntereses],[TotalNetoRecaudable]) VALUES (N''PRUEBA-CREDITO-01'',5519.56,87739.56);
INSERT INTO dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (16,1,1,N''55551234'');
INSERT INTO dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (16,2,1,N''55555678'');
INSERT INTO dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (17,1,1,N''55048015'');
INSERT INTO dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (18,1,1,N''84518718'');
INSERT INTO dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (19,1,3,N''54949828'');
INSERT INTO dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (29,1,1,N''55551234'');
INSERT INTO dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (32,1,1,N''74169728'');
INSERT INTO dbo.[TipoDireccion] ([CodigoTipoDireccion],[Descripcion]) VALUES (1,N''Particular'');
INSERT INTO dbo.[TipoDireccion] ([CodigoTipoDireccion],[Descripcion]) VALUES (2,N''Trabajo'');
INSERT INTO dbo.[TipoDireccion] ([CodigoTipoDireccion],[Descripcion]) VALUES (3,N''Otra'');
INSERT INTO dbo.[TipoGarantia] ([CodigoTipoGarantia],[Descripcion]) VALUES (1,N''Vehiculo nuevo de agencia'');
INSERT INTO dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (1,N''Deposito bancario'',1);
INSERT INTO dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (2,N''Transferencia ACH'',1);
INSERT INTO dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (3,N''Tarjeta de credito'',1);
INSERT INTO dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (4,N''Tarjeta de debito'',1);
INSERT INTO dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (5,N''Efectivo en ventanilla'',0);
INSERT INTO dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (1,N''Familiar'');
INSERT INTO dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (2,N''Amistad'');
INSERT INTO dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (3,N''Laboral'');
INSERT INTO dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (4,N''Otra'');
INSERT INTO dbo.[TipoTelefono] ([CodigoTipoTelefono],[Descripcion]) VALUES (1,N''Celular'');
INSERT INTO dbo.[TipoTelefono] ([CodigoTipoTelefono],[Descripcion]) VALUES (2,N''Casa'');
INSERT INTO dbo.[TipoTelefono] ([CodigoTipoTelefono],[Descripcion]) VALUES (3,N''Trabajo'');
SET IDENTITY_INSERT dbo.[Vendedor] ON;
INSERT INTO dbo.[Vendedor] ([CodigoVendedor],[CodigoEmpleado],[CodigoPersona],[CodigoAgencia]) VALUES (16,N''PRUEBA-CREDITO-V01'',31,1);
SET IDENTITY_INSERT dbo.[Vendedor] OFF;
DBCC CHECKIDENT (''dbo.Vendedor'', RESEED, 16) WITH NO_INFOMSGS;
ALTER TABLE dbo.[Agencia] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Credito] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[CreditoFiador] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Departamento] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Depreciacion] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DetalleCuota] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DetallePago] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[DetalleReferencia] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Deudor] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Direccion] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Fiador] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Garantia] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Linea] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Marca] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Municipio] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[ParametroCredito] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Persona] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Referencia] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[ResumenCredito] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Telefono] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoDireccion] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoGarantia] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoPago] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoReferencia] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[TipoTelefono] WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE dbo.[Vendedor] WITH CHECK CHECK CONSTRAINT ALL;
ALTER SEQUENCE [dbo].[SecComprobante] RESTART WITH 4;
IF (SELECT COUNT_BIG(*) FROM dbo.[Agencia]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Credito]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[CreditoFiador]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Departamento]) <> 2 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Depreciacion]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetalleCuota]) <> 12 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetallePago]) <> 3 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetalleReferencia]) <> 3 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Deudor]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Direccion]) <> 5 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Fiador]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Garantia]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Linea]) <> 5 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Marca]) <> 5 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Municipio]) <> 2 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[ParametroCredito]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Persona]) <> 8 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Referencia]) <> 3 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[ResumenCredito]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Telefono]) <> 7 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoDireccion]) <> 3 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoGarantia]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoPago]) <> 5 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoReferencia]) <> 4 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoTelefono]) <> 3 THROW 52501,''Conteo de copia no coincide.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Vendedor]) <> 1 THROW 52501,''Conteo de copia no coincide.'',1;
EXEC sys.sp_addextendedproperty @name=N''MAGISAUTO_CopiaEquipo'',@value=N''2026-10-13'';
SELECT N''Copia de equipo instalada'' Resultado, DB_NAME() Base, COUNT(*) Recibos FROM dbo.DetallePago;
COMMIT TRANSACTION; END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;';
EXEC sys.sp_executesql @Carga;
