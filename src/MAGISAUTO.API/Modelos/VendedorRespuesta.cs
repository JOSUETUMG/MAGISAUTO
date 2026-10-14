namespace MAGISAUTO.API.Modelos;

public sealed record VendedorRespuesta(int CodigoVendedor, int CodigoPersona, string CodigoEmpleado,
    string DPI, string PrimerNombre, string? SegundoNombre, string PrimerApellido, string? SegundoApellido,
    int CodigoAgencia, string NombreAgencia, string Region)
{
    public string NombreCompleto => string.Join(" ", new[] { PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido }
        .Where(x => !string.IsNullOrWhiteSpace(x)));
}
