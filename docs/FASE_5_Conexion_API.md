# Fase 5 — Conexión de la API con SQL Server

Fecha: 8 de octubre de 2026. Rama: pruebas-diego.

## Alcance

Conectar la API .NET 10 a MAGISAUTO_Proyecto_V2 con una cuenta limitada y demostrar una consulta real mediante procedimientos almacenados. Se incorporan listado/búsqueda de marcas, comprobación de base de datos y manejo de errores. No incluye todavía clientes, créditos, pagos ni pantallas.

## Recorrido

Petición HTTP → controlador → repositorio de marcas → Microsoft.Data.SqlClient → procedimiento api.Marca_Listar o api.Marca_Buscar → respuesta JSON.

El repositorio usa CommandType.StoredProcedure, nombres de procedimiento fijos, parámetro NVARCHAR(200), ejecución asíncrona y cancelación. Conexiones y lectores se liberan al terminar. Las marcas se devuelven ordenadas según el procedimiento.

No se alteraron los procedimientos ni las reglas del crédito. La cuenta de aplicación se creó administrativamente en SSMS, separada de la cuenta de revisión.

## Entrega

| Elemento | Uso |
| --- | --- |
| ConexionSqlFactory | Lee configuración privada y crea conexiones, sin imprimir credenciales. |
| MarcaRepositorio | Ejecuta listado/búsqueda almacenado y devuelve código/descripción. |
| MarcasController | GET /api/catalogos/marcas, con validación del filtro. |
| SaludBaseDatosController | GET /api/salud/base-datos, consulta real. |
| ErroresApiHandler | Respuestas controladas de errores, HTTP 503 para fallos de conexión. |
| Preparar-ConexionLocal.ps1 | Configuración y script administrativo privados por equipo. |
| Verificar-Api.ps1 | Pruebas HTTP locales y de permisos de la cuenta. |

/api/salud conserva su significado: API disponible sin comprobar SQL. La nueva ruta de base de datos verifica conexión, permiso y procedimiento de marcas.

## Acceso y configuración

Cuenta magis_api_diego en MAGISAUTO_Proyecto_V2, integrante de magis_api. Puede ejecutar procedimientos, sin administración del servidor/base ni acceso directo a tablas. El rol permite los procedimientos de v2; la API en esta fase solo expone consultas de marcas.

Contraseña aleatoria en appsettings.Local.json, excluido de Git y de las nuevas salidas de compilación/publicación. El script administrativo privado queda bajo artifacts, también excluido. Las variables de entorno tienen prioridad sobre el archivo local. Solo se carga el archivo local en desarrollo.

El inicio de sesión del personal es una decisión separada y sigue pendiente/opcional. No se publicó la aplicación en Internet.

## Validación

- [x] Compilación sin errores ni advertencias.
- [x] Cuenta propia de aplicación configurada por Diego.
- [x] Salud de API y consulta real a la base.
- [x] Cinco marcas iniciales desde SQL.
- [x] Búsqueda por descripción, código, espacios exteriores y sin coincidencias.
- [x] Rechazo de filtros vacíos, de espacios y de más de 200 caracteres.
- [x] Caracteres SQL tratados como parámetro de búsqueda.
- [x] OpenAPI documenta rutas y errores.
- [x] Configuración ausente/inválida, servidor inaccesible y permisos insuficientes devuelven 503.
- [x] Errores sin contraseñas, datos internos del proveedor ni nombres de cuentas.
- [x] API disponible aunque falle la base.
- [x] Cuenta sin sysadmin/db_owner ni acceso directo a tablas.
- [x] Lectura directa de Marca rechazada por SQL Server.

Las 31 comprobaciones se conservan en evidencias/fase-5-api.json. Los ensayos hicieron consultas de lectura sin operaciones nuevas. Los servidores temporales se cerraron al finalizar.

## Probar en Visual Studio

1. Abrir MAGISAUTO.sln y seleccionar MAGISAUTO.API.
2. Detener cualquier ejecución anterior de la API.
3. Elegir http y presionar Ctrl+F5.
4. Abrir http://localhost:5164/api/salud/base-datos.
5. Abrir http://localhost:5164/api/catalogos/marcas.

Se espera Disponible y el catálogo Toyota, Hyundai, Kia, Nissan y Suzuki. Cada compañero configura su propia base y credencial siguiendo README.md.

## Próximo paso y límites

Quedan endpoints de negocio, interfaz y pruebas de recorridos de usuario. Estas comprobaciones no certifican módulos futuros ni sustituyen la aceptación del ingeniero. Los cambios siguen locales hasta registrarlos y publicarlos en Git.
