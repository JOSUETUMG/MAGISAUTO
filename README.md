# MAGIS-AUTO

Proyecto del equipo de Diego Fernandez, Dylan Jimenez y Danny Josue.

Esta primera versión contiene la solución de Visual Studio y el inicio de la API
en C# con ASP.NET Core sobre .NET 10. Los cambios iniciales están en la rama `pruebas`.

## Abrir y ejecutar en Visual Studio

1. Instalar Visual Studio Community 2026 con **Desarrollo de ASP.NET y web** y el SDK de .NET 10.
2. Abrir `MAGISAUTO.sln` desde la raíz del repositorio.
3. Esperar a que Visual Studio restaure las dependencias.
4. Si se solicita, elegir `MAGISAUTO.API` como proyecto de inicio.
5. Elegir el perfil **http** y pulsar **Ctrl+F5**.

El navegador abrirá `http://localhost:5164/api/salud`. La respuesta esperada es un
JSON con `aplicacion: "MAGISAUTO.API"`, `estado: "Disponible"` y la fecha UTC.
Este perfil HTTP está pensado para pruebas locales. También se incluye un perfil
HTTPS que requiere el certificado de desarrollo de ASP.NET Core.

## Ejecutar desde una terminal

Desde la carpeta que contiene la solución:

```powershell
dotnet restore MAGISAUTO.sln
dotnet build MAGISAUTO.sln --no-restore
dotnet run --project src/MAGISAUTO.API --launch-profile http
```

## Rutas disponibles

| Método | Ruta | Uso |
| --- | --- | --- |
| GET | `/api/salud` | Verifica que la API está funcionando. |
| GET | `/openapi/v1.json` | Describe la API en formato OpenAPI, solo en desarrollo. |
| GET | `/` | Redirige a la comprobación de funcionamiento. |

También se pueden enviar las solicitudes del archivo `MAGISAUTO.API.http` desde Visual Studio.
OpenAPI se entrega como JSON; todavía no se incluye una interfaz Swagger.

## Estructura inicial

```text
MAGISAUTO.sln
src/
  MAGISAUTO.API/
    Controllers/SaludController.cs
    Properties/launchSettings.json
    Program.cs
    appsettings.json
    MAGISAUTO.API.http
```

## Base de datos y siguientes fases

La API todavía no está conectada a SQL Server. La ruta de salud solo verifica la API.
Este inicio no crea ni modifica bases de datos, tablas, clientes, créditos o pagos.

La conexión y las operaciones se incorporarán al desarrollar el modelo y los
procedimientos almacenados aprobados por el equipo. Las operaciones de datos se
realizarán desde la API mediante procedimientos almacenados, según lo solicitado
para el proyecto. Las contraseñas se configurarán localmente, fuera de Git.

## Trabajar en la rama de pruebas

Para descargar esta versión por primera vez:

```powershell
git clone --branch pruebas https://github.com/JOSUETUMG/MAGISAUTO.git
```

Si ya se tiene una copia del repositorio, guardar primero el trabajo pendiente y usar:

```powershell
git fetch origin
git switch pruebas
git pull --ff-only origin pruebas
```

Antes de compartir cambios, comprobar que la rama activa sea `pruebas` y compilar
la solución. La carpeta `.vs` y las salidas `bin` y `obj` están excluidas de Git.
