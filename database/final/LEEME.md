# SQL final de MAGIS-AUTO

La base elegida para la aplicación y la entrega es **MAGISAUTO_Entrega_Final**. Las otras bases se conservan como antecedentes; no se eliminan ni se necesitan para esta entrega.

**Estado al 17/10/2026:** carga nueva confirmada por captura de SSMS (6 créditos, 144 cuotas, 9 pagos y 1 anulado). Conexión privada cambiada y verificada contra MAGISAUTO_Entrega_Final. Los 20 procedimientos de reportes se ejecutaron con la cuenta API; comprobados mora, abonos, anticipos y anulación. Confirmación visual de Clientes, Créditos y Cartera en mora mediante capturas; Pagos anulados confirmado por Diego en el chat. Véase `docs/COMPROBACIONES_ENTREGA_FINAL_2026-10-17.md`. No repetir la carga.

## Contenido

`MAGISAUTO_Final.sql` instala desde cero el modelo con 001, 002 y 003 integradas: 26 tablas, 154 procedimientos API, cuatro vistas, dos funciones y 20 reportes. Incluye 350 filas ficticias coherentes, seis clientes, ocho vehículos, seis créditos, 144 cuotas y nueve pagos; uno anulado.

Nombres, documentos, contactos y vehículos son ficticios. Los correos usan example.invalid. Los planes y pagos se generan con los procedimientos del sistema. Las fechas históricas de presentación y anulación de esta muestra se fijan explícitamente, como explican los comentarios SQL.

| Crédito | Cliente | Caso al corte 16/10/2026 |
| --- | --- | --- |
| MGA-2026-001 | Ana Lucía Morales López | Al día y valoración posterior |
| MGA-2026-002 | Carlos Eduardo Méndez Ruiz | Abono parcial |
| MGA-2026-003 | María Fernanda Castillo Paz | Cuotas atrasadas |
| MGA-2026-004 | José Antonio Herrera Díaz | Pago anterior al primer vencimiento |
| MGA-2026-005 | Sofía Isabel Ramírez Luna | Pago efectivo y otro anulado |
| MGA-2026-006 | Luis Fernando Aguilar Reyes | Borrador sin plan aprobado |

Usar corte **16/10/2026** y, para períodos, **01/06/2026 a 16/10/2026**. Otros cortes pueden mostrar resultados distintos.

## Actualizar la copia ya instalada de Diego

1. Detener la aplicación en Visual Studio.
2. Abrir en SSMS, con conexión administradora, `artifacts/acceso-local/ACTUALIZAR_ENTREGA_FINAL.sql`. Ejecutar todo con F5, sin seleccionar fragmentos. Es privado para la cuenta local existente; no se entrega ni publica.
3. Comprueba que la base conserva exactamente la muestra original. Hace respaldo completo COPY_ONLY con CHECKSUM y lo verifica antes de reemplazar datos. Muestra su ruta. Si la muestra cambió o falla el respaldo, se detiene. El reemplazo usa una transacción y comprobaciones financieras.
4. Debe terminar con **Datos de entrega instalados**, base final, **6 créditos, 144 cuotas, 9 pagos y 1 anulado**. Habilita la cuenta API existente mediante el rol limitado magis_api en esta base.
5. Ejecutar `scripts/Conectar-EntregaFinal.ps1`: comprueba acceso y seis créditos, respalda la configuración privada y cambia únicamente la base de conexión. Reiniciar la aplicación.
6. Ejecutar completo `VERIFICAR_INSTALACION.sql` sobre la base final y comprobar los reportes en la interfaz.

No repetir la carga tras registrar movimientos. `PREPARAR_DEMOSTRACION.sql` es el reemplazo público, sin asignación de cuenta local. `DATOS_DEMOSTRACION.sql` es un componente: **no ejecutarlo solo**.

## Instalar en otra computadora

Ejecutar completo `MAGISAUTO_Final.sql` como administrador en SSMS, sin modo SQLCMD. Crea MAGISAUTO_Entrega_Final y rechaza una base existente; no usarlo para actualizar la copia instalada. Resultado esperado: **Instalacion final completada**, con 26 tablas, 154 procedimientos API, cuatro vistas, dos funciones, 20 reportes y 350 filas.

Configurar acceso siguiendo `docs/INSTALACION_EQUIPO.md`, usando este instalador y MAGISAUTO_Entrega_Final. No ejecutar el paquete histórico ni migraciones adicionales sobre esta instalación. No compartir claves, appsettings.Local.json ni SQL privado de acceso.

La creación de la base ocurre antes de la transacción de objetos y datos. Un fallo puede dejar una base nueva vacía; no equivale a éxito ni se elimina automáticamente.

## Validación y reproducción

- `validacion-sintaxis.json`: análisis ScriptDom; no certifica ejecución en SQL Server.
- `validacion-contenido.json`: estado de carga y conexión, pendiente hasta comprobarlas.
- `VERIFICAR_INSTALACION.sql`: conteos, coherencia financiera, casos y los 20 reportes; espera la muestra sin movimientos adicionales.
- `manifest.json` y `SHA256SUMS.json`: inventario y huellas de los archivos.

Reproducir con `scripts/Preparar-DatosEntrega.py`, después `scripts/Preparar-SqlFinal.py` y finalmente `scripts/Verificar-SqlFinal.ps1`. No conectan ni modifican SQL Server. Código de referencia: b8c44aa, rama pruebas-diego.

Recorrido: `docs/GUION_DEMOSTRACION_FINAL.md`. Los ejemplos PRUEBA-CREDITO-01 y cifras de 81 filas en documentos anteriores son históricos. El manual de Josué debe usar los nuevos nombres y pantallas después de instalar estos datos.

## Organización vigente de bases

Solo dos bases de uso activo: **MAGISAUTO_Entrega_Final** (aplicación y entrega) y **MAGISAUTO_ValidacionV2** (ensayos aislados). MAGISAUTO_Proyecto_V2 y otras copias permanecen como antecedentes; no se usan ni se eliminan en este cambio.

## Actualización CRUD del 18/10/2026

La migración `database/v2/migraciones/003_CRUD_Entrega.sql` ya fue instalada por Diego en MAGISAUTO_Entrega_Final, según la captura de SSMS. No repetirla en esa copia. Las pruebas manuales de valoraciones y cancelación del borrado del recibo 9 fueron confirmadas el 18/10/2026. Solo cambia tres procedimientos; no vuelve a cargar datos. Para instalación nueva, el SQL final ya la incluye. Ver `docs/CRUD_ENTREGA_2026-10-18.md`: valoraciones previas editables y eliminación física de pagos anulados, con efecto en los reportes históricos.

## Correccion de instalacion nueva (18/10/2026)

El SQL definitivo retira la carga inicial duplicada que provocaba errores de clave en Departamento y Agencia. Su carga de objetos y datos coincide con R3, instalado correctamente por Josue con 350 filas y conexion de la aplicacion comprobada. Para nuevas instalaciones usar este MAGISAUTO_Final.sql; no usar los archivos temporales R2/R3 ni reinstalar las bases que ya funcionan. Evidencia detallada en `docs/CORRECCION_INSTALADOR_2026-10-18.md`.
