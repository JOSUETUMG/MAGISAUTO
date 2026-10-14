# Fase 6 — Registro de vendedores

Fecha: 11 de octubre de 2026. Rama: `pruebas-diego`. Avance de la fase 6; no es el cierre de la fase.

## Objetivo

El inciso D del enunciado requiere identificar al vendedor por código de empleado, DPI, nombre y agencia o región, y relacionarlo con los créditos. Este módulo registra y administra vendedores usando las tablas Persona, Vendedor y Agencia existentes. No implementa todavía las pantallas de créditos ni de comisiones.

## Qué puede hacer el usuario

- Listar vendedores con código interno, código de empleado, nombre completo, DPI y agencia/región.
- Buscar por código interno, código de empleado, DPI, nombre completo, nombre de agencia o región, y combinarlo con una agencia seleccionada.
- Crear un vendedor; SQL genera el código interno. La persona y el vendedor se guardan juntos.
- Editar código de empleado, nombres, apellidos y agencia. El código interno, el vínculo personal y el DPI se conservan.
- Eliminar un vendedor sin créditos asociados, previa confirmación. Cancelar conserva el registro.

## Datos y validaciones

| Dato | Regla y motivo |
| --- | --- |
| Código interno | Correlativo automático `CodigoVendedor`. No se captura ni se modifica. |
| Código de empleado | Obligatorio, hasta 30 caracteres; único según la restricción SQL existente. |
| DPI | Exactamente 13 dígitos; identifica a la persona. Validación de formato, sin consulta a registros oficiales. |
| Primer nombre y primer apellido | Obligatorios, hasta 64 caracteres cada uno. |
| Segundo nombre y segundo apellido | Opcionales, hasta 64 caracteres. Espacios se normalizan a ausencia de dato. |
| Agencia | Código positivo de una agencia existente. El selector muestra su nombre y región. |

Los textos editables se recortan; un campo obligatorio con solo espacios se rechaza. El catálogo de agencias se vuelve a cargar al abrir el formulario. Si no hay agencias, el formulario indica que primero se registre una y no habilita Guardar. No se inventan campos de comisión en esta pantalla: la comisión pertenece a las condiciones de cada crédito y sus pagos.

## Persona compartida y transacciones

Persona conserva los datos de identidad; Vendedor conserva el rol laboral y su agencia. Una misma persona puede tener otros roles, como cliente o fiador.

Al crear:

1. Se comprueba si el DPI ya pertenece a una persona.
2. Si no existe, se crea la persona y se asigna el rol de vendedor.
3. Si existe y aún no es vendedor, se reutiliza únicamente cuando los nombres y apellidos coinciden con su ficha, ignorando mayúsculas/minúsculas. Un conflicto devuelve un mensaje y no reemplaza la identidad existente.
4. Si ya es vendedor, se rechaza la duplicación.

Una transacción exterior con aislamiento Serializable agrupa las llamadas a los procedimientos. Si falla el código de empleado o la agencia, se revierten también los cambios personales. La edición lee y conserva NIT, correo, nacimiento y género, aunque no se editen en este formulario. La serialización evita sobrescribir esos campos a partir de una lectura concurrente dentro de la operación; no implementa control de versiones del formulario para detectar ediciones antiguas de nombres.

**Editar los nombres actualiza la ficha personal compartida**, lo cual se explica en el formulario. **Eliminar el vendedor retira el rol, no la Persona.** Así se conservan sus datos y otros roles; una persona sin roles puede permanecer para reutilizarse por DPI. No se añade un borrado automático de personas.

Si un crédito referencia al vendedor, SQL impide la eliminación. Cambiar su agencia actual no reescribe la agencia guardada en los contratos anteriores; el esquema mantiene ese dato por crédito.

## Recorrido y archivos

`vendedores.html` → `vendedores.js` → `VendedoresController` → `IVendedorRepositorio` / `VendedorRepositorio` → procedimientos `api.*` → SQL Server.

| Archivo | Qué hace |
| --- | --- |
| `src/MAGISAUTO.API/Modelos/VendedorSolicitud.cs` | Contrato de captura y validaciones de campos. |
| `src/MAGISAUTO.API/Modelos/VendedorRespuesta.cs` | Datos del listado con nombre completo y agencia/región. |
| `src/MAGISAUTO.API/Datos/IVendedorRepositorio.cs` | Contrato para consultar, guardar y eliminar. |
| `src/MAGISAUTO.API/Datos/VendedorRepositorio.cs` | Combina lecturas, preserva datos personales y ejecuta las escrituras dentro de la transacción. |
| `src/MAGISAUTO.API/Controllers/VendedoresController.cs` | Rutas y validación de filtros y códigos. |
| `src/MAGISAUTO.API/Program.cs` | Registra el repositorio. |
| `src/MAGISAUTO.API/wwwroot/vendedores.html` | Listado, filtros, formulario y confirmación de eliminación. |
| `src/MAGISAUTO.API/wwwroot/vendedores.js` | Envía solicitudes, gestiona diálogos y muestra resultados como texto seguro. |
| `src/MAGISAUTO.API/wwwroot/index.html`, `lineas.html`, `agencias.html` | Incluyen el acceso a Vendedores en el menú. |
| `scripts/Verificar-Vendedores.ps1` | Pruebas de integración con datos temporales propios y limpieza. |

Se reutilizan `api.Persona_Listar`, `Persona_Insertar`, `Persona_Actualizar`, `Vendedor_Listar`, `Vendedor_Insertar`, `Vendedor_Actualizar`, `Vendedor_Eliminar` y `Agencia_Listar`. No se añade SQL directo de negocio, procedimientos ni migraciones; tampoco se cambia el paquete de instalación.

