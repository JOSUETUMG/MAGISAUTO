# Fase 1 — Preparación del proyecto y forma de trabajo

Documento reconstruido el 11 de octubre de 2026. Rama de trabajo: `pruebas-diego`.

Recupera la preparación inicial y explica su relación con el repositorio actual. Algunas tareas de preparación se solaparon con los acuerdos iniciales; no se atribuye a esta fase todo lo que existe hoy. La conexión real mediante procedimientos y las pantallas pertenecen a fases posteriores.

## 1. Objetivo

Tener un lugar organizado para desarrollar MAGIS-AUTO, una aplicación inicial ejecutable, una base de proyecto separada de las bases de clase y una rama individual que permita trabajar sin modificar las de los compañeros.

## 2. Herramientas y responsabilidad de cada parte

| Elemento | Función |
| --- | --- |
| Visual Studio | Abrir la solución, editar, compilar y ejecutar la aplicación. |
| C# y ASP.NET Core .NET 10 | Construir la API que recibe solicitudes y aplica el acceso a datos. |
| SQL Server | Almacenar los datos, relaciones y procedimientos del proyecto. |
| SSMS | Administrar SQL Server, ejecutar instaladores y consultar resultados. No sustituye al motor de base de datos. |
| HTML, CSS y JavaScript | Construir las pantallas web incorporadas después. |
| Git | Registrar cambios en archivos mediante commits y ramas. |
| GitHub | Compartir el repositorio y sus versiones. No hospeda automáticamente la base SQL ni ejecuta la aplicación local. |

Recorrido previsto: navegador → API → procedimiento almacenado → SQL Server → respuesta a la pantalla. La aplicación no debe realizar operaciones de negocio conectando el navegador directamente con la base.

## 3. Solución inicial y evidencia histórica

El historial contiene el commit `b6b82aa`, **Iniciar solucion MAGISAUTO con API ASP.NET Core**, como evidencia del arranque técnico. No se atribuyen a ese commit los repositorios SQL, los permisos de aplicación ni las interfaces añadidas después.

La solución se abre desde `MAGISAUTO.sln`; la aplicación está en `src/MAGISAUTO.API`. La ruta `/api/salud` responde con el nombre de la aplicación, su estado y la fecha UTC para comprobar que la API se está ejecutando.

**Importante:** obtener `Disponible` en `/api/salud` no demuestra que SQL Server esté conectado. La comprobación `/api/salud/base-datos` y el acceso a marcas por procedimientos se incorporaron en [fase 5](FASE_5_Conexion_API.md).

## 4. Organización individual y ramas

Diego aclaró que cada integrante desarrollará el proyecto completo en su propia rama. Por eso no se asignan módulos obligatorios a Dylan o Danny ni se depende de sus avances para completar esta rama.

- Rama de Diego: `pruebas-diego`.
- Repositorio: <https://github.com/JOSUETUMG/MAGISAUTO>.
- Cada commit conserva una versión de los archivos. Enviar cambios publica esos commits en el remoto; crear el commit local no prueba que se hayan subido.
- No se modifica la rama de otro compañero ni se integra automáticamente su trabajo.
- Se acordó avanzar al siguiente bloque cuando el anterior estuviera completado, sin esperar una fecha ficticia del calendario. Diego indicó que normalmente no dispone de los sábados; no se inventó una cantidad de horas diarias.

Durante la publicación se observó un intento de autenticación por contraseña rechazado y posteriormente un envío desde Visual Studio. La publicación del avance posterior `337da5a` fue verificada en la revisión previa de esta conversación. Eso no significa que los nuevos documentos locales ya estén publicados.

## 5. Separación de bases de datos

Al existir una base anterior con el mismo nombre que el archivo de clase, se optó por usar una base distinta para el proyecto. El esquema de partida fue `MagisV1 (2).sql`; no se debe confundir con los instaladores ampliados posteriores.

| Base | Papel en la historia del proyecto |
| --- | --- |
| `MagisV1` | Base de clase anterior, separada del proyecto actual. |
| `MAGISAUTO_Complemento` | Base utilizada para ejercicios de clase; no pertenece al desarrollo funcional de esta rama. |
| `MAGISAUTO_Proyecto` | Nombre utilizado al preparar la base inicial del proyecto; se conserva separado de V2. |
| `MAGISAUTO_Proyecto_V2` | Base vigente incorporada después con la implementación SQL V2. |
| `MAGISAUTO_ValidacionV2` | Base posterior para pruebas aisladas del SQL V2. |

