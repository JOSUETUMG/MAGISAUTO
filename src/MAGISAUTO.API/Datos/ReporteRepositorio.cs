using System.Data;
using System.Globalization;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed record ColumnaReporte(string Nombre, string Tipo);
public sealed record TablaReporte(string Titulo, List<ColumnaReporte> Columnas, List<Dictionary<string, object?>> Filas);
public sealed record ResultadoReporte(int Id, string Titulo, string Utilidad, string Nota,
    Dictionary<string, string> Filtros, string ConsultadoEnGuatemala, List<TablaReporte> Tablas);

public sealed class ReporteRepositorio(ConexionSqlFactory factory)
{
    private static OperacionCatalogoException Invalido(string texto) => new(400, texto);

    // Convierte solo los filtros declarados; los valores viajan como parámetros tipados.
    private static (List<SqlParameter>, Dictionary<string, string>) Parametros(DefinicionReporte reporte, IQueryCollection query)
    {
        if (query.Keys.Any(k => !reporte.Filtros.Any(f => f.Nombre == k)))
            throw Invalido("La consulta contiene filtros no admitidos.");
        var parametros = new List<SqlParameter>();
        var aplicados = new Dictionary<string, string>();
        foreach (var f in reporte.Filtros)
        {
            if (query[f.Nombre].Count > 1) throw Invalido("No repitas el mismo filtro.");
            string valor = query[f.Nombre].ToString().Trim();
            if (valor.Length == 0)
            {
                if (f.Obligatorio) throw Invalido($"Completa el filtro: {f.Etiqueta}.");
                valor = f.Tipo == "fecha" ? CatalogoReportes.HoyGuatemala.ToString("yyyy-MM-dd") : f.Predeterminado!.Value.ToString(CultureInfo.InvariantCulture);
            }
            var sqlNombre = "@" + char.ToUpperInvariant(f.Nombre[0]) + f.Nombre[1..];
            if (f.Tipo == "fecha")
            {
                if (!DateOnly.TryParseExact(valor, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var fecha)
                    || fecha.Year > 9998)
                    throw Invalido($"{f.Etiqueta}: usa una fecha válida hasta el año 9998.");
                parametros.Add(new(sqlNombre, SqlDbType.Date) { Value = fecha.ToDateTime(TimeOnly.MinValue) });
            }
            else if (f.Tipo == "credito")
            {
                if (valor.Length > 20 || valor.Any(c => !(char.IsAsciiLetterOrDigit(c) || c is '-' or '_')))
                    throw Invalido("El número de crédito admite hasta 20 letras, números, guion o guion bajo.");
                parametros.Add(new(sqlNombre, SqlDbType.VarChar, 20) { Value = valor });
            }
            else
            {
                if (!int.TryParse(valor, NumberStyles.None, CultureInfo.InvariantCulture, out var numero)
                    || numero < (f.Minimo ?? 1) || numero > (f.Maximo ?? int.MaxValue))
                    throw Invalido($"{f.Etiqueta}: ingresa un número entero dentro del rango permitido.");
                parametros.Add(new(sqlNombre, SqlDbType.Int) { Value = numero });
                valor = numero.ToString(CultureInfo.InvariantCulture);
            }
            aplicados[f.Nombre] = valor;
        }
        if (aplicados.TryGetValue("desde", out var desde) && string.CompareOrdinal(desde, aplicados["hasta"]) > 0)
            throw Invalido("La fecha Desde no puede ser posterior a Hasta.");
        return (parametros, aplicados);
    }