El listado combina datos de procedimientos y aplica búsqueda literal en la API, sin distinguir mayúsculas. `%` y `_` no son comodines en este módulo. A diferencia de los catálogos anteriores, no se usa `Vendedor_Buscar`, que no incluye nombres personales. La implementación lee catálogos completos y no tiene paginación: es una limitación conocida para el volumen académico, no una solución optimizada para grandes volúmenes. Solo devuelve los campos del vendedor; no expone NIT, correo u otros datos personales leídos para conservarlos al editar.

## API

| Método y ruta | Resultado |
| --- | --- |
| `GET /api/vendedores` | 200 con listado; admite `criterio` y `codigoAgencia`. |
| `POST /api/vendedores` | 201 con `codigoVendedor` generado. |
| `PUT /api/vendedores/{codigo}` | 204 al actualizar. |
| `DELETE /api/vendedores/{codigo}` | 204 al eliminar el rol. |

Ejemplo de captura ficticia:

```json
{
  "codigoEmpleado": "PRUEBA-DIEGO-01",
  "dpi": "9990000000001",
  "primerNombre": "Prueba",
  "segundoNombre": null,
  "primerApellido": "Diego",
  "segundoApellido": null,
  "codigoAgencia": 1
}
```

La agencia del ejemplo debe existir. Ese DPI es un dato de prueba de formato; no se afirma que corresponda a una identidad real.

Errores: 400 por datos/filtros inválidos; 404 por vendedor inexistente; 409 por duplicados, cambio de identidad, agencia inexistente o créditos que impiden borrar; 503 para fallos SQL no clasificados mediante el manejador general. Los mensajes de negocio no exponen restricciones internas ni credenciales.

## Validación ejecutada y límites

- Compilación: cero errores y cero advertencias.
- Sintaxis JavaScript comprobada con Node.
- 59 comprobaciones de Vendedores correctas: listado enriquecido, creación atómica, recorte, campos, duplicados, reversión de personas al fallar, edición, conservación de metadatos del cliente, búsqueda, filtros, protección por crédito, eliminación del rol sin perder al cliente, reutilización de persona existente, contrato API y conservación de datos iniciales.
- 34 comprobaciones de Agencias correctas como regresión.

Evidencias: [Vendedores](evidencias/fase-6-vendedores.json) y [regresión de Agencias](evidencias/fase-6-vendedores-regresion-agencias.json).

El ensayo crea agencias, vendedor/persona, rol de cliente, marca/línea, vehículo y un crédito **borrador**, todos propios del ensayo. No aprueba créditos ni genera cuotas o pagos. Los datos temporales se retiran y se compara el listado original de personas y vendedores. Los correlativos pueden avanzar; no se reajustan.

La entrega de HTML y navegación se comprobó por HTTP. La revisión manual posterior se detalla abajo; la revisión móvil y un recorrido visual automatizado siguen pendientes. Las comprobaciones de los módulos anteriores no sustituyen esta validación. No se generó un nuevo informe PDF de cierre porque la fase continúa abierta.

### Revisión manual confirmada por Diego

El 11 de octubre de 2026, Diego confirmó que los datos se conservan al recargar y que funcionan las búsquedas por nombre y agencia. La primera captura muestra el vendedor de prueba con código interno 7, código de empleado PRUEBA-DIEGO-02 y agencia asociada. La captura posterior muestra «Vendedor eliminado correctamente» y cero vendedores en el listado filtrado por agencia.

Se registran como verificados manualmente la persistencia confirmada, la búsqueda por nombre y agencia y la eliminación mostrada en pantalla. La primera captura acredita el listado del registro, pero no prueba por sí sola todo el recorrido de creación y edición. No se atribuyen a esta confirmación la cancelación de eliminación, los duplicados, la búsqueda por DPI/código, Ver todas ni los errores de formulario. La conservación de Persona tras retirar el vendedor está cubierta por las pruebas HTTP/SQL; no es visible en estas capturas.

## Prueba manual propuesta

1. Reiniciar la aplicación desde Visual Studio y abrir `http://localhost:5164/vendedores.html`.
2. Si no hay vendedores, observar el estado vacío; abrir **Agregar vendedor**.
3. Usar código `PRUEBA-DIEGO-01`, DPI ficticio libre de 13 dígitos, primer nombre `Prueba`, primer apellido `Diego`, y seleccionar una agencia existente. Los segundos nombres/apellidos pueden quedar vacíos.
4. Guardar: debe aparecer con código interno automático, nombre completo y agencia.
5. Editar nombres, código de empleado o agencia; el DPI y código interno permanecen. Recargar y comprobar persistencia.
6. Buscar por DPI, código o nombre y probar el filtro de agencia y **Ver todas**.
7. Intentar registrar el mismo vendedor otra vez: debe informar el conflicto.
8. Abrir **Eliminar** y pulsar **Conservar vendedor**; después eliminar únicamente el registro de prueba y comprobar que desaparece. Su Persona se conserva, según la regla del módulo.

La protección por créditos ya se probó automáticamente; no es necesario crear un crédito manual para esta revisión.

## Estado de entrega

Vendedores y Agencias permanecen locales en `pruebas-diego`; la documentación inicial publicada sigue siendo el commit `32d4bd5`. No se realiza un envío nuevo a GitHub en este avance.

Después de validar este módulo corresponde continuar con clientes y sus contactos/referencias. El cierre de fase y el informe PDF se rigen por [Informes por fase](INFORMES_POR_FASE.md).
