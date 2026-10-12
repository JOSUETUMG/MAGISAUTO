# MAGIS-AUTO

Proyecto universitario de financiamiento de vehículos. Trabajo individual de Diego en **pruebas-diego**, conservando los acuerdos del equipo.

Documentación por fases: [índice y orden de lectura](docs/README.md), desde los requisitos y preparación inicial hasta los módulos implementados.

Decisiones vigentes de la revisión del enunciado: [total recaudable, anulaciones, código del vehículo y referencias](docs/DECISIONES_REVISION_PDF.md). Incluye qué está implementado y qué falta en el recorrido de solicitudes.

API en C# / ASP.NET Core .NET 10 y SQL Server, con interfaz HTML/CSS/JavaScript. Los módulos de marcas y líneas permiten listar, buscar, agregar, editar y eliminar mediante procedimientos almacenados. Los módulos de clientes, créditos y pagos todavía no tienen endpoints ni pantallas.

## Abrir y ejecutar

1. Abrir MAGISAUTO.sln en Visual Studio 2026 con desarrollo ASP.NET y SDK .NET 10.
2. Esperar la restauración y seleccionar MAGISAUTO.API como proyecto de inicio.
3. En la máquina de Diego, MAGISAUTO_Proyecto_V2 y la configuración local ya están preparadas.
4. Si estaba ejecutándose, detenerla y volver a iniciar. Elegir **http** y pulsar **Ctrl+F5**.
5. El navegador abre http://localhost:5164/ con la pantalla de marcas.
6. Probar http://localhost:5164/api/salud/base-datos.
7. Probar http://localhost:5164/api/catalogos/marcas.

HTTP es para pruebas locales. HTTPS requiere el certificado de desarrollo. Los ensayos automáticos cierran sus servidores temporales: para usar la API, iniciarla desde Visual Studio o terminal.

## Rutas

| Método | Ruta | Resultado |
| --- | --- | --- |
| GET | /api/salud | API disponible, sin consultar SQL. |
| GET | /api/salud/base-datos | Consulta real mediante api.Marca_Listar. |
| GET | /api/catalogos/marcas | Listado mediante api.Marca_Listar. |
| GET | /api/catalogos/marcas?criterio=Toyota | Búsqueda mediante api.Marca_Buscar. |
| GET | /openapi/v1.json | Contrato OpenAPI en desarrollo. |
| GET | / | Pantalla de administración de marcas. |
| POST | /api/catalogos/marcas | Crea una marca: codigoMarca y descripcion. |
| PUT | /api/catalogos/marcas/{codigo} | Actualiza descripcion; conserva el código. |
| DELETE | /api/catalogos/marcas/{codigo} | Elimina una marca sin relaciones. |
| GET | /lineas.html | Pantalla de líneas y selección de marca. |
| GET | /api/catalogos/lineas | Lista líneas con nombre de marca; acepta criterio y codigoMarca. |
| POST | /api/catalogos/lineas | Crea con codigoMarca, codigoLinea y descripcion. |
| PUT | /api/catalogos/lineas/{codigoMarca}/{codigoLinea} | Actualiza el nombre conservando la clave compuesta. |
| DELETE | /api/catalogos/lineas/{codigoMarca}/{codigoLinea} | Elimina una línea sin vehículos asociados. |

Sin filtro se listan todas; filtro vacío, de espacios o mayor de 200 caracteres devuelve 400. Sin coincidencias se devuelve lista vacía. Configuración, conexión o permisos insuficientes producen 503 con ProblemDetails e identificador de solicitud, sin credenciales ni mensajes internos del proveedor.

La búsqueda conserva LIKE y sus comodines del procedimiento existente. Usa un parámetro NVARCHAR(200), nunca SQL concatenado. Solicitudes de ejemplo: src/MAGISAUTO.API/MAGISAUTO.API.http.

El código de una nueva marca es un entero positivo proporcionado por el usuario (no es IDENTITY en el esquema existente). El nombre es obligatorio, admite 128 caracteres y se recortan sus espacios exteriores. No se añadió una regla de nombres únicos. Un código duplicado o una eliminación bloqueada por líneas asociadas devuelven 409; editar o eliminar una marca inexistente devuelve 404. La pantalla pide confirmación antes de eliminar, conserva el formulario cuando hay errores y evita envíos simultáneos desde un mismo formulario.

## Otra máquina

Cada equipo necesita su propia base y credencial; Git no las instala.

1. Instalar database/v2/entrega/MAGISAUTO_Proyecto_Completo.sql según su LEEME.md, con un nombre nuevo.
2. Desde la raíz del repositorio:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/Preparar-ConexionLocal.ps1 -Usuario magis_api_local

   También acepta -Servidor y -Base. No reemplaza una configuración ya existente.
