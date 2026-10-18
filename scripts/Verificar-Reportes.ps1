# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Conserva los datos anteriores.
param([Parameter(Mandatory)][string]$Credencial,[string]$SalidaCompilacion='bin\Reportes',[switch]$ConexionLocalSinCifrado)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$salida=Join-Path $repo 'artifacts\verificacion-reportes'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new();$proceso=$null;$estado='Fallido';$inicial=$null;$prefijo='RP'+[Guid]::NewGuid().ToString('N').Substring(0,10).ToUpper();$vin=$prefijo+'00001';$numero=$prefijo+'-01';$numero2=$prefijo+'-02';$numero3=$prefijo+'-03'
function Query([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandTimeout=45;$cmd.CommandText=$sql;$ds=[Data.DataSet]::new();$da=[Data.SqlClient.SqlDataAdapter]::new($cmd);try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}}
function Comprobar([string]$nombre,[bool]$ok){if(-not $ok){throw "Falló: $nombre"};$pruebas.Add([pscustomobject]@{Prueba=$nombre;Resultado='Correcto'})}
function Captura {
 $r=[ordered]@{}
 foreach($t in @('Persona','Deudor','Fiador','Vendedor','Telefono','Direccion','Referencia','DetalleReferencia','Garantia','Credito','CreditoFiador','DetalleCuota','DetallePago','ResumenCredito','Depreciacion')){
  $ds=Query "SELECT * FROM dbo.[$t] FOR JSON PATH,INCLUDE_NULL_VALUES;";$r[$t]=($ds.Tables[0].Rows|ForEach-Object{$_[0]}) -join ''
 };return ($r|ConvertTo-Json -Depth 8 -Compress)
}
function Peticion([string]$metodo,[string]$ruta,[object]$datos=$null){
 $p=@{Uri="$url$ruta";Method=$metodo;NoProxy=$true;SkipHttpErrorCheck=$true;TimeoutSec=35}
 if($null -ne $datos){$p.ContentType='application/json; charset=utf-8';$p.Body=$datos|ConvertTo-Json -Depth 20 -Compress}
 $r=Invoke-WebRequest @p;$texto=if($r.Content -is [byte[]]){[Text.Encoding]::UTF8.GetString($r.Content)}else{[string]$r.Content};$json=if($texto -and $r.Headers.'Content-Type' -match 'json'){$texto|ConvertFrom-Json}else{$null}
 return [pscustomobject]@{Codigo=[int]$r.StatusCode;Texto=$texto;Json=$json}
}
function Bien([string]$nombre,[string]$metodo,[string]$ruta,[object]$datos,[int]$codigo){$r=Peticion $metodo $ruta $datos;Comprobar $nombre ($r.Codigo -eq $codigo);return $r}
try{
 $cn.Open();Comprobar 'Destino aislado confirmado' ((Query 'SELECT DB_NAME()').Tables[0].Rows[0][0] -ceq 'MAGISAUTO_ValidacionV2')
 Comprobar 'Procedimientos financieros disponibles' ((Query "SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('api') AND name IN('DetallePago_Insertar','DetallePago_Anular','Credito_Presentar')").Tables[0].Rows[0][0] -eq 3)
 # Usar la misma cuenta limitada que la aplicación, en el destino aislado.
 [void](Query "IF USER_ID(N'magis_api_diego') IS NULL CREATE USER magis_api_diego FOR LOGIN magis_api_diego; IF IS_ROLEMEMBER(N'magis_api',N'magis_api_diego')<>1 ALTER ROLE magis_api ADD MEMBER magis_api_diego;")
 $inicial=Captura
 $local=Get-Content (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cs=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto);$cs['Initial Catalog']='MAGISAUTO_ValidacionV2'
 if($ConexionLocalSinCifrado){
  if($cs.DataSource -ne 'tcp:127.0.0.1,1433'){throw 'El modo de ensayo sin cifrado solo admite loopback local.'}
  $cs['Encrypt']=$false
 }

 $limitada=[Data.SqlClient.SqlConnection]::new($cs.ConnectionString)
 try{$limitada.Open();$cmd=$limitada.CreateCommand();$cmd.CommandText='SELECT * FROM dbo.Credito';$negado=$false;try{[void]$cmd.ExecuteScalar()}catch{$negado=$true};Comprobar 'Cuenta API sin lectura directa de tablas' $negado}finally{$limitada.Dispose()}
 $tcp=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$tcp.Start();$puerto=$tcp.LocalEndpoint.Port;$tcp.Stop();$url="http://127.0.0.1:$puerto"
 $vars=@('ASPNETCORE_ENVIRONMENT','DOTNET_ENVIRONMENT','ConnectionStrings__MagisAuto');$antes=@{}
 foreach($v in $vars){$antes[$v]=[Environment]::GetEnvironmentVariable($v,'Process')}
 try{
  $env:ASPNETCORE_ENVIRONMENT='Development';$env:DOTNET_ENVIRONMENT='Development';$env:ConnectionStrings__MagisAuto=$cs.ConnectionString
  $dll=Join-Path $api "$SalidaCompilacion\MAGISAUTO.API.dll"
  $proceso=Start-Process dotnet -ArgumentList @(('"'+$dll+'"'),'--urls',$url) -WorkingDirectory $api -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')
 }finally{foreach($v in $vars){[Environment]::SetEnvironmentVariable($v,$antes[$v],'Process')};$local=$null;$cs=$null}
 $iniciado=$false;for($i=0;$i -lt 40;$i++){try{if((Peticion GET '/api/salud').Codigo -eq 200){$iniciado=$true;break}}catch{};Start-Sleep -Milliseconds 200}
 Comprobar 'API temporal disponible' $iniciado
 foreach($ruta in @('/reportes.html','/reportes.css','/reportes.js','/reportes-formato.js','/','/pagos.html')){[void](Bien "Recurso $ruta" GET $ruta $null 200)}
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
 [void](Query "EXEC api.DetalleReferencia_Insertar @CodigoDeudor=$($ids.Cliente),@CodigoReferencia=$($ids.Referencia),@CodigoTipoReferencia=2,@ParentescoRelacion=N'Amistad';")
 $datos=@{numeroCredito=$numero;codigoDeudor=[int]$ids.Cliente;codigoGarantia=[int]$ids.Vehiculo;codigoVendedor=[int]$ids.Vendedor;enganche='20000.00';plazo=12;fiadoresRequeridos=1;fiadores=@([int]$ids.Fiador)}
 [void](Bien 'Preparar borrador propio' POST '/api/creditos' $datos 201)
 $b='/api/pagos';$saldo="$b/credito/$numero";$autor=@{responsable='Ensayo de pagos'}

 # Fechas históricas solo en el crédito ficticio de la base aislada.
 [void](Query @"
 EXEC api.Credito_Presentar @NumeroCredito='$numero',@Responsable=N'Ensayo reportes';
 DECLARE @aprobacion datetime2(0)=DATEADD(month,-3,CONVERT(date,dbo.fn_AhoraGuatemala()));
 EXEC api.Credito_Aprobar @NumeroCredito='$numero',@Responsable=N'Ensayo reportes',@FechaAprobacion=@aprobacion;
 DECLARE @ayer datetime2(0)=DATEADD(day,-1,dbo.fn_AhoraGuatemala());
 EXEC api.DetallePago_Insertar @NumeroCredito='$numero',@Cuota=1,@Monto=1000,@CodigoTipoPago=5,@Responsable=N'Ensayo reportes',@FechaPago=@ayer;
 EXEC api.DetallePago_Insertar @NumeroCredito='$numero',@Cuota=1,@Monto=500,@CodigoTipoPago=2,@Responsable=N'Ensayo reportes',@ReferenciaBancaria=N'REF-REPORTES';
 DECLARE @pago bigint=(SELECT MIN(CodigoPago) FROM dbo.DetallePago WHERE NumeroCredito='$numero');
 EXEC api.DetallePago_Anular @CodigoPago=@pago,@Responsable=N'Ensayo reportes',@Motivo=N'Validar cortes históricos';
"@)
 $fechas=(Query "SELECT CONVERT(varchar(10),CONVERT(date,dbo.fn_AhoraGuatemala()),23) Hoy,CONVERT(varchar(10),DATEADD(day,-1,CONVERT(date,dbo.fn_AhoraGuatemala())),23) Ayer,CONVERT(varchar(10),DATEADD(year,-1,CONVERT(date,dbo.fn_AhoraGuatemala())),23) Desde,YEAR(dbo.fn_AhoraGuatemala()) Anio;").Tables[0].Rows[0]
 $hoy=$fechas.Hoy;$ayer=$fechas.Ayer;$desde=$fechas.Desde;$anio=$fechas.Anio
 $catalogo=(Bien 'Catálogo de consultas disponible' GET '/api/reportes' $null 200).Json
 Comprobar 'Veinte consultas identificadas, con utilidad y filtros' ($catalogo.reportes.Count -eq 20 -and @($catalogo.reportes|Where-Object{ -not $_.utilidad -or -not $_.filtros }).Count -eq 0)
 $selectores=(Bien 'Selectores mediante SP' GET '/api/reportes/catalogos' $null 200).Json
 Comprobar 'Cliente y crédito propios presentes en selectores' ($ids.Cliente -in $selectores.clientes.codigoDeudor -and $numero -in $selectores.creditos.numeroCredito)
 Comprobar 'Selectores no exponen DPI ni cadena de conexión' (($selectores|ConvertTo-Json -Depth 10) -notmatch 'DPI|Password|ConnectionString')
 $resultados=@{}
 $registros=Get-Content (Join-Path $repo 'database/v2/entrega/reportes.json') -Raw | ConvertFrom-Json
 foreach($reporte in $registros){
  $id=[int]$reporte.numero
  $consulta="fechaCorte=$hoy";$sql="@FechaCorte='$hoy'"
  if($id -in @(1,3,4,8,13,19,20)){$consulta="desde=$desde&hasta=$hoy";$sql="@Desde='$desde',@Hasta='$hoy'"}
  if($id -eq 2){$consulta+='&diasMinimos=1';$sql+=',@DiasMinimos=1'}
  if($id -eq 5){$consulta="mes=1&anio=$anio";$sql="@Mes=1,@Anio=$anio"}
  if($id -eq 6){$consulta+="&codigoDeudor=$($ids.Cliente)";$sql+=",@CodigoDeudor=$($ids.Cliente)"}
  if($id -eq 7){$consulta+="&numeroCredito=$numero";$sql+=",@NumeroCredito='$numero'"}
  if($id -eq 11){$consulta+='&dias=30';$sql+=',@Dias=30'}
  $http=(Bien "Reporte $id ejecutado por API" GET "/api/reportes/${id}?$consulta" $null 200).Json
  $resultados[$id]=$http
  $ds=Query "EXEC $($reporte.procedimiento) $sql;"
  Comprobar "Reporte $id conserva todas las tablas SQL" ($http.tablas.Count -eq $ds.Tables.Count)
  $igual=$true
  for($ti=0;$ti -lt $ds.Tables.Count;$ti++){
   $tabla=$ds.Tables[$ti];$t=$http.tablas[$ti]
   if($t.filas.Count -ne $tabla.Rows.Count -or $t.columnas.Count -ne $tabla.Columns.Count){$igual=$false;break}
   for($ci=0;$ci -lt $tabla.Columns.Count;$ci++){
    $nombre=$tabla.Columns[$ci].ColumnName
    if($t.columnas[$ci].nombre -cne $nombre){$igual=$false}
    for($ri=0;$ri -lt $tabla.Rows.Count;$ri++){
     $v=$tabla.Rows[$ri][$ci];$actual=$t.filas[$ri].$nombre
     if($v -is [DBNull]){if($null -ne $actual){$igual=$false}}
     elseif($v -is [datetime]){$formato=if($t.columnas[$ci].tipo -eq 'fecha'){'yyyy-MM-dd'}else{'yyyy-MM-dd HH:mm:ss'};if($actual -cne $v.ToString($formato)){$igual=$false}}
     elseif($v -is [decimal] -or $v -is [long]){if($actual -isnot [string] -or [decimal]$actual -ne [decimal]$v){$igual=$false}}
     elseif([string]$actual -cne [string]$v){$igual=$false}
    }
   }
  }
  Comprobar "Reporte $id coincide con SP, incluidos importes, fechas y nulos" $igual
 }
 Comprobar 'Estado de cuenta entrega resumen, cuotas y movimientos' ($resultados[6].tablas.Count -eq 3 -and $resultados[6].tablas[1].filas.Count -eq 12 -and $resultados[6].tablas[2].filas.Count -eq 2)
 foreach($corte in @($ayer,$hoy)){
  $dev=(Bien "Devengo consultable al $corte" GET "/api/reportes/10?fechaCorte=$corte" $null 200).Json
  $fila=@($dev.tablas[0].filas|Where-Object NumeroCredito -eq $numero)[0]
  $esperado=(Query "SELECT COALESCE((SELECT SUM(Interes) FROM dbo.DetalleCuota WHERE NumeroCredito='$numero' AND FechaVencimiento<='$corte'),0) Devengado,COALESCE((SELECT SUM(Interes) FROM dbo.DetallePago WHERE NumeroCredito='$numero' AND FechaPago<DATEADD(day,1,CONVERT(date,'$corte')) AND (FechaAnulacion IS NULL OR FechaAnulacion>=DATEADD(day,1,CONVERT(date,'$corte')))),0) Cobrado;").Tables[0].Rows[0]
  Comprobar "Devengo y cobro independiente con anulación al $corte" ([decimal]$fila.InteresesDevengados -eq [decimal]$esperado.Devengado -and [decimal]$fila.InteresesCobrados -eq [decimal]$esperado.Cobrado)
  Comprobar "Devengado pendiente correcto al $corte" ([decimal]$fila.DevengadosPorCobrar -eq ([decimal]$esperado.Devengado-[decimal]$esperado.Cobrado))
 }
 $resumen=$resultados[6].tablas[0].filas[0]
 Comprobar 'Corte actual resta solo 500 efectivos' ([decimal]$resumen.PagadoAlCorte -eq 500 -and [decimal]$resumen.SaldoTotal -eq ([decimal]$resumen.TotalPlan-500))
 $historico=(Bien 'Estado de cuenta al corte anterior a la anulación' GET "/api/reportes/6?codigoDeudor=$($ids.Cliente)&fechaCorte=$ayer" $null 200).Json
 Comprobar 'Al corte anterior el pago de 1000 era efectivo' ([decimal]$historico.tablas[0].filas[0].PagadoAlCorte -eq 1000 -and $historico.tablas[2].filas.Count -eq 1 -and $historico.tablas[2].filas[0].VigenteAlCorte -eq 1)
 $antes=(Bien 'Plan previo a aprobar' GET "/api/reportes/7?numeroCredito=$numero&fechaCorte=$desde" $null 200).Json
 Comprobar 'Saldo previo a aprobación es nulo, no cero' ($antes.tablas[1].filas.Count -eq 12 -and @($antes.tablas[1].filas|Where-Object{ $null -ne $_.SaldoPendiente }).Count -eq 0)
 Comprobar 'Mora identifica crédito propio vencido' ($numero -in $resultados[2].tablas[0].filas.NumeroCredito)
 Comprobar 'Abonos parciales identifica cuota propia con 500' (@($resultados[12].tablas[0].filas|Where-Object{ $_.NumeroCredito -eq $numero -and [decimal]$_.Pagado -eq 500 }).Count -eq 1)
 Comprobar 'Carta individual generada con nombre del cliente' (@($resultados[5].tablas[0].filas|Where-Object{ $_.CodigoDeudor -eq $ids.Cliente -and $_.CartaFelicitacion -like '*Ensayo crédito*' }).Count -eq 1)
 Comprobar 'Anulación conserva auditoría y monto original' (@($resultados[20].tablas[0].filas|Where-Object{ $_.NumeroCredito -eq $numero -and [decimal]$_.Monto -eq 1000 -and $_.AnuladoPor -eq 'Ensayo reportes' }).Count -eq 1)
 Comprobar 'Exposición del fiador conserva vínculo del crédito' ($numero -in $resultados[18].tablas[0].filas.NumeroCredito)
 $normal=(Bien 'Fecha de corte predeterminada Guatemala' GET '/api/reportes/9' $null 200).Json
 Comprobar 'Fecha predeterminada coincide con SQL Guatemala' ($normal.filtros.fechaCorte -eq $hoy)
 [void](Bien 'Período sin operaciones' GET '/api/reportes/1?desde=1900-01-01&hasta=1900-01-02' $null 200)
 foreach($caso in @(
  @('/api/reportes/0',404),@('/api/reportes/21',404),@('/api/reportes/1',400),
  @('/api/reportes/1?desde=2026-11-01&hasta=2026-01-01',400),@('/api/reportes/1?desde=2026-02-30&hasta=2026-03-01',400),
  @('/api/reportes/9?fechaCorte=9999-12-31',400),@('/api/reportes/9?fechaCorte=ayer',400),
  @('/api/reportes/11?dias=0',400),@('/api/reportes/11?dias=366',400),@('/api/reportes/2?diasMinimos=0',400),
  @('/api/reportes/5?mes=13&anio=2026',400),@('/api/reportes/5?mes=1&anio=1899',400),
  @('/api/reportes/6?codigoDeudor=0',400),@('/api/reportes/6?codigoDeudor=2147483647',404),
  @('/api/reportes/7?numeroCredito=INEXISTENTE-ENSAYO',404),@('/api/reportes/9?procedimiento=dbo.Credito',400),
  @('/api/reportes/9?fechaCorte=2026-01-01&fechaCorte=2026-01-02',400),
  @('/api/reportes/6?codigoDeudor=1%20OR%201%3D1',400),@('/api/reportes/7?numeroCredito=%27%3BDELETE%20dbo.Credito',400),
  @('/api/reportes/1?desde=2026-01-01%27%20OR%201%3D1&hasta=2026-12-31',400)
 )){
  $e=Bien "Validación $($caso[0])" GET $caso[0] $null $caso[1]
  Comprobar 'Error no expone conexión ni mensajes internos SQL' ($e.Texto -notmatch 'Password|Server=|SqlException|stackTrace')
 }
 [void](Bien 'Reportes no admite escritura POST' POST '/api/reportes/1' @{} 405)
 $d=(Bien 'Reporte vacío conserva columnas' GET '/api/reportes/1?desde=1900-01-01&hasta=1900-01-02' $null 200).Json
 Comprobar 'Detalle vacío y agregado nulo preservados' ($d.tablas[0].filas.Count -eq 0 -and $d.tablas[0].columnas.Count -gt 0 -and $null -eq $d.tablas[1].filas[0].CapitalColocadoBruto)
 $estado='Correcto'
}finally{
 if($proceso -and -not $proceso.HasExited){Stop-Process -Id $proceso.Id}
 try{
  if($cn.State -eq 'Open'){
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
 COMMIT;
"@)
   if($inicial){Comprobar 'Registros previos de validación conservados tras retirar solo el ensayo' ((Captura) -ceq $inicial)}
  }
 }catch{$estado='Fallido';throw}finally{
  $cn.Dispose();[pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';ConexionLocalSinCifrado=[bool]$ConexionLocalSinCifrado;Fecha=(Get-Date -Format o);Pruebas=$pruebas}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $salida 'resultado.json') -Encoding UTF8
 }
}
Write-Output "Reportes: $($pruebas.Count) comprobaciones correctas."
