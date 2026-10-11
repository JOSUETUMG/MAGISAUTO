-- Ejecutar en SSMS con la cuenta administradora.
-- Autoriza solo conexion, lectura y consulta de definiciones en esta base.
USE [MAGISAUTO_Proyecto_V2];
SET XACT_ABORT ON;
IF DB_NAME()<>'MAGISAUTO_Proyecto_V2' THROW 52210,'Base incorrecta.',1;
IF SUSER_ID(N'codex_lectura') IS NULL THROW 52211,'No existe la cuenta tecnica esperada. No se creo ningun login.',1;
IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'codex_lectura' AND sid<>SUSER_SID(N'codex_lectura'))
 THROW 52212,'El usuario existente pertenece a otra identidad. Revisar antes de continuar.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 IF USER_ID(N'codex_lectura') IS NULL
  CREATE USER [codex_lectura] FOR LOGIN [codex_lectura];
 GRANT CONNECT TO [codex_lectura];
 GRANT SELECT ON SCHEMA::dbo TO [codex_lectura];
 GRANT VIEW DEFINITION TO [codex_lectura];
 COMMIT TRANSACTION;
 SELECT DB_NAME() Base,N'Permisos de revision concedidos a codex_lectura.' Resultado;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
