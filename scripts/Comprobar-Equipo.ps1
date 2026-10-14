# Lee la configuracion local sin imprimirla. Solo consulta SP y metadatos de la conexion.
param()
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$ruta=Join-Path $repo 'src/MAGISAUTO.API/appsettings.Local.json'
if(-not(Test-Path -LiteralPath $ruta)){throw 'Primero ejecuta Preparar-Equipo.ps1 y habilita la cuenta en SSMS.'}
$config=Get-Content -LiteralPath $ruta -Raw|ConvertFrom-Json
$cs=[Data.SqlClient.SqlConnectionStringBuilder]::new($config.ConnectionStrings.MagisAuto)
$c=[Data.SqlClient.SqlConnection]::new($cs.ConnectionString)
try{
 $c.Open()
 $cmd=$c.CreateCommand();$cmd.CommandText='SELECT DB_NAME()'
 if([string]$cmd.ExecuteScalar() -cne $cs.InitialCatalog){throw 'La base conectada no coincide con la configuracion.'}
 Write-Output "Conexion correcta a la base local: $($cs.InitialCatalog)"
 $cmd.Dispose();$cmd=$c.CreateCommand();$cmd.CommandType=[Data.CommandType]::StoredProcedure;$cmd.CommandText='api.Marca_Listar'
 $reader=$cmd.ExecuteReader();$n=0;while($reader.Read()){$n++};$reader.Close();$cmd.Dispose()
 Write-Output "Procedimiento de marcas correcto: $n registros."
 $cmd=$c.CreateCommand();$cmd.CommandType=[Data.CommandType]::StoredProcedure;$cmd.CommandText='api.Reporte06_EstadoCuenta'
 [void]$cmd.Parameters.Add('@CodigoDeudor',[Data.SqlDbType]::Int);$cmd.Parameters['@CodigoDeudor'].Value=6
 [void]$cmd.Parameters.Add('@FechaCorte',[Data.SqlDbType]::Date);$cmd.Parameters['@FechaCorte'].Value=[datetime]'2026-10-13'
 $reader=$cmd.ExecuteReader();$sets=0;$counts=@();do{$n=0;while($reader.Read()){$n++};$counts+=,$n;$sets++}while($reader.NextResult());$reader.Close();$cmd.Dispose()
 if($sets -ne 3 -or ($counts -join ',') -ne '1,12,3'){throw 'La conexion funciona, pero los datos no coinciden con la fotografia inicial (1 credito, 12 cuotas, 3 pagos).'}
 Write-Output 'Copia inicial confirmada: 1 credito, 12 cuotas y 3 recibos. Abre Visual Studio con perfil http.'
}catch{
 # No propagar mensajes que pudieran contener informacion de conexion.
 Write-Error 'No se completo la comprobacion. Revisa servidor, base, cuenta habilitada, modo mixto y copia instalada. No compartas tu archivo de conexion.' -ErrorAction Continue
 exit 1
}finally{$c.Dispose();$config=$null;$cs.Clear()}
