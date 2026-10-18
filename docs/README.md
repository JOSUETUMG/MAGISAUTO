# Documentación de MAGIS-AUTO

Orden recomendado para estudiar el proyecto. Las fases 0 y 1 se reconstruyeron el 11 de octubre de 2026; sus documentos separan los antecedentes de los avances posteriores. Una fase documentada no significa que todos los módulos de la aplicación estén terminados.

| Orden | Documento | Qué explica |
| --- | --- | --- |
| 0 | [Requisitos y acuerdos](FASE_0_Requisitos_y_Acuerdos.md) | Enunciado, decisiones financieras, ejemplos y aclaraciones posteriores. |
| 1 | [Preparación del proyecto](FASE_1_Preparacion_del_Proyecto.md) | Herramientas, solución inicial, ramas, bases separadas y evidencia histórica. |
| 2 | [Modelo ER](FASE_2_Modelo_ER.md) | Entidades y relaciones; documento histórico del modelo de 25 tablas. |
| 3 | [Modelo relacional y 3FN](FASE_3_Modelo_Relacional_3FN.md) | Claves, restricciones, normalización y ajustes del modelo. |
| 4 | [SQL implementado](FASE_4_SQL_Implementado.md) | Versión V2 de 26 tablas, procedimientos, reportes y validaciones. |
| 5 | [Conexión de la API](FASE_5_Conexion_API.md) | Acceso real a SQL, permisos de aplicación y pruebas. |
| 6 | [Marcas](FASE_6_Marcas.md), [Líneas](FASE_6_Lineas.md), [Agencias](FASE_6_Agencias.md), [Vendedores](FASE_6_Vendedores.md), [Clientes](FASE_6_Clientes.md), [Fiadores](FASE_6_Fiadores.md) , [Vehículos](FASE_6_Vehiculos.md), [Créditos](FASE_6_Creditos.md) [Pagos](FASE_6_Pagos.md) y [Consultas y reportes](FASE_6_Reportes.md) | Pantallas, operaciones, validaciones y pruebas de estos módulos. La fase continúa abierta. |

## Revisión actual contra el enunciado

- [Correcciones posteriores a la auditoría](CIERRE_TECNICO_2026-10-16.md): mantenimiento independiente, cuotas/resúmenes de borrador, devengo mensual, migración 002 instalada y confirmaciones manuales de intereses e impresión. Consultar este documento para el estado más reciente.

- [Auditoría detallada del 16 de octubre de 2026](REVISION_FINAL_CONTRA_PDF_2026-10-16.md): requisitos completos, matriz actual de las 26 entidades, 20 reportes, pruebas nuevas y excepciones pendientes de aceptación. Distingue este estado de los documentos históricos de fases anteriores.

## Instalación para compañeros

- [Instalar base con datos y conectar Visual Studio](INSTALACION_EQUIPO.md).
- [Guía de tareas y Git (PDF)](equipo/MAGISAUTO_Guia_de_trabajo_equipo_y_Git.pdf).
- [Verificación del paquete](PAQUETE_EQUIPO_2026-10-13.md).

## Decisiones vigentes y evidencias

- [Diseño común y acciones de las 20 consultas](FASE_6_Diseno_y_Acciones_Reportes.md): menú agrupado, paleta del logo, cierres, detalle de mora y plan; 134 pruebas HTTP/SQL y 198 DOM, revisión visual real pendiente.

- [Cierre del bloque C05/C06 y pendientes acotados](FASE_6_Cierre_C05_C06.md): pruebas manuales confirmadas, matriz de entidades y operaciones financieras, ensayo de bloqueos SQL e impacto para el equipo.

- [Consultas de personas y vínculos](FASE_6_Consultas_Integradas.md): seis consultas y eliminación controlada, recorrido manual confirmado; 86 comprobaciones automáticas; sin cambios SQL.

- [Parámetros y comisión — avance del 15 de octubre](FASE_6_Parametros_y_Comision.md): versiones de configuración y porcentaje pactado por crédito, conservación del historial y pruebas aisladas.
- [Valoraciones de vehículos — avance del 15 de octubre](FASE_6_Valoraciones.md): historial, registro posterior y protección contractual, pruebas aisladas y recorrido manual confirmado por Diego.
- [Catálogos auxiliares — avance del 14 de octubre](FASE_6_Catalogos_Auxiliares.md): siete mantenimientos con 242 comprobaciones HTTP/SQL y recorrido manual básico confirmado después por Diego; sin cambios de SQL.
- [Auditoría inicial de cobertura](AUDITORIA_COBERTURA_2026-10-14.md): fotografía del commit anterior al avance de catálogos auxiliares.

- [Pruebas manuales de Reportes del 13 de octubre](PRUEBAS_MANUALES_REPORTES_2026-10-13.md): 20 consultas, casos límite y capturas originales.

- [Pruebas manuales de Pagos del 13 de octubre](PRUEBAS_MANUALES_PAGOS_2026-10-13.md): recorrido completo, capturas originales, importes conciliados y pendientes.

- [Decisiones de la revisión del PDF](DECISIONES_REVISION_PDF.md): precisiones del 11 de octubre sobre referencias, total recaudable, anulaciones y código del vehículo. Complementan y actualizan los puntos indicados de los documentos históricos.
- [Evidencias](evidencias): resultados guardados de las pruebas; no representan nuevas ejecuciones cada vez que se leen.
- [Informes por fase](INFORMES_POR_FASE.md): acuerdo de entregar PDF al cerrar cada fase. Este índice no certifica que ya estén generados todos los PDF.
- [README del proyecto](../README.md): instrucciones actuales para abrir, ejecutar y configurar otra máquina.
- [Entrega SQL vigente](../database/final/LEEME.md): instalador consolidado y muestra de entrega. Los paquetes anteriores se conservan como antecedentes.

Cada documento debe distinguir requisitos del docente, decisiones del equipo, comportamiento implementado y pendientes. Las interpretaciones del equipo no equivalen a aprobación del docente. Los cambios locales solo aparecerán en GitHub después de su publicación.

## Preparación de la entrega final

- [SQL consolidado e instrucciones](../database/final/LEEME.md): modelo con 001 y 002 integradas y muestra coherente de 350 filas. Base única elegida: MAGISAUTO_Entrega_Final. Carga confirmada por captura, conexión cambiada y 20 reportes SQL ejecutados con la cuenta API el 17/10/2026. Cuatro pantallas confirmadas visualmente por Diego; ver el registro de comprobaciones.
- [Recorrido breve para la demostración](GUION_DEMOSTRACION_FINAL.md): ayuda de 7 a 10 minutos, con datos de referencia y respuestas para la defensa.

- [Comprobaciones de la muestra final del 17 de octubre](COMPROBACIONES_ENTREGA_FINAL_2026-10-17.md): instalación, conexión, 20 reportes SQL y cuatro confirmaciones visuales, con sus evidencias y límites.

## Organización vigente de bases

Solo dos bases de uso activo: **MAGISAUTO_Entrega_Final** (aplicación y entrega) y **MAGISAUTO_ValidacionV2** (ensayos aislados). MAGISAUTO_Proyecto_V2 y otras copias permanecen como antecedentes; no se usan ni se eliminan en este cambio.

Documentación técnica actualizada: [versión resumida, 14 páginas](../output/pdf/DocumentacionSQL_Resumida.pdf) y [consulta completa, 40 páginas](../output/pdf/DocumentacionSQL_Completada.pdf). Ambas usan los nuevos casos de entrega y la organización de dos bases activas.
