using System.Data;
using System.Text.Json;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

public sealed class ClienteRepositorio(ConexionSqlFactory conexiones)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private static int Id(Fila f, string key) => Convert.ToInt32(f[key]);
    private static string? Texto(Fila f, string key) => (string?)f[key];
    private static string? Opcional(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
    private static T Modelo<T>(Fila f) => JsonSerializer.Deserialize<T>(JsonSerializer.Serialize(f, Json), Json)!;
    private static OperacionCatalogoException Conflicto(string texto) => new(409, texto);
    private static OperacionCatalogoException Invalido(string texto) => new(400, texto);

    private async Task<T> Transaccion<T>(Func<ClienteSqlSesion, Task<T>> accion, CancellationToken ct)
    {
        await using var cn = conexiones.Crear();
        await cn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        try
        {
            var result = await accion(new ClienteSqlSesion(cn, tx));
            await tx.CommitAsync(ct);
            return result;
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        { throw Conflicto("El DPI, NIT, cliente o referencia ya están registrados. Revisa los datos sin duplicar personas."); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw Conflicto("Hay datos relacionados o un catálogo no válido. Revisa tipos, municipio y dependencias antes de guardar o eliminar."); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El registro ya no existe. Recarga el expediente."); }
        catch (SqlException ex) when (ex.Number is 51001 or 51002 or 51009 or 51010 or 51011 or 51012 or 51014 or 51015)
        { throw Conflicto("La operación no cumple las reglas de identidad, fecha o referencias de la persona."); }
    }

    private static async Task<Dictionary<string, List<Fila>>> Cargar(ClienteSqlSesion db, CancellationToken ct)
    {
        var datos = new Dictionary<string, List<Fila>>();
        foreach (var entidad in new[] { "Persona", "Deudor", "Telefono", "Direccion", "Referencia", "DetalleReferencia" })
            datos[entidad] = await db.Leer(entidad, ct);
        return datos;
    }

    private static List<T> Contactos<T>(Dictionary<string, List<Fila>> datos, string tabla, int persona) =>
        datos[tabla].Where(f => Id(f, "codigoPersona") == persona).Select(Modelo<T>).ToList();

    private static ReferenciaClienteSolicitud Referencia(Dictionary<string, List<Fila>> datos, Fila referencia, Fila? vinculo = null)
    {
        int persona = Id(referencia, "codigoPersona");
        var result = Modelo<ReferenciaClienteSolicitud>(datos["Persona"].Single(p => Id(p, "codigoPersona") == persona));
        result.CodigoReferencia = Id(referencia, "codigoReferencia");
        result.LugarTrabajo = Texto(referencia, "lugarTrabajo")!;
        result.CodigoTipoReferencia = vinculo is null ? 0 : Id(vinculo, "codigoTipoReferencia");
        result.ParentescoRelacion = vinculo is null ? "" : Texto(vinculo, "parentescoRelacion")!;
        result.Telefonos = Contactos<TelefonoClienteSolicitud>(datos, "Telefono", persona);
        result.Direcciones = Contactos<DireccionClienteSolicitud>(datos, "Direccion", persona);
        return result;
    }

    public async Task<IReadOnlyList<ClienteFicha>> Consultar(string? criterio, CancellationToken ct)
    {
        // Lectura consistente de todo el expediente; no se mezclan dos versiones mientras alguien guarda.
        return await Transaccion<IReadOnlyList<ClienteFicha>>(async db =>
        {
            var datos = await Cargar(db, ct);
            var result = new List<ClienteFicha>();
            foreach (var cliente in datos["Deudor"])
            {
                int codigo = Id(cliente, "codigoDeudor"), persona = Id(cliente, "codigoPersona");
                var ficha = Modelo<ClienteFicha>(datos["Persona"].Single(p => Id(p, "codigoPersona") == persona));
                ficha.CodigoCliente = codigo;
                ficha.CodigoPersona = persona;
                ficha.Telefonos = Contactos<TelefonoClienteSolicitud>(datos, "Telefono", persona);
                ficha.Direcciones = Contactos<DireccionClienteSolicitud>(datos, "Direccion", persona);
                ficha.Referencias = datos["DetalleReferencia"].Where(v => Id(v, "codigoDeudor") == codigo)
                    .Select(v => Referencia(datos, datos["Referencia"].Single(r => Id(r, "codigoReferencia") == Id(v, "codigoReferencia")), v)).ToList();
                if (criterio is null || new[] { codigo.ToString(), ficha.DPI, ficha.NIT, ficha.NombreCompleto, ficha.CorreoElectronico }
                    .Any(x => x.Contains(criterio, StringComparison.OrdinalIgnoreCase))) result.Add(ficha);
            }
            return result;
        }, ct);
    }

    public async Task<object> Catalogos(CancellationToken ct) => await Transaccion<object>(async db =>
    {
        var result = new Dictionary<string, object>();
        foreach (var tabla in new[] { "TipoTelefono", "TipoDireccion", "Departamento", "Municipio", "TipoReferencia" })
            result[tabla] = await db.Leer(tabla, ct);
        var datos = await Cargar(db, ct);
        result["Referencias"] = datos["Referencia"].Select(r => new { CodigoPersona = Id(r, "codigoPersona"), Datos = Referencia(datos, r) }).ToArray();
        return result;
    }, ct);

    private static async Task<int> GuardarPersona(ClienteSqlSesion db, NombresPersonaSolicitud s, Fila? anterior,
        ClienteSolicitud? cliente, CancellationToken ct)
    {
        var valores = new Fila
        {
            ["PrimerNombre"] = s.PrimerNombre.Trim(), ["SegundoNombre"] = Opcional(s.SegundoNombre),
            ["PrimerApellido"] = s.PrimerApellido.Trim(), ["SegundoApellido"] = Opcional(s.SegundoApellido),
            ["DPI"] = cliente?.DPI ?? anterior?.GetValueOrDefault("dpi"),
            ["NIT"] = cliente?.NIT.Trim() ?? anterior?.GetValueOrDefault("nit"),
            ["CorreoElectronico"] = cliente?.CorreoElectronico.Trim() ?? anterior?.GetValueOrDefault("correoElectronico"),
            ["FechaNacimiento"] = cliente?.FechaNacimiento?.Date ?? anterior?.GetValueOrDefault("fechaNacimiento"),
            ["Genero"] = anterior?.GetValueOrDefault("genero")
        };
        if (anterior is not null) valores["CodigoPersona"] = Id(anterior, "codigoPersona");
        var id = await db.Ejecutar(anterior is null ? "Persona_Insertar" : "Persona_Actualizar", valores, ct);
        return anterior is null ? Convert.ToInt32(id) : Id(anterior, "codigoPersona");
    }

    public async Task<int> Guardar(int? codigo, ClienteSolicitud s, CancellationToken ct)
    {
        if (s.FechaNacimiento is null || s.FechaNacimiento.Value.Date >= DateTime.UtcNow.AddHours(-6).Date)
            throw Invalido("La fecha de nacimiento debe ser anterior a hoy.");
        if (s.Referencias.Any(r => r is null)) throw Invalido("No envíes referencias vacías.");
        ContactosPersona.Validar(s.Telefonos, s.Direcciones);
        foreach (var r in s.Referencias) ContactosPersona.Validar(r.Telefonos, r.Direcciones);
        if (s.Referencias.Where(r => r.CodigoReferencia is not null).GroupBy(r => r.CodigoReferencia).Any(g => g.Count() > 1))
            throw Invalido("Cada referencia debe ser una persona distinta; no repitas la misma referencia.");
        return await Transaccion(async db =>
        {
            var datos = await Cargar(db, ct);
            var deudor = codigo is null ? null : datos["Deudor"].SingleOrDefault(d => Id(d, "codigoDeudor") == codigo);
            if (codigo is not null && deudor is null) throw new OperacionCatalogoException(404, "El cliente ya no existe.");
            var persona = deudor is null ? datos["Persona"].SingleOrDefault(p => Texto(p, "dpi") == s.DPI)
                : datos["Persona"].Single(p => Id(p, "codigoPersona") == Id(deudor, "codigoPersona"));
            if (persona is not null)
            {
                if (Texto(persona, "dpi") != s.DPI) throw Conflicto("El DPI del cliente se conserva al editar.");
                if (codigo is null)
                {
                    if (datos["Deudor"].Any(d => Id(d, "codigoPersona") == Id(persona, "codigoPersona"))) throw Conflicto("Esta persona ya es cliente.");
                    var nombres = new[] { ("primerNombre", s.PrimerNombre.Trim()), ("segundoNombre", Opcional(s.SegundoNombre)),
                        ("primerApellido", s.PrimerApellido.Trim()), ("segundoApellido", Opcional(s.SegundoApellido)) };
                    if (nombres.Any(n => !string.Equals(Texto(persona, n.Item1), n.Item2, StringComparison.OrdinalIgnoreCase)))
                        throw Conflicto("El DPI pertenece a una persona existente. Usa sus nombres registrados para vincularla.");
                    // No eliminar contactos preexistentes al añadir un rol desde un formulario nuevo.
                    if (datos["Telefono"].Any(t => Id(t, "codigoPersona") == Id(persona, "codigoPersona"))
                        || datos["Direccion"].Any(d => Id(d, "codigoPersona") == Id(persona, "codigoPersona")))
                    {
                        if (s.Telefonos.Count > 0 || s.Direcciones.Count > 0) throw Conflicto("La persona ya tiene contactos. Registra primero el rol sin contactos nuevos; después edita su expediente para conservar y ampliar los existentes.");
                        s.Telefonos = Contactos<TelefonoClienteSolicitud>(datos, "Telefono", Id(persona, "codigoPersona"));
                        s.Direcciones = Contactos<DireccionClienteSolicitud>(datos, "Direccion", Id(persona, "codigoPersona"));
                    }
                }
            }
            int personaId = await GuardarPersona(db, s, persona, s, ct);
            int clienteId = codigo ?? Convert.ToInt32(await db.Ejecutar("Deudor_Insertar", new Fila { ["CodigoPersona"] = personaId }, ct));
            await ContactosPersona.Guardar(db, personaId, s.Telefonos, s.Direcciones, datos, ct);
            var vinculos = datos["DetalleReferencia"].Where(v => Id(v, "codigoDeudor") == clienteId).ToList();
            foreach (var v in vinculos.Where(v => !s.Referencias.Any(r => r.CodigoReferencia == Id(v, "codigoReferencia"))))
                await db.Ejecutar("DetalleReferencia_Eliminar", new Fila { ["CodigoDeudor"] = clienteId, ["CodigoReferencia"] = Id(v, "codigoReferencia") }, ct);
            foreach (var r in s.Referencias)
            {
                var referencia = r.CodigoReferencia is null ? null : datos["Referencia"].SingleOrDefault(x => Id(x, "codigoReferencia") == r.CodigoReferencia);
                if (r.CodigoReferencia is not null && referencia is null) throw Conflicto("La referencia seleccionada ya no existe.");
                var personaRef = referencia is null ? null : datos["Persona"].Single(p => Id(p, "codigoPersona") == Id(referencia, "codigoPersona"));
                if (personaRef is not null && Id(personaRef, "codigoPersona") == personaId) throw Conflicto("El cliente no puede ser su propia referencia.");
                bool vinculada = vinculos.Any(v => Id(v, "codigoReferencia") == r.CodigoReferencia);
                int refId;
                if (referencia is not null && !vinculada)
                {
                    // Vincular un registro compartido no reemplaza su ficha ni sus contactos.
                    refId = Id(referencia, "codigoReferencia");
                }
                else
                {
                    int refPersona = await GuardarPersona(db, r, personaRef, null, ct);
                    var valores = new Fila { ["CodigoPersona"] = refPersona, ["LugarTrabajo"] = r.LugarTrabajo.Trim() };
                    if (referencia is not null) valores["CodigoReferencia"] = Id(referencia, "codigoReferencia");
                    var nuevoId = await db.Ejecutar(referencia is null ? "Referencia_Insertar" : "Referencia_Actualizar", valores, ct);
                    refId = referencia is null ? Convert.ToInt32(nuevoId) : Id(referencia, "codigoReferencia");
                    await ContactosPersona.Guardar(db, refPersona, r.Telefonos, r.Direcciones, datos, ct);
                }
                await db.Ejecutar(vinculada ? "DetalleReferencia_Actualizar" : "DetalleReferencia_Insertar",
                    new Fila { ["CodigoDeudor"] = clienteId, ["CodigoReferencia"] = refId,
                        ["CodigoTipoReferencia"] = r.CodigoTipoReferencia, ["ParentescoRelacion"] = r.ParentescoRelacion.Trim() }, ct);
            }
            return clienteId;
        }, ct);
    }

    public Task<int> Eliminar(int codigo, CancellationToken ct) => Transaccion(async db =>
    {
        try
        {
            await db.Ejecutar("Deudor_Eliminar", new Fila { ["CodigoDeudor"] = codigo }, ct);
        }
        catch (SqlException ex) when (ex.Number == 547)
        {
            throw Conflicto("No se puede eliminar el cliente porque tiene créditos o referencias vinculadas. El cliente se conserva.");
        }
        return codigo;
    }, ct);
}
