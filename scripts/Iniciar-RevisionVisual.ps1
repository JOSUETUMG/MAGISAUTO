# Servidor temporal de revisión: únicamente base aislada y loopback.
$ErrorActionPreference='Stop'
$api=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/MAGISAUTO.API'
$local=Get-Content (Join-Path $api 'appsettings.Local.json') -Raw|ConvertFrom-Json
$cadena=[Data.SqlClient.SqlConnectionStringBuilder]::new($local.ConnectionStrings.MagisAuto)
$cadena['Initial Catalog']='MAGISAUTO_ValidacionV2'
$env:ConnectionStrings__MagisAuto=$cadena.ConnectionString
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:DOTNET_ENVIRONMENT='Development'
Set-Location $api
dotnet bin/Reportes/MAGISAUTO.API.dll --urls http://127.0.0.1:5189
