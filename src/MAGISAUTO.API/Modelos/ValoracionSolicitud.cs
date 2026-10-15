using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Modelos;

public class ValoracionSolicitud : IValidatableObject
{
    private string observacion = "";

    [Range(1, int.MaxValue)] public int CodigoGarantia { get; set; }
    public DateOnly FechaValoracion { get; set; }
    [Range(typeof(decimal), "0.01", "9999999999999999.99", ErrorMessage = "El valor original debe ser positivo y estar dentro del rango permitido.")]
    [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString | JsonNumberHandling.WriteAsString)]
    public decimal ValorOriginal { get; set; }
    [Range(typeof(decimal), "15", "20", ErrorMessage = "El porcentaje debe estar entre 15% y 20%.")]
    [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString | JsonNumberHandling.WriteAsString)]
    public decimal Porcentaje { get; set; }
    [Required, StringLength(300)] public string Observacion { get => observacion; set => observacion = (value ?? "").Trim(); }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (FechaValoracion == default)
            yield return new ValidationResult("Indica la fecha de la valoración.", [nameof(FechaValoracion)]);
        if (FechaValoracion > MAGISAUTO.API.Datos.CatalogoReportes.HoyGuatemala)
            yield return new ValidationResult("La valoración no puede tener una fecha futura.", [nameof(FechaValoracion)]);
        if (decimal.Round(ValorOriginal, 2) != ValorOriginal)
            yield return new ValidationResult("El valor original admite hasta dos decimales; no se redondea al guardar.", [nameof(ValorOriginal)]);
        if (decimal.Round(Porcentaje, 4) != Porcentaje)
            yield return new ValidationResult("El porcentaje admite hasta cuatro decimales; no se redondea al guardar.", [nameof(Porcentaje)]);
    }
}

public sealed class ValoracionFicha : ValoracionSolicitud
{
    [JsonNumberHandling(JsonNumberHandling.WriteAsString)] public decimal ValorDepreciado { get; set; }
    public int CodigoDepreciacion { get; set; }
    public string Vehiculo { get; set; } = "";
    public bool ProtegidaPorContrato { get; set; }
}
