using MAGISAUTO.API.Modelos;

namespace MAGISAUTO.API.Datos;

public interface IAgenciaRepositorio
{
    Task<IReadOnlyList<AgenciaRespuesta>> ConsultarAsync(string? criterio, CancellationToken cancellationToken);
    Task<int> CrearAsync(string nombre, string region, CancellationToken cancellationToken);
    Task ActualizarAsync(int codigo, string nombre, string region, CancellationToken cancellationToken);
    Task EliminarAsync(int codigo, CancellationToken cancellationToken);
}
