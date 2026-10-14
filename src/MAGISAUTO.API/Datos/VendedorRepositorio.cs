using System.Data;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed class VendedorRepositorio(ConexionSqlFactory conexiones) : IVendedorRepositorio
{
    // Los procedimientos genéricos separan Persona y Vendedor. Una transacción exterior
    // conserva ambos cambios juntos y evita sobrescribir campos personales no editados aquí.
    private static SqlCommand Comando(SqlConnection cn, SqlTransaction? tx, string nombre)
    {
        var cmd = cn.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = nombre;
        cmd.CommandTimeout = 15;
        return cmd;
    }

    private static async Task<List<Dictionary<string, object>>> Leer(SqlConnection cn, SqlTransaction? tx, string proc, CancellationToken ct)
    {
        await using var cmd = Comando(cn, tx, proc);
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        var filas = new List<Dictionary<string, object>>();
        while (await reader.ReadAsync(ct))
        {
            var fila = new Dictionary<string, object>();
            for (var i = 0; i < reader.FieldCount; i++) fila[reader.GetName(i)] = reader.GetValue(i);
            filas.Add(fila);
        }
        return filas;
    }

    private static string? Texto(Dictionary<string, object> fila, string campo) =>
        fila[campo] is DBNull ? null : (string)fila[campo];

    private static string? Opcional(string? texto) => string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();

    private static void TextoParametro(SqlCommand cmd, string nombre, int longitud, string? valor, bool unicode = true) =>
        cmd.Parameters.Add(nombre, unicode ? SqlDbType.NVarChar : SqlDbType.VarChar, longitud).Value = (object?)valor ?? DBNull.Value;

    public async Task<IReadOnlyList<VendedorRespuesta>> ConsultarAsync(string? criterio, int? codigoAgencia, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        var vendedores = await Leer(cn, null, "api.Vendedor_Listar", ct);
        var personas = (await Leer(cn, null, "api.Persona_Listar", ct)).ToDictionary(p => (int)p["CodigoPersona"]);
        var agencias = (await Leer(cn, null, "api.Agencia_Listar", ct)).ToDictionary(a => (int)a["CodigoAgencia"]);
        var resultado = new List<VendedorRespuesta>();
        foreach (var vendedor in vendedores)
        {
            var agenciaId = (int)vendedor["CodigoAgencia"];
            if (codigoAgencia is not null && agenciaId != codigoAgencia) continue;
            // Una eliminación concurrente entre lecturas no debe romper el listado.
            if (!personas.TryGetValue((int)vendedor["CodigoPersona"], out var persona)
                || !agencias.TryGetValue(agenciaId, out var agencia)) continue;
            var item = new VendedorRespuesta((int)vendedor["CodigoVendedor"], (int)persona["CodigoPersona"],
                (string)vendedor["CodigoEmpleado"], Texto(persona, "DPI") ?? "",
                (string)persona["PrimerNombre"], Texto(persona, "SegundoNombre"),
                (string)persona["PrimerApellido"], Texto(persona, "SegundoApellido"),
                agenciaId, (string)agencia["Nombre"], (string)agencia["Region"]);
            // Filtro literal sobre datos obtenidos exclusivamente por procedimientos.
            if (criterio is null || new[] { item.CodigoVendedor.ToString(), item.CodigoEmpleado, item.DPI,
                    item.NombreCompleto, item.NombreAgencia, item.Region }
                .Any(texto => texto.Contains(criterio, StringComparison.OrdinalIgnoreCase))) resultado.Add(item);
        }
        return resultado;
    }

    public async Task<int> GuardarAsync(int? codigo, VendedorSolicitud s, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        try
        {
            var vendedores = await Leer(cn, tx, "api.Vendedor_Listar", ct);
            var vendedor = codigo is null ? null : vendedores.SingleOrDefault(v => (int)v["CodigoVendedor"] == codigo);
            if (codigo is not null && vendedor is null) throw new OperacionCatalogoException(404, "El vendedor ya no existe. Actualiza el listado.");
            var personas = await Leer(cn, tx, "api.Persona_Listar", ct);
            var persona = vendedor is null
                ? personas.SingleOrDefault(p => Texto(p, "DPI") == s.DPI)
                : personas.Single(p => (int)p["CodigoPersona"] == (int)vendedor["CodigoPersona"]);
            if (vendedor is not null && Texto(persona!, "DPI") != s.DPI)
                throw new OperacionCatalogoException(409, "El DPI identifica a la persona y se conserva al editar el vendedor.");
            if (vendedor is null && persona is not null)
            {
                if (vendedores.Any(v => (int)v["CodigoPersona"] == (int)persona["CodigoPersona"]))
                    throw new OperacionCatalogoException(409, "Esta persona ya está registrada como vendedor.");
                var nombres = new Dictionary<string, string?> { ["PrimerNombre"] = s.PrimerNombre.Trim(), ["SegundoNombre"] = Opcional(s.SegundoNombre),
                    ["PrimerApellido"] = s.PrimerApellido.Trim(), ["SegundoApellido"] = Opcional(s.SegundoApellido) };
                if (nombres.Any(n => !string.Equals(Texto(persona, n.Key), n.Value, StringComparison.OrdinalIgnoreCase)))
                    throw new OperacionCatalogoException(409, "El DPI ya pertenece a una persona registrada. Usa sus nombres y apellidos existentes para vincularla sin reemplazarlos.");
            }

            int personaId;
            if (persona is null || vendedor is not null)
            {
                await using var cmd = Comando(cn, tx, persona is null ? "api.Persona_Insertar" : "api.Persona_Actualizar");
                if (persona is not null) cmd.Parameters.Add("@CodigoPersona", SqlDbType.Int).Value = persona["CodigoPersona"];
                TextoParametro(cmd, "@DPI", 13, s.DPI, false);
                TextoParametro(cmd, "@PrimerNombre", 64, s.PrimerNombre.Trim());
                TextoParametro(cmd, "@SegundoNombre", 64, Opcional(s.SegundoNombre));
                TextoParametro(cmd, "@PrimerApellido", 64, s.PrimerApellido.Trim());
                TextoParametro(cmd, "@SegundoApellido", 64, Opcional(s.SegundoApellido));
                if (persona is not null)
                {
                    TextoParametro(cmd, "@NIT", 20, Texto(persona, "NIT"), false);
                    TextoParametro(cmd, "@CorreoElectronico", 254, Texto(persona, "CorreoElectronico"));
                    cmd.Parameters.Add("@FechaNacimiento", SqlDbType.Date).Value = persona["FechaNacimiento"];
                    cmd.Parameters.Add("@Genero", SqlDbType.Char, 1).Value = persona["Genero"];
                    await cmd.ExecuteNonQueryAsync(ct);
                    personaId = (int)persona["CodigoPersona"];
                }
                else personaId = Convert.ToInt32(await cmd.ExecuteScalarAsync(ct));
            }
            else personaId = (int)persona["CodigoPersona"];

            await using var guardar = Comando(cn, tx, codigo is null ? "api.Vendedor_Insertar" : "api.Vendedor_Actualizar");
            if (codigo is not null) guardar.Parameters.Add("@CodigoVendedor", SqlDbType.Int).Value = codigo.Value;
            TextoParametro(guardar, "@CodigoEmpleado", 30, s.CodigoEmpleado.Trim(), false);
            guardar.Parameters.Add("@CodigoPersona", SqlDbType.Int).Value = personaId;
            guardar.Parameters.Add("@CodigoAgencia", SqlDbType.Int).Value = s.CodigoAgencia;
            int id;
            if (codigo is null) id = Convert.ToInt32(await guardar.ExecuteScalarAsync(ct));
            else { await guardar.ExecuteNonQueryAsync(ct); id = codigo.Value; }
            await tx.CommitAsync(ct);
            return id;
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        { throw new OperacionCatalogoException(409, "Ya existe ese código de empleado o esa persona está registrada como vendedor."); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw new OperacionCatalogoException(409, "La agencia seleccionada ya no está disponible. Actualiza las agencias."); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El registro ya no existe. Actualiza el listado."); }
        catch (SqlException ex) when (ex.Number is 51009 or 51010 or 51011 or 51012 or 51013)
        { throw new OperacionCatalogoException(409, "Los datos de la persona no permiten esta operación. Conserva su identidad y los datos obligatorios de sus otros roles."); }
        // Dispose revierte la transacción exterior ante cualquier excepción, incluso validaciones de negocio.
    }

    public async Task EliminarAsync(int codigo, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = Comando(cn, null, "api.Vendedor_Eliminar");
        cmd.Parameters.Add("@CodigoVendedor", SqlDbType.Int).Value = codigo;
        try { await cmd.ExecuteNonQueryAsync(ct); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El vendedor ya no existe. Actualiza el listado."); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw new OperacionCatalogoException(409, "No se puede eliminar este vendedor porque tiene créditos asociados."); }
        // Se elimina el rol, no la Persona compartida con clientes, fiadores o referencias.
    }
}
