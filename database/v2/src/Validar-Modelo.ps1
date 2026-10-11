$ErrorActionPreference='Stop'
$dir='C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\Extensions\Application'
[void][Reflection.Assembly]::LoadFrom('C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\Microsoft.Data.SqlClient.dll')
Add-Type -Path (Join-Path $dir 'Microsoft.SqlServer.TransactSql.ScriptDom.dll')
Add-Type -Path (Join-Path $dir 'Microsoft.SqlServer.Dac.dll')
Add-Type -Path (Join-Path $dir 'Microsoft.SqlServer.Dac.Extensions.dll')
$parser=[Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser]::new($true)
$payload=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'deployment_payload.sql') -Raw
$reader=[IO.StringReader]::new($payload)
$errors=$null
$tree=$parser.Parse($reader,[ref]$errors)
$reader.Dispose()
$model=[Microsoft.SqlServer.Dac.Model.TSqlModel]::new([Microsoft.SqlServer.Dac.Model.SqlServerVersion]::Sql160,[Microsoft.SqlServer.Dac.Model.TSqlModelOptions]::new())
$count=0
try {
 foreach($batch in $tree.Batches) {
  foreach($stmt in $batch.Statements) {
   $type=$stmt.GetType().Name
   if($type -in @('CreateTableStatement','CreateIndexStatement','CreateSequenceStatement','CreateRoleStatement')){
    $model.AddObjects($payload.Substring($stmt.StartOffset,$stmt.FragmentLength));$count++
   }
  }
 }
 foreach($m in [regex]::Matches($payload,"EXEC\(N'((?:[^']|'')*)'\);",'Singleline')) {
  $model.AddObjects($m.Groups[1].Value.Replace("''","'"));$count++
 }
 try {$rawMessages=$model.Validate()}catch {Write-Output $_.Exception.ToString();throw}
 $messages=@($rawMessages | ForEach-Object {[pscustomobject]@{Tipo=$_.MessageType.ToString();Codigo=$_.ErrorCode;Mensaje=$_.Message}})
 [pscustomobject]@{Objetos=$count;Mensajes=$messages}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot '..\entrega\validacion-modelo.json') -Encoding UTF8
 $messages|ConvertTo-Json -Depth 5
 Write-Output "Objetos analizados: $count"
}finally{$model.Dispose()}

if($messages.Count -gt 0){throw 'El modelo tiene mensajes que requieren revision.'}
