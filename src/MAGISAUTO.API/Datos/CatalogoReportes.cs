using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Datos;

public sealed record FiltroReporte(string Nombre, string Etiqueta, string Tipo, bool Obligatorio = true,
    int? Minimo = null, int? Maximo = null, int? Predeterminado = null);
public sealed record DefinicionReporte(int Id, string Titulo, string Utilidad, string Nota,
    FiltroReporte[] Filtros, string[] Secciones, [property: JsonIgnore] string Procedimiento);

// Lista cerrada: ni la ruta ni los filtros HTTP pueden elegir nombres de procedimientos SQL.
public static class CatalogoReportes
{
    private static readonly FiltroReporte Desde = new("desde", "Desde", "fecha");
    private static readonly FiltroReporte Hasta = new("hasta", "Hasta (inclusive)", "fecha");
    private static readonly FiltroReporte Corte = new("fechaCorte", "Fecha de corte (inclusive)", "fecha", false);
    public static DateOnly HoyGuatemala => DateOnly.FromDateTime(DateTime.UtcNow.AddHours(-6));
    public static readonly DefinicionReporte[] Todos =
    [
        new(1, "Créditos emitidos", "Mide colocacion bruta por periodo; muestra anulaciones por separado, sin ocultar que el credito fue emitido.", "Colocación bruta: incluye créditos emitidos que después se anularon. Estado es el estado actual.", [Desde, Hasta], ["Créditos emitidos", "Resumen del período"], "api.Reporte01_CreditosEmitidos"),
        new(2, "Cartera en mora", "Determina creditos con cuotas vencidas pendientes al corte, incorporando abonos y anulaciones historicas.", "Los saldos se calculan al cierre de la fecha indicada en Guatemala. La mora comienza al día siguiente del vencimiento.", [Corte, new("diasMinimos", "Días mínimos de atraso", "entero", false, 1, 3652058, 1)], ["Cartera en mora"], "api.Reporte02_CarteraMora"),
        new(3, "Pagos por medio", "Compara uso de los cinco medios de pago y distingue ingresos y reversiones del periodo.", "El movimiento neto resta las anulaciones ocurridas en el período, aunque el pago original sea anterior.", [Desde, Hasta], ["Pagos por medio"], "api.Reporte03_PagosPorMedio"),
        new(4, "Ventas por vendedor", "Clasifica vendedores por capital colocado en creditos no anulados al cierre del periodo.", "El período incluye completos los días inicial y final, en hora de Guatemala.", [Desde, Hasta], ["Ventas por vendedor"], "api.Reporte04_VentasVendedor"),
        new(5, "Cumpleañeros y cartas", "Lista clientes cumpleaneros y genera el texto individual de su carta, sin enviar correos automaticamente.", "Las cartas se generan para consulta e impresión. No se envían correos.", [new("mes", "Mes de cumpleaños", "entero", true, 1, 12), new("anio", "Año de la felicitación", "entero", true, 1900, 9998)], ["Cumpleañeros y cartas"], "api.Reporte05_Cumpleaneros"),
        new(6, "Estado de cuenta por cliente", "Entrega resumen por credito, cuotas y movimientos del cliente hasta una fecha.", "El corte incluye el día completo en Guatemala. Para interpretar el saldo histórico usa «Pago efectivo al corte»: un pago anulado actualmente pudo ser efectivo en una fecha anterior. Los movimientos también conservan los datos actuales de anulación.", [new("codigoDeudor", "Cliente", "cliente"), Corte], ["Resumen por crédito", "Cuotas al corte", "Movimientos del cliente"], "api.Reporte06_EstadoCuenta"),
        new(7, "Plan de pagos por crédito", "Muestra todas las cuotas del contrato y su desglose; el saldo al corte es nulo si el contrato no estaba vigente al corte.", "El plan muestra el contrato completo y su estado actual. Un saldo sin valor indica que el contrato no estaba activo al corte; no equivale a cero.", [new("numeroCredito", "Crédito", "credito"), Corte], ["Condiciones del contrato", "Plan y saldos al corte"], "api.Reporte07_PlanPagos"),
        new(8, "Comisiones por vendedor", "Audita la comision generada y revertida por vendedor; no afirma que haya sido desembolsada al vendedor.", "Comisión generada menos reversiones del período. No representa un desembolso al vendedor.", [Desde, Hasta], ["Comisiones por vendedor"], "api.Reporte08_Comisiones"),
        new(9, "Capital pendiente", "Mide cuanto capital se ha recuperado y cuanto falta recuperar por credito.", "Los saldos se calculan al cierre de la fecha indicada en Guatemala. La mora comienza al día siguiente del vencimiento.", [Corte], ["Capital pendiente"], "api.Reporte09_CapitalPendiente"),
        new(10, "Intereses: devengo y cobros", "Distingue intereses del contrato, devengados al corte, cobrados y de cuotas futuras.", "Criterio académico: el interés mensual se devenga completo en la fecha de vencimiento de cada cuota, sin prorrateo diario. El cobro anticipado de cuotas futuras se muestra separado. No incluye cargos ni seguros.", [Corte], ["Intereses: devengo mensual y cobros"], "api.Reporte10_Intereses"),
        new(11, "Próximos vencimientos", "Prepara la cobranza de cuotas pendientes que vencen dentro del horizonte indicado.", "Incluye desde la fecha de corte hasta el último día del horizonte, ambos inclusive.", [Corte, new("dias", "Horizonte en días", "entero", false, 1, 365, 30)], ["Próximos vencimientos"], "api.Reporte11_ProximosVencimientos"),
        new(12, "Abonos parciales", "Localiza cuotas que recibieron abonos pero todavia no estan liquidadas.", "Los saldos se calculan al cierre de la fecha indicada en Guatemala. La mora comienza al día siguiente del vencimiento.", [Corte], ["Abonos parciales"], "api.Reporte12_AbonosParciales"),
        new(13, "Créditos por marca y línea", "Compara la colocacion por marca y linea de vehiculo, excluyendo anulaciones al cierre.", "El período incluye completos los días inicial y final, en hora de Guatemala.", [Desde, Hasta], ["Créditos por marca y línea"], "api.Reporte13_CreditosMarcaLinea"),
        new(14, "Cartera por agencia y región", "Compara cartera y mora por agencia y region; cuenta cada credito una sola vez.", "Los saldos se calculan al cierre de la fecha indicada en Guatemala. La mora comienza al día siguiente del vencimiento.", [Corte], ["Cartera por agencia y región"], "api.Reporte14_CarteraAgenciaRegion"),
        new(15, "Mora por rangos", "Clasifica cada credito por su cuota pendiente mas antigua y suma su deuda vencida.", "Los saldos se calculan al cierre de la fecha indicada en Guatemala. La mora comienza al día siguiente del vencimiento.", [Corte], ["Mora por rangos"], "api.Reporte15_MoraRangos"),
        new(16, "Garantía frente al capital", "Compara la ultima valoracion conocida al corte con el capital pendiente, sin modificar la deuda.", "Se usa la última valoración registrada hasta el corte. Sin valoración, el margen no se puede determinar.", [Corte], ["Garantía frente al capital"], "api.Reporte16_GarantiaContraCapital"),
        new(17, "Depreciación y costo del financiamiento", "Relaciona precio, depreciacion y desembolso contractual del cliente. Los cargos no se presentan como ganancia neta.", "El desembolso contractual incluye enganche y cuotas. Los cargos no son utilidad neta; la depreciación no reduce la deuda.", [Corte], ["Depreciación y costo del financiamiento"], "api.Reporte17_DepreciacionCostoFinanciamiento"),
        new(18, "Créditos respaldados por fiador", "Identifica la exposicion de cada fiador. Un mismo credito puede aparecer con distintos fiadores y no debe sumarse como cartera global.", "Un crédito puede repetirse para distintos fiadores. No sumes estas filas como cartera global.", [Corte], ["Créditos respaldados por fiador"], "api.Reporte18_CreditosFiador"),
        new(19, "Recaudación por componentes", "Separa los componentes cobrados y resta las anulaciones ocurridas durante el periodo.", "Los componentes netos restan las anulaciones del período. Un neto negativo representa más reversiones que cobros.", [Desde, Hasta], ["Recaudación por componentes"], "api.Reporte19_RecaudacionComponentes"),
        new(20, "Pagos anulados", "Permite auditar las anulaciones, sus responsables y los importes y comisiones revertidos.", "El período corresponde a la fecha de anulación. Los importes son los originales que se revirtieron.", [Desde, Hasta], ["Pagos anulados"], "api.Reporte20_PagosAnulados"),
    ];
    public static DefinicionReporte Obtener(int id) => Todos.FirstOrDefault(x => x.Id == id)
        ?? throw new OperacionCatalogoException(404, "La consulta solicitada no existe.");
}
