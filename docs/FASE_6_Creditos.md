# Fase 6 — Créditos, presentación y aprobación

Implementación del 12 de octubre de 2026 en `pruebas-diego`. La fase 6 sigue abierta. Este documento describe código local; no acredita publicación en GitHub ni instalación en la base del proyecto.

## Recorrido y significado de cada paso

1. **Guardar borrador**: número de obligación único (1–20 letras, números, guion o guion bajo), cliente, vehículo, vendedor, enganche, plazo y fiadores. Guarda las condiciones y asignaciones en una sola transacción. Permite un expediente incompleto y completar los fiadores por etapas. Aún no genera cuotas, depreciación ni ingresos.
2. **Presentar solicitud**: el procedimiento `api.Credito_Presentar` exige identificación, NIT, correo, nacimiento, teléfono y dirección del cliente, más tres referencias distintas y completas. Guarda `FechaPresentacion` y `PresentadoPor`. La presentación es un hito del borrador, no un nuevo estado contractual: `Estado` sigue siendo `BORRADOR`. La pantalla dice «Solicitud presentada».
3. **Aprobar y generar cuotas**: requiere presentación previa y vuelve a comprobar cliente, referencias, fiadores y vehículo. Guarda responsable y fecha de aprobación, pasa a `VIGENTE`, crea el plan completo, una depreciación inicial y el resumen. Todo ocurre en la transacción SQL existente, dentro de una transacción serializable de la API.
4. **Consultar**: listado, búsqueda por número/cliente/VIN/estado, expediente y plan con capital, interés, manejo, ambos seguros y total de cada cuota.
5. **Eliminar borrador**: retira sus asignaciones de fiadores junto con el crédito, conservando personas y roles. Si otras dependencias lo impiden, revierte todo. Nunca elimina contratos aprobados.
6. **Anular**: requiere motivo y responsable. Conserva el historial, las cuotas y la aprobación. Los pagos efectivos impiden anular. Esta pantalla no registra ni anula pagos; ese módulo sigue pendiente.

Editar condiciones del borrador o modificar sus asignaciones SQL de fiadores borra la presentación vigente. Hay que presentarlo otra vez. Los cambios posteriores en el expediente personal se revisan nuevamente al aprobar; la fecha de presentación documenta el acto anterior, no una garantía permanente de que los datos siguen completos.

## Reglas y cantidades

- El número del crédito lo escribe el operador y se conserva al editar. No se añadió otro correlativo de vehículo.
- Enganche mínimo: porcentaje activo (inicialmente 20%), redondeado hacia arriba al centavo. Debe quedar un monto positivo por financiar. Plazos: 12, 24, 36, 48 o 60 meses.
- Al guardar condiciones se toman el precio actual, la agencia del vendedor y los parámetros activos. El formulario avisa que editar un borrador vuelve a tomar esos valores.
- Comisión predeterminada, interés, seguros y depreciación proceden de la configuración SQL. En esta entrega no hay controles para sobreescribir esos porcentajes por contrato.
- Cuota francesa y ajuste final existentes, Q25 de manejo por cuota y seguros calculados sobre el monto inicial financiado. Se muestran resultados SQL, sin recalcular el plan en JavaScript.
- Total neto recaudable es la suma de cuotas: incluye capital, interés, manejo y seguros; excluye enganche y no resta comisiones. No representa cobros realizados ni utilidad.
- La API devuelve decimales como texto para conservar centavos. La entrada de enganche admite número JSON o texto decimal; rechaza más de dos decimales.
- El comité indica la cantidad de fiadores; puede ser cero. La aprobación exige la cantidad y datos obligatorios. Una persona no puede respaldar su propio crédito.
- Un vehículo solo puede respaldar un crédito vigente. Varios borradores pueden evaluarlo; la exclusividad se comprueba al aprobar.
- La interfaz desactiva presentar/aprobar/anular mientras haya cambios sin guardar. Cada operación sensible tiene confirmación propia. Los errores conservan el formulario; si la escritura terminó pero falla la recarga, se avisa para evitar repetirla.

## Archivos y responsabilidades

