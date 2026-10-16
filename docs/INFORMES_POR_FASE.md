# Informes de cierre por fase

Acuerdo solicitado por Diego el 10 de octubre de 2026: al terminar cada fase, entregar un PDF que permita al equipo estudiar lo realizado y explicar el proyecto.

## Contenido de cada PDF

Actualización del 15 de octubre: Diego confirmó las pruebas manuales de consultas y eliminación
controlada, incluida la referencia de prueba y navegación estrecha/teclado. Se consolidó la
[matriz C05/C06](FASE_6_Cierre_C05_C06.md) con sus límites. Evidencia: 86 comprobaciones de
consultas/eliminación (incluyen las 69 iniciales) y 9 de excepciones financieras. El nuevo ensayo
bloqueó las tres escrituras manuales de cuotas de un contrato aprobado y liquidado y conservó
las 26 tablas de la base aislada. Sin cambios SQL ni migración; actualización local, sin nueva
publicación. El remanente se concentra en C07/Reportes, la mejora de mora y la entrega.
No repetir los recorridos manuales ya confirmados; ver la lista acotada del informe.

1. Objetivo y alcance de la fase, relacionados con el enunciado del proyecto.
2. Resumen acumulado de lo construido hasta ese momento.
3. Funcionalidades nuevas, cambios a funcionalidades anteriores y motivo de cada cambio.
4. Archivos, clases, métodos, rutas de la API y objetos SQL agregados o modificados, con ubicaciones verificadas.
5. Recorrido de los datos: pantalla → API → procedimiento → base de datos, con ejemplos del módulo.
6. Reglas y validaciones, diferenciando requisitos del PDF, decisiones del equipo y aclaraciones pendientes con el ingeniero.
7. Pruebas ejecutadas, evidencia real, resultados y limitaciones. Separar pruebas automáticas, revisión visual y pruebas hechas por Diego.
8. Instrucciones para abrir y probar la entrega desde Visual Studio y SSMS cuando corresponda.
9. Lista de lo terminado, pendientes y siguiente fase. Indicar rama, base utilizada y si los cambios están locales o publicados.

Usar español claro, ejemplos y capturas cuando estén disponibles. Omitir contraseñas, cadenas privadas y datos personales de prueba innecesarios. Validar visualmente el PDF antes de entregarlo y conservar una fuente editable en la documentación.

## Momento de entrega

El informe se entrega al cerrar una fase. Un módulo terminado dentro de una fase se documenta como avance; no equivale a declarar toda la fase terminada. Si el usuario solicita un informe antes del cierre, identificarlo como informe de avance.

La fase 6 sigue abierta: Marcas, Líneas y Agencias implementadas, con pruebas manuales confirmadas por Diego para las operaciones documentadas de cada módulo. Vendedores cuenta con pruebas HTTP/SQL y confirmación manual de persistencia, búsqueda por nombre/agencia y eliminación; el alcance y los límites están en su documento. Los ejercicios de clase en MAGISAUTO_Complemento no son parte de la implementación del proyecto.

Clientes, contactos y referencias cuentan con pruebas HTTP/SQL y revisión manual de Diego para el guardado por etapas, edición, búsquedas, apertura, listado y cancelación/bloqueo de eliminación, según su documento. El nuevo aviso específico de eliminación bloqueada también fue confirmado mediante captura. El indicador de expediente completo no presenta ni aprueba créditos: el paso formal de presentación con validación SQL sigue pendiente del módulo Créditos.

Fiadores cuenta con 70 comprobaciones HTTP/SQL y 62 de Clientes como regresión. Diego comprobó mediante capturas y confirmaciones el registro por etapas, la edición, búsquedas, Ver todos, cancelación de eliminación y eliminación sin créditos. La reutilización de Persona y protección por créditos cuentan con evidencia automática; no se declaran comprobadas manualmente. El alcance está en FASE_6_Fiadores.md y todavía no incluye asignación a créditos.

Vehículos cuenta con 80 comprobaciones HTTP/SQL y 42 de Líneas como regresión. Diego confirmó las operaciones principales, los filtros, el rechazo de VIN duplicado, la cancelación y conservación y la eliminación final. Sus reglas, archivos, API, límites y guía de prueba están en FASE_6_Vehiculos.md. La fase 6 continúa abierta; no se ha generado su PDF de cierre.


Créditos incorpora borradores con fiadores, presentación SQL del expediente, aprobación con cuotas, consulta y anulación con motivo. Ver [documentación detallada](FASE_6_Creditos.md). La instalación del parche en la base del proyecto y la revisión manual permanecen pendientes; la fase 6 sigue abierta.

Créditos superó 57 comprobaciones HTTP/SQL en la base aislada, conservando sus registros anteriores; evidencia en `evidencias/fase-6-creditos.json`. La migración aditiva es repetible y se mantiene pendiente de instalar en el proyecto.


Actualización del 13 de octubre: Diego confirmó instalación del parche de Créditos y el recorrido manual hasta aprobación, consulta, búsquedas y Ver todos. El crédito de prueba se conserva vigente. Se agrega [Pagos y abonos](FASE_6_Pagos.md), cuyo recorrido manual principal y vista previa de impresión se completaron después, como detalla el informe enlazado al final. La fase 6 no se cierra todavía.

