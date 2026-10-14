# Fase 6 — Vehículos

Fecha: 12 de octubre de 2026. Avance local en `pruebas-diego`. La fase 6 continúa abierta.

## Objetivo y alcance

El inciso B del enunciado requiere identificar cada vehículo nuevo de agencia por VIN/chasis, marca, línea, año, precio al contado en quetzales y placa cuando exista. Se utiliza la entidad SQL `Garantia`, sin crear otra tabla de vehículos ni otro correlativo.

El módulo permite agregar, listar, buscar, filtrar por marca, consultar, editar y eliminar vehículos cuando sus relaciones lo permiten. El código interno es `CodigoGarantia`, asignado automáticamente por SQL. La interpretación de conservar ese correlativo global, asociado a marca y línea, está documentada en las decisiones del proyecto; no se presenta como una aclaración confirmada por el docente.

Registrar un vehículo no crea un crédito. La asignación y aprobación se implementarán en Créditos. La base ya impide más de un crédito vigente sobre la misma garantía.

## Datos y reglas

| Dato | Regla implementada |
| --- | --- |
| Código interno | Automático e inmutable; los saltos del correlativo no son errores. |
| VIN/chasis | Obligatorio, único, 17 caracteres alfanuméricos sin I, O ni Q, conforme a la restricción SQL existente. Se recortan espacios exteriores y se convierte a mayúsculas. No se consulta un registro oficial ni se verifica un dígito de control. |
| Marca y línea | Se seleccionan de los catálogos. La línea debe pertenecer a la marca: su clave es compuesta. |
| Año | Entero entre 1886 y 2100, conservando el intervalo del esquema; no se impone un intervalo nuevo basado en el año actual. |
| Precio al contado | Mayor que cero, hasta dos decimales, dentro de `decimal(18,2)`. Se rechazan fracciones adicionales en lugar de redondearlas silenciosamente. |
| Placa | Opcional, hasta 20 caracteres. Vacío o espacios se guardan como NULL; cuando existe, SQL exige unicidad. Se convierte a mayúsculas. No se inventa un patrón adicional. |
| Tipo de garantía | Obligatorio, tomado de `TipoGarantia`. El catálogo inicial contiene Vehículo nuevo de agencia. |
| Condición | Siempre nuevo de agencia, conforme al alcance y a `EsNuevo=1` en SQL. La API no ofrece cambiarlo a usado. |

La pantalla permite varios vehículos sin placa. Un VIN o una placa duplicados devuelven un aviso, sin registrar parcialmente el vehículo.

## Edición, eliminación y protección del historial

Antes de tener un crédito aprobado, SQL permite corregir los datos del vehículo, conservando su código interno y las restricciones de unicidad. Una vez que cualquier crédito vinculado tiene fecha de aprobación, `Garantia_Actualizar` bloquea toda edición, incluso si el contrato se anula posteriormente.

La pantalla muestra **Ver datos** para vehículos con historial contractual y deja los campos de consulta protegidos. El servidor vuelve a aplicar la regla aunque el listado esté desactualizado. Esta protección existente también impide agregar o corregir una placa después de aprobar: es una limitación del procedimiento actual que debe considerarse al implementar Créditos, sin desactivar la protección ni afirmar que ese caso ya está resuelto.

`Garantia_Eliminar` bloquea el borrado si hay créditos —incluidos borradores— o valoraciones vinculadas. La API explica: **«No se puede eliminar el vehículo porque tiene créditos o valoraciones vinculadas. El vehículo se conserva.»** No se borran relaciones en cascada para permitir una eliminación.

Los borradores de crédito conservan el precio capturado al prepararlos; editar el inventario no reescribe sus condiciones. La revisión de condiciones antes de aprobar pertenece al recorrido de Créditos.

## Depreciación

La base ya registra la valoración inicial al ejecutar `Credito_Aprobar`, con un porcentaje entre 15% y 20% y 15% como parámetro académico inicial. El alta del vehículo conserva su precio al contado; no crea otra valoración inicial ni resta depreciación a la deuda.

