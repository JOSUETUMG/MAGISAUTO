using System.Data;
using System.Globalization;
using System.Text.Json;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

public sealed class VehiculoRepositorio(ConexionSqlFactory conexiones)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private static int Id(Fila f, string campo) => Convert.ToInt32(f[campo]);

    private async Task<T> Consultar<T>(Func<ClienteSqlSesion, Task<T>> accion, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var resultado = await accion(new ClienteSqlSesion(cn, tx));
        await tx.CommitAsync(ct);
        return resultado;
    }

    public Task<object> Catalogos(CancellationToken ct) => Consultar<object>(async db => new
    {
        Marcas = await db.Leer("Marca", ct),
        Lineas = await db.Leer("Linea", ct),
        TiposGarantia = await db.Leer("TipoGarantia", ct)
    }, ct);

    public Task<IReadOnlyList<VehiculoFicha>> Listar(string? criterio, int? codigoMarca, CancellationToken ct) => Consultar<IReadOnlyList<VehiculoFicha>>(async db =>
    {
        var vehiculos = await db.Leer("Garantia", ct);
        var marcas = (await db.Leer("Marca", ct)).ToDictionary(m => Id(m, "codigoMarca"));
        var lineas = (await db.Leer("Linea", ct)).ToDictionary(l => (Id(l, "codigoMarca"), Id(l, "codigoLinea")));
        var tipos = (await db.Leer("TipoGarantia", ct)).ToDictionary(t => Id(t, "codigoTipoGarantia"));
        var creditos = await db.Leer("Credito", ct);
        var valoraciones = await db.Leer("Depreciacion", ct);
        var resultado = new List<VehiculoFicha>();
        foreach (var fila in vehiculos)
        {
            var item = JsonSerializer.Deserialize<VehiculoFicha>(JsonSerializer.Serialize(fila, Json), Json)!;
            if (codigoMarca is not null && item.CodigoMarca != codigoMarca) continue;
            item.Marca = (string)marcas[item.CodigoMarca]["descripcion"]!;
            item.Linea = (string)lineas[(item.CodigoMarca, item.CodigoLinea)]["descripcion"]!;
            item.TipoGarantia = (string)tipos[item.CodigoTipoGarantia]["descripcion"]!;
            var asociados = creditos.Where(c => Id(c, "codigoGarantia") == item.CodigoGarantia).ToList();
            item.TieneHistorialContractual = asociados.Any(c => c["fechaAprobacion"] is not null);
            item.CreditosVinculados = asociados.Count;
            item.ValoracionesRegistradas = valoraciones.Count(v => Id(v, "codigoGarantia") == item.CodigoGarantia);
            if (criterio is null || new[] { item.CodigoGarantia.ToString(CultureInfo.InvariantCulture), item.VIN, item.Placa ?? "",
                    item.Marca, item.Linea, item.Anio.ToString(CultureInfo.InvariantCulture) }
                .Any(v => v.Contains(criterio, StringComparison.OrdinalIgnoreCase))) resultado.Add(item);
        }
        return resultado;
    }, ct);

    public async Task<int> Guardar(int? codigo, VehiculoSolicitud s, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = cn.CreateCommand();
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = codigo is null ? "api.Garantia_Insertar" : "api.Garantia_Actualizar";
        cmd.CommandTimeout = 15;
        if (codigo is not null) cmd.Parameters.Add("@CodigoGarantia", SqlDbType.Int).Value = codigo.Value;
        cmd.Parameters.Add("@VIN", SqlDbType.VarChar, 17).Value = s.VIN;
        cmd.Parameters.Add("@CodigoMarca", SqlDbType.Int).Value = s.CodigoMarca;
        cmd.Parameters.Add("@CodigoLinea", SqlDbType.Int).Value = s.CodigoLinea;
        cmd.Parameters.Add("@Anio", SqlDbType.SmallInt).Value = s.Anio;
        var precio = cmd.Parameters.Add("@ValorAgencia", SqlDbType.Decimal);
        precio.Precision = 18; precio.Scale = 2; precio.Value = s.ValorAgencia;
        cmd.Parameters.Add("@Placa", SqlDbType.VarChar, 20).Value = (object?)s.Placa ?? DBNull.Value;
        cmd.Parameters.Add("@CodigoTipoGarantia", SqlDbType.Int).Value = s.CodigoTipoGarantia;
        // El alcance y la restricción SQL admiten únicamente vehículos nuevos de agencia.
        cmd.Parameters.Add("@EsNuevo", SqlDbType.Bit).Value = true;
        try
        {
            if (codigo is null) return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct));
            await cmd.ExecuteNonQueryAsync(ct);
            return codigo.Value;
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        { throw new OperacionCatalogoException(409, "Ya existe un vehículo con ese VIN o esa placa. Revisa el registro existente."); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw new OperacionCatalogoException(409, "Revisa la marca, la línea correspondiente y el tipo de garantía seleccionado."); }
        catch (SqlException ex) when (ex.Number == 51005)
        { throw new OperacionCatalogoException(409, "El vehículo tiene historial de un crédito aprobado. Sus datos se conservan y no se pueden editar."); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El vehículo ya no existe. Actualiza el listado."); }
    }

    public async Task Eliminar(int codigo, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = cn.CreateCommand();
        cmd.CommandType = CommandType.StoredProcedure; cmd.CommandText = "api.Garantia_Eliminar"; cmd.CommandTimeout = 15;
        cmd.Parameters.Add("@CodigoGarantia", SqlDbType.Int).Value = codigo;
        try { await cmd.ExecuteNonQueryAsync(ct); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw new OperacionCatalogoException(409, "No se puede eliminar el vehículo porque tiene créditos o valoraciones vinculadas. El vehículo se conserva."); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El vehículo ya no existe. Actualiza el listado."); }
    }
}
