# Fase 6 — Catálogo de líneas de vehículos

## Resultado y alcance

Líneas tiene listado, búsqueda, creación, edición y eliminación a través de la API y de los procedimientos existentes. Pantalla en /lineas.html, enlazada desde Marcas. Continúa la fase 6; no cierra todos sus catálogos ni el proyecto.

Se usa MAGISAUTO_Proyecto_V2 y la rama pruebas-diego. No se modificaron esquemas SQL, procedimientos, credenciales ni reglas financieras. MAGISAUTO_Complemento sigue reservada para clase.

## Identidad y reglas

- La clave es (CodigoMarca, CodigoLinea). El código 1 de Toyota es distinto del código 1 de Hyundai.
- Al crear se selecciona una marca existente, se proporciona un código entero positivo y un nombre obligatorio de hasta 128 caracteres.
- Al editar se conserva la marca y el código, y cambia solo el nombre, conforme a api.Linea_Actualizar.
- El nombre no tiene una nueva restricción de unicidad: se respeta el esquema existente.
- Se permite eliminar una línea sin vehículos asociados. Si dbo.Garantia referencia esa combinación de marca/línea, SQL impide el borrado y la API explica el motivo.
- Los cambios de nombre simultáneos conservan el comportamiento anterior: prevalece el último guardado; no se añadió control de versiones.

## Archivos y cambios

| Archivo | Responsabilidad |
| --- | --- |
| src/MAGISAUTO.API/Controllers/LineasController.cs | GET, POST, PUT y DELETE; validación de entrada, filtro de marca y nombre de marca en el listado. |
| src/MAGISAUTO.API/Datos/ILineaRepositorio.cs | Contrato de las cinco operaciones. |
| src/MAGISAUTO.API/Datos/LineaRepositorio.cs | Ejecuta api.Linea_Listar/Buscar/Insertar/Actualizar/Eliminar con parámetros tipados. |
| src/MAGISAUTO.API/Modelos/LineaSolicitud.cs | Validación de códigos y nombre en altas/ediciones. |
| src/MAGISAUTO.API/Modelos/LineaRespuesta.cs | Respuesta de línea y listado con nombre de marca. |
| src/MAGISAUTO.API/Datos/OperacionCatalogoException.cs | Error controlado compartido por Marcas y Líneas; sustituye el nombre específico OperacionMarcaException. |
| src/MAGISAUTO.API/Infraestructura/ErroresApiHandler.cs | Reconoce la excepción compartida; conserva respuestas de Marcas. |
| src/MAGISAUTO.API/Datos/MarcaRepositorio.cs | Solo cambia el nombre del tipo de excepción utilizado. |
| src/MAGISAUTO.API/Program.cs | Registra ILineaRepositorio en la aplicación. |
| src/MAGISAUTO.API/wwwroot/lineas.html y lineas.js | Pantalla con filtros, formularios, confirmación y mensajes. |
| src/MAGISAUTO.API/wwwroot/index.html y estilos.css | Navegación entre catálogos y estilos para selector/tabla de líneas. |
| scripts/Verificar-Lineas.ps1 | Ensayo HTTP y de relaciones, con limpieza de registros propios. |

El catálogo de marcas se obtiene mediante api.Marca_Listar para mostrar nombres y seleccionar la marca. La API combina las respuestas y filtra por codigoMarca en memoria. No hace consultas SQL directas. Este enfoque conserva el SQL entregado; se debe revisar paginación si el catálogo crece considerablemente.

## Rutas

| Método | Ruta | Uso |
| --- | --- | --- |
| GET | /api/catalogos/lineas | Listar todas. |
| GET | /api/catalogos/lineas?criterio=Corolla | Buscar por nombre de línea, código de línea o código de marca, según el procedimiento. |
| GET | /api/catalogos/lineas?codigoMarca=1 | Filtrar por marca exacta; se puede combinar con criterio. |
| POST | /api/catalogos/lineas | Crear con codigoMarca, codigoLinea y descripcion. |
| PUT | /api/catalogos/lineas/{codigoMarca}/{codigoLinea} | Editar descripcion de la clave exacta. |
| DELETE | /api/catalogos/lineas/{codigoMarca}/{codigoLinea} | Eliminar la clave exacta si no tiene dependencias. |