Se pidió conservar la estructura al retirar los datos de operaciones de la preparación inicial. También se acordó que la entrega para compañeros incluyera catálogos y parámetros, sin clientes, vehículos, créditos ni pagos de ejemplo. Esto no autoriza futuros vaciados automáticos.

Los nombres de la tabla explican sus funciones; no constituyen una consulta nueva al servidor ni una invitación a eliminarlas.

## 6. Conexión y configuración local

Las capturas de preparación identificaron el servidor local `WolfGo`, instancia predeterminada, y mostraron la habilitación de TCP/IP con escucha en el puerto 1433. SSMS pudo conectarse inicialmente mediante memoria compartida; ese transporte no demostraba por sí solo disponibilidad TCP para la aplicación.

La cuenta limitada de la API y su configuración privada son avances posteriores documentados en fase 5. La configuración actual excluye de Git contraseñas, `appsettings.Local.json`, credenciales locales y archivos generados de compilación. No se copian secretos a esta documentación.

Para otro compañero, descargar una rama no instala SQL Server ni copia los datos locales. Debe instalar la base desde el paquete correspondiente y configurar su conexión. Las instrucciones actuales están en el [README principal](../README.md) y la [entrega V2](../database/v2/entrega/LEEME.md).

## 7. Cómo se organiza hoy el repositorio

Este mapa orienta al lector sobre la versión actual; no afirma que todas las carpetas ya existieran en fase 1.

| Ubicación | Contenido y finalidad |
| --- | --- |
| `src/MAGISAUTO.API` | Aplicación, controladores, acceso a datos y archivos web. |
| `database/entrega-companero` | Primera entrega ampliada, conservada como antecedente de 25 tablas. |
| `database/v2` | Fuentes, entrega y auditoría de la versión de 26 tablas. |
| `scripts` | Preparación y verificaciones reproducibles; revisar el alcance de cada script antes de ejecutarlo. |
| `docs` | Explicaciones de fases, decisiones, limitaciones y evidencias de pruebas. |
| `.gitignore` | Evita incorporar configuración privada y archivos generados. |

## 8. Comprobaciones y límites de la reconstrucción

| Evidencia | Qué permite afirmar | Qué no permite afirmar |
| --- | --- | --- |
| Commit inicial | Hubo una solución y una API inicial versionadas. | Que los módulos financieros estuvieran terminados. |
| Respuesta de `/api/salud` mostrada por Diego | La API podía responder localmente. | Que estuviera conectada a SQL. |
| Capturas de SSMS y configuración | Se trabajó con una base separada y configuración local de SQL Server. | Que todas las reglas financieras se hubieran probado entonces. |
| Publicación posterior verificada | El avance hasta `337da5a` llegó a GitHub. | Que estos documentos reconstruidos estén publicados sin un nuevo envío. |
| Documentos y evidencias de fases 4–6 | Respaldan implementaciones y pruebas posteriores. | Que fueran resultados de la fase 1. |

Esta reconstrucción no vuelve a ejecutar instaladores, cambia permisos, crea bases ni realiza pruebas con movimientos financieros. La revisión previa del 11 de octubre compiló el estado actual sin errores ni advertencias; es una comprobación posterior, no evidencia fechada del arranque.

## 9. Resultado y continuidad

Quedó una base de trabajo: solución inicial, forma de ejecución, separación de bases y desarrollo individual mediante `pruebas-diego`. El diseño de entidades se desarrolla en [fase 2](FASE_2_Modelo_ER.md), la organización relacional en [fase 3](FASE_3_Modelo_Relacional_3FN.md), SQL en [fase 4](FASE_4_SQL_Implementado.md), conexión en [fase 5](FASE_5_Conexion_API.md) y pantallas en fase 6.

Consultar [fase 0](FASE_0_Requisitos_y_Acuerdos.md) para requisitos y decisiones. Los PDF se rigen por [Informes por fase](INFORMES_POR_FASE.md); este documento editable no implica que ya se haya generado un PDF retrospectivo.
