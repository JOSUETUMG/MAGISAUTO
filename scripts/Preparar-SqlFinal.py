"""Construye el instalador final sin conectarse a SQL Server ni cambiar archivos historicos."""
from pathlib import Path
import re, json, hashlib

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'database/final'
OUT.mkdir(parents=True,exist_ok=True)
source=ROOT/'database/equipo/MAGISAUTO_Equipo_2026-10-13.sql'
migration=ROOT/'database/v2/migraciones/002_Cierre_Tecnico.sql'
source_bytes=source.read_bytes()
src=source_bytes.decode('utf-8-sig')
marker="DECLARE @Carga nvarchar(max)=N'USE '+QUOTENAME(@Base)+N';"
assert src.count(marker)==1
payload=src.split(marker,1)[1].rsplit("';",1)[0].replace("''", "'")
assert payload.startswith(' SET XACT_ABORT ON; BEGIN TRY BEGIN TRANSACTION;')
assert payload.rstrip().endswith('THROW; END CATCH;')
literal=re.compile(r"EXEC\(N'((?:[^']|'')*)'\);",re.S)
kind=re.compile(r'CREATE\s+(?:OR\s+ALTER\s+)?(PROCEDURE|VIEW|FUNCTION)\s+(\w+)\.\[?(\w+)\]?',re.I)
modules={}
def collect(m):
 text=m.group(1).replace("''", "'")
 found=kind.match(text)
 if not found:return m.group(0)
 key=found.group(2)+'.'+found.group(3)
 modules[key]=text
 return '\n-- OBJETOS_FINALES --\n' if len(modules)==1 else ''
body=literal.sub(collect,payload)
assert len(modules)==157,len(modules)
changed=[]
for match in literal.finditer(migration.read_text(encoding='utf-8-sig')):
 text=match.group(1).replace("''", "'");found=kind.match(text)
 if found:
  key=found.group(2)+'.'+found.group(3);modules[key]=text;changed.append(key)
assert len(changed)==9 and len(modules)==160
notes={
 'api.Credito_Presentar':'EXPEDIENTE: exige datos y tres referencias completas antes de presentar.',
 'api.Credito_Aprobar':'APROBACION: valida requisitos; sustituye simulaciones por cuotas y resumen definitivos.',
 'api.Credito_Actualizar':'BORRADOR: sincroniza el resumen si cambian las condiciones financieras.',
 'api.Credito_Anular':'HISTORIAL: exige resolver pagos efectivos antes de anular el contrato.',
 'api.DetallePago_Insertar':'PAGO: valida saldo y medio, desglosa componentes y asigna un recibo unico.',
 'api.DetallePago_Anular':'ANULACION: conserva el pago y registra fecha, motivo y responsable.',
 'api.DetallePago_Eliminar':'PROTECCION: la correccion financiera se realiza por anulacion, no borrado fisico.',
 'api.Reporte10_Intereses':'DEVENGO ACADEMICO: interes completo al vencimiento; anticipos separados, sin prorrateo diario.',
 'dbo.fn_Saldos':'CORTE HISTORICO: considera fecha de pago y fecha de anulacion al reconstruir los saldos.',
 'dbo.vw_CuotaDesglosada':'CUOTA TOTAL: capital, interes, manejo y seguros; el enganche queda fuera.',
 'dbo.vw_DepreciacionCalculada':'GARANTIA: la depreciacion no modifica la deuda ni el contrato.',
}
chunks=[]
for key,text in modules.items():
 found=kind.match(text)
 # Instalacion nueva: una sola definicion final por objeto; sin actualizaciones intermedias.
 text=re.sub(r'^CREATE\s+(?:OR\s+ALTER\s+)?', 'CREATE ',text,count=1,flags=re.I)
 note=notes.get(key)
 if key.startswith('api.ResumenCredito_') and key.split('_')[-1] in ('Insertar','Actualizar','Eliminar'):
  note='RESUMEN DE SIMULACION: solo BORRADOR; importes calculados, nunca introducidos a mano.'
 if key.startswith('api.DetalleCuota_') and key.split('_')[-1] in ('Insertar','Actualizar','Eliminar'):
  note='CUOTA DE SIMULACION: solo BORRADOR; mantiene coherente el resumen existente.'
 chunks.append('-- '+key+('\n-- '+note if note else '')+"\nEXEC(N'"+text.replace("'","''")+"');")