Ejemplo: registrar un vehículo de Q100,000 mantiene ese precio. Al aprobar con depreciación del 15%, el procedimiento registra una valoración con valor depreciado de Q85,000. El monto financiado depende del enganche, no de restar esa depreciación.

En este avance se consultan las valoraciones existentes para identificar dependencias. **No se implementa todavía una pantalla de mantenimiento del historial de valoraciones** ni un proceso automático periódico de depreciación. Tampoco se declara terminada la aprobación de créditos por existir sus procedimientos SQL.

## Recorrido y archivos

Pantalla → VehiculosController → VehiculoRepositorio → procedimientos `api.*` → SQL Server.

| Archivo | Responsabilidad |
| --- | --- |
| `src/MAGISAUTO.API/Modelos/VehiculoSolicitud.cs` | Validaciones, normalización de VIN/placa y ficha de respuesta. |
| `src/MAGISAUTO.API/Controllers/VehiculosController.cs` | Rutas, filtros y respuestas de consulta, alta, edición y eliminación. |
| `src/MAGISAUTO.API/Datos/VehiculoRepositorio.cs` | Ejecuta procedimientos, combina marca/línea con el vehículo, cuenta dependencias y traduce errores. |
| `src/MAGISAUTO.API/wwwroot/vehiculos.html` | Listado, filtros, formulario y confirmación de eliminación. |
| `src/MAGISAUTO.API/wwwroot/vehiculos.js` | Selección dependiente de línea, operaciones, importes y mensajes. |
| `src/MAGISAUTO.API/wwwroot/vehiculos.css` | Tabla desplazable y formulario adaptable a pantallas pequeñas. |
| `scripts/Verificar-Vehiculos.ps1` | Ensayo HTTP/SQL con registros temporales propios y limpieza. |

`Program.cs` registra el repositorio. Las seis pantallas anteriores incluyen el enlace a Vehículos. Para las lecturas se reutiliza `ClienteSqlSesion`; los nombres de procedimientos son constantes internas, nunca texto elegido por el usuario. La lectura de vehículos, catálogos y dependencias usa una transacción consistente Serializable.

Se utilizan `Garantia_Listar/Insertar/Actualizar/Eliminar`, los Listar de Marca, Linea, TipoGarantia, Credito y Depreciacion. El guardado envía parámetros SQL con sus tipos y precisión explícitos. No se añadió SQL directo de negocio, tablas, procedimientos, permisos ni una nueva versión del paquete SQL.

## API

| Método | Ruta | Resultado |
| --- | --- | --- |
| GET | `/api/vehiculos` | Todas las fichas. Admite `criterio` y `codigoMarca`. |
| GET | `/api/vehiculos/{codigo}` | Ficha individual o 404. |
| GET | `/api/vehiculos/catalogos` | Marcas, líneas y tipos de garantía existentes. |
| POST | `/api/vehiculos` | Crea el vehículo; 201 con `codigoGarantia`. |
| PUT | `/api/vehiculos/{codigo}` | Actualiza si no existe historial contractual aprobado; 204. |
| DELETE | `/api/vehiculos/{codigo}` | Elimina sin dependencias; 204. |

La búsqueda es literal por código, VIN, placa, marca, línea o año, sin interpretar el texto como SQL ni como comodines. Se puede combinar con el filtro por marca. Filtros vacíos explícitos, códigos no positivos y datos inválidos devuelven 400; duplicados o dependencias, 409; registros inexistentes, 404.

`valorAgencia` se devuelve como texto decimal y acepta texto decimal o número JSON. Esto conserva los centavos incluso en el límite de `decimal(18,2)`, que excede la precisión segura de los números JavaScript. El formulario lo envía como texto y el formato visible Q usa sus dígitos sin convertirlos a coma flotante.

La respuesta incluye `tieneHistorialContractual`, `creditosVinculados` y `valoracionesRegistradas`. Estos datos orientan la pantalla; no son un estado de disponibilidad comercial ni sustituyen las restricciones SQL.

