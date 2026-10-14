using System.ComponentModel.DataAnnotations;

namespace MAGISAUTO.API.Modelos;

public class NombresPersonaSolicitud
{
    [Required, StringLength(64)] public string PrimerNombre { get; set; } = "";
    [StringLength(64)] public string? SegundoNombre { get; set; }
    [Required, StringLength(64)] public string PrimerApellido { get; set; } = "";
    [StringLength(64)] public string? SegundoApellido { get; set; }
}

public sealed class TelefonoClienteSolicitud
{
    [Range(0, short.MaxValue)] public int Correlativo { get; set; }
    [Range(1, int.MaxValue)] public int CodigoTipoTelefono { get; set; }
    [Required, StringLength(32, MinimumLength = 8)] public string Numero { get; set; } = "";
}

public sealed class DireccionClienteSolicitud
{
    [Range(0, short.MaxValue)] public int Correlativo { get; set; }
    [Range(1, int.MaxValue)] public int CodigoTipoDireccion { get; set; }
    [Range(1, int.MaxValue)] public int CodigoDepartamento { get; set; }
    [Range(1, int.MaxValue)] public int CodigoMunicipio { get; set; }
    [Required, StringLength(300)] public string Detalle { get; set; } = "";
}

public class ReferenciaClienteSolicitud : NombresPersonaSolicitud
{
    [Range(1, int.MaxValue)] public int? CodigoReferencia { get; set; }
    [Required, StringLength(200)] public string LugarTrabajo { get; set; } = "";
    [Range(1, int.MaxValue)] public int CodigoTipoReferencia { get; set; }
    [Required, StringLength(100)] public string ParentescoRelacion { get; set; } = "";
    [Required] public List<TelefonoClienteSolicitud> Telefonos { get; set; } = [];
    [Required] public List<DireccionClienteSolicitud> Direcciones { get; set; } = [];
}

public class ClienteSolicitud : NombresPersonaSolicitud
{
    [Required, RegularExpression("^[0-9]{13}$", ErrorMessage = "El DPI debe tener 13 dígitos.")]
    public string DPI { get; set; } = "";
    [Required, StringLength(20)] public string NIT { get; set; } = "";
    [Required, EmailAddress, StringLength(254)] public string CorreoElectronico { get; set; } = "";
    [Required] public DateTime? FechaNacimiento { get; set; }
    [Required] public List<TelefonoClienteSolicitud> Telefonos { get; set; } = [];
    [Required] public List<DireccionClienteSolicitud> Direcciones { get; set; } = [];
    [Required] public List<ReferenciaClienteSolicitud> Referencias { get; set; } = [];
}

public sealed class ClienteFicha : ClienteSolicitud
{
    public int CodigoCliente { get; set; }
    public int CodigoPersona { get; set; }
    public string NombreCompleto => string.Join(" ", new[] { PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido }.Where(x => !string.IsNullOrWhiteSpace(x)));
    public int ReferenciasCompletas => Referencias.Count(r => r.Telefonos.Count > 0 && r.Direcciones.Count > 0);
    public List<string> Faltantes
    {
        get
        {
            var faltantes = new List<string>();
            if (Telefonos.Count == 0) faltantes.Add("Agrega al menos un teléfono del cliente.");
            if (Direcciones.Count == 0) faltantes.Add("Agrega al menos una dirección del cliente.");
            if (ReferenciasCompletas < 3) faltantes.Add($"Completa al menos tres referencias distintas con teléfono y dirección; tienes {ReferenciasCompletas}.");
            return faltantes;
        }
    }
}
