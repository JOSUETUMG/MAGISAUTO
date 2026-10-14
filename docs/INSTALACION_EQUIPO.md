# Instalar la base de prueba y ejecutar MAGIS-AUTO en Visual Studio

## Qué compartir

El repositorio completo en `pruebas-diego`, este documento, el [SQL con los datos](../database/equipo/LEEME.md) y la [guía PDF de tareas y Git](equipo/MAGISAUTO_Guia_de_trabajo_equipo_y_Git.pdf). No enviar `appsettings.Local.json`, contraseñas, `artifacts/acceso-local` ni archivos de credenciales de Diego. Todos los datos de negocio de esta copia fueron confirmados ficticios por Diego.

Git descarga archivos; la base debe instalarse en el motor SQL de cada computadora. Esta copia no conecta a una base compartida ni modifica la base de Diego. Los documentos antiguos se conservan como antecedentes; para una instalación con los datos actuales usar exclusivamente `database/equipo`.

## 1. Requisitos

- Windows, Git y acceso al repositorio.
- Visual Studio compatible con .NET 10, carga de desarrollo ASP.NET y web y SDK .NET 10. En el equipo de Diego se usa Visual Studio 2026.
- Motor SQL Server 2022 o 2025 en funcionamiento y SSMS para administrarlo. Instalar SSMS no instala el motor.
- Cuenta administradora local del motor para crear la base y el login de aplicación. Este recorrido usa un login SQL limitado y requiere autenticación mixta (SQL Server y Windows).
- Conocer el nombre de la instancia: por ejemplo `localhost`, `.\SQLEXPRESS` o `NOMBREPC\INSTANCIA`. Debe ser el mismo con el que se conectan en SSMS; no copiar el nombre de la computadora de Diego.

## 2. Descargar la versión común y crear la rama propia

```powershell
git clone https://github.com/JOSUETUMG/MAGISAUTO.git
cd MAGISAUTO
git fetch origin
```

Cada compañero ejecuta SOLO el bloque que le corresponde, una vez que Diego confirme que el paquete está publicado:

```powershell
# Compañero 1
git switch -c companero1-sql origin/pruebas-diego
```

```powershell
# Compañero 2
git switch -c companero2-pruebas-docs origin/pruebas-diego
```

Si la rama ya existe, usar `git switch NOMBRE` sin `-c` y revisar sus cambios antes de actualizar. Nadie modifica `main` en este flujo. No necesitan hacer un nuevo clon si ya tienen una copia correcta y actualizada.

## 3. Crear la base con los mismos registros

Abrir `database/equipo/MAGISAUTO_Equipo_2026-10-13.sql` en SSMS como administrador y ejecutar todo con F5. El destino predeterminado es `MAGISAUTO_Equipo`; puede elegirse otro nombre nuevo cambiando solo `@Base`. Debe terminar mostrando la copia instalada y **3 recibos**. Si hay cualquier error, detenerse y compartir solo el mensaje, sin credenciales.

El archivo se niega a reemplazar una base existente. No ejecutar por fragmentos, no ejecutar el SQL antiguo y no aplicar después la migración de presentación: ya está incluida.

## 4. Generar la conexión de la aplicación

