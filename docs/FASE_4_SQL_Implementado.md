# Fase 4 — Implementación SQL de MAGIS-AUTO

Fecha: 8 de octubre de 2026. Rama: pruebas-diego.

Estado: v2 implementada, probada en MAGISAUTO_ValidacionV2 e instalada por Diego como MAGISAUTO_Proyecto_V2. La base nueva se verificó directamente el 8 de octubre de 2026. Conexión de la API completada posteriormente en la Fase 5; MAGISAUTO_Proyecto anterior se conserva.

## Resultado y correspondencia con el PDF

26 tablas, 150 procedimientos, 4 vistas, 2 funciones y 20 reportes. Instalador sin operaciones de ejemplo. Se completaron 45 comprobaciones de integración en MAGISAUTO_ValidacionV2, creada por Diego en SSMS. Los datos ficticios están solo allí; no se modificaron la base del proyecto ni las bases de clase.

| Inciso | Implementación |
| --- | --- |
| A | Persona, Deudor, contactos y referencias; tres referencias completas al aprobar e identidad única según rol. |
| B | Garantia, Marca, Linea, VIN único, placa opcional, historial Depreciacion y un crédito vigente por vehículo. |
| C | Crédito, fiadores N:M, condiciones históricas, plan con desglose completo y resumen con totales guardados. |
| D | Vendedor/Agencia, comisión pactada por contrato sobre pagos efectivos y reversión al anular. |
| E | Cuotas mensuales, abonos, comprobante único, fecha/hora, monto depositado almacenado, medio y referencia. |
| Operaciones | Procedimientos de aplicación, búsquedas y 20 reportes; conexión desde API pendiente. |

El inciso E exige guardar el monto depositado: se mantiene Monto y se valida contra el desglose. Es redundancia controlada. ResumenCredito es un agregado contractual generado al aprobar; no tiene edición manual. No se afirma normalización física absoluta. Explicar al ingeniero la excepción de tabla derivada y la interpretación de anulación frente al borrado, además de confirmar el total neto recaudable.

## Relaciones financieras

Un crédito genera muchas cuotas y cada cuota recibe varios pagos. Un crédito tiene cero o un resumen (exactamente uno tras aprobar). CreditoFiador relaciona créditos y fiadores muchos a muchos. Un vehículo conserva su historial de créditos, con solo uno vigente, y múltiples valoraciones. Vendedor coloca múltiples créditos. Las vistas presentan cargos contractuales y resultados calculados; los procedimientos siguen siendo la vía de operación.

## Diccionario físico final

Extraído del SQL v2: columnas, tipos, nulabilidad y condiciones de columna. Las FK y CHECK de tabla completos, índices y módulos están en deployment_payload.sql y en el instalador.

### Departamento

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoDepartamento | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoDepartamento].

### Municipio

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoDepartamento | int NOT NULL REFERENCES dbo.Departamento(CodigoDepartamento) |
| CodigoMunicipio | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoDepartamento],[CodigoMunicipio].

### TipoTelefono

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoTipoTelefono | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoTipoTelefono].

### TipoDireccion

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoTipoDireccion | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoTipoDireccion].

### TipoGarantia

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoTipoGarantia | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoTipoGarantia].

### TipoReferencia

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoTipoReferencia | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoTipoReferencia].

### TipoPago

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoTipoPago | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |
| RequiereReferencia | bit NOT NULL |

PK: [CodigoTipoPago].

### Marca

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoMarca | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoMarca].

### Linea

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoMarca | int NOT NULL REFERENCES dbo.Marca(CodigoMarca) |
| CodigoLinea | int NOT NULL |
| Descripcion | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Descripcion)))>0) |

PK: [CodigoMarca],[CodigoLinea].

### Agencia

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoAgencia | int IDENTITY(1,1) NOT NULL |
| Nombre | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Nombre)))>0) |
| Region | nvarchar(128) NOT NULL CHECK(LEN(LTRIM(RTRIM(Region)))>0) |

PK: [CodigoAgencia].

