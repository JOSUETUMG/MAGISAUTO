# Requiere PowerShell 7. Solo modifica registros temporales creados por este ensayo.
param([string]$SalidaCompilacion='bin\Debug\net10.0')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
$salida=Join-Path $repo 'artifacts\verificacion-fiadores'
[void](New-Item -ItemType Directory -Path $salida -Force)
if(-not(Test-Path -LiteralPath $dll)){throw 'Compila primero la API.'}
$pruebas=[Collections.Generic.List[object]]::new()
$proceso=$null;$creada=$false;$persona=$null;$vendedor=$null;$estado='Fallido'
$vinculo=$false;$personasPrueba=[Collections.Generic.List[int]]::new();$codigo=$null;$agencia=$null;$agencia2=$null;$persona=$null;$deudor=$null;$garantia=$null;$credito=$null;$marcaId=$null;$lineaCreada=$false
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

 $base='/api/fiadores'
 $inicial=Peticion GET $base
 Comprobar 'Listado de fiadores disponible' ($inicial.Codigo -eq 200)
 $personasIniciales=@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 10 -Compress
 $clientesIniciales=(Peticion GET '/api/clientes').Json|ConvertTo-Json -Depth 20 -Compress
 $contactosIniciales=@(Listado 'api.Telefono_Listar';Listado 'api.Direccion_Listar')|ConvertTo-Json -Depth 10 -Compress
 $cat=(Peticion GET "$base/catalogos").Json
 Comprobar 'Catálogos de contactos y ubicación disponibles' ($cat.TipoTelefono.Count -gt 0 -and $cat.TipoDireccion.Count -gt 0 -and $cat.Municipio.Count -gt 0)
 $municipio=$cat.Municipio[0]
 function TelefonoNuevo([string]$numero='55551234'){ @{correlativo=0;codigoTipoTelefono=[int]$cat.TipoTelefono[0].codigoTipoTelefono;numero=$numero} }
 function DireccionNueva { @{correlativo=0;codigoTipoDireccion=[int]$cat.TipoDireccion[0].codigoTipoDireccion;codigoDepartamento=[int]$municipio.codigoDepartamento;codigoMunicipio=[int]$municipio.codigoMunicipio;detalle='Dirección ficticia de ensayo'} }
 function Ficha { (Peticion GET "$base/$codigo").Json }
 foreach($ruta in @('/','/lineas.html','/agencias.html','/vendedores.html','/clientes.html','/fiadores.html')){
  $r=Peticion GET $ruta;Comprobar "Pantalla y enlace a Fiadores: $ruta" ($r.Codigo -eq 200 -and $r.Texto.Contains('/fiadores.html'))
 }
 $r=Peticion GET '/fiadores.html';Comprobar 'Recursos correctos en HTML' ($r.Texto.Contains('/fiadores.js') -and $r.Texto.Contains('/clientes.css') -and -not $r.Texto.Contains('fiadors'))
 foreach($ruta in @('/fiadores.js','/clientes.css')){Comprobar "Recurso disponible $ruta" ((Peticion GET $ruta).Codigo -eq 200)}
 $nit='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,12)
 $datos=@{dpi=$dpi;nit=$nit;primerNombre='  Fiador  ';segundoNombre=' ';primerApellido='  Ensayo  ';correoElectronico='fiador@example.invalid';telefonos=@();direcciones=@()}
 $r=Peticion POST $base $datos;if($r.Codigo -eq 201){$codigo=$r.Json.codigoFiador}
 Comprobar 'Registrar fiador sin teléfono como incompleto' ($r.Codigo -eq 201 -and $codigo -gt 0)
 $f=Ficha;$persona=$f.codigoPersona;$personasPrueba.Add([int]$persona)
 Comprobar 'Nombre recortado y teléfono pendiente' ($f.primerNombre -ceq 'Fiador' -and $null -eq $f.segundoNombre -and $f.faltantes.Count -eq 1)
 $r=Peticion POST $base $datos;Comprobar 'Persona ya fiadora rechazada' ($r.Codigo -eq 409)
 $mal=$datos.Clone();$mal.dpi=$dpiFallido
 Comprobar 'NIT duplicado rechazado' ((Peticion POST $base $mal).Codigo -eq 409)
 Comprobar 'Creación fallida no deja persona' (@(Listado 'api.Persona_Listar'|Where-Object DPI -eq $dpiFallido).Count -eq 0)
 foreach($campo in @('nit','primerNombre','primerApellido','correoElectronico')){
  $mal=$datos.Clone();$mal[$campo]='  ';Comprobar "Campo vacío rechazado: $campo" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 }
 foreach($campo in @('telefonos','direcciones')){
  $mal=$datos.Clone();$mal[$campo]=$null;Comprobar "Colección nula rechazada: $campo" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
  $mal[$campo]=@($null);Comprobar "Contacto nulo rechazado: $campo" ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 }
 $mal=$datos.Clone();$mal.dpi='123';Comprobar 'Formato de DPI rechazado' ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 $mal.dpi=$dpiFallido;Comprobar 'DPI inmutable al editar' ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 409)
 $mal=$datos.Clone();$mal.correoElectronico='sin-formato';Comprobar 'Correo inválido rechazado' ((Peticion PUT "$base/$codigo" $mal).Codigo -eq 400)
 $f.telefonos=@((TelefonoNuevo),(TelefonoNuevo '55555678'));$f.direcciones=@((DireccionNueva),(DireccionNueva))
 Comprobar 'Guardar múltiples contactos' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 204)
 $f=Ficha;Comprobar 'Recarga conserva contactos y satisface teléfono' ($f.telefonos.Count -eq 2 -and $f.direcciones.Count -eq 2 -and $f.faltantes.Count -eq 0)
 $anterior=$f|ConvertTo-Json -Depth 20 -Compress
 $f.primerNombre='NO PERSISTIR';$f.direcciones[0].codigoMunicipio=2147483647
 Comprobar 'Municipio inválido rechazado' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 409)
 Comprobar 'Reversión completa de cambios anteriores al error' ((Ficha|ConvertTo-Json -Depth 20 -Compress) -ceq $anterior)
 $f=Ficha;$f.telefonos[1].correlativo=$f.telefonos[0].correlativo
 Comprobar 'Correlativo repetido rechazado' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 400)
 $f=Ficha;$f.telefonos[0].correlativo=32766
 Comprobar 'Contacto ajeno o inexistente rechazado' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 409)
 $f=Ficha;$f.telefonos[0].numero=' 123456 ';Comprobar 'Teléfono corto tras recorte rechazado' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 400)
 $f=Ficha;$f.segundoNombre='Editado';$f.telefonos[0].numero='55550000';$f.direcciones[0].detalle='Dirección editada'
 Comprobar 'Editar persona y contactos' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 204)
 $f=Ficha;Comprobar 'Persisten edición y contactos' ($f.nombreCompleto -ceq 'Fiador Editado Ensayo' -and $f.telefonos[0].numero -ceq '55550000' -and $f.direcciones[0].detalle -ceq 'Dirección editada')
 foreach($criterio in @($codigo.ToString(),$dpi,$nit,'Editado','fiador@example.invalid')){
  $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString($criterio))";Comprobar "Búsqueda literal por $criterio" ($r.Codigo -eq 200 -and $codigo -in @($r.Json.codigoFiador))
 }
 $r=Peticion GET "${base}?criterio=$([Uri]::EscapeDataString("' OR 1=1--"))";Comprobar 'Texto SQL se trata como búsqueda literal' ($r.Codigo -eq 200 -and @($r.Json).Count -eq 0)
 Comprobar 'Criterio vacío rechazado' ((Peticion GET "${base}?criterio=").Codigo -eq 400)
 Comprobar 'Criterio demasiado largo rechazado' ((Peticion GET "${base}?criterio=$('x'*201)").Codigo -eq 400)
 # Comparte la misma persona con un cliente para comprobar conservación de roles.
 [void](Procedimiento 'api.Persona_Actualizar' @{CodigoPersona=[int]$persona;DPI=$dpi;NIT=$nit;PrimerNombre='Fiador';SegundoNombre='Editado';PrimerApellido='Ensayo';CorreoElectronico='fiador@example.invalid';FechaNacimiento=[datetime]'1990-01-01';Genero='F'})
 $deudor=Procedimiento 'api.Deudor_Insertar' @{CodigoPersona=[int]$persona}
 $f=Ficha;$f.segundoNombre='Compartido';Comprobar 'Editar fiador que también es cliente' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 204)
 $p=@(Listado 'api.Persona_Listar'|Where-Object CodigoPersona -eq $persona)[0]
 Comprobar 'Conservar nacimiento y género no editados en Fiadores' ($p.FechaNacimiento -eq [datetime]'1990-01-01' -and $p.Genero -ceq 'F')
 Comprobar 'Cliente comparte los cambios de nombre' ((Peticion GET "/api/clientes/$deudor").Json.segundoNombre -ceq 'Compartido')
 $f=Ficha;$f.telefonos=@();$f.direcciones=@();Comprobar 'Retirar contactos compartidos explícitamente' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 204)
 Comprobar 'Quitar teléfonos vuelve a indicar pendiente' ((Ficha).faltantes.Count -eq 1 -and (Peticion GET "/api/clientes/$deudor").Json.telefonos.Count -eq 0)
 $f=Ficha;$f.telefonos=@((TelefonoNuevo));Comprobar 'Completar teléfono sin obligar dirección' ((Peticion PUT "$base/$codigo" $f).Codigo -eq 204 -and (Ficha).faltantes.Count -eq 0)
 # Crédito de otra persona: protege la relación real sin aprobar ni cobrar nada.
 $personaCredito=Procedimiento 'api.Persona_Insertar' @{DPI=$dpiFallido;NIT=('C'+$nit);PrimerNombre='Deudor';PrimerApellido='Temporal';CorreoElectronico='deudor@example.invalid';FechaNacimiento=[datetime]'1990-01-01'}
 $personasPrueba.Add([int]$personaCredito)
 $deudorCredito=Procedimiento 'api.Deudor_Insertar' @{CodigoPersona=[int]$personaCredito}
 $agencia=Procedimiento 'api.Agencia_Insertar' @{Nombre=$nombre;Region='Ensayo'}
 $vendedor=Procedimiento 'api.Vendedor_Insertar' @{CodigoPersona=[int]$personaCredito;CodigoAgencia=[int]$agencia;CodigoEmpleado=('ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14))}
 $marcaId=Get-Random -Minimum 100000000 -Maximum 2000000000
 [void](Procedimiento 'api.Marca_Insertar' @{CodigoMarca=[int]$marcaId;Descripcion=$nombre})
 [void](Procedimiento 'api.Linea_Insertar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1;Descripcion=$nombre});$lineaCreada=$true
 $garantia=Procedimiento 'api.Garantia_Insertar' @{VIN=('ENS'+[Guid]::NewGuid().ToString('N').Substring(0,14).ToUpper());CodigoMarca=[int]$marcaId;CodigoLinea=1;Anio=2026;ValorAgencia=[decimal]100000;CodigoTipoGarantia=1;EsNuevo=$true}
 $numero='ENS'+[Guid]::NewGuid().ToString('N').Substring(0,15)
 [void](Procedimiento 'api.Credito_Insertar' @{NumeroCredito=$numero;CodigoDeudor=[int]$deudorCredito;CodigoGarantia=[int]$garantia;CodigoVendedor=[int]$vendedor;Enganche=[decimal]20000});$credito=$numero
 [void](Procedimiento 'api.CreditoFiador_Insertar' @{NumeroCredito=$credito;CodigoFiador=[int]$codigo});$vinculo=$true
 $r=Peticion DELETE "$base/$codigo"
 Comprobar 'Crédito vinculado impide eliminar con mensaje específico' ($r.Codigo -eq 409 -and $r.Json.detail -ceq 'No se puede eliminar el fiador porque tiene créditos vinculados. El fiador se conserva.')
 Comprobar 'Fiador y vínculo permanecen después del rechazo' ((Peticion GET "$base/$codigo").Codigo -eq 200 -and @(Listado 'api.CreditoFiador_Listar'|Where-Object NumeroCredito -eq $credito).Count -eq 1)
 [void](Procedimiento 'api.CreditoFiador_Eliminar' @{NumeroCredito=$credito;CodigoFiador=[int]$codigo});$vinculo=$false
 $codigoAnterior=$codigo;Comprobar 'Eliminar rol sin créditos vinculados' ((Peticion DELETE "$base/$codigo").Codigo -eq 204);$codigo=$null
 Comprobar 'Eliminar fiador conserva cliente y contacto compartido' ((Peticion GET "/api/clientes/$deudor").Codigo -eq 200 -and @(Listado 'api.Telefono_Listar'|Where-Object CodigoPersona -eq $persona).Count -eq 1)
 foreach($metodo in @('GET','PUT','DELETE')){Comprobar "Fiador inexistente devuelve 404 en $metodo" ((Peticion $metodo "$base/$codigoAnterior" $(if($metodo -eq 'PUT'){$datos}else{$null})).Codigo -eq 404)}
 Comprobar 'Código cero rechazado' ((Peticion GET "$base/0").Codigo -eq 400)
 $datos.primerNombre='Fiador';$datos.segundoNombre='Compartido';$datos.primerApellido='Ensayo'
 foreach($campo in @('primerNombre','nit','correoElectronico')){
  $mal=$datos.Clone();$mal[$campo]=$(if($campo -eq 'correoElectronico'){'otro@example.invalid'}else{'Otro'})
  Comprobar "Reutilizar no reemplaza $campo existente" ((Peticion POST $base $mal).Codigo -eq 409)
 }
 $mal=$datos.Clone();$mal.telefonos=@((TelefonoNuevo));Comprobar 'Alta de rol no sustituye contactos existentes' ((Peticion POST $base $mal).Codigo -eq 409)
 $r=Peticion POST $base $datos;if($r.Codigo -eq 201){$codigo=$r.Json.codigoFiador}
 Comprobar 'Reutilizar persona por DPI sin duplicación' ($r.Codigo -eq 201 -and (Ficha).codigoPersona -eq $persona)
 Comprobar 'Reutilizar conserva teléfono existente' ((Ficha).telefonos.Count -eq 1)
 Comprobar 'Retirar rol recreado' ((Peticion DELETE "$base/$codigo").Codigo -eq 204);$codigo=$null
 $final=Peticion GET $base;Comprobar 'Fiadores iniciales conservados' (($inicial.Json|ConvertTo-Json -Depth 20 -Compress) -ceq ($final.Json|ConvertTo-Json -Depth 20 -Compress))
 $estado='Correcto'
}finally{
 try{
  if($vinculo){[void](Procedimiento 'api.CreditoFiador_Eliminar' @{NumeroCredito=$credito;CodigoFiador=[int]$codigo})}
  if($credito){[void](Procedimiento 'api.Credito_Eliminar' @{NumeroCredito=$credito})}
  if($garantia){[void](Procedimiento 'api.Garantia_Eliminar' @{CodigoGarantia=[int]$garantia})}
  if($lineaCreada){[void](Procedimiento 'api.Linea_Eliminar' @{CodigoMarca=[int]$marcaId;CodigoLinea=1})}
  if($marcaId){[void](Procedimiento 'api.Marca_Eliminar' @{CodigoMarca=[int]$marcaId})}
  if($vendedor){[void](Procedimiento 'api.Vendedor_Eliminar' @{CodigoVendedor=[int]$vendedor})}
  if($codigo){[void](Procedimiento 'api.Fiador_Eliminar' @{CodigoFiador=[int]$codigo})}
  foreach($id in @($deudor,$deudorCredito)|Where-Object {$_}){[void](Procedimiento 'api.Deudor_Eliminar' @{CodigoDeudor=[int]$id})}
  # Buscar únicamente los DPI generados por este ensayo para limpiar incluso fallos parciales.
  foreach($p in @(Listado 'api.Persona_Listar'|Where-Object { $_.DPI -in @($dpi,$dpiFallido) })){
   foreach($tabla in @('Telefono','Direccion')){
    foreach($contacto in @(Listado "api.${tabla}_Listar"|Where-Object CodigoPersona -eq $p.CodigoPersona)){
     [void](Procedimiento "api.${tabla}_Eliminar" @{CodigoPersona=[int]$p.CodigoPersona;Correlativo=[int]$contacto.Correlativo})
    }
   }
   [void](Procedimiento 'api.Persona_Eliminar' @{CodigoPersona=[int]$p.CodigoPersona})
  }
  if($agencia){[void](Procedimiento 'api.Agencia_Eliminar' @{CodigoAgencia=[int]$agencia})}
  if($estado -eq 'Correcto'){
   Comprobar 'Personas iniciales intactas tras limpieza' ($personasIniciales -ceq (@(Listado 'api.Persona_Listar')|ConvertTo-Json -Depth 10 -Compress))
   Comprobar 'Contactos iniciales intactos tras limpieza' ($contactosIniciales -ceq (@(Listado 'api.Telefono_Listar';Listado 'api.Direccion_Listar')|ConvertTo-Json -Depth 10 -Compress))
   Comprobar 'Expedientes de clientes iniciales intactos' ($clientesIniciales -ceq ((Peticion GET '/api/clientes').Json|ConvertTo-Json -Depth 20 -Compress))
  }
 }catch{$estado='Fallido';throw}finally{
  if($null -ne $proceso){if(-not $proceso.HasExited){Stop-Process -Id $proceso.Id;$proceso.WaitForExit()};$proceso.Dispose()}
  [pscustomobject]@{Estado=$estado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $salida 'resultado.json') -Encoding utf8
 }
}
Write-Output "Comprobaciones correctas: $($pruebas.Count). Datos temporales retirados; los correlativos pueden tener saltos."
