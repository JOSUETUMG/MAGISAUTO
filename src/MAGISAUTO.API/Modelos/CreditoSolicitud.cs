using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Modelos;

public sealed class CreditoSolicitud : IValidatableObject
{
    [Required, RegularExpression(@"[A-Za-z0-9_-]{1,20}")]
    public string NumeroCredito { get; set; } = "";
    [Range(1,int.MaxValue)] public int CodigoDeudor { get; set; }
    [Range(1,int.MaxValue)] public int CodigoGarantia { get; set; }
    [Range(1,int.MaxValue)] public int CodigoVendedor { get; set; }
    [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)]
    public decimal Enganche { get; set; }
    // Porcentaje visible; null usa el valor activo al crear y conserva el pactado al editar.
    [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)]
    public decimal? ComisionPorcentaje { get; set; }
    [Range(1,int.MaxValue)] public int? CodigoParametro { get; set; }
    public short Plazo { get; set; } = 60;
    [Range(0,short.MaxValue)] public short FiadoresRequeridos { get; set; } = 1;
    [Required] public List<int> Fiadores { get; set; } = [];
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (ComisionPorcentaje is decimal comision && (comision<0 || comision>100 || decimal.Round(comision,4)!=comision))
            yield return new("La comisión debe estar entre 0% y 100%, con máximo cuatro decimales.",[nameof(ComisionPorcentaje)]);
        if (Enganche <= 0 || Enganche >= 10000000000000000m || decimal.Round(Enganche,2)!=Enganche)
            yield return new("Indica un enganche positivo con máximo dos decimales.",[nameof(Enganche)]);
        if (!new short[]{12,24,36,48,60}.Contains(Plazo)) yield return new("El plazo debe ser 12, 24, 36, 48 o 60 meses.",[nameof(Plazo)]);
        if (Fiadores is not null && (Fiadores.Any(x=>x<=0) || Fiadores.Distinct().Count()!=Fiadores.Count))
            yield return new("Selecciona fiadores distintos y válidos.",[nameof(Fiadores)]);
    }
}
public class CreditoAccion
{
    [Required, StringLength(100)] public string Responsable { get; set; } = "";
}
public sealed class CreditoAnulacion : CreditoAccion
{
    [Required, StringLength(300)] public string Motivo { get; set; } = "";
}
