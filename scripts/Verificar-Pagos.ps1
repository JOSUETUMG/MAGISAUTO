# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Conserva los datos anteriores.
param([Parameter(Mandatory)][string]$Credencial,[string]$SalidaCompilacion='bin\Pagos',[switch]$ConexionLocalSinCifrado)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$salida=Join-Path $repo 'artifacts\verificacion-pagos'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new();$proceso=$null;$estado='Fallido';$inicial=$null;$prefijo='PG'+[Guid]::NewGuid().ToString('N').Substring(0,10).ToUpper();$vin=$prefijo+'00001';$numero=$prefijo+'-01';$numero2=$prefijo+'-02';$numero3=$prefijo+'-03'
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
 foreach($ruta in @('/pagos.html','/pagos.css','/pagos.js','/','/vehiculos.html','/creditos.html','/clientes.html','/fiadores.html','/vendedores.html','/agencias.html','/lineas.html')){[void](Bien "Recurso $ruta" GET $ruta $null 200)}
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
 $p=@{numeroCredito=$numero;cuota=1;monto='1000.00';codigoTipoPago=5;responsable='Ensayo';observacion='Abono parcial';referenciaBancaria=$null}
 [void](Bien 'No recibir pago de borrador' POST $b $p 409)
 [void](Bien 'Presentar crédito de ensayo' POST "/api/creditos/$numero/presentar" $autor 204)
 [void](Bien 'Aprobar crédito de ensayo' POST "/api/creditos/$numero/aprobar" $autor 204)
 $contrato=(Peticion GET "/api/creditos/$numero").Json
 $s=(Bien 'Consultar plan y saldos iniciales' GET $saldo $null 200).Json
 Comprobar 'Doce cuotas pendientes, sin pagos' ($s.cuotas.Count -eq 12 -and [decimal]$s.totalPagado -eq 0 -and $s.saldoPorCobrar -eq $s.totalPlan -and $s.cuotas[0].estadoPago -eq 'PENDIENTE')
 $catalogos=(Bien 'Medios de pago disponibles' GET "$b/catalogos" $null 200).Json
 Comprobar 'Cinco medios con regla de referencia' ($catalogos.tiposPago.Count -ge 5 -and @($catalogos.tiposPago|Where-Object requiereReferencia).Count -ge 1)
 foreach($caso in @(@{monto='0'},@{monto='-1'},@{monto='1.001'},@{monto='10000000000000000'},@{cuota=0},@{cuota=61},@{responsable=' '},@{observacion=('x'*301)},@{referenciaBancaria=('x'*101)})){
  $mal=$p.Clone();foreach($k in $caso.Keys){$mal[$k]=$caso[$k]};[void](Bien "Validación HTTP: $($caso.Keys -join ',')" POST $b $mal 400)
 }
 $mal=$p.Clone();$mal.monto='999999';[void](Bien 'Rechazar sobrepago de cuota' POST $b $mal 409)
 $mal=$p.Clone();$mal.cuota=13;[void](Bien 'Rechazar cuota inexistente del plan' POST $b $mal 409)
 $mal=$p.Clone();$mal.codigoTipoPago=2147483647;[void](Bien 'Rechazar medio inexistente' POST $b $mal 409)
 $mal=$p.Clone();$mal.numeroCredito=$numero2;[void](Bien 'Rechazar crédito inexistente' POST $b $mal 409)
 $mal=$p.Clone();$mal.codigoTipoPago=[int]($catalogos.tiposPago|Where-Object requiereReferencia|Select-Object -First 1).codigoTipoPago
 [void](Bien 'Referencia bancaria obligatoria en SQL' POST $b $mal 409)
 Comprobar 'Errores no registran pagos' ([decimal](Peticion GET $saldo).Json.totalPagado -eq 0)
 $p['capital']='999999';$p['comprobante']='999999';$p['fechaPago']='2000-01-01'
 $r=(Bien 'Registrar primer abono parcial' POST $b $p 201).Json;$id1=$r.codigoPago;$recibo1=$r.comprobante
 Comprobar 'Identificadores y montos preservados como texto' ($r.codigoPago -is [string] -and $r.comprobante -is [string] -and $r.monto -is [string])
 Comprobar 'SQL genera recibo, fecha y reparto, ignorando campos calculados del cliente' ($r.comprobante -ne '999999' -and $r.fechaPago -notlike '2000*' -and [decimal]$r.capital -lt 1000)
 [decimal]$componentes=0;foreach($k in @('capital','interes','manejoCuenta','seguroAuto','seguroVida')){$componentes += [decimal]$r.$k};Comprobar 'Cinco componentes suman exactamente el abono' ($componentes -eq 1000)
 $detalle=(Bien 'Leer comprobante por código' GET "$b/$id1" $null 200).Json
 Comprobar 'Comprobante incluye cliente, medio y estado efectivo' ($detalle.cliente -match $prefijo -and $detalle.medioPago -and $detalle.estado -eq 'EFECTIVO' -and $detalle.registradoPor -eq 'Ensayo')
 Comprobar 'Comisión sobre abono efectivo' ([decimal]$detalle.comisionEfectiva -eq [decimal]::Round(1000*[decimal]$contrato.porcentajeComision,2))
 $s=(Peticion GET $saldo).Json
 Comprobar 'Cuota parcial con saldo exacto' ([decimal]$s.cuotas[0].saldoPendiente -eq ([decimal]$s.cuotas[0].total-1000) -and $s.cuotas[0].estadoPago -eq 'PARCIAL' -and [decimal]$s.totalPagado -eq 1000)
 foreach($criterio in @($recibo1,$numero,$prefijo,'Efectivo')){
  $lista=(Bien "Búsqueda de pago: $criterio" GET ($b+'?criterio='+[Uri]::EscapeDataString($criterio)) $null 200).Json
  Comprobar "Búsqueda encuentra recibo propio: $criterio" ($id1 -in $lista.codigoPago)
 }
 $suma=0
 foreach($tipo in $catalogos.tiposPago){
  $abono=$p.Clone();$abono.cuota=3;$abono.monto='0.01';$abono.codigoTipoPago=[int]$tipo.codigoTipoPago;$abono.referenciaBancaria=if($tipo.requiereReferencia){'  ENSAYO-'+$prefijo+'  '}else{$null}
  $r=(Bien "Registrar un centavo mediante $($tipo.descripcion)" POST $b $abono 201).Json
  [decimal]$d=0;foreach($k in @('capital','interes','manejoCuenta','seguroAuto','seguroVida')){$d+=[decimal]$r.$k};Comprobar "Reparto exacto de centavo: $($tipo.descripcion)" ($d -eq .01)
  if($tipo.requiereReferencia){Comprobar 'Referencia normalizada sin perder contenido' ($r.referenciaBancaria -ceq ('ENSAYO-'+$prefijo))}
  $suma++
 }
 [void](Bien 'Buscar referencia bancaria' GET ($b+'?criterio=ENSAYO-'+$prefijo) $null 200)
 $abono=$p.Clone();$abono.monto='2500.00';$r=(Bien 'Segundo abono en la misma cuota' POST $b $abono 201).Json
 Comprobar 'Recibos distintos para abonos de una cuota' ($r.comprobante -ne $recibo1)
 $s=(Peticion GET $saldo).Json;$abono.monto=$s.cuotas[0].saldoPendiente
 [void](Bien 'Liquidar saldo restante de cuota uno' POST $b $abono 201)
 $s=(Peticion GET $saldo).Json;Comprobar 'Cuota uno pagada sin saldo' ($s.cuotas[0].estadoPago -eq 'PAGADA' -and [decimal]$s.cuotas[0].saldoPendiente -eq 0 -and -not $s.cuotas[0].permitePago)
 [void](Bien 'No registrar otro abono sobre cuota pagada' POST $b $p 409)
 $antesPago=(Peticion GET "$b/$id1").Json
 [void](Bien 'Editar únicamente observación' PUT "$b/$id1/observacion" @{observacion='<texto de prueba> corregido';monto='999999'} 204)
 $despuesPago=(Peticion GET "$b/$id1").Json;Comprobar 'Editar conserva importe, fecha y comprobante' ($antesPago.monto -eq $despuesPago.monto -and $antesPago.fechaPago -eq $despuesPago.fechaPago -and $antesPago.comprobante -eq $despuesPago.comprobante -and $despuesPago.observacion -ceq '<texto de prueba> corregido')
 [void](Bien 'Observación demasiado larga rechazada' PUT "$b/$id1/observacion" @{observacion=('x'*301)} 400)
 # Dos peticiones HTTP independientes intentan completar la misma cuota.
 $abono.cuota=2;$abono.monto=$s.cuotas[1].saldoPendiente;$json=$abono|ConvertTo-Json -Compress
 $handler=[Net.Http.HttpClientHandler]::new();$handler.UseProxy=$false;$http=[Net.Http.HttpClient]::new($handler)
 try{
  $c1=[Net.Http.StringContent]::new($json,[Text.Encoding]::UTF8,'application/json');$c2=[Net.Http.StringContent]::new($json,[Text.Encoding]::UTF8,'application/json')
  $t1=$http.PostAsync("$url$b",$c1);$t2=$http.PostAsync("$url$b",$c2)
  $r1=$t1.GetAwaiter().GetResult();$r2=$t2.GetAwaiter().GetResult();$codigos=@([int]$r1.StatusCode,[int]$r2.StatusCode)|Sort-Object
  Comprobar 'Dos pagos simultáneos: uno aceptado y uno rechazado' ($codigos[0] -eq 201 -and $codigos[1] -eq 409)
 }finally{$http.Dispose();$c1.Dispose();$c2.Dispose();if($r1){$r1.Dispose()};if($r2){$r2.Dispose()}}
 $s=(Peticion GET $saldo).Json;Comprobar 'Concurrencia no sobrepaga ni deja saldo negativo' ([decimal]$s.cuotas[1].saldoPendiente -eq 0 -and [decimal]$s.cuotas[1].pagado -eq [decimal]$s.cuotas[1].total)
 foreach($q in $s.cuotas|Where-Object permitePago){$abono.cuota=[int]$q.cuota;$abono.monto=$q.saldoPendiente;[void](Bien "Liquidar cuota $($q.cuota)" POST $b $abono 201)}
 $s=(Peticion GET $saldo).Json;Comprobar 'Contrato liquidado al completar las doce cuotas' ($s.estado -eq 'LIQUIDADO' -and [decimal]$s.saldoPorCobrar -eq 0 -and $s.totalPagado -eq $s.totalPlan)
 [void](Bien 'No recibir pagos en crédito liquidado' POST $b $p 409)
 [void](Bien 'Anulación requiere motivo' POST "$b/$id1/anular" @{responsable='Ensayo';motivo=' '} 400)
 [void](Bien 'Anulación requiere responsable' POST "$b/$id1/anular" @{responsable=' ';motivo='Ensayo'} 400)
 $anular=@{responsable='Ensayo de anulación';motivo='Corrección del abono ficticio'}
 [void](Bien 'Anular pago conservando historial' POST "$b/$id1/anular" $anular 204)
 $s=(Peticion GET $saldo).Json;$f=(Peticion GET "$b/$id1").Json
 Comprobar 'Anulación reabre crédito y restaura Q1000 de saldo' ($s.estado -eq 'VIGENTE' -and [decimal]$s.saldoPorCobrar -eq 1000 -and [decimal]$s.cuotas[0].saldoPendiente -eq 1000)
 Comprobar 'Comprobante anulado conserva importe, motivo, actor y fecha' ($f.estado -eq 'ANULADO' -and $f.monto -eq '1000.00' -and $f.motivoAnulacion -eq $anular.motivo -and $f.anuladoPor -eq $anular.responsable -and $null -ne $f.fechaAnulacion -and [decimal]$f.comisionEfectiva -eq 0)
 [void](Bien 'Anulación repetida rechazada' POST "$b/$id1/anular" $anular 409)
 [void](Bien 'No exponer borrado físico de pago' DELETE "$b/$id1" $null 405)
 [void](Bien 'Pago inexistente al consultar' GET "$b/9223372036854775807" $null 404)
 [void](Bien 'Pago inexistente al editar' PUT "$b/9223372036854775807/observacion" @{observacion='Ensayo'} 404)
 [void](Bien 'Pago inexistente al anular' POST "$b/9223372036854775807/anular" $anular 404)
 [void](Bien 'Crédito inexistente al consultar saldos' GET "$b/credito/$numero3" $null 404)
 $historial=(Peticion GET "$b`?numeroCredito=$numero").Json
 Comprobar 'Filtro por crédito incluye el pago anulado y solo el crédito solicitado' ($id1 -in $historial.codigoPago -and @($historial|Where-Object numeroCredito -ne $numero).Count -eq 0)
 # Anular todos los pagos propios para validar saldos no cobrables del contrato anulado.
 foreach($h in $historial|Where-Object estado -eq 'EFECTIVO'){[void](Bien 'Anular pago propio de cierre del ensayo' POST "$b/$($h.codigoPago)/anular" $anular 204)}
 $s=(Peticion GET $saldo).Json;Comprobar 'Anular todos revierte pagos y comisiones efectivos' ([decimal]$s.totalPagado -eq 0 -and [decimal]$s.comisionEfectiva -eq 0 -and $s.saldoPlan -eq $s.totalPlan)
 [void](Bien 'Anular crédito sin pagos efectivos' POST "/api/creditos/$numero/anular" @{responsable='Ensayo';motivo='Fin de ensayo'} 204)
 $s=(Peticion GET $saldo).Json;Comprobar 'Crédito anulado conserva plan, sin saldo por cobrar' ($s.estado -eq 'ANULADO' -and [decimal]$s.saldoPorCobrar -eq 0 -and $s.cuotas.Count -eq 12 -and @($s.cuotas|Where-Object permitePago).Count -eq 0)
 [void](Bien 'No recibir pagos de crédito anulado' POST $b $p 409)
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
Write-Output "Pagos: $($pruebas.Count) comprobaciones correctas."
