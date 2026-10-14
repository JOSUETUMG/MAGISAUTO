# Verificacion reproducible del paquete en el destino aislado instalado por el administrador.
# No modifica la configuracion local ni escribe datos de negocio en la fuente.
param(
 [Parameter(Mandatory=$true)][string]$Credencial,
 [string]$SalidaCompilacion='artifacts/build-publicacion',
 [switch]$ConexionLocalSinCifrado
)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src/MAGISAUTO.API'
$base='MAGISAUTO_EnsayoEquipo_20261013'
$checks=[Collections.Generic.List[object]]::new();$process=$null;$c=$null
function Check([string]$name,[bool]$ok){if(-not $ok){throw "Fallo de verificacion: $name"};$checks.Add([pscustomobject]@{Prueba=$name;Resultado='Correcto'})}
try{
 $cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
 $c=[Data.SqlClient.SqlConnection]::new("Server=tcp:127.0.0.1,1433;Database=$base;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8",[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
 $c.Open()
 function Query([string]$sql){$cmd=$c.CreateCommand();$cmd.CommandTimeout=45;$cmd.CommandText=$sql;$ds=[Data.DataSet]::new();$da=[Data.SqlClient.SqlDataAdapter]::new($cmd);try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}}
 Check 'Destino aislado confirmado' ((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -ceq $base)
 $manifest=Get-Content (Join-Path $repo 'database/equipo/manifest.json') -Raw|ConvertFrom-Json
 foreach($prop in $manifest.tablas.PSObject.Properties){$name=$prop.Name;Check "Conteo de $name" ((Query "SELECT COUNT(*) FROM dbo.[$name]").Tables[0].Rows[0][0] -eq $prop.Value)}
 Check '151 procedimientos, 4 vistas y 2 funciones' ((Query "SELECT COUNT(*) FROM sys.sql_modules").Tables[0].Rows[0][0] -eq 157)
 Check 'Restricciones activas y confiables' ((Query 'SELECT (SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1)+(SELECT COUNT(*) FROM sys.check_constraints WHERE is_disabled=1 OR is_not_trusted=1)').Tables[0].Rows[0][0] -eq 0)
 $cc=Query 'DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS, NO_INFOMSGS;'
 Check 'Datos cumplen las restricciones' (($cc.Tables|ForEach-Object{$_.Rows.Count}|Measure-Object -Sum).Sum -eq 0)
 # Probar el siguiente recibo en la copia. La secuencia se restaura al inicio 4 sin crear pagos.
 try{Check 'Siguiente recibo es 4' ((Query 'SELECT NEXT VALUE FOR dbo.SecComprobante').Tables[0].Rows[0][0] -eq 4)}finally{[void](Query 'ALTER SEQUENCE dbo.SecComprobante RESTART WITH 4;')}
 $local=Get-Content (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cs=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto);$cs['Initial Catalog']=$base
 if($ConexionLocalSinCifrado){if($cs.DataSource -ne 'tcp:127.0.0.1,1433'){throw 'Opcion sin TLS permitida solo en loopback.'};$cs['Encrypt']=$false}
 $limited=[Data.SqlClient.SqlConnection]::new($cs.ConnectionString)
 try{$limited.Open();$cmd=$limited.CreateCommand();$cmd.CommandText='SELECT * FROM dbo.Credito';$denied=$false;try{[void]$cmd.ExecuteScalar()}catch [Data.SqlClient.SqlException]{$denied=$_.Exception.Number -eq 229};Check 'Cuenta API sin SELECT directo en tablas' $denied}finally{$limited.Dispose()}
 $tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$tcp.Start();$port=$tcp.LocalEndpoint.Port;$tcp.Stop();$url="http://127.0.0.1:$port"
 $log=Join-Path $repo 'artifacts/verificacion-equipo';[void](New-Item -ItemType Directory -Force $log)
 $saved=@{};$vars=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto')
 foreach($v in $vars){$saved[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{
  $env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development';$env:ConnectionStrings__MagisAuto=$cs.ConnectionString
  $dll=Join-Path $repo "$SalidaCompilacion/MAGISAUTO.API.dll"
  $process=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $log 'servidor.log') -RedirectStandardError (Join-Path $log 'error.log')
 }finally{foreach($v in $vars){[Environment]::SetEnvironmentVariable($v,$saved[$v],'Process')};$local=$null;$cs.Clear()}
 function Get([string]$path){Invoke-RestMethod -Uri "$url$path" -NoProxy -TimeoutSec 30}
 $ready=$false;for($i=0;$i -lt 40;$i++){try{$null=Get '/api/salud';$ready=$true;break}catch{Start-Sleep -Milliseconds 250}}
 Check 'API temporal disponible' $ready
 $null=Get '/api/salud/base-datos';Check 'API conecta con la copia mediante SP' $true
 $catalog=Get '/api/reportes';Check 'Catalogo de 20 consultas' ($catalog.reportes.Count -eq 20)
 foreach($report in $catalog.reportes){
  $pairs=@();foreach($f in $report.filtros){$value=switch($f.nombre){'desde'{'2026-10-12'} 'hasta'{'2026-10-13'} 'fechaCorte'{'2026-10-13'} 'diasMinimos'{'1'} 'dias'{'30'} 'mes'{'8'} 'anio'{'2026'} 'codigoDeudor'{'6'} 'numeroCredito'{'PRUEBA-CREDITO-01'} default{throw "Filtro no previsto: $($f.nombre)"}};$pairs+="$($f.nombre)=$value"}
  $result=Get ("/api/reportes/$($report.id)?"+($pairs -join '&'))
  Check "Reporte $($report.id) responde desde la copia" ($result.id -eq $report.id -and $result.tablas.Count -gt 0)
  if($report.id -eq 6){$serialized=$result|ConvertTo-Json -Depth 20 -Compress;Check 'Estado de cuenta: tres secciones y saldos iniciales' ($result.tablas.Count -eq 3 -and $serialized.Contains('86239.56') -and $serialized.Contains('78708.91') -and $serialized.Contains('1500.00'))}
  if($report.id -eq 19){$serialized=$result|ConvertTo-Json -Depth 20 -Compress;Check 'Recaudacion neta Q1500 y capital Q1291.09' ($serialized.Contains('1500.00') -and $serialized.Contains('1291.09'))}
 }
 foreach($path in @('/','/pagos.html','/reportes.html')){$response=Invoke-WebRequest "$url$path" -NoProxy;Check "Pantalla $path disponible" ($response.StatusCode -eq 200)}
 $output=@{Estado='Correcto';Fecha=[DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(-6)).ToString('o');BaseEnsayo=$base;ScriptSha256=$manifest.sha256;Comprobaciones=$checks;Limitaciones=@('Instalacion administrativa realizada por Diego en SSMS; la cuenta de revision no puede crear bases.','La prueba automatizada usa la cuenta API existente mapeada SOLO en el ensayo. No certifica una computadora distinta.','Si se indico ConexionLocalSinCifrado: solo loopback aislado por limitacion TLS del proceso de ensayo; los archivos entregados conservan Encrypt=True.')}
 $output|ConvertTo-Json -Depth 8|Set-Content (Join-Path $repo 'docs/evidencias/paquete-equipo.json') -Encoding utf8
 Write-Output "Paquete del equipo: $($checks.Count) comprobaciones correctas."
}finally{if($process -and -not $process.HasExited){Stop-Process -Id $process.Id};if($c){$c.Dispose()}}