| Archivo | Función |
|---|---|
| `src/MAGISAUTO.API/Modelos/CreditoSolicitud.cs` | Valida número, identificadores, plazo, enganche y fiadores distintos; responsable/motivo obligatorios. |
| `src/MAGISAUTO.API/Datos/CreditoRepositorio.cs` | Lee mediante procedimientos, enriquece nombres, conserva precisión y agrupa condiciones/asignaciones en una transacción. Traduce rechazos SQL a mensajes de negocio. |
| `src/MAGISAUTO.API/Controllers/CreditosController.cs` | Expone las rutas de consulta, borrador y acciones. |
| `src/MAGISAUTO.API/Program.cs` | Registra el repositorio para los controladores. |
| `src/MAGISAUTO.API/wwwroot/creditos.html`, `.js`, `.css` | Pantalla, formulario, confirmaciones, revisión del cliente y plan de cuotas. Los otros módulos incluyen su enlace. |
| `database/v2/src/presentacion_procs.py` | Fuente del nuevo procedimiento de presentación. |
| `database/v2/src/financial_procs.py` | Invalida presentación al editar; exige presentación al aprobar, conservando las validaciones previas. |
| `database/v2/src/build_entrega.py` | Incluye las dos columnas nuevas y el procedimiento; las operaciones de asignación invalidan presentación. |
| `database/v2/src/build_migracion_creditos.py` | Genera el parche desde las mismas definiciones del instalador, sin copiar lógica a mano. |
| `database/v2/migraciones/001_Presentacion_Creditos.sql` | Parche aditivo y repetible para una base v2 existente. |
| `scripts/Verificar-Creditos.ps1` | Ensayos HTTP/SQL con cuenta API limitada sobre la base de validación, con limpieza de sus registros propios. |

## API

| Método | Ruta | Resultado |
|---|---|---|
| GET | `/api/creditos?criterio=...` | Lista y filtra créditos. |
| GET | `/api/creditos/catalogos` | Clientes, vendedores, fiadores, vehículos y configuración activa. |
| GET | `/api/creditos/{numero}` | Condiciones, presentación, responsables, fiadores y cuotas. |
| POST | `/api/creditos` | Crea borrador con asignaciones, responde 201. |
| PUT | `/api/creditos/{numero}` | Actualiza borrador; responde 204. |
| POST | `/api/creditos/{numero}/presentar` | Comprueba expediente y registra presentación. |
| POST | `/api/creditos/{numero}/aprobar` | Aprueba y genera cuotas; responde 204. |
| POST | `/api/creditos/{numero}/anular` | Conserva historial y registra motivo/actor. |
| DELETE | `/api/creditos/{numero}` | Elimina únicamente borrador sin otras dependencias. |

Las acciones de presentar/aprobar reciben `responsable`; anular recibe también `motivo`. Los errores de validación HTTP devuelven 400, ausencia 404, reglas/dependencias 409 y migración faltante 503. Los nombres de procedimientos se eligen en código, no desde el cuerpo HTTP. La API no ejecuta consultas directas sobre tablas.

## Instalación en la base del proyecto

La cuenta disponible para la aplicación y revisión **no tiene permisos para modificar el esquema** de `MAGISAUTO_Proyecto_V2`. Sí existe acceso administrativo a `MAGISAUTO_ValidacionV2`, donde se ensaya el parche.

1. En SSMS, con la cuenta que administra el proyecto, abrir `database/v2/migraciones/001_Presentacion_Creditos.sql` y ejecutarlo completo. El archivo selecciona expresamente `MAGISAUTO_Proyecto_V2`.
2. Comprobar el resultado «Presentación de créditos instalada». No borra bases ni registros. Si falla, revierte su transacción. Se puede ejecutar nuevamente.
3. Detener y reiniciar la API desde Visual Studio. Abrir `http://localhost:5164/creditos.html`.

El instalador completo se actualiza a revisión 2.1 para **bases nuevas**: 26 tablas, 151 procedimientos, 4 vistas y 2 funciones. Para la base existente usar el parche, no el instalador completo. Los créditos históricos no reciben fechas de presentación inventadas. El verificador de huellas de la versión 2.0 es histórico y no debe interpretarse como verificador de esta revisión.

## Prueba manual guiada

Preparar un vehículo ficticio libre y un vendedor. Reutilizar el cliente de prueba con tres referencias completas o crear otro; agregar un fiador con teléfono si se requieren uno o más.

1. Agregar `PRUEBA-CREDITO-01`, seleccionar los registros, precio del vehículo Q100000, enganche `20000.00`, plazo 12 y un fiador. Guardar. Debe decir Borrador y no mostrar cuotas.
2. Abrir el expediente, comprobar selecciones y condiciones, recargar el navegador y abrir nuevamente. Buscar por número, cliente y VIN; probar Ver todos.
3. Con un cliente que tenga dos referencias, Presentar debe explicar que faltan referencias. Completar la tercera desde Clientes y volver a intentarlo.
4. Presentar indicando responsable. Debe mostrar solicitud presentada, fecha y nombre, sin cuotas.
5. Editar y guardar el borrador: debe requerir presentación otra vez. Cancelar cualquiera de los cuadros de confirmación conserva el registro.
6. Después de revisar las condiciones, aprobar el crédito de prueba. Debe mostrar VIGENTE y 12 cuotas con su desglose. El capital acumulado debe ser Q80000.
7. No se permite editar ni eliminar el contrato aprobado. Una anulación de prueba requiere motivo y conserva el plan; no equivale a borrar el ensayo de la base del proyecto.

