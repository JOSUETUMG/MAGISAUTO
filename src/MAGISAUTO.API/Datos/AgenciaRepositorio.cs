using System.Data;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed class AgenciaRepositorio(ConexionSqlFactory conexiones) : IAgenciaRepositorio
{
    public async Task<int> CrearAsync(string nombre, string region, CancellationToken cancellationToken)
    {
        await using var conexion = conexiones.Crear();
        await conexion.OpenAsync(cancellationToken);
        await using var comando = conexion.CreateCommand();
        comando.CommandType = CommandType.StoredProcedure;
        comando.CommandText = "api.Agencia_Insertar";
        comando.CommandTimeout = 10;
        AgregarDatos(comando, nombre, region);
        // El correlativo lo asigna SQL Server; el procedimiento devuelve OUTPUT INSERTED como Id.
        return Convert.ToInt32(await comando.ExecuteScalarAsync(cancellationToken));
    }

    public Task ActualizarAsync(int codigo, string nombre, string region, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Agencia_Actualizar", codigo, nombre, region, cancellationToken);

    public Task EliminarAsync(int codigo, CancellationToken cancellationToken) =>
        EjecutarAsync("api.Agencia_Eliminar", codigo, null, null, cancellationToken);

    private static void AgregarDatos(SqlCommand comando, string nombre, string region)
    {
        comando.Parameters.Add("@Nombre", SqlDbType.NVarChar, 128).Value = nombre;
        comando.Parameters.Add("@Region", SqlDbType.NVarChar, 128).Value = region;
    }

    private async Task EjecutarAsync(string procedimiento, int codigo, string? nombre, string? region,
        CancellationToken cancellationToken)
    {
        await using var conexion = conexiones.Crear();
        await conexion.OpenAsync(cancellationToken);
        await using var comando = conexion.CreateCommand();
        comando.CommandType = CommandType.StoredProcedure;
        comando.CommandText = procedimiento;
        comando.CommandTimeout = 10;
        comando.Parameters.Add("@CodigoAgencia", SqlDbType.Int).Value = codigo;
        if (nombre is not null && region is not null) AgregarDatos(comando, nombre, region);
        try { await comando.ExecuteNonQueryAsync(cancellationToken); }
        catch (SqlException ex) when (ex.Number == 51008)
        {
            throw new OperacionCatalogoException(404, "La agencia ya no existe. Actualiza el listado.");
        }
        catch (SqlException ex) when (ex.Number == 547)
        {
            throw new OperacionCatalogoException(409, "No se puede eliminar esta agencia porque tiene vendedores o créditos asociados.");
        }
    }

    public async Task<IReadOnlyList<AgenciaRespuesta>> ConsultarAsync(string? criterio, CancellationToken cancellationToken)
    {
        await using var conexion = conexiones.Crear();
        await conexion.OpenAsync(cancellationToken);
        await using var comando = conexion.CreateCommand();
        comando.CommandType = CommandType.StoredProcedure;
        comando.CommandText = criterio is null ? "api.Agencia_Listar" : "api.Agencia_Buscar";
        comando.CommandTimeout = 10;
        if (criterio is not null) comando.Parameters.Add("@Criterio", SqlDbType.NVarChar, 200).Value = criterio;
        var agencias = new List<AgenciaRespuesta>();
        await using var lector = await comando.ExecuteReaderAsync(cancellationToken);
        var codigo = lector.GetOrdinal("CodigoAgencia");
        var nombre = lector.GetOrdinal("Nombre");
        var region = lector.GetOrdinal("Region");
        while (await lector.ReadAsync(cancellationToken))
            agencias.Add(new AgenciaRespuesta(lector.GetInt32(codigo), lector.GetString(nombre), lector.GetString(region)));
        return agencias;
    }
}
