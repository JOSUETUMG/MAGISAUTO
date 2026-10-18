# Comprobaciones de la muestra final — 17 de octubre de 2026

Base utilizada: **MAGISAUTO_Entrega_Final**. Muestra: **2026-10-16-v1**. Este registro documenta comprobaciones ya realizadas; no implica una nueva carga ni una nueva ejecución de pruebas.

## Instalación y conexión

| Comprobación | Resultado | Evidencia |
| --- | --- | --- |
| Carga de datos | Datos de entrega instalados: 6 créditos, 144 cuotas, 9 pagos y 1 pago anulado | Captura de SSMS enviada por Diego; muestra base MAGISAUTO_Entrega_Final y campo RespaldoAnterior |
| Acceso de la aplicación | Conexión abierta correctamente y presencia de los seis créditos MGA-2026-001 a MGA-2026-006 comprobada antes de cambiar la configuración | Ejecución de scripts/Conectar-EntregaFinal.ps1 registrada en el chat |
| Cambio de conexión | Configuración privada actualizada a MAGISAUTO_Entrega_Final, con copia previa de la configuración | Resultado del mismo script; no se incorporan credenciales a este documento |

La captura de carga corresponde a `0-clipboard-4bb3f021-971c-43a2-b8a6-3880fe039306.png`, adjunta al chat. Las imágenes permanecen como evidencia de la conversación; sus archivos temporales no se consideran archivos permanentes del repositorio.

## Comprobaciones automáticas realizadas

- Los **20 procedimientos de reportes** se ejecutaron correctamente en SQL Server con la cuenta limitada de la aplicación, mediante consultas de lectura.
- Fecha de corte: **16/10/2026**. Período de reportes: **01/06/2026 a 16/10/2026**; cumpleaños: octubre de 2026; estado de cuenta: cliente 1; plan: MGA-2026-001.
- Cartera en mora: MGA-2026-003 y MGA-2026-002, sin incluir el caso al día.
- Intereses: cinco contratos aprobados; se comprobaron las igualdades entre intereses del contrato, devengados, futuros, cobrados y pendientes. MGA-2026-004 presenta Q562.50 de intereses cobrados anticipados.
- Abonos parciales: MGA-2026-002 y MGA-2026-004.
- Anulaciones: un pago de Q1,000, correspondiente a MGA-2026-005.

Resultados detallados locales: `artifacts/datos-entrega/reportes-verificados.json`. Estado resumido de entrega: `database/final/validacion-contenido.json`.

**Límite:** estas ejecuciones verifican los procedimientos SQL, no una prueba HTTP completa ni la inspección visual de los 20 reportes. El intento HTTP desde una segunda sesión no terminó y no se cuenta como aprobado.

## Confirmaciones visuales de Diego

| Pantalla | Resultado confirmado | Tipo de evidencia |
| --- | --- | --- |
| Clientes | 6 clientes con nombres nuevos y expediente indicado como completo para revisión | Captura `codex-clipboard-ea83b07e-931e-47c0-bdd6-ab650e58fba3.png` |
| Créditos | MGA-2026-001 a MGA-2026-006; cinco vigentes y uno en borrador. Montos financiados: Q120,000, Q100,000, Q88,000, Q108,000, Q84,000 y Q128,000 | Captura `codex-clipboard-9b1dcba2-7378-4e29-a556-7d58449dd2fd.png` |
| Cartera en mora | Al 16/10/2026: María, MGA-2026-003, 62 días, 3 cuotas, Q7,620.12; Carlos, MGA-2026-002, 11 días, 1 cuota, Q1,785.18 | Captura `codex-clipboard-b87701e8-6be0-4b46-a5d3-d879abe21089.png` |
| Pagos anulados | Aparece el pago de Q1,000 de MGA-2026-005 (Sofía), consultado para 01/06/2026 a 16/10/2026 | Confirmación textual de Diego: «si aparece»; sin captura adicional |

Queda completada la revisión visual de **estas cuatro pantallas**. No se extiende esta confirmación a otras pantallas u operaciones no revisadas.

## Alcance de este registro

Este cierre documental no modifica datos, procedimientos ni conexiones. No registra un commit ni una publicación en GitHub y no certifica por sí solo todos los requisitos del proyecto. La actualización de otros documentos de entrega y su publicación son pasos separados.

## Actualización de instrucciones de entrega

Se actualizaron README, guía de instalación, ejemplos de conexión y los valores predeterminados de los preparadores: aplicación y entrega en MAGISAUTO_Entrega_Final; pruebas aisladas en MAGISAUTO_ValidacionV2. No se crearon ni eliminaron bases. El cambio posterior de documentación no altera los datos de negocio.

Comprobar-Equipo.ps1 se adaptó a la muestra final y se ejecutó en lectura: conexión final correcta, cinco marcas y estado de cuenta del cliente 1 al 16/10/2026 con un crédito, 24 cuotas y tres pagos. Se verificó la sintaxis de los tres scripts de preparación/comprobación editados.

Se actualizaron los dos PDF técnicos manteniendo las ocho páginas originales de Dylan: versión resumida de 14 páginas y completa de 40. Se revisó el formato renderizado de las páginas modificadas. Los ejemplos financieros utilizan MGA-2026-004 y las instrucciones incluyen el instalador final consolidado; 001 y 002 no se vuelven a aplicar. Los documentos y ensayos históricos conservan sus antecedentes.

Esta actualización permanece local; no se creó commit ni se realizó push.
