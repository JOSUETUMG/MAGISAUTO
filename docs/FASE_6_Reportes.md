# Fase 6 — Consultas y reportes

Implementación del 13 de octubre de 2026 en `pruebas-diego`. La fase 6 continúa abierta. El módulo fue implementado y recorrido manualmente por Diego: ver [las 20 consultas y casos límite](PRUEBAS_MANUALES_REPORTES_2026-10-13.md). La publicación se comprueba mediante el commit remoto, no por esta declaración.

## Requisitos y alcance

Actualización del 16 de octubre: [Diseño y acciones de las 20 consultas](FASE_6_Diseno_y_Acciones_Reportes.md)
implementa el detalle de mora, consulta de plan, lectura ampliada, CSV y navegación común.
No confundir pruebas DOM correctas con aprobación visual: el recorrido final sigue pendiente.

Nota del 15 de octubre: los pendientes generales antiguos de catálogos, parámetros y entidades
integradas deben leerse con el [estado consolidado C05/C06](FASE_6_Cierre_C05_C06.md).
No se reabren por aparecer en este informe histórico. Los pendientes visuales específicos de
Reportes siguen identificados por separado.

Se contrastó el PDF original «Base de Datos I Proyecto final I.pdf», apartado «Módulo de consultas», página impresa 3 (cuarta página física). Pide al menos 20 consultas financieras, explicación de su utilidad y las consultas de todos los catálogos. Enumera como ejemplos créditos por período, mora, pagos por medio, ventas por vendedor, cumpleaños con carta, estado de cuenta y plan de pagos. Todas las operaciones SQL deben pasar por procedimientos almacenados llamados desde la API.

Se integran los **20 procedimientos de reporte existentes** de SQL 2.1. Los siete ejemplos del PDF quedan accesibles en la nueva pantalla. La revisión de Listar/Buscar y CRUD de todas las demás entidades y catálogos es un pendiente separado: disponer de 20 reportes no certifica por sí solo el cumplimiento integral del PDF.

El comentario del ingeniero sobre la cantidad y utilidad de las consultas refuerza esta prioridad. No se interpreta como una aprobación de las decisiones financieras pendientes.

## Qué permite hacer

Abrir `/reportes.html`, elegir una de las 20 consultas, leer su propósito, completar filtros y pulsar Consultar. Los filtros se ajustan a la consulta: período, corte, días, cliente, crédito o mes/año. El valor inicial de fecha proviene del servidor en hora de Guatemala, no de la zona del navegador.

Se muestran todas las tablas devueltas por el procedimiento, en secciones separadas. Créditos emitidos entrega detalle y agregado; estado de cuenta entrega resumen, cuotas y movimientos; plan de pagos entrega condiciones y cuotas. Las secciones vacías muestran un aviso y los agregados nulos se conservan como «Sin dato», sin convertirlos artificialmente a cero.

Las tablas permiten desplazamiento horizontal, conservan encabezados y muestran importes completos sin partir los centavos. Cambiar un filtro descarta el resultado anterior y cancela la petición pendiente: una respuesta tardía no debe aparecer bajo filtros diferentes.

Cumpleañeros permite abrir la carta individual e imprimirla con el navegador. El nombre y el texto se insertan como texto, sin interpretar HTML. No envía correos ni representa una integración de mensajería. No se añadió impresión general de tablas anchas, exportación CSV ni gráficos.

## Inventario de consultas

