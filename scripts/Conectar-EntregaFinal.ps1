# Cambia solo la base del archivo privado, despues de comprobar acceso y datos.
# No imprime la cadena de conexion ni modifica servidores, usuarios o claves.
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$file=Join-Path $repo 'src/MAGISAUTO.API/appsettings.Local.json'
$local=Get-Content -LiteralPath $file -Raw|ConvertFrom-Json
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto)
$builder['Initial Catalog']='MAGISAUTO_Entrega_Final'
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try{
 try{$connection.Open()}catch{throw 'Todavia no hay acceso a MAGISAUTO_Entrega_Final. Ejecute primero el archivo administrativo preparado; la configuracion no fue cambiada.'}
 $cmd=$connection.CreateCommand();$cmd.CommandText='api.Credito_Buscar';$cmd.CommandType=[Data.CommandType]::StoredProcedure
 [void]$cmd.Parameters.AddWithValue('@Criterio','MGA-2026-')
 $table=[Data.DataTable]::new();$table.Load($cmd.ExecuteReader());$cmd.Dispose()
 foreach($n in 1..6){$code='MGA-2026-{0:D3}' -f $n;if(-not ($table.Rows|Where-Object NumeroCredito -eq $code)){throw "Falta $code; no se cambio la configuracion."}}
 $backup=Join-Path $repo ('artifacts/acceso-local/conexion-anterior-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'.json')
 [void](New-Item -ItemType Directory -Force (Split-Path $backup -Parent))
 Copy-Item -LiteralPath $file -Destination $backup
 $local.ConnectionStrings.MagisAuto=$builder.ConnectionString
 $temp=$file+'.tmp';$local|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $temp -Encoding utf8
 Move-Item -LiteralPath $temp -Destination $file -Force
 Write-Output 'Conexion verificada y configurada: MAGISAUTO_Entrega_Final. Reinicie la aplicacion.'
}finally{$connection.Dispose();$builder.Clear();$local=$null}
