# Fase 0 — Requisitos y acuerdos de MAGIS-AUTO

Documento reconstruido el 11 de octubre de 2026 para completar el historial. Trabajo de Diego en `pruebas-diego`.

No es un acta escrita al comenzar el proyecto. Recupera las decisiones de la conversación y las contrasta con la primera entrega SQL y los documentos posteriores. No atribuye una fecha exacta a cada aprobación ni afirma que las funciones ya estuvieran programadas en fase 0.

## 1. Para qué sirvió esta fase

Comprender el enunciado y acordar las reglas antes de diseñar e implementar la solución. El objetivo es administrar financiamiento de vehículos nuevos: registrar las personas y el vehículo, preparar y aprobar un crédito, generar cuotas, registrar pagos y consultar reportes.

La referencia de requisitos es **Base de Datos I Proyecto final I.pdf**, proporcionado por Diego. `MagisV1 (2).sql` es la base de partida entregada; las ampliaciones del proyecto se documentan como decisiones e implementación propias, no como contenido literal del archivo original.

## 2. Lo que exige el enunciado

| Área | Requisito y finalidad |
| --- | --- |
| Clientes | Código interno, identificación, nombres, correo y varios teléfonos y direcciones. Permite identificar y contactar a quien solicita financiamiento. |
| Referencias | Al menos tres referencias personales, con datos de contacto, trabajo y relación con el solicitante. Sustentan el expediente del cliente. |
| Vehículos | VIN/chasis único, marca, línea, año, precio al contado y placa opcional. Identifican la garantía; un vehículo no respalda simultáneamente dos créditos activos. |
| Depreciación | Pérdida inicial de valor entre 15% y 20% al salir de agencia. Se distingue el valor del vehículo de la deuda del cliente. |
| Crédito | Número único, aprobación, plazo, enganche y monto financiado. Cada obligación pertenece a un cliente y puede tener fiadores. |
| Cuotas | Vencimientos mensuales y desglose de capital, interés, Q25 de manejo y seguros de automóvil y vida. Tasa anual inicial de 12.5%, configurable. |
| Totales | Almacenar intereses totales y total neto recaudable del contrato. |
| Vendedores | Código de empleado, identificación, nombre y agencia o región. Un vendedor por crédito; comisión sobre pagos efectivos. |
| Pagos | Una cuota admite varios abonos. Cada transacción tiene comprobante, fecha/hora, monto guardado, medio y referencia bancaria cuando corresponde. |
| Aplicación | Web o móvil; registrar, actualizar, eliminar, listar y buscar las entidades. Acceso a datos por procedimientos almacenados llamados desde la API. |
| Reportes | Consultas de catálogos y al menos 20 consultas financieras, explicando su utilidad; incluye el caso de cumpleaños y carta individual. |

La fecha de entrega indicada en el PDF es el 17 de octubre de 2026. La existencia de tablas o procedimientos no equivale a terminar sus pantallas ni a demostrar todos los requisitos.

## 3. Decisiones adoptadas y reflejadas en la entrega SQL

Estos valores completan lo que el enunciado no detalla. No son recomendaciones comerciales ni tasas oficiales de aseguradoras.

| Tema | Acuerdo del proyecto | Para qué sirve |
| --- | --- | --- |
| Enganche | Mínimo 20% del precio; admite uno mayor, dejando capital por financiar. | Determina cuánto aporta el cliente y cuánto presta el crédito. |
| Plazos | 12, 24, 36, 48 o 60 meses; 60 predeterminado. | Mantiene opciones explícitas. No se implementó autorización de plazos fuera de esta lista. |
| Amortización | Sistema francés, tasa mensual = anual nominal / 12. | Capital más interés forman una cuota base constante, salvo ajuste final de centavos. |
| Vencimientos | Primer vencimiento un mes después de aprobar; fechas calculadas desde el día original. | Evita que un mes corto cambie permanentemente el día de cobro. |
| Manejo | Q25 por cuota, no por cada abono. | Evita cobrar varias veces el cargo mensual. |
| Seguros | Auto 0.15% mensual y vida 0.05% mensual del monto originalmente financiado. | Valores académicos iniciales; se guardan las condiciones de cada contrato. |
| Fiadores | Uno por defecto; el comité puede indicar cero o más según el caso. | Admite la flexibilidad descrita en el enunciado. Un cliente no es su propio fiador. |
| Comisión | Inicial 2% del pago efectivo completo, configurable por crédito. | Reconoce cobros reales; una anulación revierte su efecto. No es un cargo adicional al cliente. |
| Depreciación | Inicial 15%, dentro del intervalo 15–20%. | Registra una valoración sin reducir automáticamente la deuda ni aplicar depreciaciones periódicas inventadas. |
| Abonos | Un movimiento se aplica a una cuota y se distribuye proporcionalmente entre sus cinco componentes. | Conserva un desglose consistente y controla centavos y sobrepagos. |
| Mora | Desde el día posterior al vencimiento sobre saldo pendiente, sin penalización monetaria adicional. | Permite reportar atrasos sin añadir multas no acordadas. |
| Correo | Puede compartirse entre personas. | No se inventa una restricción de correo único. |
| Datos opcionales | Dependen del rol y del momento del expediente; placa opcional. | Permite preparar registros sin permitir que un contrato se apruebe incompleto. |
| Acceso del personal | Inicio de sesión pendiente y opcional dentro del alcance acordado. | Se distingue de la credencial técnica que conecta la API con SQL Server. |
| Datos iniciales | Catálogos y parámetros; sin operaciones de ejemplo en el paquete compartido. | Cada compañero empieza sin clientes, créditos o pagos ficticios precargados. |

