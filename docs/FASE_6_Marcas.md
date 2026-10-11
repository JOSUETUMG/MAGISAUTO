# Fase 6 — Módulo de marcas

## Alcance y relación con el PDF

Se implementaron las cinco operaciones solicitadas para la entidad Marca: insertar, actualizar, borrar, listar y buscar. La pantalla usa la API del mismo sitio. La API ejecuta exclusivamente api.Marca_Insertar, api.Marca_Actualizar, api.Marca_Eliminar, api.Marca_Listar y api.Marca_Buscar, con parámetros tipados. No se modificaron SQL, catálogos originales, reglas financieras ni credenciales.

Esta fase cubre solamente Marca. No completa el CRUD de las demás entidades ni las interfaces de clientes, garantías, créditos, pagos o reportes. Siguen pendientes las aclaraciones académicas sobre borrado financiero, resumen derivado y total neto recaudable.

## Comportamiento

- Pantalla inicial en /, con lista, búsqueda, contador, estados de carga/vacío/error y formulario en diálogo.
- Código manual entero positivo; no se cambia al editar. Nombre obligatorio de hasta 128 caracteres; se eliminan espacios exteriores.
- No se inventa unicidad del nombre: el esquema existente solo garantiza unicidad del código.
- POST crea (201), PUT actualiza (200), DELETE elimina (204).
- Validación de entrada (400), registro inexistente (404), código repetido o relaciones que impiden eliminar (409). Conexión/permisos fallidos continúan devolviendo 503.
- Confirmación antes de borrar; cancelación disponible; botones de guardado/borrado bloqueados mientras se envía la operación. Escape cierra diálogos salvo que haya una escritura en curso.
- Textos del catálogo se insertan como texto, sin interpretar HTML. Etiquetas, foco visible, avisos accesibles y diseño adaptable a ancho pequeño.
- Búsqueda conserva los comodines LIKE del procedimiento original. Sin criterio, el formulario muestra todas las marcas.

El inicio de sesión del personal sigue pendiente/opcional. La aplicación sigue destinada a pruebas locales. Cambios de dos usuarios sobre el mismo nombre se resuelven con la última actualización; esta fase no añade control de versiones de registros.

## Evidencia y límites

- Compilación correcta, sin errores ni advertencias.
- 28 comprobaciones HTTP y SQL de CRUD, validaciones, datos persistidos, Unicode, relaciones, estado original restaurado y recursos estáticos.
- 31 comprobaciones de regresión de conexión, consultas, errores y permisos.
- Ensayos con cuenta limitada de la API. La línea temporal del caso de relación se preparó mediante procedimiento almacenado; no se modificaron tablas directamente.
- Solo se borraron la marca y la línea creadas por el ensayo. Las cinco marcas originales quedaron iguales.
- Evidencias: evidencias/fase-6-marcas.json y evidencias/fase-6-regresion-api.json.

La prueba visual automatizada quedó pendiente: la herramienta integrada no pudo inicializarse y Edge de automatización se cerró al iniciar. El script de recorrido de navegador está preparado, pero no se afirma que se haya ejecutado correctamente ni que el diseño móvil se haya verificado.

Revisión manual posterior con Diego: sus capturas muestran el listado inicial de cinco marcas, la creación de 900001 / Prueba Diego, su edición conservando el código, la eliminación con retorno a cinco marcas y la búsqueda de Toyota con un solo resultado. Quedan documentadas las cinco operaciones visibles. Las capturas no prueban por sí solas la cancelación de borrado, todos los casos de error o el diseño móvil.

## Prueba manual en Visual Studio

1. Detener la ejecución anterior. Mantener la rama pruebas-diego y seleccionar MAGISAUTO.API.
2. Ejecutar con el perfil http y Ctrl+F5. Abrir http://localhost:5164/ (sin /api/salud).
3. Confirmar las cinco marcas iniciales. Buscar Toyota y después pulsar Ver todas.
4. Pulsar Agregar marca. Elegir un código libre, por ejemplo 900001 si no existe, y el nombre Prueba Diego.
5. Guardar. Debe aparecer el aviso de éxito y la nueva marca en la tabla.
6. Intentar agregar el mismo código: debe aparecer un mensaje de duplicado sin reemplazar la marca. Cancelar ese formulario.
7. Editar la marca de prueba a Prueba Diego editada. El código permanece fijo; guardar debe actualizar el listado.
8. Pulsar Eliminar y luego Conservar marca: el registro debe seguir en la tabla.
9. Eliminar de nuevo y confirmar. Solo debe desaparecer la marca de prueba.
10. Buscar un nombre inexistente: debe mostrarse el estado vacío. Comprobar también el formulario con teclado y una ventana estrecha.

No usar marcas originales para ensayar eliminaciones. El caso de relaciones bloqueadas ya se verificó con una marca y una línea temporales en el ensayo automático.

## Ejecutar comprobaciones

Desde la raíz del repositorio, con PowerShell 7 y la configuración local preparada:

    dotnet build MAGISAUTO.sln
    pwsh -File scripts/Verificar-Marcas.ps1
    pwsh -File scripts/Verificar-Api.ps1

El último comando ejecuta 27 comprobaciones sin el parámetro opcional de credencial de lectura, o 31 si se proporciona. El ensayo de marcas inicia y detiene su propio servidor temporal. No confirma ni publica cambios en Git.
