# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Crea fichas temporales propias y las retira al finalizar.
param([Parameter(Mandatory)][string]$Credencial,[string]$SalidaCompilacion='bin\CierreTecnico')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent;$api=Join-Path $repo 'src\MAGISAUTO.API';$salida=Join-Path $repo 'artifacts\verificacion-cierre-tecnico'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new();$proceso=$null;$estado='Fallido';$creada=$null
function Comprobar([string]$nombre,[bool]$ok){if(-not $ok){throw "Falló: $nombre"};$pruebas.Add([pscustomobject]@{Prueba=$nombre;Resultado='Correcto'})}
function Query([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$da=[Data.SqlClient.SqlDataAdapter]::new($cmd);$ds=[Data.DataSet]::new();try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}}
function Captura{
 $r=[ordered]@{};$tablas=(Query "SELECT t.name,STRING_AGG(QUOTENAME(c.name),',') WITHIN GROUP(ORDER BY ic.key_ordinal) Clave FROM sys.tables t JOIN sys.indexes i ON i.object_id=t.object_id AND i.is_primary_key=1 JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE SCHEMA_NAME(t.schema_id)='dbo' GROUP BY t.name ORDER BY t.name;").Tables[0]
 Comprobar 'Instantánea incluye 26 tablas' ($tablas.Rows.Count -eq 26)
 foreach($t in $tablas.Rows){$json=((Query "SELECT * FROM dbo.[$($t.name)] ORDER BY $($t.Clave) FOR JSON PATH, INCLUDE_NULL_VALUES;").Tables[0].Rows|ForEach-Object{$_[0]}) -join '';$r[$t.name]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))};return ($r|ConvertTo-Json -Depth 12 -Compress)
}
function Peticion([string]$metodo,[string]$ruta,[object]$datos=$null){
 $p=@{Uri="$url$ruta";Method=$metodo;NoProxy=$true;SkipHttpErrorCheck=$true;TimeoutSec=20}
 if($null -ne $datos){$p.ContentType='application/json; charset=utf-8';$p.Body=$datos|ConvertTo-Json -Depth 12 -Compress}
 $r=Invoke-WebRequest @p
 $texto=if($r.Content -is [byte[]]){[Text.Encoding]::UTF8.GetString($r.Content)}else{[string]$r.Content}
 $json=if($texto -and $r.Headers.'Content-Type' -match 'json'){$texto|ConvertFrom-Json -AsHashtable}else{$null}
 [pscustomobject]@{Codigo=[int]$r.StatusCode;Texto=$texto;Json=$json}
}

