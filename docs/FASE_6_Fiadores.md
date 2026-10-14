# Fase 6 — Fiadores y contactos

Fecha: 12 de octubre de 2026. Avance local en `pruebas-diego`. La fase 6 continúa abierta.

## Objetivo y relación con el enunciado

El inciso C de **Base de Datos I Proyecto final I.pdf** exige registrar DPI, NIT, nombre completo, teléfono y correo de cada fiador o codeudor. Un ciudadano puede respaldar varios créditos y un crédito puede tener varios fiadores. La cantidad depende del análisis del comité; el acuerdo académico conserva uno por defecto y admite cero o más.

Este avance implementa el registro de fiadores y sus contactos. **No asigna fiadores a créditos ni aprueba financiamiento.** Esas operaciones pertenecen al futuro módulo Créditos, utilizando la relación `CreditoFiador` y sus procedimientos ya existentes. SQL ya impide que el cliente sea fiador de su propio crédito.

## Qué se puede hacer

- Agregar un fiador, consultar todos, buscar y abrir su expediente.
- Editar datos personales y varios teléfonos y direcciones.
- Reutilizar una Persona registrada con el mismo DPI, sin crear otra identidad.
- Guardar datos básicos y completar el teléfono después. Mientras falte, el expediente indica **Teléfono pendiente**. Es preparación por etapas, no un fiador completo para aprobar el crédito.
- Eliminar solamente el rol Fiador cuando no tiene créditos vinculados. Persona, contactos y otros roles se conservan.

El teléfono es parte del requisito del PDF. El procedimiento existente de aprobación comprueba al menos un teléfono por fiador requerido. Las direcciones se ofrecen porque Persona ya permite registrarlas; no se añade una dirección obligatoria al fiador ni se le exigen tres referencias. Las referencias personales corresponden al expediente del cliente.

## Datos y validaciones

| Campo | Regla implementada |
| --- | --- |
| Código de fiador | Correlativo automático de SQL; puede presentar saltos. |
| DPI | Obligatorio, exactamente 13 dígitos. Se conserva al editar. No se verifica con un registro oficial. |
| NIT | Obligatorio, hasta 20 caracteres, sujeto a unicidad de Persona en SQL. |
| Nombres y apellidos | Primer nombre y primer apellido obligatorios; segundos opcionales. Hasta 64 caracteres por campo. |
| Correo | Obligatorio, formato de correo, hasta 254 caracteres. No se añade unicidad. |
| Teléfonos | Varios; tipo del catálogo y número de 8–32 caracteres. Cero mientras se prepara; al menos uno para tener datos completos. |
| Direcciones | Opcionales; cada dirección agregada requiere tipo, departamento, municipio correspondiente y detalle de hasta 300 caracteres. |
| Nacimiento y género | No se editan en esta pantalla y se conservan si Persona ya los tiene. |

Los números de contacto se asignan dentro de cada persona. Se rechazan códigos de contactos repetidos o que no pertenezcan a la persona. Los nombres y datos de texto se recortan; se rechazan campos obligatorios con solo espacios.

## Reutilización y datos compartidos

Al agregar un fiador con un DPI existente, los nombres deben coincidir con la persona registrada. Si ya hay NIT y correo, también deben coincidir; si estaban ausentes, se completan. Esto evita reemplazar inadvertidamente los datos de un cliente o vendedor al registrar otro rol.

Si esa Persona ya tiene contactos, se registra el fiador sin agregar contactos nuevos en ese primer guardado. La aplicación conserva los existentes y permite editarlos al abrir el expediente. Si se envían contactos nuevos en ese caso, muestra una indicación y no guarda parcialmente. Si ya es fiador, se rechaza una segunda alta del mismo rol.

Editar una ficha existente sí actualiza los datos de Persona y sus contactos compartidos con Clientes y otros roles. La pantalla avisa de ese alcance. Eliminar un teléfono o dirección del formulario y guardar lo retira de la Persona compartida.

Ejemplo: una persona ya registrada como cliente puede también ser fiador de otro cliente. Al registrar ese segundo rol con el mismo DPI no se duplica Persona. Retirar el rol Fiador sin créditos vinculados conserva su registro de cliente y sus contactos.

