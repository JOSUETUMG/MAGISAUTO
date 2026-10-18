"""Prepara datos ficticios coherentes y un reemplazo protegido para SSMS; no conecta a SQL."""
from pathlib import Path
import re,json,hashlib,collections
R=Path(__file__).resolve().parents[1];D=R/'database/final';A=R/'artifacts/datos-entrega';A.mkdir(parents=True,exist_ok=True)
old=(R/'database/equipo/MAGISAUTO_Equipo_2026-10-13.sql').read_text(encoding='utf-8-sig')
mark="DECLARE @Carga nvarchar(max)=N'USE '+QUOTENAME(@Base)+N';"
old=old.split(mark,1)[1].rsplit("';",1)[0].replace("''","'")
inserts=re.findall(r'INSERT INTO dbo\.\[(\w+)\] \(([^\n]+?)\) VALUES \(([^\n]+)\);',old)
assert len(inserts)==81
def lit(x):
 if x is None:return 'NULL'
 if isinstance(x,(int,float)):return str(x)
 return "N'"+x.replace("'","''")+"'"
seed=["-- DATOS FICTICIOS COHERENTES, corte de demostracion: 16/10/2026.","-- Nombres, DPI, NIT, VIN, contactos y direcciones son sinteticos.","-- Planes y pagos se calculan con los procedimientos reales, no a mano.","IF CONVERT(date,dbo.fn_AhoraGuatemala())<'20261016' THROW 52700,'Estos casos requieren fecha del servidor igual o posterior al 16/10/2026.',1;"]
counts=collections.Counter()
def rows(table,columns,data,identity=False):
 if identity:seed.append(f'SET IDENTITY_INSERT dbo.[{table}] ON;')
 for row in data:seed.append(f'INSERT dbo.[{table}] ({",".join("["+c+"]" for c in columns)}) VALUES ({",".join(lit(x) for x in row)});');counts[table]+=1
 if identity:seed.append(f'SET IDENTITY_INSERT dbo.[{table}] OFF;')
cats=['Departamento','Municipio','TipoTelefono','TipoDireccion','TipoGarantia','TipoReferencia','TipoPago','Marca','Linea']
for catalog in cats:
 for t,c,v in inserts:
  if t==catalog:seed.append(f'INSERT dbo.[{t}] ({c}) VALUES ({v});');counts[t]+=1
rows('Agencia',['CodigoAgencia','Nombre','Region'],[(1,'MAGIS-AUTO Jalapa','Oriente'),(2,'MAGIS-AUTO Jutiapa','Oriente')],True)
rows('ParametroCredito',['CodigoParametro','Nombre','Activo','TasaAnual','ManejoMensual','TasaSeguroAuto','TasaSeguroVida','EngancheMinimo','ComisionPredeterminada','DepreciacionInicial'],[(1,'Plan automotriz 2026',1,.125,25,.0015,.0005,.2,.02,.15)],True)
names=[('Ana','Lucía','Morales','López'),('Carlos','Eduardo','Méndez','Ruiz'),('María','Fernanda','Castillo','Paz'),('José','Antonio','Herrera','Díaz'),('Sofía','Isabel','Ramírez','Luna'),('Luis','Fernando','Aguilar','Reyes'),('Mario','Alberto','Rivas','Cruz'),('Paola','Andrea','Mejía','Soto'),('Elena','Patricia','Vargas','León'),('Ricardo','Estuardo','Pineda','Roca'),('Gabriela','Alejandra','Duarte','Vega'),('Andrea','Paola','Fuentes','Gil'),('Daniel','Esteban','Cabrera','Mora'),('Patricia','Elena','López','Solís'),('Roberto','Enrique','Santos','Pérez'),('Mónica','Beatriz','Rivera','Ruiz'),('Jorge','Manuel','Reyes','Lima'),('Claudia','Maribel','Gómez','Lara'),('Sergio','Andrés','Luna','Ríos'),('Verónica','Isabel','Paz','Navas'),('Héctor','Daniel','Flores','Cano'),('Rosa','María','Cruz','Mena'),('Óscar','Eduardo','Vega','Sosa'),('Diana','Carolina','Ruiz','Ochoa'),('Fernando','Javier','León','Vidal'),('Lucía','Gabriela','Soto','Campos'),('Miguel','Ángel','Roca','Molina'),('Adriana','Marisol','Peña','López'),('Pablo','Andrés','Navas','Herrera'),('Sandra','Elizabeth','Mora','Reyes')]
# 6 clientes, 2 vendedores, 3 fiadores y 18 referencias = 29 personas.
names=names[:29]
person=[]
for n,parts in enumerate(names,1):
 birth=f'{1985+n%12}-{10 if n in (1,5) else n%9+1:02d}-{n%25+1:02d}'
 female={1,3,5,8,9,11,12,14,16,18,20,22,24,26,28}
 person.append((n,f'990{n:010d}',f'{9000000+n}-{n%10}',*parts,birth,'F' if n in female else 'M',f'persona{n:02d}@example.invalid'))
