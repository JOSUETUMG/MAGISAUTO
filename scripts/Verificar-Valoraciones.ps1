# Ensayo exclusivamente en MAGISAUTO_ValidacionV2. Inserta una valoración temporal y la retira al finalizar.
param([string]$Credencial='C:\Users\dfern\Documents\Codex\2026-09-12\hol\work\sql-credential.xml',[string]$SalidaCompilacion='bin\Valoraciones')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent;$api=Join-Path $repo 'src\MAGISAUTO.API';$salida=Join-Path $repo 'artifacts\verificacion-valoraciones'
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
 $base='/api/valoraciones';$lista=(Peticion GET $base);Comprobar 'Listado de valoraciones disponible' ($lista.Codigo -eq 200 -and @($lista.Json).Count -gt 0)
 $original=@($lista.Json|Where-Object protegidaPorContrato|Select-Object -First 1);Comprobar 'Existe valoración inicial contractual para el ensayo' ($original.Count -eq 1);$v=$original[0]
 Comprobar 'Porcentaje se devuelve en unidades humanas' ([decimal]$v.porcentaje -ge 15 -and [decimal]$v.porcentaje -le 20)
 Comprobar 'Consulta por vehículo' ((Peticion GET "${base}?codigoGarantia=$($v.codigoGarantia)").Codigo -eq 200)
 Comprobar 'Búsqueda vacía rechazada' ((Peticion GET "${base}?criterio=").Codigo -eq 400)
 Comprobar 'Filtro desconocido rechazado' ((Peticion GET "${base}?otro=1").Codigo -eq 400)
 Comprobar 'Detalle individual disponible' ((Peticion GET "$base/$($v.codigoDepreciacion)").Codigo -eq 200)
 $hoy=[DateTime]::UtcNow.AddHours(-6).ToString('yyyy-MM-dd')
 $marca='ENSAYO-'+[Guid]::NewGuid().ToString('N')
 $datos=@{codigoGarantia=$v.codigoGarantia;fechaValoracion=$hoy;valorOriginal='85000.00';porcentaje='15';observacion=$marca}
 $credito=(Query "SELECT TOP(1) NumeroCredito FROM dbo.Credito WHERE CodigoGarantia=$($v.codigoGarantia) AND FechaAprobacion IS NOT NULL ORDER BY NumeroCredito").Tables[0].Rows[0][0]
 $contratoAntes=(Peticion GET "/api/creditos/$credito").Texto
 $reportesAntes=@{};foreach($idReporte in @(16,17)){$reportesAntes[$idReporte]=(Peticion GET "/api/reportes/${idReporte}?fechaCorte=$hoy").Json}
 foreach($filtro in @('?criterio=a&criterio=b','?codigoGarantia=','?codigoGarantia=1&codigoGarantia=2')){Comprobar "Filtro rechazado: $filtro" ((Peticion GET "$base$filtro").Codigo -eq 400)}
 foreach($cambio in @(@{valorOriginal='0'},@{valorOriginal='-1'},@{valorOriginal='1.001'},@{porcentaje='21'},@{porcentaje='15.00001'},@{observacion=' '},@{observacion=('x'*301)},@{fechaValoracion='0001-01-01'})){
  $mal=$datos.Clone();foreach($k in $cambio.Keys){$mal[$k]=$cambio[$k]};Comprobar "Validación $($cambio.Keys) $($cambio.Values)" ((Peticion POST $base $mal).Codigo -eq 400)
 }
 Comprobar 'Fecha futura rechazada' ((Peticion POST $base (@{codigoGarantia=$v.codigoGarantia;fechaValoracion='2100-01-01';valorOriginal='100000';porcentaje='15';observacion='Ensayo'})).Codigo -eq 400)
 Comprobar 'Porcentaje fuera de rango rechazado' ((Peticion POST $base (@{codigoGarantia=$v.codigoGarantia;fechaValoracion=(Get-Date).ToString('yyyy-MM-dd');valorOriginal='100000';porcentaje='14.99';observacion='Ensayo'})).Codigo -eq 400)
 $r=Peticion POST $base $datos;if($r.Codigo -eq 201){$creada=[int]$r.Json.codigoDepreciacion};Comprobar 'Registro de valoración posterior' ($r.Codigo -eq 201 -and $creada -gt 0)
 $nueva=(Peticion GET "$base/$creada").Json;Comprobar 'Cálculo exacto Q85000 al 15% = Q72250' ([decimal]$nueva.porcentaje -eq 15 -and [decimal]$nueva.valorDepreciado -eq 72250)
 Comprobar 'Buscar observación devuelve solo la valoración propia' (@((Peticion GET "${base}?criterio=$marca").Json).Count -eq 1)
 Comprobar 'Búsqueda sin resultados' (@((Peticion GET "${base}?criterio=NO-$marca").Json).Count -eq 0)
 Comprobar 'Registro no modifica crédito, comisión ni cuotas' ((Peticion GET "/api/creditos/$credito").Texto -ceq $contratoAntes)
 foreach($idReporte in @(16,17)){
  $reporte=Peticion GET "/api/reportes/${idReporte}?fechaCorte=$hoy"
  Comprobar "Reporte $idReporte disponible" ($reporte.Codigo -eq 200)
  $fila=@($reporte.Json.tablas[0].filas|Where-Object { $_['NumeroCredito'] -eq $credito })[0]
  Comprobar "Reporte $idReporte usa nueva valoración Q72250" ($null -ne $fila -and [decimal]$fila['ValorDepreciado'] -eq 72250)
  $previa=@($reportesAntes[$idReporte].tablas[0].filas|Where-Object { $_['NumeroCredito'] -eq $credito })[0]
  $campos=if($idReporte -eq 16){@('CapitalPendiente','PrecioContado')}else{@('MontoFinanciado','TotalIntereses','TotalNetoRecaudable','Enganche')}
  foreach($campo in $campos){Comprobar "Reporte $idReporte conserva $campo" ($fila[$campo] -ceq $previa[$campo])}
 }
 Comprobar 'Historial contractual bloquea edición' ((Peticion PUT "$base/$creada" $datos).Codigo -eq 409)
 Comprobar 'Historial contractual bloquea eliminación' ((Peticion DELETE "$base/$creada").Codigo -eq 409)
 $estado='Correcto'
}finally{
 if($null -ne $creada -and $cn.State -eq 'Open'){[void](Query "IF DB_NAME()<>'MAGISAUTO_ValidacionV2' THROW 52000,'Destino incorrecto',1; DELETE dbo.Depreciacion WHERE CodigoDepreciacion=$creada AND Observacion=N'$marca';")}
 if($proceso){if(-not $proceso.HasExited){$proceso.Kill($true);$proceso.WaitForExit()};$proceso.Dispose()}
 if($cn.State -eq 'Open'){$despues=Captura;Comprobar 'Limpieza restaura las 26 tablas' ($antes -ceq $despues);$cn.Close()};$cn.Dispose();$resultado=[pscustomobject]@{Estado=$estado;Base='MAGISAUTO_ValidacionV2';Pruebas=$pruebas};$resultado|ConvertTo-Json -Depth 6|Set-Content (Join-Path $salida 'resultado.json') -Encoding UTF8
}
