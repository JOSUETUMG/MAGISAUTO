using System.Data;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

// Sesión compartida por Clientes y Fiadores: todos los nombres se eligen en código, nunca desde HTTP.
internal sealed class ClienteSqlSesion(SqlConnection conexion, SqlTransaction? transaccion)
{
    private SqlCommand Comando(string nombre)
    {
        var cmd = conexion.CreateCommand();
        cmd.Transaction = transaccion;
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = nombre;
        cmd.CommandTimeout = 15;
        return cmd;
    }

    public async Task<List<Dictionary<string, object?>>> Leer(string entidad, CancellationToken ct)
    {
        await using var cmd = Comando($"api.{entidad}_Listar");
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        var rows = new List<Dictionary<string, object?>>();
        while (await reader.ReadAsync(ct))
        {
            var row = new Dictionary<string, object?>();
            for (int i = 0; i < reader.FieldCount; i++)
                row[JsonNamingPolicy.CamelCase.ConvertName(reader.GetName(i))] = reader.IsDBNull(i) ? null : reader.GetValue(i);
            rows.Add(row);
        }
        return rows;
    }

    public async Task<object?> Ejecutar(string procedimiento, Dictionary<string, object?> valores, CancellationToken ct)
    {
        await using var cmd = Comando($"api.{procedimiento}");
        foreach (var (nombre, valor) in valores)
        {
            var tipo = nombre switch
            {
                "DPI" or "NIT" or "Numero" => SqlDbType.VarChar,
                "FechaNacimiento" => SqlDbType.Date,
                "Genero" => SqlDbType.Char,
                "Correlativo" => SqlDbType.SmallInt,
                _ when nombre.StartsWith("Codigo", StringComparison.Ordinal) => SqlDbType.Int,
                _ => SqlDbType.NVarChar
            };
            var p = cmd.Parameters.Add("@" + nombre, tipo);
            p.Value = valor ?? DBNull.Value;
        }
        return await cmd.ExecuteScalarAsync(ct);
    }
}
