# Fase 6 — Catálogo de agencias

Fecha: 11 de octubre de 2026. Rama: `pruebas-diego`. Es un avance de la fase 6, que continúa abierta.

## Objetivo y relación con el enunciado

El inciso D relaciona a los vendedores con una agencia o región. La tabla Agencia y sus procedimientos ya existían en V2. Este módulo permite utilizarlos desde la aplicación y prepara el catálogo que seleccionará el futuro módulo de vendedores.

Se puede listar, buscar, agregar, editar y eliminar agencias. No incorpora todavía el registro de vendedores ni cambia las reglas financieras o la estructura SQL.

## Datos y reglas

| Campo | Comportamiento |
| --- | --- |
| Código | Lo asigna SQL Server al crear; no se captura ni se cambia al editar. Los saltos del correlativo son normales. |
| Nombre | Obligatorio, máximo 128 caracteres; se recortan espacios exteriores. |
| Región | Obligatoria, máximo 128 caracteres; se recortan espacios exteriores. Es texto libre según el esquema existente. |

No se inventa una restricción de nombre único ni un nuevo catálogo de regiones. Un registro sin dependencias se puede eliminar; si tiene vendedores o créditos relacionados, SQL bloquea la eliminación y la API muestra un mensaje comprensible. La cancelación del diálogo conserva el registro.

## Recorrido y archivos

Pantalla `agencias.html` → `agencias.js` → `AgenciasController` → `IAgenciaRepositorio` / `AgenciaRepositorio` → procedimientos `api.Agencia_*` → tabla `dbo.Agencia`.

| Archivo dentro del repositorio | Qué agrega |
| --- | --- |
| `src/MAGISAUTO.API/Modelos/AgenciaSolicitud.cs` | Nombre y región con validaciones compartidas por crear y editar. |
| `src/MAGISAUTO.API/Modelos/AgenciaRespuesta.cs` | Código, nombre y región devueltos a la pantalla. |
| `src/MAGISAUTO.API/Datos/IAgenciaRepositorio.cs` | Contrato de las operaciones del catálogo. |
| `src/MAGISAUTO.API/Datos/AgenciaRepositorio.cs` | Ejecuta procedimientos con parámetros; obtiene el ID creado y traduce errores conocidos. |
| `src/MAGISAUTO.API/Controllers/AgenciasController.cs` | Rutas HTTP y validación de solicitudes. |
| `src/MAGISAUTO.API/Program.cs` | Registra el repositorio de agencias. |
| `src/MAGISAUTO.API/wwwroot/agencias.html` | Listado, búsqueda, formulario y confirmación de eliminación. |
| `src/MAGISAUTO.API/wwwroot/agencias.js` | Carga datos, abre formularios, envía operaciones y muestra resultados. |
| `src/MAGISAUTO.API/wwwroot/index.html` y `lineas.html` | Añaden Agencias a la navegación. |
| `scripts/Verificar-Agencias.ps1` | Ensayo real HTTP/SQL con registros temporales y limpieza. |
| `scripts/Verificar-InterfazAgencias.cjs` | Recorrido de navegador preparado; limitado por el entorno descrito más abajo. |

Los estilos existentes se reutilizan. El texto de las agencias se muestra mediante `textContent`, sin interpretar etiquetas HTML. Los formularios bloquean envíos repetidos mientras guardan; los mensajes de error conservan los campos para corregirlos. El listado distingue carga, ausencia de resultados y fallo de conexión.

## Contrato de la API

| Método y ruta | Operación SQL | Resultado |
| --- | --- | --- |
| `GET /api/catalogos/agencias` | `api.Agencia_Listar` | 200, listado. |
| `GET /api/catalogos/agencias?criterio=Oriente` | `api.Agencia_Buscar` | 200, coincidencias por código, nombre o región. |
| `POST /api/catalogos/agencias` | `api.Agencia_Insertar` | 201, código generado y datos guardados. |
| `PUT /api/catalogos/agencias/{codigo}` | `api.Agencia_Actualizar` | 200, datos actualizados manteniendo el código. |
| `DELETE /api/catalogos/agencias/{codigo}` | `api.Agencia_Eliminar` | 204 si se elimina. |

Crear y editar reciben, por ejemplo, `{"nombre":"Agencia de prueba","region":"Oriente"}`. El código no forma parte de esos datos editables.

