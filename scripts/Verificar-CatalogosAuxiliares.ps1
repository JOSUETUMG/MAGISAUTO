# Requiere PowerShell 7 y una compilación previa. Solo escribe en MAGISAUTO_ValidacionV2.
param(
 [string]$Credencial='C:\Users\dfern\Documents\Codex\2026-09-12\hol\work\sql-credential.xml',
 [string]$SalidaCompilacion='bin\Auxiliares',
 [switch]$ConexionLocalSinCifrado,
 [string]$Node,
 [string]$ModulosNode
)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$salida=Join-Path $repo 'artifacts\verificacion-auxiliares'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial; $cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new(); $proceso=$null; $estado='Fallido'; $inicial=$null
$prefijo='CA'+[Guid]::NewGuid().ToString('N').Substring(0,12)
$codigo=Get-Random -Minimum 100000000 -Maximum 1000000000; $otro=$codigo+1
$creados=[Collections.Generic.List[object]]::new()
$catalogos=@(
 @('departamentos','Departamento','CodigoDepartamento','Municipio'),
 @('municipios','Municipio','CodigoMunicipio','Direccion'),
 @('tipos-telefono','TipoTelefono','CodigoTipoTelefono','Telefono'),
 @('tipos-direccion','TipoDireccion','CodigoTipoDireccion','Direccion'),
 @('tipos-garantia','TipoGarantia','CodigoTipoGarantia','Garantia'),
 @('tipos-referencia','TipoReferencia','CodigoTipoReferencia','DetalleReferencia'),
 @('tipos-pago','TipoPago','CodigoTipoPago','DetallePago')
)
function Query([string]$sql){
 $cmd=$cn.CreateCommand(); $cmd.CommandTimeout=30; $cmd.CommandText=$sql
 $ds=[Data.DataSet]::new(); $da=[Data.SqlClient.SqlDataAdapter]::new($cmd)
 try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}
}
function Comprobar([string]$nombre,[bool]$ok){
 if(-not $ok){throw "Falló: $nombre"}
 $pruebas.Add([pscustomobject]@{Prueba=$nombre;Resultado='Correcto'})
}
function Captura {
 $r=[ordered]@{}
 $tablas=(Query "SELECT t.name,STRING_AGG(CONVERT(nvarchar(max),QUOTENAME(c.name)),',') WITHIN GROUP(ORDER BY ic.key_ordinal) Clave FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id AND i.is_primary_key=1 JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE SCHEMA_NAME(t.schema_id)='dbo' GROUP BY t.name ORDER BY t.name;").Tables[0]
 Comprobar 'Instantánea incluye las 26 tablas' ($tablas.Rows.Count -eq 26)
 foreach($t in $tablas.Rows){
  $ds=Query "SELECT * FROM dbo.[$($t.name)] ORDER BY $($t.Clave) FOR JSON PATH,INCLUDE_NULL_VALUES;"
  $json=($ds.Tables[0].Rows|ForEach-Object{$_[0]}) -join ''
  $r[$t.name]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))
 };return ($r|ConvertTo-Json -Compress)
}
function Peticion([string]$metodo,[string]$ruta,[object]$datos=$null){
 $p=@{Uri="$url$ruta";Method=$metodo;NoProxy=$true;SkipHttpErrorCheck=$true;TimeoutSec=25}
 if($null -ne $datos){$p.ContentType='application/json; charset=utf-8';$p.Body=$datos|ConvertTo-Json -Depth 8 -Compress}
 $r=Invoke-WebRequest @p
 $texto=if($r.Content -is [byte[]]){[Text.Encoding]::UTF8.GetString($r.Content)}else{[string]$r.Content}
 $json=if($texto -and $r.Headers.'Content-Type' -match 'json'){$texto|ConvertFrom-Json}else{$null}
 return [pscustomobject]@{Codigo=[int]$r.StatusCode;Texto=$texto;Json=$json}
}
function Bien([string]$nombre,[string]$metodo,[string]$ruta,[object]$datos,[int]$codigoEsperado){
 $r=Peticion $metodo $ruta $datos
 Comprobar "$nombre (HTTP $codigoEsperado)" ($r.Codigo -eq $codigoEsperado)
 if($codigoEsperado -ge 400){Comprobar "$nombre sin detalles internos" ($r.Texto -notmatch 'Password|Server=|SqlException|stackTrace')}
 return $r
}
function Crear([string]$slug,[int]$id,[int]$dep=0){
 $d=@{codigo=$id;descripcion="  $prefijo $slug  "}
 if($dep){$d.codigoDepartamento=$dep}
 if($slug -eq 'tipos-pago'){$d.requiereReferencia=$false}
 # Registrar la propiedad del fixture antes de enviar: también cubre respuestas interrumpidas.
 $creados.Add([pscustomobject]@{Slug=$slug;Codigo=$id;Departamento=$dep})
 $r=Bien "Crear $slug" POST "$base/$slug" $d 201
 Comprobar "$slug conserva código y recorta descripción" ($r.Json.codigo -eq $id -and $r.Json.descripcion -ceq "$prefijo $slug")
 return $r
}
try{
 $cn.Open(); Comprobar 'Destino aislado confirmado' ((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -ceq 'MAGISAUTO_ValidacionV2')
 $inicial=Captura
 # La cuenta ya debe existir: esta prueba no modifica usuarios ni permisos.
 $local=Get-Content (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cs=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto); $cs['Initial Catalog']='MAGISAUTO_ValidacionV2'
 if($ConexionLocalSinCifrado){
  if($cs.DataSource -ne 'tcp:127.0.0.1,1433'){throw 'El modo sin cifrado solo admite el servidor loopback local.'}
  $cs['Encrypt']=$false
 }
 $limitada=[Data.SqlClient.SqlConnection]::new($cs.ConnectionString)
 try{
  $limitada.Open();$cmd=$limitada.CreateCommand();$cmd.CommandText='SELECT * FROM dbo.Departamento';$negado=$false
  try{[void]$cmd.ExecuteScalar()}catch [Data.SqlClient.SqlException]{$negado=$_.Exception.Number -eq 229}
  Comprobar 'Cuenta API sin SELECT directo de tablas (229)' $negado
 }finally{$limitada.Dispose()}
 foreach($c in $catalogos){
  Comprobar "Código reservado libre en $($c[1])" ((Query "SELECT COUNT(*) FROM dbo.[$($c[1])] WHERE [$($c[2])] IN($codigo,$otro)").Tables[0].Rows[0][0] -eq 0)
 }
 $tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop();$url="http://127.0.0.1:$puerto"; $base='/api/catalogos/auxiliares'
 $vars=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto');$antes=@{}
 foreach($v in $vars){$antes[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{
  $env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development';$env:ConnectionStrings__MagisAuto=$cs.ConnectionString
  $dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
  $proceso=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')
 }finally{foreach($v in $vars){[Environment]::SetEnvironmentVariable($v,$antes[$v],'Process')};$local=$null;$cs=$null}
 $iniciado=$false;for($i=0;$i -lt 40;$i++){try{if((Peticion GET '/api/salud').Codigo -eq 200){$iniciado=$true;break}}catch{};Start-Sleep -Milliseconds 200}
 Comprobar 'API temporal disponible' $iniciado
 $defs=(Bien 'Metadatos' GET $base $null 200)
 Comprobar 'Siete catálogos públicos sin nombres internos de SP' ($defs.Json.Count -eq 7 -and $defs.Texto -notmatch '"entidad"|"clave"|api\.Departamento')
 foreach($ruta in @('/auxiliares.html','/auxiliares.css','/auxiliares.js')){[void](Bien "Recurso $ruta" GET $ruta $null 200)}
 foreach($pagina in @('index','lineas','agencias','vendedores','clientes','fiadores','vehiculos','creditos','pagos','reportes')){
  $r=Bien "Página $pagina" GET "/$pagina.html" $null 200
  Comprobar "Navegación $pagina a auxiliares" ($r.Texto.Contains('href="/auxiliares.html"'))
 }
 [void](Crear 'departamentos' $codigo);[void](Crear 'departamentos' $otro)
 foreach($c in $catalogos){
  $slug=$c[0];$tabla=$c[1];$clave=$c[2];$dep=if($slug -eq 'municipios'){$codigo}else{0}
  if($slug -ne 'departamentos'){[void](Crear $slug $codigo $dep)}
  $q=if($dep){"?codigoDepartamento=$dep"}else{''};$ruta="$base/$slug/$codigo$q"
  $d=@{codigo=$codigo;descripcion="$prefijo duplicado"};if($dep){$d.codigoDepartamento=$dep};if($slug -eq 'tipos-pago'){$d.requiereReferencia=$false}
  [void](Bien "Duplicado $slug" POST "$base/$slug" $d 409)
  $r=(Bien "Buscar $slug" GET "$base/${slug}?criterio=$prefijo" $null 200).Json
  Comprobar "Búsqueda devuelve código propio $slug" ($codigo -in $r.codigo)
  $d=@{descripcion="$prefijo modificado"};if($slug -eq 'tipos-pago'){$d.requiereReferencia=$true}
  [void](Bien "Editar $slug" PUT $ruta $d 200)
  $r=(Bien "Listar $slug" GET "$base/$slug$q" $null 200).Json
  $fila=@($r|Where-Object{$_.codigo -eq $codigo})
  Comprobar "Persistencia edición $slug" ($fila.Count -eq 1 -and $fila[0].descripcion -ceq "$prefijo modificado")
  if($slug -eq 'tipos-pago'){
   Comprobar 'Referencia bancaria true persistida' ($fila[0].requiereReferencia -eq $true)
   [void](Bien 'Cambiar referencia a false' PUT $ruta @{descripcion="$prefijo modificado";requiereReferencia=$false} 200)
   Comprobar 'False persistido en SQL' ((Query "SELECT RequiereReferencia FROM dbo.TipoPago WHERE CodigoTipoPago=$codigo").Tables[0].Rows[0][0] -eq $false)
  }
  $falta="$base/$slug/2147483647$q"
  [void](Bien "Editar ausente $slug" PUT $falta $d 404);[void](Bien "Eliminar ausente $slug" DELETE $falta $null 404)
  $d.descripcion=' ';[void](Bien "Descripción vacía $slug" PUT $ruta $d 400)
  $d.descripcion='x'*129;[void](Bien "Descripción larga $slug" PUT $ruta $d 400)
  # Usar un registro previamente referenciado: la FK impide cualquier borrado.
  $depSelect=if($dep){',p.CodigoDepartamento'}else{''}
  $depJoin=if($dep){' AND h.CodigoDepartamento=p.CodigoDepartamento'}else{''}
  $usado=(Query "SELECT TOP(1) p.[$clave] Codigo$depSelect FROM dbo.[$tabla] p WHERE EXISTS(SELECT 1 FROM dbo.[$($c[3])] h WHERE h.[$clave]=p.[$clave]$depJoin) ORDER BY p.[$clave];").Tables[0]
  Comprobar "Existe dependencia de ensayo para $slug" ($usado.Rows.Count -eq 1)
  $qd=if($dep){"?codigoDepartamento=$($usado.Rows[0].CodigoDepartamento)"}else{''}
  [void](Bien "Protección FK $slug" DELETE "$base/$slug/$($usado.Rows[0].Codigo)$qd" $null 409)
 }
 # Clave compuesta: el mismo código puede pertenecer a otro departamento.
 [void](Crear 'municipios' $codigo $otro)
 $a=(Bien 'Filtrar primer departamento' GET "$base/municipios?codigoDepartamento=$codigo&criterio=$prefijo" $null 200).Json
 $b=(Bien 'Filtrar segundo departamento' GET "$base/municipios?codigoDepartamento=$otro&criterio=$prefijo" $null 200).Json
 Comprobar 'Municipios con mismo código siguen independientes' ($a.Count -eq 1 -and $b.Count -eq 1 -and $a[0].descripcion -cne $b[0].descripcion)
 [void](Bien 'Eliminar solo segundo municipio' DELETE "$base/municipios/${codigo}?codigoDepartamento=$otro" $null 204)
 Comprobar 'Municipio del primer departamento conservado' ((Query "SELECT COUNT(*) FROM dbo.Municipio WHERE CodigoDepartamento=$codigo AND CodigoMunicipio=$codigo").Tables[0].Rows[0][0] -eq 1)
 foreach($caso in @(
  @('GET',"$base/inexistente",$null,404),
  @('GET',"$base/departamentos?criterio=",$null,400),
  @('GET',"$base/departamentos?criterio=$('x'*201)",$null,400),
  @('GET',"$base/departamentos?procedimiento=dbo.Persona",$null,400),
  @('GET',"$base/departamentos?criterio=a&criterio=b",$null,400),
  @('GET',"$base/departamentos?codigoDepartamento=1",$null,400),
  @('GET',"$base/municipios?codigoDepartamento=",$null,400),
  @('GET',"$base/municipios?codigoDepartamento=-1",$null,400),
  @('GET',"$base/municipios?codigoDepartamento=abc",$null,400),
  @('DELETE',"$base/municipios/$codigo",$null,400),
  @('POST',"$base/municipios",@{codigo=$otro;descripcion='Prueba'},400),
  @('POST',"$base/municipios",@{codigo=$otro;codigoDepartamento=2147483647;descripcion='Prueba'},409),
  @('POST',"$base/departamentos",@{codigo=0;descripcion='Prueba'},400),
  @('POST',"$base/departamentos",@{descripcion='Prueba'},400),
  @('POST',"$base/departamentos",@{codigo=$codigo;descripcion='Prueba';requiereReferencia=$false},400),
  @('POST',"$base/departamentos",@{codigo=$codigo;descripcion='Prueba';codigoDepartamento=1},400),
  @('POST',"$base/tipos-pago",@{codigo=$codigo;descripcion='Prueba'},400),
  @('PUT',"$base/departamentos/$codigo",@{codigo=$otro;descripcion='Prueba'},400),
  @('PUT',"$base/departamentos/$codigo",@{descripcion='Prueba';procedimiento='dbo.Persona'},400),
  @('DELETE',"$base/departamentos/${codigo}?codigoDepartamento=1",$null,400),
  @('DELETE',"$base/municipios/${codigo}?codigoDepartamento=$codigo&codigoDepartamento=$otro",$null,400)
 )){[void](Bien "Validación $($caso[0]) $($caso[1])" $caso[0] $caso[1] $caso[2] $caso[3])}
 $inyeccion=[Uri]::EscapeDataString("'; DELETE FROM dbo.Departamento;--")
 $r=Bien 'Búsqueda se trata como texto' GET "$base/departamentos?criterio=$inyeccion" $null 200
 Comprobar 'Búsqueda de texto SQL sin coincidencias' ($r.Json.Count -eq 0)
 # Eliminar hijos antes de padres; todos son fixtures propios de esta ejecución.
 foreach($f in @($creados|Sort-Object @{Expression={if($_.Slug -eq 'departamentos'){1}else{0}}})){
  if($f.Slug -eq 'municipios' -and $f.Departamento -eq $otro){continue}
  $q=if($f.Departamento){"?codigoDepartamento=$($f.Departamento)"}else{''}
  [void](Bien "Eliminar propio $($f.Slug) $($f.Codigo)" DELETE "$base/$($f.Slug)/$($f.Codigo)$q" $null 204)
 }
 if($Node){
  $antesNode=$env:NODE_PATH
  try{
   if($ModulosNode){$env:NODE_PATH=$ModulosNode}
   & $Node (Join-Path $PSScriptRoot 'verificar-auxiliares-ui.cjs') $url $salida
   Comprobar 'Recorrido de navegador completado' ($LASTEXITCODE -eq 0)
  }finally{$env:NODE_PATH=$antesNode}
 }
 $estado='Correcto'
}finally{
 if($proceso -and -not $proceso.HasExited){Stop-Process -Id $proceso.Id}
 try{
  if($cn.State -eq 'Open' -and $inicial){
   # Retira solo filas con código y marca propios, incluso si una aserción falló.
   foreach($f in @($creados|Sort-Object @{Expression={if($_.Slug -eq 'departamentos'){1}else{0}}})){
    $c=$catalogos|Where-Object{$_[0] -eq $f.Slug};$dep=if($f.Departamento){" AND CodigoDepartamento=$($f.Departamento)"}else{''}
    [void](Query "IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1; DELETE FROM dbo.[$($c[1])] WHERE [$($c[2])]=$($f.Codigo)$dep AND Descripcion LIKE '$prefijo%';")
   }
   Comprobar 'Las 26 tablas conservan todos sus datos previos' ((Captura) -ceq $inicial)
  }
 }catch{$estado='Fallido';throw}finally{
  $cn.Dispose()
  [pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';Fecha=(Get-Date -Format o);ConexionLocalSinCifrado=[bool]$ConexionLocalSinCifrado;NavegadorSolicitado=[bool]$Node;Pruebas=$pruebas}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $salida 'resultado.json') -Encoding UTF8
 }
}
Write-Output "Auxiliares: $($pruebas.Count) comprobaciones correctas."