| Nº | Consulta / procedimiento | Filtros | Utilidad |
|---|---|---|---|
| 01 | Créditos emitidos — `api.Reporte01_CreditosEmitidos` | Desde y Hasta, inclusive | Mide colocacion bruta por periodo; muestra anulaciones por separado, sin ocultar que el credito fue emitido. |
| 02 | Cartera en mora — `api.Reporte02_CarteraMora` | Fecha de corte y días mínimos de atraso (≥1) | Determina creditos con cuotas vencidas pendientes al corte, incorporando abonos y anulaciones historicas. |
| 03 | Pagos por medio — `api.Reporte03_PagosPorMedio` | Desde y Hasta, inclusive | Compara uso de los cinco medios de pago y distingue ingresos y reversiones del periodo. |
| 04 | Ventas por vendedor — `api.Reporte04_VentasVendedor` | Desde y Hasta, inclusive | Clasifica vendedores por capital colocado en creditos no anulados al cierre del periodo. |
| 05 | Cumpleañeros y cartas — `api.Reporte05_Cumpleaneros` | Mes (1–12) y año (1900–9998) | Lista clientes cumpleaneros y genera el texto individual de su carta, sin enviar correos automaticamente. |
| 06 | Estado de cuenta por cliente — `api.Reporte06_EstadoCuenta` | Cliente y fecha de corte | Entrega resumen por credito, cuotas y movimientos del cliente hasta una fecha. |
| 07 | Plan de pagos por crédito — `api.Reporte07_PlanPagos` | Crédito y fecha de corte | Muestra todas las cuotas del contrato y su desglose; el saldo al corte es nulo si el contrato no estaba vigente al corte. |
| 08 | Comisiones por vendedor — `api.Reporte08_Comisiones` | Desde y Hasta, inclusive | Audita la comision generada y revertida por vendedor; no afirma que haya sido desembolsada al vendedor. |
| 09 | Capital pendiente — `api.Reporte09_CapitalPendiente` | Fecha de corte | Mide cuanto capital se ha recuperado y cuanto falta recuperar por credito. |
| 10 | Intereses del contrato — `api.Reporte10_Intereses` | Fecha de corte | Compara los intereses proyectados del plan con los cobrados; no confunde proyeccion con devengo contable. |
| 11 | Próximos vencimientos — `api.Reporte11_ProximosVencimientos` | Fecha de corte y horizonte de 1–365 días | Prepara la cobranza de cuotas pendientes que vencen dentro del horizonte indicado. |
| 12 | Abonos parciales — `api.Reporte12_AbonosParciales` | Fecha de corte | Localiza cuotas que recibieron abonos pero todavia no estan liquidadas. |
| 13 | Créditos por marca y línea — `api.Reporte13_CreditosMarcaLinea` | Desde y Hasta, inclusive | Compara la colocacion por marca y linea de vehiculo, excluyendo anulaciones al cierre. |
| 14 | Cartera por agencia y región — `api.Reporte14_CarteraAgenciaRegion` | Fecha de corte | Compara cartera y mora por agencia y region; cuenta cada credito una sola vez. |
| 15 | Mora por rangos — `api.Reporte15_MoraRangos` | Fecha de corte | Clasifica cada credito por su cuota pendiente mas antigua y suma su deuda vencida. |
| 16 | Garantía frente al capital — `api.Reporte16_GarantiaContraCapital` | Fecha de corte | Compara la ultima valoracion conocida al corte con el capital pendiente, sin modificar la deuda. |
| 17 | Depreciación y costo del financiamiento — `api.Reporte17_DepreciacionCostoFinanciamiento` | Fecha de corte | Relaciona precio, depreciacion y desembolso contractual del cliente. Los cargos no se presentan como ganancia neta. |
| 18 | Créditos respaldados por fiador — `api.Reporte18_CreditosFiador` | Fecha de corte | Identifica la exposicion de cada fiador. Un mismo credito puede aparecer con distintos fiadores y no debe sumarse como cartera global. |
| 19 | Recaudación por componentes — `api.Reporte19_RecaudacionComponentes` | Desde y Hasta, inclusive | Separa los componentes cobrados y resta las anulaciones ocurridas durante el periodo. |
| 20 | Pagos anulados — `api.Reporte20_PagosAnulados` | Desde y Hasta, inclusive | Permite auditar las anulaciones, sus responsables y los importes y comisiones revertidos. |

## Recorrido y archivos

`reportes.html` → `reportes.js` → `GET /api/reportes/{id}` → `ReporteRepositorio.Consultar` → procedimiento `api.ReporteNN_*` → tablas SQL → respuesta estructurada → secciones en pantalla.

