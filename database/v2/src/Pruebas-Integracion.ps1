param([string]$Servidor='tcp:127.0.0.1,1433',[string]$Base='MAGISAUTO_ValidacionV2',[string]$Credencial)
$ErrorActionPreference='Stop'
if($Base -ne 'MAGISAUTO_ValidacionV2'){throw 'Este ensayo solo permite MAGISAUTO_ValidacionV2.'}
$cs="Server=$Servidor;Database=$Base;Encrypt=True;TrustServerCertificate=True;Connect Timeout=8"
if($Credencial){
 $cred=Import-Clixml -LiteralPath $Credencial
 $cred.Password.MakeReadOnly()
 $conn=[System.Data.SqlClient.SqlConnection]::new($cs,[System.Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))
}else{$conn=[System.Data.SqlClient.SqlConnection]::new($cs+';Integrated Security=True')}
$results=[Collections.Generic.List[object]]::new()
function Query([string]$sql){
 $cmd=$conn.CreateCommand();$cmd.CommandTimeout=60;$cmd.CommandText=$sql
 $ds=[Data.DataSet]::new();$da=[Data.SqlClient.SqlDataAdapter]::new($cmd)
 try{[void]$da.Fill($ds);return ,$ds}finally{$da.Dispose();$cmd.Dispose()}
}
function Check([string]$name,[string]$sql){
 $ds=Query $sql
 if([int]$ds.Tables[0].Rows[0][0] -ne 1){throw "Fallo: $name"}
 $results.Add([pscustomobject]@{Prueba=$name;Resultado='Correcto'})
}
function Reject([string]$name,[string]$sql,[int]$code){
 try{[void](Query $sql)}catch{
  $ex=$_.Exception;while($ex.InnerException){$ex=$ex.InnerException}
  if($ex -is [System.Data.SqlClient.SqlException] -and $ex.Number -eq $code){$results.Add([pscustomobject]@{Prueba=$name;Resultado='Rechazo esperado';Codigo=$code});return}
  throw
 }
 throw "No se rechazo: $name"
}
$out=Join-Path $PSScriptRoot '..\entrega\validacion-integracion.json'
try{
 $conn.Open()
 Check 'Destino aislado y operaciones vacias' "SELECT CASE WHEN DB_NAME()='MAGISAUTO_ValidacionV2' AND NOT EXISTS(SELECT 1 FROM dbo.Credito) AND NOT EXISTS(SELECT 1 FROM dbo.Persona) THEN 1 ELSE 0 END;"
 Check 'Inventario 26 tablas, 4 vistas, 150 procedimientos, 20 reportes' "SELECT CASE WHEN (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)=26 AND (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped=0)=4 AND (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('api'))=150 AND (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('api') AND name LIKE 'Reporte%')=20 THEN 1 ELSE 0 END;"
 [void](Query (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixture-validacion.sql') -Raw))
 Check '12 cuotas, capital Q80000 y vencimiento desde el dia original' "SELECT CASE WHEN COUNT(*)=12 AND SUM(Capital)=80000 AND MIN(FechaVencimiento)='20200229' AND MAX(FechaVencimiento)='20210131' AND MAX(CASE WHEN Cuota=2 THEN FechaVencimiento END)='20200331' THEN 1 ELSE 0 END FROM dbo.DetalleCuota WHERE NumeroCredito='PRUEBA-01';"
 Check 'Desglose fijo del contrato' "SELECT CASE WHEN COUNT(*)=12 AND MIN(ManejoCuenta)=25 AND MAX(ManejoCuenta)=25 AND MIN(SeguroAuto)=120 AND MAX(SeguroAuto)=120 AND MIN(SeguroVida)=40 AND MAX(SeguroVida)=40 AND SUM(Total)=SUM(Capital+Interes+ManejoCuenta+SeguroAuto+SeguroVida) THEN 1 ELSE 0 END FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito='PRUEBA-01';"
 Check 'Resumen coincide exactamente con el plan' "SELECT CASE WHEN r.TotalIntereses=q.I AND r.TotalNetoRecaudable=q.T THEN 1 ELSE 0 END FROM dbo.ResumenCredito r CROSS APPLY(SELECT SUM(Interes) I,SUM(Total) T FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=r.NumeroCredito)q WHERE r.NumeroCredito='PRUEBA-01';"
 Check 'Cuota base francesa fija salvo ajuste final' "SELECT CASE WHEN MIN(Capital+Interes)=MAX(Capital+Interes) THEN 1 ELSE 0 END FROM dbo.DetalleCuota WHERE NumeroCredito='PRUEBA-01' AND Cuota<12;"
 Reject 'Enganche menor al 20 por ciento' "DECLARE @d int=(SELECT CodigoDeudor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@g int=(SELECT CodigoGarantia FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@v int=(SELECT CodigoVendedor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'); EXEC api.Credito_Insertar @NumeroCredito='PRUEBA-MINIMO',@CodigoDeudor=@d,@CodigoGarantia=@g,@CodigoVendedor=@v,@Enganche=19999.99;" 51104
 Reject 'Plazo fuera de los acordados' "DECLARE @d int=(SELECT CodigoDeudor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@g int=(SELECT CodigoGarantia FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@v int=(SELECT CodigoVendedor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'); EXEC api.Credito_Insertar @NumeroCredito='PRUEBA-PLAZO',@CodigoDeudor=@d,@CodigoGarantia=@g,@CodigoVendedor=@v,@Enganche=20000,@Plazo=61;" 51100
 [void](Query "DECLARE @d int=(SELECT CodigoDeudor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@g int=(SELECT CodigoGarantia FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@v int=(SELECT CodigoVendedor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'); EXEC api.Credito_Insertar @NumeroCredito='PRUEBA-VIN',@CodigoDeudor=@d,@CodigoGarantia=@g,@CodigoVendedor=@v,@Enganche=20000,@FiadoresRequeridos=0;")
 Reject 'Vehiculo con otro credito activo' "EXEC api.Credito_Aprobar @NumeroCredito='PRUEBA-VIN',@Responsable=N'Ensayo';" 51112
 Check 'Rechazo de aprobacion no deja plan parcial' "SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM dbo.DetalleCuota WHERE NumeroCredito='PRUEBA-VIN') AND NOT EXISTS(SELECT 1 FROM dbo.ResumenCredito WHERE NumeroCredito='PRUEBA-VIN') AND (SELECT Estado FROM dbo.Credito WHERE NumeroCredito='PRUEBA-VIN')='BORRADOR' THEN 1 ELSE 0 END;"
 [void](Query "EXEC api.Credito_Eliminar @NumeroCredito='PRUEBA-VIN';")
 Reject 'No volver a aprobar' "EXEC api.Credito_Aprobar @NumeroCredito='PRUEBA-01',@Responsable=N'Ensayo';" 51111
 Reject 'No editar condiciones aprobadas' "DECLARE @d int=(SELECT CodigoDeudor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@g int=(SELECT CodigoGarantia FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'),@v int=(SELECT CodigoVendedor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'); EXEC api.Credito_Actualizar @NumeroCredito='PRUEBA-01',@CodigoDeudor=@d,@CodigoGarantia=@g,@CodigoVendedor=@v,@Enganche=20000;" 51106
 Reject 'No borrar credito aprobado' "EXEC api.Credito_Eliminar @NumeroCredito='PRUEBA-01';" 51108
 Reject 'No sobrepagar una cuota' "EXEC api.DetallePago_Insertar @NumeroCredito='PRUEBA-01',@Cuota=1,@Monto=99999,@CodigoTipoPago=5,@Responsable=N'Ensayo',@FechaPago='20200229';" 51209
 Reject 'Referencia bancaria obligatoria' "EXEC api.DetallePago_Insertar @NumeroCredito='PRUEBA-01',@Cuota=1,@Monto=100,@CodigoTipoPago=1,@Responsable=N'Ensayo',@FechaPago='20200229';" 51207
 Reject 'Rechazar monto cero' "EXEC api.DetallePago_Insertar @NumeroCredito='PRUEBA-01',@Cuota=1,@Monto=0,@CodigoTipoPago=5,@Responsable=N'Ensayo';" 51200
 [void](Query "EXEC api.DetallePago_Insertar @NumeroCredito='PRUEBA-01',@Cuota=1,@Monto=100.01,@CodigoTipoPago=5,@Responsable=N'Ensayo',@FechaPago='20200229';")
 Check 'Monto depositado igual al desglose y comision Q2.00' "SELECT CASE WHEN Monto=100.01 AND Monto=Capital+Interes+ManejoCuenta+SeguroAuto+SeguroVida AND Comision=2.00 THEN 1 ELSE 0 END FROM dbo.vw_PagoDesglosado WHERE NumeroCredito='PRUEBA-01';"
 Check 'Mora desde el dia posterior al vencimiento' "SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM dbo.fn_Saldos('20200229') WHERE NumeroCredito='PRUEBA-01' AND FechaVencimiento<'20200229' AND SaldoPendiente>0) AND EXISTS(SELECT 1 FROM dbo.fn_Saldos('20200301') WHERE NumeroCredito='PRUEBA-01' AND FechaVencimiento<'20200301' AND SaldoPendiente>0) THEN 1 ELSE 0 END;"
 [void](Query "DECLARE @c int=(SELECT CodigoParametro FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'); EXEC api.ParametroCredito_Actualizar @CodigoParametro=@c,@Nombre=N'Parametros modificados para prueba',@Activo=1,@TasaAnual=0.15,@ManejoMensual=25,@TasaSeguroAuto=0.003,@TasaSeguroVida=0.001,@EngancheMinimo=0.20,@ComisionPredeterminada=0.03,@DepreciacionInicial=0.15;")
 Check 'Cambiar parametros no altera contrato aprobado ni seguros ni comision' "SELECT CASE WHEN c.TasaAnual=0.125 AND c.PorcentajeComision=0.02 AND (SELECT MIN(SeguroAuto) FROM dbo.vw_CuotaDesglosada WHERE NumeroCredito=c.NumeroCredito)=120 AND (SELECT MIN(Comision) FROM dbo.vw_PagoDesglosado WHERE NumeroCredito=c.NumeroCredito)=2 THEN 1 ELSE 0 END FROM dbo.Credito c WHERE c.NumeroCredito='PRUEBA-01';"
 [void](Query "DECLARE @id bigint=(SELECT MIN(CodigoPago) FROM dbo.DetallePago WHERE NumeroCredito='PRUEBA-01'); EXEC api.DetallePago_Anular @CodigoPago=@id,@Motivo=N'Ensayo de anulacion',@Responsable=N'Ensayo';")
 Check 'Anular conserva comprobante y saldo historico anterior' "SELECT CASE WHEN (SELECT COUNT(*) FROM dbo.DetallePago WHERE NumeroCredito='PRUEBA-01')=1 AND (SELECT Total-SaldoPendiente FROM dbo.fn_Saldos('20200301') WHERE NumeroCredito='PRUEBA-01' AND Cuota=1)=100.01 AND (SELECT Total-SaldoPendiente FROM dbo.fn_Saldos(CONVERT(date,dbo.fn_AhoraGuatemala())) WHERE NumeroCredito='PRUEBA-01' AND Cuota=1)=0 THEN 1 ELSE 0 END;"
 Reject 'No anular dos veces' "DECLARE @id bigint=(SELECT MIN(CodigoPago) FROM dbo.DetallePago WHERE NumeroCredito='PRUEBA-01'); EXEC api.DetallePago_Anular @CodigoPago=@id,@Motivo=N'Ensayo',@Responsable=N'Ensayo';" 51218
 [void](Query "DECLARE @n smallint=1,@importe decimal(18,2); WHILE @n<=12 BEGIN SELECT @importe=SaldoPendiente FROM dbo.fn_Saldos(CONVERT(date,dbo.fn_AhoraGuatemala())) WHERE NumeroCredito='PRUEBA-01' AND Cuota=@n; EXEC api.DetallePago_Insertar @NumeroCredito='PRUEBA-01',@Cuota=@n,@Monto=@importe,@CodigoTipoPago=5,@Responsable=N'Ensayo'; SET @n+=1; END;")
 Check 'Liquidacion total y recibos unicos' "SELECT CASE WHEN (SELECT Estado FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01')='LIQUIDADO' AND (SELECT SUM(SaldoPendiente) FROM dbo.fn_Saldos(CONVERT(date,dbo.fn_AhoraGuatemala())) WHERE NumeroCredito='PRUEBA-01')=0 AND (SELECT COUNT(*)-COUNT(DISTINCT Comprobante) FROM dbo.DetallePago)=0 THEN 1 ELSE 0 END;"
 [void](Query "DECLARE @id bigint=(SELECT MAX(CodigoPago) FROM dbo.DetallePago WHERE NumeroCredito='PRUEBA-01'); EXEC api.DetallePago_Anular @CodigoPago=@id,@Motivo=N'Ensayo de reapertura',@Responsable=N'Ensayo';")
 Check 'Anular pago reabre credito liquidado' "SELECT CASE WHEN Estado='VIGENTE' THEN 1 ELSE 0 END FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01';"
 # All reports must bind and execute, including views with the relocated columns.
 $inv=Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\entrega\reportes.json') -Raw | ConvertFrom-Json
 foreach($r in $inv){
  $args=switch([int]$r.numero){
   {$_ -in 1,3,4,8,13,19,20}{"@Desde='20200101',@Hasta=@h";break}
   5{'@Mes=1,@Anio=2026';break}
   6{'@CodigoDeudor=@d,@FechaCorte=@h';break}
   7{"@NumeroCredito='PRUEBA-01',@FechaCorte=@h";break}
   default{'@FechaCorte=@h'}
  }
  [void](Query "DECLARE @h date=CONVERT(date,dbo.fn_AhoraGuatemala()),@d int=(SELECT CodigoDeudor FROM dbo.Credito WHERE NumeroCredito='PRUEBA-01'); EXEC $($r.procedimiento) $args;")
  $results.Add([pscustomobject]@{Prueba=$r.procedimiento;Resultado='Ejecutado'})
 }
 Check 'No hay FK deshabilitadas ni no confiables' "SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1) THEN 1 ELSE 0 END;"
 # Two independent sessions attempt to settle the same last unpaid quota.
 $balance=Query "SELECT SaldoPendiente FROM dbo.fn_Saldos(CONVERT(date,dbo.fn_AhoraGuatemala())) WHERE NumeroCredito='PRUEBA-01' AND Cuota=12;"
 $amount=[decimal]$balance.Tables[0].Rows[0][0]
 $sessions=@();$commands=@();$tasks=@();$success=0;$rejected=0
 try{
  for($i=0;$i -lt 2;$i++){
   if($Credencial){$cx=[Data.SqlClient.SqlConnection]::new($cs,[Data.SqlClient.SqlCredential]::new($cred.UserName,$cred.Password))}else{$cx=[Data.SqlClient.SqlConnection]::new($cs+';Integrated Security=True')}
   $cx.Open();$sessions+=,$cx
   $cmd=$cx.CreateCommand();$cmd.CommandTimeout=30
   $cmd.CommandText="WAITFOR DELAY '00:00:01'; EXEC api.DetallePago_Insertar @NumeroCredito='PRUEBA-01',@Cuota=12,@Monto=@m,@CodigoTipoPago=5,@Responsable=N'Ensayo concurrente';"
   $p=$cmd.Parameters.Add('@m',[Data.SqlDbType]::Decimal);$p.Precision=18;$p.Scale=2;$p.Value=$amount
   $commands+=,$cmd;$tasks+=,$cmd.ExecuteNonQueryAsync()
  }
  foreach($task in $tasks){try{[void]$task.GetAwaiter().GetResult();$success++}catch{$ex=$_.Exception;while($ex.InnerException){$ex=$ex.InnerException};if($ex -is [Data.SqlClient.SqlException] -and $ex.Number -in 51203,51209,51210){$rejected++}else{throw}}}
  if($success -ne 1 -or $rejected -ne 1){throw 'Concurrencia: se esperaba un solo pago aceptado.'}
  Check 'Dos pagos simultaneos no sobrepagan' "SELECT CASE WHEN SUM(SaldoPendiente)=0 AND MIN(SaldoPendiente)=0 THEN 1 ELSE 0 END FROM dbo.fn_Saldos(CONVERT(date,dbo.fn_AhoraGuatemala())) WHERE NumeroCredito='PRUEBA-01';"
 }finally{foreach($cmd in $commands){$cmd.Dispose()};foreach($cx in $sessions){$cx.Dispose()}}
 [pscustomobject]@{Estado='Correcto';Base=$Base;Fecha=(Get-Date -Format o);Pruebas=$results} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $out -Encoding UTF8
 Write-Output "Pruebas correctas: $($results.Count). Datos ficticios conservados solo en $Base."
}catch{
 [pscustomobject]@{Estado='Fallido';Base=$Base;Fecha=(Get-Date -Format o);Pruebas=$results;Error=$_.Exception.Message} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $out -Encoding UTF8
 throw
}finally{$conn.Dispose()}
