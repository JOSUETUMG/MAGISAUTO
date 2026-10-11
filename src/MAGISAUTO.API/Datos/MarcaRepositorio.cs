using System.Data;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed class MarcaRepositorio(ConexionSqlFactory conexiones) : IMarcaRepositorio
{
    public Task CrearAsync(int codigo, string descripcion, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Marca_Insertar", codigo, descripcion, cancellationToken);

    public Task ActualizarAsync(int codigo, string descripcion, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Marca_Actualizar", codigo, descripcion, cancellationToken);

    public Task EliminarAsync(int codigo, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Marca_Eliminar", codigo, null, cancellationToken);

    private async Task EjecutarAsync(string procedimiento, int codigo, string? descripcion,
        CancellationToken cancellationToken)
    {
        await using var conexion = conexiones.Crear();
        await conexion.OpenAsync(cancellationToken);
        await using var comando = conexion.CreateCommand();
        comando.CommandType = CommandType.StoredProcedure;
        comando.CommandText = procedimiento;
        comando.CommandTimeout = 10;
        comando.Parameters.Add("@CodigoMarca", SqlDbType.Int).Value = codigo;
        if (descripcion is not null)
            comando.Parameters.Add("@Descripcion", SqlDbType.NVarChar, 128).Value = descripcion;
        try
        {
            await comando.ExecuteNonQueryAsync(cancellationToken);
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            throw new OperacionCatalogoException(409, "Ya existe una marca con ese código. Usa otro código.");
        }
        catch (SqlException ex) when (ex.Number == 51008)
        {
            throw new OperacionCatalogoException(404, "La marca ya no existe. Actualiza el listado.");
        }
        catch (SqlException ex) when (ex.Number == 547 && descripcion is null)
        {
            throw new OperacionCatalogoException(409, "No se puede eliminar esta marca porque tiene líneas asociadas.");
        }
    }

    public async Task<IReadOnlyList<MarcaRespuesta>> ConsultarAsync(
        string? criterio, CancellationToken cancellationToken)
    {
        await using var conexion = conexiones.Crear();
        await conexion.OpenAsync(cancellationToken);
        await using var comando = conexion.CreateCommand();
        comando.CommandType = CommandType.StoredProcedure;
        comando.CommandText = criterio is null ? "api.Marca_Listar" : "api.Marca_Buscar";
        comando.CommandTimeout = 10;

        if (criterio is not null)
        {
            comando.Parameters.Add("@Criterio", SqlDbType.NVarChar, 200).Value = criterio;
        }

        var marcas = new List<MarcaRespuesta>();
        await using var lector = await comando.ExecuteReaderAsync(cancellationToken);
        var codigo = lector.GetOrdinal("CodigoMarca");
        var descripcion = lector.GetOrdinal("Descripcion");

        while (await lector.ReadAsync(cancellationToken))
        {
            marcas.Add(new MarcaRespuesta(lector.GetInt32(codigo), lector.GetString(descripcion)));
        }

        return marcas;
    }
}
