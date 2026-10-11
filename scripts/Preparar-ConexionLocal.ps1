param(
 [string]$Servidor='tcp:127.0.0.1,1433',
 [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,100}$')][string]$Base='MAGISAUTO_Proyecto_V2',
 [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,100}$')][string]$Usuario='magis_api_diego'
)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$config=Join-Path $repo 'src\MAGISAUTO.API\appsettings.Local.json'
$privado=Join-Path $repo 'artifacts\acceso-local'
$script=Join-Path $privado 'HABILITAR_API_LOCAL.sql'
if(Test-Path -LiteralPath $config){throw 'Ya existe appsettings.Local.json. Se conserva su configuración; no se genera otra contraseña.'}

# Contraseña distinta por equipo. Nunca imprimirla ni pasarla como argumento de un proceso.
$bytes=New-Object byte[] 32
$rng=[Security.Cryptography.RandomNumberGenerator]::Create()
try{$rng.GetBytes($bytes)}finally{$rng.Dispose()}
$password='Aa1!'+[Convert]::ToBase64String($bytes)
$cadena=[System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$cadena['Data Source']=$Servidor
$cadena['Initial Catalog']=$Base
$cadena['User ID']=$Usuario
$cadena['Password']=$password
$cadena['Encrypt']=$true
# Solo para el certificado local de desarrollo. En un servidor publicado se valida el certificado.
$cadena['TrustServerCertificate']=$true
$cadena['Connect Timeout']=5
$cadena['Application Name']='MAGISAUTO.API'
$cadena['Persist Security Info']=$false
$sql=@"
-- Configuración administrativa LOCAL. Este archivo contiene una clave privada y está excluido de Git.
-- Crea una cuenta nueva para ejecutar los procedimientos; no cambia los datos ni la estructura del negocio.
USE [master];
SET XACT_ABORT ON;
IF DB_ID(N'$Base') IS NULL THROW 52300,'La base de trabajo no existe.',1;
IF SUSER_ID(N'$Usuario') IS NOT NULL THROW 52301,'La cuenta ya existe. No se cambió su contraseña; revisar si este paso ya se completó.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE LOGIN [$Usuario] WITH PASSWORD=N'$password', CHECK_POLICY=ON, CHECK_EXPIRATION=OFF, DEFAULT_DATABASE=[$Base];
 USE [$Base];
 IF DATABASE_PRINCIPAL_ID(N'magis_api') IS NULL THROW 52302,'Falta el rol de aplicación de la versión 2.',1;
 IF OBJECT_ID(N'api.Marca_Listar',N'P') IS NULL OR OBJECT_ID(N'api.Marca_Buscar',N'P') IS NULL
  THROW 52303,'Faltan los procedimientos de marcas.',1;
 CREATE USER [$Usuario] FOR LOGIN [$Usuario];
 ALTER ROLE [magis_api] ADD MEMBER [$Usuario];
 COMMIT TRANSACTION;
 SELECT DB_NAME() Base,N'Acceso de la API configurado correctamente.' Resultado;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
"@
[void](New-Item -ItemType Directory -Path $privado -Force)
[IO.File]::WriteAllText($script,$sql,[Text.UTF8Encoding]::new($true))
$json=@{ConnectionStrings=@{MagisAuto=$cadena.ConnectionString}}|ConvertTo-Json -Depth 3
[IO.File]::WriteAllText($config,$json,[Text.UTF8Encoding]::new($true))
$password=$null;$json=$null;$sql=$null;$cadena.Clear()
Write-Output 'Configuración local preparada. La contraseña no se imprimió.'
Write-Output "Ejecutar en SSMS, con Autenticación de Windows: $script"
Write-Output 'Después reiniciar la API para que cargue la configuración local.'
