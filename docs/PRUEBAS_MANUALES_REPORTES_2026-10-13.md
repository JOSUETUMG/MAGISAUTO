# Pruebas manuales de Reportes - 13 de octubre de 2026

Ejecución manual de Diego; revisión de las capturas proporcionadas en el chat. Incluye las 20 consultas, filtros inválidos, período vacío, corte anterior a aprobación y límites de mora. No sustituye una auditoría completa ni cierra la fase 6.

## Datos y conciliación

PRUEBA-CREDITO-01: recibos 1 y 3 efectivos, recibo 2 anulado. Pagos efectivos Q1,500.00, saldo contractual Q86,239.56, capital pendiente Q78,708.91, cuota 1 pendiente Q5,811.63 y comisión efectiva Q30.00. Las cifras son las observadas en ese recorrido; no se atribuyen a una nueva ejecución automatizada.

## REP-01 - Créditos emitidos

**Filtros / contexto:** 12/10 al 13/10; captura válida usa 11/10 al 13/10 (también incluye la aprobación).

**Resultado observado:** 1 crédito, Q80,000.00 colocado; precio Q100,000, enganche Q20,000, 12 meses, interés Q5,519.56, cuotas Q87,739.56, VIGENTE sin anulación.

**Evidencias originales:**

- [REP-01-01.png](evidencias/reportes-manual-2026-10-13/REP-01-01.png)
- [REP-01-02.png](evidencias/reportes-manual-2026-10-13/REP-01-02.png)

## REP-01-invalido - Fechas invertidas

**Filtros / contexto:** Desde 14/10/2026, Hasta 13/10/2026.

**Resultado observado:** Mensaje «La fecha Desde no puede ser posterior a Hasta.»; sin resultados anteriores en la captura.

**Evidencias originales:**

- [REP-01-invalido-01.png](evidencias/reportes-manual-2026-10-13/REP-01-invalido-01.png)

## REP-01-vacio - Período vacío

**Filtros / contexto:** Desde y Hasta 11/10/2026.

**Resultado observado:** Detalle 0 filas; resumen 1 fila con 0 créditos y capital «Sin dato», no cero artificial. Se conserva captura repetida enviada por el usuario.

**Evidencias originales:**

- [REP-01-vacio-01.png](evidencias/reportes-manual-2026-10-13/REP-01-vacio-01.png)
- [REP-01-vacio-02.png](evidencias/reportes-manual-2026-10-13/REP-01-vacio-02.png)

## REP-02 - Cartera en mora

**Filtros / contexto:** Corte 13/10/2026; mínimo 1 día.

**Resultado observado:** 0 filas: aún no vence la primera cuota.

**Evidencias originales:**

- [REP-02-01.png](evidencias/reportes-manual-2026-10-13/REP-02-01.png)

## REP-02-limite - Inicio de mora

**Filtros / contexto:** Cortes 12/11 y 13/11/2026; mínimo 1 día.

**Resultado observado:** 12/11: 0 filas; 13/11: 1 crédito, 1 cuota, 1 día, Q5,811.63 vencido. La primera captura del intento usó 12/10 por error; se conserva identificada y NO se usa como evidencia del 12/11. La última corrige el corte.

**Evidencias originales:**

- [REP-02-limite-01.png](evidencias/reportes-manual-2026-10-13/REP-02-limite-01.png)
- [REP-02-limite-02.png](evidencias/reportes-manual-2026-10-13/REP-02-limite-02.png)
- [REP-02-limite-03.png](evidencias/reportes-manual-2026-10-13/REP-02-limite-03.png)

## REP-03 - Pagos por medio

**Filtros / contexto:** 13/10/2026, ambos extremos.

**Resultado observado:** Efectivo: 2 recibos, Q7,311.63 recibido, Q6,311.63 anulado, Q1,000 neto. ACH: 1 recibo, Q500 recibido/neto, Q0 anulado.

**Evidencias originales:**

- [REP-03-01.png](evidencias/reportes-manual-2026-10-13/REP-03-01.png)

## REP-04 - Ventas por vendedor

**Filtros / contexto:** 12/10 al 13/10/2026.

**Resultado observado:** Vendedor 16, PRUEBA-CREDITO-V01, Vendedor Credito: 1 crédito, Q80,000 colocados.

**Evidencias originales:**

- [REP-04-01.png](evidencias/reportes-manual-2026-10-13/REP-04-01.png)

## REP-05 - Cumpleañeros y carta

**Filtros / contexto:** Mes 8, año 2026.

**Resultado observado:** Cliente Editado Prueba, nacimiento 1998-08-15, edad 28, cliente.prueba@example.com; carta individual y vista previa de una página. No se acredita correo, PDF guardado ni impresión física. Espacio superior amplio en impresión: mejora visual pendiente.

