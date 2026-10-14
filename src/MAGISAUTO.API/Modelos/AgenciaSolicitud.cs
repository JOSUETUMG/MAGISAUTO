using System.ComponentModel.DataAnnotations;

namespace MAGISAUTO.API.Modelos;

public sealed class AgenciaSolicitud
{
    [Required(ErrorMessage = "Escribe el nombre de la agencia.")]
    [StringLength(128, ErrorMessage = "El nombre admite hasta 128 caracteres.")]
    public string Nombre { get; init; } = string.Empty;

    [Required(ErrorMessage = "Escribe la región de la agencia.")]
    [StringLength(128, ErrorMessage = "La región admite hasta 128 caracteres.")]
    public string Region { get; init; } = string.Empty;
}
