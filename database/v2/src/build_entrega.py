from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / 'entrega'
OUT.mkdir(parents=True, exist_ok=True)
OUT.mkdir(exist_ok=True)
parts = []
entities = {}
procedures = []

def emit(sql): parts.append(sql.strip())
def proc(name, params, body, write=False):
    procedures.append(name)
    tx1 = 'BEGIN TRANSACTION;' if write else ''
    tx2 = 'COMMIT TRANSACTION;' if write else ''
    rollback = 'IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;' if write else ''
    sql = f'''CREATE PROCEDURE api.[{name}] {params}
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  {tx1}
  {body}
  {tx2}
 END TRY
 BEGIN CATCH
  {rollback}
  THROW;
 END CATCH;
END;'''
    emit("EXEC(N'" + sql.replace("'", "''") + "');")

def table(name, cols, keys, extra='', identity=None, special=False):
    # cols: (name, SQL type, SQL null/default/check clause)
    entities[name] = dict(cols=cols, keys=keys, identity=identity, special=special)
    definitions = [f'[{c}] {typ} {tail}' for c,typ,tail in cols]
    definitions.append(f'CONSTRAINT [PK_{name}] PRIMARY KEY (' + ','.join(f'[{k}]' for k in keys) + ')')
    if extra: definitions.append(extra)
    emit(f'CREATE TABLE dbo.[{name}](\n '+',\n '.join(definitions)+'\n);')

def cat(name, key, extra_cols=None, extra=''):
    table(name, [(key,'int','NOT NULL'),('Descripcion','nvarchar(128)',"NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0)")]+(extra_cols or []),[key],extra)

emit('''SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;
CREATE SCHEMA_PLACEHOLDER'''.replace('CREATE SCHEMA_PLACEHOLDER', "EXEC(N'CREATE SCHEMA api AUTHORIZATION dbo;');"))
cat('Departamento','CodigoDepartamento')
table('Municipio',[('CodigoDepartamento','int','NOT NULL REFERENCES dbo.Departamento(CodigoDepartamento)'),('CodigoMunicipio','int','NOT NULL'),('Descripcion','nvarchar(128)','NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0)')],['CodigoDepartamento','CodigoMunicipio'])
for name in ['TipoTelefono','TipoDireccion','TipoGarantia','TipoReferencia']:
    cat(name,'Codigo'+name)
cat('TipoPago','CodigoTipoPago',[('RequiereReferencia','bit','NOT NULL')])
cat('Marca','CodigoMarca')
table('Linea',[('CodigoMarca','int','NOT NULL REFERENCES dbo.Marca(CodigoMarca)'),('CodigoLinea','int','NOT NULL'),('Descripcion','nvarchar(128)','NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0)')],['CodigoMarca','CodigoLinea'])
table('Agencia',[('CodigoAgencia','int','IDENTITY(1,1) NOT NULL'),('Nombre','nvarchar(128)','NOT NULL CHECK(LEN(LTRIM(RTRIM(Nombre)))>0)'),('Region','nvarchar(128)','NOT NULL CHECK(LEN(LTRIM(RTRIM(Region)))>0)')],['CodigoAgencia'],identity='CodigoAgencia')
table('Persona',[
 ('CodigoPersona','int','IDENTITY(1,1) NOT NULL'),('DPI','varchar(13)',"NULL CHECK(DPI IS NULL OR (LEN(DPI)=13 AND DPI NOT LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2))"),
 ('NIT','varchar(20)',"NULL CHECK(NIT IS NULL OR LEN(LTRIM(RTRIM(NIT)))>0)"),('PrimerNombre','nvarchar(64)','NOT NULL CHECK(LEN(LTRIM(RTRIM(PrimerNombre)))>0)'),('SegundoNombre','nvarchar(64)','NULL'),
 ('PrimerApellido','nvarchar(64)','NOT NULL CHECK(LEN(LTRIM(RTRIM(PrimerApellido)))>0)'),('SegundoApellido','nvarchar(64)','NULL'),('FechaNacimiento','date','NULL'),
 ('Genero','char(1)',"NULL CHECK(Genero IN ('M','F','O'))"),('CorreoElectronico','nvarchar(254)',"NULL CHECK(CorreoElectronico IS NULL OR CorreoElectronico LIKE '%_@_%._%')")],['CodigoPersona'],identity='CodigoPersona')