## Pruebas realizadas

- Compilación sin errores ni advertencias y sintaxis JavaScript válida.
- **80 comprobaciones HTTP/SQL correctas**: alta, consulta, edición, normalización, VIN/placa duplicados, varios vehículos sin placa, año, precio y precisión, asociación marca/línea, filtros, errores, protección por valoración y crédito borrador, y eliminación sin dependencias.
- Se verificó el importe mínimo Q0.01 y el máximo exacto de `decimal(18,2)` sin perder centavos.
- **42 comprobaciones de Líneas correctas** como regresión con la API que incorpora Vehículos.
- Vehículos, catálogos, créditos, valoraciones y personas iniciales se compararon al finalizar y quedaron intactos. Se retiraron los registros temporales propios; los correlativos pueden avanzar.

Evidencias: [Vehículos](evidencias/fase-6-vehiculos.json) y [regresión de Líneas](evidencias/fase-6-vehiculos-regresion-lineas.json).

Se creó un crédito borrador y una valoración temporales para probar dependencias. No se aprobaron contratos ni se generaron pagos. La protección de edición por un crédito ya aprobado se conservó y se revisó en el procedimiento SQL; **no se ejecutó ese escenario de aprobación en este ensayo**, por lo que no se cuenta entre sus pruebas.

Diego confirmó manualmente el alta del vehículo 12, edición del precio a Q105000.50 y placa, búsquedas y filtros, Ver todos, rechazo del VIN duplicado, cambio de líneas al seleccionar otra marca, cancelación y conservación del registro y eliminación final con listado vacío (12 de octubre). Las verificaciones HTTP de archivos y controles no equivalen a haber recorrido el formulario en un navegador. No se afirma validación visual automática ni móvil.

Para repetir: compilar la API y ejecutar desde PowerShell 7 `./scripts/Verificar-Vehiculos.ps1`, con la configuración privada local preparada. El parámetro `-SalidaCompilacion` permite seleccionar una salida dentro del proyecto API. Es un ensayo del entorno académico local, no una herramienta para ejecutar sobre una base de producción.

## Guía de prueba manual

1. Detener y volver a iniciar el proyecto en Visual Studio. Abrir `http://localhost:5164/vehiculos.html` o elegir Vehículos en el menú.
2. Agregar un vehículo ficticio con VIN `PRUEBA00000000001` (17 caracteres), marca y línea existentes, año 2026 y precio `100000.00`. Dejar la placa vacía. Debe asignarse el código automáticamente.
3. Editar el precio a `105000.50` y poner una placa ficticia libre, por ejemplo `PRUEBA-V01`. Guardar, recargar y comprobar los cambios.
4. Buscar por VIN, placa, marca y año; probar el filtro de marca y Ver todos.
5. Intentar agregar otro vehículo con el mismo VIN: debe rechazarlo sin perder el formulario. Cancelar esa operación.
6. Abrir un registro, cambiar de marca y comprobar que las líneas se renuevan. Cancelar para conservar el registro original. Una marca sin líneas debe impedir guardar e indicar qué falta.
7. Probar Eliminar → Conservar vehículo. Después, si es el vehículo ficticio sin dependencias, confirmar la eliminación y comprobar que desaparece.

No se necesita crear créditos manualmente para estas pruebas; el bloqueo por relaciones ya tiene evidencia automática. Las operaciones del módulo de Créditos se probarán al implementarlo.

## Estado y pendientes

Cambios locales en `pruebas-diego`, aún sin una nueva publicación en GitHub. Las tablas y el paquete SQL permanecen en su versión existente. La fase 6 sigue abierta y su PDF de cierre se entregará al finalizarla.

Quedan el mantenimiento pendiente de valoraciones, el recorrido de solicitudes y aprobación de Créditos, pagos y reportes. Los listados no tienen paginación y la edición no incluye control de versiones entre usuarios; son limitaciones del alcance académico actual.