Código no positivo, datos requeridos ausentes/blancos y textos demasiado largos: 400. Registro inexistente al editar o eliminar: 404. Dependencias al eliminar: 409. Los fallos de conexión usan el manejador general con 503 y no exponen credenciales. El criterio opcional admite hasta 200 caracteres; si se envía, no puede estar vacío. Se conserva el comportamiento LIKE del procedimiento existente, incluidos sus comodines.

## Validación ejecutada

- Compilación de la solución: cero errores y cero advertencias.
- 34 comprobaciones de agencias correctas: recursos web, navegación, alta con ID automático, persistencia, recorte de campos, validaciones, filtros, búsqueda de Unicode y texto de inyección, edición, bloqueo por vendedor, eliminación e inexistentes, contrato OpenAPI y conservación del catálogo inicial.
- 28 comprobaciones de Marcas correctas como regresión.
- Sintaxis JavaScript de Agencias verificada con Node.

Evidencias: [Agencias HTTP/SQL](evidencias/fase-6-agencias.json) y [regresión de Marcas](evidencias/fase-6-agencias-regresion-marcas.json).

El ensayo crea exclusivamente una agencia, una persona y un vendedor temporales mediante procedimientos, y los retira al finalizar. Las identidades SQL avanzan; no se reajustan los contadores. El catálogo existente se compara antes y después. Se probó el bloqueo por vendedor; no se creó un crédito financiero nuevo para repetir la otra relación de agencia.

**Límite de automatización visual:** Edge de automatización se cerró durante el arranque. El recorrido automatizado no llegó a ejecutarse y no se afirma validación visual móvil. El fallo de arranque se conserva en [resultado del intento de interfaz](evidencias/fase-6-agencias-interfaz.json), con cero pruebas automatizadas de interfaz completadas. La entrega de HTML/JS por HTTP no equivale a ejecutar los botones en un navegador.

### Confirmación manual de Diego

El 11 de octubre de 2026, Diego seleccionó la tabla de ocho pruebas del chat y confirmó «todo esto funciono». Esta evidencia es su confirmación manual; no sustituye ni cambia el resultado del intento automatizado anterior.

| Prueba | Resultado confirmado por Diego |
| --- | --- |
| Listar | Se muestra la agencia inicial con código, nombre y región. |
| Agregar | La agencia de prueba aparece con código asignado automáticamente. |
| Editar | Nombre y región cambian; el código se conserva. |
| Recargar | Los cambios permanecen después de F5. |
| Buscar | Se encuentra la agencia de prueba por nombre y por región. |
| Ver todas | Se restablece el listado completo. |
| Cancelar eliminación | Conservar agencia mantiene el registro. |
| Eliminar | Confirmar la eliminación retira la agencia de prueba del listado. |

La selección confirmada no incluye la prueba manual de campos vacíos ni la protección por relaciones. Las validaciones de campos y el bloqueo por vendedor sí cuentan con las pruebas HTTP/SQL descritas arriba; no se atribuye a Diego una comprobación adicional.

## Cómo probarlo en Visual Studio

1. Detener la aplicación si está abierta, compilar e iniciar nuevamente con el perfil HTTP.
2. Abrir `http://localhost:5164/agencias.html` o elegir **Agencias** en el menú.
3. Buscar la agencia inicial por nombre o región y pulsar **Ver todas**.
4. Pulsar **Agregar agencia**, escribir `Prueba Diego` y región `Oriente`. El código se asigna automáticamente.
5. Editar esa agencia: cambiar nombre y región; el código debe conservarse. Recargar y buscar los valores nuevos.
6. Abrir Eliminar y elegir **Conservar agencia**; el registro debe seguir visible.
7. Eliminar únicamente la agencia de prueba y verificar que desaparece. Conservar la agencia inicial.

Para repetir el ensayo HTTP/SQL, compilar y ejecutar `pwsh -File scripts/Verificar-Agencias.ps1` desde la raíz. Admite `-SalidaCompilacion` para una salida alternativa, como las otras verificaciones. El script visual requiere Playwright y un servidor iniciado; `MAGISAUTO_URL` permite elegir su URL.

## Estado y siguiente paso

La documentación inicial se publicó y verificó en GitHub con el commit `32d4bd5`. El módulo Agencias y este informe se preparan localmente después de esa publicación; no se afirma un envío adicional.

Sigue Vendedores, usando este catálogo. La fase 6 permanece abierta; el PDF de cierre se entregará según [Informes por fase](INFORMES_POR_FASE.md).
