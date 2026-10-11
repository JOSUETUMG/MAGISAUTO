# Fase 3 — Modelo relacional y normalización de MAGIS-AUTO

Fecha: 8 de octubre de 2026. Rama de trabajo: pruebas-diego.
Estado: ajustes aprobados por Diego y llevados a v2. La Fase 4 documenta el resultado y la corrección de Monto conforme al inciso E.

## 1. Alcance y versiones

La Fase 2 fue aceptada por Diego al solicitar continuar. Esta fase revisa sus 25 tablas y propone un modelo de 26 tablas: las mismas entidades, con una nueva tabla ResumenCredito y una separación más clara entre datos guardados y resultados calculados.

Este documento NO describe una migración ya ejecutada. El SQL compartido con el compañero sigue siendo la versión anterior de 25 tablas. La base instalada y el ZIP no se modificaron. Antes de entregar una versión nueva habrá que adaptar y probar el instalador, los procedimientos, índices y reportes; el instalador anterior es de instalación nueva, no una migración sobre una base existente.

## 2. Qué significa normalizar aquí

- **1FN:** cada celda representa un dato y no una lista. Una persona con tres teléfonos tiene tres filas en Telefono. Referencias y fiadores se relacionan mediante filas, no columnas Referencia1/2/3.
- **2FN:** un atributo que no es llave depende de la llave completa. En DetalleCuota, la cuota 1 del crédito A es distinta de la cuota 1 del crédito B. Capital e interés corresponden a la pareja (NumeroCredito, Cuota); el manejo mensual fijo pertenece al contrato.
- **3FN:** no duplicar en una tabla datos determinados por otro atributo que no es llave. El nombre de una agencia se obtiene de Agencia; no se copia en cada vendedor. El porcentaje de comisión pactado se obtiene de Credito; no se copia en cada pago.

Formalmente, una dependencia X → Y significa que a un mismo X siempre le corresponde el mismo Y bajo las reglas del modelo. Para 3FN, en cada dependencia funcional no trivial X → A, X debe ser superllave o A pertenecer a alguna llave candidata. La revisión siguiente identifica las dependencias de negocio; no pretende demostrar que cualquier futura regla adicional mantenga la normalización.