### Persona

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoPersona | int IDENTITY(1,1) NOT NULL |
| DPI | varchar(13) NULL CHECK(DPI IS NULL OR (LEN(DPI)=13 AND DPI NOT LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2)) |
| NIT | varchar(20) NULL CHECK(NIT IS NULL OR LEN(LTRIM(RTRIM(NIT)))>0) |
| PrimerNombre | nvarchar(64) NOT NULL CHECK(LEN(LTRIM(RTRIM(PrimerNombre)))>0) |
| SegundoNombre | nvarchar(64) NULL |
| PrimerApellido | nvarchar(64) NOT NULL CHECK(LEN(LTRIM(RTRIM(PrimerApellido)))>0) |
| SegundoApellido | nvarchar(64) NULL |
| FechaNacimiento | date NULL |
| Genero | char(1) NULL CHECK(Genero IN ('M','F','O')) |
| CorreoElectronico | nvarchar(254) NULL CHECK(CorreoElectronico IS NULL OR CorreoElectronico LIKE '%_@_%._%') |

PK: [CodigoPersona].

### Telefono

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoPersona | int NOT NULL REFERENCES dbo.Persona(CodigoPersona) |
| Correlativo | smallint NOT NULL CHECK(Correlativo>0) |
| CodigoTipoTelefono | int NOT NULL REFERENCES dbo.TipoTelefono(CodigoTipoTelefono) |
| Numero | varchar(32) NOT NULL CHECK(LEN(LTRIM(RTRIM(Numero)))>=8) |

PK: [CodigoPersona],[Correlativo].

### Direccion

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoPersona | int NOT NULL REFERENCES dbo.Persona(CodigoPersona) |
| Correlativo | smallint NOT NULL CHECK(Correlativo>0) |
| CodigoTipoDireccion | int NOT NULL REFERENCES dbo.TipoDireccion(CodigoTipoDireccion) |
| CodigoDepartamento | int NOT NULL |
| CodigoMunicipio | int NOT NULL |
| Detalle | nvarchar(300) NOT NULL CHECK(LEN(LTRIM(RTRIM(Detalle)))>0) |

PK: [CodigoPersona],[Correlativo].

### Deudor

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoDeudor | int IDENTITY(1,1) NOT NULL |
| CodigoPersona | int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona) |

PK: [CodigoDeudor].

### Referencia

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoReferencia | int IDENTITY(1,1) NOT NULL |
| CodigoPersona | int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona) |
| LugarTrabajo | nvarchar(200) NOT NULL CHECK(LEN(LTRIM(RTRIM(LugarTrabajo)))>0) |

PK: [CodigoReferencia].

### DetalleReferencia

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoDeudor | int NOT NULL REFERENCES dbo.Deudor(CodigoDeudor) |
| CodigoReferencia | int NOT NULL REFERENCES dbo.Referencia(CodigoReferencia) |
| CodigoTipoReferencia | int NOT NULL REFERENCES dbo.TipoReferencia(CodigoTipoReferencia) |
| ParentescoRelacion | nvarchar(100) NOT NULL CHECK(LEN(LTRIM(RTRIM(ParentescoRelacion)))>0) |

PK: [CodigoDeudor],[CodigoReferencia].

### Fiador

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoFiador | int IDENTITY(1,1) NOT NULL |
| CodigoPersona | int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona) |

PK: [CodigoFiador].

### Vendedor

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoVendedor | int IDENTITY(1,1) NOT NULL |
| CodigoEmpleado | varchar(30) NOT NULL UNIQUE CHECK(LEN(LTRIM(RTRIM(CodigoEmpleado)))>0) |
| CodigoPersona | int NOT NULL UNIQUE REFERENCES dbo.Persona(CodigoPersona) |
| CodigoAgencia | int NOT NULL REFERENCES dbo.Agencia(CodigoAgencia) |

PK: [CodigoVendedor].

### Garantia

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoGarantia | int IDENTITY(1,1) NOT NULL |
| VIN | varchar(17) NOT NULL UNIQUE CHECK(LEN(VIN)=17 AND VIN NOT LIKE '%[^0-9A-HJ-NPR-Z]%' COLLATE Latin1_General_100_BIN2) |
| CodigoMarca | int NOT NULL |
| CodigoLinea | int NOT NULL |
| Anio | smallint NOT NULL CHECK(Anio BETWEEN 1886 AND 2100) |
| ValorAgencia | decimal(18,2) NOT NULL CHECK(ValorAgencia>0) |
| Placa | varchar(20) NULL CHECK(Placa IS NULL OR LEN(LTRIM(RTRIM(Placa)))>0) |
| CodigoTipoGarantia | int NOT NULL REFERENCES dbo.TipoGarantia(CodigoTipoGarantia) |
| EsNuevo | bit NOT NULL DEFAULT 1 CHECK(EsNuevo=1) |

