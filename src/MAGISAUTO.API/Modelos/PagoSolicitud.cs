using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Modelos;

public sealed class PagoSolicitud : IValidatableObject
{
    [Required, StringLength(20)] public string NumeroCredito { get; set; } = "";
    [Range(1,60)] public short Cuota { get; set; }
    [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)] public decimal Monto { get; set; }
    [Range(1,int.MaxValue)] public int CodigoTipoPago { get; set; }
    [Required, StringLength(100)] public string Responsable { get; set; } = "";
    [StringLength(100)] public string? ReferenciaBancaria { get; set; }
    [StringLength(300)] public string? Observacion { get; set; }
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (Monto<=0 || Monto>=10000000000000000m || decimal.Round(Monto,2)!=Monto)
            yield return new("Indica un monto positivo con máximo dos decimales.",[nameof(Monto)]);
    }
}
public sealed class PagoObservacion
{
    [StringLength(300)] public string? Observacion { get; set; }
}
public sealed class PagoAnulacion
{
    [Required,StringLength(100)] public string Responsable { get; set; } = "";
    [Required,StringLength(300)] public string Motivo { get; set; } = "";
}