Para probar eliminación, crear otro **borrador**, sin aprobarlo; eliminarlo y comprobar que las fichas de clientes y fiadores siguen disponibles. Los contratos aprobados para revisión manual permanecerán como historial en la base del proyecto.

## Verificación realizada

- Compilación .NET sin errores ni advertencias; sintaxis JavaScript comprobada.
- **57 comprobaciones correctas** HTTP/SQL en `MAGISAUTO_ValidacionV2`, con la misma cuenta limitada de la API. Se comprobó que no puede leer directamente las tablas.
- Migración aplicada dos veces sin fallo; borrador con dos referencias permitido, presentación bloqueada, presentación completa registrada y aprobación directa bloqueada.
- Edición invalida presentación. Quitar una referencia después de presentar bloquea aprobación; un fiador sin teléfono también la bloquea.
- Plan de 12 cuotas con suma decimal exacta de Q80000 de capital, total neto igual a la suma de cuotas y manejo/seguros conforme a las condiciones activas. La base de validación conserva una configuración modificada por pruebas anteriores; no se restableció la configuración del proyecto.
- Duplicados y condiciones inválidas rechazados, con reversión de asignaciones ante fallo. Exclusividad del vehículo al aprobar; contratos aprobados no editables ni eliminables.
- Pago efectivo bloquea anulación; tras anular el pago de ensayo, la anulación del crédito conserva cuotas, motivo y aprobación.
- Los registros iniciales de 15 tablas de validación se compararon después de limpiar exclusivamente el prefijo aleatorio del ensayo: quedaron intactos. Avanzar identidades/secuencia durante ensayos es normal. No se ejecutaron altas, aprobaciones ni pagos en la base del proyecto.

Evidencia: [fase-6-creditos.json](evidencias/fase-6-creditos.json). Repetir con PowerShell 7: `scripts/Verificar-Creditos.ps1`, después de compilar en `src/MAGISAUTO.API/bin/Creditos`. La credencial administrativa de validación se suministra con `-Credencial`; el ensayo no permite cambiar el destino a la base del proyecto. El acceso administrativo se usa exclusivamente para instalar el parche y preparar/limpiar sus propios datos ficticios; las acciones bajo prueba pasan por HTTP y la cuenta API.

Los antiguos 45 ensayos SQL y los archivos `validacion-*.json` del paquete acreditan v2.0, no se presentan como una nueva ejecución sobre v2.1. La fuente del ensayo histórico se adaptó para incluir presentación y el nuevo inventario; todavía exige una base de validación sin operaciones para repetirse. No se ha verificado una instalación nueva completa de v2.1; sí el parche sobre v2.0 y el recorrido descrito.

## Límites y pendientes

- Diego confirmó manualmente el recorrido principal: alta de borrador, presentación, aprobación, 12 cuotas, persistencia al reabrir, búsquedas por número y cliente y Ver todos. Los demás rechazos y anulaciones cuentan con el ensayo automatizado; no se afirma que todos hayan sido repetidos manualmente.
- Instalación del parche en `MAGISAUTO_Proyecto_V2` confirmada por la captura de SSMS de Diego y el recorrido de presentación/aprobación en la aplicación.
- Autenticación/roles del personal no implementados: responsable es un nombre escrito, no una identidad autenticada. Esta es una aplicación académica local.
- Sin paginación, sin bloqueo optimista para ediciones simultáneas de borradores y sin historial de cada presentación reemplazada. Las reglas financieras sí se protegen en SQL/transacciones.
- Pagos, reportes y mantenimiento pendiente de valoraciones continúan en la fase 6. El PDF integral se entregará al cerrar esa fase.


## Aceptación manual y continuación — 13 de octubre

Las capturas de Diego confirman el crédito `PRUEBA-CREDITO-01`, cliente 6, vehículo 14, vendedor 16 y fiador 4. Precio Q100000, enganche Q20000 y capital Q80000, plazo 12 meses. El plan aprobado conserva intereses Q5519.56 y total Q87739.56, con 12 cuotas de Q7311.63, manejo Q25 y seguros Q120/Q40. Se conservó vigente para probar [Pagos y abonos](FASE_6_Pagos.md). La instalación y la revisión manual marcadas como pendientes en secciones anteriores describen el estado de entrega inicial, ya superado para este recorrido.
