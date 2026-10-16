# Consultas de personas y vínculos — 15 de octubre de 2026

Base de trabajo: `ea63fd9b4e2a58b606c582ac26a471f725dd1a8c`, rama `pruebas-diego`.
Cambios locales, todavía sin commit ni publicación de este bloque.

## Alcance

Desde **Consultas y reportes → Consultar personas, contactos, referencias y asignaciones**
se accede a seis consultas generales. No exigen que exista un cliente o fiador visible para
mostrar una persona, un contacto o una referencia. No sustituyen los editores de expedientes.

| Consulta | Entidad / procedimientos api.* | Criterios |
|---|---|---|
| Personas | Persona_Listar / Persona_Buscar | Código, DPI, NIT, nombres, apellidos, nacimiento, género, correo |
| Teléfonos | Telefono_Listar / Telefono_Buscar | Persona, correlativo, tipo por código, número |
| Direcciones | Direccion_Listar / Direccion_Buscar | Persona, correlativo, códigos de tipo/departamento/municipio, detalle |
| Referencias | Referencia_Listar / Referencia_Buscar | Código de referencia/persona, lugar de trabajo |
| Referencias por cliente | DetalleReferencia_Listar / DetalleReferencia_Buscar | Códigos de cliente/referencia/tipo, parentesco o relación |
| Fiadores por crédito | CreditoFiador_Listar / CreditoFiador_Buscar | Número de crédito, código de fiador |

La búsqueda usa los campos de cada entidad, no nombres de tablas relacionadas. La ayuda
explica esta diferencia. SQL conserva sus reglas de intercalación y conversión de fechas;
el criterio es texto parcial de 1–60 caracteres. `%`, `_` y `[` se escapan como texto literal.
Ver todos omite el criterio. Más de 10000 filas genera un error explícito, sin truncamiento.

API: GET `/api/consultas-integradas` y GET `/api/consultas-integradas/{id}`;
solo admite `criterio` opcional, no parámetros repetidos o desconocidos. El catálogo interno
fija los nombres de procedimientos. Respuestas sin caché. La ampliación de eliminación
controlada se describe al final de este documento.
La interfaz usa texto seguro, cancela solicitudes anteriores y descarta respuestas obsoletas.

## Evidencia

- Compilación: cero errores y advertencias; comprobación de sintaxis JavaScript correcta.
- `scripts/Verificar-ConsultasIntegradas.ps1`: **69 comprobaciones correctas**, exclusivamente
  en `MAGISAUTO_ValidacionV2`, API temporal con la cuenta limitada de la aplicación.
- [Resultado](evidencias/fase-6-consultas-integradas.json): seis listados comparados con el
  conteo completo SQL, búsqueda por clave existente, vacíos, filtros inválidos, porcentaje
  literal, rechazo de escritura, entidad no admitida, página y enlace accesibles.
- Hash de contenido de las 26 tablas igual antes y después. No se insertaron datos de prueba.
- Diego confirmó que completó las pruebas manuales de las seis consultas en otro chat,
  incluyendo el recorrido solicitado aquí. Es confirmación del usuario, no ejecución de navegador
  por el agente. Diego confirmó posteriormente también el recorrido de eliminación descrito
  en el [cierre C05/C06](FASE_6_Cierre_C05_C06.md).

## Recorrido manual de consultas confirmado por Diego

1. Reiniciar la aplicación con la versión nueva y abrir Consultas y reportes; seguir el nuevo enlace.
2. En cada una de las seis opciones, comprobar que aparecen columnas y cantidad, incluso si es cero.
3. Si hay filas, copiar un código visible (o número de crédito), buscarlo y verificar que está presente.
4. Buscar `ZZZ_NO_EXISTE_4D774E`: cero resultados. Ver todos: recuperar cantidad original.
5. Buscar vacío: mensaje de validación. Ver todos debe funcionar después.
6. Cambiar rápidamente entre consultas: título y filas deben corresponder siempre a la última opción.
7. Con ventana estrecha, recorrer columnas mediante desplazamiento horizontal; los botones deben alcanzarse.
8. Con Tab, operar selector, búsqueda y botones; enfocar el área de tabla y desplazar con flechas.
9. Recargar: vuelve a Personas y no se modifican registros.

