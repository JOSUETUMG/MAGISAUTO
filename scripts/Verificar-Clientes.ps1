# Requiere PowerShell 7. Solo modifica registros temporales creados por este ensayo.
param([string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-clientes'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la API.'}
$pruebas=[Collections.Generic.List[object]]::new()
$proceso=$null;$creada=$false;$persona=$null;$vendedor=$null;$estado='Fallido'
$codigo=$null;$agencia=$null;$agencia2=$null;$persona=$null;$deudor=$null;$garantia=$null;$credito=$null;$marcaId=$null;$lineaCreada=$false
$dpi='998'+(Get-Random -Minimum 1000000000L -Maximum 9999999999L).ToString()
$cliente2=$null;$persona2=$null;$refPropia=$null;$vendedorPrueba=$null;$personasPrueba=[Collections.Generic.List[int]]::new();$referenciasPrueba=[Collections.Generic.List[int]]::new();$agenciaPrueba=$null
$dpiFallido='997'+(Get-Random -Minimum 1000000000L -Maximum 9999999999L).ToString()
$nombre="Ensayo cliente $([Guid]::NewGuid().ToString('N').Substring(0,10))"
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
 $base='/api/clientes'
 $inicial=Peticion GET $base
 Comprobar 'Listado clientes disponible' ($inicial.Codigo -eq 200)
 $personasIniciales=@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 8 -Compress
 $cat=(Peticion GET "$base/catalogos").Json
 Comprobar 'Catálogos de contactos, ubicación y referencias disponibles' ($cat.TipoTelefono.Count -gt 0 -and $cat.TipoDireccion.Count -gt 0 -and $cat.Municipio.Count -gt 0 -and $cat.TipoReferencia.Count -gt 0)
 $municipio=$cat.Municipio[0]
 function TelefonoNuevo([string]$numero='55551234') { @{correlativo=0;codigoTipoTelefono=[int]$cat.TipoTelefono[0].codigoTipoTelefono;numero=$numero} }
 function DireccionNueva { @{correlativo=0;codigoTipoDireccion=[int]$cat.TipoDireccion[0].codigoTipoDireccion;codigoDepartamento=[int]$municipio.codigoDepartamento;codigoMunicipio=[int]$municipio.codigoMunicipio;detalle='Dirección ficticia del ensayo'} }
 function ReferenciaNueva([int]$n) { @{primerNombre="Referencia $n";primerApellido='Ensayo';lugarTrabajo='Trabajo ficticio';codigoTipoReferencia=[int]$cat.TipoReferencia[0].codigoTipoReferencia;parentescoRelacion='Amistad';telefonos=@((TelefonoNuevo));direcciones=@((DireccionNueva))} }
 function Enviar([string]$metodo,[string]$ruta,[object]$cuerpo){
  # Peticion de la plantilla serializa solo a profundidad 2; sobrescribir para expedientes anidados.
  $r=Invoke-WebRequest -Uri "$url$ruta" -Method $metodo -ContentType 'application/json; charset=utf-8' -Body ($cuerpo|ConvertTo-Json -Depth 20 -Compress) -NoProxy -SkipHttpErrorCheck -TimeoutSec 30
  $text=if($r.Content -is [byte[]]){[Text.Encoding]::UTF8.GetString($r.Content)}else{[string]$r.Content}
  [pscustomobject]@{Codigo=[int]$r.StatusCode;Texto=$text;Json=$(if($text){$text|ConvertFrom-Json}else{$null})}
 }
 function Ficha { (Peticion GET "$base/$codigo").Json }
 function RecordarReferencias($f){
  foreach($ref in $f.referencias){if($ref.codigoReferencia -notin $referenciasPrueba){$referenciasPrueba.Add([int]$ref.codigoReferencia)}}
  foreach($ref in @(Listado 'api.Referencia_Listar'|Where-Object CodigoReferencia -in $referenciasPrueba)){
   if($ref.CodigoPersona -notin $personasPrueba){$personasPrueba.Add([int]$ref.CodigoPersona)}
  }
 }
 foreach($ruta in @('/clientes.html','/clientes.js','/clientes.css','/vendedores.html')){
  $r=Peticion GET $ruta;Comprobar "Recurso disponible $ruta" ($r.Codigo -eq 200)
 }
 $nit='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,12)
 $datos=@{dpi=$dpi;nit=$nit;primerNombre='  Cliente  ';primerApellido='  Ensayo  ';correoElectronico='cliente@example.invalid';fechaNacimiento='1990-01-01';telefonos=@();direcciones=@();referencias=@()}
 $r=Enviar POST $base $datos
 if($r.Codigo -eq 201){$codigo=$r.Json.codigoCliente}
 Comprobar 'Guardar cliente con expediente incompleto' ($r.Codigo -eq 201 -and $codigo -gt 0)
 $f=Ficha;$persona=$f.codigoPersona;$personasPrueba.Add([int]$persona)
 Comprobar 'Datos recortados y faltantes explícitos' ($f.primerNombre -ceq 'Cliente' -and $f.faltantes.Count -eq 3 -and $f.referenciasCompletas -eq 0)
 $r=Enviar POST $base $datos;Comprobar 'DPI cliente duplicado rechazado' ($r.Codigo -eq 409)
 $mal=$datos.Clone();$mal.dpi=$dpiFallido
 $r=Enviar POST $base $mal;Comprobar 'NIT duplicado rechazado' ($r.Codigo -eq 409)
 Comprobar 'No queda persona de creación fallida' (@(Listado 'api.Persona_Listar'|Where-Object DPI -eq $dpiFallido).Count -eq 0)
 foreach($campo in @('nit','primerNombre','primerApellido','correoElectronico')){
  $mal=$datos.Clone();$mal[$campo]='   ';$r=Enviar PUT "$base/$codigo" $mal;Comprobar "$campo vacío rechazado" ($r.Codigo -eq 400)
 }
 foreach($campo in @('telefonos','direcciones','referencias')){
  $mal=$datos.Clone();$mal[$campo]=$null;$r=Enviar PUT "$base/$codigo" $mal;Comprobar "Colección nula $campo rechazada" ($r.Codigo -eq 400)
 }
 $mal=$datos.Clone();$mal.fechaNacimiento='2099-01-01';$r=Enviar PUT "$base/$codigo" $mal;Comprobar 'Nacimiento futuro rechazado' ($r.Codigo -eq 400)
 $mal=$datos.Clone();$mal.dpi=$dpiFallido;$r=Enviar PUT "$base/$codigo" $mal;Comprobar 'Cambio DPI cliente rechazado' ($r.Codigo -eq 409)
 $f.telefonos=@((TelefonoNuevo),(TelefonoNuevo '55555678'));$f.direcciones=@((DireccionNueva),(DireccionNueva));$f.referencias=@((ReferenciaNueva 1),(ReferenciaNueva 2))
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'Guardar varios contactos y dos referencias' ($r.Codigo -eq 204)
 $f=Ficha;RecordarReferencias $f
 Comprobar 'Dos referencias mantienen expediente incompleto' ($f.telefonos.Count -eq 2 -and $f.direcciones.Count -eq 2 -and $f.referenciasCompletas -eq 2 -and $f.faltantes.Count -eq 1)
 $f.referencias+=ReferenciaNueva 3
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'Agregar tercera referencia' ($r.Codigo -eq 204)
 $f=Ficha;RecordarReferencias $f
 Comprobar 'Tres referencias completas satisfacen checklist sin aprobar crédito' ($f.referenciasCompletas -eq 3 -and $f.faltantes.Count -eq 0)
 $antes=$f|ConvertTo-Json -Depth 20 -Compress
 $f.primerNombre='No debe persistir';$f.direcciones[0].codigoMunicipio=2147483647
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'Municipio inválido rechazado' ($r.Codigo -eq 409)
 Comprobar 'Error revierte expediente entero' ((Ficha|ConvertTo-Json -Depth 20 -Compress) -ceq $antes)
 $f=Ficha;$f.telefonos[1].correlativo=$f.telefonos[0].correlativo
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'Correlativo repetido de contacto rechazado' ($r.Codigo -eq 400)
 $f=Ficha;$f.telefonos[0].correlativo=32766
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'No se puede editar contacto ajeno o inexistente' ($r.Codigo -eq 409)
 $f=Ficha;$f.referencias+= $f.referencias[0]
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'Referencia repetida no cuenta dos veces' ($r.Codigo -eq 400)
 $refPropia=Procedimiento 'api.Referencia_Insertar' @{CodigoPersona=[int]$persona;LugarTrabajo='Ensayo propio'}
 $f=Ficha;$rprop=ReferenciaNueva 4;$rprop.codigoReferencia=[int]$refPropia;$f.referencias+= $rprop
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'Cliente no puede ser su propia referencia' ($r.Codigo -eq 409)
 [void](Procedimiento 'api.Referencia_Eliminar' @{CodigoReferencia=[int]$refPropia});$refPropia=$null
 $f=Ficha;$f.telefonos[0].numero='55550000';$f.direcciones[0].detalle='Dirección editada ñ <b>literal</b>';$f.referencias[0].parentescoRelacion='Vecino';$f.referencias[0].lugarTrabajo='Lugar actualizado'
 $r=Enviar PUT "$base/$codigo" $f;Comprobar 'Editar contactos y referencia' ($r.Codigo -eq 204)
 $f=Ficha;Comprobar 'Cambios de contactos y relación persistidos' ($f.telefonos[0].numero -ceq '55550000' -and $f.direcciones[0].detalle -match 'editada ñ' -and $f.referencias[0].parentescoRelacion -ceq 'Vecino')
 $f.referencias[2].telefonos=@();$r=Enviar PUT "$base/$codigo" $f;Comprobar 'Referencia incompleta se permite en borrador' ($r.Codigo -eq 204)
 $f=Ficha;Comprobar 'Referencia sin teléfono deja de contar completa' ($f.referenciasCompletas -eq 2 -and $f.faltantes.Count -eq 1)
 $f.referencias[2].telefonos=@((TelefonoNuevo));$r=Enviar PUT "$base/$codigo" $f;Comprobar 'Completar referencia de nuevo' ($r.Codigo -eq 204)
 # Reuse reference on second client; linking must not overwrite its shared data.
 $segundo=$datos.Clone();$segundo.dpi=$dpiFallido;$segundo.nit='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,12);$segundo.primerNombre='Segundo'
 $r=Enviar POST $base $segundo
 if($r.Codigo -eq 201){$cliente2=$r.Json.codigoCliente}
 Comprobar 'Crear segundo cliente de ensayo' ($r.Codigo -eq 201)
 $f2=(Peticion GET "$base/$cliente2").Json;$persona2=$f2.codigoPersona;$personasPrueba.Add([int]$persona2)
 $f=Ficha;$f2.referencias=@($f.referencias[0]);$f2.referencias[0].primerNombre='No reemplazar al vincular'
 $r=Enviar PUT "$base/$cliente2" $f2;Comprobar 'Vincular referencia existente' ($r.Codigo -eq 204)
 $f2=(Peticion GET "$base/$cliente2").Json
 Comprobar 'Vincular no duplica ni reemplaza identidad compartida' ($f2.referencias[0].codigoReferencia -eq $f.referencias[0].codigoReferencia -and $f2.referencias[0].primerNombre -ceq 'Referencia 1')
 $r=Peticion DELETE "$base/$cliente2";Comprobar 'Cliente con referencias no se borra accidentalmente' ($r.Codigo -eq 409)
 $f2.referencias=@();$r=Enviar PUT "$base/$cliente2" $f2;Comprobar 'Retirar vínculo sin borrar referencia compartida' ($r.Codigo -eq 204 -and (Ficha).referencias.Count -eq 3)
 $r=Peticion DELETE "$base/$cliente2";Comprobar 'Eliminar rol cliente sin vínculos' ($r.Codigo -eq 204);$cliente2=$null
 Comprobar 'Eliminar cliente conserva persona' (@(Listado 'api.Persona_Listar'|Where-Object CodigoPersona -eq $persona2).Count -eq 1)
 foreach($criterio in @($dpi,$nit,'Cliente Ensayo','cliente@example.invalid')){
  $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($criterio))"
  Comprobar "Búsqueda por $criterio" ($r.Codigo -eq 200 -and $codigo -in @($r.Json.codigoCliente))
 }
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString("' OR 1=1--"))";Comprobar 'Filtro de texto no ejecuta SQL' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 $r=Peticion GET "${base}?criterio=";Comprobar 'Filtro vacío rechazado' ($r.Codigo -eq 400)
 # A credit draft checks the actual client FK. No approval/quotas/payments are created.
 $agenciaPrueba=Procedimiento 'api.Agencia_Insertar' @{Nombre=$nombre;Region='Ensayo'}
 $vendedorPrueba=Procedimiento 'api.Vendedor_Insertar' @{CodigoEmpleado=('ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14));CodigoPersona=[int]$persona;CodigoAgencia=[int]$agenciaPrueba}
 $marcaId=Get-Random -Minimum 100000000 -Maximum 2000000000
 [void](Procedimiento 'api.Marca_Insertar' @{CodigoMarca=[int]$marcaId;Descripcion=$nombre})
 [void](Procedimiento 'api.Linea_Insertar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1;Descripcion=$nombre});$lineaCreada=$true
 $garantia=Procedimiento 'api.Garantia_Insertar' @{VIN=('ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14).ToUpper());CodigoMarca=[int]$marcaId;CodigoLinea=1;Anio=2026;ValorAgencia=[decimal]100000;CodigoTipoGarantia=1;EsNuevo=$true}
 $numero='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,15)
 [void](Procedimiento 'api.Credito_Insertar' @{NumeroCredito=$numero;CodigoDeudor=[int]$codigo;CodigoGarantia=[int]$garantia;CodigoVendedor=[int]$vendedorPrueba;Enganche=[decimal]20000});$credito=$numero
 $f=Ficha;$f.referencias=@();$r=Enviar PUT "$base/$codigo" $f;Comprobar 'Retirar referencias en crédito borrador' ($r.Codigo -eq 204)
 $r=Peticion DELETE "$base/$codigo";Comprobar 'Cliente con crédito se conserva' ($r.Codigo -eq 409)
 [void](Procedimiento 'api.Credito_Eliminar' @{NumeroCredito=$credito});$credito=$null
 [void](Procedimiento 'api.Garantia_Eliminar' @{CodigoGarantia=[int]$garantia});$garantia=$null
 [void](Procedimiento 'api.Linea_Eliminar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1});$lineaCreada=$false
 [void](Procedimiento 'api.Marca_Eliminar' @{CodigoMarca=[int]$marcaId});$marcaId=$null
 $codigoAnterior=$codigo;$r=Peticion DELETE "$base/$codigo";Comprobar 'Eliminar cliente después de retirar dependencias' ($r.Codigo -eq 204);$codigo=$null
 Comprobar 'Se conserva el rol vendedor de la persona' (@(Listado 'api.Vendedor_Listar'|Where-Object CodigoVendedor -eq $vendedorPrueba).Count -eq 1)
 $r=Peticion GET "$base/$codigoAnterior";Comprobar 'Cliente inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Enviar PUT "$base/$codigoAnterior" $datos;Comprobar 'Editar cliente inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion DELETE "$base/$codigoAnterior";Comprobar 'Eliminar cliente inexistente devuelve 404' ($r.Codigo -eq 404)
 $r=Peticion GET "$base/0";Comprobar 'Código cero rechazado' ($r.Codigo -eq 400)
 # Re-add client role: existing contacts must be preserved.
 $r=Enviar POST $base $datos;if($r.Codigo -eq 201){$codigo=$r.Json.codigoCliente}
 Comprobar 'Reutilizar persona existente sin duplicarla' ($r.Codigo -eq 201 -and (Ficha).codigoPersona -eq $persona)
 Comprobar 'Reutilizar conserva contactos anteriores' ((Ficha).telefonos.Count -eq 2 -and (Ficha).direcciones.Count -eq 2)
 $r=Peticion DELETE "$base/$codigo";Comprobar 'Retirar cliente recreado' ($r.Codigo -eq 204);$codigo=$null
 $final=Peticion GET $base;Comprobar 'Clientes iniciales conservados' (($inicial.Json|ConvertTo-Json -Depth 20 -Compress) -ceq ($final.Json|ConvertTo-Json -Depth 20 -Compress))
 $estado='Correcto'
}finally{
 try{
  if($credito){[void](Procedimiento 'api.Credito_Eliminar' @{NumeroCredito=$credito})}
  if($garantia){[void](Procedimiento 'api.Garantia_Eliminar' @{CodigoGarantia=[int]$garantia})}
  if($lineaCreada){[void](Procedimiento 'api.Linea_Eliminar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1})}
  if($marcaId){[void](Procedimiento 'api.Marca_Eliminar' @{CodigoMarca=[int]$marcaId})}
  if($vendedorPrueba){[void](Procedimiento 'api.Vendedor_Eliminar' @{CodigoVendedor=[int]$vendedorPrueba})}
  foreach($clienteLimpio in @($codigo,$cliente2)|Where-Object {$_}){
   foreach($v in @(Listado 'api.DetalleReferencia_Listar'|Where-Object CodigoDeudor -eq $clienteLimpio)){
    if($v.CodigoReferencia -notin $referenciasPrueba){$referenciasPrueba.Add([int]$v.CodigoReferencia)}
    [void](Procedimiento 'api.DetalleReferencia_Eliminar' @{CodigoDeudor=[int]$clienteLimpio;CodigoReferencia=[int]$v.CodigoReferencia})
   }
   [void](Procedimiento 'api.Deudor_Eliminar' @{CodigoDeudor=[int]$clienteLimpio})
  }
  if($refPropia){[void](Procedimiento 'api.Referencia_Eliminar' @{CodigoReferencia=[int]$refPropia})}
  foreach($ref in @(Listado 'api.Referencia_Listar'|Where-Object CodigoReferencia -in $referenciasPrueba)){
   if($ref.CodigoPersona -notin $personasPrueba){$personasPrueba.Add([int]$ref.CodigoPersona)}
   [void](Procedimiento 'api.Referencia_Eliminar' @{CodigoReferencia=[int]$ref.CodigoReferencia})
  }
  foreach($p in @(Listado 'api.Persona_Listar'|Where-Object { $_.DPI -in @($dpi,$dpiFallido) })){
   if($p.CodigoPersona -notin $personasPrueba){$personasPrueba.Add([int]$p.CodigoPersona)}
  }
  foreach($personaLimpia in $personasPrueba){
   foreach($tabla in @('Telefono','Direccion')){
    foreach($contacto in @(Listado "api.${tabla}_Listar"|Where-Object CodigoPersona -eq $personaLimpia)){
     [void](Procedimiento "api.${tabla}_Eliminar" @{CodigoPersona=[int]$personaLimpia;Correlativo=[int]$contacto.Correlativo})
    }
   }
   [void](Procedimiento 'api.Persona_Eliminar' @{CodigoPersona=[int]$personaLimpia})
  }
  if($agenciaPrueba){[void](Procedimiento 'api.Agencia_Eliminar' @{CodigoAgencia=[int]$agenciaPrueba})}
  if($estado -eq 'Correcto'){Comprobar 'Personas iniciales conservadas después de limpieza' ($personasIniciales -ceq (@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 8 -Compress))}
 }catch{$estado='Fallido';throw}finally{
  if($null -ne $proceso){if(-not $proceso.HasExited){Stop-Process -Id $proceso.Id;$proceso.WaitForExit()};$proceso.Dispose()}
  [pscustomobject]@{Estado=$estado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 }
}
Write-Output "Comprobaciones correctas: $($pruebas.Count). Datos temporales retirados; los correlativos pueden tener saltos."