**Evidencias originales:**

- [REP-05-01.png](evidencias/reportes-manual-2026-10-13/REP-05-01.png)
- [REP-05-02.png](evidencias/reportes-manual-2026-10-13/REP-05-02.png)
- [REP-05-03.png](evidencias/reportes-manual-2026-10-13/REP-05-03.png)

## REP-06 - Estado de cuenta

**Filtros / contexto:** Cliente 6; corte 13/10/2026.

**Resultado observado:** Tres secciones: resumen 1 crédito, 12 cuotas, 3 movimientos. Plan Q87,739.56, pagado Q1,500, saldo Q86,239.56, capital Q78,708.91, vencido Q0. Primera cuota pendiente Q5,811.63: capital Q5,002.21, interés Q662.37, manejo Q19.87, auto Q95.38, vida Q31.80. Recibos efectivos al corte Sí/No/Sí; comisiones originales Q20/Q126.23/Q10. La observación del recibo 1 ya aparece «Cuota 1», distinta de la primera captura histórica de pagos; no se infiere que haya permanecido sin cambios.

**Evidencias originales:**

- [REP-06-01.png](evidencias/reportes-manual-2026-10-13/REP-06-01.png)
- [REP-06-02.png](evidencias/reportes-manual-2026-10-13/REP-06-02.png)
- [REP-06-03.png](evidencias/reportes-manual-2026-10-13/REP-06-03.png)
- [REP-06-04.png](evidencias/reportes-manual-2026-10-13/REP-06-04.png)
- [REP-06-05.png](evidencias/reportes-manual-2026-10-13/REP-06-05.png)

## REP-07 - Plan de pagos

**Filtros / contexto:** Crédito PRUEBA-CREDITO-01; corte indicado 13/10/2026.

**Resultado observado:** Aprobación 12/10/2026 16:21:54; precio Q100,000, enganche Q20,000, financiado Q80,000, tasa 12.5%, 12 meses, interés Q5,519.56, plan Q87,739.56. Doce cuotas de Q7,311.63, de 12/11/2026 a 12/10/2027. Primera cuota saldo Q5,811.63 y capital Q5,002.21. Filtros no visibles en estas capturas.

**Evidencias originales:**

- [REP-07-01.png](evidencias/reportes-manual-2026-10-13/REP-07-01.png)
- [REP-07-02.png](evidencias/reportes-manual-2026-10-13/REP-07-02.png)

## REP-07-anterior - Plan antes de aprobación

**Filtros / contexto:** Se indicó corte 11/10/2026; el filtro no aparece en la captura.

**Resultado observado:** 12 cuotas conservadas y saldos pendiente/capital «Sin dato». Compatible con el corte solicitado, pero sin comprobación visual de la fecha aplicada.

**Evidencias originales:**

- [REP-07-anterior-01.png](evidencias/reportes-manual-2026-10-13/REP-07-anterior-01.png)
- [REP-07-anterior-02.png](evidencias/reportes-manual-2026-10-13/REP-07-anterior-02.png)

## REP-08 - Comisiones

**Filtros / contexto:** 13/10/2026.

**Resultado observado:** Vendedor 16: Q156.23 generados, Q126.23 revertidos y Q30 netos. No equivale a desembolso al vendedor.

**Evidencias originales:**

- [REP-08-01.png](evidencias/reportes-manual-2026-10-13/REP-08-01.png)

## REP-09 - Capital pendiente

**Filtros / contexto:** Corte 13/10/2026.

**Resultado observado:** Q80,000 financiados - Q1,291.09 recuperados = Q78,708.91 pendientes.

**Evidencias originales:**

- [REP-09-01.png](evidencias/reportes-manual-2026-10-13/REP-09-01.png)

## REP-10 - Intereses

**Filtros / contexto:** Corte 13/10/2026.

**Resultado observado:** Q5,519.56 contractuales - Q170.96 cobrados = Q5,348.60 pendientes; proyección, no devengo contable.

**Evidencias originales:**

- [REP-10-01.png](evidencias/reportes-manual-2026-10-13/REP-10-01.png)

## REP-11 - Próximos vencimientos

**Filtros / contexto:** Corte 13/10/2026, horizonte 30 días.

**Resultado observado:** Cuota 1, vence 12/11/2026; total Q7,311.63, pendiente Q5,811.63 con componentes Q5,002.21/Q662.37/Q19.87/Q95.38/Q31.80.

**Evidencias originales:**

- [REP-11-01.png](evidencias/reportes-manual-2026-10-13/REP-11-01.png)
- [REP-11-02.png](evidencias/reportes-manual-2026-10-13/REP-11-02.png)