| Archivo | Responsabilidad principal |
|---|---|
| `Datos/CatalogoReportes.cs` | Lista cerrada de IDs, procedimientos, utilidad, advertencias, filtros y nombres de secciones; `HoyGuatemala` establece la fecha inicial. |
| `Datos/ReporteRepositorio.cs` | `Parametros` valida los filtros y crea parámetros SQL tipados. `Catalogos` obtiene opciones mediante SP. `Consultar` lee cada conjunto de resultados, mantiene los tipos y controla errores. |
| `Controllers/ReportesController.cs` | Expone tres rutas de solo lectura y deshabilita caché de respuestas. |
| `Program.cs` | Registra el repositorio en la aplicación. |
| `wwwroot/reportes.html` y `reportes.css` | Selector, filtros, resultados desplazables, mensajes y carta imprimible. |
| `wwwroot/reportes.js` | Carga las definiciones, construye filtros, consulta, evita respuestas obsoletas, renderiza mediante `textContent` y abre cartas. |
| `wwwroot/reportes-formato.js` | `decimal` y `celda` conservan precisión al mostrar dinero, porcentajes, recibos, fechas y nulos. |
| Nueve páginas anteriores | Añaden el enlace «Consultas y reportes». |
| `scripts/Verificar-Reportes.ps1` | Ensayo HTTP/SQL real sobre datos ficticios propios, con comparación contra SP y limpieza restringida. |
| `scripts/Verificar-FormatoReportes.cjs` | Ensayo de representación monetaria y estados, sin navegador ni SQL. |

Los archivos C# y de interfaz están dentro de `src/MAGISAUTO.API`. Los comentarios generales de todo el proyecto y la preparación para la defensa siguen previstos para el cierre; los comentarios nuevos explican las decisiones clave de este módulo.

## API y validaciones

| Método y ruta | Respuesta |
|---|---|
| `GET /api/reportes` | Fecha de Guatemala y 20 definiciones de consulta con filtros. No requiere SQL para devolver esas definiciones. |
| `GET /api/reportes/catalogos` | Clientes y créditos para seleccionar; consulta `Persona_Listar`, `Deudor_Listar` y `Credito_Listar`. No devuelve DPI, NIT ni credenciales. |
| `GET /api/reportes/{id}?filtros` | ID/título/utilidad/nota, filtros efectivamente aplicados, fecha de consulta y todas las tablas, columnas tipadas y filas. |

Ejemplos:

- `/api/reportes/19?desde=2026-10-13&hasta=2026-10-13`
- `/api/reportes/6?codigoDeudor=6&fechaCorte=2026-10-13`
- `/api/reportes/7?numeroCredito=PRUEBA-CREDITO-01&fechaCorte=2026-10-13`
- `/api/reportes/5?mes=8&anio=2026`

Un ID inexistente o cliente/crédito inexistente devuelve 404. Fechas inválidas, Desde posterior a Hasta, filtros ajenos a la consulta, valores duplicados, enteros fuera de rango o un crédito con caracteres no admitidos devuelven 400. Solo se admite GET; no se agregan operaciones de escritura.

La fecha de corte es opcional en la API y se resuelve al día actual de Guatemala. Días mínimos toma 1 y horizonte toma 30 si se omiten. Mes, año, cliente, crédito y fechas de período son obligatorios para sus respectivos reportes. Las fechas admiten hasta el año 9998, evitando desbordamientos al calcular el fin de día o el horizonte. El formato es `yyyy-MM-dd`.

Se limitan a 10,000 filas por sección. Si se supera el límite, la API devuelve 422 y no muestra un informe parcial como completo. No hay paginación; ese umbral no recibió un ensayo de carga masiva en esta entrega. El tiempo de espera SQL es de 30 segundos. Se utiliza una transacción de lectura serializable para mantener coherencia entre las varias tablas; puede bloquear temporalmente escrituras concurrentes y requiere evaluación adicional con grandes volúmenes.

## SQL, seguridad y precisión

No se alteraron procedimientos ni tablas; **no hay nuevo parche SQL para Reportes**. Se requiere la base con los 20 SP existentes. La configuración privada y los datos del proyecto permanecen intactos.

