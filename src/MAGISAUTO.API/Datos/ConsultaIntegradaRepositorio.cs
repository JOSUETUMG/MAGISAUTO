using System.Data;
using System.Globalization;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed record DefinicionConsultaIntegrada(string Id, string Titulo, string Ayuda);

public sealed class ConsultaIntegradaRepositorio(ConexionSqlFactory factory)
{
    // Solo esta lista interna puede elegir procedimientos; nunca un nombre enviado por el cliente.
    private static readonly Dictionary<string, (string Entidad, string Titulo, string Ayuda)> Catalogo = new()
    {
        ["personas"] = ("Persona", "Personas", "Código, DPI, NIT, nombres, apellidos, nacimiento, género o correo. Incluye personas sin un rol vigente."),
        ["telefonos"] = ("Telefono", "Teléfonos", "Código de persona, correlativo, código de tipo o número de teléfono."),
        ["direcciones"] = ("Direccion", "Direcciones", "Código de persona, correlativo, códigos de tipo, departamento o municipio, o detalle de la dirección."),
        ["referencias"] = ("Referencia", "Referencias", "Código de referencia, código de persona o lugar de trabajo. Incluye fichas sin vínculos con clientes."),
        ["vinculos-referencias"] = ("DetalleReferencia", "Referencias por cliente", "Código de cliente, referencia o tipo de referencia, o parentesco/relación."),
        ["fiadores-creditos"] = ("CreditoFiador", "Fiadores por crédito", "Número de crédito o código de fiador. Incluye asignaciones de borradores y contratos."),
        ["cuotas"] = ("DetalleCuota", "Cuotas", "Consulta global por crédito, cuota, vencimiento o importe. Solo se modifica la simulación de borradores; aprobar genera el plan definitivo."),
        ["resumenes"] = ("ResumenCredito", "Resúmenes de créditos", "Consulta por crédito o importe. En borradores se crea o recalcula desde sus cuotas; los totales no se escriben a mano. Los contratos aprobados se conservan.")
    };

    public static IEnumerable<DefinicionConsultaIntegrada> Definiciones => Catalogo.Select(x => new DefinicionConsultaIntegrada(x.Key, x.Value.Titulo, x.Value.Ayuda));

    public async Task Eliminar(string id, int codigo, CancellationToken ct)
    {
        var entidad = id switch { "personas" => "Persona", "referencias" => "Referencia", _ => throw new OperacionCatalogoException(404, "Esta consulta no permite eliminar registros.") };
        if (codigo <= 0) throw new OperacionCatalogoException(400, "El código debe ser un entero positivo.");
        await using var cn = factory.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = cn.CreateCommand();
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = $"api.{entidad}_Eliminar";
        cmd.Parameters.Add("@Codigo" + entidad, SqlDbType.Int).Value = codigo;
        // El DELETE y las FK comprueban las dependencias atómicamente, incluso si
        // otro usuario vincula el registro después de abrir la confirmación.
        try { await cmd.ExecuteNonQueryAsync(ct); }
        catch (SqlException ex) when (ex.Number == 547)
        {
            throw new OperacionCatalogoException(409, id == "personas"
                ? "La persona tiene contactos o roles vinculados (cliente, fiador, vendedor o referencia). No se eliminó ningún dato."
                : "La referencia está vinculada a un cliente. No se eliminó ningún dato.");
        }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El registro ya no existe. Actualiza la consulta."); }
    }

    public async Task<TablaReporte> Consultar(string id, IQueryCollection query, CancellationToken ct)
    {
        if (!Catalogo.TryGetValue(id, out var definicion)) throw new OperacionCatalogoException(404, "Consulta no encontrada.");
        if (query.Keys.Any(k => k != "criterio") || query["criterio"].Count > 1)
            throw new OperacionCatalogoException(400, "Solo se admite un criterio de búsqueda.");
        var criterio = query["criterio"].ToString().Trim();
        if (query.ContainsKey("criterio") && (criterio.Length == 0 || criterio.Length > 60))
            throw new OperacionCatalogoException(400, "Escribe entre 1 y 60 caracteres para buscar.");
        await using var cn = factory.Crear();
        await cn.OpenAsync(ct);
        await using var cmd = cn.CreateCommand();
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.CommandText = $"api.{definicion.Entidad}_{(criterio.Length == 0 ? "Listar" : "Buscar")}";
        if (criterio.Length > 0)
        {
            // LIKE de SQL Server: los comodines escritos por el usuario se buscan literalmente.
            var literal = criterio.Replace("[", "[[]").Replace("%", "[%]").Replace("_", "[_]");
            cmd.Parameters.Add("@Criterio", SqlDbType.NVarChar, 200).Value = literal;
        }
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        var columnas = Enumerable.Range(0, reader.FieldCount).Select(i => new ColumnaReporte(reader.GetName(i), reader.GetDataTypeName(i))).ToList();
        var filas = new List<Dictionary<string, object?>>();
        while (await reader.ReadAsync(ct))
        {
            if (filas.Count >= 10000) throw new OperacionCatalogoException(422, "Hay más de 10000 registros. Usa un criterio más específico.");
            var fila = new Dictionary<string, object?>();
            for (int i = 0; i < reader.FieldCount; i++)
                fila[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i) switch
                {
                    DateTime fecha => fecha.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                    decimal numero => numero.ToString(CultureInfo.InvariantCulture),
                    long numero => numero.ToString(CultureInfo.InvariantCulture),
                    var valor => valor
                };
            filas.Add(fila);
        }
        return new(definicion.Titulo, columnas, filas);
    }
}
