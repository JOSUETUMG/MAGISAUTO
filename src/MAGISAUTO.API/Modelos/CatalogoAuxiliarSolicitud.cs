using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Modelos;

// No ignorar códigos adicionales al editar: las claves solo se reciben en la ruta/query.
[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class CatalogoAuxiliarEditar
{
    [Required, StringLength(128)] public string Descripcion { get; set; } = "";
    public bool? RequiereReferencia { get; set; }
}

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public sealed class CatalogoAuxiliarCrear : CatalogoAuxiliarEditar
{
    [Range(1, int.MaxValue)] public int Codigo { get; set; }
    [Range(1, int.MaxValue)] public int? CodigoDepartamento { get; set; }
}

public sealed record CatalogoAuxiliarFila(int Codigo, string Descripcion,
    int? CodigoDepartamento, bool? RequiereReferencia);