try{
 $cn.Open();Comprobar 'Destino aislado confirmado' ((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -ceq 'MAGISAUTO_ValidacionV2');$antes=Captura; [void](Query (Get-Content (Join-Path $repo 'database/v2/migraciones/002_Cierre_Tecnico.sql') -Raw))
 $local=Get-Content (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json;$cs=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto);$cs['Initial Catalog']='MAGISAUTO_ValidacionV2'
 $tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop();$url="http://127.0.0.1:$puerto";$vars=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto');$prev=@{};foreach($v in $vars){$prev[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{$env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development';$env:ConnectionStrings__MagisAuto=$cs.ConnectionString;$dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll";$proceso=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')}finally{foreach($v in $vars){[Environment]::SetEnvironmentVariable($v,$prev[$v],'Process')}}
 $listo=$false;for($i=0;$i -lt 40;$i++){try{if((Peticion GET '/api/salud').Codigo -eq 200){$listo=$true;break}}catch{};Start-Sleep -Milliseconds 200};Comprobar 'API temporal disponible' $listo

 function Fila([string]$entidad,[string]$criterio){$r=Peticion GET ('/api/consultas-integradas/'+$entidad+'?criterio='+[uri]::EscapeDataString($criterio));if($r.Codigo -ne 200){throw $r.Texto};return $r.Json.filas[0]}
 function TextoFila($f){$d=@{};foreach($k in $f.Keys){$d[$k]=if($null -eq $f[$k]){$null}else{[string]$f[$k]}};return $d}
 function Cambiar($entidad,$op,$datos,$anterior=$null){return Peticion POST "/api/mantenimiento-personas/$entidad/$op" @{datos=$datos;anterior=$anterior}}
 function EsperarCodigo($nombre,$r,$codigo){if($r.Codigo -ne $codigo){throw "$nombre : $($r.Codigo) $($r.Texto)"};Comprobar $nombre $true}
 $marca='CIERRE-'+[Guid]::NewGuid().ToString('N').Substring(0,12)
 foreach($e in @('personas','telefonos','direcciones','referencias','cuotas','resumenes')){EsperarCodigo "Formulario $e disponible" (Peticion GET "/api/mantenimiento-personas/$e") 200}
 EsperarCodigo 'No permite elegir tabla arbitraria' (Peticion GET '/api/mantenimiento-personas/ParametroCredito') 404
 $p=@{PrimerNombre=$marca;PrimerApellido='Prueba'}
 EsperarCodigo 'Crear persona sin expediente' (Cambiar personas crear $p) 204
 $f=TextoFila (Fila personas $marca);$personaPrueba=[int]$f.CodigoPersona
 $nuevo=$f.Clone();$nuevo.SegundoNombre='Editado'
 EsperarCodigo 'Editar persona sin expediente' (Cambiar personas editar $nuevo $f) 204
 EsperarCodigo 'Rechaza edición obsoleta' (Cambiar personas editar $nuevo $f) 409
 $f=TextoFila (Fila personas $marca);$mal=$f.Clone();$mal.CorreoElectronico='invalido'
 EsperarCodigo 'Correo inválido rechazado' (Cambiar personas editar $mal $f) 400
 $mal=$f.Clone();$mal.PrimerNombre='   '
 EsperarCodigo 'Nombre vacío rechazado' (Cambiar personas editar $mal $f) 400
 $mal=$f.Clone();$mal.FechaNacimiento='2099-01-01'
 EsperarCodigo 'Nacimiento futuro rechazado' (Cambiar personas editar $mal $f) 400
 $tipoTel=[int](Query 'SELECT TOP(1) CodigoTipoTelefono FROM dbo.TipoTelefono ORDER BY CodigoTipoTelefono').Tables[0].Rows[0][0]
 $tel=@{CodigoPersona=[string]$personaPrueba;CodigoTipoTelefono=[string]$tipoTel;Numero='55555555'}
 EsperarCodigo 'Crear teléfono independiente' (Cambiar telefonos crear $tel) 204
 $tf=TextoFila (Fila telefonos ([string]$personaPrueba));$tn=$tf.Clone();$tn.Numero='55555556'
 EsperarCodigo 'Editar teléfono independiente' (Cambiar telefonos editar $tn $tf) 204
 EsperarCodigo 'Persona con contacto protegida' (Cambiar personas eliminar @{CodigoPersona=[string]$personaPrueba} $f) 409
 $ubicacion=(Query 'SELECT TOP(1) CodigoDepartamento,CodigoMunicipio FROM dbo.Municipio ORDER BY CodigoDepartamento,CodigoMunicipio').Tables[0].Rows[0]
 $tipoDir=[int](Query 'SELECT TOP(1) CodigoTipoDireccion FROM dbo.TipoDireccion ORDER BY CodigoTipoDireccion').Tables[0].Rows[0][0]
 $dir=@{CodigoPersona=[string]$personaPrueba;CodigoTipoDireccion=[string]$tipoDir;CodigoDepartamento=[string]$ubicacion.CodigoDepartamento;CodigoMunicipio=[string]$ubicacion.CodigoMunicipio;Detalle=$marca}
 EsperarCodigo 'Crear dirección independiente' (Cambiar direcciones crear $dir) 204
 $df=TextoFila (Fila direcciones $marca);$dn=$df.Clone();$dn.Detalle=$marca+' editada'
 EsperarCodigo 'Editar dirección independiente' (Cambiar direcciones editar $dn $df) 204
 EsperarCodigo 'Crear referencia independiente' (Cambiar referencias crear @{CodigoPersona=[string]$personaPrueba;LugarTrabajo=$marca}) 204
 $rf=TextoFila (Fila referencias $marca);$rn=$rf.Clone();$rn.LugarTrabajo=$marca+' editado'
 EsperarCodigo 'Editar referencia independiente' (Cambiar referencias editar $rn $rf) 204
 $rf=TextoFila (Fila referencias $marca)
 EsperarCodigo 'Eliminar referencia libre' (Cambiar referencias eliminar @{CodigoReferencia=$rf.CodigoReferencia} $rf) 204
 $tf=TextoFila (Fila telefonos ([string]$personaPrueba))
 EsperarCodigo 'Eliminar teléfono independiente' (Cambiar telefonos eliminar @{CodigoPersona=$tf.CodigoPersona;Correlativo=$tf.Correlativo} $tf) 204
 $df=TextoFila (Fila direcciones $marca)
 EsperarCodigo 'Eliminar dirección independiente' (Cambiar direcciones eliminar @{CodigoPersona=$df.CodigoPersona;Correlativo=$df.Correlativo} $df) 204
 EsperarCodigo 'Eliminar persona independiente libre' (Cambiar personas eliminar @{CodigoPersona=[string]$personaPrueba} $f) 204
 # Simulación propia: copiar solo condiciones, nunca cuotas o pagos reales.
 $numero='CI'+[Guid]::NewGuid().ToString('N').Substring(0,12)
 [void](Query "INSERT dbo.Credito(NumeroCredito,CodigoDeudor,CodigoGarantia,CodigoVendedor,CodigoAgencia,CodigoParametro,Plazo,PrecioContado,Enganche,EngancheMinimo,TasaAnual,ManejoMensual,TasaSeguroAuto,TasaSeguroVida,PorcentajeComision,FiadoresRequeridos,Estado) SELECT TOP(1) '$numero',CodigoDeudor,CodigoGarantia,CodigoVendedor,CodigoAgencia,CodigoParametro,Plazo,PrecioContado,Enganche,EngancheMinimo,TasaAnual,ManejoMensual,TasaSeguroAuto,TasaSeguroVida,PorcentajeComision,FiadoresRequeridos,'BORRADOR' FROM dbo.Credito WHERE FechaAprobacion IS NOT NULL;")
 $q=@{NumeroCredito=$numero;Cuota='1';FechaVencimiento='2026-11-12';Capital='100.00';Interes='10.00'}
 EsperarCodigo 'Crear cuota de simulación' (Cambiar cuotas crear $q) 204
 EsperarCodigo 'Crear resumen derivado' (Cambiar resumenes crear @{NumeroCredito=$numero}) 204
 $sf=TextoFila (Fila resumenes $numero)
 Comprobar 'Resumen suma interés real de cuotas' ([decimal]$sf.TotalIntereses -eq 10)
 $qf=TextoFila (Fila cuotas $numero);$qn=@{};foreach($k in @('NumeroCredito','Cuota','FechaVencimiento','Capital','Interes')){$qn[$k]=$qf[$k]};$qn.Interes='12.00'
 EsperarCodigo 'Editar cuota de simulación' (Cambiar cuotas editar $qn $qf) 204
 Comprobar 'Cambio de cuota sincroniza resumen' ([decimal](Fila resumenes $numero).TotalIntereses -eq 12)
 EsperarCodigo 'Recalcular resumen de borrador' (Cambiar resumenes editar @{NumeroCredito=$numero} @{NumeroCredito=$numero}) 204
 $aprobado=[string](Query "SELECT TOP(1) NumeroCredito FROM dbo.Credito WHERE FechaAprobacion IS NOT NULL ORDER BY NumeroCredito").Tables[0].Rows[0][0]
 $af=TextoFila (Fila cuotas $aprobado)
 $ad=@{};foreach($k in @('NumeroCredito','Cuota','FechaVencimiento','Capital','Interes')){$ad[$k]=$af[$k]}
 EsperarCodigo 'Cuota aprobada no se edita' (Cambiar cuotas editar $ad $af) 409
 EsperarCodigo 'Cuota aprobada no se borra' (Cambiar cuotas eliminar @{NumeroCredito=$af.NumeroCredito;Cuota=$af.Cuota} $af) 409
 EsperarCodigo 'Resumen aprobado no se recalcula' (Cambiar resumenes editar @{NumeroCredito=$aprobado} @{NumeroCredito=$aprobado}) 409
 EsperarCodigo 'Resumen aprobado no se borra' (Cambiar resumenes eliminar @{NumeroCredito=$aprobado} @{NumeroCredito=$aprobado}) 409
 $qf=TextoFila (Fila cuotas $numero)
 EsperarCodigo 'Eliminar cuota de simulación' (Cambiar cuotas eliminar @{NumeroCredito=$numero;Cuota='1'} $qf) 204
 Comprobar 'Resumen vacío coherente' ([decimal](Fila resumenes $numero).TotalNetoRecaudable -eq 0)
 EsperarCodigo 'Eliminar resumen de borrador' (Cambiar resumenes eliminar @{NumeroCredito=$numero} @{NumeroCredito=$numero}) 204
 # Cortes independientes calculados a partir del contrato, sin usar fn_Saldos para el devengo esperado.
 $fechas=(Query "SELECT MIN(FechaVencimiento) Primero,MAX(FechaVencimiento) Ultimo FROM dbo.DetalleCuota WHERE NumeroCredito='$aprobado'").Tables[0].Rows[0]
 foreach($corte in @(([datetime]$fechas.Primero).AddDays(-1),[datetime]$fechas.Primero,([datetime]$fechas.Primero).AddDays(1),[datetime]$fechas.Ultimo)){
  $fecha=$corte.ToString('yyyy-MM-dd');$datos=(Query "EXEC api.Reporte10_Intereses @FechaCorte='$fecha';").Tables[0]
  $fila=@($datos.Rows|Where-Object NumeroCredito -eq $aprobado)[0]
  $esperado=[decimal](Query "SELECT COALESCE(SUM(Interes),0) FROM dbo.DetalleCuota WHERE NumeroCredito='$aprobado' AND FechaVencimiento<='$fecha';").Tables[0].Rows[0][0]
  Comprobar "Devengo exacto al corte $fecha" ([decimal]$fila.InteresesDevengados -eq $esperado)
  Comprobar "Devengo más futuro coincide con contrato $fecha" ([decimal]$fila.InteresesDevengados+[decimal]$fila.InteresesPorDevengar -eq [decimal]$fila.InteresesDelContrato)
  Comprobar "Cobrado y pendiente concilian $fecha" ([decimal]$fila.InteresesCobrados+[decimal]$fila.InteresesPendientes -eq [decimal]$fila.InteresesDelContrato)
  $anticipo=[decimal](Query "SELECT COALESCE(SUM(p.Interes),0) FROM dbo.DetallePago p JOIN dbo.DetalleCuota q ON q.NumeroCredito=p.NumeroCredito AND q.Cuota=p.Cuota WHERE p.NumeroCredito='$aprobado' AND q.FechaVencimiento>'$fecha' AND p.FechaPago<DATEADD(day,1,CONVERT(date,'$fecha')) AND (p.FechaAnulacion IS NULL OR p.FechaAnulacion>=DATEADD(day,1,CONVERT(date,'$fecha')));").Tables[0].Rows[0][0]
  Comprobar "Interés cobrado anticipado separado al $fecha" ([decimal]$fila.InteresesCobradosAnticipados -eq $anticipo)
 }
 # Simular una base sin 002, exclusivamente en validación; restaurar el SP en todos los casos.
 $defReporte=[string](Query "SELECT OBJECT_DEFINITION(OBJECT_ID('api.Reporte10_Intereses'))").Tables[0].Rows[0][0]
 try{
  [void](Query "CREATE OR ALTER PROCEDURE api.Reporte10_Intereses @FechaCorte date=NULL AS SELECT CAST('SIN-MIGRACION' AS varchar(20)) NumeroCredito,CAST(0 AS decimal(18,2)) InteresesDelContrato;")
  EsperarCodigo 'Reporte detecta actualización SQL pendiente' (Peticion GET '/api/reportes/10?fechaCorte=2026-10-16') 409
  EsperarCodigo 'Cuotas bloqueadas sin actualización SQL' (Cambiar cuotas crear @{NumeroCredito=$numero;Cuota='1';FechaVencimiento='2026-11-12';Capital='100';Interes='10'}) 409
  EsperarCodigo 'Resúmenes bloqueados sin actualización SQL' (Cambiar resumenes crear @{NumeroCredito=$numero}) 409
 }finally{[void](Query ($defReporte -replace '^CREATE\s+(OR\s+ALTER\s+)?PROCEDURE','CREATE OR ALTER PROCEDURE'))}
 $estado='Correcto'
}finally{
 if($cn.State -eq 'Open'){
  if($numero){[void](Query "IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1; DELETE dbo.ResumenCredito WHERE NumeroCredito='$numero'; DELETE dbo.DetalleCuota WHERE NumeroCredito='$numero'; DELETE dbo.Credito WHERE NumeroCredito='$numero' AND Estado='BORRADOR';")}
  if($personaPrueba){[void](Query "IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1; IF EXISTS(SELECT 1 FROM dbo.Persona WHERE CodigoPersona=$personaPrueba AND PrimerNombre=N'$marca') BEGIN DELETE dbo.Referencia WHERE CodigoPersona=$personaPrueba; DELETE dbo.Telefono WHERE CodigoPersona=$personaPrueba; DELETE dbo.Direccion WHERE CodigoPersona=$personaPrueba; DELETE dbo.Persona WHERE CodigoPersona=$personaPrueba; END;")}
 }
 if($proceso){if(-not $proceso.HasExited){$proceso.Kill($true);$proceso.WaitForExit()};$proceso.Dispose()}
 if($cn.State -eq 'Open'){$despues=Captura;Comprobar 'Las 26 tablas conservan filas y valores previos' ($antes -ceq $despues);$cn.Close()};$cn.Dispose()
 [pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $salida 'resultado.json') -Encoding UTF8
}
Write-Output "Cierre técnico: $($pruebas.Count) comprobaciones correctas."
