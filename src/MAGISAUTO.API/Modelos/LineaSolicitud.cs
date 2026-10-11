using System.ComponentModel.DataAnnotations;

namespace MAGISAUTO.API.Modelos;

public sealed class LineaCrearSolicitud : LineaEditarSolicitud
{
    [Range(1, int.MaxValue, ErrorMessage = "Selecciona una marca válida.")]
    public int CodigoMarca { get; init; }

    [Range(1, int.MaxValue, ErrorMessage = "El código de línea debe ser un entero mayor que cero.")]
    public int CodigoLinea { get; init; }
}

public class LineaEditarSolicitud
{
    [Required(ErrorMessage = "Escribe el nombre de la línea.")]
    [StringLength(128, ErrorMessage = "El nombre admite hasta 128 caracteres.")]
    public string Descripcion { get; init; } = string.Empty;
}
