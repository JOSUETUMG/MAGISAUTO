using System.ComponentModel.DataAnnotations;

namespace MAGISAUTO.API.Modelos;

public sealed class MarcaCrearSolicitud : MarcaEditarSolicitud
{
    [Range(1, int.MaxValue, ErrorMessage = "El código debe ser un entero mayor que cero.")]
    public int CodigoMarca { get; init; }
}

public class MarcaEditarSolicitud
{
    [Required(ErrorMessage = "Escribe el nombre de la marca.")]
    [StringLength(128, ErrorMessage = "El nombre admite hasta 128 caracteres.")]
    public string Descripcion { get; init; } = string.Empty;
}