PK: [CodigoGarantia].

### ParametroCredito

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoParametro | int IDENTITY(1,1) NOT NULL |
| Nombre | nvarchar(100) NOT NULL |
| Activo | bit NOT NULL |
| TasaAnual | decimal(9,6) NOT NULL CHECK(TasaAnual BETWEEN 0 AND 1) |
| ManejoMensual | decimal(18,2) NOT NULL CHECK(ManejoMensual=25) |
| TasaSeguroAuto | decimal(9,6) NOT NULL CHECK(TasaSeguroAuto>0 AND TasaSeguroAuto<=1) |
| TasaSeguroVida | decimal(9,6) NOT NULL CHECK(TasaSeguroVida>0 AND TasaSeguroVida<=1) |
| EngancheMinimo | decimal(9,6) NOT NULL CHECK(EngancheMinimo>=0.20 AND EngancheMinimo<1) |
| ComisionPredeterminada | decimal(9,6) NOT NULL CHECK(ComisionPredeterminada BETWEEN 0 AND 1) |
| DepreciacionInicial | decimal(9,6) NOT NULL CHECK(DepreciacionInicial BETWEEN 0.15 AND 0.20) |

PK: [CodigoParametro].

### Credito

| Campo | Tipo y condiciones |
| --- | --- |
| NumeroCredito | varchar(20) NOT NULL CHECK(LEN(LTRIM(RTRIM(NumeroCredito)))>0) |
| CodigoDeudor | int NOT NULL REFERENCES dbo.Deudor(CodigoDeudor) |
| CodigoGarantia | int NOT NULL REFERENCES dbo.Garantia(CodigoGarantia) |
| CodigoVendedor | int NOT NULL REFERENCES dbo.Vendedor(CodigoVendedor) |
| CodigoAgencia | int NOT NULL REFERENCES dbo.Agencia(CodigoAgencia) |
| CodigoParametro | int NOT NULL REFERENCES dbo.ParametroCredito(CodigoParametro) |
| Plazo | smallint NOT NULL DEFAULT 60 CHECK(Plazo IN(12,24,36,48,60)) |
| PrecioContado | decimal(18,2) NOT NULL CHECK(PrecioContado>0) |
| Enganche | decimal(18,2) NOT NULL |
| EngancheMinimo | decimal(9,6) NOT NULL CHECK(EngancheMinimo>=0.20 AND EngancheMinimo<1) |
| TasaAnual | decimal(9,6) NOT NULL CHECK(TasaAnual BETWEEN 0 AND 1) |
| ManejoMensual | decimal(18,2) NOT NULL CHECK(ManejoMensual=25) |
| TasaSeguroAuto | decimal(9,6) NOT NULL CHECK(TasaSeguroAuto>0 AND TasaSeguroAuto<=1) |
| TasaSeguroVida | decimal(9,6) NOT NULL CHECK(TasaSeguroVida>0 AND TasaSeguroVida<=1) |
| PorcentajeComision | decimal(9,6) NOT NULL CHECK(PorcentajeComision BETWEEN 0 AND 1) |
| FiadoresRequeridos | smallint NOT NULL CHECK(FiadoresRequeridos>=0) |
| Estado | varchar(10) NOT NULL DEFAULT 'BORRADOR' CHECK(Estado IN('BORRADOR','VIGENTE','LIQUIDADO','ANULADO')) |
| FechaAprobacion | datetime2(0) NULL |
| AprobadoPor | nvarchar(100) NULL |
| FechaAnulacion | datetime2(0) NULL |
| MotivoAnulacion | nvarchar(300) NULL |
| AnuladoPor | nvarchar(100) NULL |

PK: [NumeroCredito].

### CreditoFiador

| Campo | Tipo y condiciones |
| --- | --- |
| NumeroCredito | varchar(20) NOT NULL REFERENCES dbo.Credito(NumeroCredito) |
| CodigoFiador | int NOT NULL REFERENCES dbo.Fiador(CodigoFiador) |

PK: [NumeroCredito],[CodigoFiador].

### Depreciacion

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoDepreciacion | int IDENTITY(1,1) NOT NULL |
| CodigoGarantia | int NOT NULL REFERENCES dbo.Garantia(CodigoGarantia) |
| FechaValoracion | date NOT NULL |
| ValorOriginal | decimal(18,2) NOT NULL CHECK(ValorOriginal>0) |
| Porcentaje | decimal(9,6) NOT NULL CHECK(Porcentaje BETWEEN 0.15 AND 0.20) |
| Observacion | nvarchar(300) NOT NULL CHECK(LEN(LTRIM(RTRIM(Observacion)))>0) |

