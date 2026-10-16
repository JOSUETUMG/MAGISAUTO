# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Crea fichas temporales propias y las retira al finalizar.
param([string]$Credencial='C:\Users\dfern\Documents\Codex\2026-09-12\hol\work\sql-credential.xml',[string]$SalidaCompilacion='bin\ConsultasIntegradas')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent;$api=Join-Path $repo 'src\MAGISAUTO.API';$salida=Join-Path $repo 'artifacts\verificacion-consultas-integradas'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new();$proceso=$null;$estado='Fallido';$creada=$null
function Comprobar([string]$nombre,[bool]$ok){if(-not $ok){throw "Falló: $nombre"};$pruebas.Add([pscustomobject]@{Prueba=$nombre;Resultado='Correcto'})}
function Query([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$da=[Data.SqlClient.SqlDataAdapter]::new($cmd);$ds=[Data.DataSet]::new();try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}}
function Captura{
 $r=[ordered]@{};$tablas=(Query "SELECT t.name,STRING_AGG(QUOTENAME(c.name),',') WITHIN GROUP(ORDER BY ic.key_ordinal) Clave FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id AND i.is_primary_key=1 JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE SCHEMA_NAME(t.schema_id)='dbo' GROUP BY t.name ORDER BY t.name;").Tables[0]
 Comprobar 'Instantánea incluye 26 tablas' ($tablas.Rows.Count -eq 26)
 foreach($t in $tablas.Rows){$json=((Query "SELECT * FROM dbo.[$($t.name)] ORDER BY $($t.Clave) FOR JSON PATH, INCLUDE_NULL_VALUES;").Tables[0].Rows|ForEach-Object{$_[0]}) -join '';$r[$t.name]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))};return ($r|ConvertTo-Json -Compress)
}
function Peticion([string]$metodo,[string]$ruta,[object]$datos=$null){
 $p=@{Uri="$url$ruta";Method=$metodo;NoProxy=$true;SkipHttpErrorCheck=$true;TimeoutSec=20}
 if($null -ne $datos){$p.ContentType='application/json; charset=utf-8';$p.Body=$datos|ConvertTo-Json -Compress}
 $r=Invoke-WebRequest @p
 $texto=if($r.Content -is [byte[]]){[Text.Encoding]::UTF8.GetString($r.Content)}else{[string]$r.Content}
 $json=if($texto -and $r.Headers.'Content-Type' -match 'json'){$texto|ConvertFrom-Json -AsHashtable}else{$null}
 [pscustomobject]@{Codigo=[int]$r.StatusCode;Texto=$texto;Json=$json}
}