    public async Task<object> Catalogos(CancellationToken ct)
    {
        await using var cn = factory.Crear();
        await cn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var sesion = new ClienteSqlSesion(cn, tx);
        var personas = (await sesion.Leer("Persona", ct)).ToDictionary(x => Convert.ToInt32(x["codigoPersona"]));
        var clientes = await sesion.Leer("Deudor", ct);
        var creditos = await sesion.Leer("Credito", ct);
        var salida = new
        {
            clientes = clientes.Select(c => new
            {
                codigoDeudor = c["codigoDeudor"],
                nombre = string.Join(" ", new[] { "primerNombre", "segundoNombre", "primerApellido", "segundoApellido" }
                    .Select(k => personas[Convert.ToInt32(c["codigoPersona"])][k]?.ToString()).Where(s => !string.IsNullOrWhiteSpace(s)))
            }).ToArray(),
            creditos = creditos.Select(c => new { numeroCredito = c["numeroCredito"], estado = c["estado"] }).ToArray()
        };
        await tx.CommitAsync(ct);
        return salida;
    }

    public async Task<ResultadoReporte> Consultar(int id, IQueryCollection query, CancellationToken ct)
    {
        var reporte = CatalogoReportes.Obtener(id);
        var (parametros, filtros) = Parametros(reporte, query);
        try
        {
            await using var cn = factory.Crear();
            await cn.OpenAsync(ct);
            // Las varias tablas de un reporte se leen dentro de una sola transacción coherente.
            await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
            await using var cmd = cn.CreateCommand();
            cmd.Transaction = tx;
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = reporte.Procedimiento;
            cmd.CommandTimeout = 30;
            cmd.Parameters.AddRange(parametros.ToArray());
            var tablas = new List<TablaReporte>();
            await using (var reader = await cmd.ExecuteReaderAsync(ct))
            {
                do
                {
                    if (reader.FieldCount == 0) continue;
                    var columnas = new List<ColumnaReporte>();
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        var tipo = reader.GetDataTypeName(i).ToLowerInvariant() switch
                        {
                            "decimal" or "numeric" or "money" or "smallmoney" => "decimal",
                            "bigint" => "entero",
                            "date" => "fecha",
                            "datetime" or "datetime2" or "smalldatetime" => "fechaHora",
                            "bit" => "booleano",
                            "int" or "smallint" or "tinyint" => "entero",
                            _ => "texto"
                        };
                        columnas.Add(new(reader.GetName(i), tipo));
                    }
                    var filas = new List<Dictionary<string, object?>>();
                    while (await reader.ReadAsync(ct))
                    {
                        // No devolver un informe truncado que parezca completo.
                        if (filas.Count >= 10000) throw new OperacionCatalogoException(422, "La consulta supera 10,000 filas por sección. No se muestran resultados parciales; limita el período cuando sea posible.");
                        var fila = new Dictionary<string, object?>();
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            object? v = reader.IsDBNull(i) ? null : reader.GetValue(i);
                            fila[columnas[i].Nombre] = v switch
                            {
                                decimal n => n.ToString(CultureInfo.InvariantCulture),
                                long n => n.ToString(CultureInfo.InvariantCulture),
                                DateTime f => f.ToString(columnas[i].Tipo == "fecha" ? "yyyy-MM-dd" : "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture),
                                _ => v
                            };
                        }
                        filas.Add(fila);
                    }
                    tablas.Add(new(reporte.Secciones.ElementAtOrDefault(tablas.Count) ?? $"Resultados {tablas.Count + 1}", columnas, filas));
                } while (await reader.NextResultAsync(ct));
            }
            await tx.CommitAsync(ct);
            return new(id, reporte.Titulo, reporte.Utilidad, reporte.Nota, filtros,
                DateTime.UtcNow.AddHours(-6).ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture), tablas);
        }
        catch (SqlException ex) when (ex.Number is 51304 or 51305)
        { throw new OperacionCatalogoException(404, "El cliente o crédito solicitado no existe."); }
        catch (SqlException ex) when (ex.Number is >= 51300 and <= 51306)
        { throw Invalido("Revisa las fechas y los filtros de la consulta."); }
        catch (SqlException ex) when (ex.Number == 1205)
        { throw new OperacionCatalogoException(409, "Otro proceso actualizó estos datos. Vuelve a consultar."); }
    }
}