## Recorrido de la información

Pantalla → FiadoresController → FiadorRepositorio → procedimientos `api.*` → SQL Server.

Persona, rol y contactos se guardan dentro de una transacción Serializable. Un error de municipio, NIT o relación revierte también los cambios anteriores de la misma operación. Las consultas del expediente se realizan dentro de una transacción consistente.

Solo se ejecutan procedimientos almacenados con parámetros; no se introduce SQL directo de negocio. Se reutilizan `Persona_*`, `Fiador_*`, `Telefono_*`, `Direccion_*` y los procedimientos Listar de los catálogos. No se modificaron tablas, procedimientos, permisos ni el paquete SQL.

## Archivos agregados y ajustes

| Archivo | Función |
| --- | --- |
| `src/MAGISAUTO.API/Modelos/FiadorSolicitud.cs` | Datos de entrada y ficha de respuesta con el teléfono pendiente calculado. |
| `src/MAGISAUTO.API/Controllers/FiadoresController.cs` | Rutas de listado, búsqueda, consulta individual, catálogos, alta, edición y eliminación. |
| `src/MAGISAUTO.API/Datos/FiadorRepositorio.cs` | Composición del expediente, reutilización de Persona, transacciones y errores comprensibles. |
| `src/MAGISAUTO.API/Datos/ContactosPersona.cs` | Validación y guardado compartidos de teléfonos y direcciones. Se extrajeron de ClienteRepositorio conservando su comportamiento. |
| `src/MAGISAUTO.API/Datos/ClienteSqlSesion.cs` | Sesión de procedimientos reutilizada por ambos módulos; su nombre histórico se conserva. |
| `src/MAGISAUTO.API/wwwroot/fiadores.html` | Listado, búsqueda, expediente por secciones y confirmación de eliminación. |
| `src/MAGISAUTO.API/wwwroot/fiadores.js` | Contactos dinámicos, selección dependiente de municipio, guardado y mensajes. |
| `src/MAGISAUTO.API/wwwroot/clientes.css` | Estilos existentes reutilizados por la nueva pantalla. |
| `scripts/Verificar-Fiadores.ps1` | Ensayo HTTP/SQL con registros propios y limpieza posterior. |

`Program.cs` registra FiadorRepositorio. Marcas, Líneas, Agencias, Vendedores y Clientes incluyen el enlace a Fiadores. Los modelos de contacto existentes en `ClienteSolicitud.cs` se reutilizan, sin crear formatos incompatibles para la misma Persona.

## Rutas

| Método | Ruta | Resultado |
| --- | --- | --- |
| GET | `/api/fiadores` | Todas las fichas; `criterio` opcional busca literalmente por código, DPI, NIT, nombre o correo. |
| GET | `/api/fiadores/{codigo}` | Ficha con contactos y faltantes; 404 si no existe. |
| GET | `/api/fiadores/catalogos` | Tipos de teléfono y dirección, departamentos y municipios disponibles. |
| POST | `/api/fiadores` | Guarda el registro; 201 con `codigoFiador`. |
| PUT | `/api/fiadores/{codigo}` | Guarda el expediente completo; 204. |
| DELETE | `/api/fiadores/{codigo}` | Retira el rol sin créditos vinculados; 204. |

Datos inválidos devuelven 400; duplicados o relaciones que impiden guardar/eliminar, 409. La eliminación bloqueada muestra: **«No se puede eliminar el fiador porque tiene créditos vinculados. El fiador se conserva.»** Los errores no muestran credenciales ni detalles SQL internos.

## Pruebas y evidencia

- Compilación correcta, sin errores ni advertencias; sintaxis JavaScript válida.
- **70 comprobaciones HTTP/SQL correctas**: alta incompleta, duplicados, datos inválidos, edición de contactos, búsquedas, reversión completa ante un error, conservación de fecha/género, Persona compartida con Cliente, protección por crédito, eliminación del rol y reutilización posterior.
- **62 comprobaciones de Clientes correctas** como regresión después de extraer las reglas compartidas de contactos.
- Los ensayos compararon personas, contactos, fiadores y expedientes de clientes iniciales con los datos finales. Se retiraron los registros temporales propios; los correlativos pueden avanzar.
- El crédito usado para comprobar la protección fue un borrador temporal de prueba. No se aprobó ni se generaron cobros o pagos.

