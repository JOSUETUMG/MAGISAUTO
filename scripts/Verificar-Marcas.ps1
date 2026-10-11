# Requiere PowerShell 7. Solo modifica registros temporales creados por este ensayo.
param([string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-marcas'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la API.'}
$pruebas=[Collections.Generic.List[object]]::new()
$proceso=$null;$creada=$false;$lineaCreada=$false;$estado='Fallido'
$codigo=Get-Random -Minimum 100000000 -Maximum 2000000000
$marca="Ensayo automático $([Guid]::NewGuid().ToString('N').Substring(0,10))"
$tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
$tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop()
$url="http://127.0.0.1:$puerto"
function Comprobar([string]$nombre,[bool]$bien){
 if(-not $bien){throw "Falló: $nombre"}
 $pruebas.Add([pscustomobject]@{Prueba=$nombre;Resultado='Correcto'})
}
function Peticion([string]$metodo,[string]$ruta,[object]$datos=$null){
 $p=@{Uri="$url$ruta";Method=$metodo;NoProxy=$true;SkipHttpErrorCheck=$true;TimeoutSec=15}
 if($null -ne $datos){$p.ContentType='application/json; charset=utf-8';$p.Body=($datos|ConvertTo-Json -Compress)}
 $r=Invoke-WebRequest @p
 $texto=if($r.Content -is [byte[]]){[Text.Encoding]::UTF8.GetString($r.Content)}else{[string]$r.Content}
 $json=if($texto -and $r.Headers.'Content-Type' -match 'json'){$texto|ConvertFrom-Json}else{$null}
 [pscustomobject]@{Codigo=[int]$r.StatusCode;Texto=$texto;Json=$json}
}
function Linea([string]$procedimiento){
 # Preparación de una relación de prueba, por procedimiento y con la misma cuenta limitada.
 $local=Get-Content -LiteralPath (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cn=[Data.SqlClient.SqlConnection]::new($local.ConnectionStrings.MagisAuto)
 try{
  $cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandType=[Data.CommandType]::StoredProcedure
  $cmd.CommandText=$procedimiento
  [void]$cmd.Parameters.Add('@CodigoMarca',[Data.SqlDbType]::Int);$cmd.Parameters['@CodigoMarca'].Value=$codigo
  [void]$cmd.Parameters.Add('@CodigoLinea',[Data.SqlDbType]::Int);$cmd.Parameters['@CodigoLinea'].Value=1
  if($procedimiento -eq 'api.Linea_Insertar'){
   [void]$cmd.Parameters.Add('@Descripcion',[Data.SqlDbType]::NVarChar,128);$cmd.Parameters['@Descripcion'].Value=$marca
  }
  [void]$cmd.ExecuteNonQuery()
 }finally{$cn.Dispose();$local=$null}
}
try{
 $vars=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto');$antes=@{}
 foreach($v in $vars){$antes[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{
  $env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development'
  Remove-Item Env:ConnectionStrings__MagisAuto -ErrorAction SilentlyContinue
  $proceso=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')
 }finally{
  foreach($v in $vars){if($null -eq $antes[$v]){Remove-Item "Env:$v" -ErrorAction SilentlyContinue}else{[Environment]::SetEnvironmentVariable($v,$antes[$v],'Process')}}
 }
 $iniciado=$false
 for($i=0;$i -lt 50;$i++){
  try{$r=Peticion GET '/api/salud';if($r.Codigo -eq 200){$iniciado=$true;break}}catch{}
  Start-Sleep -Milliseconds 150
 }
 Comprobar 'Servidor de ensayo disponible' $iniciado
 $base='/api/catalogos/marcas'
 $inicial=Peticion GET $base
 Comprobar 'Catálogo accesible' ($inicial.Codigo -eq 200)
 Comprobar 'Código temporal no pertenece a una marca existente' ($codigo -notin @($inicial.Json.codigoMarca))
 $r=Peticion GET '/'
 Comprobar 'Página de marcas servida desde la API' ($r.Codigo -eq 200 -and $r.Texto.Contains('Marcas de vehículos'))
 foreach($archivo in @('/estilos.css','/marcas.js')){$r=Peticion GET $archivo;Comprobar "Recurso disponible: $archivo" ($r.Codigo -eq 200)}
 $r=Peticion POST $base @{codigoMarca=$codigo;descripcion="  $marca  "}
 if($r.Codigo -eq 201){$creada=$true}
 Comprobar 'Crear marca y recortar espacios' ($r.Codigo -eq 201 -and $r.Json.descripcion -ceq $marca -and $r.Json.codigoMarca -eq $codigo)
 $r=Peticion GET "${base}?criterio=$codigo"
 Comprobar 'Marca creada persistida y buscable por código' (@($r.Json).Count -eq 1 -and $r.Json[0].descripcion -ceq $marca)
 $r=Peticion POST $base @{codigoMarca=$codigo;descripcion='No debe reemplazar la marca'}
 Comprobar 'Código duplicado devuelve conflicto claro' ($r.Codigo -eq 409 -and $r.Json.detail -match 'código' -and $r.Texto -notmatch 'SqlException|PK_Marca')
 foreach($nombre in @('', '   ', ('x'*129))){
  $r=Peticion PUT "$base/$codigo" @{descripcion=$nombre}
  Comprobar "Nombre inválido de longitud $($nombre.Length) rechazado" ($r.Codigo -eq 400)
 }
 $r=Peticion POST $base @{codigoMarca=0;descripcion=$marca}
 Comprobar 'Código cero rechazado' ($r.Codigo -eq 400)
 $r=Peticion POST $base @{codigoMarca=1.5;descripcion=$marca}
 Comprobar 'Código decimal rechazado' ($r.Codigo -eq 400)
 $r=Peticion POST $base @{codigoMarca=2147483648;descripcion=$marca}
 Comprobar 'Código fuera del rango entero rechazado' ($r.Codigo -eq 400)
 $r=Peticion PUT "$base/$codigo" @{}
 Comprobar 'Nombre ausente rechazado' ($r.Codigo -eq 400)
 $r=Peticion GET "${base}?criterio=$codigo"
 Comprobar 'Errores no alteraron la marca' ($r.Json[0].descripcion -ceq $marca)
 $nuevo="$marca editado ñ <b>texto</b>"
 $r=Peticion PUT "$base/$codigo" @{descripcion=$nuevo}
 Comprobar 'Editar marca conserva código' ($r.Codigo -eq 200 -and $r.Json.codigoMarca -eq $codigo -and $r.Json.descripcion -ceq $nuevo)
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($nuevo))"
 Comprobar 'Edición persistida y Unicode conservado' (@($r.Json).Count -eq 1 -and $r.Json[0].descripcion -ceq $nuevo)
 Linea 'api.Linea_Insertar';$lineaCreada=$true
 $r=Peticion DELETE "$base/$codigo"
 Comprobar 'Marca con línea asociada devuelve 409' ($r.Codigo -eq 409 -and $r.Json.detail -match 'líneas asociadas' -and $r.Texto -notmatch 'REFERENCE|SqlException')
 $r=Peticion GET "${base}?criterio=$codigo"
 Comprobar 'Borrado bloqueado conserva la marca' (@($r.Json).Count -eq 1)
 Linea 'api.Linea_Eliminar';$lineaCreada=$false
 $r=Peticion DELETE "$base/$codigo"
 if($r.Codigo -eq 204){$creada=$false}
 Comprobar 'Eliminar marca sin relaciones devuelve 204' ($r.Codigo -eq 204 -and $r.Texto.Length -eq 0)
 $r=Peticion GET "${base}?criterio=$codigo"
 Comprobar 'Marca eliminada ya no aparece' (@($r.Json).Count -eq 0)
 $r=Peticion DELETE "$base/$codigo"
 Comprobar 'Eliminar una marca inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion PUT "$base/$codigo" @{descripcion=$marca}
 Comprobar 'Editar una marca inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion DELETE "$base/0"
 Comprobar 'Eliminar con código inválido devuelve 400' ($r.Codigo -eq 400)
 $r=Peticion GET '/openapi/v1.json'
 Comprobar 'OpenAPI incluye crear, editar y eliminar' ($null -ne $r.Json.paths.$base.post -and $null -ne $r.Json.paths."$base/{codigo}".put -and $null -ne $r.Json.paths."$base/{codigo}".delete)
 $final=Peticion GET $base
 Comprobar 'Catálogo original conservado después del ensayo' (($inicial.Json|ConvertTo-Json -Compress) -ceq ($final.Json|ConvertTo-Json -Compress))
 $estado='Correcto'
}finally{
 try{
  if($lineaCreada){Linea 'api.Linea_Eliminar'}
  if($creada){$limpieza=Peticion DELETE "/api/catalogos/marcas/$codigo";if($limpieza.Codigo -ne 204){throw "Revisar marca temporal ${codigo}: limpieza pendiente."}}
 }finally{
  if($null -ne $proceso){if(-not $proceso.HasExited){Stop-Process -Id $proceso.Id;$proceso.WaitForExit()};$proceso.Dispose()}
  [pscustomobject]@{Estado=$estado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 }
}
Write-Output "Comprobaciones correctas: $($pruebas.Count). Registros temporales retirados."
