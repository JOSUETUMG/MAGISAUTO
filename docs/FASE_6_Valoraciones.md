# Fase 6 - Valoraciones de vehículos

Avance local en `pruebas-diego`. La fase 6 continúa abierta.

## Objetivo

Vehículos ahora permite abrir el historial de valoraciones de una garantía. Cada fila muestra fecha, valor original, porcentaje de depreciación, valor calculado y observación. El valor calculado afecta los reportes de garantía al corte, pero nunca modifica la deuda ni las cuotas del crédito.

La valoración inicial la genera SQL al aprobar un crédito. Desde el historial se puede registrar una valoración posterior para un vehículo con crédito aprobado. Los registros vinculados a un contrato quedan disponibles solo para consulta: SQL protege su edición y eliminación para conservar el historial.

## Implementación

La API usa exclusivamente los procedimientos existentes `api.Depreciacion_Listar`, `api.Depreciacion_Insertar`, `api.Depreciacion_Actualizar` y `api.Depreciacion_Eliminar`. No se añadieron tablas, procedimientos ni migraciones SQL.

| Ruta | Uso |
| --- | --- |
| `GET /api/valoraciones` | Lista el historial; permite `codigoGarantia` y `criterio`. |
| `GET /api/valoraciones/{codigo}` | Consulta una valoración. |
| `POST /api/valoraciones` | Registra una valoración posterior para un vehículo con crédito aprobado. |
| `PUT /api/valoraciones/{codigo}` | Actualiza solo si SQL permite el cambio. |
| `DELETE /api/valoraciones/{codigo}` | Elimina solo si SQL permite el cambio. |

La pantalla presenta los porcentajes como unidades humanas: `15` equivale a `15%`. SQL conserva el valor como fracción (`0.15`). El porcentaje debe quedar entre 15% y 20%, el importe debe ser positivo con hasta dos decimales y la fecha no puede ser futura.

## Guía de prueba manual

1. Iniciar la aplicación y abrir **Vehículos**.
2. En un vehículo con crédito aprobado, elegir **Valoraciones**.
3. Comprobar la valoración inicial, sus importes y el aviso de historial protegido.
4. Registrar una valoración posterior con fecha actual, porcentaje entre 15% y 20% y observación.
5. Verificar que aparece en el historial y que el sistema no permite editarla ni eliminarla cuando pertenece al contrato.
6. Revisar el reporte de garantía a una fecha de corte posterior; debe usar la última valoración, sin alterar deuda ni cuotas.

## Verificación técnica

Resultado del 15/10/2026: **42 comprobaciones correctas**, conservadas en el archivo de evidencia. Compilación y sintaxis JavaScript correctas. No se requieren nuevas migraciones SQL.

La compilación de la API terminó con cero errores y cero advertencias. El ensayo `scripts/Verificar-Valoraciones.ps1` se ejecuta exclusivamente contra `MAGISAUTO_ValidacionV2`. Tras habilitar el acceso de red local, pudo conectarse: el impedimento inicial no era un error de los datos del proyecto.

El ensayo registra una valoración temporal propia, verifica el cálculo exacto Q85,000 al 15% = Q72,250, búsquedas, filtros inválidos, validaciones, protección de edición/eliminación y conservación del crédito completo, incluida su comisión y sus cuotas. Comprueba también los reportes 16/17. Retira únicamente su registro de prueba y compara las 26 tablas mediante hashes de sus datos ordenados por clave. Los correlativos pueden avanzar. Resultado de la ejecución: `evidencias/fase-6-valoraciones.json`.

## Evidencia manual confirmada por Diego

El 15 de octubre de 2026 Diego confirmó que pasaron las once pruebas de búsqueda, recuperación del listado, búsqueda sin coincidencias, campos obligatorios, fecha futura, porcentajes fuera de rango, importes inválidos, cancelación, protección, persistencia/formato y ventana estrecha. La confirmación textual no equivale a una ejecución automatizada del navegador ni a una prueba en móvil real.

Las capturas muestran el vehículo 14, una valoración inicial del 12/10/2026 de Q100,000 al 15% = Q85,000 y otra del 15/10/2026 de Q85,000 al 15% = Q72,250. Ambas aparecen protegidas. La segunda permanece como dato académico de prueba en la base del usuario; el ensayo automático no la borra.

En el reporte 16, el capital pendiente se mantuvo en Q78,708.91; el margen pasó de Q6,291.09 a -Q6,458.91 y el indicador de insuficiencia pasó de No a Sí. En el reporte 17 se conservaron precio Q100,000, enganche Q20,000, monto financiado Q80,000, intereses Q5,519.56 y total contractual Q87,739.56. El valor depreciado pasó de Q85,000 a Q72,250 y la pérdida estimada de Q15,000 a Q27,750. Se solicitaron cortes 14/10 y 15/10, aunque los controles de fecha de corte no aparecen en las capturas recortadas.

## Alcance y límites

- El PDF menciona 15–20% para la depreciación inmediata. El esquema SQL existente aplica ese intervalo a todas las valoraciones; conservarlo en seguimientos es una limitación de esta versión, no una regla posterior expresamente exigida por el docente. El ejemplo de seguimiento no establece una periodicidad ni un descuento automático.
- La restricción de registrar seguimientos únicamente después de un crédito aprobado pertenece a la API. Los SP genéricos conservan su comportamiento anterior. La edición y eliminación de registros sin contrato siguen expuestas; este ensayo se concentra en el recorrido contractual.
- Los listados cargan el historial y filtran en la API; no hay paginación. El ensayo usa una valoración contractual preexistente en la copia aislada y debe ejecutarse sin otros usuarios modificando esa copia.
- No se modificaron archivos SQL, permisos, configuraciones privadas ni bases de compañeros. La publicación del código no actualiza automáticamente sus ramas.
