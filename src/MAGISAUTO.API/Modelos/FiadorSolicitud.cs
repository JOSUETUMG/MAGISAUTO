using System.ComponentModel.DataAnnotations;

namespace MAGISAUTO.API.Modelos;

public class FiadorSolicitud : NombresPersonaSolicitud
{
    [Required, RegularExpression("^[0-9]{13}$", ErrorMessage = "El DPI debe tener 13 dígitos.")]
    public string DPI { get; set; } = "";
    [Required, StringLength(20)] public string NIT { get; set; } = "";
    [Required, EmailAddress, StringLength(254)] public string CorreoElectronico { get; set; } = "";
    [Required] public List<TelefonoClienteSolicitud> Telefonos { get; set; } = [];
    [Required] public List<DireccionClienteSolicitud> Direcciones { get; set; } = [];
}

public sealed class FiadorFicha : FiadorSolicitud
{
    public int CodigoFiador { get; set; }
    public int CodigoPersona { get; set; }
    public string NombreCompleto => string.Join(" ", new[] { PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido }.Where(x => !string.IsNullOrWhiteSpace(x)));
    public List<string> Faltantes => Telefonos.Count == 0 ? ["Agrega al menos un teléfono del fiador antes de aprobar un crédito que lo requiera."] : [];
}