try{
 $cn.Open();Comprobar 'Destino aislado confirmado' ((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -ceq 'MAGISAUTO_ValidacionV2');$antes=Captura
 $local=Get-Content (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json;$cs=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto);$cs['Initial Catalog']='MAGISAUTO_ValidacionV2'
 $tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop();$url="http://127.0.0.1:$puerto";$vars=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto');$prev=@{};foreach($v in $vars){$prev[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{$env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development';$env:ConnectionStrings__MagisAuto=$cs.ConnectionString;$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll";$proceso=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')}finally{foreach($v in $vars){[Environment]::SetEnvironmentVariable($v,$prev[$v],'Process')}}
 $listo=$false;for($i=0;$i -lt 40;$i++){try{if((Peticion GET '/api/salud').Codigo -eq 200){$listo=$true;break}}catch{};Start-Sleep -Milliseconds 200};Comprobar 'API temporal disponible' $listo
 $base='/api/consultas-integradas'
 $catalogo=Peticion GET $base
 Comprobar 'Seis consultas disponibles' ($catalogo.Codigo -eq 200 -and $catalogo.Json.Count -eq 6)
 $entidades=@{personas='Persona';telefonos='Telefono';direcciones='Direccion';referencias='Referencia';'vinculos-referencias'='DetalleReferencia';'fiadores-creditos'='CreditoFiador'}
 foreach($id in $entidades.Keys){
  $tabla=$entidades[$id];$r=Peticion GET "$base/$id"
  Comprobar "$id listado coincide con todas las filas SQL" ($r.Codigo -eq 200 -and $r.Json.filas.Count -eq (Query "SELECT COUNT(*) FROM dbo.[$tabla]").Tables[0].Rows[0][0])
  Comprobar "$id conserva columnas aun sin resultados" ($r.Json.columnas.Count -gt 0)
  if($r.Json.filas.Count -gt 0){
   $clave=$r.Json.columnas[0].nombre;$valor=[string]$r.Json.filas[0][$clave]
   $busqueda=Peticion GET "$base/${id}?criterio=$([uri]::EscapeDataString($valor))"
   Comprobar "$id búsqueda encuentra clave existente" ($busqueda.Codigo -eq 200 -and @($busqueda.Json.filas|Where-Object { [string]$_[$clave] -ceq $valor }).Count -gt 0)
  }
  $vacio=Peticion GET "$base/${id}?criterio=ZZZ_NO_EXISTE_4D774E"
  Comprobar "$id sin resultados" ($vacio.Codigo -eq 200 -and $vacio.Json.filas.Count -eq 0)
  foreach($f in @('?criterio=','?criterio=a&criterio=b','?otro=x',('?criterio='+('x'*61)))){Comprobar "$id rechaza filtro $f" ((Peticion GET "$base/$id$f").Codigo -eq 400)}
  $comodin=Peticion GET "$base/${id}?criterio=%25"
  Comprobar "$id porcentaje literal no devuelve todo" ($comodin.Codigo -eq 200 -and @($comodin.Json.filas|Where-Object { -not (@($_.Values|Where-Object { [string]$_ -like '*%*' }).Count) }).Count -eq 0)
  Comprobar "$id no admite escritura" ((Peticion POST "$base/$id" @{}).Codigo -eq 405)
 }
 Comprobar 'Entidad ajena rechazada' ((Peticion GET "$base/ParametroCredito").Codigo -eq 404)
 Comprobar 'Página servida' ((Peticion GET '/consultas-integradas.html').Codigo -eq 200)
 Comprobar 'Acceso desde reportes' ((Peticion GET '/reportes.html').Texto.Contains('/consultas-integradas.html'))
 # Solo se crean fichas propias en la base aislada; nunca se borran registros preexistentes.
 $marca='BORRADO-'+[Guid]::NewGuid().ToString('N')
 $personaPrueba=[int](Query "IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1; INSERT dbo.Persona(PrimerNombre,PrimerApellido) OUTPUT INSERTED.CodigoPersona VALUES(N'$marca',N'Prueba');").Tables[0].Rows[0][0]
 $referenciaPrueba=[int](Query "INSERT dbo.Referencia(CodigoPersona,LugarTrabajo) OUTPUT INSERTED.CodigoReferencia VALUES($personaPrueba,N'$marca');").Tables[0].Rows[0][0]
 Comprobar 'Persona con referencia no se elimina' ((Peticion DELETE "$base/personas/$personaPrueba").Codigo -eq 409)
 $deudor=[int](Query 'SELECT TOP(1) CodigoDeudor FROM dbo.Deudor ORDER BY CodigoDeudor').Tables[0].Rows[0][0]
 $tipo=[int](Query 'SELECT TOP(1) CodigoTipoReferencia FROM dbo.TipoReferencia ORDER BY CodigoTipoReferencia').Tables[0].Rows[0][0]
 [void](Query "INSERT dbo.DetalleReferencia(CodigoDeudor,CodigoReferencia,CodigoTipoReferencia,ParentescoRelacion) VALUES($deudor,$referenciaPrueba,$tipo,N'$marca');")
 Comprobar 'Referencia vinculada no se elimina' ((Peticion DELETE "$base/referencias/$referenciaPrueba").Codigo -eq 409)
 Comprobar 'Vínculo protegido se conserva' ((Query "SELECT COUNT(*) FROM dbo.DetalleReferencia WHERE CodigoReferencia=$referenciaPrueba").Tables[0].Rows[0][0] -eq 1)
 [void](Query "DELETE dbo.DetalleReferencia WHERE CodigoReferencia=$referenciaPrueba;")
 Comprobar 'Referencia libre se elimina' ((Peticion DELETE "$base/referencias/$referenciaPrueba").Codigo -eq 204)
 Comprobar 'Eliminar referencia conserva persona' ((Query "SELECT COUNT(*) FROM dbo.Persona WHERE CodigoPersona=$personaPrueba").Tables[0].Rows[0][0] -eq 1)
 Comprobar 'Repetir eliminación devuelve inexistente' ((Peticion DELETE "$base/referencias/$referenciaPrueba").Codigo -eq 404)
 $tipoTel=[int](Query 'SELECT TOP(1) CodigoTipoTelefono FROM dbo.TipoTelefono ORDER BY CodigoTipoTelefono').Tables[0].Rows[0][0]
 [void](Query "INSERT dbo.Telefono(CodigoPersona,Correlativo,CodigoTipoTelefono,Numero) VALUES($personaPrueba,1,$tipoTel,'55555555');")
 Comprobar 'Persona con teléfono no se elimina' ((Peticion DELETE "$base/personas/$personaPrueba").Codigo -eq 409)
 [void](Query "DELETE dbo.Telefono WHERE CodigoPersona=$personaPrueba;")
 $ubicacion=(Query 'SELECT TOP(1) CodigoDepartamento,CodigoMunicipio FROM dbo.Municipio ORDER BY CodigoDepartamento,CodigoMunicipio').Tables[0].Rows[0]
 $tipoDir=[int](Query 'SELECT TOP(1) CodigoTipoDireccion FROM dbo.TipoDireccion ORDER BY CodigoTipoDireccion').Tables[0].Rows[0][0]
 [void](Query "INSERT dbo.Direccion(CodigoPersona,Correlativo,CodigoTipoDireccion,CodigoDepartamento,CodigoMunicipio,Detalle) VALUES($personaPrueba,1,$tipoDir,$($ubicacion.CodigoDepartamento),$($ubicacion.CodigoMunicipio),N'$marca');")
 Comprobar 'Persona con dirección no se elimina' ((Peticion DELETE "$base/personas/$personaPrueba").Codigo -eq 409)
 [void](Query "DELETE dbo.Direccion WHERE CodigoPersona=$personaPrueba;")
 foreach($rol in @('Deudor','Fiador')){
  [void](Query "INSERT dbo.[$rol](CodigoPersona) VALUES($personaPrueba);")
  Comprobar "Persona con rol $rol no se elimina" ((Peticion DELETE "$base/personas/$personaPrueba").Codigo -eq 409)
  [void](Query "DELETE dbo.[$rol] WHERE CodigoPersona=$personaPrueba;")
 }
 $agencia=[int](Query 'SELECT TOP(1) CodigoAgencia FROM dbo.Agencia ORDER BY CodigoAgencia').Tables[0].Rows[0][0]
 [void](Query "INSERT dbo.Vendedor(CodigoPersona,CodigoEmpleado,CodigoAgencia) VALUES($personaPrueba,'$($marca.Substring(0,30))',$agencia);")
 Comprobar 'Persona con rol vendedor no se elimina' ((Peticion DELETE "$base/personas/$personaPrueba").Codigo -eq 409)
 [void](Query "DELETE dbo.Vendedor WHERE CodigoPersona=$personaPrueba;")
 Comprobar 'Persona libre se elimina' ((Peticion DELETE "$base/personas/$personaPrueba").Codigo -eq 204)
 Comprobar 'Persona eliminada no existe en SQL' ((Query "SELECT COUNT(*) FROM dbo.Persona WHERE CodigoPersona=$personaPrueba").Tables[0].Rows[0][0] -eq 0)
 Comprobar 'Persona inexistente devuelve 404' ((Peticion DELETE "$base/personas/$personaPrueba").Codigo -eq 404)
 Comprobar 'Código negativo rechazado' ((Peticion DELETE "$base/personas/-1").Codigo -eq 400)
 Comprobar 'Eliminación ajena rechazada' ((Peticion DELETE "$base/telefonos/1").Codigo -eq 404)
 Comprobar 'Filtros en eliminación rechazados' ((Peticion DELETE "$base/personas/1?criterio=x").Codigo -eq 400)
 $estado='Correcto'
}finally{
 if($personaPrueba -and $cn.State -eq 'Open'){
  [void](Query "IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1; IF EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=$personaPrueba AND PrimerNombre=N'$marca') BEGIN DELETE dbo.DetalleReferencia WHERE CodigoReferencia IN(SELECT CodigoReferencia FROM dbo.Referencia WHERE CodigoPersona=$personaPrueba); DELETE dbo.Referencia WHERE CodigoPersona=$personaPrueba; DELETE dbo.Telefono WHERE CodigoPersona=$personaPrueba; DELETE dbo.Direccion WHERE CodigoPersona=$personaPrueba; DELETE dbo.Deudor WHERE CodigoPersona=$personaPrueba; DELETE dbo.Fiador WHERE CodigoPersona=$personaPrueba; DELETE dbo.Vendedor WHERE CodigoPersona=$personaPrueba; DELETE dbo.Persona WHERE CodigoPersona=$personaPrueba; END;")
 }
 if($proceso){if(-not $proceso.HasExited){$proceso.Kill($true);$proceso.WaitForExit()};$proceso.Dispose()}
 if($cn.State -eq 'Open'){$despues=Captura;Comprobar 'Consultas conservan las 26 tablas' ($antes -ceq $despues);$cn.Close()};$cn.Dispose()
 $resultado=[pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';Pruebas=$pruebas};$resultado|ConvertTo-Json -Depth 6|Set-Content (Join-Path $salida 'resultado.json') -Encoding UTF8
}
