# Requiere PowerShell 7. Solo modifica registros temporales creados por este ensayo.
param([string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-agencias'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la API.'}
$pruebas=[Collections.Generic.List[object]]::new()
$proceso=$null;$creada=$false;$persona=$null;$vendedor=$null;$estado='Fallido'
$codigo=$null
$nombre="Ensayo automático $([Guid]::NewGuid().ToString('N').Substring(0,10))"
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
function Procedimiento([string]$nombreProc,[hashtable]$parametros){
 $local=Get-Content -LiteralPath (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cn=[Data.SqlClient.SqlConnection]::new($local.ConnectionStrings.MagisAuto)
 try{
  $cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandType=[Data.CommandType]::StoredProcedure
  $cmd.CommandText=$nombreProc
  foreach($clave in $parametros.Keys){[void]$cmd.Parameters.AddWithValue("@$clave",$parametros[$clave])}
  $cmd.ExecuteScalar()
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
 $base='/api/catalogos/agencias'
 $inicial=Peticion GET $base
 Comprobar 'Catálogo de agencias accesible' ($inicial.Codigo -eq 200)
 $r=Peticion GET '/agencias.html'
 Comprobar 'Pantalla de agencias servida' ($r.Codigo -eq 200 -and $r.Texto.Contains('Región') -and $r.Texto.Contains('Código automático'))
 foreach($archivo in @('/estilos.css','/agencias.js')){$r=Peticion GET $archivo;Comprobar "Recurso disponible: $archivo" ($r.Codigo -eq 200)}
 foreach($pagina in @('/','/lineas.html')){$r=Peticion GET $pagina;Comprobar "Navegación a agencias desde $pagina" ($r.Codigo -eq 200 -and $r.Texto.Contains('/agencias.html'))}
 $r=Peticion POST $base @{nombre="  $nombre  ";region='  Oriente  '}
 if($r.Codigo -eq 201){$creada=$true;$codigo=$r.Json.codigoAgencia}
 Comprobar 'SQL asigna código y API recorta nombre y región' ($r.Codigo -eq 201 -and $codigo -gt 0 -and $r.Json.nombre -ceq $nombre -and $r.Json.region -ceq 'Oriente')
 $r=Peticion GET "${base}?criterio=$codigo"
 Comprobar 'Agencia nueva persistida' (@($r.Json|Where-Object codigoAgencia -eq $codigo).Count -eq 1)
 foreach($campo in @('nombre','region')){
  foreach($valor in @('', '   ', ('x'*129))){
   $datos=@{nombre=$nombre;region='Oriente'};$datos[$campo]=$valor
   $r=Peticion PUT "$base/$codigo" $datos
   Comprobar "$campo inválido con longitud $($valor.Length) rechazado" ($r.Codigo -eq 400)
  }
  $datos=@{nombre=$nombre;region='Oriente'};$datos.Remove($campo)
  $r=Peticion POST $base $datos
  Comprobar "$campo ausente rechazado" ($r.Codigo -eq 400)
 }
 foreach($criterio in @('', '   ', ('x'*201))){
  $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($criterio))"
  Comprobar "Filtro inválido con longitud $($criterio.Length) rechazado" ($r.Codigo -eq 400)
 }
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString("' OR 1=1--"))"
 Comprobar 'Texto de inyección tratado como criterio de búsqueda' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 $nuevo="$nombre ñ <b>texto</b>";$region="Región $([Guid]::NewGuid().ToString('N').Substring(0,10))"
 $r=Peticion PUT "$base/$codigo" @{nombre=$nuevo;region=$region}
 Comprobar 'Editar conserva código y actualiza ambos campos' ($r.Codigo -eq 200 -and $r.Json.codigoAgencia -eq $codigo -and $r.Json.nombre -ceq $nuevo -and $r.Json.region -ceq $region)
 foreach($criterio in @($nuevo,$region)){
  $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($criterio))"
  Comprobar "Buscar por dato editado: $criterio" ($r.Codigo -eq 200 -and @($r.Json).Count -eq 1 -and $r.Json[0].codigoAgencia -eq $codigo)
 }
 $dpi='999'+(Get-Random -Minimum 1000000000L -Maximum 9999999999L).ToString()
 $persona=Procedimiento 'api.Persona_Insertar' @{DPI=$dpi;PrimerNombre='Ensayo';PrimerApellido='Agencias'}
 $vendedor=Procedimiento 'api.Vendedor_Insertar' @{CodigoEmpleado=('ENS-'+[Guid]::NewGuid().ToString('N').Substring(0,20));CodigoPersona=[int]$persona;CodigoAgencia=[int]$codigo}
 $r=Peticion DELETE "$base/$codigo"
 Comprobar 'Agencia vinculada a vendedor devuelve 409 sin detalles SQL' ($r.Codigo -eq 409 -and $r.Json.detail -match 'vendedores' -and $r.Texto -notmatch 'SqlException|REFERENCE|FK_')
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($region))"
 Comprobar 'Borrado bloqueado conserva los datos' (@($r.Json).Count -eq 1 -and $r.Json[0].nombre -ceq $nuevo)
 [void](Procedimiento 'api.Vendedor_Eliminar' @{CodigoVendedor=[int]$vendedor});$vendedor=$null
 [void](Procedimiento 'api.Persona_Eliminar' @{CodigoPersona=[int]$persona});$persona=$null
 $r=Peticion DELETE "$base/$codigo"
 if($r.Codigo -eq 204){$creada=$false}
 Comprobar 'Agencia sin relaciones se elimina' ($r.Codigo -eq 204 -and $r.Texto.Length -eq 0)
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($region))"
 Comprobar 'La agencia eliminada ya no aparece' (@($r.Json).Count -eq 0)
 $r=Peticion DELETE "$base/$codigo"
 Comprobar 'Eliminar inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion PUT "$base/$codigo" @{nombre=$nombre;region='Oriente'}
 Comprobar 'Editar inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion DELETE "$base/0"
 Comprobar 'Código cero rechazado' ($r.Codigo -eq 400)
 $r=Peticion PUT "$base/-1" @{nombre=$nombre;region='Oriente'}
 Comprobar 'Código negativo rechazado' ($r.Codigo -eq 400)
 $r=Peticion GET '/openapi/v1.json'
 Comprobar 'OpenAPI documenta las cuatro operaciones' ($null -ne $r.Json.paths.$base.get -and $null -ne $r.Json.paths.$base.post -and $null -ne $r.Json.paths."$base/{codigo}".put -and $null -ne $r.Json.paths."$base/{codigo}".delete)
 $final=Peticion GET $base
 Comprobar 'Catálogo inicial conservado' (($inicial.Json|ConvertTo-Json -Compress) -ceq ($final.Json|ConvertTo-Json -Compress))
 $estado='Correcto'
}finally{
 try{
  if($vendedor){[void](Procedimiento 'api.Vendedor_Eliminar' @{CodigoVendedor=[int]$vendedor})}
  if($persona){[void](Procedimiento 'api.Persona_Eliminar' @{CodigoPersona=[int]$persona})}
  if($creada){$limpieza=Peticion DELETE "/api/catalogos/agencias/$codigo";if($limpieza.Codigo -ne 204){throw "Revisar agencia temporal ${codigo}: limpieza pendiente."}}
 }finally{
  if($null -ne $proceso){if(-not $proceso.HasExited){Stop-Process -Id $proceso.Id;$proceso.WaitForExit()};$proceso.Dispose()}
  [pscustomobject]@{Estado=$estado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 }
}
Write-Output "Comprobaciones correctas: $($pruebas.Count). Registros temporales retirados; los correlativos pueden tener saltos."