Evidencias: [Fiadores](evidencias/fase-6-fiadores.json) y [regresión de Clientes](evidencias/fase-6-fiadores-regresion-clientes.json).

El navegador integrado no pudo abrir el servidor temporal: `net::ERR_CONNECTION_TIMED_OUT`. Las pruebas HTTP verificaron la entrega de HTML, JavaScript y estilos, pero no demuestran un recorrido visual completo. No se declara éxito visual automatizado ni validación móvil.

### Revisión manual de Diego — 12 de octubre de 2026

Las capturas muestran el listado inicial vacío, el alta del fiador 3 sin teléfono con el pendiente correspondiente, el paso a datos completos después de agregar el teléfono y la edición del nombre a Fiador Editado Prueba. Se comprobó visualmente la búsqueda por nombre y por parte del DPI. Diego confirmó también la búsqueda por correo, Ver todos y Conservar fiador. Finalmente mostró el aviso de eliminación correcta y el listado sin fiadores.

La imagen de eliminación confirma la respuesta y la retirada del listado; la conservación de Persona y contactos dispone de evidencia automática. No se atribuye a estas capturas una inspección directa de las tablas. La persistencia específica después de F5, las direcciones, Volver sin guardar, la reutilización y el bloqueo por crédito no se declaran comprobados manualmente sin confirmación adicional.

Para repetir el ensayo desde PowerShell 7, con la configuración local preparada, compilar la API y ejecutar `./scripts/Verificar-Fiadores.ps1`; el parámetro `-SalidaCompilacion` permite indicar otra carpeta dentro del proyecto API. El ensayo solo debe usarse en el entorno académico local: crea y retira sus propios datos ficticios y no sustituye una prueba de producción.

## Prueba manual recomendada

1. Detener y volver a iniciar la aplicación en Visual Studio. Abrir `http://localhost:5164/fiadores.html` o pulsar Fiadores en el menú.
2. Agregar una persona ficticia con DPI libre de 13 dígitos, NIT de prueba libre, nombre, apellido y correo de ejemplo. Guardar sin contactos: debe aparecer el teléfono pendiente.
3. Agregar un teléfono con su tipo y guardar. Debe indicar datos completos para revisión aunque no se agregue dirección. Opcionalmente agregar otra línea telefónica y una dirección del catálogo.
4. Editar un nombre o contacto, guardar, recargar y volver a abrir. Buscar por nombre, DPI, NIT o correo; probar Ver todos.
5. Hacer un cambio sin guardarlo y pulsar Volver sin guardar; al abrir de nuevo debe conservarse la versión guardada.
6. Pulsar Eliminar y después Conservar fiador: debe permanecer. Para probar la eliminación real, usar solo el fiador ficticio sin créditos vinculados. Se retira el rol; se conserva su Persona.
7. Si se prueba la reutilización, usar los datos exactos de una persona ficticia existente; registrar el rol sin contactos nuevos y comprobar que aparecen los anteriores al abrirlo.

La protección de un fiador con crédito ya cuenta con ensayo automático; no se necesita inventar un crédito desde SQL para la prueba manual de esta pantalla.

## Límites y pendientes

No hay asignación de fiadores a créditos en esta pantalla, evaluación de riesgo, autenticación del comité ni decisiones automáticas de aprobación. La edición simultánea no dispone de control de versiones: el último expediente completo guardado puede sobrescribir cambios de otra sesión. Los listados componen los datos por procedimientos sin paginación, apropiados para el volumen académico actual.

Vehículos se incorporó después de este módulo; su alcance y pruebas se documentan en [Vehículos](FASE_6_Vehiculos.md). Sigue pendiente el recorrido de Créditos, pagos y reportes. Este avance no cierra la fase 6. Su PDF se entregará al cerrar la fase, según lo acordado; el contenido editable de este módulo queda aquí. Los cambios continúan locales y no se ha realizado una publicación nueva en GitHub.
