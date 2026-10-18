# Instalar la entrega y conectar MAGIS-AUTO

## Bases y archivos vigentes

Se usan solo dos bases activas: **MAGISAUTO_Entrega_Final** para la aplicación y entrega; **MAGISAUTO_ValidacionV2** para ensayos automatizados aislados. Para presentar o elaborar el manual basta la primera. Las bases anteriores son antecedentes, no pasos adicionales de instalación. No se eliminan automáticamente.

Compartir el repositorio de pruebas-diego cuando su publicación esté confirmada, `database/final/MAGISAUTO_Final.sql`, esta guía y la documentación técnica actualizada. No compartir appsettings.Local.json, claves, respaldos ni artifacts/acceso-local. Git descarga archivos, no instala ni sincroniza SQL Server.

## 1. Requisitos

Windows, SQL Server 2022 o 2025, SSMS, SDK .NET 10 y Visual Studio con desarrollo ASP.NET. SSMS no incluye el motor. Usar la instancia propia mostrada en SSMS, por ejemplo localhost o .\SQLEXPRESS. La cuenta SQL limitada de la aplicación requiere modo mixto. No usar sa como cuenta de la aplicación.

## 2. Obtener el proyecto

Usar la copia completa y actualizada de la rama pruebas-diego. No descartar cambios locales ni modificar main. La actualización de estos archivos es local hasta que se confirme el push; no asumir que GitHub ya los contiene.

## 3. Instalar la base final

1. Abrir `database/final/MAGISAUTO_Final.sql` en SSMS con conexión administradora.
2. Ejecutar TODO con F5, sin fragmentos ni modo SQLCMD. El destino es MAGISAUTO_Entrega_Final.
3. Esperar **Instalacion final completada**: 26 tablas, 154 procedimientos API, cuatro vistas, dos funciones, 20 reportes y 350 filas de muestra.
4. Seleccionar MAGISAUTO_Entrega_Final y ejecutar completo `database/final/VERIFICAR_INSTALACION.sql`. Espera la muestra inicial sin movimientos adicionales.

Las actualizaciones 001 y 002 ya están integradas: no ejecutarlas otra vez ni instalar el paquete histórico del equipo. Si la base final ya existe, el instalador se detiene. Comprobar su versión, sin crear una tercera base ni borrar datos. En Diego la nueva muestra ya se cargó y verificó; no repetir la carga. En otra computadora con una copia antigua, revisar su contenido y respaldarla antes de preparar una actualización específica.

## 4. Configurar una computadora nueva

Desde la raíz del repositorio:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/Preparar-Equipo.ps1 -Servidor "localhost" -Base "MAGISAUTO_Entrega_Final" -Usuario "magis_api_equipo"
```

Cambiar localhost por la instancia propia. Genera una clave aleatoria y dos archivos privados: appsettings.Local.json y artifacts/acceso-local/HABILITAR_API_LOCAL.sql. Ejecutar este último completo en SSMS como administrador en la misma instancia. Crea la cuenta limitada y su pertenencia a magis_api; no carga datos de negocio.

Si ya existe configuración o login, conservarlos y revisar su conexión. No regenerar claves ni sobrescribirlos a ciegas. Para la cuenta existente de Diego, Conectar-EntregaFinal.ps1 comprueba acceso y los seis créditos antes de cambiar solo la base; no crea permisos.

## 5. Comprobar y ejecutar

```powershell
powershell.exe -NoProfile -File scripts/Comprobar-Equipo.ps1
```

Solo lectura: confirma base final, marcas y estado de cuenta del cliente 1 al 16/10/2026 (un crédito, 24 cuotas y tres pagos). Los movimientos posteriores pueden cambiar esa fotografía.

Abrir MAGISAUTO.sln, seleccionar MAGISAUTO.API y perfil http, reiniciar y pulsar Ctrl+F5. Abrir http://localhost:5164/. La salud SQL se consulta en /api/salud/base-datos. Para usar los reportes, corte **16/10/2026**; períodos **01/06/2026 a 16/10/2026**. No cambiar el reloj del sistema.

## 6. Datos para el manual y la demostración

| Crédito | Cliente | Caso |
| --- | --- | --- |
| MGA-2026-001 | Ana Lucía Morales López | Al día; 24 cuotas; valoración posterior |
| MGA-2026-002 | Carlos Eduardo Méndez Ruiz | Abono parcial; Q1,785.18 vencidos al corte |
| MGA-2026-003 | María Fernanda Castillo Paz | Tres cuotas vencidas; Q7,620.12; 62 días de mora |
| MGA-2026-004 | José Antonio Herrera Díaz | Anticipo; Q562.50 de intereses cobrados anticipados |
| MGA-2026-005 | Sofía Isabel Ramírez Luna | Un pago anulado de Q1,000; recibo 9 |
| MGA-2026-006 | Luis Fernando Aguilar Reyes | Borrador sin cuotas aprobadas |

Muestra inicial: seis clientes, ocho vehículos, seis créditos (cinco vigentes y un borrador), 144 cuotas, nueve pagos (ocho efectivos y uno anulado). Todos los datos son ficticios. Cumpleaños: octubre de 2026. El historial de pruebas anterior no describe esta nueva muestra.

## 7. Problemas habituales

- Base existente: revisar versión; no reinstalar, borrar ni crear otra copia por rutina.
- Servidor no encontrado: confirmar instancia y servicio de SQL Server.
- Login failed: revisar cuenta habilitada, modo mixto y base; no compartir claves.
- API 503: revisar configuración privada y reiniciar la aplicación después de cambiarla.
- Puerto ocupado: cerrar la ejecución anterior de Visual Studio.
- Datos diferentes: comprobar base final y movimientos posteriores; no volver a cargar la muestra para ocultarlos.

## 8. Evidencias y publicación

Ver `COMPROBACIONES_ENTREGA_FINAL_2026-10-17.md`: instalación, conexión, 20 reportes SQL y cuatro confirmaciones visuales. No equivale a una prueba visual de todos los reportes. Git no publica cambios de SQL Server automáticamente. Las instrucciones históricas de database/equipo y el PDF antiguo de tareas no son el instalador vigente.
