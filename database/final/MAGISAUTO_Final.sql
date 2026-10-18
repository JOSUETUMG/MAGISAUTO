/* MAGIS-AUTO - SQL FINAL DE ENTREGA - 16/10/2026
Codigo de referencia: b8c44aa, rama pruebas-diego.
INSTALACION NUEVA COMPLETA: 26 tablas, 154 procedimientos API, 4 vistas,
2 funciones, 20 reportes y 350 filas ficticias coherentes de demostracion.
Incluye las funcionalidades de las migraciones 001 y 002. NO ejecutarlas despues.
Corte de demostracion: 16/10/2026. Seis casos: al dia, parcial, mora, anticipo, anulacion y borrador.

INSTRUCCIONES: abrir TODO el archivo en SSMS y ejecutar con F5, sin seleccionar
fragmentos y sin modo SQLCMD, usando una cuenta con permiso para crear bases.
Cambiar SOLO @Base si se necesita otro nombre NUEVO. No cambiar el nombre de
bases anteriores ni borrarlas: se usara MAGISAUTO_Entrega_Final para la aplicacion y entrega.
Si el destino existe, el script se detiene sin modificarlo.
CREATE DATABASE esta fuera de la transaccion: si falla la carga puede quedar una
base nueva vacia; no se elimina automaticamente. Un mensaje de error NO es exito.

El SQL dinamico mantiene la carga en una transaccion y permite elegir @Base
una sola vez. Las comillas duplicadas son parte de ese mecanismo.
No contiene cuentas de servidor ni claves. La conexion de la API se configura
por computadora mediante scripts/Preparar-Equipo.ps1 y su SQL privado.
*/
USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;
-- 1. DESTINO NUEVO: se valida antes de crear cualquier objeto.
DECLARE @Base sysname=N'MAGISAUTO_Entrega_Final';
IF @Base IS NULL OR @Base NOT LIKE N'MAGISAUTO[_]%' OR @Base LIKE N'%[^A-Za-z0-9_]%' COLLATE Latin1_General_100_BIN2
 THROW 52500,'Use un nombre nuevo MAGISAUTO_... con letras, numeros y guion bajo.',1;
IF DB_ID(@Base) IS NOT NULL THROW 52500,'La base ya existe. No se modifico. Elija otro nombre.',1;
DECLARE @Crear nvarchar(max)=N'CREATE DATABASE '+QUOTENAME(@Base)+N';';
EXEC sys.sp_executesql @Crear;
DECLARE @Carga nvarchar(max)=N'USE '+QUOTENAME(@Base)+N'; SET XACT_ABORT ON; BEGIN TRY BEGIN TRANSACTION;
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;
EXEC(N''CREATE SCHEMA api AUTHORIZATION dbo;'');

-- 2. TABLAS Y RELACIONES: PK, FK, indices y restricciones de negocio.
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


-- 3. VISTAS, FUNCIONES Y PROCEDIMIENTOS DEFINITIVOS
-- dbo.vw_CreditoResumen
EXEC(N''CREATE VIEW dbo.vw_CreditoResumen AS
 SELECT c.*,CONVERT(decimal(18,2),c.PrecioContado-c.Enganche) AS MontoFinanciado,
 r.TotalIntereses,r.TotalNetoRecaudable
 FROM dbo.Credito c LEFT JOIN dbo.ResumenCredito r ON r.NumeroCredito=c.NumeroCredito;'');

-- dbo.vw_CuotaDesglosada
-- CUOTA TOTAL: capital, interes, manejo y seguros; el enganche queda fuera.
EXEC(N''CREATE VIEW dbo.vw_CuotaDesglosada AS
 SELECT q.*,c.ManejoMensual AS ManejoCuenta,s.SeguroAuto,s.SeguroVida,
 CONVERT(decimal(18,2),q.Capital+q.Interes+c.ManejoMensual+s.SeguroAuto+s.SeguroVida) AS Total
 FROM dbo.DetalleCuota q JOIN dbo.Credito c ON c.NumeroCredito=q.NumeroCredito
 CROSS APPLY(SELECT CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroAuto,2)) SeguroAuto,
 CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroVida,2)) SeguroVida)s;'');

-- dbo.vw_PagoDesglosado
EXEC(N''CREATE VIEW dbo.vw_PagoDesglosado AS
 SELECT p.*,c.PorcentajeComision,
 CONVERT(decimal(18,2),ROUND(p.Monto*c.PorcentajeComision,2)) AS Comision
 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito;'');

-- dbo.vw_DepreciacionCalculada
-- GARANTIA: la depreciacion no modifica la deuda ni el contrato.
EXEC(N''CREATE VIEW dbo.vw_DepreciacionCalculada AS
 SELECT d.*,CONVERT(decimal(18,2),ROUND(d.ValorOriginal*(1-d.Porcentaje),2)) AS ValorDepreciado
 FROM dbo.Depreciacion d;'');

