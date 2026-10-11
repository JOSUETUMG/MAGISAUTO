using MAGISAUTO.API.Modelos;

namespace MAGISAUTO.API.Datos;

public interface ILineaRepositorio
{
    Task<IReadOnlyList<LineaRespuesta>> ConsultarAsync(string? criterio, CancellationToken cancellationToken);
    Task CrearAsync(int marca, int codigo, string descripcion, CancellationToken cancellationToken);
    Task ActualizarAsync(int marca, int codigo, string descripcion, CancellationToken cancellationToken);
    Task EliminarAsync(int marca, int codigo, CancellationToken cancellationToken);
}
