using MAGISAUTO.API.Modelos;

namespace MAGISAUTO.API.Datos;

public interface IVendedorRepositorio
{
    Task<IReadOnlyList<VendedorRespuesta>> ConsultarAsync(string? criterio, int? codigoAgencia, CancellationToken ct);
    Task<int> GuardarAsync(int? codigo, VendedorSolicitud solicitud, CancellationToken ct);
    Task EliminarAsync(int codigo, CancellationToken ct);
}
