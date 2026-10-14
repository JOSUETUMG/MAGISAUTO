using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Modelos;

public class VehiculoSolicitud : IValidatableObject
{
    private string vin = "";
    private string? placa;
    [Required, RegularExpression("^[0-9A-HJ-NPR-Z]{17}$", ErrorMessage = "El VIN debe tener 17 letras o números, sin I, O ni Q.")]
    public string VIN { get => vin; set => vin = (value ?? "").Trim().ToUpperInvariant(); }
    [Range(1, int.MaxValue)] public int CodigoMarca { get; set; }
    [Range(1, int.MaxValue)] public int CodigoLinea { get; set; }
    [Range(1886, 2100, ErrorMessage = "El año debe estar entre 1886 y 2100, según el esquema del proyecto.")]
    public int Anio { get; set; }
    [Range(typeof(decimal), "0.01", "9999999999999999.99", ErrorMessage = "El precio debe ser positivo y estar dentro del rango permitido.")]
    [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString | JsonNumberHandling.WriteAsString)]
    public decimal ValorAgencia { get; set; }
    [StringLength(20)] public string? Placa { get => placa; set => placa = string.IsNullOrWhiteSpace(value) ? null : value.Trim().ToUpperInvariant(); }
    [Range(1, int.MaxValue)] public int CodigoTipoGarantia { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (decimal.Round(ValorAgencia, 2) != ValorAgencia)
            yield return new ValidationResult("El precio admite hasta dos decimales; no se redondea al guardar.", [nameof(ValorAgencia)]);
    }
}

public sealed class VehiculoFicha : VehiculoSolicitud
{
    public int CodigoGarantia { get; set; }
    public string Marca { get; set; } = "";
    public string Linea { get; set; } = "";
    public string TipoGarantia { get; set; } = "";
    public bool EsNuevo { get; set; }
    public bool TieneHistorialContractual { get; set; }
    public int CreditosVinculados { get; set; }
    public int ValoracionesRegistradas { get; set; }
}