emit('CREATE UNIQUE INDEX UX_Persona_DPI ON dbo.Persona(DPI) WHERE DPI IS NOT NULL; CREATE UNIQUE INDEX UX_Persona_NIT ON dbo.Persona(NIT) WHERE NIT IS NOT NULL;')
table('Telefono',[('CodigoPersona','int','NOT NULL REFERENCES dbo.Persona(CodigoPersona)'),('Correlativo','smallint','NOT NULL CHECK(Correlativo>0)'),('CodigoTipoTelefono','int','NOT NULL REFERENCES dbo.TipoTelefono(CodigoTipoTelefono)'),('Numero','varchar(32)','NOT NULL CHECK(LEN(LTRIM(RTRIM(Numero)))>=8)')],['CodigoPersona','Correlativo'])
table('Direccion',[('CodigoPersona','int','NOT NULL REFERENCES dbo.Persona(CodigoPersona)'),('Correlativo','smallint','NOT NULL CHECK(Correlativo>0)'),('CodigoTipoDireccion','int','NOT NULL REFERENCES dbo.TipoDireccion(CodigoTipoDireccion)'),('CodigoDepartamento','int','NOT NULL'),('CodigoMunicipio','int','NOT NULL'),('Detalle','nvarchar(300)','NOT NULL CHECK(LEN(LTRIM(RTRIM(Detalle)))>0)')],['CodigoPersona','Correlativo'], 'CONSTRAINT FK_Direccion_Municipio FOREIGN KEY(CodigoDepartamento,CodigoMunicipio) REFERENCES dbo.Municipio(CodigoDepartamento,CodigoMunicipio)')
table('Deudor',[('CodigoDeudor','int','IDENTITY(1,1) NOT NULL'),('CodigoPersona','int','NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona)')],['CodigoDeudor'],identity='CodigoDeudor')
table('Referencia',[('CodigoReferencia','int','IDENTITY(1,1) NOT NULL'),('CodigoPersona','int','NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona)'),('LugarTrabajo','nvarchar(200)','NOT NULL CHECK(LEN(LTRIM(RTRIM(LugarTrabajo)))>0)')],['CodigoReferencia'],identity='CodigoReferencia')
table('DetalleReferencia',[('CodigoDeudor','int','NOT NULL REFERENCES dbo.Deudor(CodigoDeudor)'),('CodigoReferencia','int','NOT NULL REFERENCES dbo.Referencia(CodigoReferencia)'),('CodigoTipoReferencia','int','NOT NULL REFERENCES dbo.TipoReferencia(CodigoTipoReferencia)'),('ParentescoRelacion','nvarchar(100)','NOT NULL CHECK(LEN(LTRIM(RTRIM(ParentescoRelacion)))>0)')],['CodigoDeudor','CodigoReferencia'])
table('Fiador',[('CodigoFiador','int','IDENTITY(1,1) NOT NULL'),('CodigoPersona','int','NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona)')],['CodigoFiador'],identity='CodigoFiador')
table('Vendedor',[('CodigoVendedor','int','IDENTITY(1,1) NOT NULL'),('CodigoEmpleado','varchar(30)','NOT NULL UNIQUE CHECK(LEN(LTRIM(RTRIM(CodigoEmpleado)))>0)'),('CodigoPersona','int','NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona)'),('CodigoAgencia','int','NOT NULL REFERENCES dbo.Agencia(CodigoAgencia)')],['CodigoVendedor'],identity='CodigoVendedor')
table('Garantia',[('CodigoGarantia','int','IDENTITY(1,1) NOT NULL'),('VIN','varchar(17)',"NOT NULL UNIQUE CHECK(LEN(VIN)=17 AND VIN NOT LIKE '%[^0-9A-HJ-NPR-Z]%' COLLATE Latin1_General_100_BIN2)"),('CodigoMarca','int','NOT NULL'),('CodigoLinea','int','NOT NULL'),('Anio','smallint','NOT NULL CHECK(Anio BETWEEN 1886 AND 2100)'),('ValorAgencia','decimal(18,2)','NOT NULL CHECK(ValorAgencia>0)'),('Placa','varchar(20)','NULL CHECK(Placa IS NULL OR LEN(LTRIM(RTRIM(Placa)))>0)'),('CodigoTipoGarantia','int','NOT NULL REFERENCES dbo.TipoGarantia(CodigoTipoGarantia)'),('EsNuevo','bit','NOT NULL DEFAULT 1 CHECK(EsNuevo=1)')],['CodigoGarantia'],'CONSTRAINT FK_Garantia_Linea FOREIGN KEY(CodigoMarca,CodigoLinea) REFERENCES dbo.Linea(CodigoMarca,CodigoLinea)',identity='CodigoGarantia')
emit('CREATE UNIQUE INDEX UX_Garantia_Placa ON dbo.Garantia(Placa) WHERE Placa IS NOT NULL;')
table('ParametroCredito',[
 ('CodigoParametro','int','IDENTITY(1,1) NOT NULL'),('Nombre','nvarchar(100)','NOT NULL'),('Activo','bit','NOT NULL'),
 ('TasaAnual','decimal(9,6)','NOT NULL CHECK(TasaAnual BETWEEN 0 AND 1)'),('ManejoMensual','decimal(18,2)','NOT NULL CHECK(ManejoMensual=25)'),
 ('TasaSeguroAuto','decimal(9,6)','NOT NULL CHECK(TasaSeguroAuto>0 AND TasaSeguroAuto<=1)'),('TasaSeguroVida','decimal(9,6)','NOT NULL CHECK(TasaSeguroVida>0 AND TasaSeguroVida<=1)'),
 ('EngancheMinimo','decimal(9,6)','NOT NULL CHECK(EngancheMinimo>=0.20 AND EngancheMinimo<1)'),('ComisionPredeterminada','decimal(9,6)','NOT NULL CHECK(ComisionPredeterminada BETWEEN 0 AND 1)'),
 ('DepreciacionInicial','decimal(9,6)','NOT NULL CHECK(DepreciacionInicial BETWEEN 0.15 AND 0.20)')],['CodigoParametro'],identity='CodigoParametro')
