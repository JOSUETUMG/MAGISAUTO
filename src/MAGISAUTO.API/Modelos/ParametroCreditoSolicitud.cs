using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Modelos;

// La API recibe porcentajes visibles (12.5), no fracciones SQL (0.125).
[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed class ParametroCreditoSolicitud : IValidatableObject
{
    [Required, StringLength(100)] public string Nombre { get; set; } = "";
    [Required, JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal? TasaAnualPorcentaje { get; set; }
    [Required, JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal? SeguroAutoMensualPorcentaje { get; set; }
    [Required, JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal? SeguroVidaMensualPorcentaje { get; set; }
    [Required, JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal? EngancheMinimoPorcentaje { get; set; }
    [Required, JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal? ComisionPredeterminadaPorcentaje { get; set; }
    [Required, JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal? DepreciacionInicialPorcentaje { get; set; }
    [Required, JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal? ManejoMensual { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        foreach (var (nombre, valor) in new (string, decimal?)[] {
            (nameof(TasaAnualPorcentaje),TasaAnualPorcentaje),
            (nameof(SeguroAutoMensualPorcentaje),SeguroAutoMensualPorcentaje),
            (nameof(SeguroVidaMensualPorcentaje),SeguroVidaMensualPorcentaje),
            (nameof(EngancheMinimoPorcentaje),EngancheMinimoPorcentaje),
            (nameof(ComisionPredeterminadaPorcentaje),ComisionPredeterminadaPorcentaje),
            (nameof(DepreciacionInicialPorcentaje),DepreciacionInicialPorcentaje) })
            if (valor is decimal v && (v < 0 || v > 100 || decimal.Round(v,4) != v))
                yield return new("Usa porcentajes entre 0 y 100, con máximo cuatro decimales.", [nombre]);
        if (SeguroAutoMensualPorcentaje <= 0 || SeguroVidaMensualPorcentaje <= 0)
            yield return new("Las tasas mensuales de seguros deben ser mayores que cero.");
        if (EngancheMinimoPorcentaje < 20 || EngancheMinimoPorcentaje >= 100)
            yield return new("El enganche mínimo debe ser al menos 20% y menor que 100%.", [nameof(EngancheMinimoPorcentaje)]);
        if (DepreciacionInicialPorcentaje < 15 || DepreciacionInicialPorcentaje > 20)
            yield return new("La depreciación inicial debe estar entre 15% y 20%.", [nameof(DepreciacionInicialPorcentaje)]);
        if (ManejoMensual is not null && ManejoMensual != 25m)
            yield return new("El manejo mensual se conserva en Q25 según el enunciado.", [nameof(ManejoMensual)]);
    }
}
