# Requiere PowerShell 7. Solo modifica registros temporales creados por este ensayo.
param([string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-vendedores'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la API.'}
$pruebas=[Collections.Generic.List[object]]::new()
$proceso=$null;$creada=$false;$persona=$null;$vendedor=$null;$estado='Fallido'
$codigo=$null;$agencia=$null;$agencia2=$null;$persona=$null;$deudor=$null;$garantia=$null;$credito=$null;$marcaId=$null;$lineaCreada=$false
$dpi='998'+(Get-Random -Minimum 1000000000L -Maximum 9999999999L).ToString()
$dpiFallido='997'+(Get-Random -Minimum 1000000000L -Maximum 9999999999L).ToString()
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
function Listado([string]$procedimiento){
 $config=Get-Content -LiteralPath (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cn=[Data.SqlClient.SqlConnection]::new($config.ConnectionStrings.MagisAuto)
 try{
  $cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandType=[Data.CommandType]::StoredProcedure;$cmd.CommandText=$procedimiento
  $reader=$cmd.ExecuteReader()
  while($reader.Read()){
   $fila=[ordered]@{};for($n=0;$n -lt $reader.FieldCount;$n++){$fila[$reader.GetName($n)]=$reader.GetValue($n)}
   [pscustomobject]$fila
  }
 }finally{$cn.Dispose();$config=$null}
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
 $base='/api/vendedores'
 $inicial=Peticion GET $base
 Comprobar 'Listado enriquecido disponible' ($inicial.Codigo -eq 200)
 $personasIniciales=@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 5 -Compress
 $agencia=Procedimiento 'api.Agencia_Insertar' @{Nombre=$nombre;Region='Oriente'}
 $agencia2=Procedimiento 'api.Agencia_Insertar' @{Nombre="$nombre segunda";Region='Centro'}
 $r=Peticion GET '/vendedores.html'
 Comprobar 'Pantalla y campos requeridos servidos' ($r.Codigo -eq 200 -and $r.Texto.Contains('Código de empleado') -and $r.Texto.Contains('DPI'))
 foreach($ruta in @('/vendedores.js','/','/lineas.html','/agencias.html')){
  $r=Peticion GET $ruta;Comprobar "Recurso y navegación: $ruta" ($r.Codigo -eq 200 -and ($ruta -eq '/vendedores.js' -or $r.Texto.Contains('/vendedores.html')))
 }
 $datos=@{codigoEmpleado=('ENS-'+[Guid]::NewGuid().ToString('N').Substring(0,18));dpi=$dpi;primerNombre='  Ensayo  ';segundoNombre='  ';primerApellido='  Vendedores  ';codigoAgencia=[int]$agencia}
 $r=Peticion POST $base $datos
 if($r.Codigo -eq 201){$codigo=$r.Json.codigoVendedor}
 Comprobar 'Crear persona y vendedor juntos' ($r.Codigo -eq 201 -and $codigo -gt 0)
 $actual=(Peticion GET "${base}?criterio=$dpi").Json[0];$persona=$actual.codigoPersona
 Comprobar 'Identidad, nombres recortados y agencia enriquecidos' ($actual.primerNombre -ceq 'Ensayo' -and $actual.primerApellido -ceq 'Vendedores' -and $null -eq $actual.segundoNombre -and $actual.nombreAgencia -ceq $nombre -and $actual.region -ceq 'Oriente')
 $r=Peticion POST $base $datos
 Comprobar 'Persona ya vendedora rechazada' ($r.Codigo -eq 409)
 $fallido=$datos.Clone();$fallido.dpi=$dpiFallido
 $r=Peticion POST $base $fallido
 Comprobar 'Código de empleado duplicado rechazado sin mensaje SQL' ($r.Codigo -eq 409 -and $r.Texto -notmatch 'SqlException|UNIQUE|UQ_')
 Comprobar 'Duplicado revierte la persona creada' (@(Listado 'api.Persona_Listar'|Where-Object DPI -eq $dpiFallido).Count -eq 0)
 $fallido.codigoEmpleado='FAIL-'+[Guid]::NewGuid().ToString('N').Substring(0,15);$fallido.codigoAgencia=2147483647
 $r=Peticion POST $base $fallido
 Comprobar 'Agencia inexistente rechazada' ($r.Codigo -eq 409)
 Comprobar 'Agencia inválida no deja persona huérfana' (@(Listado 'api.Persona_Listar'|Where-Object DPI -eq $dpiFallido).Count -eq 0)
 foreach($campo in @('codigoEmpleado','primerNombre','primerApellido')){
  foreach($valor in @('', '   ')){
   $invalido=$datos.Clone();$invalido[$campo]=$valor;$r=Peticion PUT "$base/$codigo" $invalido
   Comprobar "$campo vacío longitud $($valor.Length) rechazado" ($r.Codigo -eq 400)
  }
 }
 foreach($campo in @('codigoEmpleado','primerNombre','segundoNombre','primerApellido','segundoApellido')){
  $invalido=$datos.Clone();$invalido[$campo]='x' * $(if($campo -eq 'codigoEmpleado'){31}else{65})
  $r=Peticion PUT "$base/$codigo" $invalido;Comprobar "$campo demasiado largo rechazado" ($r.Codigo -eq 400)
 }
 foreach($valor in @('123','abcdefghijklm','12345678901234')){
  $invalido=$datos.Clone();$invalido.dpi=$valor;$r=Peticion PUT "$base/$codigo" $invalido
  Comprobar "DPI inválido $valor rechazado" ($r.Codigo -eq 400)
 }
 $invalido=$datos.Clone();$invalido.codigoAgencia=0;$r=Peticion POST $base $invalido
 Comprobar 'Agencia requerida' ($r.Codigo -eq 400)
 $invalido=$datos.Clone();$invalido.dpi=$dpiFallido;$r=Peticion PUT "$base/$codigo" $invalido
 Comprobar 'Cambio de identidad bloqueado' ($r.Codigo -eq 409)
 # Metadata owned by another role must survive editing names in the seller module.
 $nit='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,12)
 [void](Procedimiento 'api.Persona_Actualizar' @{CodigoPersona=[int]$persona;DPI=$dpi;NIT=$nit;PrimerNombre='Ensayo';PrimerApellido='Vendedores';CorreoElectronico='ensayo@example.invalid';FechaNacimiento=[datetime]'1990-01-01';Genero='M'})
 $deudor=Procedimiento 'api.Deudor_Insertar' @{CodigoPersona=[int]$persona}
 $datos.primerNombre='Editado ñ <b>literal</b>';$datos.primerApellido='Vendedores';$datos.segundoNombre='Segundo';$datos.segundoApellido='Apellido';$datos.codigoAgencia=[int]$agencia2
 $r=Peticion PUT "$base/$codigo" $datos
 Comprobar 'Editar nombres y cambiar agencia' ($r.Codigo -eq 204)
 $p=Listado 'api.Persona_Listar'|Where-Object CodigoPersona -eq $persona
 Comprobar 'Editar conserva NIT, correo, nacimiento y género del cliente' ($p.NIT -ceq $nit -and $p.CorreoElectronico -ceq 'ensayo@example.invalid' -and $p.FechaNacimiento -eq [datetime]'1990-01-01' -and $p.Genero -ceq 'M')
 $invalido=$datos.Clone();$invalido.codigoAgencia=2147483647;$invalido.primerNombre='No debe guardarse'
 $r=Peticion PUT "$base/$codigo" $invalido
 Comprobar 'Edición con agencia inválida rechazada' ($r.Codigo -eq 409)
 $p=Listado 'api.Persona_Listar'|Where-Object CodigoPersona -eq $persona
 Comprobar 'Fallo al editar revierte también los nombres' ($p.PrimerNombre -ceq $datos.primerNombre)
 foreach($criterio in @($dpi,$datos.codigoEmpleado,'Editado ñ',"$nombre segunda")){
  $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($criterio))"
  Comprobar "Buscar vendedor por $criterio" ($r.Codigo -eq 200 -and @($r.Json).Count -eq 1 -and $r.Json[0].codigoVendedor -eq $codigo)
 }
 $r=Peticion GET "${base}?codigoAgencia=$agencia&criterio=$dpi"
 Comprobar 'Filtro excluye agencia anterior' (@($r.Json).Count -eq 0)
 $r=Peticion GET "${base}?codigoAgencia=$agencia2&criterio=$dpi"
 Comprobar 'Filtro incluye agencia actual' (@($r.Json).Count -eq 1)
 foreach($filtro in @('criterio=','criterio=%20','codigoAgencia=','codigoAgencia=0',('criterio='+('x'*201)))){
  $r=Peticion GET "${base}?$filtro";Comprobar "Filtro inválido $filtro" ($r.Codigo -eq 400)
 }
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString("' OR 1=1--"))"
 Comprobar 'Búsqueda literal no ejecuta SQL' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 # Credit in draft exercises the actual seller FK without approving or producing payments.
 $marcaId=Get-Random -Minimum 100000000 -Maximum 2000000000
 [void](Procedimiento 'api.Marca_Insertar' @{CodigoMarca=[int]$marcaId;Descripcion=$nombre})
 [void](Procedimiento 'api.Linea_Insertar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1;Descripcion=$nombre});$lineaCreada=$true
 $garantia=Procedimiento 'api.Garantia_Insertar' @{VIN=('ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14).ToUpper());CodigoMarca=[int]$marcaId;CodigoLinea=1;Anio=2026;ValorAgencia=[decimal]100000;CodigoTipoGarantia=1;EsNuevo=$true}
 $numero='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,15)
 [void](Procedimiento 'api.Credito_Insertar' @{NumeroCredito=$numero;CodigoDeudor=[int]$deudor;CodigoGarantia=[int]$garantia;CodigoVendedor=[int]$codigo;Enganche=[decimal]20000});$credito=$numero
 $r=Peticion DELETE "$base/$codigo"
 Comprobar 'Vendedor con crédito no se elimina y error es comprensible' ($r.Codigo -eq 409 -and $r.Json.detail -match 'créditos' -and $r.Texto -notmatch 'SqlException|REFERENCE')
 [void](Procedimiento 'api.Credito_Eliminar' @{NumeroCredito=$credito});$credito=$null
 [void](Procedimiento 'api.Garantia_Eliminar' @{CodigoGarantia=[int]$garantia});$garantia=$null
 [void](Procedimiento 'api.Linea_Eliminar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1});$lineaCreada=$false
 [void](Procedimiento 'api.Marca_Eliminar' @{CodigoMarca=[int]$marcaId});$marcaId=$null
 $codigoAnterior=$codigo
 $r=Peticion DELETE "$base/$codigo"
 Comprobar 'Eliminar vendedor sin créditos' ($r.Codigo -eq 204)
 $codigo=$null
 Comprobar 'Eliminar rol conserva la persona compartida' (@(Listado 'api.Persona_Listar'|Where-Object CodigoPersona -eq $persona).Count -eq 1)
 Comprobar 'Eliminar vendedor conserva el rol cliente' (@(Listado 'api.Deudor_Listar'|Where-Object CodigoDeudor -eq $deudor).Count -eq 1)
 $r=Peticion DELETE "$base/$codigoAnterior";Comprobar 'Eliminar inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion PUT "$base/$codigoAnterior" $datos;Comprobar 'Editar inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion DELETE "$base/0";Comprobar 'Código cero rechazado' ($r.Codigo -eq 400)
 $invalido=$datos.Clone();$invalido.primerNombre='Otra identidad'
 $r=Peticion POST $base $invalido
 Comprobar 'No reemplaza nombres de persona existente al vincular' ($r.Codigo -eq 409)
 $r=Peticion POST $base $datos
 if($r.Codigo -eq 201){$codigo=$r.Json.codigoVendedor}
 Comprobar 'Persona existente se reutiliza como vendedor' ($r.Codigo -eq 201 -and (Peticion GET "${base}?criterio=$dpi").Json[0].codigoPersona -eq $persona)
 $r=Peticion DELETE "$base/$codigo";Comprobar 'Retirar vendedor recreado' ($r.Codigo -eq 204);$codigo=$null
 [void](Procedimiento 'api.Deudor_Eliminar' @{CodigoDeudor=[int]$deudor});$deudor=$null
 [void](Procedimiento 'api.Persona_Eliminar' @{CodigoPersona=[int]$persona});$persona=$null
 [void](Procedimiento 'api.Agencia_Eliminar' @{CodigoAgencia=[int]$agencia});$agencia=$null
 [void](Procedimiento 'api.Agencia_Eliminar' @{CodigoAgencia=[int]$agencia2});$agencia2=$null
 $r=Peticion GET '/openapi/v1.json'
 Comprobar 'Contrato API completo' ($null -ne $r.Json.paths.$base.get -and $null -ne $r.Json.paths.$base.post -and $null -ne $r.Json.paths."$base/{codigo}".put -and $null -ne $r.Json.paths."$base/{codigo}".delete)
 $final=Peticion GET $base
 Comprobar 'Vendedores originales conservados' (($inicial.Json|ConvertTo-Json -Depth 5 -Compress) -ceq ($final.Json|ConvertTo-Json -Depth 5 -Compress))
 Comprobar 'Personas originales conservadas' ($personasIniciales -ceq (@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 5 -Compress))
 $estado='Correcto'
}finally{
 try{
  if($credito){[void](Procedimiento 'api.Credito_Eliminar' @{NumeroCredito=$credito})}
  if($garantia){[void](Procedimiento 'api.Garantia_Eliminar' @{CodigoGarantia=[int]$garantia})}
  if($lineaCreada){[void](Procedimiento 'api.Linea_Eliminar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1})}
  if($marcaId){[void](Procedimiento 'api.Marca_Eliminar' @{CodigoMarca=[int]$marcaId})}
  if($codigo){[void](Procedimiento 'api.Vendedor_Eliminar' @{CodigoVendedor=[int]$codigo})}
  if($deudor){[void](Procedimiento 'api.Deudor_Eliminar' @{CodigoDeudor=[int]$deudor})}
  # Only test-owned DPIs are eligible for cleanup if a failed assertion interrupted ID capture.
  foreach($p in @(Listado 'api.Persona_Listar'|Where-Object { $_.DPI -in @($dpi,$dpiFallido) })){
   [void](Procedimiento 'api.Persona_Eliminar' @{CodigoPersona=[int]$p.CodigoPersona})
  }
  if($agencia){[void](Procedimiento 'api.Agencia_Eliminar' @{CodigoAgencia=[int]$agencia})}
  if($agencia2){[void](Procedimiento 'api.Agencia_Eliminar' @{CodigoAgencia=[int]$agencia2})}
 }finally{
  if($null -ne $proceso){if(-not $proceso.HasExited){Stop-Process -Id $proceso.Id;$proceso.WaitForExit()};$proceso.Dispose()}
  [pscustomobject]@{Estado=$estado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 }
}
Write-Output "Comprobaciones correctas: $($pruebas.Count). Datos temporales retirados; los correlativos pueden tener saltos."
