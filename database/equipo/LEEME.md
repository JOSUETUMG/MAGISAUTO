# Copia de MAGISAUTO para el equipo

Esta es la copia con **estructura y datos ficticios** de `MAGISAUTO_Proyecto_V2`, preparada el 13 de octubre de 2026. Diego confirmó que las personas y contactos son datos de prueba. Cada compañero instala una base independiente: no se conecta a la computadora de Diego ni sincroniza datos entre equipos.

## Archivo que deben utilizar

`MAGISAUTO_Equipo_2026-10-13.sql`: instalador completo y autónomo, con 26 tablas, 151 procedimientos, cuatro vistas, dos funciones y 81 registros en total. Incluye los catálogos, parámetros, personas, referencias, vehículo, crédito, 12 cuotas, tres pagos y la anulación. Incluye las definiciones programables vigentes de la fuente. La estructura de tablas parte del instalador 2.1; las columnas se verifican por nombre/tipo, pues el orden físico de columnas de Crédito puede diferir de una base actualizada por migración.

**No ejecutar primero el instalador vacío, ni el SQL antiguo de `database/entrega-companero`, ni la migración de presentación después de esta copia.** Este archivo ya incluye esa funcionalidad. No es un respaldo de logins, contraseñas, trabajos del servidor ni de otras bases.

1. Abrir SSMS y conectarse al motor SQL Server 2022 o 2025 como administrador local.
2. Abrir el archivo completo. El destino predeterminado es `MAGISAUTO_Equipo`.
3. Si necesitan otro nombre, cambiar únicamente `DECLARE @Base ...` por un nombre nuevo que empiece por `MAGISAUTO_`.
4. Ejecutar TODO con F5, sin seleccionar fragmentos y sin modo SQLCMD. Si SSMS pregunta por los finales de línea, aceptar Windows (CRLF).
5. Verificar el mensaje de copia instalada y tres recibos. Actualizar el explorador de bases.

Si el destino existe, se detiene sin modificarlo. No borrar una base para resolver ese aviso: comprobar si ya se instaló o elegir un nombre nuevo. La creación de la base queda fuera de la transacción de objetos/datos; si esa transacción falla, puede quedar una base nueva vacía para revisar. No se elimina automáticamente.

## Conectar Visual Studio

Seguir [la guía completa de instalación](../../docs/INSTALACION_EQUIPO.md). El proyecto ya utiliza el archivo local de configuración: no se requiere editar C# para cambiar de servidor. Cada equipo genera su propia clave mediante `Preparar-Equipo.ps1` y ejecuta el SQL privado de habilitación; ese paso requiere modo mixto de SQL Server.

## Cifras iniciales de control

- Crédito `PRUEBA-CREDITO-01`, cliente 6, vendedor 16 y fiador 4.
- Recibos 1 (Q1,000) y 3 (Q500) efectivos; recibo 2 (Q6,311.63) anulado.
- Pagado efectivo Q1,500; capital pendiente Q78,708.91; saldo contractual Q86,239.56.
- Primera cuota pendiente Q5,811.63; comisión efectiva Q30. El siguiente recibo disponible es 4.
- En reportes, usar corte/período del **13 de octubre de 2026** para reproducir las capturas. La mora cambia según el corte elegido.

Ver [manifest y conteos](manifest.json), [evidencia de verificación](../../docs/evidencias/paquete-equipo.json) y [pruebas manuales de reportes](../../docs/PRUEBAS_MANUALES_REPORTES_2026-10-13.md). Los datos posteriores de cada compañero serán propios; volver a ejecutar el instalador no actualiza ni reinicia su base.
