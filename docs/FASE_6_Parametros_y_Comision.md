# Fase 6 — Parámetros y comisión por crédito

Avance del 15 de octubre de 2026, rama `pruebas-diego`. Continúa la fase 6 después de
Catálogos auxiliares. Este cambio se prepara localmente; no es una publicación ni un cierre de fase.

## Propósito

El enunciado exige una tasa de interés configurable y una comisión específica del vendedor
por crédito, calculada sobre pagos efectivos. La tabla y los procedimientos ya lo permitían;
faltaba administrarlo desde la aplicación. El manejo de cuenta permanece en **Q25 mensuales**,
conforme al enunciado y las restricciones SQL existentes.

La pantalla `/parametros.html` se abre desde el enlace **Administrar parámetros del crédito**
en Catálogos auxiliares. Créditos también incluye un enlace de consulta. La reorganización del
menú en Administración sigue pendiente; no se cambió toda la navegación durante este bloque.

## Configuraciones y conservación del historial

1. **Nueva configuración / Copiar:** crea una versión inactiva, con código asignado por SQL.
2. **Editar:** solo para versiones inactivas que ningún crédito utiliza, incluidos borradores
   y contratos anulados. Activas o utilizadas muestran **Ver** y **Copiar**.
3. **Activar:** requiere confirmación. Desactiva la anterior y activa la elegida dentro de una
   sola transacción. Si falla, se revierte el cambio completo. La operación repetida es idempotente.
4. **Eliminar:** solo para versiones inactivas y sin créditos relacionados. No se deja la
   aplicación sin configuración eliminando la activa.

Activar otra versión no reescribe créditos ni cuotas. Los borradores sin editar conservan sus
condiciones. Si se vuelve a guardar un borrador, el SP existente toma la configuración activa
y el precio actual del vehículo, y exige presentar de nuevo la solicitud si ya estaba presentada.
La pantalla muestra tanto las condiciones guardadas como las que se aplicarán al guardar.

Congelar las versiones utilizadas también protege la depreciación inicial: el SP de aprobación
la obtiene de la versión vinculada al borrador. Una versión usada no puede cambiar sus valores
desde esta API, aunque haya dejado de ser la activa.

Estas protecciones adicionales se implementan en la API mediante SP existentes y transacciones
serializables. Los SP genéricos de parámetros conservan su comportamiento anterior; una persona
con permiso para ejecutarlos directamente en SQL podría omitir las protecciones de la interfaz/API.
No se afirma que exista una nueva restricción SQL ni se modifican permisos en este bloque.

## Valores y unidades

| Campo visible | Rango aceptado por la aplicación | Almacenamiento SQL |
| --- | --- | --- |
| Nombre | Obligatorio, hasta 100 caracteres, recorta espacios exteriores. | `Nombre`, nvarchar(100). |
| Tasa de interés anual (%) | 0 a 100. | `TasaAnual`, fracción decimal(9,6). |
| Seguro de automóvil mensual (%) | Mayor que 0, hasta 100. | `TasaSeguroAuto`, fracción sobre monto inicial financiado. |
| Seguro de vida mensual (%) | Mayor que 0, hasta 100. | `TasaSeguroVida`, fracción sobre monto inicial financiado. |
| Enganche mínimo (%) | Desde 20, menor que 100. | `EngancheMinimo`, fracción. |
| Comisión predeterminada (%) | 0 a 100. | `ComisionPredeterminada`, fracción. |
| Depreciación inicial (%) | 15 a 20. | `DepreciacionInicial`, fracción. |
| Manejo mensual (Q) | Solo 25, campo de lectura. | `ManejoMensual`, decimal(18,2). |

Los porcentajes visibles admiten hasta cuatro decimales. **12.5 significa 12.5%**, convertido
exactamente a **0.125000** en SQL; no hay redondeo silencioso de una precisión superior.
Las respuestas devuelven decimales como cadenas. Estos rangos reproducen las restricciones del
modelo; no son recomendaciones comerciales de tasas o comisiones.

