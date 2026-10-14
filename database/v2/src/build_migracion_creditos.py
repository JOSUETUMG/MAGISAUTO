"""Genera un parche aditivo a partir de los mismos procedimientos del instalador."""
from pathlib import Path
import runpy
root = Path(__file__).resolve().parent
ns = runpy.run_path(str(root / 'build_entrega.py'))
names = ['Credito_Presentar','Credito_Actualizar','Credito_Aprobar',
         'CreditoFiador_Insertar','CreditoFiador_Actualizar','CreditoFiador_Eliminar']
parts = [p.replace('CREATE PROCEDURE', 'CREATE OR ALTER PROCEDURE', 1)
         for p in ns['parts'] if any('CREATE PROCEDURE api.[' + n + ']' in p for n in names)]
assert len(parts) == len(names)
parts = ["\n".join(line.rstrip() for line in part.split("\n")) for part in parts]
header = """/* MAGIS-AUTO: presentación de solicitudes. Ejecutar TODO en SSMS con una cuenta
autorizada para alterar esta base. No borra registros ni crea otra base.
Destino predeterminado: MAGISAUTO_Proyecto_V2. Puede repetirse.
Los contratos históricos conservan su estado y no reciben una presentación inventada. */
USE [MAGISAUTO_Proyecto_V2];
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 IF OBJECT_ID(N'dbo.Credito',N'U') IS NULL THROW 51500,'Falta el esquema v2.',1;
 IF COL_LENGTH('dbo.Credito','FechaPresentacion') IS NULL ALTER TABLE dbo.Credito ADD FechaPresentacion datetime2(0) NULL;
 IF COL_LENGTH('dbo.Credito','PresentadoPor') IS NULL ALTER TABLE dbo.Credito ADD PresentadoPor nvarchar(100) NULL;
 EXEC sys.sp_refreshview N'dbo.vw_CreditoResumen';
"""
out = root.parent / 'migraciones'
out.mkdir(exist_ok=True)
(out / '001_Presentacion_Creditos.sql').write_text(header + '\n\n'.join(parts) + """
 COMMIT TRANSACTION;
 SELECT DB_NAME() BaseActualizada,N'Presentación de créditos instalada' Resultado;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
""",encoding='utf-8-sig')
