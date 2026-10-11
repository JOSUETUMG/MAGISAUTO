using MAGISAUTO.API.Modelos;

namespace MAGISAUTO.API.Datos;

public interface IMarcaRepositorio
{
    Task CrearAsync(int codigo, string descripcion, CancellationToken cancellationToken);
    Task ActualizarAsync(int codigo, string descripcion, CancellationToken cancellationToken);
    Task EliminarAsync(int codigo, CancellationToken cancellationToken);
    Task<IReadOnlyList<MarcaRespuesta>> ConsultarAsync(
        string? criterio, CancellationToken cancellationToken);
}
