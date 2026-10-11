$ErrorActionPreference='Stop'
Add-Type -Path 'C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\Extensions\Application\Microsoft.SqlServer.TransactSql.ScriptDom.dll'
$parser=[Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser]::new($true)
$total=0
$failures=[System.Collections.Generic.List[object]]::new()
function Parse-Sql([string]$sql,[string]$name) {
 $reader=[IO.StringReader]::new($sql)
 $errors=$null
 try {$tree=$parser.Parse($reader,[ref]$errors)}finally{$reader.Dispose()}
 foreach($e in $errors){$failures.Add([pscustomobject]@{Archivo=$name;Linea=$e.Line;Columna=$e.Column;Mensaje=$e.Message})}
 $script:total++
}
$payload=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'deployment_payload.sql') -Raw
Parse-Sql $payload 'Objetos y semillas'
Parse-Sql (Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\entrega\MAGISAUTO_Proyecto_Completo.sql') -Raw) 'Instalador completo'
$i=0
foreach($m in [regex]::Matches($payload,"EXEC\(N'((?:[^']|'')*)'\);",'Singleline')) {
 $i++;$sql=$m.Groups[1].Value.Replace("''", "'")
 Parse-Sql $sql ('Modulo '+$i+' '+$sql.Substring(0,[Math]::Min(90,$sql.Length)))
}
[pscustomobject]@{BloquesAnalizados=$total;Errores=@($failures)} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot '..\entrega\validacion-sintaxis.json') -Encoding UTF8
if($failures.Count){$failures|ConvertTo-Json -Depth 5;exit 1}
Write-Output "Sintaxis correcta en $total bloques y modulos."