La búsqueda conserva LIKE, incluidos sus comodines. El nombre de marca se selecciona con el filtro Marca, no con el campo de texto. Entrada inválida devuelve 400; línea inexistente 404; clave duplicada, marca inexistente o vehículo que impide borrar 409; conexión/permisos fallidos 503. No se exponen los mensajes internos de SQL.

## Pantalla

Selector de marca y búsqueda por código/nombre de línea; Ver todas limpia ambos filtros. Al guardar se muestra la marca utilizada. Los diálogos muestran la identidad completa, piden confirmación al eliminar y conservan datos tras errores. La marca y el código quedan bloqueados al editar. Sin marcas disponibles no se habilita un alta; ante un fallo de carga se retiran filas antiguas y se permite reintentar con Ver todas. Los nombres se muestran como texto, sin interpretar HTML.

## Validación realizada

- Compilación sin errores ni advertencias y sintaxis JavaScript válida.
- 42 comprobaciones nuevas: altas en dos marcas con el mismo código de línea, duplicado dentro de una marca, marca inexistente, filtros y combinaciones, validaciones, actualización aislada, Unicode, protección de vehículo asociado, eliminación aislada, 404, búsqueda sin coincidencias, OpenAPI y recuperación del catálogo original.
- 28 comprobaciones de regresión de Marcas aprobadas.
- 31 comprobaciones de regresión de conexión, errores y permisos aprobadas.
- Total: 101 comprobaciones automáticas aprobadas en esta entrega.

El ensayo creó dos marcas, dos líneas y un vehículo ficticio para comprobar la relación. Se retiraron sus propios registros y se compararon los catálogos originales antes/después. La secuencia IDENTITY de Garantia puede haber avanzado por el vehículo de prueba; no se restableció ni reutilizó ese identificador. La preparación del vehículo usó procedimientos y la misma cuenta limitada de la API. No se crearon créditos ni pagos.

Evidencias: evidencias/fase-6-lineas.json, fase-6-lineas-regresion-marcas.json y fase-6-lineas-regresion-api.json.

La herramienta de navegador se inicializó, pero la URL temporal no respondió desde ese navegador. No se completó la verificación visual automática. Posteriormente, Diego mostró la pantalla con las cinco líneas originales y confirmó que funcionan el filtro, la creación, la edición y la eliminación. Queda registrado el recorrido manual de Líneas junto al de Marcas. No se afirma validación visual móvil ni que se hayan revisado manualmente todos los casos de error.

## Probar con Diego

1. Detener la ejecución anterior en Visual Studio y arrancar MAGISAUTO.API con perfil http (Ctrl+F5).
2. Abrir http://localhost:5164/lineas.html o elegir Líneas de vehículos desde Marcas.
3. Seleccionar Toyota en Marca y observar únicamente sus líneas. Buscar por un nombre existente; Ver todas debe restablecer el catálogo completo.
4. Agregar una línea de prueba con marca Toyota, código libre 900001 (si no está ocupado) y nombre Prueba Diego.
5. Editar su nombre. La marca y el código deben conservarse. Recargar para comprobar persistencia.
6. Intentar repetir la combinación Toyota/900001: debe explicar el duplicado sin reemplazar la línea.
7. Probar Conservar línea en el diálogo de borrado. Después eliminar únicamente la línea de prueba y confirmar que desaparece al recargar.

Para repetir el ensayo automático: compilar y ejecutar `pwsh -File scripts/Verificar-Lineas.ps1` desde la raíz. SalidaCompilacion permite otra carpeta de compilación.

## Informes y siguientes pasos

Al cerrar cada fase se entregará un PDF con resumen acumulado, cambios, ejemplos, pruebas y pendientes, conforme a INFORMES_POR_FASE.md. Este módulo sigue siendo un avance de la fase 6. Los demás catálogos y módulos del enunciado continúan pendientes. Las publicaciones se realizan en pruebas-diego cuando Diego las solicita.