emit('CREATE UNIQUE INDEX UX_Parametro_Activo ON dbo.ParametroCredito(Activo) WHERE Activo=1;')
table('Credito',[
 ('NumeroCredito','varchar(20)','NOT NULL CHECK(LEN(LTRIM(RTRIM(NumeroCredito)))>0)'),('CodigoDeudor','int','NOT NULL REFERENCES dbo.Deudor(CodigoDeudor)'),('CodigoGarantia','int','NOT NULL REFERENCES dbo.Garantia(CodigoGarantia)'),
 ('CodigoVendedor','int','NOT NULL REFERENCES dbo.Vendedor(CodigoVendedor)'),('CodigoAgencia','int','NOT NULL REFERENCES dbo.Agencia(CodigoAgencia)'),('CodigoParametro','int','NOT NULL REFERENCES dbo.ParametroCredito(CodigoParametro)'),
 ('Plazo','smallint','NOT NULL DEFAULT 60 CHECK(Plazo IN(12,24,36,48,60))'),('PrecioContado','decimal(18,2)','NOT NULL CHECK(PrecioContado>0)'),('Enganche','decimal(18,2)','NOT NULL'),
 ('EngancheMinimo','decimal(9,6)','NOT NULL CHECK(EngancheMinimo>=0.20 AND EngancheMinimo<1)'),
 ('TasaAnual','decimal(9,6)','NOT NULL CHECK(TasaAnual BETWEEN 0 AND 1)'),('ManejoMensual','decimal(18,2)','NOT NULL CHECK(ManejoMensual=25)'),('TasaSeguroAuto','decimal(9,6)','NOT NULL CHECK(TasaSeguroAuto>0 AND TasaSeguroAuto<=1)'),('TasaSeguroVida','decimal(9,6)','NOT NULL CHECK(TasaSeguroVida>0 AND TasaSeguroVida<=1)'),
 ('PorcentajeComision','decimal(9,6)','NOT NULL CHECK(PorcentajeComision BETWEEN 0 AND 1)'),('FiadoresRequeridos','smallint','NOT NULL CHECK(FiadoresRequeridos>=0)'),
 ('Estado','varchar(10)',"NOT NULL DEFAULT 'BORRADOR' CHECK(Estado IN('BORRADOR','VIGENTE','LIQUIDADO','ANULADO'))"),('FechaAprobacion','datetime2(0)','NULL'),('AprobadoPor','nvarchar(100)','NULL'),
 ('FechaPresentacion','datetime2(0)','NULL'),('PresentadoPor','nvarchar(100)','NULL'),
 ('FechaAnulacion','datetime2(0)','NULL'),('MotivoAnulacion','nvarchar(300)','NULL'),('AnuladoPor','nvarchar(100)','NULL')],['NumeroCredito'],
 '''CONSTRAINT CK_Credito_Enganche CHECK(Enganche>=CEILING(PrecioContado*EngancheMinimo*100)/100 AND Enganche<PrecioContado),
 CONSTRAINT CK_Credito_Estado CHECK((Estado='BORRADOR' AND FechaAprobacion IS NULL) OR (Estado IN('VIGENTE','LIQUIDADO') AND FechaAprobacion IS NOT NULL AND AprobadoPor IS NOT NULL) OR (Estado='ANULADO' AND FechaAnulacion IS NOT NULL AND MotivoAnulacion IS NOT NULL AND AnuladoPor IS NOT NULL))''',special=True)