Desde una terminal en la raíz del repositorio (donde está `MAGISAUTO.sln`):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/Preparar-Equipo.ps1 -Servidor "localhost" -Base "MAGISAUTO_Equipo" -Usuario "magis_api_equipo"
```

Sustituir `localhost` por su instancia real, por ejemplo `.\SQLEXPRESS`. Si cambiaron el nombre de la base, usar el mismo en `-Base`. `ExecutionPolicy Bypass` afecta únicamente a ese proceso. Este script verifica el SDK y reutiliza el generador local del proyecto, crea una contraseña aleatoria por computadora y deja dos archivos privados:

- `src/MAGISAUTO.API/appsettings.Local.json`: configuración que carga la API al ejecutar el perfil de desarrollo.
- `artifacts/acceso-local/HABILITAR_API_LOCAL.sql`: instrucciones para crear el login y el usuario local con esa misma clave.

**Aún falta habilitar la cuenta:** abrir el segundo archivo en SSMS, en la misma instancia, como administrador y ejecutarlo completo. Solo crea la cuenta y su pertenencia al rol `magis_api`; no cambia los datos de negocio. Ese rol permite procedimientos y deniega acceso directo a las tablas. No usar `sa` como cuenta de la aplicación.

Ambos archivos están ignorados por Git. No imprimirlos, enviarlos por chat ni incorporarlos con `git add -f`. Si ya existe la configuración local o el login, el proceso se detiene; conservarlos y revisar con Diego antes de reemplazar nada.

## 5. Verificar antes de abrir la aplicación

```powershell
powershell.exe -NoProfile -File scripts/Comprobar-Equipo.ps1
```

Comprueba la conexión y procedimientos de lectura, sin imprimir la clave. Para la fotografía inicial debe encontrar un crédito, 12 cuotas y tres recibos. Si después cambian datos de su copia, esa comprobación inicial puede dejar de coincidir aunque la conexión funcione.

## 6. Ejecutar en Visual Studio

1. Abrir `MAGISAUTO.sln`; esperar la restauración de paquetes NuGet.
2. Seleccionar `MAGISAUTO.API` como proyecto de inicio.
3. Elegir el perfil **http** y pulsar **Ctrl+F5**.
4. Abrir `http://localhost:5164/api/salud` para comprobar la API.
5. Abrir `http://localhost:5164/api/salud/base-datos` para comprobar la conexión real con SQL.
6. Abrir `http://localhost:5164/pagos.html` y seleccionar `PRUEBA-CREDITO-01`.
7. Abrir `http://localhost:5164/reportes.html`; usar corte 13/10/2026 y cliente 6 para el estado de cuenta.

También puede ejecutarse desde terminal:

```powershell
dotnet run --project src/MAGISAUTO.API --launch-profile http
```

Solo es un entorno local de desarrollo. La cuenta de conexión técnica no es el inicio de sesión del personal. No cambiar el código para apuntar a la computadora de Diego.

## 7. Resultados de control

| Comprobación | Resultado inicial |
|---|---|
| Crédito | PRUEBA-CREDITO-01, VIGENTE |
| Pagos | 1 y 3 efectivos; 2 anulado |
| Pagado efectivo | Q1,500.00 |
| Saldo de cuota 1 | Q5,811.63 |
| Capital pendiente | Q78,708.91 |
| Saldo contractual | Q86,239.56 |
| Comisión efectiva | Q30.00 |

Los parámetros y fechas del plan son históricos. No cambiar el reloj de Windows para reproducir las capturas: seleccionar la fecha del reporte. Las operaciones nuevas usarán la hora actual del servidor y las reglas normales del sistema.

## 8. Problemas habituales

| Mensaje / situación | Acción |
|---|---|
| La base ya existe | Comprobar si ya se instaló; no borrar datos. Elegir otro nombre si se necesita otra copia. |
| Servidor no encontrado | Usar exactamente la instancia de SSMS; comprobar que su servicio esté iniciado. |
| Login failed | Ejecutar el SQL privado de habilitación y confirmar modo mixto, instancia y base. No compartir la clave. |
| Falta SDK .NET 10 | Instalar el SDK/carga web y reiniciar terminal/Visual Studio. |
| Puerto 5164 ocupado | Detener la ejecución anterior de la aplicación antes de iniciar otra. |
| SQL funciona, API da 503 | Revisar archivo local, perfil http/Development y cuenta habilitada. Reiniciar la API tras configurar. |
| La cuenta o configuración ya existe | No regenerar claves a ciegas; revisar si se completó una preparación anterior. |
| Advertencia de finales de línea | Normalizar CRLF y ejecutar el archivo completo. No es una validación de resultados SQL. |

## 9. Entregar cambios

Cada uno sube código/documentación a su rama y abre revisión hacia `pruebas-diego`, como explica el PDF. **Git no sube automáticamente los cambios hechos en SQL Server.** Una modificación del esquema o procedimiento debe acompañarse de su fuente/script SQL y una explicación; no volver a exportar toda la base para cada pequeña corrección. Los datos creados durante pruebas son locales.

La base `MAGISAUTO_EnsayoEquipo_20261013` es el destino usado para verificar el paquete en el equipo de Diego. Los compañeros no necesitan crearlo ni usar las cuentas de revisión de Diego. Deben utilizar el instalador público con destino `MAGISAUTO_Equipo` y generar su propia cuenta.
