# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Conserva los datos anteriores.
param([Parameter(Mandatory)][string]$Credencial,[string]$SalidaCompilacion='bin\Parametros',[switch]$ConexionLocalSinCifrado)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$salida=Join-Path $repo 'artifacts\verificacion-parametros'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new();$proceso=$null;$estado='Fallido';$inicial=$null;$prefijo='PC'+[Guid]::NewGuid().ToString('N').Substring(0,10).ToUpper();$vin=$prefijo+'00001';$numero=$prefijo+'-01';$numero2=$prefijo+'-02';$numero3=$prefijo+'-03'
$originalActivo=$null
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
 # La validación de objeto usa una clave vacía en errors; PowerShell la admite como Hashtable.
 $json=if($texto -and $r.Headers.'Content-Type' -match 'json'){if([int]$r.StatusCode -ge 400){$texto|ConvertFrom-Json -AsHashtable}else{$texto|ConvertFrom-Json}}else{$null}
 return [pscustomobject]@{Codigo=[int]$r.StatusCode;Texto=$texto;Json=$json}
}
function Bien([string]$nombre,[string]$metodo,[string]$ruta,[object]$datos,[int]$codigoEsperado){
 $r=Peticion $metodo $ruta $datos
 Comprobar "$nombre (HTTP $codigoEsperado)" ($r.Codigo -eq $codigoEsperado)
 if($codigoEsperado -ge 400){Comprobar "$nombre sin detalles internos" ($r.Texto -notmatch 'Password|Server=|SqlException|stackTrace')}
 return $r
}
try{
 $cn.Open(); Comprobar 'Destino aislado confirmado' ((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -ceq 'MAGISAUTO_ValidacionV2')
 $inicial=Captura
 $activos=(Query "SELECT CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1").Tables[0]
 Comprobar 'Una configuración activa inicial' ($activos.Rows.Count -eq 1)
 $originalActivo=[int]$activos.Rows[0][0]
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
 $tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop();$url="http://127.0.0.1:$puerto"; $base='/api/parametros-credito'
 $vars=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto');$antes=@{}
 foreach($v in $vars){$antes[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{
  $env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development';$env:ConnectionStrings__MagisAuto=$cs.ConnectionString
  $dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
  $proceso=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')
 }finally{foreach($v in $vars){[Environment]::SetEnvironmentVariable($v,$antes[$v],'Process')};$local=$null;$cs=$null}
 $iniciado=$false;for($i=0;$i -lt 40;$i++){try{if((Peticion GET '/api/salud').Codigo -eq 200){$iniciado=$true;break}}catch{};Start-Sleep -Milliseconds 200}
 Comprobar 'API temporal disponible' $iniciado
 # Crear únicamente identidades y vehículo con prefijo aleatorio propio.
 [void](Query @"
 SET XACT_ABORT ON;
 BEGIN TRANSACTION;
 DECLARE @i int=1,@p int,@d int,@r int;
 WHILE @i<=6 BEGIN
  DECLARE @nit varchar(20)=CONCAT('$prefijo','-',@i),@dpi varchar(13)=CONCAT('996',RIGHT(CONCAT('000000000',ABS(CONVERT(bigint,CHECKSUM(NEWID())))),9),@i);
  EXEC api.Persona_Insertar @DPI=@dpi,@NIT=@nit,@PrimerNombre=N'Ensayo crédito',@PrimerApellido=N'$prefijo',@FechaNacimiento='19900101',@CorreoElectronico=N'prueba@example.invalid';
  SELECT @p=CodigoPersona FROM dbo.Persona WHERE NIT=@nit;
  EXEC api.Telefono_Insertar @CodigoPersona=@p,@Correlativo=1,@CodigoTipoTelefono=1,@Numero='00000000';
  EXEC api.Direccion_Insertar @CodigoPersona=@p,@Correlativo=1,@CodigoTipoDireccion=1,@CodigoDepartamento=21,@CodigoMunicipio=1,@Detalle=N'Ensayo aislado';
  IF @i=1 BEGIN EXEC api.Deudor_Insertar @CodigoPersona=@p; SELECT @d=CodigoDeudor FROM dbo.Deudor WHERE CodigoPersona=@p; END;
  IF @i=2 EXEC api.Vendedor_Insertar @CodigoEmpleado='$prefijo',@CodigoPersona=@p,@CodigoAgencia=1;
  IF @i=3 EXEC api.Fiador_Insertar @CodigoPersona=@p;
  IF @i>=4 BEGIN EXEC api.Referencia_Insertar @CodigoPersona=@p,@LugarTrabajo=N'Ensayo'; SELECT @r=CodigoReferencia FROM dbo.Referencia WHERE CodigoPersona=@p;
   IF @i<6 EXEC api.DetalleReferencia_Insertar @CodigoDeudor=@d,@CodigoReferencia=@r,@CodigoTipoReferencia=2,@ParentescoRelacion=N'Amistad'; END;
  SET @i+=1;
 END;
 EXEC api.Garantia_Insertar @VIN='$vin',@CodigoMarca=1,@CodigoLinea=1,@Anio=2026,@ValorAgencia=100000,@CodigoTipoGarantia=1,@EsNuevo=1;
 COMMIT;
"@)
 $ids=(Query "SELECT (SELECT CodigoDeudor FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE p.NIT='$prefijo-1') Cliente,(SELECT CodigoVendedor FROM dbo.Vendedor WHERE CodigoEmpleado='$prefijo') Vendedor,(SELECT CodigoFiador FROM dbo.Fiador f JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona WHERE p.NIT='$prefijo-3') Fiador,(SELECT CodigoGarantia FROM dbo.Garantia WHERE VIN='$vin') Vehiculo,(SELECT CodigoReferencia FROM dbo.Referencia r JOIN dbo.Persona p ON p.CodigoPersona=r.CodigoPersona WHERE p.NIT='$prefijo-6') Referencia;").Tables[0].Rows[0]
 $datos=@{numeroCredito=$numero;codigoDeudor=[int]$ids.Cliente;codigoGarantia=[int]$ids.Vehiculo;codigoVendedor=[int]$ids.Vendedor;enganche='20000.00';plazo=12;fiadoresRequeridos=1;fiadores=@([int]$ids.Fiador)}

 foreach($rutaRecurso in @('/parametros.html','/parametros.js','/parametros.css','/creditos.html','/creditos.js','/auxiliares.html')){[void](Bien "Recurso $rutaRecurso" GET $rutaRecurso $null 200)}
 $lista=(Bien 'Listado de configuraciones' GET $base $null 200).Json
 Comprobar 'Configuración activa devuelta en porcentaje' (@($lista|Where-Object activo).Count -eq 1 -and [decimal]($lista|Where-Object activo).manejoMensual -eq 25)
 $a=@{nombre="$prefijo A";tasaAnualPorcentaje='12.5';seguroAutoMensualPorcentaje='0.15';seguroVidaMensualPorcentaje='0.05';engancheMinimoPorcentaje='20';comisionPredeterminadaPorcentaje='2';depreciacionInicialPorcentaje='15';manejoMensual='25.00'}
 $idA=(Bien 'Crear configuración A' POST $base $a 201).Json.codigoParametro
 $nueva=@((Bien 'Buscar configuración propia' GET "${base}?criterio=$prefijo" $null 200).Json)[0]
 Comprobar 'Nueva configuración inactiva y sin uso' (-not $nueva.activo -and -not $nueva.enUso -and $nueva.codigoParametro -eq $idA)
 Comprobar '12.5% se guarda exactamente como 0.125000' ((Query "SELECT TasaAnual FROM dbo.ParametroCredito WHERE CodigoParametro=$idA").Tables[0].Rows[0][0] -eq [decimal]0.125)
 $a.tasaAnualPorcentaje='12.5001';[void](Bien 'Editar configuración no utilizada' PUT "$base/$idA" $a 204)
 Comprobar 'Cuatro decimales porcentuales preservados' ((Query "SELECT TasaAnual FROM dbo.ParametroCredito WHERE CodigoParametro=$idA").Tables[0].Rows[0][0] -eq [decimal]0.125001)
 $a.tasaAnualPorcentaje='12.5';[void](Bien 'Reponer tasa de ensayo' PUT "$base/$idA" $a 204)
 foreach($cambio in @(@{nombre=' '},@{nombre=('x'*101)},@{tasaAnualPorcentaje='100.0001'},@{tasaAnualPorcentaje='-0.1'},@{tasaAnualPorcentaje='1.00001'},@{tasaAnualPorcentaje=$null},@{seguroAutoMensualPorcentaje='0'},@{seguroVidaMensualPorcentaje='0'},@{engancheMinimoPorcentaje='19.99'},@{engancheMinimoPorcentaje='100'},@{comisionPredeterminadaPorcentaje='101'},@{depreciacionInicialPorcentaje='14.9999'},@{depreciacionInicialPorcentaje='20.0001'},@{manejoMensual='26'},@{activo=$true},@{codigoParametro=1})){
  $mal=$a.Clone();foreach($k in $cambio.Keys){$mal[$k]=$cambio[$k]};[void](Bien "Validación parámetro $($cambio.Keys -join ',')" POST $base $mal 400)
 }
 foreach($consulta in @('?criterio=','?criterio=a&criterio=b','?activo=true',('?criterio='+('x'*201)))){[void](Bien "Filtro inválido $consulta" GET "$base$consulta" $null 400)}
 [void](Bien 'Activar A' POST "$base/$idA/activar" $null 204)
 [void](Bien 'Activar A repetido es idempotente' POST "$base/$idA/activar" $null 204)
 [void](Bien 'No editar configuración activa aunque esté libre' PUT "$base/$idA" $a 409)
 [void](Bien 'No borrar activa aunque esté libre' DELETE "$base/$idA" $null 409)
 [void](Bien 'Activar ausente' POST "$base/2147483647/activar" $null 404)
 Comprobar 'Activación fallida conserva A activa' ((Query 'SELECT CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1').Tables[0].Rows[0][0] -eq $idA)
 $b=$a.Clone();$b.nombre="$prefijo B";$b.tasaAnualPorcentaje='18';$b.seguroAutoMensualPorcentaje='0.2';$b.seguroVidaMensualPorcentaje='0.06';$b.engancheMinimoPorcentaje='25';$b.comisionPredeterminadaPorcentaje='7.5';$b.depreciacionInicialPorcentaje='20'
 $idB=(Bien 'Crear configuración B' POST $base $b 201).Json.codigoParametro
 [void](Query "EXEC api.DetalleReferencia_Insertar @CodigoDeudor=$($ids.Cliente),@CodigoReferencia=$($ids.Referencia),@CodigoTipoReferencia=2,@ParentescoRelacion=N'Amistad';")
 $ruta="/api/creditos/$numero";$autor=@{responsable='Ensayo parámetros'};$datos.enganche='25000.00'
 [void](Bien 'Crédito usa comisión predeterminada al omitirla' POST '/api/creditos' $datos 201)
 $f=(Bien 'Consultar crédito con A' GET $ruta $null 200).Json
 Comprobar 'Crédito copia versión A y comisión de 2%' ($f.codigoParametro -eq $idA -and [decimal]$f.porcentajeComision -eq [decimal]0.02)
 foreach($comision in @('-1','100.0001','1.00001','abc')){
  $mal=$datos.Clone();$mal.comisionPorcentaje=$comision;[void](Bien "Comisión inválida $comision" PUT $ruta $mal 400)
 }
 foreach($comision in @('0','100','0.0001','3.25')){
  $datos.comisionPorcentaje=$comision;[void](Bien "Comisión válida $comision" PUT $ruta $datos 204)
  $f=(Peticion GET $ruta).Json;Comprobar "Comisión exacta $comision" ([decimal]$f.porcentajeComision -eq [decimal]$comision/100)
 }
 $sinComision=$datos.Clone();$sinComision.Remove('comisionPorcentaje');[void](Bien 'Editar omitiendo comisión conserva pacto' PUT $ruta $sinComision 204)
 Comprobar 'Pacto 3.25% conservado sin campo' ([decimal](Peticion GET $ruta).Json.porcentajeComision -eq [decimal]0.0325)
 $sinComision.comisionPorcentaje=$null;[void](Bien 'Editar con null conserva pacto' PUT $ruta $sinComision 204)
 Comprobar 'Pacto 3.25% conservado con null' ([decimal](Peticion GET $ruta).Json.porcentajeComision -eq [decimal]0.0325)
 [void](Bien 'No editar configuración usada por borrador' PUT "$base/$idA" $a 409)
 [void](Bien 'No borrar configuración usada' DELETE "$base/$idA" $null 409)
 Comprobar 'API identifica configuración utilizada' (@((Peticion GET "${base}?criterio=$prefijo").Json|Where-Object codigoParametro -eq $idA)[0].enUso)
 $borradorAntes=(Peticion GET $ruta).Texto
 [void](Bien 'Activar B sustituye A' POST "$base/$idB/activar" $null 204)
 Comprobar 'Una sola configuración activa: B' ((Query 'SELECT COUNT(*) FROM dbo.ParametroCredito WHERE Activo=1').Tables[0].Rows[0][0] -eq 1 -and (Query 'SELECT CodigoParametro FROM dbo.ParametroCredito WHERE Activo=1').Tables[0].Rows[0][0] -eq $idB)
 Comprobar 'Activar B no reescribe borrador existente' ((Peticion GET $ruta).Texto -ceq $borradorAntes)
 $obsoleto=$datos.Clone();$obsoleto.codigoParametro=$idA
 [void](Bien 'Pantalla con versión activa obsoleta rechazada' PUT $ruta $obsoleto 409)
 Comprobar 'Rechazo obsoleto revierte también fiadores y valores' ((Peticion GET $ruta).Texto -ceq $borradorAntes)
 [void](Bien 'Presentar crédito de A después de activar B' POST "$ruta/presentar" $autor 204)
 [void](Bien 'Aprobar crédito conserva condiciones de A' POST "$ruta/aprobar" $autor 204)
 $aprobado=(Peticion GET $ruta).Json
 Comprobar 'Contrato usa interés de A y comisión pactada' ([decimal]$aprobado.tasaAnual -eq [decimal]0.125 -and [decimal]$aprobado.porcentajeComision -eq [decimal]0.0325 -and $aprobado.cuotas.Count -eq 12)
 Comprobar 'Manejo y seguro auto originales conservados' ([decimal]$aprobado.cuotas[0].manejoCuenta -eq 25 -and [decimal]$aprobado.cuotas[0].seguroAuto -eq [decimal]112.5)
 Comprobar 'Depreciación original A aplicada al aprobar' ((Query "SELECT Porcentaje FROM dbo.Depreciacion WHERE CodigoGarantia=$($ids.Vehiculo)").Tables[0].Rows[0][0] -eq [decimal]0.15)
 $contratoAntes=(Peticion GET $ruta).Texto
 $modificado=$datos.Clone();$modificado.comisionPorcentaje='99';[void](Bien 'Comisión aprobada no editable' PUT $ruta $modificado 409)
 Comprobar 'Contrato aprobado intacto tras rechazo' ((Peticion GET $ruta).Texto -ceq $contratoAntes)
 $nuevo=$datos.Clone();$nuevo.numeroCredito=$numero2;$nuevo.Remove('comisionPorcentaje')
 [void](Bien 'Nuevo borrador recibe B' POST '/api/creditos' $nuevo 201)
 $f=(Peticion GET "/api/creditos/$numero2").Json
 Comprobar 'Nuevos valores B y comisión 7.5%' ($f.codigoParametro -eq $idB -and [decimal]$f.tasaAnual -eq [decimal]0.18 -and [decimal]$f.porcentajeComision -eq [decimal]0.075)
 $pago=(Bien 'Pago efectivo con comisión pactada' POST '/api/pagos' @{numeroCredito=$numero;cuota=1;monto='1000.00';codigoTipoPago=5;responsable='Ensayo parámetros'} 201).Json
 $mov=(Bien 'Consultar recibo' GET "/api/pagos?numeroCredito=$numero" $null 200).Json
 Comprobar 'Pago de Q1000 genera Q32.50, no comisión de B' ([decimal]$mov[0].comision -eq [decimal]32.5)
 [void](Bien 'Reactivar A sin editar datos históricos' POST "$base/$idA/activar" $null 204)
 Comprobar 'Cambiar activa conserva cuotas y contrato aprobado' ((Peticion GET $ruta).Texto -ceq $contratoAntes)
 # Concurrencia: dos solicitudes de activación conservan el índice único y la atomicidad.
 $http=[Net.Http.HttpClient]::new([Net.Http.HttpClientHandler]@{UseProxy=$false})
 try{
  $t1=$http.PostAsync("$url$base/$idA/activar",[Net.Http.StringContent]::new(''))
  $t2=$http.PostAsync("$url$base/$idB/activar",[Net.Http.StringContent]::new(''))
  [Threading.Tasks.Task]::WaitAll(@($t1,$t2))
  Comprobar 'Activaciones concurrentes responden éxito o conflicto recuperable' ([int]$t1.Result.StatusCode -in 204,409 -and [int]$t2.Result.StatusCode -in 204,409)
 }finally{$http.Dispose()}
 Comprobar 'Concurrencia conserva exactamente una activa' ((Query 'SELECT COUNT(*) FROM dbo.ParametroCredito WHERE Activo=1').Tables[0].Rows[0][0] -eq 1)
 [void](Bien 'Eliminar borrador propio de B' DELETE "/api/creditos/$numero2" $null 204)
 [void](Bien 'Restaurar activa original por API' POST "$base/$originalActivo/activar" $null 204)
 [void](Bien 'Eliminar B inactiva y libre' DELETE "$base/$idB" $null 204)
 [void](Bien 'Eliminar configuración inexistente' DELETE "$base/$idB" $null 404)
 [void](Bien 'Editar configuración inexistente' PUT "$base/$idB" $b 404)
 [void](Bien 'A permanece protegida aun inactiva' DELETE "$base/$idA" $null 409)
 Comprobar 'Búsqueda sin coincidencias devuelve lista vacía' (@((Bien 'Buscar inexistente' GET "${base}?criterio=NO_EXISTE_$prefijo" $null 200).Json).Count -eq 0)
 $estado='Correcto'
}finally{
 if($proceso -and -not $proceso.HasExited){Stop-Process -Id $proceso.Id}
 try{
  if($cn.State -eq 'Open' -and $inicial){
   # Limpieza administrativa exclusiva de la base aislada y del prefijo de este ensayo.
   [void](Query @"
 IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1;
 BEGIN TRANSACTION;
 DELETE FROM dbo.DetallePago WHERE NumeroCredito IN('$numero','$numero2','$numero3');
 DELETE FROM dbo.DetalleCuota WHERE NumeroCredito IN('$numero','$numero2','$numero3');
 DELETE FROM dbo.ResumenCredito WHERE NumeroCredito IN('$numero','$numero2','$numero3');
 DELETE FROM dbo.CreditoFiador WHERE NumeroCredito IN('$numero','$numero2','$numero3');
 DELETE FROM dbo.Credito WHERE NumeroCredito IN('$numero','$numero2','$numero3');
 DELETE FROM dbo.Depreciacion WHERE CodigoGarantia IN(SELECT CodigoGarantia FROM dbo.Garantia WHERE VIN='$vin');
 DELETE FROM dbo.Garantia WHERE VIN='$vin';
 DELETE dr FROM dbo.DetalleReferencia dr JOIN dbo.Deudor d ON d.CodigoDeudor=dr.CodigoDeudor JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE p.NIT LIKE '$prefijo-%';
 DELETE r FROM dbo.Referencia r JOIN dbo.Persona p ON p.CodigoPersona=r.CodigoPersona WHERE p.NIT LIKE '$prefijo-%';
 DELETE d FROM dbo.Deudor d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE p.NIT LIKE '$prefijo-%';
 DELETE f FROM dbo.Fiador f JOIN dbo.Persona p ON p.CodigoPersona=f.CodigoPersona WHERE p.NIT LIKE '$prefijo-%';
 DELETE v FROM dbo.Vendedor v JOIN dbo.Persona p ON p.CodigoPersona=v.CodigoPersona WHERE p.NIT LIKE '$prefijo-%';
 DELETE t FROM dbo.Telefono t JOIN dbo.Persona p ON p.CodigoPersona=t.CodigoPersona WHERE p.NIT LIKE '$prefijo-%';
 DELETE d FROM dbo.Direccion d JOIN dbo.Persona p ON p.CodigoPersona=d.CodigoPersona WHERE p.NIT LIKE '$prefijo-%';
 DELETE FROM dbo.Persona WHERE NIT LIKE '$prefijo-%';
 UPDATE dbo.ParametroCredito SET Activo=0 WHERE Nombre LIKE '$prefijo%';
 DELETE FROM dbo.ParametroCredito WHERE Nombre LIKE '$prefijo%';
 UPDATE dbo.ParametroCredito SET Activo=1 WHERE CodigoParametro=$originalActivo;
 COMMIT;
"@)
   if($inicial){Comprobar 'Registros previos de validación conservados tras retirar solo el ensayo' ((Captura) -ceq $inicial)}
  }
 }catch{$estado='Fallido';throw}finally{
  $cn.Dispose();[pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';Fecha=(Get-Date -Format o);ConexionLocalSinCifrado=[bool]$ConexionLocalSinCifrado;Pruebas=$pruebas}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $salida 'resultado.json') -Encoding UTF8
 }
}
Write-Output "Parámetros y comisión: $($pruebas.Count) comprobaciones correctas."
