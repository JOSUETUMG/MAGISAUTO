# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Conserva los datos anteriores.
param([string]$Credencial='C:\Users\dfern\Documents\Codex\2026-09-12\hol\work\sql-credential.xml',[string]$SalidaCompilacion='bin\CrudEntrega',[switch]$ConexionLocalSinCifrado)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$api=Join-Path $repo 'src\MAGISAUTO.API'
$salida=Join-Path $repo 'artifacts\verificacion-crud-entrega'
[void](New-Item -ItemType Directory -Force $salida)
$cred=Import-Clixml -LiteralPath $Credencial;$cred.Password.MakeReadOnly()
$cn=[Data.SqlClient.SqlConnection]::new('Server=tcp:127.0.0.1,1433;Database=MAGISAUTO_ValidacionV2;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8',[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
$pruebas=[Collections.Generic.List[object]]::new();$proceso=$null;$estado='Fallido';$inicial=$null;$prefijo='CT'+[Guid]::NewGuid().ToString('N').Substring(0,10).ToUpper();$vin=$prefijo+'00001';$numero=$prefijo+'-01';$numero2=$prefijo+'-02';$numero3=$prefijo+'-03'
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
 $migracion=(Get-Content (Join-Path $repo 'database\v2\migraciones\001_Presentacion_Creditos.sql') -Raw).Replace('USE [MAGISAUTO_Proyecto_V2]','USE [MAGISAUTO_ValidacionV2]')
 [void](Query $migracion);[void](Query $migracion);Comprobar 'Migración aditiva repetible' $true
 $cierre=Get-Content (Join-Path $repo 'database\v2\migraciones\002_Cierre_Tecnico.sql') -Raw
 [void](Query $cierre);[void](Query $cierre);Comprobar 'Migración de cierre repetible' $true
 # Usar la misma cuenta limitada que la aplicación, en el destino aislado.
 [void](Query "IF USER_ID(N'magis_api_diego') IS NULL CREATE USER magis_api_diego FOR LOGIN magis_api_diego; IF IS_ROLEMEMBER(N'magis_api',N'magis_api_diego')<>1 ALTER ROLE magis_api ADD MEMBER magis_api_diego;")
 $inicial=Captura
 $local=Get-Content (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
 $cs=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto);$cs['Initial Catalog']='MAGISAUTO_ValidacionV2'
 if($ConexionLocalSinCifrado){
  if($cs.DataSource -ne 'tcp:127.0.0.1,1433'){throw 'El modo sin cifrado solo admite loopback local.'}
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
 foreach($ruta in @('/creditos.html','/creditos.css','/creditos.js','/','/vehiculos.html')){[void](Bien "Recurso $ruta" GET $ruta $null 200)}
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
 # CRUD de valoraciones sin contrato aprobado: mismo recorrido HTTP que la interfaz.
 $val=@{codigoGarantia=[int]$ids.Vehiculo;fechaValoracion=[DateTime]::UtcNow.AddHours(-6).ToString('yyyy-MM-dd');valorOriginal='100000.00';porcentaje='15';observacion='Valoracion previa temporal'}
 $vr=Bien 'Crear valoracion previa sin contrato' POST '/api/valoraciones' $val 201
 $vid=$vr.Json.codigoDepreciacion
 [void](Bien 'Consultar valoracion previa' GET "/api/valoraciones/$vid" $null 200)
 [void](Bien 'Buscar valoracion previa' GET '/api/valoraciones?criterio=temporal' $null 200)
 $val.porcentaje='20';[void](Bien 'Editar valoracion previa' PUT "/api/valoraciones/$vid" $val 204)
 Comprobar 'Valor depreciado recalculado' ([decimal](Peticion GET "/api/valoraciones/$vid").Json.valorDepreciado -eq 80000)
 [void](Bien 'Borrar valoracion previa' DELETE "/api/valoraciones/$vid" $null 204)
 [void](Bien 'Valoracion borrada no existe' GET "/api/valoraciones/$vid" $null 404)
 $datos=@{numeroCredito=$numero;codigoDeudor=[int]$ids.Cliente;codigoGarantia=[int]$ids.Vehiculo;codigoVendedor=[int]$ids.Vendedor;enganche='20000.00';plazo=12;fiadoresRequeridos=1;fiadores=@([int]$ids.Fiador)}
 $b='/api/creditos';$ruta="$b/$numero";$autor=@{responsable='Comité de ensayo'}
 $configuracion=(Bien 'Catálogos de selección disponibles' GET "$b/catalogos" $null 200).Json.parametros[0]
 [void](Bien 'Guardar borrador con dos referencias' POST $b $datos 201)
 [void](Bien 'Número de crédito duplicado rechazado' POST $b $datos 409)
 $f=(Bien 'Consultar borrador' GET $ruta $null 200).Json
 Comprobar 'Borrador conserva condiciones y asignaciones; no genera cuotas' ($f.estado -eq 'BORRADOR' -and $f.montoFinanciado -eq '80000.00' -and $f.fiadores.Count -eq 1 -and $f.cuotas.Count -eq 0 -and $null -eq $f.fechaPresentacion)
 foreach($c in @($numero,$prefijo,$vin,'BORRADOR')){$r=Peticion GET ($b+'?criterio='+[Uri]::EscapeDataString($c));Comprobar "Búsqueda por $c" ($r.Codigo -eq 200 -and $numero -in $r.Json.numeroCredito)}
 [void](Bien 'Presentación exige tres referencias' POST "$ruta/presentar" $autor 409)
 [void](Bien 'Responsable obligatorio' POST "$ruta/presentar" @{responsable=' '} 400)
 foreach($cambio in @(@{enganche='19999.99'},@{enganche='100000.00'},@{enganche='1.001'},@{plazo=61},@{fiadores=@([int]$ids.Fiador,[int]$ids.Fiador)},@{codigoVendedor=2147483647})){
  $mal=$datos.Clone();foreach($k in $cambio.Keys){$mal[$k]=$cambio[$k]};$r=Peticion PUT $ruta $mal;Comprobar "Condiciones inválidas: $($cambio.Keys -join ',')" ($r.Codigo -in 400,409)
 }
 $f=(Peticion GET $ruta).Json;Comprobar 'Fallos de edición revierten también las asignaciones' ($f.fiadores.Count -eq 1 -and $f.fiadores[0] -eq $ids.Fiador -and $f.enganche -eq '20000.00')
 [void](Query "EXEC api.DetalleReferencia_Insertar @CodigoDeudor=$($ids.Cliente),@CodigoReferencia=$($ids.Referencia),@CodigoTipoReferencia=2,@ParentescoRelacion=N'Amistad';")
 [void](Bien 'Aprobación directa exige presentación' POST "$ruta/aprobar" $autor 409)
 [void](Bien 'Presentar expediente completo' POST "$ruta/presentar" $autor 204)
 $f=(Peticion GET $ruta).Json;Comprobar 'Presentación guarda actor y fecha sin cuotas ni aprobación' ($null -ne $f.fechaPresentacion -and $f.presentadoPor -eq $autor.responsable -and $f.estado -eq 'BORRADOR' -and $f.cuotas.Count -eq 0)
 [void](Bien 'Repetición de presentación rechazada' POST "$ruta/presentar" $autor 409)
 [void](Bien 'Editar condiciones de borrador presentado' PUT $ruta $datos 204)
 Comprobar 'Edición requiere presentar nuevamente' ($null -eq (Peticion GET $ruta).Json.fechaPresentacion)
 [void](Bien 'Presentar otra vez' POST "$ruta/presentar" $autor 204)
 [void](Query "EXEC api.DetalleReferencia_Eliminar @CodigoDeudor=$($ids.Cliente),@CodigoReferencia=$($ids.Referencia);")
 [void](Bien 'Aprobación revalida referencias después de presentar' POST "$ruta/aprobar" $autor 409)
 [void](Query "EXEC api.DetalleReferencia_Insertar @CodigoDeudor=$($ids.Cliente),@CodigoReferencia=$($ids.Referencia),@CodigoTipoReferencia=2,@ParentescoRelacion=N'Amistad';")
 $pfiador=(Query "SELECT CodigoPersona FROM dbo.Fiador WHERE CodigoFiador=$($ids.Fiador)").Tables[0].Rows[0][0]
 [void](Query "EXEC api.Telefono_Eliminar @CodigoPersona=$pfiador,@Correlativo=1;")
 [void](Bien 'Aprobación exige teléfono del fiador' POST "$ruta/aprobar" $autor 409)
 [void](Query "EXEC api.Telefono_Insertar @CodigoPersona=$pfiador,@Correlativo=1,@CodigoTipoTelefono=1,@Numero='00000000';")
 [void](Query "EXEC api.DetalleCuota_Insertar @NumeroCredito='$numero',@Cuota=1,@FechaVencimiento='2027-01-01',@Capital=10,@Interes=1; EXEC api.ResumenCredito_Insertar @NumeroCredito='$numero';")
 [void](Bien 'Aprobar solicitud y generar plan' POST "$ruta/aprobar" $autor 204)
 $f=(Peticion GET $ruta).Json;[decimal]$capital=0;[decimal]$total=0;foreach($q in $f.cuotas){$capital+=[decimal]$q.capital;$total+=[decimal]$q.total}
 Comprobar '12 cuotas liquidan Q80000 de capital' ($f.estado -eq 'VIGENTE' -and $f.cuotas.Count -eq 12 -and $capital -eq 80000)
 Comprobar 'Aprobación reemplaza simulación y resumen previo' ([decimal]$f.totalIntereses -gt 1 -and [decimal]$f.cuotas[0].capital -gt 10)
 Comprobar 'Total neto coincide con suma de cuotas, sin enganche' ([decimal]$f.totalNetoRecaudable -eq $total)
 Comprobar 'Manejo Q25 y seguros sobre monto inicial según configuración existente' ([decimal]$f.cuotas[0].manejoCuenta -eq 25 -and [decimal]$f.cuotas[0].seguroAuto -eq [decimal]::Round(80000*[decimal]$configuracion.tasaSeguroAuto,2) -and [decimal]$f.cuotas[0].seguroVida -eq [decimal]::Round(80000*[decimal]$configuracion.tasaSeguroVida,2))
 Comprobar 'Una valoración inicial automática' ((Query "SELECT COUNT(*) FROM dbo.Depreciacion WHERE CodigoGarantia=$($ids.Vehiculo)").Tables[0].Rows[0][0] -eq 1)
 $protegida=(Query "SELECT CodigoDepreciacion FROM dbo.Depreciacion WHERE CodigoGarantia=$($ids.Vehiculo)").Tables[0].Rows[0][0]
 [void](Bien 'Valoracion contractual no editable' PUT "/api/valoraciones/$protegida" $val 409)
 [void](Bien 'Valoracion contractual no borrable' DELETE "/api/valoraciones/$protegida" $null 409)
 [void](Bien 'Aprobación duplicada rechazada' POST "$ruta/aprobar" $autor 409)
 [void](Bien 'Crédito aprobado no se edita' PUT $ruta $datos 409)
 [void](Bien 'Crédito aprobado no se elimina' DELETE $ruta $null 409)
 $otro=$datos.Clone();$otro.numeroCredito=$numero2;[void](Bien 'Otro borrador puede evaluar el mismo vehículo' POST $b $otro 201)
 [void](Bien 'Presentar segundo borrador' POST "$b/$numero2/presentar" $autor 204)
 [void](Bien 'Vehículo impide dos contratos vigentes' POST "$b/$numero2/aprobar" $autor 409)
 [void](Bien 'Eliminar borrador con sus asignaciones' DELETE "$b/$numero2" $null 204)
 [void](Bien 'El borrador eliminado no existe' GET "$b/$numero2" $null 404)
 [void](Bien 'Anulación requiere motivo' POST "$ruta/anular" $autor 400)
 [void](Query "EXEC api.DetallePago_Insertar @NumeroCredito='$numero',@Cuota=1,@Monto=100,@CodigoTipoPago=5,@Responsable=N'Ensayo';")
 [void](Bien 'Pagos efectivos impiden anular' POST "$ruta/anular" @{responsable='Ensayo';motivo='Prueba'} 409)
 $pago=(Query "SELECT CodigoPago FROM dbo.DetallePago WHERE NumeroCredito='$numero'").Tables[0].Rows[0][0]
 [void](Bien 'Pago efectivo no se elimina' DELETE "/api/pagos/$pago" $null 409)
 [void](Bien 'Pago efectivo conservado tras rechazo' GET "/api/pagos/$pago" $null 200)
 [void](Query "EXEC api.DetallePago_Anular @CodigoPago=$pago,@Motivo=N'Fin de ensayo',@Responsable=N'Ensayo';")
 $saldoAntesBorrar=(Peticion GET "/api/pagos/credito/$numero").Texto
 [void](Bien 'Borrado fisico de pago anulado' DELETE "/api/pagos/$pago" $null 204)
 [void](Bien 'Pago borrado ya no existe' GET "/api/pagos/$pago" $null 404)
 [void](Bien 'Segundo borrado devuelve no encontrado' DELETE "/api/pagos/$pago" $null 404)
 Comprobar 'Borrado de anulado conserva saldo y comision efectivos' ((Peticion GET "/api/pagos/credito/$numero").Texto -ceq $saldoAntesBorrar)
 Comprobar 'Fila fisicamente retirada' ((Query "SELECT COUNT(*) FROM dbo.DetallePago WHERE CodigoPago=$pago").Tables[0].Rows[0][0] -eq 0)
 [void](Bien 'Anular conserva el contrato' POST "$ruta/anular" @{responsable='Ensayo';motivo='Fin de ensayo'} 204)
 $f=(Peticion GET $ruta).Json;Comprobar 'Historial de aprobación, cuotas y motivo conservados' ($f.estado -eq 'ANULADO' -and $f.cuotas.Count -eq 12 -and $null -ne $f.fechaAprobacion -and $f.motivoAnulacion -eq 'Fin de ensayo')
 [void](Bien 'Contrato anulado no se elimina' DELETE $ruta $null 409)
 $otro.numeroCredito=$numero3;$otro.fiadores=@();$otro.fiadoresRequeridos=0
 [void](Bien 'Comité puede requerir cero fiadores' POST $b $otro 201)
 [void](Bien 'Eliminar segundo borrador sin fiadores' DELETE "$b/$numero3" $null 204)
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
  $cn.Dispose();[pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';Fecha=(Get-Date -Format o);ConexionLocalSinCifrado=[bool]$ConexionLocalSinCifrado;Pruebas=$pruebas}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $salida 'resultado.json') -Encoding UTF8
 }
}
Write-Output "Créditos: $($pruebas.Count) comprobaciones correctas."