rows('Persona',['CodigoPersona','DPI','NIT','PrimerNombre','SegundoNombre','PrimerApellido','SegundoApellido','FechaNacimiento','Genero','CorreoElectronico'],person,True)
rows('Telefono',['CodigoPersona','Correlativo','CodigoTipoTelefono','Numero'],[(n,1,1,f'5550{1000+n:04d}') for n in range(1,30)])
rows('Direccion',['CodigoPersona','Correlativo','CodigoTipoDireccion','CodigoDepartamento','CodigoMunicipio','Detalle'],[(n,1,1,21 if n%2 else 22,1,f'{n} avenida, casa {10+n}, zona 1') for n in range(1,30)])
rows('Deudor',['CodigoDeudor','CodigoPersona'],[(n,n) for n in range(1,7)],True)
rows('Vendedor',['CodigoVendedor','CodigoEmpleado','CodigoPersona','CodigoAgencia'],[(1,'VEN-001',7,1),(2,'VEN-002',8,2)],True)
rows('Fiador',['CodigoFiador','CodigoPersona'],[(1,9),(2,10),(3,11)],True)
jobs=['Centro educativo Los Pinos','Comercial El Roble','Clínica Las Flores']
rows('Referencia',['CodigoReferencia','CodigoPersona','LugarTrabajo'],[(n,n+11,jobs[(n-1)%3]) for n in range(1,19)],True)
rows('DetalleReferencia',['CodigoDeudor','CodigoReferencia','CodigoTipoReferencia','ParentescoRelacion'],[(client,(client-1)*3+j,2 if j<3 else 3,'Amistad' if j<3 else 'Compañero de trabajo') for client in range(1,7) for j in range(1,4)])
prices=[150000,125000,110000,135000,105000,160000,145000,118000]
brands=[1,2,3,4,5,1,4,2]
rows('Garantia',['CodigoGarantia','VIN','CodigoMarca','CodigoLinea','Anio','ValorAgencia','Placa','CodigoTipoGarantia','EsNuevo'],[(n,f'MGA2026{n:010d}',brands[n-1],1,2026,prices[n-1],None,1,1) for n in range(1,9)],True)
seed += ["-- En una base nueva las identidades empiezan en 1. En el reemplazo, se reinician solo tras vaciar los datos autorizados.","IF EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID('dbo.Depreciacion') AND last_value IS NOT NULL) DBCC CHECKIDENT ('dbo.Depreciacion', RESEED, 0) WITH NO_INFOMSGS;", "IF EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=OBJECT_ID('dbo.DetallePago') AND last_value IS NOT NULL) DBCC CHECKIDENT ('dbo.DetallePago', RESEED, 0) WITH NO_INFOMSGS;",'ALTER SEQUENCE dbo.SecComprobante RESTART WITH 1;']
cases=[('20260710',24,1,'Al día'),('20260805',36,2,'Abono parcial'),('20260615',48,3,'En mora'),('20261001',12,0,'Anticipo'),('20260912',24,1,'Pago anulado'),(None,60,2,'Borrador')]
for n,(date,months,guarantor,case) in enumerate(cases,1):
 code=f'MGA-2026-{n:03d}';seed.append(f'-- {code}: {case}.')
 seed.append(f"EXEC api.Credito_Insertar @NumeroCredito='{code}',@CodigoDeudor={n},@CodigoGarantia={n},@CodigoVendedor={1 if n%2 else 2},@Enganche={prices[n-1]*.2:.2f},@Plazo={months},@FiadoresRequeridos={1 if guarantor else 0};")
 if guarantor:seed.append(f"EXEC api.CreditoFiador_Insertar @NumeroCredito='{code}',@CodigoFiador={guarantor};");counts['CreditoFiador']+=1
 if date:
  seed.append(f"EXEC api.Credito_Presentar @NumeroCredito='{code}',@Responsable=N'Coordinación comercial';")
  # El SP Presentar no recibe fecha: para esta carga historica sintetica se fija antes de aprobar.
  seed.append(f"UPDATE dbo.Credito SET FechaPresentacion=DATEADD(hour,8,CONVERT(datetime2,'{date}')) WHERE NumeroCredito='{code}' AND Estado='BORRADOR';")
  seed.append(f"EXEC api.Credito_Aprobar @NumeroCredito='{code}',@Responsable=N'Comité de crédito',@FechaAprobacion='{date} 09:00:00',@PorcentajeDepreciacion=0.15;")
  counts['DetalleCuota']+=months;counts['ResumenCredito']+=1;counts['Depreciacion']+=1
 counts['Credito']+=1