No enviar datos personales ni capturas de toda la tabla si basta describir un error.

## Impacto y pendientes

**Sin cambios SQL ni migración.** Se reutilizan doce procedimientos del paquete existente.
Dylan puede conservar sus definiciones: añadir únicamente la relación de estas consultas con
sus procedimientos si documenta recorridos de la aplicación. Josué debe incorporar el acceso,
campos admitidos, búsqueda sin resultados y navegación estrecha al manual.

Archivos: repositorio y controlador ConsultasIntegradas; registro en Program; página,
estilos y JavaScript `consultas-integradas`; enlace en reportes; ensayo y esta evidencia.

Se cubre el listado/búsqueda general pendiente de C05 para seis entidades y la eliminación
explícita. La matriz de cobertura, excepciones y límites se consolida en el
[cierre del bloque C05/C06](FASE_6_Cierre_C05_C06.md). No se agrega limpieza automática,
borrado en cascada ni edición de contratos.
Las pruebas previas de expedientes no se vuelven a contabilizar como ensayos de este bloque.

## Ampliación: eliminación controlada

DELETE `/api/consultas-integradas/personas/{codigo}` y
DELETE `/api/consultas-integradas/referencias/{codigo}` usan exclusivamente
`api.Persona_Eliminar` y `api.Referencia_Eliminar`. Sin cambios SQL ni migración.
Se devuelve 204 al eliminar, 404 si no existe y 409 si una FK impide el borrado.
Las FK comprueban las dependencias en el propio DELETE; no se confía en una lista
que podría quedar desactualizada entre consulta y confirmación.

- Persona: teléfonos, direcciones, Deudor, Fiador, Vendedor y Referencia bloquean el borrado.
- Referencia: DetalleReferencia bloquea el borrado. Eliminar una ficha libre conserva su Persona.
- No se desvinculan contactos o roles automáticamente. Los procedimientos existentes son
  transaccionales y no tienen borrado en cascada para estas relaciones.
- La interfaz muestra el código y datos identificativos en una confirmación nativa del navegador,
  explica el alcance y bloquea nuevas acciones mientras se procesa la eliminación.
- La prueba ampliada crea registros temporales propios solo en MAGISAUTO_ValidacionV2,
  verifica todos los bloqueos mencionados y compara las 26 tablas antes y después.
  Las identidades pueden avanzar aunque se limpien las filas; no se reinician.

### Comprobación visual de la ampliación confirmada por Diego

Validación automática de esta ampliación: **86 comprobaciones correctas** en total,
incluidas las 69 anteriores (no son 86 adicionales). Compilación sin errores ni advertencias
y sintaxis JavaScript correcta. [Evidencia ampliada](evidencias/fase-6-consultas-integradas-eliminacion.json).
Las 26 tablas conservan su contenido al finalizar. La base de la aplicación no se modificó.

1. En Personas, pulsar Eliminar en una fila y Cancelar: conservar la fila.
2. En una persona con contactos o roles, confirmar: mensaje de bloqueo y fila conservada.
3. En una referencia vinculada a cliente, confirmar: mensaje de bloqueo y fila conservada.
4. Para probar borrado exitoso, usar únicamente fichas desechables conocidas: referencia sin
   clientes vinculados y persona sin contactos ni roles. Confirmar código antes de aceptar.
   Debe actualizarse la tabla; borrar la referencia debe conservar su persona.
5. Comprobar con ventana estrecha y teclado que Eliminar y la confirmación son accesibles.

Diego confirmó cancelación, bloqueos, eliminación de la referencia de prueba y ventana estrecha
con teclado. El éxito de eliminación de Persona sin vínculos está acreditado por el ensayo
automático, sin atribuir una prueba manual adicional. No repetir el recorrido ya confirmado.

Dylan: documentar Persona_Eliminar, Referencia_Eliminar y las FK; no reinstalar la base.
Josué: añadir cancelación, éxito y bloqueo de estas acciones al manual y pruebas.