La API escoge procedimientos de una lista cerrada por ID, usa `CommandType.StoredProcedure` y parámetros `Date`, `Int` o `VarChar(20)` con valores separados. No concatena el texto HTTP en SQL. La cuenta de aplicación conserva sus permisos de ejecutar SP sin lectura directa de tablas. Los mensajes propios no devuelven detalles internos del proveedor.

Los importes `decimal` y los identificadores `bigint` se serializan como texto. La interfaz agrupa dígitos sin convertir dinero a `Number`; las tasas se muestran como porcentajes. Las fechas de SQL se muestran sin desplazarlas por la zona horaria del navegador. Nulo significa «Sin dato», no dinero cero. Los valores de nombres y cartas se renderizan con `textContent`.

Los ensayos de entrada maliciosa validan esta nueva ruta; no constituyen una auditoría de seguridad de toda la aplicación. Autenticación del personal y restricciones de acceso por rol continúan pendientes según el alcance final. No exponer esta aplicación académica como servicio público sin revisar esos aspectos.

## Cómo interpretar los resultados

- El corte incluye todo el día en Guatemala. Para un día pasado se resta un pago si era efectivo entonces, aunque se haya anulado después. En movimientos, «Anulado actualmente» y «Pago efectivo al corte» pueden diferir sin contradicción.
- Los reportes de movimiento por período registran cobros en la fecha de pago y reversiones en la fecha de anulación. Un período puede tener movimiento neto negativo.
- Comisiones separa generado, revertido y neto. No declara comisiones desembolsadas al vendedor.
- Colocación por vendedor y marca/línea excluye anulaciones al final del período; Créditos emitidos conserva la colocación bruta y el estado actual.
- El plan completo puede mostrarse con saldo nulo si el crédito aún no estaba aprobado al corte. El estado mostrado del contrato es el actual.
- La depreciación afecta la valoración de garantía, no reduce la deuda. Sin valoración el margen es «Sin dato». El indicador compara únicamente el valor registrado, no certifica cobertura cuando falta valoración.
- Un crédito con varios fiadores aparece por cada vínculo: no sumar esas filas como cartera global.
- Intereses del contrato y costo de financiamiento son proyecciones contractuales; no se presentan como devengo contable ni ganancia neta.
- Nombres, contactos y cartas utilizan los datos personales actuales. No se implementó una historia temporal de esos datos.

## Verificación realizada

**134 comprobaciones HTTP/SQL correctas**, registradas en [fase-6-reportes.json](evidencias/fase-6-reportes.json). Se ejecutó la API con su cuenta limitada contra `MAGISAUTO_ValidacionV2`, preparando únicamente una ficha/contrato ficticio con prefijo aleatorio. No se añadieron pagos al crédito manual del proyecto.

Se verificaron:

1. Catálogo de 20 consultas, selectores, recursos estáticos y permisos limitados.
2. Las 20 consultas por HTTP: cantidad de tablas, columnas, filas, importes, fechas y nulos comparados con la ejecución de su SP sobre los mismos datos.
3. Tres tablas del estado de cuenta y dos del plan, con las doce cuotas del contrato de ensayo.
4. Aprobación histórica, pago de Q1000 el día anterior, pago de Q500 actual y anulación actual del primero. El corte anterior conserva Q1000 efectivos; el actual conserva Q500.
5. Plan anterior a la aprobación: cuotas presentes con saldos nulos.
6. Crédito en mora, cuota con abono parcial, vínculo del fiador, carta individual y auditoría de anulación.
7. Filtros inválidos, repetidos, desconocidos, ausencia de requeridos, inexistentes y cadenas de intento de inyección en fechas, código de cliente y crédito; errores sin información privada.
8. Período vacío con columnas conservadas y agregado nulo, método de escritura rechazado y fecha predeterminada coherente con SQL Guatemala.
9. Comparación de los datos de 15 tablas antes y después de retirar solo los registros propios: datos anteriores conservados. Las identidades/secuencias pueden avanzar normalmente.

**15 comprobaciones de formato correctas** en [fase-6-reportes-formato.json](evidencias/fase-6-reportes-formato.json): importes grandes, centavos, netos negativos, porcentajes, bigint, nulos, fecha sin desplazamiento y efectividad histórica.