-- dbo.fn_AhoraGuatemala
EXEC(N''CREATE FUNCTION dbo.fn_AhoraGuatemala() RETURNS datetime2(0) AS BEGIN RETURN CONVERT(datetime2(0),SYSUTCDATETIME() AT TIME ZONE ''''UTC'''' AT TIME ZONE ''''Central America Standard Time''''); END;'');

-- dbo.fn_Saldos
-- CORTE HISTORICO: considera fecha de pago y fecha de anulacion al reconstruir los saldos.
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

-- api.Departamento_Listar
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

-- api.Departamento_Buscar
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

-- api.Departamento_Insertar
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

-- api.Departamento_Actualizar
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

-- api.Departamento_Eliminar
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

-- api.Municipio_Listar
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

-- api.Municipio_Buscar
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

-- api.Municipio_Insertar
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

-- api.Municipio_Actualizar
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

-- api.Municipio_Eliminar
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

-- api.TipoTelefono_Listar
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

-- api.TipoTelefono_Buscar
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

-- api.TipoTelefono_Insertar
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

-- api.TipoTelefono_Actualizar
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

-- api.TipoTelefono_Eliminar
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

-- api.TipoDireccion_Listar
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

-- api.TipoDireccion_Buscar
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

-- api.TipoDireccion_Insertar
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

-- api.TipoDireccion_Actualizar
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

-- api.TipoDireccion_Eliminar
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

-- api.TipoGarantia_Listar
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

-- api.TipoGarantia_Buscar
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

-- api.TipoGarantia_Insertar
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

-- api.TipoGarantia_Actualizar
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

-- api.TipoGarantia_Eliminar
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

-- api.TipoReferencia_Listar
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

-- api.TipoReferencia_Buscar
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

-- api.TipoReferencia_Insertar
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

-- api.TipoReferencia_Actualizar
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

-- api.TipoReferencia_Eliminar
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

-- api.TipoPago_Listar
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

-- api.TipoPago_Buscar
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

-- api.TipoPago_Insertar
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

-- api.TipoPago_Actualizar
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

-- api.TipoPago_Eliminar
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

-- api.Marca_Listar
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

-- api.Marca_Buscar
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

-- api.Marca_Insertar
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

-- api.Marca_Actualizar
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

-- api.Marca_Eliminar
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

-- api.Linea_Listar
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

-- api.Linea_Buscar
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

-- api.Linea_Insertar
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

-- api.Linea_Actualizar
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

-- api.Linea_Eliminar
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

-- api.Agencia_Listar
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

-- api.Agencia_Buscar
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

-- api.Agencia_Insertar
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

-- api.Agencia_Actualizar
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

-- api.Agencia_Eliminar
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

-- api.Persona_Listar
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

-- api.Persona_Buscar
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

-- api.Persona_Insertar
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

-- api.Persona_Actualizar
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

-- api.Persona_Eliminar
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

-- api.Telefono_Listar
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

-- api.Telefono_Buscar
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

-- api.Telefono_Insertar
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

-- api.Telefono_Actualizar
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

-- api.Telefono_Eliminar
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

-- api.Direccion_Listar
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

-- api.Direccion_Buscar
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

-- api.Direccion_Insertar
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

-- api.Direccion_Actualizar
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

-- api.Direccion_Eliminar
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

-- api.Deudor_Listar
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

-- api.Deudor_Buscar
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

-- api.Deudor_Insertar
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

-- api.Deudor_Actualizar
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

-- api.Deudor_Eliminar
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

-- api.Referencia_Listar
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

-- api.Referencia_Buscar
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

-- api.Referencia_Insertar
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

-- api.Referencia_Actualizar
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

-- api.Referencia_Eliminar
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

-- api.DetalleReferencia_Listar
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

-- api.DetalleReferencia_Buscar
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

-- api.DetalleReferencia_Insertar
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

-- api.DetalleReferencia_Actualizar
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

-- api.DetalleReferencia_Eliminar
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

-- api.Fiador_Listar
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

-- api.Fiador_Buscar
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

-- api.Fiador_Insertar
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

-- api.Fiador_Actualizar
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

-- api.Fiador_Eliminar
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

-- api.Vendedor_Listar
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

-- api.Vendedor_Buscar
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

-- api.Vendedor_Insertar
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

-- api.Vendedor_Actualizar
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

-- api.Vendedor_Eliminar
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

-- api.Garantia_Listar
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

-- api.Garantia_Buscar
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

-- api.Garantia_Insertar
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

-- api.Garantia_Actualizar
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

-- api.Garantia_Eliminar
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

-- api.ParametroCredito_Listar
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

-- api.ParametroCredito_Buscar
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

-- api.ParametroCredito_Insertar
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

-- api.ParametroCredito_Actualizar
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

-- api.ParametroCredito_Eliminar
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

-- api.Credito_Listar
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

-- api.Credito_Buscar
EXEC(N''CREATE PROCEDURE api.[Credito_Buscar] @Criterio nvarchar(200)
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

-- api.CreditoFiador_Listar
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

-- api.CreditoFiador_Buscar
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

-- api.CreditoFiador_Insertar
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

-- api.CreditoFiador_Actualizar
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

-- api.CreditoFiador_Eliminar
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

-- api.Depreciacion_Listar
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

-- api.Depreciacion_Buscar
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

-- api.Depreciacion_Insertar
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

-- api.Depreciacion_Actualizar
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

-- api.Depreciacion_Eliminar
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

-- api.DetalleCuota_Listar
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

-- api.DetalleCuota_Buscar
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

-- api.DetalleCuota_Insertar
-- CUOTA DE SIMULACION: solo BORRADOR; mantiene coherente el resumen existente.
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

END;'');

-- api.DetalleCuota_Actualizar
-- CUOTA DE SIMULACION: solo BORRADOR; mantiene coherente el resumen existente.
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

END;'');

-- api.DetalleCuota_Eliminar
-- CUOTA DE SIMULACION: solo BORRADOR; mantiene coherente el resumen existente.
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

END;'');

-- api.DetallePago_Listar
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

-- api.DetallePago_Buscar
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

-- api.ResumenCredito_Listar
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

-- api.ResumenCredito_Buscar
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

-- api.Credito_Insertar
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

-- api.Credito_Actualizar
-- BORRADOR: sincroniza el resumen si cambian las condiciones financieras.
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

END;'');

-- api.Credito_Eliminar
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

-- api.Credito_Aprobar
-- APROBACION: valida requisitos; sustituye simulaciones por cuotas y resumen definitivos.
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

 DELETE dbo.ResumenCredito WHERE NumeroCredito=@NumeroCredito;
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

-- api.Credito_Anular
-- HISTORIAL: exige resolver pagos efectivos antes de anular el contrato.
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

-- api.DetallePago_Insertar
-- PAGO: valida saldo y medio, desglosa componentes y asigna un recibo unico.
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

-- api.DetallePago_Actualizar
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

-- api.DetallePago_Anular
-- ANULACION: conserva el pago y registra fecha, motivo y responsable.
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

-- api.DetallePago_Eliminar
-- PROTECCION: la correccion financiera se realiza por anulacion, no borrado fisico.
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

-- api.Credito_Presentar
-- EXPEDIENTE: exige datos y tres referencias completas antes de presentar.
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

-- api.Reporte01_CreditosEmitidos
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

-- api.Reporte02_CarteraMora
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

-- api.Reporte03_PagosPorMedio
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

-- api.Reporte04_VentasVendedor
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

-- api.Reporte05_Cumpleaneros
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

-- api.Reporte06_EstadoCuenta
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

-- api.Reporte07_PlanPagos
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

-- api.Reporte08_Comisiones
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

-- api.Reporte09_CapitalPendiente
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

