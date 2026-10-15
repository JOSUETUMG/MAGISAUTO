using System.Data;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed class CatalogoAuxiliarRepositorio(ConexionSqlFactory conexiones)
{
    public static void ValidarDepartamento(DefinicionAuxiliar d, int? departamento, bool requerido)
    {
        if ((!d.UsaDepartamento && departamento is not null) || departamento <= 0
            || (d.UsaDepartamento && requerido && departamento is null))
            throw new OperacionCatalogoException(400, "Indica un departamento válido únicamente para Municipios.");
    }

    private static void ValidarDatos(DefinicionAuxiliar d, CatalogoAuxiliarEditar s)
    {
        if (string.IsNullOrWhiteSpace(s.Descripcion) || s.Descripcion.Length > 128)
            throw new OperacionCatalogoException(400, "Escribe una descripción de hasta 128 caracteres.");
        if (d.UsaReferenciaBancaria != s.RequiereReferencia.HasValue)
            throw new OperacionCatalogoException(400, "Indica si requiere referencia bancaria únicamente para Tipos de pago.");
    }

    private static SqlCommand Comando(SqlConnection cn, DefinicionAuxiliar d, string operacion)
    {
        var cmd = cn.CreateCommand();
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = $"api.{d.Entidad}_{operacion}";
        cmd.CommandTimeout = 15;
        return cmd;
    }

    public async Task<List<CatalogoAuxiliarFila>> Listar(DefinicionAuxiliar d, string? criterio,
        int? departamento, CancellationToken ct)
    {
        ValidarDepartamento(d, departamento, false);
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = Comando(cn, d, criterio is null ? "Listar" : "Buscar");
        if (criterio is not null) cmd.Parameters.Add("@Criterio", SqlDbType.NVarChar, 200).Value = criterio;
        var filas = new List<CatalogoAuxiliarFila>();
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            int? dep = d.UsaDepartamento ? reader.GetInt32(reader.GetOrdinal("CodigoDepartamento")) : null;
            if (departamento is not null && dep != departamento) continue;
            filas.Add(new(reader.GetInt32(reader.GetOrdinal(d.Clave)), reader.GetString(reader.GetOrdinal("Descripcion")),
                dep, d.UsaReferenciaBancaria ? reader.GetBoolean(reader.GetOrdinal("RequiereReferencia")) : null));
        }
        return filas;
    }

    public async Task Guardar(DefinicionAuxiliar d, int codigo, int? departamento,
        CatalogoAuxiliarEditar? datos, bool crear, CancellationToken ct)
    {
        ValidarDepartamento(d, departamento, true);
        if (codigo <= 0) throw new OperacionCatalogoException(400, "El código debe ser un entero positivo.");
        if (datos is not null) ValidarDatos(d, datos);
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = Comando(cn, d, datos is null ? "Eliminar" : crear ? "Insertar" : "Actualizar");
        cmd.Parameters.Add("@" + d.Clave, SqlDbType.Int).Value = codigo;
        if (d.UsaDepartamento) cmd.Parameters.Add("@CodigoDepartamento", SqlDbType.Int).Value = departamento!.Value;
        if (datos is not null)
        {
            cmd.Parameters.Add("@Descripcion", SqlDbType.NVarChar, 128).Value = datos.Descripcion.Trim();
            if (d.UsaReferenciaBancaria) cmd.Parameters.Add("@RequiereReferencia", SqlDbType.Bit).Value = datos.RequiereReferencia!.Value;
        }
        try
        {
            // Consumir OUTPUT y el final del SP: una fila emitida no sustituye un COMMIT correcto.
            await using var reader = await cmd.ExecuteReaderAsync(ct);
            do { while (await reader.ReadAsync(ct)) { } } while (await reader.NextResultAsync(ct));
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        { throw new OperacionCatalogoException(409, d.UsaDepartamento ? "Ese código de municipio ya existe en el departamento seleccionado." : "Ese código ya existe en el catálogo. Usa uno disponible."); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El registro ya no existe. Actualiza el catálogo."); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw new OperacionCatalogoException(409, datos is null ? "No se puede eliminar: el registro está relacionado con otros datos. Se conserva para protegerlos." : "Revisa la descripción y que el departamento seleccionado exista."); }
    }
}