Compilación .NET correcta, sin errores ni advertencias; JavaScript y PowerShell sin errores de sintaxis. El ensayo SQL utilizó `-ConexionLocalSinCifrado`, restringido a loopback y a la base aislada, por la limitación de credenciales TLS del entorno automatizado. No se cambió la conexión privada del proyecto.

**Intento automático histórico:** se intentó iniciar Edge mediante Playwright, pero terminó antes de abrir una página por errores del entorno restringido. No hay captura del módulo tomada por el navegador automático. Posteriormente Diego proporcionó capturas de las 20 consultas y de la vista previa de la carta; se documentan en el informe manual y su manifest SHA-256. Teclado, móvil y respuesta tardía siguen pendientes. La carta conserva una mejora visual pendiente de espacio superior.

Para repetir los ensayos desde la raíz, con credencial administrativa propia únicamente de la base aislada:

```powershell
dotnet build src/MAGISAUTO.API/MAGISAUTO.API.csproj --no-restore -o src/MAGISAUTO.API/bin/Reportes -p:UseAppHost=false
pwsh -File scripts/Verificar-Reportes.ps1 -Credencial <archivo-local-cifrado>
node scripts/Verificar-FormatoReportes.cjs
```

El ensayo requiere PowerShell 7, SQL 2.1, catálogos existentes y conexión local configurada. La opción sin TLS solo se usa explícitamente cuando corresponda a ese entorno aislado; no es una recomendación de despliegue.

## Guion manual y resultado documentado

Reiniciar la API en Visual Studio y abrir `http://localhost:5164/reportes.html`. Las cifras siguientes parten de las últimas capturas del 13 de octubre: crédito PRUEBA-CREDITO-01, cliente 6, recibos 1 y 3 efectivos, recibo 2 anulado y ningún otro pago posterior. Si existen más operaciones, comparar contra ellas en lugar de forzar estas cifras.

1. **19. Recaudación por componentes**, Desde y Hasta `2026-10-13`: neto Q1500.00; capital Q1291.09, intereses Q170.96, manejo Q5.13, seguro auto Q24.62 y seguro vida Q8.20. Es un reporte global; otras operaciones de ese día también aparecerán.
2. **06. Estado de cuenta**, Cliente Editado Prueba (6), corte `2026-10-13`: revisar tres secciones. Pagado Q1500.00, saldo total Q86239.56; cuota 1 con Q5811.63 de saldo; movimientos incluyen los tres recibos, con recibo 2 no efectivo al corte.
3. **03. Pagos por medio**, mismo día: Efectivo recibido Q7311.63, anulado Q6311.63, neto Q1000; ACH recibido/neto Q500. Otros medios pueden no tener filas.
4. **08. Comisiones**, mismo día: generado Q156.23, revertido Q126.23, neto Q30.00 para el vendedor del crédito, si no tiene otros movimientos.
5. **20. Pagos anulados**, mismo día: recibo 2, importe Q6311.63, comisión revertida Q126.23, responsable y motivo conservados.
6. **07. Plan**, crédito de prueba, mismo corte: condiciones y doce cuotas; saldo correcto de la primera cuota. Con corte anterior a la aprobación, verificar «Sin dato» en saldos.
7. **05. Cumpleañeros**, mes 8 y año 2026: según la fecha de nacimiento registrada, buscar Cliente Editado Prueba, abrir su carta y revisar vista previa de impresión sin enviarla.
8. Consultar un período sin operaciones, fechas invertidas y campos obligatorios vacíos. Cambiar rápidamente la selección/filtros mientras carga y comprobar que no quedan resultados anteriores bajo filtros nuevos.
9. Revisar desplazamiento horizontal, importes sin cortes, teclado y pantalla estrecha. No declarar aprobados estos puntos hasta contar con evidencia.

## Pendientes

Mejoras visuales identificadas, teclado/móvil/respuestas tardías, cobertura restante de consultas de catálogos y CRUD, configuración pendiente, revisión completa contra el PDF, comentarios generales del código/SQL y preparación para defender el proyecto. La fase 6 sigue abierta y su PDF de cierre todavía no corresponde. Los cambios actuales no se publican en GitHub por el mero hecho de escribir este informe.
