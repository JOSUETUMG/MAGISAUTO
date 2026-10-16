# Diseño común y acciones de Reportes — 16 de octubre de 2026

Preparado para publicación en `pruebas-diego`. Este bloque amplía el
alcance visual a petición de Diego: menú, paleta del logo, accesos, cierres y acciones de reportes.
No modifica SQL, cálculos, datos de la aplicación ni requiere migraciones del equipo.

## Navegación y diseño

- Las 13 páginas comparten `identidad.css` y `sitio.js`. Los módulos se agrupan en Inventario,
  Personas, Financiamiento y Administración. Reportes tiene acceso directo. La página actual
  se identifica dentro de su grupo y solo un grupo queda abierto a la vez.
- Paleta tomada como referencia visual del logo proporcionado: marino `#07345c`, azul
  `#075a96`, rojo `#bb1428`, blanco y gris. El logo no se ha redibujado ni sustituido por otro.
- Los enlaces sueltos a Personas y vínculos y Parámetros son tarjetas con título, explicación
  y acceso. Las subpáginas tienen enlace explícito de regreso.
- Los diálogos con botón de cerrar/cancelar/conservar incorporan un cierre superior visible.
  Este pulsa el control original y refleja su bloqueo durante guardado: no salta la lógica
  del módulo. Los expedientes de clientes/fiadores tienen regreso también al pie.
- Tablas de reportes: acciones visibles en escritorio, desplazamiento horizontal, lectura
  ampliada de registros anchos; texto corto ya no reserva 300 píxeles por celda.
- Nuevos detalles tienen Cerrar y volver; al cerrar se devuelve el foco al control de origen.
  Las peticiones del detalle se cancelan al cerrarlo. Las capas de plan y rango son independientes.

## Decisiones para las 20 consultas

Todos los resultados ofrecen Volver a filtros e Imprimir reporte. Cada tabla con filas ofrece
Exportar CSV; el nombre incluye los filtros y el archivo conserva valores sin formato monetario.
Los textos que parecen fórmulas se neutralizan al exportar. Las tablas de ocho o más columnas
permiten Leer registro en formato vertical, salvo Cumpleañeros, que ya ofrece su carta.

| # | Consulta | Acción contextual y motivo |
|---|---|---|
| 1 | Créditos emitidos | Ver plan por crédito, con corte al Hasta del período |
| 2 | Cartera en mora | Ver plan para consultar las cuotas del crédito al mismo corte |
| 3 | Pagos por medio | CSV e impresión del resumen; no se inventa un recibo para una fila agregada |
| 4 | Ventas por vendedor | CSV e impresión; la fila resume varios contratos |
| 5 | Cumpleañeros y cartas | Ver carta, cerrar e imprimir carta; no enviar mensajes |
| 6 | Estado de cuenta | Ver plan en filas con número de crédito; lectura ampliada en tablas anchas |
| 7 | Plan de pagos | Lectura ampliada de condiciones si aplica; no abrir recursivamente otro plan |
| 8 | Comisiones por vendedor | CSV e impresión del resumen; no hay acción de pagar comisión |
| 9 | Capital pendiente | Ver plan al mismo corte |
| 10 | Intereses del contrato | Ver plan para explicar los intereses y cuotas |
| 11 | Próximos vencimientos | Ver plan del crédito para revisar el vencimiento |
| 12 | Abonos parciales | Ver plan para revisar la cuota y su saldo |
| 13 | Créditos por marca y línea | CSV e impresión del agregado; no se asigna un crédito arbitrario |
| 14 | Cartera por agencia y región | CSV/impresión y lectura ampliada cuando la tabla sea ancha |
| 15 | Mora por rangos | Ver créditos del rango; desde allí Ver plan; conserva fecha de corte |
| 16 | Garantía frente al capital | Ver plan y lectura ampliada; no modificar garantía desde el reporte |
| 17 | Depreciación y costo | Ver plan y lectura ampliada del desglose |
| 18 | Créditos respaldados por fiador | Ver plan del crédito mostrado; se mantiene advertencia de duplicidad entre fiadores |
| 19 | Recaudación por componentes | CSV e impresión del agregado; no crear una acción de cobro |
| 20 | Pagos anulados | Ver plan del crédito y lectura ampliada de datos de anulación |

El detalle de plan ofrece además **Ver pagos actuales de este crédito**. El texto distingue
ese historial actual del saldo al corte del reporte. No hay botones de escritura financiera
en Reportes ni rutas nuevas de base de datos.

## Mora por rangos y consistencia

