# MAGIS-AUTO — SQL versión 2.0

Preparado el 8 de octubre de 2026, rama pruebas-diego.

## Contenido

Instalación nueva con **26 tablas, 150 procedimientos, 4 vistas y 2 funciones**, llaves, índices, restricciones, catálogos y parámetros. Incluye los 20 reportes descritos en reportes.json. Sin clientes, referencias, fiadores, vendedores, vehículos, créditos, cuotas ni pagos de ejemplo.

Es una ampliación académica del modelo del ingeniero, conforme al PDF y los acuerdos. No es copia literal de MagisV1 ni migración de una base existente. API y pantallas se desarrollan por separado.

## Instalación en SSMS

1. Conectarse al motor SQL Server 2022/2025 con permiso para crear bases.
2. Abrir MAGISAUTO_Proyecto_Completo.sql. El nombre predeterminado es MAGISAUTO_Proyecto_V2; puede cambiarse la variable @Base por otro nombre NUEVO.
3. Ejecutar TODO, sin selección parcial ni modo SQLCMD.
4. Comprobar: 26 tablas, 150 procedimientos y 20 reportes, seguido de instalación completa.
5. Seleccionar la nueva base y ejecutar VERIFICAR_INSTALACION.sql.

Si el nombre existe, se detiene. No borra, migra ni sobrescribe. Un error revierte la transacción de objetos; la base nueva puede quedar vacía para inspección. No ejecutar después el archivo original del ingeniero encima de esta versión.

## Cambios frente a v1

- DetalleCuota guarda fecha, capital e interés. Los cargos mensuales se obtienen de las condiciones originales del crédito mediante vw_CuotaDesglosada. Sigue disponible todo el desglose de los incisos C y E.
- El porcentaje de comisión pertenece al contrato; vw_PagoDesglosado calcula la comisión de cada pago.
- ResumenCredito conserva TotalIntereses y TotalNetoRecaudable en la transacción de aprobación. Un borrador no tiene resumen y muestra NULL en esos totales hasta aprobar.
- MontoFinanciado y ValorDepreciado se exponen en vistas de lectura.
- **Monto depositado sigue almacenado en DetallePago**, como pide el inciso E. CHECK y procedimiento exigen igualdad con los cinco componentes. Es redundancia controlada; no se afirma normalización física absoluta.
- Procedimientos, índices y los 20 reportes utilizan las nuevas fuentes.

ResumenCredito tiene Listar y Buscar; su alta pertenece a la aprobación. No se permite editar/borrar manualmente el resumen de un contrato aprobado. Las 25 entidades operativas conservan Insertar, Actualizar, Eliminar, Listar y Buscar con restricciones financieras. La excepción de esta tabla derivada debe explicarse junto con la interpretación del borrado financiero en la evaluación.

## Reglas conservadas

- Identidad única por rol, correo compartido permitido, contactos múltiples y tres referencias completas al aprobar. Persona admite datos opcionales cuando el rol no los requiere.
- VIN/chasis único, placa opcional, vehículos nuevos y un crédito vigente por vehículo. Fiadores N:M; uno por defecto, cero o más según comité; no puede ser su propio cliente.
- Enganche mínimo 20%, mayor permitido; plazos 12/24/36/48/60, predeterminado 60.
- Sistema francés sobre saldo programado; nominal anual inicial 12.5%, mensual anual/12, configurable; tasa cero y ajuste final de centavos.
- Vencimientos desde el día original, con ajuste al último día si no existe en ese mes.
- Q25 de manejo; seguros académicos de prueba: auto 0.15% y vida 0.05% mensual del monto original financiado. No son cotizaciones de mercado. Condiciones históricas inmutables por contrato.
- Comisión inicial 2%, configurable por crédito, sobre pagos efectivos completos; se revierte al anular, no se carga al cliente. El reporte no certifica desembolso al vendedor.
- Depreciación inicial 15%, seleccionable hasta 20%, con historial. No reduce la deuda ni se aplica periódicamente de forma automática.
- Abonos parciales por cuota, reparto proporcional en centavos, sin sobrepago ni anticipos extraordinarios a capital.
- Recibo único, hora de Guatemala, cinco medios y referencia bancaria según medio. Movimientos cronológicos, sin futuro ni anteriores a aprobación.
- Mora desde el día posterior al vencimiento, sin penalización monetaria. Cortes consideran pagos y anulaciones hasta el final del día.
- Historial financiero conservado: físicos solo registros sin dependencias/borradores; pagos se anulan con fecha, motivo y responsable. Un pago solo permite actualizar observación; corregir importe requiere anular y registrar de nuevo.
- TotalNetoRecaudable = suma de cuotas completas, excluye enganche y no resta comisiones. No equivale a utilidad ni saldo pendiente.

Pendientes del ingeniero: confirmar esa interpretación de total neto recaudable y la anulación frente al borrado físico por entidad. No se presentan como instrucciones textuales del PDF.

## Catálogos y acceso

Incluye cabeceras de Jalapa/Jutiapa (no todo Guatemala), cinco marcas/líneas, tipos de contacto/referencia/garantía/pago, agencia académica y parámetros activos. Ampliables con procedimientos; no requiere el complemento de clase.

La aplicación debe llamar solo procedimientos api.* con parámetros y una cuenta del rol magis_api. Ese rol permite EXECUTE en api y deniega lectura/escritura directa en dbo. El instalador no crea logins ni contraseñas. Vistas y funciones son fuentes internas. El login del personal sigue opcional; el responsable escrito no verifica identidad.

Operaciones financieras: Credito_Aprobar, Credito_Anular y DetallePago_Anular. Listar/Buscar no están paginadas todavía y se orientan al volumen académico.

## Evidencia y límites

- Sintaxis: 159 bloques sin errores.
- Modelo: 195 objetos sin mensajes.
- Instalación real en SQL Server 2025: MAGISAUTO_ValidacionV2.
- **45 comprobaciones de integración correctas**, incluida ejecución de los 20 reportes, condiciones históricas, abonos, anulaciones, liquidación y dos pagos simultáneos.
- Fórmulas: 75 planes y 1,000 repartos de abonos en SQL Server, con variables de tabla sin operaciones persistentes.

No son pruebas exhaustivas ni de rendimiento masivo. La API, interfaz y autenticación no se probaron aquí. Ejecutar reportes no sustituye la revisión académica de su utilidad.

La base de ensayo conserva datos ficticios; NO están en el instalador. MAGISAUTO_Proyecto y las bases de clase no se modificaron. Todavía falta instalar v2 como base de trabajo y configurar la conexión de la aplicación.

## Archivos

- MAGISAUTO_Proyecto_Completo.sql: instalación nueva.
- VERIFICAR_INSTALACION.sql: estructura y ausencia de operaciones.
- inventario.json y reportes.json: objetos y utilidad de consultas.
- validacion-*.json: resultados obtenidos; no certificados de otra instalación.
- SHA256SUMS.txt: integridad de esta entrega.

Fuentes y ensayo aislado están en ../src en el repositorio. El ZIP no incluye credenciales, permisos de la cuenta técnica ni datos ficticios del ensayo.