emit("CREATE UNIQUE INDEX UX_Credito_VehiculoActivo ON dbo.Credito(CodigoGarantia) WHERE Estado='VIGENTE';")
emit('CREATE INDEX IX_Credito_Deudor ON dbo.Credito(CodigoDeudor,FechaAprobacion); CREATE INDEX IX_Credito_Vendedor ON dbo.Credito(CodigoVendedor,FechaAprobacion);')
table('CreditoFiador',[('NumeroCredito','varchar(20)','NOT NULL REFERENCES dbo.Credito(NumeroCredito)'),('CodigoFiador','int','NOT NULL REFERENCES dbo.Fiador(CodigoFiador)')],['NumeroCredito','CodigoFiador'])
table('Depreciacion',[('CodigoDepreciacion','int','IDENTITY(1,1) NOT NULL'),('CodigoGarantia','int','NOT NULL REFERENCES dbo.Garantia(CodigoGarantia)'),('FechaValoracion','date','NOT NULL'),('ValorOriginal','decimal(18,2)','NOT NULL CHECK(ValorOriginal>0)'),('Porcentaje','decimal(9,6)','NOT NULL CHECK(Porcentaje BETWEEN 0.15 AND 0.20)'),('Observacion','nvarchar(300)','NOT NULL CHECK(LEN(LTRIM(RTRIM(Observacion)))>0)')],['CodigoDepreciacion'],identity='CodigoDepreciacion')
emit('CREATE INDEX IX_Depreciacion_Historial ON dbo.Depreciacion(CodigoGarantia,FechaValoracion DESC,CodigoDepreciacion DESC);')
table('DetalleCuota',[('NumeroCredito','varchar(20)','NOT NULL REFERENCES dbo.Credito(NumeroCredito)'),('Cuota','smallint','NOT NULL CHECK(Cuota BETWEEN 1 AND 60)'),('FechaVencimiento','date','NOT NULL')]+[(c,'decimal(18,2)',f'NOT NULL CHECK({c}>=0)') for c in ['Capital','Interes']],['NumeroCredito','Cuota'])
emit('CREATE INDEX IX_Cuota_Vencimiento ON dbo.DetalleCuota(FechaVencimiento,NumeroCredito) INCLUDE(Capital,Interes);')
emit('CREATE SEQUENCE dbo.SecComprobante AS bigint START WITH 1 INCREMENT BY 1;')
table('DetallePago',[
 ('CodigoPago','bigint','IDENTITY(1,1) NOT NULL'),('Comprobante','bigint','NOT NULL UNIQUE DEFAULT(NEXT VALUE FOR dbo.SecComprobante)'),('NumeroCredito','varchar(20)','NOT NULL'),('Cuota','smallint','NOT NULL'),
 ('FechaPago','datetime2(0)','NOT NULL'),('CodigoTipoPago','int','NOT NULL REFERENCES dbo.TipoPago(CodigoTipoPago)'),('ReferenciaBancaria','nvarchar(100)','NULL'),('Monto','decimal(18,2)','NOT NULL CHECK(Monto>0)'),
 *[(c,'decimal(18,2)',f'NOT NULL CHECK({c}>=0)') for c in ['Capital','Interes','ManejoCuenta','SeguroAuto','SeguroVida']],
 ('RegistradoPor','nvarchar(100)','NOT NULL CHECK(LEN(LTRIM(RTRIM(RegistradoPor)))>0)'),('FechaAnulacion','datetime2(0)','NULL'),('MotivoAnulacion','nvarchar(300)','NULL'),('AnuladoPor','nvarchar(100)','NULL'),('Observacion','nvarchar(300)','NULL')],['CodigoPago'],
 '''CONSTRAINT FK_Pago_Cuota FOREIGN KEY(NumeroCredito,Cuota) REFERENCES dbo.DetalleCuota(NumeroCredito,Cuota),
 CONSTRAINT CK_Pago_Desglose CHECK(Monto=Capital+Interes+ManejoCuenta+SeguroAuto+SeguroVida),
 CONSTRAINT CK_Pago_Anulacion CHECK((FechaAnulacion IS NULL AND MotivoAnulacion IS NULL AND AnuladoPor IS NULL) OR (FechaAnulacion IS NOT NULL AND FechaAnulacion>=FechaPago AND MotivoAnulacion IS NOT NULL AND AnuladoPor IS NOT NULL))''',identity='CodigoPago',special=True)