Se reutiliza Reporte02_CarteraMora con el mismo corte, y se filtra por DiasMora en los rangos
01–30, 31–60, 61–90 y 91 o más. No se suman cuotas como créditos diferentes: el SP devuelve
una fila por crédito y considera su vencimiento pendiente más antiguo, igual que Reporte15.
Los límites 30/31, 60/61 y 90/91 se ensayaron explícitamente en DOM con datos controlados.
Si cambia la cantidad desde el resumen inicial, se muestra una advertencia para actualizarlo.
Las consultas se ejecutan en momentos distintos; no se promete una instantánea compartida
entre resumen y detalle cuando otra persona modifica movimientos simultáneamente.

## Comprobaciones realizadas

- Compilación .NET sin errores/advertencias; sintaxis JavaScript comprobada.
- **134 comprobaciones HTTP/SQL correctas**, repetidas el 15 de octubre de 2026 durante este
  cambio, con TLS y base `MAGISAUTO_ValidacionV2`. [Evidencia](evidencias/fase-6-reportes-diseno-http.json).
- **198 comprobaciones DOM correctas**, terminadas el 16 de octubre: los 13 menús, destinos,
  página activa, cierre por teclado de menú, controles superiores y bloqueos de guardado,
  tarjetas, representación de respuestas reales de las 20 consultas, límites de mora,
  exportación de rangos, conservación del corte, cierre de capas y respuestas tardías.
  [Evidencia](evidencias/fase-6-diseno-dom.json).
- DOM usa jsdom; **no acredita renderizado, apariencia, anchos reales, interacción nativa
  de diálogos ni vista previa real de impresión**. Dos evaluaciones JS separadas inicialmente
  no compartían la constante de formato en el ensayo; se corrigió la carga conjunta del ensayo.
- El navegador integrado devolvió `ERR_CONNECTION_TIMED_OUT` al conectar por localhost y
  127.0.0.1, también tras reintentar el 16 de octubre. No existe captura automática aprobada.
  La API sí responde a la verificación ejecutada junto al servidor temporal.
- No se repitieron las pruebas manuales anteriores ni se presentan como pruebas del nuevo diseño.

## Un único recorrido visual pendiente

Actualización del 16 de octubre: Diego informó que el único defecto visual observado era
el texto MAGISAUTO oscuro en el encabezado. Se fijó blanco tanto para el enlace normal
como visitado y se versionó la referencia a identidad.css en las 13 páginas para renovar
la caché. Su captura posterior confirma el nombre legible en blanco y el menú de Marcas.
Esta evidencia confirma esa corrección; no acredita por sí sola la impresión ni cada
diálogo de Reportes. La lista siguiente conserva el alcance de comprobación visual.

Reiniciar la aplicación y recargar con Ctrl+F5. No repetir los CRUD ni registrar pagos nuevos.

1. Abrir los cuatro grupos del menú en ventana amplia y estrecha; comprobar acceso y página activa.
2. Revisar las tarjetas de Reportes y Catálogos auxiliares y sus enlaces de regreso.
3. Abrir un editor, un historial y una confirmación; cerrar desde arriba y abajo sin guardar.
4. En Reportes, consultar y abrir un plan; cerrar para volver sin perder el resultado.
5. En Mora por rangos, usar una fecha con mora: abrir rango, plan y regresar. Si está vacío,
   comprobar el mensaje; no modificar créditos para fabricar mora en la base principal.
6. Probar una carta, Leer registro, exportar una tabla y revisar la vista previa de impresión.
   Confirmar que la impresión no corta columnas; cancelar si no se desea imprimir.
7. Recorrer controles con Tab, reducir ancho y cambiar rápidamente filtros. Compartir solo
   defectos observados y una captura general del aspecto, sin repetir casos ya comprobados.

Hasta este recorrido no se declara cerrado el control visual C07. La mejora de mora ya está
implementada y tiene pruebas de lógica; no sigue siendo una mejora pendiente de desarrollo.

## Reproducción e impacto

Con Node, npm, PowerShell 7 y la configuración privada de la base aislada:

```powershell
npm install --prefix artifacts/diseno-dom jsdom@30.1.3 --ignore-scripts --no-audit --no-fund
dotnet build src/MAGISAUTO.API --no-restore -o src/MAGISAUTO.API/bin/Reportes -p:UseAppHost=false
pwsh -File scripts/Verificar-Diseno.ps1 -Node node
```

Las dependencias de prueba quedan en artifacts, ignorado por Git. La aplicación no necesita
jsdom, npm ni servicios externos. El servidor temporal se limita a loopback/base aislada y
se cierra al terminar. No debe ejecutarse el lanzador aislado contra la base de producción.

Dylan: no actualizar SQL. Josué: renovar capturas y navegación del manual con la identidad
aprobada, y describir las acciones de reporte de la tabla anterior. La publicación en
pruebas-diego y la integración en otras ramas son pasos distintos; este bloque no modifica
ramas de compañeros. La publicación se confirma comparando el commit local con el remoto.
