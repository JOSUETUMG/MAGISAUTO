Resumen

- Añade una interfaz web completa para MAGIS AUTOMOTIZ (sitio estático dentro de src/MAGISAUTO.API/wwwroot).
- Implementa la funcionalidad de "Referencias personales" en la API: entidad, DbContext (InMemory por defecto), repositorio, servicio, controlador y pruebas unitarias.
- Incluye pruebas unitarias básicas para las reglas de negocio (no permitir que el cliente sea su propia referencia; comprobar mínimo de 3 referencias).
- Agrega archivos estáticos: index.html, styles.css, script.js y enlaza la UI con la API local.

Archivos añadidos/actualizados (destacados)

- src/MAGISAUTO.API/wwwroot/index.html
- src/MAGISAUTO.API/wwwroot/styles.css
- src/MAGISAUTO.API/wwwroot/script.js
- src/MAGISAUTO.API/Models/Cliente.cs
- src/MAGISAUTO.API/Models/PersonalReference.cs
- src/MAGISAUTO.API/Dtos/PersonalReferenceDto.cs
- src/MAGISAUTO.API/Data/ApplicationDbContext.cs
- src/MAGISAUTO.API/Repositories/IPersonalReferenceRepository.cs
- src/MAGISAUTO.API/Repositories/PersonalReferenceRepository.cs
- src/MAGISAUTO.API/Services/IPersonalReferenceService.cs
- src/MAGISAUTO.API/Services/PersonalReferenceService.cs
- src/MAGISAUTO.API/Controllers/PersonalReferencesController.cs
- tests/MAGISAUTO.Tests/* (proyecto de pruebas y tests)

Cómo probar localmente
1) Compilar:
   dotnet build "MAGISAUTO.sln"

2) Ejecutar la API (usa BD InMemory por defecto):
   dotnet run --project "src\\MAGISAUTO.API\\MAGISAUTO.API.csproj"

3) Abrir la UI en el navegador:
   http://localhost:5164/index.html  (puede variar el puerto; ver salida de dotnet run)

4) Comprobar endpoints:
- POST /api/personalreferences  (crear referencia)
- GET /api/personalreferences/client/{clienteId}  (listar)
- GET /api/personalreferences/client/{clienteId}/hasminimum  (comprueba >= 3)

5) Ejecutar pruebas:
   dotnet test tests\\MAGISAUTO.Tests\\MAGISAUTO.Tests.csproj

Notas
- Persistencia actual: ApplicationDbContext usa InMemory para facilitar pruebas y demo. Para producción: añadir proveedor SQL Server y ejecutar migraciones.
- UI estática (wwwroot) aún consume datos locales definidos en script.js; se puede adaptar para consumir endpoints REST reales.