assert body.count('-- OBJETOS_FINALES --')==1
body=body.replace('-- OBJETOS_FINALES --','-- 3. VISTAS, FUNCIONES Y PROCEDIMIENTOS DEFINITIVOS\n'+ '\n\n'.join(chunks))
body=body.replace('<>151 THROW 51401','<>154 THROW 51401')
body=body.replace('-- Definiciones vigentes capturadas de la base fuente.','')
body=body.replace('CREATE TABLE dbo.[Departamento]','-- 2. TABLAS Y RELACIONES: PK, FK, indices y restricciones de negocio.\nCREATE TABLE dbo.[Departamento]',1)
body=body.replace('CREATE ROLE magis_api','-- 4. SEGURIDAD: ejecutar procedimientos; sin acceso directo a las tablas.\n-- No se crean logins, usuarios de servidor ni contrasenas. Cada equipo configura su acceso.\nCREATE ROLE magis_api',1)
first=body.index(' NOCHECK CONSTRAINT ALL;')
begin=body.rfind('\n',0,first)
body=body[:begin]+'\n-- 5. DATOS FICTICIOS: fotografia del equipo del 13/10/2026 (81 filas).\n-- Se cargan claves historicas; al terminar se revalidan TODAS las restricciones.\n'+body[begin:]
body=body.replace('ALTER SEQUENCE [dbo].[SecComprobante] RESTART WITH 4;', '-- El siguiente recibo sera 4; los recibos 1 y 3 son efectivos y el 2 esta anulado.\nALTER SEQUENCE [dbo].[SecComprobante] RESTART WITH 4;')
body=body.replace("SELECT N'Copia de equipo instalada' Resultado, DB_NAME() Base, COUNT(*) Recibos FROM dbo.DetallePago;", """-- 6. VALIDACION FINAL: no confirmar una instalacion incompleta.
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api'))<>154 THROW 52502,'Se esperaban 154 procedimientos API.',1;
IF (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped=0)<>4 THROW 52502,'Se esperaban 4 vistas.',1;
IF (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN','IF','TF') AND is_ms_shipped=0)<>2 THROW 52502,'Se esperaban 2 funciones.',1;
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'api') AND name LIKE N'Reporte%')<>20 THROW 52502,'Se esperaban 20 reportes.',1;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1) OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE is_disabled=1 OR is_not_trusted=1) THROW 52502,'Restricciones sin validar.',1;
EXEC sys.sp_addextendedproperty @name=N'MAGISAUTO_EntregaFinal',@value=N'b8c44aa + 002 integrada; datos de muestra 2026-10-13';""")
# El resultado de exito se devuelve despues de confirmar la transaccion.
body=body.replace('COMMIT TRANSACTION; END TRY', "COMMIT TRANSACTION;\nSELECT N'Instalacion final completada' Resultado, DB_NAME() Base, 26 Tablas, 154 ProcedimientosAPI, 4 Vistas, 2 Funciones, 20 Reportes, 81 FilasDeMuestra;\nEND TRY")
body=re.sub(r'\n[ \t]*\n(?:[ \t]*\n)+','\n\n',body)
demo_file=OUT/'DATOS_DEMOSTRACION.sql'
demo=json.loads((OUT/'datos-demostracion.json').read_text(encoding='utf-8'))
first=body.index('-- 5. DATOS FICTICIOS:')
last=body.index('-- 6. VALIDACION FINAL:')
body=body[:first]+'-- 5. DATOS DE DEMOSTRACION COHERENTES; CORTE 16/10/2026.\n'+demo_file.read_text(encoding='utf-8')+'\n'+body[last:]
body=body.replace('81 FilasDeMuestra',str(demo['Filas'])+' FilasDeMuestra').replace('datos de muestra 2026-10-13','datos coherentes 2026-10-16-v1')
header="""/* MAGIS-AUTO - SQL FINAL DE ENTREGA - 16/10/2026
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
"""
final=header+"DECLARE @Carga nvarchar(max)=N'USE '+QUOTENAME(@Base)+N';"+body.replace("'","''")+"';\nEXEC sys.sp_executesql @Carga;\n"
target=OUT/'MAGISAUTO_Final.sql'
target.write_bytes(final.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8-sig'))
# Material desescapado solo para verificaciones locales, nunca para ejecutar por fragmentos.
work=ROOT/'artifacts/sql-final';work.mkdir(parents=True,exist_ok=True)
(work/'carga.sql').write_text(body,encoding='utf-8')
(work/'modulos.json').write_text(json.dumps(modules,ensure_ascii=False,indent=2),encoding='utf-8')
manifest=json.loads((ROOT/'database/equipo/manifest.json').read_text(encoding='utf-8-sig'))
meta={'archivo':target.name,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'commitCodigo':'b8c44aab3976a5facf6ed6d9ced2ea1205eaedd2','destinoPredeterminado':'MAGISAUTO_Entrega_Final','tablas':demo['Tablas'],'filasMuestra':demo['Filas'],'fechaDatosMuestra':demo['Corte'],'versionDatos':demo['Version'],'procedimientosApi':154,'vistas':4,'funciones':2,'reportes':20,'migracionesIntegradas':['001','002'],'fuentes':{str(source.relative_to(ROOT)):hashlib.sha256(source_bytes).hexdigest(),str(migration.relative_to(ROOT)):hashlib.sha256(migration.read_bytes()).hexdigest()},'credencialesIncluidas':False,'datosSha256':hashlib.sha256(demo_file.read_bytes()).hexdigest(),'estado':'Preparado; pendiente carga y comprobacion en SSMS'}
(OUT/'manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('SQL final generado: 160 objetos programables, 26 tablas y 350 filas de demostracion.')
