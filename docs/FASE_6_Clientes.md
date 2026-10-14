# Fase 6 — Clientes, contactos y referencias

Fecha: 11 de octubre de 2026. Trabajo local en `pruebas-diego`. La fase 6 continúa abierta.

## Objetivo y alcance

El inciso A requiere identificar al cliente, permitir varios teléfonos y direcciones y registrar al menos tres referencias completas. Este módulo permite preparar ese expediente desde una pantalla, con datos de Persona, Deudor, Telefono, Direccion, Referencia y DetalleReferencia ya existentes en SQL V2.

Se puede agregar, consultar, buscar, editar y eliminar el rol cliente cuando no tiene dependencias. Los teléfonos, direcciones y vínculos de referencias se agregan, editan o quitan desde el expediente; todos los cambios se guardan juntos.

**El módulo no presenta ni aprueba solicitudes de crédito.** El indicador de datos completos es una comprobación del expediente guardado en la API, no un nuevo estado contractual ni una validación SQL de presentación. Al construir Créditos seguirá pendiente implementar el paso formal de presentación mediante procedimiento, que exigirá las tres referencias. La aprobación SQL existente vuelve a validarlas. No se cambia el enunciado ni se declara cumplido ese paso por tener el indicador.

## Datos y reglas

| Dato | Regla |
| --- | --- |
| Código de cliente | Correlativo automático de Deudor. Los saltos no son errores. |
| DPI | Obligatorio, 13 dígitos. No se sustituye la persona al editar. Es validación de formato, no verificación oficial. |
| NIT | Obligatorio, máximo 20 caracteres, único según el esquema. No se consulta un registro oficial. |
| Nombres y apellidos | Primer nombre y primer apellido obligatorios; segundos opcionales. Hasta 64 caracteres por campo. |
| Correo | Obligatorio y con formato válido; puede compartirse entre personas. |
| Nacimiento | Obligatorio y anterior a hoy, considerando Guatemala. Se usa en los reportes de cumpleaños. |
| Teléfonos | Cero o más al preparar; mínimo uno para considerar completos los contactos. Tipo y número de 8–32 caracteres; correlativo automático dentro de la persona. |
| Direcciones | Cero o más al preparar; mínimo una para completar contactos. Tipo, departamento, municipio y detalle de hasta 300 caracteres. |
| Referencias | Se pueden completar por etapas. Nombre, trabajo, tipo de referencia y relación son requeridos al guardar una referencia; sus contactos pueden completarse después. |

Un cliente nuevo puede guardarse con sus datos básicos y sin contactos o referencias. No se permite omitir sus datos de identidad requeridos por `Deudor_Insertar`. Por tanto, «borrador incompleto» aquí significa un expediente con contactos o referencias pendientes, no una Persona sin identificación registrada como cliente.

El indicador enumera lo que falta: teléfono del cliente, dirección del cliente y al menos tres referencias con teléfono y dirección. Los vínculos se identifican por CodigoReferencia y cada Referencia corresponde a una Persona única. No cuenta dos veces el mismo vínculo ni permite usar al propio cliente como referencia. La aplicación no puede certificar la identidad real de referencias que se capturan sin DPI; se debe reutilizar una referencia ya registrada en lugar de crear otra ficha de la misma persona.

## Personas y referencias compartidas

Al crear un cliente cuyo DPI ya existe, se reutiliza Persona si sus nombres coinciden y aún no es cliente. La ficha se completa con los datos requeridos del cliente y conserva género. Si ya tenía contactos y el formulario nuevo no envía otros, se conservan. Si se envían contactos nuevos en ese caso, se pide primero registrar el rol y luego abrir el expediente para ampliarlos con la información existente.

Editar nombres, NIT, correo, nacimiento o contactos modifica la Persona compartida con sus demás roles. El formulario explica esta relación. El módulo conserva los campos personales no editados de una referencia, incluidos DPI, NIT, correo, nacimiento y género.

Las referencias pueden:

- **Crearse:** se registra Persona, su rol Referencia, trabajo, contactos y vínculo con el cliente en una transacción.
- **Reutilizarse:** el selector permite vincular una referencia existente. Esa primera vinculación conserva sus datos compartidos; solo se guarda el tipo/relación del vínculo. Para editarla, se guarda y vuelve a abrir el expediente.
- **Editar sus datos:** los cambios personales, de trabajo y contactos afectan la ficha compartida; el parentesco/tipo afecta solo el vínculo con ese cliente.
- **Quitarse del expediente:** se elimina DetalleReferencia, conservando Referencia, Persona y sus contactos para los demás clientes.

