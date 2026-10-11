using System.Data;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed class LineaRepositorio(ConexionSqlFactory conexiones) : ILineaRepositorio
{
    public Task CrearAsync(int marca, int codigo, string descripcion, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Linea_Insertar", marca, codigo, descripcion, cancellationToken);

    public Task ActualizarAsync(int marca, int codigo, string descripcion, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Linea_Actualizar", marca, codigo, descripcion, cancellationToken);

    public Task EliminarAsync(int marca, int codigo, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Linea_Eliminar", marca, codigo, null, cancellationToken);

    private async Task EjecutarAsync(string procedimiento, int marca, int codigo, string? descripcion,
        CancellationToken cancellationToken)
    {
        await using var conexion = conexiones.Crear();
        await conexion.OpenAsync(cancellationToken);
        await using var comando = conexion.CreateCommand();
        comando.CommandType = CommandType.StoredProcedure;
        comando.CommandText = procedimiento;
        comando.CommandTimeout = 10;
        comando.Parameters.Add("@CodigoMarca", SqlDbType.Int).Value = marca;
        comando.Parameters.Add("@CodigoLinea", SqlDbType.Int).Value = codigo;
        if (descripcion is not null)
            comando.Parameters.Add("@Descripcion", SqlDbType.NVarChar, 128).Value = descripcion;
        try { await comando.ExecuteNonQueryAsync(cancellationToken); }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            throw new OperacionCatalogoException(409, "Ya existe una línea con ese código dentro de la marca seleccionada.");
        }
        catch (SqlException ex) when (ex.Number == 51008)
        {
            throw new OperacionCatalogoException(404, "La línea ya no existe en esa marca. Actualiza el listado.");
        }
        catch (SqlException ex) when (ex.Number == 547)
        {
            throw new OperacionCatalogoException(409, descripcion is null
                ? "No se puede eliminar esta línea porque tiene vehículos asociados."
                : "La marca seleccionada ya no existe. Actualiza el catálogo y selecciona otra marca.");
        }
    }

    public async Task<IReadOnlyList<LineaRespuesta>> ConsultarAsync(string? criterio, CancellationToken cancellationToken)
    {
        await using var conexion = conexiones.Crear();
        await conexion.OpenAsync(cancellationToken);
        await using var comando = conexion.CreateCommand();
        comando.CommandType = CommandType.StoredProcedure;
        comando.CommandText = criterio is null ? "api.Linea_Listar" : "api.Linea_Buscar";
        comando.CommandTimeout = 10;
        if (criterio is not null)
            comando.Parameters.Add("@Criterio", SqlDbType.NVarChar, 200).Value = criterio;
        var lineas = new List<LineaRespuesta>();
        await using var lector = await comando.ExecuteReaderAsync(cancellationToken);
        var marca = lector.GetOrdinal("CodigoMarca");
        var codigo = lector.GetOrdinal("CodigoLinea");
        var descripcion = lector.GetOrdinal("Descripcion");
        while (await lector.ReadAsync(cancellationToken))
            lineas.Add(new LineaRespuesta(lector.GetInt32(marca), lector.GetInt32(codigo), lector.GetString(descripcion)));
        return lineas;
    }
}
