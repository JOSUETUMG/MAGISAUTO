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
| 6 | [Marcas](FASE_6_Marcas.md), [Líneas](FASE_6_Lineas.md), [Agencias](FASE_6_Agencias.md), [Vendedores](FASE_6_Vendedores.md), [Clientes](FASE_6_Clientes.md), [Fiadores](FASE_6_Fiadores.md) , [Vehículos](FASE_6_Vehiculos.md), [Créditos](FASE_6_Creditos.md) y [Pagos](FASE_6_Pagos.md) | Pantallas, operaciones, validaciones y pruebas de estos módulos. La fase continúa abierta. |

## Decisiones vigentes y evidencias

- [Pruebas manuales de Pagos del 13 de octubre](PRUEBAS_MANUALES_PAGOS_2026-10-13.md): recorrido completo, capturas originales, importes conciliados y pendientes.

- [Decisiones de la revisión del PDF](DECISIONES_REVISION_PDF.md): precisiones del 11 de octubre sobre referencias, total recaudable, anulaciones y código del vehículo. Complementan y actualizan los puntos indicados de los documentos históricos.
- [Evidencias](evidencias): resultados guardados de las pruebas; no representan nuevas ejecuciones cada vez que se leen.
- [Informes por fase](INFORMES_POR_FASE.md): acuerdo de entregar PDF al cerrar cada fase. Este índice no certifica que ya estén generados todos los PDF.
- [README del proyecto](../README.md): instrucciones actuales para abrir, ejecutar y configurar otra máquina.
- [Entrega SQL vigente](../database/v2/entrega/LEEME.md): instalación V2. El paquete de `database/entrega-companero` se conserva como antecedente, no como versión actual.

Cada documento debe distinguir requisitos del docente, decisiones del equipo, comportamiento implementado y pendientes. Las interpretaciones del equipo no equivalen a aprobación del docente. Los cambios locales solo aparecerán en GitHub después de su publicación.