No se implementa en esta pantalla la eliminación global de una Persona o Referencia. El cliente con créditos o vínculos de referencias no puede eliminarse; primero deben resolverse las dependencias permitidas. Eliminar su rol no borra Persona, contactos ni otros roles. No hay borrado en cascada.

## Guardado completo y protección frente a errores

La API recibe la versión completa del expediente. Los contactos ausentes de esa versión se quitan; los contactos nuevos llevan correlativo cero y el servidor asigna su número. Los códigos existentes deben pertenecer a esa persona. Se rechazan correlativos repetidos, vínculos repetidos y referencias inexistentes.

Una transacción exterior Serializable agrupa todas las llamadas a procedimientos. Si falla un municipio, NIT, identidad o relación, se revierte también lo que se había cambiado antes dentro de esa operación. Las lecturas del expediente usan una transacción consistente.

Esto no es control de versiones del formulario: dos personas editando una ficha antigua todavía pueden sobrescribir cambios válidos. La aplicación está orientada al trabajo local académico; no se declara resuelta la edición simultánea por varios usuarios.

Si guardar tiene éxito pero falla la recarga de la respuesta, la pantalla conserva el código asignado y ofrece **Recargar expediente**, sin repetir la creación. Los errores normales de guardado conservan el formulario. Volver sin guardar descarta los cambios locales explícitamente.

## Arquitectura y archivos

Pantalla → API de Clientes → ClienteRepositorio → ClienteSqlSesion → procedimientos existentes `api.*` → SQL Server.

| Archivo | Responsabilidad |
| --- | --- |
| `src/MAGISAUTO.API/Modelos/ClienteSolicitud.cs` | Modelos de datos básicos, teléfonos, direcciones, referencias y ficha con faltantes calculados. |
| `src/MAGISAUTO.API/Controllers/ClientesController.cs` | Listado, consulta individual, catálogos, alta, edición y eliminación. |
| `src/MAGISAUTO.API/Datos/ClienteRepositorio.cs` | Compone el expediente, conserva personas compartidas y guarda los cambios de forma atómica. |
| `src/MAGISAUTO.API/Datos/ClienteSqlSesion.cs` | Ejecuta solo procedimientos y vincula sus parámetros; los nombres se eligen en código, nunca desde la petición. |
| `src/MAGISAUTO.API/Program.cs` | Registra el repositorio. |
| `src/MAGISAUTO.API/wwwroot/clientes.html` | Listado y editor por secciones. |
| `src/MAGISAUTO.API/wwwroot/clientes.js` | Formularios dinámicos, catálogo de municipios dependiente del departamento, referencias y peticiones. |
| `src/MAGISAUTO.API/wwwroot/clientes.css` | Diseño de contactos, referencias y editor adaptable a pantallas pequeñas. |
| `scripts/Verificar-Clientes.ps1` | Ensayo HTTP/SQL con datos propios y limpieza. |

Marcas, Líneas, Agencias y Vendedores incluyen ahora el enlace a Clientes. Los valores se muestran como texto, no como HTML proporcionado por el usuario.

Se reutilizan los procedimientos Listar de Persona, Deudor, Telefono, Direccion, Referencia, DetalleReferencia y los catálogos de tipos y ubicación; además de los Insertar/Actualizar/Eliminar necesarios para guardar y retirar vínculos. No se usa SQL directo de negocio, ni se añaden tablas, procedimientos, permisos o migraciones en este avance. El paquete SQL continúa igual.

## Rutas y respuesta

| Ruta | Resultado |
| --- | --- |
| `GET /api/clientes?criterio=texto` | Lista fichas; filtro literal por código, DPI, NIT, nombre o correo. Sin filtro, lista todas. |
| `GET /api/clientes/{codigo}` | Ficha individual, contactos, referencias completas y faltantes; 404 si no existe. |
| `GET /api/clientes/catalogos` | Tipos, departamentos, municipios y referencias disponibles para reutilizar. |
| `POST /api/clientes` | 201 con `codigoCliente`, después de guardar. |
| `PUT /api/clientes/{codigo}` | 204 si se guardó todo el expediente. |
| `DELETE /api/clientes/{codigo}` | 204 al retirar el rol sin dependencias. |

Faltantes se devuelve como lista de textos; `referenciasCompletas` cuenta las referencias con contactos. No existe una ruta para presentar solicitudes o aprobar créditos en este módulo.

400 indica datos o filtros inválidos, 404 un registro inexistente y 409 duplicados, identidades o relaciones que impiden la operación. Los fallos SQL no clasificados pasan por el manejador general. Las credenciales no aparecen en las respuestas.