Pagos superó **126 comprobaciones HTTP/SQL** en la base aislada, incluyendo concurrencia, liquidación, anulación y conservación de registros previos. Evidencia: `evidencias/fase-6-pagos.json`. El ensayo utilizó la opción local explícita sin TLS por una limitación del proceso restringido; la configuración del proyecto permanece intacta. El recorrido manual posterior se documenta a continuación.

## Resultados manuales de Pagos — 13 de octubre de 2026

[Informe completo de pruebas](PRUEBAS_MANUALES_PAGOS_2026-10-13.md): 15 casos, 16 capturas originales, conciliación de los tres recibos y límites de la evidencia. Incluye abonos, rechazo de sobrepago, cuota pagada, observación, anulación y restauración, ACH con referencia, búsqueda, Ver todos y vista previa de impresión. «Ver todos» tiene confirmación textual; no se afirma que se guardó un PDF ni que se imprimió en papel.

El crédito de prueba permanece VIGENTE con Q1500 efectivos y Q86239.56 por cobrar. La siguiente prioridad es el módulo de consultas/reportes. El ingeniero reforzó el uso de SP para todo SQL y un módulo amplio de consultas; no confirmó las interpretaciones financieras pendientes. La fase 6 continúa abierta; este avance no sustituye su PDF acumulado de cierre.

## Avance de Consultas y reportes — 13 de octubre de 2026

[Documentación del módulo](FASE_6_Reportes.md): 20 SP integrados, filtros tipados, resultados múltiples, nulos, cortes históricos y cartas individuales. Cuenta con 134 comprobaciones HTTP/SQL y 15 de formato; los registros previos de la base aislada se conservaron. No hay revisión visual automática aprobada: Edge no pudo abrir la página en el entorno restringido. Actualización: Diego completó el recorrido de las 20 consultas; [24 casos y 40 capturas](PRUEBAS_MANUALES_REPORTES_2026-10-13.md) documentan sus resultados y límites. Quedan teclado, móvil, respuestas tardías y el resto del alcance de fase 6; no se genera todavía su PDF de cierre.

Acuerdo posterior con Diego: antes de la entrega se comentarán las funciones/procedimientos y líneas clave de SQL y código (propósito, parámetros, cálculos, validaciones, transacciones y decisiones), y se preparará al equipo para entender y defender el proyecto. Este trabajo general queda para el cierre, después de completar y probar los módulos.

## Avance de Catálogos auxiliares — 14 de octubre de 2026

[Documentación del bloque](FASE_6_Catalogos_Auxiliares.md): Departamentos, Municipios y tipos de teléfono, dirección, garantía, referencia y pago. Se reutilizan 35 SP existentes sin migración. La compilación y 242 comprobaciones HTTP/SQL en la base aislada resultaron correctas; las 26 tablas conservaron sus datos anteriores. La revisión en navegador no pudo ejecutarse por restricciones del entorno y queda pendiente junto con su recorrido manual. Este avance local no se ha publicado y no cierra la fase 6.

Actualización posterior: Diego completó el recorrido manual básico de Auxiliares, documentado
con sus límites en el informe del bloque: carga de los siete catálogos, operaciones de ensayo,
dependencias, búsqueda vacía, teclado y ventana estrecha. No se acredita una prueba en móvil real.

## Avance de Parámetros y comisión — 15 de octubre de 2026

[Documentación y guía](FASE_6_Parametros_y_Comision.md): configuraciones inactivas editables,
activación atómica, conservación de versiones utilizadas y comisión específica por crédito.
El manejo mensual sigue fijo en Q25. Se reutilizan SP existentes, sin nuevos archivos SQL.
Compilación sin errores ni advertencias; **134 pruebas nuevas y 57 de regresión de Créditos**
correctas. La base aislada conservó sus registros anteriores. La revisión visual del nuevo bloque
queda pendiente; sus cambios siguen locales y la fase 6 continúa abierta.

## Actualización de Parámetros y avance de Valoraciones — 15 de octubre de 2026

Diego completó después el recorrido manual de Parámetros: consulta, copia, edición persistente, validación de enganche, cancelación y confirmación de activación, comisión propia del crédito, protección por uso, limpieza, búsqueda y ventana estrecha. Catálogos y Parámetros fueron publicados en `pruebas-diego`, commit `b4eb4f0`; las notas anteriores describen su estado histórico.

[Valoraciones](FASE_6_Valoraciones.md) incorpora historial por vehículo, búsquedas y registro posterior con protección contractual. **42 comprobaciones HTTP/SQL correctas** en `MAGISAUTO_ValidacionV2`, comparación del crédito completo y de los reportes 16/17, y limpieza verificada de las 26 tablas. Compilación sin errores ni advertencias; evidencia en `evidencias/fase-6-valoraciones.json`.

Diego confirmó las once pruebas manuales y aportó capturas de los reportes. La valoración académica de Q72,250 permanece en su base, protegida por el contrato. El informe distingue esta evidencia de las pruebas automáticas, del alcance limitado del rango SQL 15–20% para seguimientos y de una prueba en móvil real. Valoraciones queda preparado localmente para publicación. La fase 6 continúa abierta: faltan revisar las demás brechas de cobertura y completar la integración documental del equipo.
