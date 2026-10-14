# Requiere PowerShell 7. Solo modifica registros temporales creados por este ensayo.
param([string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-vehiculos'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la API.'}
$pruebas=[Collections.Generic.List[object]]::new()
$proceso=$null;$creada=$false;$persona=$null;$vendedor=$null;$estado='Fallido'
$codigo2=$null;$marca2=$null;$linea2=$false;$valoracion=$null;$marcaCreada=$false;$vinculo=$false;$personasPrueba=[Collections.Generic.List[int]]::new();$codigo=$null;$agencia=$null;$agencia2=$null;$persona=$null;$deudor=$null;$garantia=$null;$credito=$null;$marcaId=$null;$lineaCreada=$false
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
 if($null -ne $datos){$p.ContentType='application/json; charset=utf-8';$p.Body=($datos|ConvertTo-Json -Depth 20 -Compress)}
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


 $base='/api/vehiculos'
 $inicial=Peticion GET $base
 Comprobar 'Listado de vehículos disponible' ($inicial.Codigo -eq 200)
 $catalogosIniciales=@(Listado 'api.Marca_Listar';Listado 'api.Linea_Listar';Listado 'api.TipoGarantia_Listar')|ConvertTo-Json -Depth 12 -Compress
 $creditosIniciales=@(Listado 'api.Credito_Listar')|ConvertTo-Json -Depth 12 -Compress
 $valoracionesIniciales=@(Listado 'api.Depreciacion_Listar')|ConvertTo-Json -Depth 12 -Compress
 $personasIniciales=@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 12 -Compress
 $marcaId=Get-Random -Minimum 100000000 -Maximum 1000000000
 $marca2Creada=$false
 $marca2=Get-Random -Minimum 1000000001 -Maximum 2000000000
 [void](Procedimiento 'api.Marca_Insertar' @{CodigoMarca=[int]$marcaId;Descripcion=$nombre});$marcaCreada=$true
 [void](Procedimiento 'api.Marca_Insertar' @{CodigoMarca=[int]$marca2;Descripcion=($nombre+' segunda')});$marca2Creada=$true
 [void](Procedimiento 'api.Linea_Insertar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1;Descripcion='Línea de ensayo'});$lineaCreada=$true
 [void](Procedimiento 'api.Linea_Insertar' @{CodigoMarca=[int]$marca2;CodigoLinea=2;Descripcion='Segunda línea'});$linea2=$true
 $cat=(Peticion GET "$base/catalogos").Json
 Comprobar 'Catálogos de marca, línea y tipo disponibles' ($cat.marcas.Count -gt 0 -and $cat.lineas.Count -gt 0 -and $cat.tiposGarantia.Count -gt 0)
 foreach($ruta in @('/','/lineas.html','/agencias.html','/vendedores.html','/clientes.html','/fiadores.html','/vehiculos.html')){
  $r=Peticion GET $ruta;Comprobar "Pantalla y navegación: $ruta" ($r.Codigo -eq 200 -and $r.Texto.Contains('/vehiculos.html'))
 }
 foreach($ruta in @('/vehiculos.js','/vehiculos.css')){Comprobar "Recurso disponible: $ruta" ((Peticion GET $ruta).Codigo -eq 200)}
 $vin='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14).ToUpper()
 $vin2='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14).ToUpper()
 $datos=@{vin=(' '+$vin.ToLower()+' ');codigoMarca=[int]$marcaId;codigoLinea=1;anio=2026;valorAgencia='100000.25';placa='  ';codigoTipoGarantia=[int]$cat.tiposGarantia[0].codigoTipoGarantia}
 $r=Peticion POST $base $datos;if($r.Codigo -eq 201){$codigo=$r.Json.codigoGarantia}
 Comprobar 'Crear vehículo sin placa y código automático' ($r.Codigo -eq 201 -and $codigo -gt 0)
 function Ficha { (Peticion GET "$base/$codigo").Json }
 $f=Ficha
 Comprobar 'VIN normalizado, precio exacto, placa nula y condición nueva' ($f.vin -ceq $vin -and $f.valorAgencia -ceq '100000.25' -and $null -eq $f.placa -and $f.esNuevo)
 Comprobar 'Marca y línea enriquecidas sin inventar historial' ($f.marca -ceq $nombre -and $f.linea -ceq 'Línea de ensayo' -and -not $f.tieneHistorialContractual -and $f.creditosVinculados -eq 0 -and $f.valoracionesRegistradas -eq 0)
 $r=Peticion POST $base $datos;Comprobar 'VIN duplicado rechazado sin detalles SQL' ($r.Codigo -eq 409 -and $r.Texto -notmatch 'SqlException|UNIQUE|UQ_')
 foreach($vinMal in @('','12345','123456789012345678','1234567890123456I','1234567890123456O','1234567890123456Q','1234567890123456-')){
  $mal=$datos.Clone();$mal.vin=$vinMal;Comprobar "VIN inválido rechazado: $vinMal" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 }
 foreach($anioMal in @(0,1885,2101)){
  $mal=$datos.Clone();$mal.anio=$anioMal;Comprobar "Año fuera del esquema: $anioMal" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 }
 foreach($precioMal in @('0','-1','1.001','10000000000000000','no-numero')){
  $mal=$datos.Clone();$mal.valorAgencia=$precioMal;Comprobar "Precio inválido rechazado: $precioMal" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 }
 $mal=$datos.Clone();$mal.placa='X'*21;Comprobar 'Placa demasiado larga rechazada' ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 foreach($campo in @('codigoMarca','codigoLinea','codigoTipoGarantia')){
  $mal=$datos.Clone();$mal[$campo]=0;Comprobar "Código cero rechazado: $campo" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
  $mal[$campo]=2147483647;Comprobar "Catálogo inexistente rechazado: $campo" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 409)
 }
 $anterior=Ficha|ConvertTo-Json -Depth 10 -Compress
 $mal=$datos.Clone();$mal.codigoLinea=2;$mal.valorAgencia='200000.00'
 Comprobar 'Línea de otra marca rechazada' ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 409)
 Comprobar 'Error de catálogo no altera el vehículo' ((Ficha|ConvertTo-Json -Depth 10 -Compress) -ceq $anterior)
 foreach($limite in @('0.01','9999999999999999.99')){
  $mal=$datos.Clone();$mal.valorAgencia=$limite
  Comprobar "Precio límite conserva centavos: $limite" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 204 -and (Ficha).valorAgencia -ceq $limite)
 }
 $placa='E'+[Guid]::NewGuid().ToString('N').Substring(0,9).ToUpper()
 $datos.placa=' '+$placa.ToLower()+' ';$datos.valorAgencia='123456.78';$datos.anio=2025
 Comprobar 'Editar precio, año y placa' ((Peticion PUT "$base/$codigo" $datos).Codigo -eq 204)
 $f=Ficha;Comprobar 'Edición persiste con placa normalizada y mismo código' ($f.codigoGarantia -eq $codigo -and $f.placa -ceq $placa -and $f.valorAgencia -ceq '123456.78' -and $f.anio -eq 2025)
 $datos2=$datos.Clone();$datos2.vin=$vin2;$datos2.codigoMarca=[int]$marca2;$datos2.codigoLinea=2
 Comprobar 'Placa duplicada rechazada' ((Peticion POST $base $datos2).Codigo -eq 409)
 $datos2.placa=$null;$datos2.esNuevo=$false
 $r=Peticion POST $base $datos2;if($r.Codigo -eq 201){$codigo2=$r.Json.codigoGarantia}
 Comprobar 'Segundo vehículo sin placa; API siempre registra nuevo' ($r.Codigo -eq 201 -and (Peticion GET "$base/$codigo2").Json.esNuevo)
 $mal=$datos.Clone();$mal.vin=$vin2;Comprobar 'No se puede editar hacia un VIN ya registrado' ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 409)
 $mal=$datos2.Clone();$mal.placa=$placa;Comprobar 'No se puede editar hacia una placa ya registrada' ((Peticion PUT "$base/$codigo2" $mal).Codigo -eq 409)
 foreach($criterio in @($codigo.ToString(),$vin,$placa,$nombre,'Línea de ensayo','2025')){
  $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($criterio))";Comprobar "Búsqueda literal por $criterio" ($r.Codigo -eq 200 -and $codigo -in @($r.Json.codigoGarantia))
 }
 $r=Peticion GET "${base}?codigoMarca=$marcaId";Comprobar 'Filtro por marca excluye la otra' ($r.Codigo -eq 200 -and $codigo -in @($r.Json.codigoGarantia) -and $codigo2 -notin @($r.Json.codigoGarantia))
 $r=Peticion GET "${base}?codigoMarca=$marca2&criterio=$vin";Comprobar 'Filtros combinados respetan marca y criterio' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 foreach($query in @('criterio=','criterio=%20%20','codigoMarca=','codigoMarca=0',('criterio='+('x'*201)))){Comprobar "Filtro inválido: $query" ((Peticion GET "${base}?$query").Codigo -eq 400)}
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString("' OR 1=1--"))";Comprobar 'Texto SQL tratado literalmente' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 $datos.placa=$null;Comprobar 'Quitar placa es válido' ((Peticion PUT "$base/$codigo" $datos).Codigo -eq 204 -and $null -eq (Ficha).placa)
 Comprobar 'Varios vehículos pueden no tener placa' ($null -eq (Peticion GET "$base/$codigo2").Json.placa)
 # Solo una valoración ficticia para comprobar FK; no es depreciación automática al registrar.
 $valoracion=Procedimiento 'api.Depreciacion_Insertar' @{CodigoGarantia=[int]$codigo2;FechaValoracion=[datetime]'2026-01-01';ValorOriginal=[decimal]123456.78;Porcentaje=[decimal]0.15;Observacion='Valoración temporal del ensayo'}
 $r=Peticion DELETE "$base/$codigo2";Comprobar 'Valoración vinculada bloquea eliminación con aviso específico' ($r.Codigo -eq 409 -and $r.Json.detail -like '*créditos o valoraciones vinculadas*')
 Comprobar 'Cuenta valoraciones sin afirmar historial contractual' ((Peticion GET "$base/$codigo2").Json.valoracionesRegistradas -eq 1 -and -not (Peticion GET "$base/$codigo2").Json.tieneHistorialContractual)
 [void](Procedimiento 'api.Depreciacion_Eliminar' @{CodigoDepreciacion=[int]$valoracion});$valoracion=$null
 # Crédito BORRADOR propio: no aprobación, pagos ni historial financiero permanente.
 $persona=Procedimiento 'api.Persona_Insertar' @{DPI=$dpi;NIT=('ENS'+[Guid]::NewGuid().ToString('N').Substring(0,12));PrimerNombre='Persona';PrimerApellido='Ensayo';CorreoElectronico='ensayo@example.invalid';FechaNacimiento=[datetime]'1990-01-01'}
 $deudor=Procedimiento 'api.Deudor_Insertar' @{CodigoPersona=[int]$persona}
 $agencia=Procedimiento 'api.Agencia_Insertar' @{Nombre=$nombre;Region='Ensayo'}
 $vendedor=Procedimiento 'api.Vendedor_Insertar' @{CodigoPersona=[int]$persona;CodigoAgencia=[int]$agencia;CodigoEmpleado=('ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14))}
 $numero='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,15)
 [void](Procedimiento 'api.Credito_Insertar' @{NumeroCredito=$numero;CodigoDeudor=[int]$deudor;CodigoGarantia=[int]$codigo;CodigoVendedor=[int]$vendedor;Enganche=[decimal]30000});$credito=$numero
 $r=Peticion DELETE "$base/$codigo";Comprobar 'Crédito borrador vinculado bloquea eliminación' ($r.Codigo -eq 409 -and $r.Json.detail -like '*créditos o valoraciones vinculadas*')
 Comprobar 'Crédito borrador contado sin historial aprobado' ((Ficha).creditosVinculados -eq 1 -and -not (Ficha).tieneHistorialContractual)
 Comprobar 'Se permite editar antes de aprobación según SQL' ((Peticion PUT "$base/$codigo" $datos).Codigo -eq 204)
 [void](Procedimiento 'api.Credito_Eliminar' @{NumeroCredito=$credito});$credito=$null
 $codigoAnterior=$codigo;Comprobar 'Eliminar sin dependencias' ((Peticion DELETE "$base/$codigo").Codigo -eq 204);$codigo=$null
 Comprobar 'Eliminar segundo vehículo sin valoración' ((Peticion DELETE "$base/$codigo2").Codigo -eq 204);$codigo2=$null
 foreach($metodo in @('GET','PUT','DELETE')){Comprobar "Registro inexistente devuelve 404: $metodo" ((Peticion $metodo "$base/$codigoAnterior" $(if($metodo -eq 'PUT'){$datos}else{$null})).Codigo -eq 404)}
 Comprobar 'Código cero no válido' ((Peticion GET "$base/0").Codigo -eq 400)
 $final=Peticion GET $base;Comprobar 'Vehículos iniciales intactos' (($inicial.Json|ConvertTo-Json -Depth 12 -Compress) -ceq ($final.Json|ConvertTo-Json -Depth 12 -Compress))
 $estado='Correcto'
}finally{
 try{
  if($credito){[void](Procedimiento 'api.Credito_Eliminar' @{NumeroCredito=$credito})}
  if($valoracion){[void](Procedimiento 'api.Depreciacion_Eliminar' @{CodigoDepreciacion=[int]$valoracion})}
  foreach($vehiculo in @($codigo,$codigo2)|Where-Object {$_}){[void](Procedimiento 'api.Garantia_Eliminar' @{CodigoGarantia=[int]$vehiculo})}
  if($vendedor){[void](Procedimiento 'api.Vendedor_Eliminar' @{CodigoVendedor=[int]$vendedor})}
  if($deudor){[void](Procedimiento 'api.Deudor_Eliminar' @{CodigoDeudor=[int]$deudor})}
  if($persona){[void](Procedimiento 'api.Persona_Eliminar' @{CodigoPersona=[int]$persona})}
  if($agencia){[void](Procedimiento 'api.Agencia_Eliminar' @{CodigoAgencia=[int]$agencia})}
  if($lineaCreada){[void](Procedimiento 'api.Linea_Eliminar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1})}
  if($linea2){[void](Procedimiento 'api.Linea_Eliminar' @{CodigoMarca=[int]$marca2;CodigoLinea=2})}
  if($marcaCreada){[void](Procedimiento 'api.Marca_Eliminar' @{CodigoMarca=[int]$marcaId})}
  if($marca2Creada){[void](Procedimiento 'api.Marca_Eliminar' @{CodigoMarca=[int]$marca2})}
  if($estado -eq 'Correcto'){
   Comprobar 'Catálogos iniciales intactos' ($catalogosIniciales -ceq (@(Listado 'api.Marca_Listar';Listado 'api.Linea_Listar';Listado 'api.TipoGarantia_Listar')|ConvertTo-Json -Depth 12 -Compress))
   Comprobar 'Créditos iniciales intactos' ($creditosIniciales -ceq (@(Listado 'api.Credito_Listar')|ConvertTo-Json -Depth 12 -Compress))
   Comprobar 'Valoraciones iniciales intactas' ($valoracionesIniciales -ceq (@(Listado 'api.Depreciacion_Listar')|ConvertTo-Json -Depth 12 -Compress))
   Comprobar 'Personas iniciales intactas' ($personasIniciales -ceq (@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 12 -Compress))
  }
 }catch{$estado='Fallido';throw}finally{
  if($null -ne $proceso){if(-not $proceso.HasExited){Stop-Process -Id $proceso.Id;$proceso.WaitForExit()};$proceso.Dispose()}
  [pscustomobject]@{Estado=$estado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 }
}
Write-Output "Comprobaciones correctas: $($pruebas.Count). Registros temporales retirados; pueden quedar saltos en correlativos."