3. Se generan una contraseña aleatoria y dos archivos privados:
   - src/MAGISAUTO.API/appsettings.Local.json: conexión local.
   - artifacts/acceso-local/HABILITAR_API_LOCAL.sql: creación administrativa de la cuenta.
4. Abrir el segundo en SSMS con cuenta administradora y ejecutarlo completo una vez. Crea la cuenta e incorpora el usuario al rol magis_api, sin cambiar datos de negocio.
5. Reiniciar la API.

Ambos archivos privados están excluidos de Git y no se comparten. Si la cuenta existe, el script se detiene sin restablecer su contraseña: revisar si ya se ejecutó. appsettings.Local.example.json contiene solo un ejemplo sin clave real.

## Configuración y permisos

En desarrollo se carga appsettings.Local.json desde la carpeta de la API. Variables de entorno y argumentos tienen prioridad. Fuera de desarrollo se configura ConnectionStrings__MagisAuto en el entorno. La configuración privada no se copia a nuevas salidas de compilación ni publicación.

La cuenta magis_api_diego pertenece a magis_api: ejecuta procedimientos api.*, con SELECT/INSERT/UPDATE/DELETE directo en dbo denegados; no es sysadmin ni db_owner. Es distinta de codex_lectura, utilizada para revisiones.

La conexión técnica no es inicio de sesión del personal, que sigue opcional/pendiente. Esta fase se ejecuta localmente y no publica en Internet.

Encrypt=True y TrustServerCertificate=True se usan para el certificado local de desarrollo. Un despliegue requiere un certificado validable y retirar esa excepción.

Se usa [Microsoft.Data.SqlClient oficial](https://www.nuget.org/packages/Microsoft.Data.SqlClient/7.1.1); referencia de [configuración de conexiones de Microsoft](https://learn.microsoft.com/sql/connect/ado-net/connection-string-syntax).

## Comprobaciones

Desde la raíz:

    dotnet restore MAGISAUTO.sln
    dotnet build MAGISAUTO.sln --no-restore
    dotnet run --project src/MAGISAUTO.API --launch-profile http

Ensayo automático con PowerShell 7:

    pwsh -File scripts/Verificar-Api.ps1

Usa la configuración local y las cinco marcas iniciales. Inicia y cierra servidores en puertos locales libres, sin insertar datos. El parámetro opcional CredencialSoloLectura acepta la ruta de una credencial cifrada local para probar denegación de procedimientos; ese archivo no se distribuye.

Se verificaron **31 comprobaciones** de consultas, validación, OpenAPI, errores y permisos. Sin ese parámetro opcional se omiten cuatro comprobaciones de la cuenta de lectura. Resultados temporales: artifacts/verificacion-api. Evidencia revisada: docs/evidencias/fase-5-api.json.

Ensayo del CRUD de marcas (crea una marca y una línea temporales, y las retira incluso si falla una comprobación):

    pwsh -File scripts/Verificar-Marcas.ps1

Se verificaron **28 comprobaciones** nuevas y las **31 anteriores** sobre la implementación de fase 6. Evidencias en docs/evidencias/fase-6-marcas.json y fase-6-regresion-api.json. Ambos scripts aceptan SalidaCompilacion si se usa otra carpeta de compilación.

El ensayo de navegador scripts/Verificar-InterfazMarcas.cjs requiere Node.js, el paquete Playwright y Microsoft Edge. MAGISAUTO_URL permite elegir el servidor de pruebas. Su ejecución automática quedó pendiente porque los navegadores de automatización no arrancaron en este entorno; no se cuenta como prueba aprobada. El recorrido manual está documentado en docs/FASE_6_Marcas.md.

## Estado y Git

- Fase 4: SQL instalado y verificado, docs/FASE_4_SQL_Implementado.md.
- Fase 5: conexión y primer catálogo, docs/FASE_5_Conexion_API.md.
- Fase 6: CRUD y pantalla de marcas implementados, API verificada y recorrido manual probado con Diego; docs/FASE_6_Marcas.md.
- Avance de fase 6: Marcas y Líneas probadas manualmente con Diego; 42 pruebas nuevas de Líneas aprobadas, más 59 de regresión. Ver docs/FASE_6_Lineas.md.
- Pendiente: demás catálogos, módulos de negocio y sus pantallas, autenticación si se incorpora y aceptación según PDF.
- Siguen pendientes las interpretaciones del ingeniero sobre total neto recaudable y borrado financiero.

Trabajar en pruebas-diego y compilar antes de compartir. SQL e instrucciones sí se versionan; base instalada, usuarios, datos y credenciales no. Esta fase no hace commit, push ni mezcla ramas automáticamente.

Al cerrar cada fase se entregará un informe PDF acumulado con cambios, explicaciones, ejemplos y pruebas. Alcance acordado en docs/INFORMES_POR_FASE.md. El catálogo de líneas no cierra toda la fase 6.