emit('CREATE INDEX IX_Pago_Cuota ON dbo.DetallePago(NumeroCredito,Cuota,FechaPago) INCLUDE(Monto,Capital,Interes,ManejoCuenta,SeguroAuto,SeguroVida,FechaAnulacion);')

table('ResumenCredito', [('NumeroCredito','varchar(20)','NOT NULL REFERENCES dbo.Credito(NumeroCredito)'),('TotalIntereses','decimal(18,2)','NOT NULL CHECK(TotalIntereses>=0)'),('TotalNetoRecaudable','decimal(18,2)','NOT NULL CHECK(TotalNetoRecaudable>=0)')], ['NumeroCredito'], special=True)
exec((ROOT/'views.py').read_text(encoding='utf-8'))

# Semillas administrativas. No son operaciones comerciales de ejemplo.
emit("INSERT dbo.Departamento VALUES(21,N'Jalapa'),(22,N'Jutiapa'); INSERT dbo.Municipio VALUES(21,1,N'Jalapa'),(22,1,N'Jutiapa');")
for name, values in {
 'TipoTelefono':['Celular','Casa','Trabajo'], 'TipoDireccion':['Particular','Trabajo','Otra'],
 'TipoGarantia':['Vehiculo nuevo de agencia'], 'TipoReferencia':['Familiar','Amistad','Laboral','Otra'],
 'Marca':['Toyota','Hyundai','Kia','Nissan','Suzuki']}.items():
    emit(f'INSERT dbo.{name} VALUES'+','.join(f"({i},N'{v}')" for i,v in enumerate(values,1))+';')
emit("INSERT dbo.Linea VALUES(1,1,N'Corolla'),(2,1,N'Accent'),(3,1,N'Soluto'),(4,1,N'Versa'),(5,1,N'Swift');")
emit("INSERT dbo.TipoPago VALUES(1,N'Deposito bancario',1),(2,N'Transferencia ACH',1),(3,N'Tarjeta de credito',1),(4,N'Tarjeta de debito',1),(5,N'Efectivo en ventanilla',0);")
emit("INSERT dbo.Agencia(Nombre,Region) VALUES(N'Agencia academica Jalapa',N'Oriente');")
emit("INSERT dbo.ParametroCredito(Nombre,Activo,TasaAnual,ManejoMensual,TasaSeguroAuto,TasaSeguroVida,EngancheMinimo,ComisionPredeterminada,DepreciacionInicial) VALUES(N'Condiciones academicas iniciales',1,0.125,25,0.0015,0.0005,0.20,0.02,0.15);")

# Funciones de consulta; la API las consume a traves de procedimientos.
emit("EXEC(N'CREATE FUNCTION dbo.fn_AhoraGuatemala() RETURNS datetime2(0) AS BEGIN RETURN CONVERT(datetime2(0),SYSUTCDATETIME() AT TIME ZONE ''UTC'' AT TIME ZONE ''Central America Standard Time''); END;');")
saldo_sql = '''CREATE FUNCTION dbo.fn_Saldos(@FechaCorte date) RETURNS TABLE AS RETURN
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
 AND(c.FechaAnulacion IS NULL OR c.FechaAnulacion>=DATEADD(day,1,CONVERT(datetime2,@FechaCorte)));'''