## Pruebas ejecutadas

- Compilación final sin errores ni advertencias; sintaxis JavaScript válida.
- 62 comprobaciones HTTP/SQL correctas, incluidas preparación incompleta, contactos múltiples, dos/tres referencias, referencia sin teléfono, reversión total ante un error, DPI/NIT duplicados, referencias repetidas y propia, reutilización entre clientes, desvinculación sin borrar la ficha compartida, protección por crédito, eliminación del rol y conservación de contactos al recrearlo.
- 59 comprobaciones de Vendedores correctas como regresión.
- Datos iniciales de clientes y personas comparados antes y después; los datos temporales se retiraron. Los correlativos pueden avanzar.

Evidencias: [Clientes](evidencias/fase-6-clientes.json) y [regresión de Vendedores](evidencias/fase-6-clientes-regresion-vendedores.json).

El ensayo utilizó datos ficticios propios, catálogos existentes y un crédito borrador temporal para comprobar dependencias. No aprobó créditos ni produjo cuotas o pagos. No modificó personas reales del usuario. No se repite la auditoría de instalación vacía porque el usuario puede haber añadido sus propios registros.

La herramienta de navegador no pudo inicializarse: «failed to write kernel assets … no se puede encontrar la ruta especificada». No se afirma recorrido visual automatizado ni validación móvil. Servir HTML/JS por HTTP no demuestra por sí solo el funcionamiento visual de los formularios.

### Comprobación manual de Diego — 12 de octubre de 2026

Las capturas y confirmaciones muestran el guardado por etapas (sin contactos, con contactos, con dos referencias y con tres referencias completas), la edición del segundo nombre y las búsquedas por nombre, DPI y correo. Diego confirmó Abrir expediente y Ver todos. Al volver a abrir se muestran el nombre editado y datos de las referencias. También confirmó Conservar cliente; posteriormente intentó eliminar el cliente con referencias y la operación fue bloqueada.

Ese último ensayo mostró un aviso demasiado general sobre catálogos y dependencias. Se ajustó exclusivamente el manejo del error de relación al eliminar el cliente para responder: «No se puede eliminar el cliente porque tiene créditos o referencias vinculadas. El cliente se conserva». El cambio no modifica las reglas de eliminación, los datos ni los procedimientos SQL. Diego mostró posteriormente la nueva redacción en la interfaz, confirmando la corrección. La eliminación permitida de un cliente sin dependencias cuenta con prueba automática, pero no se declara comprobada manualmente en este recorrido.

Al incorporar Fiadores se extrajeron la validación y el guardado de contactos a `Datos/ContactosPersona.cs`, compartidos por ambos repositorios; la sesión de procedimientos `ClienteSqlSesion` también se reutiliza. Se repitieron las 62 comprobaciones de Clientes con resultado correcto. Evidencia: [regresión al agregar Fiadores](evidencias/fase-6-fiadores-regresion-clientes.json).

## Prueba manual por etapas

1. Reiniciar el proyecto y abrir `http://localhost:5164/clientes.html`.
2. Agregar un cliente ficticio: DPI libre de 13 dígitos, NIT de prueba libre, nombres, correo de ejemplo y fecha pasada. Guardar sin contactos. Debe indicar que faltan teléfono, dirección y tres referencias.
3. Agregar dos teléfonos y una dirección, seleccionando un municipio del departamento elegido. Guardar, recargar y buscar al cliente por nombre o DPI.
4. Crear dos referencias con sus nombres, trabajo, relación, teléfono y dirección; guardar. El indicador debe mostrar dos referencias completas y mantener el pendiente.
5. Agregar la tercera referencia completa y guardar. Debe indicar datos completos para revisión, sin aprobar ni presentar crédito.
6. Editar un teléfono, dirección o relación; recargar y comprobar persistencia. Probar **Volver sin guardar** después de un cambio local.
7. Para retirar el cliente de prueba, quitar sus vínculos de referencias y guardar primero. Luego eliminar el rol cliente desde el listado. Las fichas personales y referencias permanecen según las reglas del módulo.

Los departamentos y municipios ofrecidos son los existentes en la base; este módulo no inventa ni carga un catálogo geográfico completo. Su administración sigue fuera de este avance.

## Estado de entrega

Cambios locales en `pruebas-diego`, sin publicación nueva. La fase 6 sigue abierta y no se genera todavía su PDF de cierre. Después de la revisión manual quedan por completar los demás módulos del enunciado, incluidos fiadores, vehículos, presentación/aprobación de créditos, pagos y reportes.
