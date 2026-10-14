# Preparacion LOCAL para un clon nuevo. No instala SQL ni publica cambios en Git.
param(
 [string]$Servidor='localhost',
 [ValidatePattern('^MAGISAUTO_[A-Za-z0-9_]{1,90}$')][string]$Base='MAGISAUTO_Equipo',
 [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,100}$')][string]$Usuario='magis_api_equipo'
)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
if(-not(Test-Path (Join-Path $repo 'MAGISAUTO.sln'))){throw 'Ejecutar desde una copia completa del repositorio.'}
if(-not(Get-Command dotnet -ErrorAction SilentlyContinue)){throw 'Instala el SDK .NET 10 y abre otra terminal.'}
$sdks=(& dotnet --list-sdks) -join "`n"
if($LASTEXITCODE -ne 0 -or $sdks -notmatch '(?m)^10\.'){throw 'Falta el SDK .NET 10; Visual Studio debe tener la carga de ASP.NET.'}
# El generador compartido usa una clave aleatoria por equipo y protege archivos existentes.
# Ambos resultados contienen secretos y estan excluidos de Git.
& (Join-Path $PSScriptRoot 'Preparar-ConexionLocal.ps1') -Servidor $Servidor -Base $Base -Usuario $Usuario
Write-Output ''
Write-Output 'Siguiente paso: ejecuta artifacts/acceso-local/HABILITAR_API_LOCAL.sql en SSMS como administrador.'
Write-Output 'La instancia debe admitir Autenticacion de SQL Server (modo mixto). No cambies la cuenta a sa.'
Write-Output 'Luego ejecuta scripts/Comprobar-Equipo.ps1, abre MAGISAUTO.sln, selecciona http y Ctrl+F5.'
Write-Output 'La configuracion de Diego no se comparte; cada computadora obtiene una clave distinta.'