-- api.Reporte10_Intereses
-- DEVENGO ACADEMICO: interes completo al vencimiento; anticipos separados, sin prorrateo diario.
EXEC(N''CREATE PROCEDURE api.Reporte10_Intereses @FechaCorte date=NULL
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SET @FechaCorte=COALESCE(@FechaCorte,CONVERT(date,dbo.fn_AhoraGuatemala()));
 IF @FechaCorte=''''99991231'''' THROW 51301,''''Fecha de corte fuera de rango.'''',1;
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
END;'');

-- api.Reporte11_ProximosVencimientos
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

-- api.Reporte12_AbonosParciales
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

-- api.Reporte13_CreditosMarcaLinea
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

-- api.Reporte14_CarteraAgenciaRegion
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

-- api.Reporte15_MoraRangos
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

-- api.Reporte16_GarantiaContraCapital
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

-- api.Reporte17_DepreciacionCostoFinanciamiento
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

-- api.Reporte18_CreditosFiador
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

-- api.Reporte19_RecaudacionComponentes
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

-- api.Reporte20_PagosAnulados
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

-- api.ResumenCredito_Insertar
-- RESUMEN DE SIMULACION: solo BORRADOR; importes calculados, nunca introducidos a mano.
EXEC(N''CREATE PROCEDURE api.ResumenCredito_Insertar @NumeroCredito varchar(20)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica el resumen de un borrador.'''',1;
  IF EXISTS(SELECT 1 FROM dbo.ResumenCredito WHERE NumeroCredito=@NumeroCredito) THROW 51002,''''El resumen ya existe. Use recalcular.'''',1; INSERT dbo.ResumenCredito(NumeroCredito,TotalIntereses,TotalNetoRecaudable) SELECT @NumeroCredito,COALESCE(SUM(Interes),0),COALESCE(SUM(Total),0) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

-- api.ResumenCredito_Actualizar
-- RESUMEN DE SIMULACION: solo BORRADOR; importes calculados, nunca introducidos a mano.
EXEC(N''CREATE PROCEDURE api.ResumenCredito_Actualizar @NumeroCredito varchar(20)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica el resumen de un borrador.'''',1;
  UPDATE r SET TotalIntereses=x.Intereses,TotalNetoRecaudable=x.Total FROM dbo.ResumenCredito r CROSS APPLY(SELECT COALESCE(SUM(Interes),0) Intereses,COALESCE(SUM(Total),0) Total FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=@NumeroCredito)x WHERE r.NumeroCredito=@NumeroCredito; IF @@ROWCOUNT=0 THROW 51008,''''Resumen no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');

-- api.ResumenCredito_Eliminar
-- RESUMEN DE SIMULACION: solo BORRADOR; importes calculados, nunca introducidos a mano.
EXEC(N''CREATE PROCEDURE api.ResumenCredito_Eliminar @NumeroCredito varchar(20)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado=''''BORRADOR'''') THROW 51003,''''Solo se modifica el resumen de un borrador.'''',1;
  DELETE dbo.ResumenCredito WHERE NumeroCredito=@NumeroCredito; IF @@ROWCOUNT=0 THROW 51008,''''Resumen no encontrado.'''',1;
  COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;'');








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



















































































































































































































































































































-- 4. SEGURIDAD: ejecutar procedimientos; sin acceso directo a las tablas.
-- No se crean logins, usuarios de servidor ni contrasenas. Cada equipo configura su acceso.
CREATE ROLE magis_api AUTHORIZATION dbo; GRANT EXECUTE ON SCHEMA::api TO magis_api; DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::dbo TO magis_api;

IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>26 THROW 51400,''Inventario de tablas incompleto.'',1; IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api''))<>154 THROW 51401,''Inventario de procedimientos incompleto.'',1;































SELECT (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api'')) Procedimientos,(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api'') AND name LIKE N''Reporte%'') Reportes;































































































































































-- Sustituir catálogos iniciales por la fotografía exacta de las 26 tablas.
-- 5. DATOS DE DEMOSTRACION COHERENTES; CORTE 16/10/2026.
-- COMPONENTE DEL INSTALADOR. No ejecutar solo: requiere tablas vacias y transaccion externa.
-- DATOS FICTICIOS COHERENTES, corte de demostracion: 16/10/2026.
-- Nombres, DPI, NIT, VIN, contactos y direcciones son sinteticos.
-- Planes y pagos se calculan con los procedimientos reales, no a mano.
IF CONVERT(date,dbo.fn_AhoraGuatemala())<''20261016'' THROW 52700,''Estos casos requieren fecha del servidor igual o posterior al 16/10/2026.'',1;
INSERT dbo.[Departamento] ([CodigoDepartamento],[Descripcion]) VALUES (21,N''Jalapa'');
INSERT dbo.[Departamento] ([CodigoDepartamento],[Descripcion]) VALUES (22,N''Jutiapa'');
INSERT dbo.[Municipio] ([CodigoDepartamento],[CodigoMunicipio],[Descripcion]) VALUES (21,1,N''Jalapa'');
INSERT dbo.[Municipio] ([CodigoDepartamento],[CodigoMunicipio],[Descripcion]) VALUES (22,1,N''Jutiapa'');
INSERT dbo.[TipoTelefono] ([CodigoTipoTelefono],[Descripcion]) VALUES (1,N''Celular'');
INSERT dbo.[TipoTelefono] ([CodigoTipoTelefono],[Descripcion]) VALUES (2,N''Casa'');
INSERT dbo.[TipoTelefono] ([CodigoTipoTelefono],[Descripcion]) VALUES (3,N''Trabajo'');
INSERT dbo.[TipoDireccion] ([CodigoTipoDireccion],[Descripcion]) VALUES (1,N''Particular'');
INSERT dbo.[TipoDireccion] ([CodigoTipoDireccion],[Descripcion]) VALUES (2,N''Trabajo'');
INSERT dbo.[TipoDireccion] ([CodigoTipoDireccion],[Descripcion]) VALUES (3,N''Otra'');
INSERT dbo.[TipoGarantia] ([CodigoTipoGarantia],[Descripcion]) VALUES (1,N''Vehiculo nuevo de agencia'');
INSERT dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (1,N''Familiar'');
INSERT dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (2,N''Amistad'');
INSERT dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (3,N''Laboral'');
INSERT dbo.[TipoReferencia] ([CodigoTipoReferencia],[Descripcion]) VALUES (4,N''Otra'');
INSERT dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (1,N''Deposito bancario'',1);
INSERT dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (2,N''Transferencia ACH'',1);
INSERT dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (3,N''Tarjeta de credito'',1);
INSERT dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (4,N''Tarjeta de debito'',1);
INSERT dbo.[TipoPago] ([CodigoTipoPago],[Descripcion],[RequiereReferencia]) VALUES (5,N''Efectivo en ventanilla'',0);
INSERT dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (1,N''Toyota'');
INSERT dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (2,N''Hyundai'');
INSERT dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (3,N''Kia'');
INSERT dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (4,N''Nissan'');
INSERT dbo.[Marca] ([CodigoMarca],[Descripcion]) VALUES (5,N''Suzuki'');
INSERT dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (1,1,N''Corolla'');
INSERT dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (2,1,N''Accent'');
INSERT dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (3,1,N''Soluto'');
INSERT dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (4,1,N''Versa'');
INSERT dbo.[Linea] ([CodigoMarca],[CodigoLinea],[Descripcion]) VALUES (5,1,N''Swift'');
SET IDENTITY_INSERT dbo.[Agencia] ON;
INSERT dbo.[Agencia] ([CodigoAgencia],[Nombre],[Region]) VALUES (1,N''MAGIS-AUTO Jalapa'',N''Oriente'');
INSERT dbo.[Agencia] ([CodigoAgencia],[Nombre],[Region]) VALUES (2,N''MAGIS-AUTO Jutiapa'',N''Oriente'');
SET IDENTITY_INSERT dbo.[Agencia] OFF;
SET IDENTITY_INSERT dbo.[ParametroCredito] ON;
INSERT dbo.[ParametroCredito] ([CodigoParametro],[Nombre],[Activo],[TasaAnual],[ManejoMensual],[TasaSeguroAuto],[TasaSeguroVida],[EngancheMinimo],[ComisionPredeterminada],[DepreciacionInicial]) VALUES (1,N''Plan automotriz 2026'',1,0.125,25,0.0015,0.0005,0.2,0.02,0.15);
SET IDENTITY_INSERT dbo.[ParametroCredito] OFF;
SET IDENTITY_INSERT dbo.[Persona] ON;
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (1,N''9900000000001'',N''9000001-1'',N''Ana'',N''Lucía'',N''Morales'',N''López'',N''1986-10-02'',N''F'',N''persona01@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (2,N''9900000000002'',N''9000002-2'',N''Carlos'',N''Eduardo'',N''Méndez'',N''Ruiz'',N''1987-03-03'',N''M'',N''persona02@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (3,N''9900000000003'',N''9000003-3'',N''María'',N''Fernanda'',N''Castillo'',N''Paz'',N''1988-04-04'',N''F'',N''persona03@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (4,N''9900000000004'',N''9000004-4'',N''José'',N''Antonio'',N''Herrera'',N''Díaz'',N''1989-05-05'',N''M'',N''persona04@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (5,N''9900000000005'',N''9000005-5'',N''Sofía'',N''Isabel'',N''Ramírez'',N''Luna'',N''1990-10-06'',N''F'',N''persona05@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (6,N''9900000000006'',N''9000006-6'',N''Luis'',N''Fernando'',N''Aguilar'',N''Reyes'',N''1991-07-07'',N''M'',N''persona06@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (7,N''9900000000007'',N''9000007-7'',N''Mario'',N''Alberto'',N''Rivas'',N''Cruz'',N''1992-08-08'',N''M'',N''persona07@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (8,N''9900000000008'',N''9000008-8'',N''Paola'',N''Andrea'',N''Mejía'',N''Soto'',N''1993-09-09'',N''F'',N''persona08@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (9,N''9900000000009'',N''9000009-9'',N''Elena'',N''Patricia'',N''Vargas'',N''León'',N''1994-01-10'',N''F'',N''persona09@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (10,N''9900000000010'',N''9000010-0'',N''Ricardo'',N''Estuardo'',N''Pineda'',N''Roca'',N''1995-02-11'',N''M'',N''persona10@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (11,N''9900000000011'',N''9000011-1'',N''Gabriela'',N''Alejandra'',N''Duarte'',N''Vega'',N''1996-03-12'',N''F'',N''persona11@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (12,N''9900000000012'',N''9000012-2'',N''Andrea'',N''Paola'',N''Fuentes'',N''Gil'',N''1985-04-13'',N''F'',N''persona12@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (13,N''9900000000013'',N''9000013-3'',N''Daniel'',N''Esteban'',N''Cabrera'',N''Mora'',N''1986-05-14'',N''M'',N''persona13@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (14,N''9900000000014'',N''9000014-4'',N''Patricia'',N''Elena'',N''López'',N''Solís'',N''1987-06-15'',N''F'',N''persona14@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (15,N''9900000000015'',N''9000015-5'',N''Roberto'',N''Enrique'',N''Santos'',N''Pérez'',N''1988-07-16'',N''M'',N''persona15@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (16,N''9900000000016'',N''9000016-6'',N''Mónica'',N''Beatriz'',N''Rivera'',N''Ruiz'',N''1989-08-17'',N''F'',N''persona16@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (17,N''9900000000017'',N''9000017-7'',N''Jorge'',N''Manuel'',N''Reyes'',N''Lima'',N''1990-09-18'',N''M'',N''persona17@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (18,N''9900000000018'',N''9000018-8'',N''Claudia'',N''Maribel'',N''Gómez'',N''Lara'',N''1991-01-19'',N''F'',N''persona18@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (19,N''9900000000019'',N''9000019-9'',N''Sergio'',N''Andrés'',N''Luna'',N''Ríos'',N''1992-02-20'',N''M'',N''persona19@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (20,N''9900000000020'',N''9000020-0'',N''Verónica'',N''Isabel'',N''Paz'',N''Navas'',N''1993-03-21'',N''F'',N''persona20@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (21,N''9900000000021'',N''9000021-1'',N''Héctor'',N''Daniel'',N''Flores'',N''Cano'',N''1994-04-22'',N''M'',N''persona21@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (22,N''9900000000022'',N''9000022-2'',N''Rosa'',N''María'',N''Cruz'',N''Mena'',N''1995-05-23'',N''F'',N''persona22@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (23,N''9900000000023'',N''9000023-3'',N''Óscar'',N''Eduardo'',N''Vega'',N''Sosa'',N''1996-06-24'',N''M'',N''persona23@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (24,N''9900000000024'',N''9000024-4'',N''Diana'',N''Carolina'',N''Ruiz'',N''Ochoa'',N''1985-07-25'',N''F'',N''persona24@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (25,N''9900000000025'',N''9000025-5'',N''Fernando'',N''Javier'',N''León'',N''Vidal'',N''1986-08-01'',N''M'',N''persona25@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (26,N''9900000000026'',N''9000026-6'',N''Lucía'',N''Gabriela'',N''Soto'',N''Campos'',N''1987-09-02'',N''F'',N''persona26@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (27,N''9900000000027'',N''9000027-7'',N''Miguel'',N''Ángel'',N''Roca'',N''Molina'',N''1988-01-03'',N''M'',N''persona27@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (28,N''9900000000028'',N''9000028-8'',N''Adriana'',N''Marisol'',N''Peña'',N''López'',N''1989-02-04'',N''F'',N''persona28@example.invalid'');
INSERT dbo.[Persona] ([CodigoPersona],[DPI],[NIT],[PrimerNombre],[SegundoNombre],[PrimerApellido],[SegundoApellido],[FechaNacimiento],[Genero],[CorreoElectronico]) VALUES (29,N''9900000000029'',N''9000029-9'',N''Pablo'',N''Andrés'',N''Navas'',N''Herrera'',N''1990-03-05'',N''M'',N''persona29@example.invalid'');
SET IDENTITY_INSERT dbo.[Persona] OFF;
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (1,1,1,N''55501001'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (2,1,1,N''55501002'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (3,1,1,N''55501003'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (4,1,1,N''55501004'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (5,1,1,N''55501005'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (6,1,1,N''55501006'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (7,1,1,N''55501007'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (8,1,1,N''55501008'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (9,1,1,N''55501009'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (10,1,1,N''55501010'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (11,1,1,N''55501011'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (12,1,1,N''55501012'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (13,1,1,N''55501013'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (14,1,1,N''55501014'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (15,1,1,N''55501015'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (16,1,1,N''55501016'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (17,1,1,N''55501017'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (18,1,1,N''55501018'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (19,1,1,N''55501019'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (20,1,1,N''55501020'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (21,1,1,N''55501021'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (22,1,1,N''55501022'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (23,1,1,N''55501023'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (24,1,1,N''55501024'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (25,1,1,N''55501025'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (26,1,1,N''55501026'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (27,1,1,N''55501027'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (28,1,1,N''55501028'');
INSERT dbo.[Telefono] ([CodigoPersona],[Correlativo],[CodigoTipoTelefono],[Numero]) VALUES (29,1,1,N''55501029'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (1,1,1,21,1,N''1 avenida, casa 11, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (2,1,1,22,1,N''2 avenida, casa 12, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (3,1,1,21,1,N''3 avenida, casa 13, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (4,1,1,22,1,N''4 avenida, casa 14, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (5,1,1,21,1,N''5 avenida, casa 15, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (6,1,1,22,1,N''6 avenida, casa 16, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (7,1,1,21,1,N''7 avenida, casa 17, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (8,1,1,22,1,N''8 avenida, casa 18, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (9,1,1,21,1,N''9 avenida, casa 19, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (10,1,1,22,1,N''10 avenida, casa 20, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (11,1,1,21,1,N''11 avenida, casa 21, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (12,1,1,22,1,N''12 avenida, casa 22, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (13,1,1,21,1,N''13 avenida, casa 23, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (14,1,1,22,1,N''14 avenida, casa 24, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (15,1,1,21,1,N''15 avenida, casa 25, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (16,1,1,22,1,N''16 avenida, casa 26, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (17,1,1,21,1,N''17 avenida, casa 27, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (18,1,1,22,1,N''18 avenida, casa 28, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (19,1,1,21,1,N''19 avenida, casa 29, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (20,1,1,22,1,N''20 avenida, casa 30, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (21,1,1,21,1,N''21 avenida, casa 31, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (22,1,1,22,1,N''22 avenida, casa 32, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (23,1,1,21,1,N''23 avenida, casa 33, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (24,1,1,22,1,N''24 avenida, casa 34, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (25,1,1,21,1,N''25 avenida, casa 35, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (26,1,1,22,1,N''26 avenida, casa 36, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (27,1,1,21,1,N''27 avenida, casa 37, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (28,1,1,22,1,N''28 avenida, casa 38, zona 1'');
INSERT dbo.[Direccion] ([CodigoPersona],[Correlativo],[CodigoTipoDireccion],[CodigoDepartamento],[CodigoMunicipio],[Detalle]) VALUES (29,1,1,21,1,N''29 avenida, casa 39, zona 1'');
SET IDENTITY_INSERT dbo.[Deudor] ON;
INSERT dbo.[Deudor] ([CodigoDeudor],[CodigoPersona]) VALUES (1,1);
INSERT dbo.[Deudor] ([CodigoDeudor],[CodigoPersona]) VALUES (2,2);
INSERT dbo.[Deudor] ([CodigoDeudor],[CodigoPersona]) VALUES (3,3);
INSERT dbo.[Deudor] ([CodigoDeudor],[CodigoPersona]) VALUES (4,4);
INSERT dbo.[Deudor] ([CodigoDeudor],[CodigoPersona]) VALUES (5,5);
INSERT dbo.[Deudor] ([CodigoDeudor],[CodigoPersona]) VALUES (6,6);
SET IDENTITY_INSERT dbo.[Deudor] OFF;
SET IDENTITY_INSERT dbo.[Vendedor] ON;
INSERT dbo.[Vendedor] ([CodigoVendedor],[CodigoEmpleado],[CodigoPersona],[CodigoAgencia]) VALUES (1,N''VEN-001'',7,1);
INSERT dbo.[Vendedor] ([CodigoVendedor],[CodigoEmpleado],[CodigoPersona],[CodigoAgencia]) VALUES (2,N''VEN-002'',8,2);
SET IDENTITY_INSERT dbo.[Vendedor] OFF;
SET IDENTITY_INSERT dbo.[Fiador] ON;
INSERT dbo.[Fiador] ([CodigoFiador],[CodigoPersona]) VALUES (1,9);
INSERT dbo.[Fiador] ([CodigoFiador],[CodigoPersona]) VALUES (2,10);
INSERT dbo.[Fiador] ([CodigoFiador],[CodigoPersona]) VALUES (3,11);
SET IDENTITY_INSERT dbo.[Fiador] OFF;
SET IDENTITY_INSERT dbo.[Referencia] ON;
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (1,12,N''Centro educativo Los Pinos'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (2,13,N''Comercial El Roble'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (3,14,N''Clínica Las Flores'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (4,15,N''Centro educativo Los Pinos'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (5,16,N''Comercial El Roble'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (6,17,N''Clínica Las Flores'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (7,18,N''Centro educativo Los Pinos'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (8,19,N''Comercial El Roble'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (9,20,N''Clínica Las Flores'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (10,21,N''Centro educativo Los Pinos'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (11,22,N''Comercial El Roble'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (12,23,N''Clínica Las Flores'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (13,24,N''Centro educativo Los Pinos'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (14,25,N''Comercial El Roble'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (15,26,N''Clínica Las Flores'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (16,27,N''Centro educativo Los Pinos'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (17,28,N''Comercial El Roble'');
INSERT dbo.[Referencia] ([CodigoReferencia],[CodigoPersona],[LugarTrabajo]) VALUES (18,29,N''Clínica Las Flores'');
SET IDENTITY_INSERT dbo.[Referencia] OFF;
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (1,1,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (1,2,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (1,3,3,N''Compañero de trabajo'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (2,4,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (2,5,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (2,6,3,N''Compañero de trabajo'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (3,7,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (3,8,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (3,9,3,N''Compañero de trabajo'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (4,10,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (4,11,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (4,12,3,N''Compañero de trabajo'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (5,13,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (5,14,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (5,15,3,N''Compañero de trabajo'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (6,16,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (6,17,2,N''Amistad'');
INSERT dbo.[DetalleReferencia] ([CodigoDeudor],[CodigoReferencia],[CodigoTipoReferencia],[ParentescoRelacion]) VALUES (6,18,3,N''Compañero de trabajo'');
SET IDENTITY_INSERT dbo.[Garantia] ON;
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (1,N''MGA20260000000001'',1,1,2026,150000,NULL,1,1);
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (2,N''MGA20260000000002'',2,1,2026,125000,NULL,1,1);
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (3,N''MGA20260000000003'',3,1,2026,110000,NULL,1,1);
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (4,N''MGA20260000000004'',4,1,2026,135000,NULL,1,1);
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (5,N''MGA20260000000005'',5,1,2026,105000,NULL,1,1);
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (6,N''MGA20260000000006'',1,1,2026,160000,NULL,1,1);
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (7,N''MGA20260000000007'',4,1,2026,145000,NULL,1,1);
INSERT dbo.[Garantia] ([CodigoGarantia],[VIN],[CodigoMarca],[CodigoLinea],[Anio],[ValorAgencia],[Placa],[CodigoTipoGarantia],[EsNuevo]) VALUES (8,N''MGA20260000000008'',2,1,2026,118000,NULL,1,1);
SET IDENTITY_INSERT dbo.[Garantia] OFF;
-- En una base nueva las identidades empiezan en 1. En el reemplazo, se reinician solo tras vaciar los datos autorizados.
IF EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(''dbo.Depreciacion'') AND last_value IS NOT NULL) DBCC CHECKIDENT (''dbo.Depreciacion'', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID(''dbo.DetallePago'') AND last_value IS NOT NULL) DBCC CHECKIDENT (''dbo.DetallePago'', RESEED, 0) WITH NO_INFOMSGS;
ALTER SEQUENCE dbo.SecComprobante RESTART WITH 1;
-- MGA-2026-001: Al día.
EXEC api.Credito_Insertar @NumeroCredito=''MGA-2026-001'',@CodigoDeudor=1,@CodigoGarantia=1,@CodigoVendedor=1,@Enganche=30000.00,@Plazo=24,@FiadoresRequeridos=1;
EXEC api.CreditoFiador_Insertar @NumeroCredito=''MGA-2026-001'',@CodigoFiador=1;
EXEC api.Credito_Presentar @NumeroCredito=''MGA-2026-001'',@Responsable=N''Coordinación comercial'';
UPDATE dbo.Credito SET FechaPresentacion=DATEADD(hour,8,CONVERT(datetime2,''20260710'')) WHERE NumeroCredito=''MGA-2026-001'' AND Estado=''BORRADOR'';
EXEC api.Credito_Aprobar @NumeroCredito=''MGA-2026-001'',@Responsable=N''Comité de crédito'',@FechaAprobacion=''20260710 09:00:00'',@PorcentajeDepreciacion=0.15;
-- MGA-2026-002: Abono parcial.
EXEC api.Credito_Insertar @NumeroCredito=''MGA-2026-002'',@CodigoDeudor=2,@CodigoGarantia=2,@CodigoVendedor=2,@Enganche=25000.00,@Plazo=36,@FiadoresRequeridos=1;
EXEC api.CreditoFiador_Insertar @NumeroCredito=''MGA-2026-002'',@CodigoFiador=2;
EXEC api.Credito_Presentar @NumeroCredito=''MGA-2026-002'',@Responsable=N''Coordinación comercial'';
UPDATE dbo.Credito SET FechaPresentacion=DATEADD(hour,8,CONVERT(datetime2,''20260805'')) WHERE NumeroCredito=''MGA-2026-002'' AND Estado=''BORRADOR'';
EXEC api.Credito_Aprobar @NumeroCredito=''MGA-2026-002'',@Responsable=N''Comité de crédito'',@FechaAprobacion=''20260805 09:00:00'',@PorcentajeDepreciacion=0.15;
-- MGA-2026-003: En mora.
EXEC api.Credito_Insertar @NumeroCredito=''MGA-2026-003'',@CodigoDeudor=3,@CodigoGarantia=3,@CodigoVendedor=1,@Enganche=22000.00,@Plazo=48,@FiadoresRequeridos=1;
EXEC api.CreditoFiador_Insertar @NumeroCredito=''MGA-2026-003'',@CodigoFiador=3;
EXEC api.Credito_Presentar @NumeroCredito=''MGA-2026-003'',@Responsable=N''Coordinación comercial'';
UPDATE dbo.Credito SET FechaPresentacion=DATEADD(hour,8,CONVERT(datetime2,''20260615'')) WHERE NumeroCredito=''MGA-2026-003'' AND Estado=''BORRADOR'';
EXEC api.Credito_Aprobar @NumeroCredito=''MGA-2026-003'',@Responsable=N''Comité de crédito'',@FechaAprobacion=''20260615 09:00:00'',@PorcentajeDepreciacion=0.15;
-- MGA-2026-004: Anticipo.
EXEC api.Credito_Insertar @NumeroCredito=''MGA-2026-004'',@CodigoDeudor=4,@CodigoGarantia=4,@CodigoVendedor=2,@Enganche=27000.00,@Plazo=12,@FiadoresRequeridos=0;
EXEC api.Credito_Presentar @NumeroCredito=''MGA-2026-004'',@Responsable=N''Coordinación comercial'';
UPDATE dbo.Credito SET FechaPresentacion=DATEADD(hour,8,CONVERT(datetime2,''20261001'')) WHERE NumeroCredito=''MGA-2026-004'' AND Estado=''BORRADOR'';
EXEC api.Credito_Aprobar @NumeroCredito=''MGA-2026-004'',@Responsable=N''Comité de crédito'',@FechaAprobacion=''20261001 09:00:00'',@PorcentajeDepreciacion=0.15;
-- MGA-2026-005: Pago anulado.
EXEC api.Credito_Insertar @NumeroCredito=''MGA-2026-005'',@CodigoDeudor=5,@CodigoGarantia=5,@CodigoVendedor=1,@Enganche=21000.00,@Plazo=24,@FiadoresRequeridos=1;
EXEC api.CreditoFiador_Insertar @NumeroCredito=''MGA-2026-005'',@CodigoFiador=1;
EXEC api.Credito_Presentar @NumeroCredito=''MGA-2026-005'',@Responsable=N''Coordinación comercial'';
UPDATE dbo.Credito SET FechaPresentacion=DATEADD(hour,8,CONVERT(datetime2,''20260912'')) WHERE NumeroCredito=''MGA-2026-005'' AND Estado=''BORRADOR'';
EXEC api.Credito_Aprobar @NumeroCredito=''MGA-2026-005'',@Responsable=N''Comité de crédito'',@FechaAprobacion=''20260912 09:00:00'',@PorcentajeDepreciacion=0.15;
-- MGA-2026-006: Borrador.
EXEC api.Credito_Insertar @NumeroCredito=''MGA-2026-006'',@CodigoDeudor=6,@CodigoGarantia=6,@CodigoVendedor=2,@Enganche=32000.00,@Plazo=60,@FiadoresRequeridos=1;
EXEC api.CreditoFiador_Insertar @NumeroCredito=''MGA-2026-006'',@CodigoFiador=2;
DECLARE @Importe decimal(18,2),@PagoAnulado bigint;
SELECT @Importe=ROUND(Total*1,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-001'' AND Cuota=1;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-001'',@Cuota=1,@Monto=@Importe,@CodigoTipoPago=1,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0001'',@FechaPago=''20260810 10:00:00'',@Observacion=N''Abono registrado en caja'';
SELECT @Importe=ROUND(Total*1,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-001'' AND Cuota=2;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-001'',@Cuota=2,@Monto=@Importe,@CodigoTipoPago=2,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0002'',@FechaPago=''20260910 10:00:00'',@Observacion=N''Abono registrado en caja'';
SELECT @Importe=ROUND(Total*1,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-001'' AND Cuota=3;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-001'',@Cuota=3,@Monto=@Importe,@CodigoTipoPago=3,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0003'',@FechaPago=''20261010 10:00:00'',@Observacion=N''Abono registrado en caja'';
SELECT @Importe=ROUND(Total*1,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-002'' AND Cuota=1;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-002'',@Cuota=1,@Monto=@Importe,@CodigoTipoPago=4,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0004'',@FechaPago=''20260905 10:00:00'',@Observacion=N''Abono registrado en caja'';
SELECT @Importe=ROUND(Total*0.5,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-002'' AND Cuota=2;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-002'',@Cuota=2,@Monto=@Importe,@CodigoTipoPago=5,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0005'',@FechaPago=''20261005 10:00:00'',@Observacion=N''Abono registrado en caja'';
SELECT @Importe=ROUND(Total*1,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-003'' AND Cuota=1;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-003'',@Cuota=1,@Monto=@Importe,@CodigoTipoPago=2,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0006'',@FechaPago=''20260715 10:00:00'',@Observacion=N''Abono registrado en caja'';
SELECT @Importe=ROUND(Total*0.5,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-004'' AND Cuota=1;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-004'',@Cuota=1,@Monto=@Importe,@CodigoTipoPago=1,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0007'',@FechaPago=''20261005 10:00:00'',@Observacion=N''Abono registrado en caja'';
SELECT @Importe=ROUND(Total*1,2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=''MGA-2026-005'' AND Cuota=1;
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-005'',@Cuota=1,@Monto=@Importe,@CodigoTipoPago=2,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0008'',@FechaPago=''20261012 10:00:00'',@Observacion=N''Abono registrado en caja'';
EXEC api.DetallePago_Insertar @NumeroCredito=''MGA-2026-005'',@Cuota=2,@Monto=1000,@CodigoTipoPago=2,@Responsable=N''Caja MAGIS-AUTO'',@ReferenciaBancaria=N''OP-2026-0009'',@FechaPago=''20261013 10:00:00'',@Observacion=N''Abono pendiente de conciliación'';
SELECT @PagoAnulado=CodigoPago FROM dbo.DetallePago WHERE NumeroCredito=''MGA-2026-005'' AND Cuota=2;
EXEC api.DetallePago_Anular @CodigoPago=@PagoAnulado,@Motivo=N''Transferencia rechazada por el banco'',@Responsable=N''Supervisión de caja'';
-- Fecha historica de la anulacion ficticia: posterior al pago, anterior al corte de la muestra.
UPDATE dbo.DetallePago SET FechaAnulacion=''20261014 11:00:00'' WHERE CodigoPago=@PagoAnulado;
EXEC api.Depreciacion_Insertar @CodigoGarantia=1,@FechaValoracion=''20261015'',@ValorOriginal=127500,@Porcentaje=0.15,@Observacion=N''Revisión trimestral de valor comercial'';
IF (SELECT COUNT_BIG(*) FROM dbo.[Agencia])<>2 THROW 52701,''Conteo inesperado en Agencia.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Credito])<>6 THROW 52701,''Conteo inesperado en Credito.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[CreditoFiador])<>5 THROW 52701,''Conteo inesperado en CreditoFiador.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Departamento])<>2 THROW 52701,''Conteo inesperado en Departamento.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Depreciacion])<>6 THROW 52701,''Conteo inesperado en Depreciacion.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetalleCuota])<>144 THROW 52701,''Conteo inesperado en DetalleCuota.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetallePago])<>9 THROW 52701,''Conteo inesperado en DetallePago.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[DetalleReferencia])<>18 THROW 52701,''Conteo inesperado en DetalleReferencia.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Deudor])<>6 THROW 52701,''Conteo inesperado en Deudor.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Direccion])<>29 THROW 52701,''Conteo inesperado en Direccion.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Fiador])<>3 THROW 52701,''Conteo inesperado en Fiador.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Garantia])<>8 THROW 52701,''Conteo inesperado en Garantia.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Linea])<>5 THROW 52701,''Conteo inesperado en Linea.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Marca])<>5 THROW 52701,''Conteo inesperado en Marca.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Municipio])<>2 THROW 52701,''Conteo inesperado en Municipio.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[ParametroCredito])<>1 THROW 52701,''Conteo inesperado en ParametroCredito.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Persona])<>29 THROW 52701,''Conteo inesperado en Persona.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Referencia])<>18 THROW 52701,''Conteo inesperado en Referencia.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[ResumenCredito])<>5 THROW 52701,''Conteo inesperado en ResumenCredito.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Telefono])<>29 THROW 52701,''Conteo inesperado en Telefono.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoDireccion])<>3 THROW 52701,''Conteo inesperado en TipoDireccion.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoGarantia])<>1 THROW 52701,''Conteo inesperado en TipoGarantia.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoPago])<>5 THROW 52701,''Conteo inesperado en TipoPago.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoReferencia])<>4 THROW 52701,''Conteo inesperado en TipoReferencia.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[TipoTelefono])<>3 THROW 52701,''Conteo inesperado en TipoTelefono.'',1;
IF (SELECT COUNT_BIG(*) FROM dbo.[Vendedor])<>2 THROW 52701,''Conteo inesperado en Vendedor.'',1;
-- Comprobar la coherencia financiera y los casos, no solo la cantidad de filas.
IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.ResumenCredito r ON r.NumeroCredito=c.NumeroCredito CROSS APPLY(SELECT SUM(Interes) I,SUM(Total) T,SUM(Capital) K FROM dbo.vw_CuotaDesglosada q WHERE q.NumeroCredito=c.NumeroCredito)x WHERE r.TotalIntereses<>x.I OR r.TotalNetoRecaudable<>x.T OR x.K<>c.PrecioContado-c.Enganche) THROW 52702,''Resumen o capital incoherente.'',1;
IF EXISTS(SELECT 1 FROM dbo.Credito WHERE FechaPresentacion>FechaAprobacion) THROW 52702,''Presentacion posterior a aprobacion.'',1;
IF EXISTS(SELECT 1 FROM dbo.DetallePago WHERE FechaAnulacion<FechaPago OR Monto<>Capital+Interes+ManejoCuenta+SeguroAuto+SeguroVida) THROW 52702,''Pago incoherente.'',1;
IF EXISTS(SELECT 1 FROM dbo.fn_Saldos(''20261016'') WHERE NumeroCredito=''MGA-2026-001'' AND FechaVencimiento<=''20261016'' AND SaldoPendiente>0) THROW 52702,''El caso al dia presenta atraso.'',1;
IF NOT EXISTS(SELECT 1 FROM dbo.fn_Saldos(''20261016'') WHERE NumeroCredito=''MGA-2026-002'' AND Cuota=2 AND SaldoPendiente>0 AND SaldoPendiente<Total) THROW 52702,''Falta abono parcial.'',1;
IF NOT EXISTS(SELECT 1 FROM dbo.fn_Saldos(''20261016'') WHERE NumeroCredito=''MGA-2026-003'' AND FechaVencimiento<''20261016'' AND SaldoPendiente>0) THROW 52702,''Falta caso de mora.'',1;
IF NOT EXISTS(SELECT 1 FROM dbo.DetallePago p JOIN dbo.DetalleCuota q ON q.NumeroCredito=p.NumeroCredito AND q.Cuota=p.Cuota WHERE p.NumeroCredito=''MGA-2026-004'' AND p.FechaPago<q.FechaVencimiento) THROW 52702,''Falta anticipo.'',1;
IF (SELECT COUNT(*) FROM dbo.DetallePago WHERE FechaAnulacion IS NOT NULL)<>1 THROW 52702,''Falta la anulacion.'',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Credito WHERE NumeroCredito=''MGA-2026-006'' AND Estado=''BORRADOR'') THROW 52702,''Falta el borrador.'',1;
IF EXISTS(SELECT 1 FROM dbo.Persona WHERE PrimerNombre LIKE ''%Prueba%'' OR PrimerApellido LIKE ''%prueba%'') THROW 52702,''Persisten nombres de prueba anteriores.'',1;

EXEC sys.sp_addextendedproperty @name=N''MAGISAUTO_DatosEntrega'',@value=N''2026-10-16-v1'';

-- 6. VALIDACION FINAL: no confirmar una instalacion incompleta.
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api''))<>154 THROW 52502,''Se esperaban 154 procedimientos API.'',1;
IF (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped=0)<>4 THROW 52502,''Se esperaban 4 vistas.'',1;
IF (SELECT COUNT(*) FROM sys.objects WHERE type IN (''FN'',''IF'',''TF'') AND is_ms_shipped=0)<>2 THROW 52502,''Se esperaban 2 funciones.'',1;
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N''api'') AND name LIKE N''Reporte%'')<>20 THROW 52502,''Se esperaban 20 reportes.'',1;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1) OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE is_disabled=1 OR is_not_trusted=1) THROW 52502,''Restricciones sin validar.'',1;
EXEC sys.sp_addextendedproperty @name=N''MAGISAUTO_EntregaFinal'',@value=N''b8c44aa + 002 integrada; datos coherentes 2026-10-16-v1'';
COMMIT TRANSACTION;
SELECT N''Instalacion final completada'' Resultado, DB_NAME() Base, 26 Tablas, 154 ProcedimientosAPI, 4 Vistas, 2 Funciones, 20 Reportes, 350 FilasDeMuestra;
END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;';
EXEC sys.sp_executesql @Carga;
