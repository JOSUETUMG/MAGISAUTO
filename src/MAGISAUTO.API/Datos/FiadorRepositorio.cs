using System.Data;
using System.Text.Json;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

public sealed class FiadorRepositorio(ConexionSqlFactory conexiones)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private static int Id(Fila f, string key) => Convert.ToInt32(f[key]);
    private static string? Texto(Fila f, string key) => (string?)f[key];
    private static string? Opcional(string? texto) => string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();
    private static T Modelo<T>(Fila fila) => JsonSerializer.Deserialize<T>(JsonSerializer.Serialize(fila, Json), Json)!;
    private static OperacionCatalogoException Conflicto(string texto) => new(409, texto);

    private async Task<T> Transaccion<T>(Func<ClienteSqlSesion, Task<T>> accion, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        try
        {
            var resultado = await accion(new ClienteSqlSesion(cn, tx));
            await tx.CommitAsync(ct);
            return resultado;
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        { throw Conflicto("El DPI o NIT ya está registrado, o esta persona ya es fiador. Revisa sus datos sin duplicarla."); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw Conflicto("Revisa el tipo de contacto y que el municipio pertenezca al departamento seleccionado."); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El registro ya no existe. Actualiza el listado."); }
        catch (SqlException ex) when (ex.Number is 51001 or 51009 or 51010 or 51011 or 51012 or 51013)
        { throw Conflicto("Conserva la identidad y los datos obligatorios de los otros roles de esta persona."); }
    }

    private static async Task<Dictionary<string, List<Fila>>> Cargar(ClienteSqlSesion db, CancellationToken ct)
    {
        var datos = new Dictionary<string, List<Fila>>();
        foreach (var entidad in new[] { "Persona", "Fiador", "Telefono", "Direccion" })
            datos[entidad] = await db.Leer(entidad, ct);
        return datos;
    }

    private static List<T> Contactos<T>(Dictionary<string, List<Fila>> datos, string tabla, int persona) =>
        datos[tabla].Where(f => Id(f, "codigoPersona") == persona).Select(Modelo<T>).ToList();

    public async Task<IReadOnlyList<FiadorFicha>> Consultar(string? criterio, CancellationToken ct) =>
        await Transaccion<IReadOnlyList<FiadorFicha>>(async db =>
        {
            var datos = await Cargar(db, ct);
            var personas = datos["Persona"].ToDictionary(p => Id(p, "codigoPersona"));
            var fichas = new List<FiadorFicha>();
            foreach (var rol in datos["Fiador"])
            {
                var persona = Id(rol, "codigoPersona");
                var ficha = Modelo<FiadorFicha>(personas[persona]);
                ficha.CodigoFiador = Id(rol, "codigoFiador");
                ficha.Telefonos = Contactos<TelefonoClienteSolicitud>(datos, "Telefono", persona);
                ficha.Direcciones = Contactos<DireccionClienteSolicitud>(datos, "Direccion", persona);
                if (criterio is null || new[] { ficha.CodigoFiador.ToString(), ficha.DPI, ficha.NIT, ficha.NombreCompleto, ficha.CorreoElectronico }
                    .Any(t => t.Contains(criterio, StringComparison.OrdinalIgnoreCase))) fichas.Add(ficha);
            }
            return fichas;
        }, ct);

    public async Task<object> Catalogos(CancellationToken ct) => await Transaccion<object>(async db =>
    {
        var datos = new Dictionary<string, object>();
        foreach (var tabla in new[] { "TipoTelefono", "TipoDireccion", "Departamento", "Municipio" })
            datos[tabla] = await db.Leer(tabla, ct);
        return datos;
    }, ct);

    public Task<int> Guardar(int? codigo, FiadorSolicitud s, CancellationToken ct)
    {
        ContactosPersona.Validar(s.Telefonos, s.Direcciones);
        return Transaccion(async db =>
        {
            var datos = await Cargar(db, ct);
            var rol = codigo is null ? null : datos["Fiador"].SingleOrDefault(f => Id(f, "codigoFiador") == codigo);
            if (codigo is not null && rol is null) throw new OperacionCatalogoException(404, "El fiador ya no existe. Actualiza el listado.");
            var persona = rol is null
                ? datos["Persona"].SingleOrDefault(p => Texto(p, "dpi") == s.DPI)
                : datos["Persona"].Single(p => Id(p, "codigoPersona") == Id(rol, "codigoPersona"));
            if (rol is not null && Texto(persona!, "dpi") != s.DPI)
                throw Conflicto("El DPI identifica a la persona y se conserva al editar el fiador.");

            if (codigo is null && persona is not null)
            {
                var personaId = Id(persona, "codigoPersona");
                if (datos["Fiador"].Any(f => Id(f, "codigoPersona") == personaId))
                    throw Conflicto("Esta persona ya está registrada como fiador.");
                var nombres = new Fila { ["primerNombre"] = s.PrimerNombre.Trim(), ["segundoNombre"] = Opcional(s.SegundoNombre),
                    ["primerApellido"] = s.PrimerApellido.Trim(), ["segundoApellido"] = Opcional(s.SegundoApellido) };
                if (nombres.Any(n => !string.Equals(Texto(persona, n.Key), (string?)n.Value, StringComparison.OrdinalIgnoreCase))
                    || (Texto(persona, "nit") is string nit && !string.Equals(nit, s.NIT.Trim(), StringComparison.OrdinalIgnoreCase))
                    || (Texto(persona, "correoElectronico") is string correo && !string.Equals(correo, s.CorreoElectronico.Trim(), StringComparison.OrdinalIgnoreCase)))
                    throw Conflicto("El DPI pertenece a una persona registrada. Usa sus nombres, NIT y correo existentes para vincularla sin reemplazarlos.");
                // Dar de alta otro rol nunca sustituye contactos compartidos silenciosamente.
                if (datos["Telefono"].Any(t => Id(t, "codigoPersona") == personaId) || datos["Direccion"].Any(d => Id(d, "codigoPersona") == personaId))
                {
                    if (s.Telefonos.Count > 0 || s.Direcciones.Count > 0)
                        throw Conflicto("Esta persona ya tiene contactos. Registra el fiador sin contactos nuevos; se conservarán los existentes. Después abre su expediente para editarlos.");
                    s.Telefonos = Contactos<TelefonoClienteSolicitud>(datos, "Telefono", personaId);
                    s.Direcciones = Contactos<DireccionClienteSolicitud>(datos, "Direccion", personaId);
                }
            }

            var reutilizar = codigo is null && persona is not null;
            var valores = new Fila
            {
                ["DPI"] = s.DPI,
                ["PrimerNombre"] = reutilizar ? persona!["primerNombre"] : s.PrimerNombre.Trim(),
                ["SegundoNombre"] = reutilizar ? persona!["segundoNombre"] : Opcional(s.SegundoNombre),
                ["PrimerApellido"] = reutilizar ? persona!["primerApellido"] : s.PrimerApellido.Trim(),
                ["SegundoApellido"] = reutilizar ? persona!["segundoApellido"] : Opcional(s.SegundoApellido),
                ["NIT"] = reutilizar ? persona!["nit"] ?? s.NIT.Trim() : s.NIT.Trim(),
                ["CorreoElectronico"] = reutilizar ? persona!["correoElectronico"] ?? s.CorreoElectronico.Trim() : s.CorreoElectronico.Trim(),
                ["FechaNacimiento"] = persona?.GetValueOrDefault("fechaNacimiento"),
                ["Genero"] = persona?.GetValueOrDefault("genero")
            };
            if (persona is not null) valores["CodigoPersona"] = Id(persona, "codigoPersona");
            var nuevoId = await db.Ejecutar(persona is null ? "Persona_Insertar" : "Persona_Actualizar", valores, ct);
            var idPersona = persona is null ? Convert.ToInt32(nuevoId) : Id(persona, "codigoPersona");
            var rolValores = new Fila { ["CodigoPersona"] = idPersona };
            if (codigo is not null) rolValores["CodigoFiador"] = codigo.Value;
            var nuevoRol = await db.Ejecutar(codigo is null ? "Fiador_Insertar" : "Fiador_Actualizar", rolValores, ct);
            await ContactosPersona.Guardar(db, idPersona, s.Telefonos, s.Direcciones, datos, ct);
            return codigo ?? Convert.ToInt32(nuevoRol);
        }, ct);
    }

    public Task<int> Eliminar(int codigo, CancellationToken ct) => Transaccion(async db =>
    {
        try { await db.Ejecutar("Fiador_Eliminar", new Fila { ["CodigoFiador"] = codigo }, ct); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw Conflicto("No se puede eliminar el fiador porque tiene créditos vinculados. El fiador se conserva."); }
        return codigo;
    }, ct);
}
