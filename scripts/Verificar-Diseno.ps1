param([string]$Node='node',[string]$SalidaCompilacion='bin/Reportes',[switch]$IncluirMantenimiento)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$salida=Join-Path $repo 'artifacts/diseno-dom'
[void](New-Item -ItemType Directory -Force $salida)
$proceso=$null
try {
 $proceso=Start-Process pwsh -ArgumentList @('-NoProfile','-File',('"'+(Join-Path $PSScriptRoot 'Iniciar-RevisionVisual.ps1')+'"'),'-SalidaCompilacion',$SalidaCompilacion) -WorkingDirectory $repo -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $salida 'servidor.log') -RedirectStandardError (Join-Path $salida 'error.log')
 $listo=$false
 for($i=0;$i -lt 30;$i++){try{[void](Invoke-RestMethod http://127.0.0.1:5189/api/reportes -NoProxy -TimeoutSec 2);$listo=$true;break}catch{};Start-Sleep -Milliseconds 200}
 if(-not $listo){throw 'API de revisión no disponible'}
 & $Node (Join-Path $PSScriptRoot 'Verificar-DisenoDOM.cjs')
 if($LASTEXITCODE -ne 0){throw 'Falló el ensayo de DOM'}
 if($IncluirMantenimiento){
  $anteriorUrl=$env:MAGIS_TEST_URL
  try{$env:MAGIS_TEST_URL='http://127.0.0.1:5189'; & $Node (Join-Path $PSScriptRoot 'Verificar-MantenimientoDOM.cjs'); if($LASTEXITCODE -ne 0){throw 'Falló el DOM de mantenimiento'}}finally{$env:MAGIS_TEST_URL=$anteriorUrl}
 }
}finally{
 if($proceso){if(-not $proceso.HasExited){$proceso.Kill($true);$proceso.WaitForExit()};$proceso.Dispose()}
}