La búsqueda reutiliza `ParametroCredito_Buscar`, incluidos sus comodines LIKE y sus valores SQL:
para buscar 12.5% por valor se introduce `0.125`. La ayuda de la pantalla indica esa diferencia.

## Comisión del crédito

El formulario de Créditos incorpora **Comisión del vendedor (%)**, obligatoria en la interfaz.
Al crear propone la comisión de la configuración activa; al editar muestra la pactada en el
crédito. Admite 0–100 con hasta cuatro decimales. Los contratos aprobados conservan el campo
bloqueado junto con el resto de sus condiciones.

La API recibe `comisionPorcentaje` (porcentaje visible) y envía `@PorcentajeComision` al SP como
decimal(9,6), dividido entre 100. Por compatibilidad:

- Al crear, omitirlo o enviarlo null utiliza la comisión predeterminada activa.
- Al editar un borrador, omitirlo o enviarlo null conserva la comisión que ya tenía.
- Un cero explícito se conserva como cero; no se sustituye por el predeterminado.

El formulario también envía `codigoParametro`, la versión activa que vio al abrirse. Si otra
persona activa una versión distinta antes de guardar, el SP rechaza la operación y revierte
también los vínculos de fiadores. Hay que cerrar y reabrir para revisar las nuevas condiciones.
Los clientes antiguos de la API pueden omitir `codigoParametro` y mantienen el comportamiento
previo de tomar la configuración activa al guardar.

No cambia el cálculo de comisión de Pagos. Ejemplo de prueba: comisión pactada 3.25%, pago
efectivo Q1000 → Q32.50, incluso si el predeterminado posterior pasa a 7.5%. La anulación de
pagos mantiene las reglas existentes de reversión; este módulo no desembolsa dinero al vendedor.

## Contrato y archivos

Base nueva: `/api/parametros-credito`.

| Operación HTTP | SP existentes utilizados |
| --- | --- |
| GET, opcional `?criterio=...` | `ParametroCredito_Listar`, `ParametroCredito_Buscar` y `Credito_Listar` para identificar uso. |
| POST, cuerpo con nombre y valores | `ParametroCredito_Insertar`, siempre inactiva; devuelve 201 y `codigoParametro`. |
| PUT `/{id}` | Listados de verificación y `ParametroCredito_Actualizar`; 204. |
| POST `/{id}/activar` | Listado y `ParametroCredito_Actualizar` para ambas versiones en una transacción; 204. |
| DELETE `/{id}` | Listados de verificación y `ParametroCredito_Eliminar`; 204. |

Validaciones: 400. Configuración inexistente: 404. Versión protegida, dependencia o conflicto
de concurrencia: 409. Fallos de conexión: 503 mediante el manejador general. Filtros desconocidos,
duplicados o vacíos se rechazan. El cuerpo de configuración no acepta campos desconocidos,
incluidos `activo` y `codigoParametro`: el estado se cambia con su acción específica.

Archivos nuevos: `Modelos/ParametroCreditoSolicitud.cs`, `Datos/ParametroCreditoRepositorio.cs`,
`Controllers/ParametrosCreditoController.cs`, `wwwroot/parametros.html`, `parametros.js` y
`parametros.css`, dentro de `src/MAGISAUTO.API`. Registro del repositorio en `Program.cs`.

Archivos modificados de Créditos: `Modelos/CreditoSolicitud.cs`, `Datos/CreditoRepositorio.cs`,
`wwwroot/creditos.html` y `creditos.js`. Enlace de acceso en `wwwroot/auxiliares.html`.

**No se modifica ningún archivo SQL ni se requiere una migración nueva.** Las escrituras de la
aplicación usan exclusivamente los SP ya instalados, con parámetros tipados. No se modificó
`appsettings.Local.json` ni la base del proyecto durante las pruebas.

## Validación

Compilación correcta, sin errores ni advertencias. **134 comprobaciones nuevas y 57 de
regresión de Créditos aprobadas (191 en total)** el 15 de octubre. Se verificó además la sintaxis
de ambos JavaScript y que sus referencias a controles correspondan a IDs HTML existentes.
La [identificación del árbol local probado](evidencias/fase-6-parametros-version.json) guarda
el commit base y las huellas de los archivos; no equivale a un commit nuevo ni publicado.