Los contratos aprobados conservan sus condiciones: cambiar parámetros para futuros créditos no debe reescribir los existentes. No se incluyeron anticipos extraordinarios a capital ni recálculo del plan por esos anticipos.

## 4. Ejemplo para entender el desglose

Vehículo de Q100,000 con enganche de Q20,000: capital financiado Q80,000. La cuota se calcula sobre ese financiamiento y el plazo elegido.

Con los parámetros académicos, cada mes se agregan Q25 de manejo, Q120 de seguro de automóvil y Q40 de seguro de vida al importe de capital más interés. Los Q185 de cargos y seguros no son el capital más interés ni representan toda la cuota.

Un crédito aprobado el 31 de enero vence al final de febrero y vuelve al 31 de marzo: se toma como referencia el día original. Este ejemplo explica la regla; no acredita una prueba nueva ejecutada al reconstruir el documento.

## 5. Aclaraciones posteriores: 11 de octubre de 2026

Las siguientes precisiones se documentaron después de las fases iniciales. La explicación completa está en [Decisiones de la revisión del PDF](DECISIONES_REVISION_PDF.md).

- **Total neto recaudable:** suma de cuotas completas, incluyendo capital, intereses, manejo y ambos seguros. Excluye el enganche y no descuenta comisiones. Es un total contractual esperado, no utilidad ni dinero ya cobrado.
- **Eliminación:** catálogos y borradores sin dependencias pueden borrarse; los movimientos financieros se anulan con historial. El resumen contractual se calcula y consulta, sin edición manual. Estas excepciones al CRUD deben explicarse al docente; su aceptación no está confirmada.
- **Código del vehículo:** se conserva el correlativo global `CodigoGarantia`, asociado a marca y línea, y el VIN único. No se añade una secuencia por marca. Se documenta como interpretación del equipo del texto del enunciado.
- **Referencias:** el borrador puede estar incompleto; presentar una solicitud completa requerirá tres referencias distintas y completas, y aprobar volverá a validarlas. Actualmente SQL valida al aprobar; falta implementar el paso de presentación en el módulo correspondiente.

## 6. Qué produjo esta fase y qué no demuestra

Produjo acuerdos para orientar el modelo y las pruebas: cálculo financiero, contactos, fiadores, vencimientos, pagos y alcance de la interfaz. No produjo por sí sola la API financiera, las pantallas ni evidencia de que se hubiera instalado la versión V2.

La conversación contiene propuestas numeradas cuyo texto original completo no está disponible aquí. No se reconstruyen números o respuestas faltantes por suposición: se registran las reglas recuperables y respaldadas por los archivos.

## 7. Fuentes y continuidad

- Enunciado PDF y conversación del proyecto: requisitos, decisiones de Diego y revisiones posteriores.
- Primera entrega SQL: antecedente de 25 tablas disponible en el historial de Git; retirado de la copia actual para evitar confundirlo con el instalador final.
- [Entrega SQL V2](../database/v2/entrega/LEEME.md): instalación vigente.
- [Fase 1](FASE_1_Preparacion_del_Proyecto.md): entorno y forma de trabajo.
- [Modelo ER](FASE_2_Modelo_ER.md) y [SQL implementado](FASE_4_SQL_Implementado.md): evolución posterior.

La política de PDF de cierre está en [Informes por fase](INFORMES_POR_FASE.md). Este archivo es una reconstrucción editable; no afirma que ya exista un PDF retrospectivo de la fase 0.
