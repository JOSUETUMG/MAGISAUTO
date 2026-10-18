# Actualización local, con copia de procedimientos y comparación de las 26 tablas.
# Para otros equipos: ejecutar el SQL 003 completo en la base elegida en SSMS.
param(
 [Parameter(Mandatory)][ValidateSet('MAGISAUTO_ValidacionV2','MAGISAUTO_Entrega_Final')][string]$Base,
 [Parameter(Mandatory)][string]$Credencial
)
$ErrorActionPreference='Stop';$repo=Split-Path $PSScriptRoot -Parent
$salida=Join-Path $repo ('artifacts/crud-entrega-'+$Base+'-'+(Get-Date -Format yyyyMMdd-HHmmss))
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new("Server=tcp:127.0.0.1,1433;Database=$Base;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8",[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$tx=$null
function Query([string]$sql){$cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandTimeout=45;$cmd.CommandText=$sql;$da=[Data.SqlClient.SqlDataAdapter]::new($cmd);$ds=[Data.DataSet]::new();try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}}
function Huellas{
 $tablas=(Query "SELECT t.name,STRING_AGG(QUOTENAME(c.name),',') WITHIN GROUP(ORDER BY ic.key_ordinal) Clave FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id AND i.is_primary_key=1 JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE SCHEMA_NAME(t.schema_id)='dbo' GROUP BY t.name ORDER BY t.name").Tables[0]
 if($tablas.Rows.Count -ne 26){throw 'Se esperaban las 26 tablas del proyecto.'}
 $r=[ordered]@{}
 foreach($t in $tablas.Rows){$json=((Query "SELECT * FROM dbo.[$($t.name)] ORDER BY $($t.Clave) FOR JSON PATH,INCLUDE_NULL_VALUES").Tables[0].Rows|ForEach-Object{$_[0]}) -join ''; $r[$t.name]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))}
 return ($r|ConvertTo-Json -Compress)
}
try{
 $cn.Open();if((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -cne $Base){throw 'Destino inesperado.'}
 $permisos=(Query "SELECT HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CREATE PROCEDURE') Crear,HAS_PERMS_BY_NAME('api','SCHEMA','ALTER') Alterar").Tables[0].Rows[0]
 if($permisos.Crear -ne 1 -or $permisos.Alterar -ne 1){throw 'La cuenta actual no puede crear/alterar procedimientos. Ejecutar 003 completo desde SSMS con una cuenta ya autorizada; no cambiar permisos de la cuenta API.'}
 $tx=$cn.BeginTransaction([Data.IsolationLevel]::Serializable)
 $antes=Huellas
 $nombres=@('DetallePago_Eliminar','Depreciacion_Actualizar','Depreciacion_Eliminar')
 $respaldo=[Collections.Generic.List[string]]::new();$respaldo.Add("USE [$Base];")
 foreach($n in $nombres){
  $def=(Query "SELECT OBJECT_DEFINITION(OBJECT_ID(N'api.$n'))").Tables[0].Rows[0][0]
  if($def -is [DBNull]){$respaldo.Add("DROP PROCEDURE IF EXISTS api.[$n];")}
  else{$alter=([string]$def -replace '^CREATE\s+(OR\s+ALTER\s+)?PROCEDURE','CREATE OR ALTER PROCEDURE');$respaldo.Add("EXEC(N'"+$alter.Replace("'","''")+"');")}
 }
 $respaldo|Set-Content (Join-Path $salida 'restaurar-procedimientos.sql') -Encoding utf8
 $migracion=Get-Content (Join-Path $repo 'database/v2/migraciones/003_CRUD_Entrega.sql') -Raw
 [void](Query $migracion)
 $despues=Huellas
 if($antes -cne $despues){throw 'La comparación detectó cambios en los datos. Se revierte la actualización.'}
 $cantidad=[int](Query "SELECT COUNT(*) FROM sys.procedures WHERE SCHEMA_NAME(schema_id)='api'").Tables[0].Rows[0][0]
 $tx.Commit();$tx=$null
 [pscustomobject]@{Base=$Base;Fecha=(Get-Date -Format o);Estado='Correcto';TablasConservadas=26;ProcedimientosApi=$cantidad;Antes=($antes|ConvertFrom-Json);Despues=($despues|ConvertFrom-Json)}|ConvertTo-Json -Depth 5|Set-Content (Join-Path $salida 'resultado.json') -Encoding utf8
 Write-Output "$Base actualizada: 26 tablas conservadas; $cantidad procedimientos API. Respaldo y resultado: $salida"
}catch{if($tx -and $tx.Connection){$tx.Rollback()};throw}finally{if($tx){$tx.Dispose()};$cn.Dispose()}