PK: [CodigoDepreciacion].

### DetalleCuota

| Campo | Tipo y condiciones |
| --- | --- |
| NumeroCredito | varchar(20) NOT NULL REFERENCES dbo.Credito(NumeroCredito) |
| Cuota | smallint NOT NULL CHECK(Cuota BETWEEN 1 AND 60) |
| FechaVencimiento | date NOT NULL |
| Capital | decimal(18,2) NOT NULL CHECK(Capital>=0) |
| Interes | decimal(18,2) NOT NULL CHECK(Interes>=0) |

PK: [NumeroCredito],[Cuota].

### DetallePago

| Campo | Tipo y condiciones |
| --- | --- |
| CodigoPago | bigint IDENTITY(1,1) NOT NULL |
| Comprobante | bigint NOT NULL UNIQUE DEFAULT(NEXT VALUE FOR dbo.SecComprobante) |
| NumeroCredito | varchar(20) NOT NULL |
| Cuota | smallint NOT NULL |
| FechaPago | datetime2(0) NOT NULL |
| CodigoTipoPago | int NOT NULL REFERENCES dbo.TipoPago(CodigoTipoPago) |
| ReferenciaBancaria | nvarchar(100) NULL |
| Monto | decimal(18,2) NOT NULL CHECK(Monto>0) |
| Capital | decimal(18,2) NOT NULL CHECK(Capital>=0) |
| Interes | decimal(18,2) NOT NULL CHECK(Interes>=0) |
| ManejoCuenta | decimal(18,2) NOT NULL CHECK(ManejoCuenta>=0) |
| SeguroAuto | decimal(18,2) NOT NULL CHECK(SeguroAuto>=0) |
| SeguroVida | decimal(18,2) NOT NULL CHECK(SeguroVida>=0) |
| RegistradoPor | nvarchar(100) NOT NULL CHECK(LEN(LTRIM(RTRIM(RegistradoPor)))>0) |
| FechaAnulacion | datetime2(0) NULL |
| MotivoAnulacion | nvarchar(300) NULL |
| AnuladoPor | nvarchar(100) NULL |
| Observacion | nvarchar(300) NULL |

PK: [CodigoPago].

### ResumenCredito

| Campo | Tipo y condiciones |
| --- | --- |
| NumeroCredito | varchar(20) NOT NULL REFERENCES dbo.Credito(NumeroCredito) |
| TotalIntereses | decimal(18,2) NOT NULL CHECK(TotalIntereses>=0) |
| TotalNetoRecaudable | decimal(18,2) NOT NULL CHECK(TotalNetoRecaudable>=0) |

PK: [NumeroCredito].

## Validación y pendientes

- [x] Sintaxis y referencias del modelo sin errores.
- [x] Instalación real: 26 tablas, 150 procedimientos y 20 reportes.
- [x] Aprobación, plan/resumen, rechazo de doble aprobación.
- [x] Enganche mínimo, plazo y rechazo de vehículo con crédito activo.
- [x] Cuotas francesas, ajuste final, vencimientos enero/febrero/marzo y desglose.
- [x] Abonos, monto/desglose, comisión, rechazo de sobrepago y referencia bancaria.
- [x] Nuevos parámetros no alteran contratos aprobados.
- [x] Anulación preserva comprobante y saldos históricos; liquidación/reapertura.
- [x] Dos sesiones pagan la última cuota: solo una se acepta.
- [x] Ejecución de los 20 reportes.
- [x] Fórmulas: 75 planes y 1,000 repartos de centavos.
- [x] Instalar v2 como base de trabajo: MAGISAUTO_Proyecto_V2.
- [x] Comparar la instalación nueva con 460 elementos de estructura/módulos y 11 catálogos/parámetros; sin diferencias ni operaciones de ejemplo.
- [x] Conectar la API con cuenta limitada y probar llamadas desde C# (Fase 5: catálogo de marcas).
- [ ] Interfaz y aceptación de usuarios.
- [ ] Confirmar las interpretaciones académicas pendientes con el ingeniero.

No se certifican todos los casos posibles, rendimiento masivo ni una interfaz no conectada. El paquete actualizado es database/v2/entrega; database/entrega-companero conserva v1 como antecedente.