Resultados de esta ejecución: [integración de parámetros y comisión](evidencias/fase-6-parametros.json)
y [regresión de créditos](evidencias/fase-6-parametros-regresion-creditos.json). Ver el estado y
la lista de comprobaciones en cada archivo; no confundirlos con evidencias históricas.

La integración se ejecuta únicamente en `MAGISAUTO_ValidacionV2`, con credencial administrativa
privada para preparar/limpiar datos y la cuenta limitada de la API para las solicitudes HTTP.
Se verifica el rechazo de SELECT directo de tablas, se crean fixtures con prefijo aleatorio y se
comparan las 26 tablas antes y después de retirarlos y restaurar la versión activa inicial.
Los contadores IDENTITY pueden avanzar; no se reinician ni se prometen códigos consecutivos.

Se comprueban porcentajes exactos, límites, versiones usadas, activaciones concurrentes,
conservación de borradores/contratos/cuotas/depreciación, rechazo de la versión obsoleta y
comisión sobre un pago efectivo. El ensayo de regresión vuelve a probar presentación,
aprobación, fiadores, cuotas, bloqueo de edición de contratos y anulaciones.

Para repetir desde la raíz del repositorio:

```powershell
dotnet build src/MAGISAUTO.API/MAGISAUTO.API.csproj --no-restore -o src/MAGISAUTO.API/bin/Parametros -p:UseAppHost=false
pwsh -NoProfile -File scripts/Verificar-ParametrosCredito.ps1
pwsh -NoProfile -File scripts/Verificar-Creditos.ps1 -SalidaCompilacion bin\Parametros
```

Los scripts requieren la base aislada y las credenciales locales existentes. Admiten la opción
explícita `-ConexionLocalSinCifrado` solo para loopback de ensayo; no se guarda esa opción en la
configuración del proyecto. El ensayo anterior de Créditos verifica su migración histórica de
presentación de forma repetible en la base aislada; no es una migración nueva de este bloque.

La sintaxis JavaScript y las referencias de controles HTML se verifican por separado.
**El recorrido visual de estas pantallas nuevas queda pendiente de revisión manual**;
las pruebas HTTP/SQL no acreditan diseño en móvil, teclado ni interacción de navegador.

## Guía de prueba manual y coordinación

1. Reiniciar la aplicación. En Catálogos auxiliares, abrir Administrar parámetros del crédito.
2. Abrir Ver en la configuración activa y comprobar las unidades y Q25 de manejo.
3. Usar Copiar, nombrar la nueva versión `PRUEBA PARAMETROS`, guardar y comprobar que nace inactiva.
4. Editar esa copia sin usar, cambiar un valor válido y reabrir para verificarlo; probar también
   un porcentaje fuera de rango. Cancelar una activación debe conservar la activa anterior.
5. En la copia local de pruebas, activar la nueva configuración y comprobar que solo una queda
   activa. Crear un borrador y verificar que propone los valores nuevos.
6. Pactar una comisión distinta en ese borrador, guardar y reabrir. Un crédito aprobado debe
   seguir mostrando su comisión guardada y no permitir cambiarla.
7. Restaurar la configuración inicial con Activar. Eliminar únicamente borradores y versiones
   de prueba que estén libres; una versión utilizada debe quedar protegida.
8. Comprobar búsqueda, Ver todos, teclado y ventana estrecha. Registrar qué se verificó realmente.

**Dylan:** los SP documentados mantienen sus definiciones. Añadir la conversión porcentaje/fracción,
el uso de los parámetros opcionales de Crédito y las protecciones/transacciones de la API.
**Josué:** nuevas capturas y pruebas para Parámetros, y actualización del formulario de Créditos.
La versión revisada debe quedar identificada en el manual. No se modificaron sus ramas.

Siguiente trabajo: valoraciones y revisión restante de cobertura; agrupar después la navegación
administrativa y preparar el cierre de fase con los aportes del equipo. Mora por rangos sigue
como mejora posterior. La fase 6 permanece abierta.
