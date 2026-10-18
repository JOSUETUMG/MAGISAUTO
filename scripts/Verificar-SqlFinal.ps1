# Analiza SQL externo e interno. No ejecuta el instalador ni modifica bases.
param([string]$ScriptDom='C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\Extensions\Application\Microsoft.SqlServer.TransactSql.ScriptDom.dll')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
if(-not (Test-Path -LiteralPath $ScriptDom)){throw 'Indique -ScriptDom con la DLL del analizador T-SQL instalada en su equipo.'}
Add-Type -Path $ScriptDom
$parser=[Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser]::new($true)
$checks=[Collections.Generic.List[object]]::new()
function Parse([string]$name,[string]$sql){
 $errors=$null;$reader=[IO.StringReader]::new($sql)
 try{$null=$parser.Parse($reader,[ref]$errors)}finally{$reader.Dispose()}
 if($errors.Count){throw ($name+': '+(($errors|ForEach-Object{"linea $($_.Line): $($_.Message)"}) -join '; '))}
 $checks.Add([pscustomobject]@{Prueba=$name;Resultado='Correcto'})
}
$file=Join-Path $repo 'database/final/MAGISAUTO_Final.sql'
$sql=Get-Content -LiteralPath $file -Raw
Parse 'Instalador externo' $sql
$marker="DECLARE @Carga nvarchar(max)=N'USE '+QUOTENAME(@Base)+N';"
$start=$sql.IndexOf($marker,[StringComparison]::Ordinal)
if($start -lt 0){throw 'No se encontro la carga dinamica.'}
$end=$sql.LastIndexOf("';",[StringComparison]::Ordinal)
$body=$sql.Substring($start+$marker.Length,$end-$start-$marker.Length).Replace("''","'")
Parse 'Carga transaccional desescapada' $body
$modules=[regex]::Matches($body,"EXEC\(N'((?:[^']|'')*)'\);",[Text.RegularExpressions.RegexOptions]::Singleline)
$count=0
foreach($m in $modules){
 $definition=$m.Groups[1].Value.Replace("''","'")
 Parse ('Lote interno '+(++$count)) $definition
}
if($count -ne 161){throw "Se esperaban 160 modulos mas CREATE SCHEMA; se encontraron $count."}
$hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
$manifest=Get-Content (Join-Path $repo 'database/final/manifest.json') -Raw|ConvertFrom-Json
if($hash -cne $manifest.sha256){throw 'El hash no coincide con el manifiesto.'}
[pscustomobject]@{Estado='Correcto';Sha256=$hash;Analizador='TSql160Parser';Comprobaciones=$checks;Limite='Validacion sintactica; no equivale a instalacion nueva en SQL Server.'}|ConvertTo-Json -Depth 5|Set-Content (Join-Path $repo 'database/final/validacion-sintaxis.json') -Encoding utf8
Write-Output "$($checks.Count) lotes SQL analizados sin errores; hash correcto."
