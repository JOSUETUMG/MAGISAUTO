# PowerShell 7. Crea y retira únicamente sus propios registros de ensayo.
param([string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-lineas'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la API.'}
$pruebas=[Collections.Generic.List[object]]::new()
$marcasCreadas=[Collections.Generic.List[int]]::new()
$lineasCreadas=[Collections.Generic.List[int]]::new()
$proceso=$null;$garantia=$null;$estado='Fallido'
$codigo=Get-Random -Minimum 100000000 -Maximum 900000000
$otra=$codigo+1;$inexistente=$codigo+2
$nombre="Ensayo líneas $([Guid]::NewGuid().ToString('N').Substring(0,10))"
$tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
$tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop();$url="http://127.0.0.1:$puerto"
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
function Vehiculo([Nullable[int]]$id){
 # Solo fixture de prueba: procedimientos y cuenta limitada de la aplicación.
 $config=Get-Content -LiteralPath (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cn=[Data.SqlClient.SqlConnection]::new($config.ConnectionStrings.MagisAuto)
 try{
  $cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandType=[Data.CommandType]::StoredProcedure
  if($null -ne $id){
   $cmd.CommandText='api.Garantia_Eliminar'
   $cmd.Parameters.Add('@CodigoGarantia',[Data.SqlDbType]::Int).Value=$id
   [void]$cmd.ExecuteNonQuery()
  }else{
   $cmd.CommandText='api.TipoGarantia_Listar';$tipo=$cmd.ExecuteScalar()
   if($null -eq $tipo){throw 'Se requiere un tipo de garantía existente para la prueba.'}
   $cmd.CommandText='api.Garantia_Insertar'
   $cmd.Parameters.Add('@VIN',[Data.SqlDbType]::VarChar,17).Value=('T'+[Guid]::NewGuid().ToString('N').Substring(0,16).ToUpperInvariant())
   $cmd.Parameters.Add('@CodigoMarca',[Data.SqlDbType]::Int).Value=$codigo
   $cmd.Parameters.Add('@CodigoLinea',[Data.SqlDbType]::Int).Value=1
   $cmd.Parameters.Add('@Anio',[Data.SqlDbType]::SmallInt).Value=2026
   $p=$cmd.Parameters.Add('@ValorAgencia',[Data.SqlDbType]::Decimal);$p.Precision=18;$p.Scale=2;$p.Value=100000
   $cmd.Parameters.Add('@CodigoTipoGarantia',[Data.SqlDbType]::Int).Value=[int]$tipo
   $cmd.Parameters.Add('@EsNuevo',[Data.SqlDbType]::Bit).Value=$true
   return [int]$cmd.ExecuteScalar()
  }
 }finally{$cn.Dispose();$config=$null}
}
try{
 $variables=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto');$antes=@{}
 foreach($v in $variables){$antes[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{
  $env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development'
  Remove-Item Env:ConnectionStrings__MagisAuto -ErrorAction SilentlyContinue
  $proceso=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')
 }finally{
  foreach($v in $variables){if($null -eq $antes[$v]){Remove-Item "Env:$v" -ErrorAction SilentlyContinue}else{[Environment]::SetEnvironmentVariable($v,$antes[$v],'Process')}}
 }
 $iniciado=$false
 for($i=0;$i -lt 50;$i++){
  try{$r=Peticion GET '/api/salud';if($r.Codigo -eq 200){$iniciado=$true;break}}catch{}
  if($proceso.HasExited){break};Start-Sleep -Milliseconds 150
 }
 Comprobar 'Servidor de ensayo disponible' $iniciado
 $base='/api/catalogos/lineas';$baseMarcas='/api/catalogos/marcas'
 $inicial=Peticion GET $base;$inicialMarcas=Peticion GET $baseMarcas
 Comprobar 'Listado accesible con nombre de marca' ($inicial.Codigo -eq 200 -and @($inicial.Json).Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($inicial.Json[0].nombreMarca))
 Comprobar 'Códigos de ensayo libres' (@($inicialMarcas.Json|Where-Object {$_.codigoMarca -in @($codigo,$otra,$inexistente)}).Count -eq 0)
 foreach($pagina in @('/lineas.html','/lineas.js','/')){$r=Peticion GET $pagina;Comprobar "Recurso disponible: $pagina" ($r.Codigo -eq 200)}
 foreach($m in @($codigo,$otra)){
  $r=Peticion POST $baseMarcas @{codigoMarca=$m;descripcion="$nombre $m"}
  if($r.Codigo -eq 201){$marcasCreadas.Add($m)}
  Comprobar "Marca temporal creada: $m" ($r.Codigo -eq 201)
  $r=Peticion POST $base @{codigoMarca=$m;codigoLinea=1;descripcion="  $nombre  "}
  if($r.Codigo -eq 201){$lineasCreadas.Add($m)}
  Comprobar "Línea 1 creada bajo marca $m" ($r.Codigo -eq 201 -and $r.Json.codigoMarca -eq $m -and $r.Json.codigoLinea -eq 1 -and $r.Json.descripcion -ceq $nombre)
 }
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($nombre))"
 Comprobar 'Buscar nombre devuelve líneas homónimas de ambas marcas' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 2)
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($nombre))&codigoMarca=$codigo"
 Comprobar 'Filtro combinado devuelve solo la marca elegida' (@($r.Json).Count -eq 1 -and $r.Json[0].codigoMarca -eq $codigo -and $r.Json[0].nombreMarca -ceq "$nombre $codigo")
 $r=Peticion GET "${base}?criterio=$codigo"
 Comprobar 'Búsqueda por código de marca' (@($r.Json).Count -eq 1 -and $r.Json[0].codigoMarca -eq $codigo)
 $r=Peticion POST $base @{codigoMarca=$codigo;codigoLinea=1;descripcion='Duplicada'}
 Comprobar 'Misma marca y código devuelve 409 sin SQL interno' ($r.Codigo -eq 409 -and $r.Json.detail -match 'Ya existe' -and $r.Texto -notmatch 'PK_Linea|SqlException')
 $r=Peticion POST $base @{codigoMarca=$inexistente;codigoLinea=1;descripcion=$nombre}
 Comprobar 'Marca inexistente devuelve 409 comprensible' ($r.Codigo -eq 409 -and $r.Json.detail -match 'marca seleccionada')
 foreach($filtro in @('criterio=','criterio=%20%20',('criterio='+('x'*201)),'codigoMarca=0','codigoMarca=','codigoMarca=texto')){
  $r=Peticion GET "${base}?$filtro";Comprobar "Filtro inválido rechazado: $($filtro.Substring(0,[Math]::Min(30,$filtro.Length)))" ($r.Codigo -eq 400)
 }
 foreach($descripcion in @('', '   ', ('x'*129))){$r=Peticion PUT "$base/$codigo/1" @{descripcion=$descripcion};Comprobar "Nombre inválido longitud $($descripcion.Length)" ($r.Codigo -eq 400)}
 foreach($valor in @(0,1.5,2147483648)){$r=Peticion POST $base @{codigoMarca=$codigo;codigoLinea=$valor;descripcion=$nombre};Comprobar "Código de línea inválido: $valor" ($r.Codigo -eq 400)}
 $r=Peticion POST $base @{codigoLinea=1;descripcion=$nombre};Comprobar 'Marca ausente rechazada' ($r.Codigo -eq 400)
 $nuevo="$nombre ñ <b>texto</b>"
 $r=Peticion PUT "$base/$codigo/1" @{descripcion=$nuevo}
 Comprobar 'Actualizar con identidad compuesta' ($r.Codigo -eq 200 -and $r.Json.descripcion -ceq $nuevo)
 $r=Peticion GET "${base}?codigoMarca=$otra"
 Comprobar 'Editar no afecta la línea del mismo código en otra marca' (@($r.Json).Count -eq 1 -and $r.Json[0].descripcion -ceq $nombre)
 $r=Peticion GET "${base}?codigoMarca=$codigo"
 Comprobar 'Nombre editado y Unicode persistidos' ($r.Json[0].descripcion -ceq $nuevo)
 $garantia=Vehiculo $null
 $r=Peticion DELETE "$base/$codigo/1"
 Comprobar 'Vehículo asociado impide eliminar con 409' ($r.Codigo -eq 409 -and $r.Json.detail -match 'vehículos asociados' -and $r.Texto -notmatch 'REFERENCE|SqlException')
 $r=Peticion GET "${base}?codigoMarca=$codigo"
 Comprobar 'Borrado bloqueado conserva la línea' (@($r.Json).Count -eq 1)
 Vehiculo $garantia;$garantia=$null
 $r=Peticion DELETE "$base/$codigo/1"
 if($r.Codigo -eq 204){[void]$lineasCreadas.Remove($codigo)}
 Comprobar 'Eliminar sin dependencias devuelve 204' ($r.Codigo -eq 204)
 $r=Peticion GET "${base}?codigoMarca=$otra"
 Comprobar 'Eliminar no afecta la otra marca' (@($r.Json).Count -eq 1 -and $r.Json[0].descripcion -ceq $nombre)
 foreach($metodo in @('DELETE','PUT')){
  $r=Peticion $metodo "$base/$codigo/1" $(if($metodo -eq 'PUT'){@{descripcion=$nombre}}else{$null})
  Comprobar "$metodo de línea inexistente devuelve 404" ($r.Codigo -eq 404)
 }
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString("' OR '1'='1"))"
 Comprobar 'Texto SQL es tratado como parámetro' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 $r=Peticion GET "${base}?criterio=sin-linea-$codigo"
 Comprobar 'Sin coincidencias devuelve lista vacía' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 $r=Peticion GET '/openapi/v1.json'
 Comprobar 'OpenAPI documenta las cuatro rutas HTTP' ($null -ne $r.Json.paths.$base.get -and $null -ne $r.Json.paths.$base.post -and $null -ne $r.Json.paths."$base/{codigoMarca}/{codigoLinea}".put -and $null -ne $r.Json.paths."$base/{codigoMarca}/{codigoLinea}".delete)
 $estado='Correcto'
}finally{
 try{
  if($null -ne $garantia){Vehiculo $garantia}
  foreach($m in @($lineasCreadas)){$r=Peticion DELETE "/api/catalogos/lineas/$m/1";if($r.Codigo -ne 204){throw "Limpieza pendiente de línea 1, marca $m"}}
  foreach($m in @($marcasCreadas)){$r=Peticion DELETE "/api/catalogos/marcas/$m";if($r.Codigo -ne 204){throw "Limpieza pendiente de marca $m"}}
  if($estado -eq 'Correcto'){
   $final=Peticion GET '/api/catalogos/lineas';$finalMarcas=Peticion GET '/api/catalogos/marcas'
   Comprobar 'Catálogo de líneas original conservado' (($inicial.Json|ConvertTo-Json -Compress) -ceq ($final.Json|ConvertTo-Json -Compress))
   Comprobar 'Catálogo de marcas original conservado' (($inicialMarcas.Json|ConvertTo-Json -Compress) -ceq ($finalMarcas.Json|ConvertTo-Json -Compress))
  }
 }catch{$estado='Fallido';throw}finally{
  if($null -ne $proceso){if(-not $proceso.HasExited){Stop-Process -Id $proceso.Id;$proceso.WaitForExit()};$proceso.Dispose()}
  [pscustomobject]@{Estado=$estado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 }
}
Write-Output "Comprobaciones correctas: $($pruebas.Count). Registros temporales retirados."
