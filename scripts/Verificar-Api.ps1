param([string]$CredencialSoloLectura, [string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-api'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la solución.'}
$resultados=[Collections.Generic.List[object]]::new()
$script:numero=0
$script:proceso=$null
$script:url=$null

function Iniciar([string]$nombre,[string]$cadena,[bool]$sobrescribir){
 $script:numero++
 $tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
 $tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop()
 $script:url="http://127.0.0.1:$puerto"
 $variables=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto')
 $anteriores=@{}
 foreach($v in $variables){$anteriores[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{
  [Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT','Development','Process')
  [Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT','Development','Process')
  if($sobrescribir){[Environment]::SetEnvironmentVariable('ConnectionStrings__MagisAuto',$cadena,'Process')}
  else{Remove-Item -LiteralPath Env:ConnectionStrings__MagisAuto -ErrorAction SilentlyContinue}
  $script:proceso=Start-Process -FilePath 'dotnet' -ArgumentList @(('"'+$dll+'"'),'--urls',$script:url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida "$($script:numero)-salida.log") -RedirectStandardError (Join-Path $salida "$($script:numero)-error.log")
 }finally{
  foreach($v in $variables){
   if($null -eq $anteriores[$v]){Remove-Item -LiteralPath "Env:$v" -ErrorAction SilentlyContinue}
   else{[Environment]::SetEnvironmentVariable($v,$anteriores[$v],'Process')}
  }
 }
 $ultimoError='Sin respuesta HTTP'
 for($i=0;$i -lt 50;$i++){
  if($script:proceso.HasExited){throw "La API se cerró al iniciar el escenario $nombre."}
  try{$r=Invoke-WebRequest -Uri "$script:url/api/salud" -UseBasicParsing -NoProxy -TimeoutSec 2;if($r.StatusCode -eq 200){return}}catch{$ultimoError=$_.Exception.Message}
  Start-Sleep -Milliseconds 150
 }
 throw "No se pudo comprobar el inicio en $nombre. $ultimoError"
}
function Detener{
 if($null -ne $script:proceso){
  if(-not $script:proceso.HasExited){Stop-Process -Id $script:proceso.Id; $script:proceso.WaitForExit()}
  $script:proceso.Dispose();$script:proceso=$null
 }
}
function Consultar([string]$ruta){
 # PowerShell 7 conserva también respuestas 400/503 para verificar ProblemDetails.
 $respuesta=Invoke-WebRequest -Uri "$script:url$ruta" -SkipHttpErrorCheck -NoProxy -TimeoutSec 15
 $texto=if($respuesta.Content -is [byte[]]){[Text.Encoding]::UTF8.GetString($respuesta.Content)}else{[string]$respuesta.Content}
 return [pscustomobject]@{Codigo=[int]$respuesta.StatusCode;Texto=$texto;Json=($texto|ConvertFrom-Json)}
}
function Afirmar([string]$nombre,[bool]$condicion){
 if(-not $condicion){throw "Comprobación fallida: $nombre"}
 $resultados.Add([pscustomobject]@{Prueba=$nombre;Resultado='Correcto'})
}
function RevisarError([string]$nombre){
 $r=Consultar '/api/catalogos/marcas'
 Afirmar "$nombre devuelve 503" ($r.Codigo -eq 503 -and $r.Json.status -eq 503 -and -not [string]::IsNullOrWhiteSpace($r.Json.traceId))
 Afirmar "$nombre no expone credenciales ni detalles internos" ($r.Texto -notmatch 'SqlException|StackTrace|Password|privado-ensayo|magis_api_diego|codex_lectura|127\.0\.0\.1')
 $s=Consultar '/api/salud'
 Afirmar "$nombre mantiene activa la API" ($s.Codigo -eq 200 -and $s.Json.estado -eq 'Disponible')
 $b=Consultar '/api/salud/base-datos'
 Afirmar "$nombre también falla en salud de base de datos" ($b.Codigo -eq 503)
}
try{
 Iniciar 'conexión real' '' $false
 $r=Consultar '/api/salud'
 Afirmar 'Salud de API disponible' ($r.Codigo -eq 200 -and $r.Json.aplicacion -eq 'MAGISAUTO.API')
 $r=Consultar '/api/salud/base-datos'
 Afirmar 'Consulta real de base de datos disponible' ($r.Codigo -eq 200 -and $r.Json.estado -eq 'Disponible')
 $r=Consultar '/api/catalogos/marcas'
 Afirmar 'Cinco marcas reales en orden' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 5 -and (@($r.Json.descripcion)-join ',') -ceq 'Toyota,Hyundai,Kia,Nissan,Suzuki')
 Afirmar 'Contrato JSON de marcas sin columnas internas adicionales' (((@($r.Json[0].PSObject.Properties.Name)|Sort-Object)-join ',') -eq 'codigoMarca,descripcion')
 $r=Consultar '/api/catalogos/marcas?criterio=Toyota'
 Afirmar 'Buscar por descripción' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 1 -and $r.Json[0].codigoMarca -eq 1)
 $r=Consultar '/api/catalogos/marcas?criterio=2'
 Afirmar 'Buscar por código' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 1 -and $r.Json[0].descripcion -eq 'Hyundai')
 $r=Consultar '/api/catalogos/marcas?criterio=%20Toyota%20'
 Afirmar 'Recortar espacios del criterio' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 1)
 $r=Consultar '/api/catalogos/marcas?criterio=sin-coincidencias-ensayo'
 Afirmar 'Sin coincidencias devuelve lista vacía' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 foreach($v in @('', '%20%20', ('x'*201))){
  $r=Consultar "/api/catalogos/marcas?criterio=$v"
  if($r.Codigo -ne 400 -or $r.Json.status -ne 400){throw "Criterio inválido: longitud=$($v.Length), HTTP=$($r.Codigo), estado JSON=$($r.Json.status)."}
  Afirmar "Criterio inválido de longitud $($v.Length) devuelve 400" $true
 }
 $criterio=[Uri]::EscapeDataString("Toyota' OR '1'='1")
 $r=Consultar "/api/catalogos/marcas?criterio=$criterio"
 Afirmar 'Caracteres SQL se tratan como parámetro de búsqueda' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 $r=Consultar '/openapi/v1.json'
 Afirmar 'OpenAPI documenta las rutas y errores' ($r.Codigo -eq 200 -and $null -ne $r.Json.paths.'/api/catalogos/marcas'.get.responses.'503' -and $null -ne $r.Json.paths.'/api/salud/base-datos')
 Detener

 Iniciar 'configuración ausente' ' ' $true
 RevisarError 'Configuración ausente'
 Detener
 Iniciar 'configuración inválida' 'NoEsUnaClave=privado-ensayo;' $true
 RevisarError 'Configuración inválida'
 Detener
 Iniciar 'servidor inaccesible' 'Server=tcp:127.0.0.1,1;Database=MAGISAUTO_Proyecto_V2;User ID=ensayo;Password=privado-ensayo;Encrypt=True;TrustServerCertificate=True;Connect Timeout=1' $true
 RevisarError 'Servidor inaccesible'
 Detener

 if($CredencialSoloLectura){
  $cred=Import-Clixml -LiteralPath $CredencialSoloLectura
  $b=[Data.SqlClient.SqlConnectionStringBuilder]::new()
  $b['Data Source']='tcp:127.0.0.1,1433';$b['Initial Catalog']='MAGISAUTO_Proyecto_V2'
  $b['User ID']=$cred.UserName;$b['Password']=$cred.GetNetworkCredential().Password
  $b['Encrypt']=$true;$b['TrustServerCertificate']=$true;$b['Connect Timeout']=3
  Iniciar 'cuenta sin permiso de procedimientos' $b.ConnectionString $true
  $b.Clear()
  RevisarError 'Permiso de procedimientos insuficiente'
  Detener
 }

 # Diagnóstico administrativo del usuario de aplicación; no es una operación de la API.
 $local=Get-Content -LiteralPath (Join-Path $api 'appsettings.Local.json') -Raw | ConvertFrom-Json
 $conexion=[Data.SqlClient.SqlConnection]::new($local.ConnectionStrings.MagisAuto)
 try{
  $conexion.Open();$c=$conexion.CreateCommand()
  $c.CommandText="SELECT CASE WHEN IS_SRVROLEMEMBER('sysadmin')=0 AND IS_MEMBER('db_owner')=0 AND HAS_PERMS_BY_NAME('api','SCHEMA','EXECUTE')=1 AND HAS_PERMS_BY_NAME('dbo','SCHEMA','SELECT')=0 AND HAS_PERMS_BY_NAME('dbo','SCHEMA','INSERT')=0 AND HAS_PERMS_BY_NAME('dbo','SCHEMA','UPDATE')=0 AND HAS_PERMS_BY_NAME('dbo','SCHEMA','DELETE')=0 THEN 1 ELSE 0 END;"
  Afirmar 'Cuenta limitada a procedimientos, sin administración ni acceso directo a tablas' ([int]$c.ExecuteScalar() -eq 1)
  $c.CommandText='SELECT COUNT(*) FROM dbo.Marca;'
  $denegado=$false
  try{[void]$c.ExecuteScalar()}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq 229){$denegado=$true}else{throw}}
  Afirmar 'Lectura directa de tabla rechazada por SQL Server' $denegado
 }finally{$conexion.Dispose()}
 $local=$null
 [pscustomobject]@{Estado='Correcto';Fecha=(Get-Date -Format o);Pruebas=$resultados}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 Write-Output "Comprobaciones correctas: $($resultados.Count). No se modificaron datos de negocio."
}catch{
 [pscustomobject]@{Estado='Fallido';Pruebas=$resultados;Error=$_.Exception.Message}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 throw
}finally{Detener}
