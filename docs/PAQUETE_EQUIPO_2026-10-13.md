# Paquete del equipo - 13 de octubre de 2026

## Qué se entrega

Una fotografía lógica de la base de trabajo `MAGISAUTO_Proyecto_V2`, en un instalador de base nueva, y la preparación de la conexión local que ya utiliza el proyecto de Visual Studio. No es una base remota compartida, un respaldo físico del servidor ni una copia de sus cuentas/contraseñas.

- [SQL y descripción](../database/equipo/LEEME.md): 26 tablas, 81 filas, 151 procedimientos, cuatro vistas y dos funciones.
- [Instrucciones completas](INSTALACION_EQUIPO.md): descargar, crear base, generar cuenta/conexión, comprobar y ejecutar.
- [Guía de tareas y Git](equipo/MAGISAUTO_Guia_de_trabajo_equipo_y_Git.pdf): documento de 14 páginas preparado anteriormente, incorporado sin alterar su contenido.
- `scripts/Preparar-Equipo.ps1`: comprueba SDK .NET 10 y reutiliza el generador de clave/configuración local del proyecto.
- `scripts/Comprobar-Equipo.ps1`: verifica la conexión y la fotografía inicial mediante procedimientos.
- [Evidencia de pruebas](evidencias/paquete-equipo.json) y [captura de instalación](evidencias/equipo/instalacion-ssms-correcta.png).

Diego confirmó explícitamente que las personas, teléfonos, direcciones y correos de esta base son ficticios de prueba. La exportación no incluye logins, contraseñas, configuración privada ni otras bases.

## Preparación de la copia

Los datos y las definiciones vigentes se leyeron en una transacción de lectura serializable. La estructura inicial parte del instalador 2.1; las definiciones de los 157 objetos programables se actualizan con las capturadas de la fuente. Los 81 registros se insertan con sus claves, identidades y fechas originales, incluidos el historial de anulación y los componentes de cada pago.

En una base NUEVA se sustituyen los catálogos iniciales por los datos de la fotografía. Las restricciones se reactivan con comprobación completa antes de terminar la transacción. No queda ninguna FK ni restricción CHECK deshabilitada o sin confianza. La secuencia de recibos comienza en el siguiente valor disponible, 4. El nombre de destino debe empezar por `MAGISAUTO_`; un destino existente es rechazado, sin reemplazo.

Las columnas se comparan por nombre y tipo, no por orden físico: la tabla Crédito de la fuente recibió columnas por una migración y su orden físico puede diferir del instalador nuevo. Los valores, tipos, nulabilidad, identidades y definiciones programables comprobados coinciden.

## Ensayo y resultados

1. La cuenta de revisión no tiene permiso para crear bases. Diego ejecutó en SSMS el instalador de ensayo con destino **MAGISAUTO_EnsayoEquipo_20261013**, separado de su base de trabajo. Se habilitaron únicamente en esa copia las cuentas existentes de revisión y de API; el instalador público no contiene esas habilitaciones particulares.
2. El primer intento falló por una construcción de `EXEC` con `QUOTENAME`; se corrigió antes de publicar. La versión corregida y las definiciones/carga pasaron un análisis de 160 bloques con ScriptDom. La captura acredita instalación correcta de 26 tablas, 151 SP, 20 reportes y tres recibos.
3. Comparación de las 26 tablas: **81 filas idénticas** por columna, estructura de columnas e identidades coincidentes. Comparación de las **157 definiciones**: iguales salvo el encabezado normalizado CREATE/ALTER. La fuente fue leída de nuevo tras las verificaciones y conserva sus datos.
4. **60 comprobaciones** del script de paquete: conteos, restricciones, siguiente recibo, cuenta limitada, API, salud SQL, las 20 consultas, saldos y tres recursos de interfaz. Los reportes conservan Q1,500 efectivos, Q78,708.91 de capital y Q86,239.56 de saldo contractual.
5. El preparador se ejecutó en una copia de directorios bajo `artifacts`, usando Windows PowerShell. Generó archivos privados; el segundo intento rechazó sobrescribirlos. El comprobador se ejecutó contra el ensayo con una cuenta limitada ya habilitada. La configuración real de Diego permaneció idéntica.
6. Se volvió a intentar el instalador contra el destino existente: rechazado con error 52500. No se recreó ni borró la base. Los tres scripts PowerShell pasaron análisis de sintaxis.

La prueba automática de API empleó `-ConexionLocalSinCifrado` exclusivamente en loopback y en la base aislada por una limitación TLS del proceso automatizado. El paquete y el generador entregados conservan `Encrypt=True;TrustServerCertificate=True` para desarrollo local. La prueba no cambió el archivo local de Diego.

## Cómo repetir el ensayo técnico

El destino de ensayo debe estar instalado y accesible; no ejecutar sobre la fuente. El archivo de credencial administrativa es privado y se proporciona localmente:

```powershell
dotnet build src/MAGISAUTO.API/MAGISAUTO.API.csproj --no-restore -o artifacts/build-publicacion -p:UseAppHost=false
pwsh -File scripts/Verificar-PaqueteEquipo.ps1 -Credencial RUTA_PRIVADA_DE_CREDENCIAL
```

La opción sin cifrado solo corresponde al problema de loopback aislado descrito; no es parte de las instrucciones normales de los compañeros. Las herramientas de generación y capturas completas intermedias quedaron bajo `artifacts`, ignoradas por Git. Los compañeros necesitan solo el instalador público y las instrucciones.

## Límites y estado

- La instalación y la API se verificaron en una base independiente del equipo de Diego. Cada compañero aún debe probar su instancia, habilitar su cuenta y ejecutar su aplicación. No se afirma que sus computadoras ya estén configuradas.
- El SQL con datos es una fotografía; nuevos cambios locales no aparecen en las otras computadoras por usar Git. Cambios futuros al modelo deben entregarse como fuentes/migraciones revisadas.
- El rol técnico no reemplaza autenticación del personal. La revisión general de seguridad y comentarios explicativos del proyecto continúa pendiente según el plan del equipo.
- La base de ensayo se conserva para revisión; la original no se modificó. Los archivos privados de preparación no se comparten.
- La fase 6 continúa abierta. Su avance de reportes y 40 capturas se publicó antes, en `dd954945727cd221765787fa30df584d7f1bfa1f`. Este paquete es una entrega posterior; su publicación se confirma verificando el commit remoto.