emit("EXEC(N'"+saldo_sql.replace("'","''")+"');")

def generic_guard(name, operation):
    guard=''
    if name=='Persona' and operation!='Eliminar':
        guard="IF @FechaNacimiento>=CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51001,'La fecha de nacimiento debe ser anterior a hoy.',1;"
        if operation=='Actualizar':
            guard+="IF EXISTS(SELECT 1 FROM dbo.Deudor WHERE CodigoPersona=@CodigoPersona) AND (@DPI IS NULL OR @NIT IS NULL OR @CorreoElectronico IS NULL OR @FechaNacimiento IS NULL) THROW 51009,'No quite datos obligatorios de un cliente.',1; IF EXISTS(SELECT 1 FROM dbo.Fiador WHERE CodigoPersona=@CodigoPersona) AND (@DPI IS NULL OR @NIT IS NULL OR @CorreoElectronico IS NULL) THROW 51010,'No quite datos obligatorios de un fiador.',1; IF EXISTS(SELECT 1 FROM dbo.Vendedor WHERE CodigoPersona=@CodigoPersona) AND @DPI IS NULL THROW 51011,'El vendedor requiere DPI.',1;"
    if name in ['Deudor','Fiador','Vendedor'] and operation!='Eliminar':
        condition='DPI IS NOT NULL'
        if name in ['Deudor','Fiador']:condition+=' AND NIT IS NOT NULL AND CorreoElectronico IS NOT NULL'
        if name=='Deudor':condition+=' AND FechaNacimiento IS NOT NULL'
        guard+=f"IF NOT EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=@CodigoPersona AND {condition}) THROW 51012,'Complete los datos obligatorios de la persona antes de asignar este rol.',1;"
        if operation=='Actualizar':
            key=entities[name]['keys'][0]
            guard+=f"IF EXISTS(SELECT 1 FROM dbo.{name} WHERE {key}=@{key} AND CodigoPersona<>@CodigoPersona) THROW 51013,'No se cambia la identidad de un rol; registre otro si corresponde.',1;"
    if name=='DetalleReferencia' and operation!='Eliminar':
        guard="IF EXISTS(SELECT 1 FROM dbo.Deudor d JOIN dbo.Referencia r ON r.CodigoPersona=d.CodigoPersona WHERE d.CodigoDeudor=@CodigoDeudor AND r.CodigoReferencia=@CodigoReferencia) THROW 51002,'El cliente no puede ser su propia referencia.',1;"
    if name=='Referencia' and operation=='Actualizar':
        guard+="IF EXISTS(SELECT 1 FROM dbo.Referencia WHERE CodigoReferencia=@CodigoReferencia AND CodigoPersona<>@CodigoPersona) THROW 51015,'No cambie la persona de una referencia; registre otra referencia.',1;"
    if name in ['CreditoFiador','DetalleCuota']:
        guard="IF NOT EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE NumeroCredito=@NumeroCredito AND Estado='BORRADOR') THROW 51003,'Solo se modifica este detalle mientras el credito es borrador.',1;"
    if name=='CreditoFiador':
        guard+="UPDATE dbo.Credito SET FechaPresentacion=NULL,PresentadoPor=NULL WHERE NumeroCredito=@NumeroCredito;"
    if name=='CreditoFiador' and operation!='Eliminar':
        guard+="IF EXISTS(SELECT 1 FROM dbo.Credito c JOIN dbo.Deudor d ON d.CodigoDeudor=c.CodigoDeudor JOIN dbo.Fiador f ON f.CodigoPersona=d.CodigoPersona WHERE c.NumeroCredito=@NumeroCredito AND f.CodigoFiador=@CodigoFiador) THROW 51004,'El cliente no puede ser fiador de su propio credito.',1;"
    if name=='Garantia' and operation=='Actualizar':
        guard+="IF EXISTS(SELECT 1 FROM dbo.Credito WITH(UPDLOCK,HOLDLOCK) WHERE CodigoGarantia=@CodigoGarantia AND FechaAprobacion IS NOT NULL) THROW 51005,'La garantia tiene historial contractual: conserve sus datos.',1;"
    if name=='Depreciacion' and operation!='Eliminar':
        guard+="IF @FechaValoracion>CONVERT(date,dbo.fn_AhoraGuatemala()) THROW 51006,'La valoracion no puede estar en el futuro.',1;"
    if name=='Depreciacion' and operation in ['Actualizar','Eliminar']:
        guard+="IF EXISTS(SELECT 1 FROM dbo.Depreciacion d JOIN dbo.Credito c ON c.CodigoGarantia=d.CodigoGarantia WHERE d.CodigoDepreciacion=@CodigoDepreciacion AND c.FechaAprobacion IS NOT NULL) THROW 51014,'La valoracion forma parte del historial; registre una nueva valoracion.',1;"
    return guard