seed.append('DECLARE @Importe decimal(18,2),@PagoAnulado bigint;')
payments=[(1,1,'20260810',1,1),(1,2,'20260910',1,2),(1,3,'20261010',1,3),(2,1,'20260905',1,4),(2,2,'20261005',.5,5),(3,1,'20260715',1,2),(4,1,'20261005',.5,1),(5,1,'20261012',1,2)]
for i,(credit,quota,date,fraction,medium) in enumerate(payments,1):
 code=f'MGA-2026-{credit:03d}'
 seed.append(f"SELECT @Importe=ROUND(Total*{fraction},2) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito='{code}' AND Cuota={quota};")
 seed.append(f"EXEC api.DetallePago_Insertar @NumeroCredito='{code}',@Cuota={quota},@Monto=@Importe,@CodigoTipoPago={medium},@Responsable=N'Caja MAGIS-AUTO',@ReferenciaBancaria=N'OP-2026-{i:04d}',@FechaPago='{date} 10:00:00',@Observacion=N'Abono registrado en caja';")
seed += ["EXEC api.DetallePago_Insertar @NumeroCredito='MGA-2026-005',@Cuota=2,@Monto=1000,@CodigoTipoPago=2,@Responsable=N'Caja MAGIS-AUTO',@ReferenciaBancaria=N'OP-2026-0009',@FechaPago='20261013 10:00:00',@Observacion=N'Abono pendiente de conciliación';", "SELECT @PagoAnulado=CodigoPago FROM dbo.DetallePago WHERE NumeroCredito='MGA-2026-005' AND Cuota=2;", "EXEC api.DetallePago_Anular @CodigoPago=@PagoAnulado,@Motivo=N'Transferencia rechazada por el banco',@Responsable=N'Supervisión de caja';", "-- Fecha historica de la anulacion ficticia: posterior al pago, anterior al corte de la muestra.", "UPDATE dbo.DetallePago SET FechaAnulacion='20261014 11:00:00' WHERE CodigoPago=@PagoAnulado;", "EXEC api.Depreciacion_Insertar @CodigoGarantia=1,@FechaValoracion='20261015',@ValorOriginal=127500,@Porcentaje=0.15,@Observacion=N'Revisión trimestral de valor comercial';"]
counts['DetallePago']=9;counts['Depreciacion']+=1
assert len(counts)==26
for table,total in sorted(counts.items()):seed.append(f"IF (SELECT COUNT_BIG(*) FROM dbo.[{table}])<>{total} THROW 52701,'Conteo inesperado en {table}.',1;")
checks="""-- Comprobar la coherencia financiera y los casos, no solo la cantidad de filas.
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
"""
seed.append(checks)
seed.append("EXEC sys.sp_addextendedproperty @name=N'MAGISAUTO_DatosEntrega',@value=N'2026-10-16-v1';")
seed='\n'.join(seed)+'\n'
(D/'DATOS_DEMOSTRACION.sql').write_text('-- COMPONENTE DEL INSTALADOR. No ejecutar solo: requiere tablas vacias y transaccion externa.\n'+seed,encoding='utf-8')
(D/'datos-demostracion.json').write_text(json.dumps({'Version':'2026-10-16-v1','Corte':'2026-10-16','DatosFicticios':True,'Tablas':dict(sorted(counts.items())),'Filas':sum(counts.values()),'Casos':[{ 'Credito':f'MGA-2026-{n:03d}','Cliente':' '.join(names[n-1]),'Caso':x[3]} for n,x in enumerate(cases,1)]},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# Respaldo SQL Server obligatorio antes de reemplazar la muestra original exacta.
guards=[];group=collections.defaultdict(list);cols={}
schema=json.loads((D/'modelo-columnas.json').read_text(encoding='utf-8'))
def sqltype(t,c):
 x=next(x for x in schema if x['Tabla']==t and x['Columna']==c);typ=x['Tipo']
 if typ in ('varchar','nvarchar','char','nchar'):return typ+'('+('max' if x['Longitud']==-1 else str(x['Longitud']//(2 if typ.startswith('n') else 1)))+')'
 if typ in ('decimal','numeric'):return f"{typ}({x['Precision']},{x['Escala']})"
 if typ=='datetime2':return f"datetime2({x['Escala']})"
 return typ
def splitvalues(v):
 parts=[];start=0;depth=0;quote=False;i=0
 while i<len(v):
  ch=v[i]
  if ch=="'":
   if quote and i+1<len(v) and v[i+1]=="'":i+=2;continue
   quote=not quote
  elif not quote:
   if ch=='(':depth+=1
   elif ch==')':depth-=1
   elif ch==',' and depth==0:parts.append(v[start:i]);start=i+1
  i+=1
 parts.append(v[start:]);assert not quote and depth==0
 return parts
for t,c,v in inserts:
 cn=re.findall(r'\[(\w+)\]',c);values=splitvalues(v);assert len(cn)==len(values)
 group[t].append('('+','.join(f'CAST({value} AS {sqltype(t,col)})' for col,value in zip(cn,values))+')');cols[t]=c
for t,values in group.items():
 guards.append(f"IF (SELECT COUNT_BIG(*) FROM dbo.[{t}])<>{len(values)} OR EXISTS(SELECT {cols[t]} FROM dbo.[{t}] EXCEPT SELECT {cols[t]} FROM (VALUES {','.join(values)}) AS original({cols[t]})) THROW 52710,'La muestra original cambio en {t}; no se reemplazo.',1;")
delete_order=['DetallePago','DetalleCuota','ResumenCredito','CreditoFiador','Credito','Depreciacion','DetalleReferencia','Referencia','Deudor','Fiador','Vendedor','Telefono','Direccion','Persona','Garantia','Linea','Marca','Agencia','ParametroCredito','Municipio','Departamento','TipoTelefono','TipoDireccion','TipoGarantia','TipoReferencia','TipoPago']
assert set(delete_order)==set(counts)
pre="""/* Ejecutar TODO en SSMS como administrador. SOLO MAGISAUTO_Entrega_Final.
Reemplaza la muestra original de 81 filas por datos ficticios coherentes.
Verifica que no se modifico la muestra. Respalda y verifica un .bak antes de borrar.
Ante fallo de respaldo o validacion, no reemplaza datos. No toca las otras bases.
No repetir tras registrar movimientos propios. No modifica procedimientos ni tablas.
*/
USE [MAGISAUTO_Entrega_Final];
SET NOCOUNT ON; SET XACT_ABORT ON;
IF DB_NAME()<>N'MAGISAUTO_Entrega_Final' THROW 52710,'Base incorrecta.',1;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'MAGISAUTO_DatosEntrega') THROW 52710,'Datos de entrega ya instalados. No se repite la carga.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'MAGISAUTO_EntregaFinal') THROW 52710,'No es el instalador final esperado.',1;
"""
backup="""
DECLARE @Directorio nvarchar(4000)=CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultBackupPath'));
IF @Directorio IS NULL THROW 52710,'No se encontro directorio de respaldo; no se reemplazo nada.',1;
IF RIGHT(@Directorio,1) NOT IN ('\\','/') SET @Directorio+=N'\\';
DECLARE @Respaldo nvarchar(4000)=@Directorio+N'MAGISAUTO_Entrega_Final_antes_datos_'+REPLACE(CONVERT(nvarchar(36),NEWID()),'-','')+N'.bak';
BEGIN TRY
 BACKUP DATABASE [MAGISAUTO_Entrega_Final] TO DISK=@Respaldo WITH COPY_ONLY,CHECKSUM;
 RESTORE VERIFYONLY FROM DISK=@Respaldo WITH CHECKSUM;
END TRY BEGIN CATCH THROW; END CATCH;
SELECT @Respaldo RespaldoVerificado;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Bloqueo int;
 EXEC @Bloqueo=sys.sp_getapplock @Resource=N'MAGISAUTO_CargaDatosEntrega',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=0;
 IF @Bloqueo<0 THROW 52710,'Ya hay otra carga en curso.',1;
 -- Bloquear las tablas durante la comprobacion y reemplazo; la aplicacion debe estar detenida.
 DECLARE @Conteo bigint;
"""
locks='\n'.join(f'SELECT @Conteo=COUNT_BIG(*) FROM dbo.[{t}] WITH(TABLOCKX,HOLDLOCK);' for t in delete_order)
sql=pre+'\n'.join(guards)+backup+locks+'\n'+'\n'.join(guards)+'\n'+'\n'.join(f'DELETE FROM dbo.[{t}];' for t in delete_order)+'\n'+seed+"\nCOMMIT;\nSELECT N'Datos de entrega instalados' Resultado,DB_NAME() Base,6 Creditos,144 Cuotas,9 Pagos,1 PagosAnulados,@Respaldo RespaldoAnterior;\nEND TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;\n"
(D/'PREPARAR_DEMOSTRACION.sql').write_text(sql,encoding='utf-8')
print(f'Datos preparados: {sum(counts.values())} filas, 6 creditos, 144 cuotas y 9 pagos; todavia no ejecutados.')
