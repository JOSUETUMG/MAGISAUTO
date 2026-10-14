using System.ComponentModel.DataAnnotations;

namespace MAGISAUTO.API.Modelos;

public sealed class VendedorSolicitud
{
    [Required(ErrorMessage = "Escribe el código de empleado.")]
    [StringLength(30, ErrorMessage = "El código de empleado admite hasta 30 caracteres.")]
    public string CodigoEmpleado { get; init; } = string.Empty;

    [Required(ErrorMessage = "Escribe el DPI.")]
    [RegularExpression("^[0-9]{13}$", ErrorMessage = "El DPI debe contener exactamente 13 dígitos.")]
    public string DPI { get; init; } = string.Empty;

    [Required(ErrorMessage = "Escribe el primer nombre.")]
    [StringLength(64, ErrorMessage = "El primer nombre admite hasta 64 caracteres.")]
    public string PrimerNombre { get; init; } = string.Empty;

    [StringLength(64, ErrorMessage = "El segundo nombre admite hasta 64 caracteres.")]
    public string? SegundoNombre { get; init; }

    [Required(ErrorMessage = "Escribe el primer apellido.")]
    [StringLength(64, ErrorMessage = "El primer apellido admite hasta 64 caracteres.")]
    public string PrimerApellido { get; init; } = string.Empty;

    [StringLength(64, ErrorMessage = "El segundo apellido admite hasta 64 caracteres.")]
    public string? SegundoApellido { get; init; }

    [Range(1, int.MaxValue, ErrorMessage = "Selecciona una agencia.")]
    public int CodigoAgencia { get; init; }
}
