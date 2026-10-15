# Fase 6 — Catálogos auxiliares

Avance local del 14 de octubre de 2026, rama `pruebas-diego`, sobre el commit
`cf6658a58a085c8d35996c208d69ef615840d8b5`. La fase 6 continúa abierta.

## Qué se incorporó

La pantalla **Catálogos auxiliares** (`/auxiliares.html`) permite listar, buscar, agregar,
editar y eliminar los siete catálogos que la auditoría inicial identificó sin mantenimiento
en la interfaz. Una lista desplegable cambia el catálogo sin crear siete pantallas repetidas.
Se añadió el enlace a las diez páginas anteriores.

| Catálogo / identificador de API | Entidad SQL | Clave y particularidades |
| --- | --- | --- |
| Departamentos / `departamentos` | `Departamento` | `CodigoDepartamento` |
| Municipios / `municipios` | `Municipio` | `CodigoDepartamento` + `CodigoMunicipio`; filtro por departamento y nombre del departamento en cada fila. |
| Tipos de teléfono / `tipos-telefono` | `TipoTelefono` | `CodigoTipoTelefono` |
| Tipos de dirección / `tipos-direccion` | `TipoDireccion` | `CodigoTipoDireccion` |
| Tipos de garantía / `tipos-garantia` | `TipoGarantia` | `CodigoTipoGarantia` |
| Tipos de referencia / `tipos-referencia` | `TipoReferencia` | `CodigoTipoReferencia` |
| Tipos de pago / `tipos-pago` | `TipoPago` | `CodigoTipoPago` y elección obligatoria Sí/No de `RequiereReferencia`. |

Los códigos son enteros positivos capturados por el usuario: estas tablas no usan IDENTITY.
Al editar se conservan código y departamento. La descripción es obligatoria, admite hasta
128 caracteres y se guarda sin espacios exteriores. No se inventa unicidad de descripciones.
Un código de municipio puede repetirse en otro departamento; ambas filas son independientes.

SQL conserva las relaciones: no permite eliminar departamentos con municipios, municipios
con direcciones ni tipos utilizados por teléfonos, direcciones, garantías, referencias o pagos.
La pantalla pide confirmar, identifica el registro y explica el bloqueo si existe una dependencia.

En Tipos de pago, cambiar la exigencia de referencia bancaria se aplica a nuevos pagos según
el procedimiento existente; no reescribe `DetallePago`. La descripción del medio se consulta
desde el catálogo, por lo que renombrarla puede cambiar el nombre mostrado en consultas de
recibos anteriores. No se implementó una copia histórica del nombre.

## Recorrido y archivos

`auxiliares.html` → `auxiliares.js` → `CatalogosAuxiliaresController` →
`CatalogoAuxiliarRepositorio` → `api.<Entidad>_<Operación>`.

| Archivo relativo al repositorio | Responsabilidad |
| --- | --- |
| `src/MAGISAUTO.API/Datos/CatalogosAuxiliares.cs` | Lista cerrada de siete catálogos y sus campos. No permite elegir tablas o procedimientos arbitrarios por HTTP. |
| `src/MAGISAUTO.API/Modelos/CatalogoAuxiliarSolicitud.cs` | Crear/editar y respuesta uniforme. Rechaza campos JSON desconocidos. |
| `src/MAGISAUTO.API/Datos/CatalogoAuxiliarRepositorio.cs` | Parámetros tipados, lectura por SP, claves compuestas y traducción de duplicados/dependencias. Consume el resultado completo del SP antes de confirmar éxito. |
| `src/MAGISAUTO.API/Controllers/CatalogosAuxiliaresController.cs` | Rutas, filtros permitidos y códigos de respuesta. |
| `src/MAGISAUTO.API/Program.cs` | Registro del repositorio. |
| `src/MAGISAUTO.API/wwwroot/auxiliares.html`, `auxiliares.js`, `auxiliares.css` | Formulario, tabla, filtros, estados de carga/error/vacío, confirmación y estilos. |
| Las otras diez páginas HTML | Solo enlace de navegación al nuevo módulo. |
| `scripts/Verificar-CatalogosAuxiliares.ps1` | Prueba HTTP/SQL real con limpieza de datos propios y comparación de las 26 tablas. |
| `scripts/verificar-auxiliares-ui.cjs` | Recorrido de navegador preparado con HTTP simulado; **no aprobado en este entorno**. |

