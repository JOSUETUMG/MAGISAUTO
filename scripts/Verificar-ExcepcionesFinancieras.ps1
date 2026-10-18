# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Comprueba bloqueos financieros; revierte cada intento.
param([Parameter(Mandatory)][string]$Credencial,[string]$SalidaCompilacion='bin\ConsultasIntegradas')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent;$api=Join-Path $repo 'src\MAGISAUTO.API';$salida=Join-Path $repo 'artifacts\verificacion-excepciones-financieras'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new();$proceso=$null;$estado='Fallido';$creada=$null
function Comprobar([string]$nombre,[bool]$ok){if(-not $ok){throw "Falló: $nombre"};$pruebas.Add([pscustomobject]@{Prueba=$nombre;Resultado='Correcto'})}
function Query([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$da=[Data.SqlClient.SqlDataAdapter]::new($cmd);$ds=[Data.DataSet]::new();try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}}
function Captura{
 $r=[ordered]@{};$tablas=(Query "SELECT t.name,STRING_AGG(QUOTENAME(c.name),',') WITHIN GROUP(ORDER BY ic.key_ordinal) Clave FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id AND i.is_primary_key=1 JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE SCHEMA_NAME(t.schema_id)='dbo' GROUP BY t.name ORDER BY t.name;").Tables[0]
 Comprobar 'Instantánea incluye 26 tablas' ($tablas.Rows.Count -eq 26)
 foreach($t in $tablas.Rows){$json=((Query "SELECT * FROM dbo.[$($t.name)] ORDER BY $($t.Clave) FOR JSON PATH, INCLUDE_NULL_VALUES;").Tables[0].Rows|ForEach-Object{$_[0]}) -join '';$r[$t.name]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))};return ($r|ConvertTo-Json -Compress)
}
try {
 $cn.Open()
 Comprobar 'Destino aislado confirmado' ((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -ceq 'MAGISAUTO_ValidacionV2')
 $antes=Captura
 $fila=(Query "SELECT TOP(1) c.Estado,c.NumeroCredito,d.Cuota,d.FechaVencimiento,d.Capital,d.Interes FROM dbo.Credito c JOIN dbo.DetalleCuota d ON d.NumeroCredito=c.NumeroCredito WHERE c.FechaAprobacion IS NOT NULL AND c.Estado<>'BORRADOR' ORDER BY c.Estado,c.NumeroCredito,d.Cuota").Tables[0]
 Comprobar 'Existe cuota aprobada para ensayo' ($fila.Rows.Count -eq 1)
 $cuota=$fila.Rows[0]
 foreach($accion in @('Insertar','Actualizar','Eliminar')){
  $cmd=$cn.CreateCommand()
  $argumentos=if($accion -eq 'Eliminar'){'@NumeroCredito=@n,@Cuota=@q'}else{'@NumeroCredito=@n,@Cuota=@q,@FechaVencimiento=@f,@Capital=@c,@Interes=@i'}
  # La transacción externa revierte también una operación que inesperadamente tuviera éxito.
  $cmd.CommandText="IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1; BEGIN TRANSACTION; BEGIN TRY EXEC api.DetalleCuota_$accion $argumentos; IF @@TRANCOUNT>0 ROLLBACK; SELECT 0 AS Error; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; SELECT ERROR_NUMBER() AS Error; END CATCH;"
  [void]$cmd.Parameters.Add('@n',[Data.SqlDbType]::VarChar,20);$cmd.Parameters['@n'].Value=$cuota.NumeroCredito
  [void]$cmd.Parameters.Add('@q',[Data.SqlDbType]::SmallInt);$cmd.Parameters['@q'].Value=if($accion -eq 'Insertar'){32767}else{$cuota.Cuota}
  if($accion -ne 'Eliminar'){
   [void]$cmd.Parameters.Add('@f',[Data.SqlDbType]::Date);$cmd.Parameters['@f'].Value=$cuota.FechaVencimiento
   foreach($p in @('c','i')){[void]$cmd.Parameters.Add("@$p",[Data.SqlDbType]::Decimal);$cmd.Parameters["@$p"].Precision=18;$cmd.Parameters["@$p"].Scale=2;$cmd.Parameters["@$p"].Value=1}
  }
  try { $codigo=[int]$cmd.ExecuteScalar();Comprobar "Cuota aprobada bloquea $accion con 51003" ($codigo -eq 51003) } finally { $cmd.Dispose() }
 }
 Comprobar 'Resumen expone cinco operaciones' ((Query "SELECT COUNT(*) FROM sys.procedures WHERE SCHEMA_NAME(schema_id)='api' AND name IN('ResumenCredito_Listar','ResumenCredito_Buscar','ResumenCredito_Insertar','ResumenCredito_Actualizar','ResumenCredito_Eliminar')").Tables[0].Rows[0][0] -eq 5)
 foreach($accion in @('Insertar','Actualizar','Eliminar')){
  $cmd=$cn.CreateCommand();$cmd.CommandText="BEGIN TRANSACTION; BEGIN TRY EXEC api.ResumenCredito_$accion @NumeroCredito=@n; IF @@TRANCOUNT>0 ROLLBACK; SELECT 0; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; SELECT ERROR_NUMBER(); END CATCH;"
  [void]$cmd.Parameters.Add('@n',[Data.SqlDbType]::VarChar,20);$cmd.Parameters['@n'].Value=$cuota.NumeroCredito
  try{Comprobar "Resumen aprobado bloquea $accion" ([int]$cmd.ExecuteScalar() -eq 51003)}finally{$cmd.Dispose()}
 }
 $despues=Captura
 Comprobar 'Las 26 tablas conservan su contenido' ($antes -ceq $despues)
 $estado='Correcto'
} finally {
 if($cn.State -eq 'Open'){[void](Query 'IF @@TRANCOUNT>0 ROLLBACK;');$cn.Close()};$cn.Dispose()
 [pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';EstadoContratoEnsayado=$cuota.Estado;FechaGuatemala=[DateTime]::UtcNow.AddHours(-6).ToString('s');Pruebas=$pruebas}|ConvertTo-Json -Depth 6|Set-Content (Join-Path $salida 'resultado.json') -Encoding utf8
}