for name,e in entities.items():
    keys=e['keys'];cols=e['cols']
    read_source={'Credito':'vw_CreditoResumen','DetalleCuota':'vw_CuotaDesglosada','DetallePago':'vw_PagoDesglosado','Depreciacion':'vw_DepreciacionCalculada'}.get(name,name)
    read_cols=cols + [(c,'decimal(18,2)','') for c in {'Credito':['MontoFinanciado','TotalIntereses','TotalNetoRecaudable'],'DetalleCuota':['ManejoCuenta','SeguroAuto','SeguroVida','Total'],'DetallePago':['PorcentajeComision','Comision'],'Depreciacion':['ValorDepreciado']}.get(name,[])]
    filter_text=' OR '.join(f"CONVERT(nvarchar(4000),[{c}]) LIKE N'%'+@Criterio+N'%'" for c,t,tail in read_cols)
    proc(name+'_Listar','',f'SELECT * FROM dbo.[{read_source}] ORDER BY '+','.join(f'[{k}]' for k in keys)+';')
    proc(name+'_Buscar','@Criterio nvarchar(200)',f"IF NULLIF(LTRIM(RTRIM(@Criterio)),N'') IS NULL THROW 51007,'Indique un criterio de busqueda.',1; SELECT * FROM dbo.[{read_source}] WHERE {filter_text} ORDER BY "+','.join(f'[{k}]' for k in keys)+';')
    if e['special']:continue
    writable=[(c,t,tail) for c,t,tail in cols if t!='AS']
    ins=[(c,t,tail) for c,t,tail in writable if c!=e['identity']]
    def params(items):return ',\n '.join('@'+c+' '+t+(' = NULL' if tail.startswith('NULL') else '') for c,t,tail in items)
    returning=f'INSERTED.[{e["identity"]}] AS Id' if e['identity'] else ','.join('INSERTED.['+k+']' for k in keys)
    proc(name+'_Insertar',params(ins),generic_guard(name,'Insertar')+f'\nINSERT dbo.[{name}]('+','.join('['+c+']' for c,t,tail in ins)+f') OUTPUT {returning} VALUES('+','.join('@'+c for c,t,tail in ins)+');',True)
    nonkeys=[(c,t,tail) for c,t,tail in writable if c not in keys]
    pred=' AND '.join('['+k+']=@'+k for k in keys)
    if nonkeys:
        body=generic_guard(name,'Actualizar')+f'\nUPDATE dbo.[{name}] SET '+','.join('['+c+']=@'+c for c,t,tail in nonkeys)+f' WHERE {pred}; IF @@ROWCOUNT=0 THROW 51008,\'Registro no encontrado.\',1;'
        pp=params(writable)
    else:
        # Tabla puente: actualizar la asignacion (no crear un procedimiento vacio).
        old=keys[-1];typ=next(t for c,t,_ in cols if c==old)
        pp=params(writable)+f', @Nuevo{old} {typ}'
        body=generic_guard(name,'Actualizar')+f'\nDECLARE @Anterior {typ}=@{old}; SET @{old}=@Nuevo{old};'+generic_guard(name,'Insertar')+f' UPDATE dbo.[{name}] SET [{old}]=@Nuevo{old} WHERE '+ ' AND '.join('['+k+']=@'+('Anterior' if k==old else k) for k in keys)+"; IF @@ROWCOUNT=0 THROW 51008,'Registro no encontrado.',1;"
    proc(name+'_Actualizar',pp,body,True)
    proc(name+'_Eliminar',params([x for x in writable if x[0] in keys]),generic_guard(name,'Eliminar')+f"\nDELETE dbo.[{name}] WHERE {pred}; IF @@ROWCOUNT=0 THROW 51008,'Registro no encontrado.',1;",True)