La interfaz usa `textContent` para mostrar descripciones, bloquea envíos repetidos durante una
escritura y conserva el formulario cuando falla. Las lecturas anteriores se cancelan y se
identifican por versión para impedir que una respuesta tardía cambie el catálogo seleccionado.
La tabla puede desplazarse horizontalmente en pantallas pequeñas; esto requiere revisión visual.

## API y SQL reutilizado

Base: `/api/catalogos/auxiliares`. `GET` a la base devuelve las siete definiciones públicas.

| Método y ruta relativa | Operación existente | Resultado |
| --- | --- | --- |
| `GET /{catalogo}` | `api.<Entidad>_Listar` | 200, filas. |
| `GET /{catalogo}?criterio=texto` | `api.<Entidad>_Buscar` | 200, coincidencias. |
| `POST /{catalogo}` | `api.<Entidad>_Insertar` | 201, fila guardada. |
| `PUT /{catalogo}/{codigo}` | `api.<Entidad>_Actualizar` | 200, fila actualizada. |
| `DELETE /{catalogo}/{codigo}` | `api.<Entidad>_Eliminar` | 204. |

En Municipios, PUT y DELETE requieren `?codigoDepartamento=...`; GET permite ese filtro
opcional, aplicado en memoria al resultado del SP. No se introduce SQL de texto en la API.
La búsqueda conserva el LIKE existente, incluidos sus comodines; el criterio admite 200 caracteres.

Alta de municipio de ejemplo (solo con códigos disponibles y departamento existente):

```json
{"codigo":50,"codigoDepartamento":21,"descripcion":"Municipio de prueba"}
```

Edición de tipo de pago (código en la ruta):

```json
{"descripcion":"Medio de prueba","requiereReferencia":false}
```

Validación incorrecta: 400. Catálogo/registro inexistente: 404. Código duplicado o dependencia:
409. Fallo de conexión: 503 mediante el manejador general. Los errores no incluyen cadenas de
conexión ni mensajes internos de SQL. Los nombres internos de entidades/SP no se envían en los
metadatos públicos. Las respuestas del controlador no se almacenan en caché.

Se reutilizan **35 procedimientos existentes** (cinco por entidad). **No hay migración ni
cambio de SQL, esquema, permisos o configuración local en este bloque.** Los selectores de
Clientes, Fiadores, Vehículos y Pagos ya leen estos catálogos mediante SP; una página abierta
puede necesitar recargarse para actualizar sus opciones.

## Validación realizada y límites

- Compilación .NET: cero errores y cero advertencias.
- **242 comprobaciones HTTP/SQL correctas** en `MAGISAUTO_ValidacionV2`, usando la cuenta
  limitada de la API. Se verificó su falta de SELECT directo a tablas (error 229).
- Altas, búsquedas, ediciones, eliminación propia, duplicados y siete bloqueos por FK;
  descripciones inválidas, campos desconocidos, filtros repetidos, claves incompletas,
  departamentos inexistentes y valores booleanos true/false.
- Dos municipios con igual código en distintos departamentos se probaron por separado.
- Se compararon las 26 tablas antes y después, ordenadas por clave primaria: sus datos
  anteriores quedaron iguales tras retirar exclusivamente los registros de ensayo.
- Se verificaron los recursos nuevos y los enlaces de las diez páginas anteriores por HTTP.
- La opción explícita de conexión local sin cifrado se usó solamente en el proceso de ensayo
  contra `127.0.0.1`; no se guardó en la configuración del proyecto.

Evidencia: [resultado HTTP/SQL](evidencias/fase-6-auxiliares.json).

**La revisión en navegador queda pendiente.** Edge no pudo iniciar en el entorno restringido;
el navegador integrado tampoco logró acceder al servidor local (tiempo de conexión agotado).
No se cuentan pruebas de interfaz como aprobadas ni se presentan capturas inventadas.
El guion Playwright está preparado para datos simulados y no sustituye la prueba real SQL.
Estado resumido: [limitación del navegador](evidencias/fase-6-auxiliares-navegador.json).