## REP-12 - Abonos parciales

**Filtros / contexto:** Corte 13/10/2026.

**Resultado observado:** Cuota 1: Q7,311.63 total, Q1,500 pagado, Q5,811.63 pendiente.

**Evidencias originales:**

- [REP-12-01.png](evidencias/reportes-manual-2026-10-13/REP-12-01.png)

## REP-13 - Marca y línea

**Filtros / contexto:** 12/10 al 13/10/2026.

**Resultado observado:** Marca 4 Nissan, línea 1 Versa: 1 crédito, Q80,000 financiados.

**Evidencias originales:**

- [REP-13-01.png](evidencias/reportes-manual-2026-10-13/REP-13-01.png)

## REP-14 - Agencia y región

**Filtros / contexto:** Corte 13/10/2026.

**Resultado observado:** Agencia 1, Agencia academica Jalapa, Oriente: 1 crédito, capital Q78,708.91, saldo Q86,239.56; segunda captura confirma vencido Q0.00.

**Evidencias originales:**

- [REP-14-01.png](evidencias/reportes-manual-2026-10-13/REP-14-01.png)
- [REP-14-02.png](evidencias/reportes-manual-2026-10-13/REP-14-02.png)

## REP-15 - Mora por rangos

**Filtros / contexto:** Corte 13/11/2026.

**Resultado observado:** Rango 01-30, 1 crédito y Q5,811.63 vencidos con los pagos registrados. Corte futuro no predice nuevos pagos.

**Evidencias originales:**

- [REP-15-01.png](evidencias/reportes-manual-2026-10-13/REP-15-01.png)

## REP-16 - Garantía frente al capital

**Filtros / contexto:** Corte 13/10/2026.

**Resultado observado:** Valoración 12/10: valor Q85,000 frente a capital Q78,708.91; margen Q6,291.09; valor menor que capital: No.

**Evidencias originales:**

- [REP-16-01.png](evidencias/reportes-manual-2026-10-13/REP-16-01.png)
- [REP-16-02.png](evidencias/reportes-manual-2026-10-13/REP-16-02.png)

## REP-17 - Depreciación y costo

**Filtros / contexto:** Corte 13/10/2026.

**Resultado observado:** Costo financiamiento/cargos Q7,739.56; desembolso contractual Q107,739.56 incluyendo enganche, no pagado actual. Valor depreciado Q85,000 y pérdida estimada Q15,000; no reduce deuda.

**Evidencias originales:**

- [REP-17-01.png](evidencias/reportes-manual-2026-10-13/REP-17-01.png)
- [REP-17-02.png](evidencias/reportes-manual-2026-10-13/REP-17-02.png)

## REP-18 - Créditos por fiador

**Filtros / contexto:** Corte 13/10/2026.

**Resultado observado:** Fiador 4, Fiador Credito: PRUEBA-CREDITO-01, capital Q78,708.91, saldo Q86,239.56, 1 crédito respaldado.

**Evidencias originales:**

- [REP-18-01.png](evidencias/reportes-manual-2026-10-13/REP-18-01.png)

## REP-19 - Recaudación por componentes

**Filtros / contexto:** 13/10/2026.

**Resultado observado:** Capital Q1,291.09, interés Q170.96, manejo Q5.13, auto Q24.62, vida Q8.20: neto Q1,500.

**Evidencias originales:**

- [REP-19-01.png](evidencias/reportes-manual-2026-10-13/REP-19-01.png)

## REP-20 - Pagos anulados

**Filtros / contexto:** 13/10/2026 por fecha de anulación.

**Resultado observado:** 1 fila: pago 19:43:03, anulación 19:45:56, cuota 1, Q6,311.63, comisión revertida Q126.23, motivo Prueba de anulación de pago, Diego prueba. El identificador del recibo quedó fuera del recorte; las horas e importes coinciden con el recibo 2.

**Evidencias originales:**

- [REP-20-01.png](evidencias/reportes-manual-2026-10-13/REP-20-01.png)

## Límites y pendientes

- Navegación con teclado, pantalla móvil, solicitudes lentas y cambios rápidos de filtros no se acreditan por estas capturas.
- La vista previa de carta se comprobó; queda revisar su espacio superior. No se acredita guardado PDF ni impresión física.
- Los filtros no visibles y la captura de octubre enviada por error se identifican expresamente en sus casos.
- El fallo previo de Edge automático sigue siendo histórico; las nuevas capturas manuales no lo convierten en una ejecución automática correcta.
- La compilación y los 134 ensayos HTTP/SQL y 15 de formato se documentan por separado; sus resultados históricos no se vuelven a contar como pruebas nuevas.
- No hay cambios SQL requeridos para este módulo. La fase 6 sigue abierta.