# Operaciones financieras y reportes se agregan desde archivos fuente revisables.
exec((ROOT/'financial_procs.py').read_text(encoding='utf-8'))
exec((ROOT/'presentacion_procs.py').read_text(encoding='utf-8'))
exec((ROOT/'report_procs.py').read_text(encoding='utf-8'))
emit('CREATE ROLE magis_api AUTHORIZATION dbo; GRANT EXECUTE ON SCHEMA::api TO magis_api; DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::dbo TO magis_api;')
emit(f"IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>{len(entities)} THROW 51400,'Inventario de tablas incompleto.',1; IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api'))<>{len(procedures)} THROW 51401,'Inventario de procedimientos incompleto.',1;")
catalogs={'Departamento','Municipio','TipoTelefono','TipoDireccion','TipoGarantia','TipoReferencia','TipoPago','Marca','Linea','Agencia','ParametroCredito'}
for entity in entities:
    if entity not in catalogs:
        emit(f"IF EXISTS(SELECT 1 FROM dbo.[{entity}]) THROW 51402,'La instalacion no debe incluir operaciones de ejemplo.',1;")
emit("SELECT (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) Tablas,(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api')) Procedimientos,(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api') AND name LIKE N'Reporte%') Reportes;")
payload='\n\n'.join(parts)
header='''/* MAGIS-AUTO - VERSION ACADEMICA 2.1 - FASE 4
Instalacion NUEVA para SQL Server 2022 o 2025. Alcance de validacion en LEEME.
Abrir en SSMS, usar una cuenta autorizada para CREATE DATABASE y ejecutar TODO.
Cambiar SOLO @Base si se desea otro nombre. No requiere modo SQLCMD.
Si la base ya existe, se detiene: NO borra, migra ni sobrescribe ninguna base.
Basado en MagisV1 (2).sql y los acuerdos de Fase 0. Esquema ampliado, no copia literal.
Sin clientes, fiadores, vendedores, vehiculos, creditos ni pagos de ejemplo.
Incluye catalogos iniciales, parametros academicos, CRUD controlado y 20 reportes.
Los porcentajes se expresan como fracciones: 0.125=12.5%, 0.02=2%.
La API solo ejecuta procedimientos api.* mediante el rol magis_api.
Las condiciones y limitaciones de los borrados estan documentadas en LEEME.
La creacion de la base es independiente; la instalacion de sus objetos es atomica.
Si falla, queda la base vacia para inspeccion; NO se elimina automaticamente.
*/
USE [master];
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Base sysname=N'MAGISAUTO_Proyecto_V2';
IF NULLIF(LTRIM(RTRIM(@Base)),N'') IS NULL THROW 50000,'Nombre de base requerido.',1;
IF DB_ID(@Base) IS NOT NULL THROW 50001,'La base ya existe. No se modifico. Use otro nombre para una instalacion nueva.',1;
DECLARE @Crear nvarchar(max)=N'CREATE DATABASE '+QUOTENAME(@Base)+N';';
EXEC sys.sp_executesql @Crear;
DECLARE @Instalar nvarchar(max)=N'USE '+QUOTENAME(@Base)+N'; SET XACT_ABORT ON; BEGIN TRY BEGIN TRANSACTION;
'''
tail="\nCOMMIT TRANSACTION; END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;';\nEXEC sys.sp_executesql @Instalar;\nSELECT @Base AS BaseInstalada,N'Instalacion completa. Sin operaciones de ejemplo.' AS Resultado;\n"
(OUT/'MAGISAUTO_Proyecto_Completo.sql').write_text(header+payload.replace("'","''")+tail,encoding='utf-8-sig')
(ROOT/'deployment_payload.sql').write_text(payload,encoding='utf-8')
(OUT/'inventario.json').write_text(json.dumps({'version':'2.1','tablas':list(entities),'vistas':['vw_CreditoResumen','vw_CuotaDesglosada','vw_PagoDesglosado','vw_DepreciacionCalculada'],'procedimientos':procedures},ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'tablas':len(entities),'procedimientos':len(procedures),'bytes':(OUT/'MAGISAUTO_Proyecto_Completo.sql').stat().st_size}))