Para repetir la integración, compilar primero y ejecutar con PowerShell 7:

```powershell
dotnet build src/MAGISAUTO.API/MAGISAUTO.API.csproj --no-restore -o src/MAGISAUTO.API/bin/Auxiliares -p:UseAppHost=false
pwsh -NoProfile -File scripts/Verificar-CatalogosAuxiliares.ps1
```

La prueba requiere la base aislada ya preparada, la credencial administrativa DPAPI del equipo
de desarrollo y la cuenta limitada configurada localmente con acceso por SP a esa base.
No crea la base ni cambia permisos. El parámetro `-Credencial` permite indicar otra ubicación.
No ejecutar contra la base del proyecto: el destino de ensayo está fijado y validado por el script.
El recorrido opcional de navegador se activa con `-Node <ejecutable>` y
`-ModulosNode <carpeta>` donde esté instalado Playwright y Edge esté disponible.

## Recorrido pendiente para Diego o Josué

Ejecutar la solución, abrir **Catálogos auxiliares** y usar códigos de prueba disponibles en
la copia local de cada compañero. Registrar fecha, versión/commit y resultados reales.

1. Cambiar entre los siete catálogos: título, columnas y datos deben corresponder a la selección.
2. Crear un tipo de teléfono, buscarlo, editar su descripción y comprobar que conserva su código.
3. Repetir un código: debe informar duplicado y conservar el formulario para corregirlo.
4. En Municipios, comprobar nombre y filtro de departamento. Si se crean dos filas con el mismo
   código en departamentos distintos, editar/eliminar una debe conservar la otra.
5. En Tipos de pago, exigir elección Sí/No; guardar No, reabrir y verificar que continúa en No.
6. Intentar eliminar un registro ya utilizado: debe mostrar el motivo y conservarlo. Cancelar
   otra eliminación también debe conservar el registro. Eliminar los registros de prueba libres.
7. Buscar un texto sin coincidencias, pulsar Ver todos, cambiar filtros rápidamente y comprobar
   que una respuesta anterior no reemplaza la selección actual.
8. Usar Tab, Enter y Escape; revisar una pantalla estrecha, desplazamiento de tabla y diálogos.
9. Recargar Clientes/Fiadores/Vehículos/Pagos y comprobar las opciones relevantes del catálogo.

## Coordinación y siguiente bloque

Actualización posterior del 14 de octubre: Diego realizó el recorrido manual guiado en su
navegador. Las capturas de la conversación muestran carga de los siete catálogos; alta,
búsqueda, edición, rechazo de duplicado y eliminación del tipo de teléfono 9001; filtros de
Jalapa/Jutiapa; persistencia de No al reabrir un tipo de pago; eliminación de ese tipo de prueba;
bloqueo de eliminación de Jalapa por dependencias; búsqueda sin resultados y tabla/formulario
completos en una ventana más estrecha. Confirmó por texto Conservar, Ver todos y Enter/Escape.
La captura de Sí no acredita por sí sola que se hubiera cerrado y reabierto tras guardarlo;
ese paso queda con evidencia parcial. No se certifican móvil real, respuestas tardías ni
operaciones CRUD manuales en cada catálogo. Las limitaciones de automatización anteriores se
conservan como evidencia histórica; la revisión visual básica ya cuenta con este recorrido.

- **Dylan:** las definiciones SQL que documenta se conservan. Puede añadir que estos 35 SP
  ahora tienen mantenimiento en la aplicación y enlazar este recorrido.
- **Josué:** añadir la pantalla al manual y registrar los casos anteriores. Las capturas y el
  estado de revisión deben corresponder al commit que realmente pruebe.
- **Diego:** integrar después de revisar; estos cambios locales no aparecen automáticamente
  en las ramas ni en las bases de sus compañeros. No se publicó ni fusionó este avance.

La auditoría inicial se conserva como fotografía del commit anterior. El avance siguiente de
[parámetros/comisión](FASE_6_Parametros_y_Comision.md) se documenta por separado. Continúan
valoraciones y la revisión de las demás operaciones integradas;
el detalle de Mora por rangos sigue siendo una mejora posterior. Este documento no cierra la
fase 6 ni reemplaza su PDF acumulado de cierre.