Referencia introductoria: [Microsoft: conceptos de normalización](https://learn.microsoft.com/en-us/office/troubleshoot/access/database-normalization-description). La aplicación a MAGIS-AUTO y las decisiones siguientes son análisis del proyecto.

## 3. Ajustes propuestos respecto del SQL anterior

| Elemento | Antes | Propuesta y motivo |
| --- | --- | --- |
| DetalleCuota | Repite manejo y ambos seguros en cada cuota | Guardar fecha, capital e interés de cada cuota; obtener los cargos fijos de las condiciones inmutables del contrato. Evita dependencias de solo NumeroCredito en una llave compuesta. |
| DetallePago | Repite porcentaje de comisión del crédito | Obtenerlo del contrato aprobado; conservar el reparto realmente aplicado al abono. |
| Total del pago | Monto guardado más cinco componentes guardados | Guardar los cinco componentes y obtener Monto sumándolos. El procedimiento sigue recibiendo el monto y verifica que su reparto coincida exactamente antes de guardar. |
| Resultados aritméticos | MontoFinanciado, Total de cuota, Comision y ValorDepreciado materializados | Exponerlos como columnas calculadas de consultas/vistas, sin capturarlos ni mantenerlos independientemente. |
| Totales del contrato | TotalIntereses y TotalNetoRecaudable en Credito | Registrar ambos en ResumenCredito al aprobar, como resumen contractual 1:1 generado desde el plan; se conserva lo solicitado por el PDF. |

Los cinco componentes de un abono son cinco conceptos definidos y distintos; no es necesario añadir un catálogo ni una tabla adicional de conceptos para este alcance. Ninguno implica guardar varios valores dentro de una celda. Si en el futuro los cargos fueran arbitrarios o variables por mes, habría que revisar este diseño.

**Límite de la afirmación de 3FN:** los datos base se organizan según las dependencias documentadas. El calendario generado y ResumenCredito son información financiera derivada que se conserva intencionalmente. Separar un resumen en otra tabla no elimina su redundancia respecto del plan: requiere consistencia transaccional. Las constantes del alcance (vehículos nuevos y Q25 de manejo) son restricciones del dominio, no se usan para afirmar una demostración formal absoluta de 3FN de cada columna física. No presentaremos el SQL anterior como estrictamente normalizado solo por tener PK y FK.

## 4. Relaciones propuestas y llaves

PK identifica una fila; FK conecta con una fila existente. En la lista, los atributos entre paréntesis forman la relación y se indica su PK. Los tipos, campos opcionales y validaciones no afectados se conservan como se revisaron en la Fase 2.

### 1. Departamento

`Departamento(CodigoDepartamento, Descripcion)`

PK: `CodigoDepartamento`.

### 2. Municipio

`Municipio(CodigoDepartamento, CodigoMunicipio, Descripcion)`

PK: `CodigoDepartamento,CodigoMunicipio`.

### 3. TipoTelefono

`TipoTelefono(CodigoTipoTelefono, Descripcion)`

PK: `CodigoTipoTelefono`.

### 4. TipoDireccion

`TipoDireccion(CodigoTipoDireccion, Descripcion)`

PK: `CodigoTipoDireccion`.

### 5. TipoGarantia

`TipoGarantia(CodigoTipoGarantia, Descripcion)`

PK: `CodigoTipoGarantia`.

### 6. TipoReferencia

`TipoReferencia(CodigoTipoReferencia, Descripcion)`

PK: `CodigoTipoReferencia`.

### 7. TipoPago

`TipoPago(CodigoTipoPago, Descripcion, RequiereReferencia)`

PK: `CodigoTipoPago`.

### 8. Marca

`Marca(CodigoMarca, Descripcion)`

PK: `CodigoMarca`.

### 9. Linea

`Linea(CodigoMarca, CodigoLinea, Descripcion)`

PK: `CodigoMarca,CodigoLinea`.

### 10. Agencia

`Agencia(CodigoAgencia, Nombre, Region)`

PK: `CodigoAgencia`.

### 11. Persona

`Persona(CodigoPersona, DPI, NIT, PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido, FechaNacimiento, Genero, CorreoElectronico)`

PK: `CodigoPersona`.

### 12. Telefono

`Telefono(CodigoPersona, Correlativo, CodigoTipoTelefono, Numero)`

PK: `CodigoPersona,Correlativo`.

### 13. Direccion

`Direccion(CodigoPersona, Correlativo, CodigoTipoDireccion, CodigoDepartamento, CodigoMunicipio, Detalle)`

PK: `CodigoPersona,Correlativo`.

### 14. Deudor

`Deudor(CodigoDeudor, CodigoPersona)`

PK: `CodigoDeudor`.

### 15. Referencia

`Referencia(CodigoReferencia, CodigoPersona, LugarTrabajo)`

PK: `CodigoReferencia`.

### 16. DetalleReferencia

`DetalleReferencia(CodigoDeudor, CodigoReferencia, CodigoTipoReferencia, ParentescoRelacion)`

PK: `CodigoDeudor,CodigoReferencia`.

### 17. Fiador

`Fiador(CodigoFiador, CodigoPersona)`

PK: `CodigoFiador`.

### 18. Vendedor

`Vendedor(CodigoVendedor, CodigoEmpleado, CodigoPersona, CodigoAgencia)`

PK: `CodigoVendedor`.

### 19. Garantia

`Garantia(CodigoGarantia, VIN, CodigoMarca, CodigoLinea, Anio, ValorAgencia, Placa, CodigoTipoGarantia, EsNuevo)`

PK: `CodigoGarantia`.

### 20. ParametroCredito

`ParametroCredito(CodigoParametro, Nombre, Activo, TasaAnual, ManejoMensual, TasaSeguroAuto, TasaSeguroVida, EngancheMinimo, ComisionPredeterminada, DepreciacionInicial)`

PK: `CodigoParametro`.

### 21. Credito

`Credito(NumeroCredito, CodigoDeudor, CodigoGarantia, CodigoVendedor, CodigoAgencia, CodigoParametro, Plazo, PrecioContado, Enganche, EngancheMinimo, TasaAnual, ManejoMensual, TasaSeguroAuto, TasaSeguroVida, PorcentajeComision, FiadoresRequeridos, Estado, FechaAprobacion, AprobadoPor, FechaAnulacion, MotivoAnulacion, AnuladoPor)`

PK: `NumeroCredito`.

### 22. CreditoFiador

`CreditoFiador(NumeroCredito, CodigoFiador)`

PK: `NumeroCredito,CodigoFiador`.

### 23. Depreciacion

`Depreciacion(CodigoDepreciacion, CodigoGarantia, FechaValoracion, ValorOriginal, Porcentaje, Observacion)`

PK: `CodigoDepreciacion`.

### 24. DetalleCuota

`DetalleCuota(NumeroCredito, Cuota, FechaVencimiento, Capital, Interes)`

PK: `NumeroCredito,Cuota`.

### 25. DetallePago

`DetallePago(CodigoPago, Comprobante, NumeroCredito, Cuota, FechaPago, CodigoTipoPago, ReferenciaBancaria, Capital, Interes, ManejoCuenta, SeguroAuto, SeguroVida, RegistradoPor, FechaAnulacion, MotivoAnulacion, AnuladoPor, Observacion)`

PK: `CodigoPago`.

### 26. ResumenCredito

`ResumenCredito(NumeroCredito, TotalIntereses, TotalNetoRecaudable)`

PK y FK: `NumeroCredito → Credito.NumeroCredito`, varchar(20). Totales: decimal(18,2), NOT NULL, no negativos. Cero filas para un borrador; exactamente una tras aprobar. No admite edición manual.

## 5. Relaciones y dependencias que justifican el modelo

| Tablas | FK / dependencia principal | Justificación |
| --- | --- | --- |
| Departamento, tipos, Marca, Agencia, ParametroCredito | PK → atributos descriptivos/configuración de su fila | Los nombres no se repiten como atributos de sus dependientes. No se presupone que dos descripciones iguales identifiquen una fila. |
| Municipio | CodigoDepartamento → Departamento; (CodigoDepartamento, CodigoMunicipio) → Descripcion | El código de municipio es local al departamento, no se toma solo como identificador. |
| Linea | CodigoMarca → Marca; (CodigoMarca, CodigoLinea) → Descripcion | El código de línea es local a la marca. |
| Persona | CodigoPersona → datos de la persona | Los roles reutilizan a la persona; el correo compartido no identifica a nadie de forma única. |
| Telefono | CodigoPersona → Persona; CodigoTipoTelefono → TipoTelefono; (CodigoPersona, Correlativo) → tipo y número | Cada teléfono es una fila; no se copian nombres de persona ni de tipo. |
| Direccion | CodigoPersona → Persona; CodigoTipoDireccion → TipoDireccion; (CodigoDepartamento, CodigoMunicipio) → Municipio | La pareja (CodigoPersona, Correlativo) determina el domicilio; no se guardan nombres del municipio/departamento. |
| Deudor, Referencia, Fiador | CodigoPersona → Persona, con UNIQUE por rol | Cada rol tiene PK propia y CodigoPersona como llave alternativa. LugarTrabajo pertenece a Referencia en el alcance actual. |
| Vendedor | CodigoPersona → Persona; CodigoAgencia → Agencia | CodigoVendedor, CodigoEmpleado y CodigoPersona son identificadores alternativos únicos no nulos. La agencia es la asignación actual. |
| DetalleReferencia | CodigoDeudor → Deudor; CodigoReferencia → Referencia; CodigoTipoReferencia → TipoReferencia | El tipo y parentesco dependen de la pareja cliente–referencia, no de la referencia aislada. |
| Garantia | (CodigoMarca, CodigoLinea) → Linea; CodigoTipoGarantia → TipoGarantia | CodigoGarantia y VIN identifican el vehículo. No hay atributo separado con el nombre de la marca. |
| Credito | CodigoDeudor → Deudor; CodigoGarantia → Garantia; CodigoVendedor → Vendedor; CodigoAgencia → Agencia; CodigoParametro → ParametroCredito | NumeroCredito determina las condiciones efectivamente pactadas y su ciclo de vida. Las condiciones históricas no son las actuales del catálogo. |
| CreditoFiador | NumeroCredito → Credito; CodigoFiador → Fiador | PK compuesta, sin atributos ajenos a la asociación. Permite 0, 1 o más según autorización. |
| Depreciacion | CodigoGarantia → Garantia | CodigoDepreciacion determina una valoración histórica, fecha, base y porcentaje. El valor resultante se calcula. |
| DetalleCuota | NumeroCredito → Credito | (NumeroCredito, Cuota) determina vencimiento y los importes de capital/interés del plan aprobado. |
| DetallePago | (NumeroCredito, Cuota) → DetalleCuota; CodigoTipoPago → TipoPago | CodigoPago y Comprobante son llaves alternativas. Determinan un evento de pago y su reparto efectivo. |
| ResumenCredito | NumeroCredito → Credito | NumeroCredito determina el resumen aprobado. La igualdad con los agregados del plan se controla en la transacción, no solo con la FK. |

Una FK compuesta siempre utiliza todos sus componentes: no unir Credito directamente con Persona, ni Pago solo por número de cuota, ni Garantia solo por código de línea.

Las uniones con padres únicos no multiplican filas del detalle: cada cuota tiene un solo crédito y cada pago una sola cuota. Para reportar importes de crédito junto a varios pagos, se agregan los pagos antes de unirlos; no se suman importes del contrato repetidos por cada pago.

**Llaves alternativas y nulabilidad:** VIN, CodigoEmpleado, CodigoPersona dentro de cada rol y Comprobante son únicos y no nulos. DPI, NIT y Placa conservan unicidad cuando tienen valor mediante índices filtrados; al admitir NULL no se presentan como llaves candidatas generales de todas las filas. Se mantienen los campos opcionales y condiciones de aprobación acordados en la Fase 2.

## 6. Condiciones históricas y datos calculados

Los parámetros sirven para preparar contratos nuevos. Si una tasa cambia mañana, un crédito aprobado conserva su tasa anterior. Por ello no se reemplazan las condiciones del crédito por una lectura de los parámetros actuales. Tampoco se toma la agencia actual del vendedor como la agencia histórica del contrato. El precio pactado del crédito puede diferir del valor de agencia actual del vehículo.

Después de aprobar, se bloquean cambios de precio, enganche, plazo, tasas, cargos, comisión, agencia contractual y plan. Una anulación conserva esas condiciones y el plan. No se permite corregirlos con una actualización genérica que altere pagos o reportes anteriores.

| Resultado mostrado | Fuente y fórmula |
| --- | --- |
| Monto financiado | PrecioContado − Enganche, decimal(18,2). |
| Tasa mensual | TasaAnual / 12, con precisión suficiente antes del redondeo monetario. |
| Manejo de la cuota | Credito.ManejoMensual, Q25. |
| Seguro auto por cuota | ROUND((PrecioContado − Enganche) × TasaSeguroAuto, 2). |
| Seguro vida por cuota | ROUND((PrecioContado − Enganche) × TasaSeguroVida, 2). |
| Total cuota | Capital + Interes + manejo + ambos seguros. |
| Monto abonado | Suma de los cinco componentes guardados en DetallePago. |
| Comisión bruta del pago | ROUND(Monto abonado × Credito.PorcentajeComision, 2); la anulación se reporta como reversión según su fecha. |
| Valor depreciado | ROUND(ValorOriginal × (1 − Porcentaje), 2). |
| TotalIntereses contractual | Suma de intereses del plan aprobado. |
| TotalNetoRecaudable contractual | Suma de cuotas completas; excluye enganche y no descuenta comisiones, según interpretación de trabajo. |

Proponer vistas de lectura `vw_CuotaDesglosada`, `vw_PagoDesglosado`, `vw_CreditoResumen` y `vw_DepreciacionCalculada`. Los procedimientos siguen siendo el punto de entrada de la API: una vista interna no cambia ese acuerdo. Se conservarán los nombres de campos en las respuestas para simplificar las pantallas y reportes.

El usuario ingresa el importe del abono, no cinco cantidades arbitrarias. El procedimiento distribuye proporcionalmente el saldo pendiente de los componentes, reparte los centavos restantes y verifica que la suma sea exactamente el importe recibido. Solo entonces guarda el evento. La regla de saldo positivo y prohibición de exceder la cuota permanece.

Ejemplo ilustrativo: un vehículo de Q100,000 con enganche de Q20,000 financia Q80,000. A las tasas de prueba aprobadas, cada cuota incorpora Q120 de seguro de auto, Q40 de vida y Q25 de manejo. La pantalla seguirá mostrando esos tres cargos junto al capital y al interés de esa cuota. Se obtienen de las condiciones originales del contrato, aunque los parámetros para créditos nuevos cambien después.

## 7. Integridad y controles que no se resuelven solo con normalización

- PK, FK, UNIQUE y CHECK protegen identificación, relaciones, rangos y coherencia dentro de una fila. Se mantienen sin borrado en cascada del historial financiero.
- Los procedimientos validan tres referencias distintas, contactos e identificación requeridos, fiadores autorizados, enganche mínimo, plazo, vehículo y aprobación. Una FK no cuenta referencias ni decide si un expediente está completo.
- Aprobación en una sola transacción: validar, fijar condiciones, generar N cuotas y crear ResumenCredito. Un fallo revierte toda la operación. Repetir aprobación debe rechazarse.
- El abono debe bloquear/controlar concurrentemente el saldo de su cuota; dos pagos simultáneos no pueden sobrepagarla. La anulación devuelve el saldo sin borrar el evento.
- Fechas mensuales conservan el día original con ajuste al último día cuando no existe. No se calcula marzo partiendo del día acortado de febrero.
- Mora y saldos son resultados a una fecha de corte. Se consideran pagos y anulaciones hasta ese corte; una anulación posterior no debe modificar retrospectivamente el saldo que se mostraba antes.
- Dinero en decimal(18,2), tasas con precisión decimal; sin float para importes. DPI, NIT y VIN son texto, no cantidades; no perder ceros iniciales.
- El resumen aprobado no equivale al saldo pendiente ni a lo recaudado. Los pagos no disminuyen TotalNetoRecaudable contractual; disminuyen el saldo calculado.
- Usuario/responsable escrito como texto no constituye autenticación. El inicio de sesión sigue opcional y pendiente.

## 8. Trabajo necesario después de aprobar este diseño

1. Actualizar el diagrama/diccionario para reflejar las 26 tablas, conservando el documento previo como antecedente.
2. Preparar una nueva versión identificable del SQL para instalaciones nuevas, y decidir separadamente el tratamiento de cualquier instalación existente según su inventario real. No ejecutar el instalador anterior encima.
3. Ajustar generador de cuotas, aprobación, abonos, anulaciones, consultas de saldos, CRUD y los 20 reportes. Revisar todos los índices que mencionen columnas trasladadas/calculadas.
4. Probar instalación limpia, relaciones y restricciones; aprobar un crédito, validar sumas y calendario, abonar parcialmente, liquidar y anular. Incluir concurrencia, fechas de corte, cambio de parámetros y rechazo de datos inválidos.
5. Comparar resultados monetarios con la versión anterior mediante casos controlados: el ajuste organizativo no debe cambiar lo cobrado.
6. Crear paquete actualizado para el compañero con instrucciones y comprobación de integridad; señalar expresamente que sustituye el diseño previo. No dar por probada esta futura versión con las pruebas de la anterior.

## 9. Checklist de esta fase

- [x] Inventariadas las 25 relaciones del SQL existente.
- [x] Definidas las 26 relaciones propuestas y sus PK.
- [x] Identificadas FK simples y compuestas, llaves alternativas y condiciones de NULL.
- [x] Explicadas 1FN, 2FN y 3FN con ejemplos del proyecto.
- [x] Identificadas repeticiones de cargos y porcentaje de comisión que deben corregirse.
- [x] Diferenciados datos de contrato, parámetros actuales, valores calculados y agregados conservados.
- [x] Preservado el desglose completo y los vencimientos mensuales acordados.
- [x] Documentados controles transaccionales y límites de la revisión.
- [x] Aprobación de estos ajustes por Diego.
- [x] Implementación y pruebas de v2 documentadas en FASE_4_SQL_Implementado.md.

Siguen pendientes de validación con el ingeniero las interpretaciones sobre anulación frente a borrado y el significado exacto de total neto recaudable. La normalización no resuelve esas decisiones de requisitos.

## Aclaración aplicada en Fase 4

El inciso E exige almacenar el monto depositado: se conservó DetallePago.Monto. CHECK y procedimiento exigen coincidencia con el desglose. La propuesta anterior de calcular exclusivamente Monto es antecedente de revisión, no el esquema final. Se reconoce esta redundancia controlada sin afirmar 3FN estricta de cada columna física. La fuente final es database/v2/src/deployment_payload.sql y el diccionario final está en la Fase 4.
