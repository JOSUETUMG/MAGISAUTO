using System.Data;
using System.Text.Json;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

public sealed class ValoracionRepositorio(ConexionSqlFactory conexiones)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private static int Id(Fila fila, string campo) => Convert.ToInt32(fila[campo]);

    private async Task<T> Consultar<T>(Func<ClienteSqlSesion, Task<T>> accion, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var resultado = await accion(new ClienteSqlSesion(cn, tx));
        await tx.CommitAsync(ct);
        return resultado;
    }

    public Task<IReadOnlyList<ValoracionFicha>> Listar(int? codigoGarantia, string? criterio, CancellationToken ct) => Consultar<IReadOnlyList<ValoracionFicha>>(async db =>
    {
        var valoraciones = await db.Leer("Depreciacion", ct);
        var garantias = (await db.Leer("Garantia", ct)).ToDictionary(g => Id(g, "codigoGarantia"));
        var marcas = (await db.Leer("Marca", ct)).ToDictionary(m => Id(m, "codigoMarca"));
        var lineas = (await db.Leer("Linea", ct)).ToDictionary(l => (Id(l, "codigoMarca"), Id(l, "codigoLinea")));
        var creditos = await db.Leer("Credito", ct);
        var resultado = new List<ValoracionFicha>();
        foreach (var fila in valoraciones)
        {
            // SqlClient materializa un campo date como DateTime; DateOnly espera el formato ISO de fecha sin hora.
            fila["fechaValoracion"] = Convert.ToDateTime(fila["fechaValoracion"]).ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);
            var item = JsonSerializer.Deserialize<ValoracionFicha>(JsonSerializer.Serialize(fila, Json), Json)!;
            // SQL guarda el porcentaje como fracción; la API presenta unidades humanas, igual que Parámetros y Créditos.
            item.Porcentaje *= 100m;
            if (codigoGarantia is not null && item.CodigoGarantia != codigoGarantia) continue;
            if (!garantias.TryGetValue(item.CodigoGarantia, out var garantia)) continue;
            var marca = (string)marcas[Id(garantia, "codigoMarca")]["descripcion"]!;
            var linea = (string)lineas[(Id(garantia, "codigoMarca"), Id(garantia, "codigoLinea"))]["descripcion"]!;
            item.Vehiculo = $"{marca} · {linea} · VIN {garantia["vin"]}";
            item.ProtegidaPorContrato = creditos.Any(c => Id(c, "codigoGarantia") == item.CodigoGarantia && c["fechaAprobacion"] is not null);
            if (criterio is null || new[] { item.CodigoDepreciacion.ToString(), item.CodigoGarantia.ToString(), item.FechaValoracion.ToString("yyyy-MM-dd"), item.Observacion, item.Vehiculo }
                .Any(valor => valor.Contains(criterio, StringComparison.OrdinalIgnoreCase))) resultado.Add(item);
        }
        return resultado.OrderByDescending(v => v.FechaValoracion).ThenByDescending(v => v.CodigoDepreciacion).ToList();
    }, ct);

    public async Task<ValoracionFicha> Obtener(int codigo, CancellationToken ct) =>
        (await Listar(null, null, ct)).SingleOrDefault(v => v.CodigoDepreciacion == codigo)
        ?? throw new OperacionCatalogoException(404, "La valoración ya no existe. Actualiza el historial.");

    public async Task<int> Guardar(int? codigo, ValoracionSolicitud solicitud, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = cn.CreateCommand();
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = codigo is null ? "api.Depreciacion_Insertar" : "api.Depreciacion_Actualizar";
        cmd.CommandTimeout = 15;
        if (codigo is not null) cmd.Parameters.Add("@CodigoDepreciacion", SqlDbType.Int).Value = codigo.Value;
        cmd.Parameters.Add("@CodigoGarantia", SqlDbType.Int).Value = solicitud.CodigoGarantia;
        cmd.Parameters.Add("@FechaValoracion", SqlDbType.Date).Value = solicitud.FechaValoracion.ToDateTime(TimeOnly.MinValue);
        var original = cmd.Parameters.Add("@ValorOriginal", SqlDbType.Decimal); original.Precision = 18; original.Scale = 2; original.Value = solicitud.ValorOriginal;
        var porcentaje = cmd.Parameters.Add("@Porcentaje", SqlDbType.Decimal); porcentaje.Precision = 9; porcentaje.Scale = 6; porcentaje.Value = solicitud.Porcentaje / 100m;
        cmd.Parameters.Add("@Observacion", SqlDbType.NVarChar, 300).Value = solicitud.Observacion;
        try
        {
            if (codigo is null) return Convert.ToInt32(await cmd.ExecuteScalarAsync(ct));
            await cmd.ExecuteNonQueryAsync(ct); return codigo.Value;
        }
        catch (SqlException ex) when (ex.Number is 51006)
        { throw new OperacionCatalogoException(400, "La valoración no puede tener una fecha futura."); }
        catch (SqlException ex) when (ex.Number is 51014)
        { throw new OperacionCatalogoException(409, "La valoración forma parte del historial contractual. Registra una nueva para conservarla."); }
        catch (SqlException ex) when (ex.Number is 547)
        { throw new OperacionCatalogoException(409, "El vehículo seleccionado ya no existe. Actualiza el historial."); }
        catch (SqlException ex) when (ex.Number is 51008)
        { throw new OperacionCatalogoException(404, "La valoración ya no existe. Actualiza el historial."); }
    }

    public async Task Eliminar(int codigo, CancellationToken ct)
    {
        await using var cn = conexiones.Crear(); await cn.OpenAsync(ct);
        await using var cmd = cn.CreateCommand(); cmd.CommandType = CommandType.StoredProcedure; cmd.CommandText = "api.Depreciacion_Eliminar";
        cmd.Parameters.Add("@CodigoDepreciacion", SqlDbType.Int).Value = codigo;
        try { await cmd.ExecuteNonQueryAsync(ct); }
        catch (SqlException ex) when (ex.Number is 51014)
        { throw new OperacionCatalogoException(409, "La valoración forma parte del historial contractual y se conserva."); }
        catch (SqlException ex) when (ex.Number is 51008)
        { throw new OperacionCatalogoException(404, "La valoración ya no existe. Actualiza el historial."); }
    }
}
