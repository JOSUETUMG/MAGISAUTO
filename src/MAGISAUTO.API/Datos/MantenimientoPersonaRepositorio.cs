using System.Data;
using System.Globalization;
using System.ComponentModel.DataAnnotations;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

public sealed record CampoFicha(string Nombre, string Etiqueta, string Tipo = "text", int Maximo = 64,
    bool Opcional = false, bool Clave = false, bool Automatico = false, string? Catalogo = null);
public sealed record CambioFicha(Dictionary<string, string?> Datos, Dictionary<string, string?>? Anterior);

// Mantenimiento independiente limitado a entidades explícitas. Nunca recibe nombres SQL.
public sealed class MantenimientoPersonaRepositorio(ConexionSqlFactory factory)
{
    private static readonly Dictionary<string, (string Tabla, CampoFicha[] Campos)> Entidades = new()
    {
        ["personas"] = ("Persona", [new("CodigoPersona", "Código", "number", Clave:true, Automatico:true),
            new("DPI", "DPI", Maximo:13, Opcional:true), new("NIT", "NIT", Maximo:20, Opcional:true),
            new("PrimerNombre", "Primer nombre"), new("SegundoNombre", "Segundo nombre", Opcional:true),
            new("PrimerApellido", "Primer apellido"), new("SegundoApellido", "Segundo apellido", Opcional:true),
            new("FechaNacimiento", "Fecha de nacimiento", "date", Opcional:true),
            new("Genero", "Género (M, F u O)", Maximo:1, Opcional:true),
            new("CorreoElectronico", "Correo electrónico", "email", 254, true)]),
        ["telefonos"] = ("Telefono", [new("CodigoPersona", "Persona", "number", Clave:true, Catalogo:"Persona"),
            new("Correlativo", "Correlativo", "number", Clave:true, Automatico:true),
            new("CodigoTipoTelefono", "Tipo de teléfono", "number", Catalogo:"TipoTelefono"),
            new("Numero", "Número (mínimo 8 caracteres)", Maximo:32)]),
        ["direcciones"] = ("Direccion", [new("CodigoPersona", "Persona", "number", Clave:true, Catalogo:"Persona"),
            new("Correlativo", "Correlativo", "number", Clave:true, Automatico:true),
            new("CodigoTipoDireccion", "Tipo de dirección", "number", Catalogo:"TipoDireccion"),
            new("CodigoDepartamento", "Departamento", "number", Catalogo:"Departamento"),
            new("CodigoMunicipio", "Municipio", "number", Catalogo:"Municipio"),
            new("Detalle", "Dirección", Maximo:300)]),
        ["referencias"] = ("Referencia", [new("CodigoReferencia", "Código", "number", Clave:true, Automatico:true),
            new("CodigoPersona", "Persona", "number", Catalogo:"Persona"),
            new("LugarTrabajo", "Lugar de trabajo", Maximo:200)]),
        ["cuotas"] = ("DetalleCuota", [new("NumeroCredito", "Crédito en borrador", Maximo:20, Clave:true, Catalogo:"Credito"),
            new("Cuota", "Número de cuota", "number", Clave:true),
            new("FechaVencimiento", "Vencimiento", "date"), new("Capital", "Capital en Q", "money"), new("Interes", "Interés en Q", "money")]),
        ["resumenes"] = ("ResumenCredito", [new("NumeroCredito", "Crédito en borrador", Maximo:20, Clave:true, Catalogo:"Credito")])
    };
    private static (string Tabla, CampoFicha[] Campos) Definicion(string id) => Entidades.TryGetValue(id, out var d)
        ? d : throw new OperacionCatalogoException(404, "Mantenimiento no disponible.");
    private static string? Texto(object? valor) => valor switch {
        null => null, DateTime f => f.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
        _ => Convert.ToString(valor, CultureInfo.InvariantCulture) };
    private static object? Valor(Fila fila, string nombre) => fila.GetValueOrDefault(char.ToLowerInvariant(nombre[0]) + nombre[1..]);
    private static OperacionCatalogoException Invalido(string mensaje) => new(400, mensaje);

    public async Task<object> Formulario(string id, CancellationToken ct)
    {
        var d = Definicion(id);
        await using var cn = factory.Crear(); await cn.OpenAsync(ct);
        var db = new ClienteSqlSesion(cn, null);
        var catalogos = new Dictionary<string, List<Fila>>();
        foreach (var tabla in d.Campos.Where(c => c.Catalogo is not null).Select(c => c.Catalogo!).Distinct())
            catalogos[tabla] = (await db.Leer(tabla, ct)).Where(f => tabla != "Credito" || Texto(Valor(f,"Estado")) == "BORRADOR").ToList();
        return new { campos = d.Campos, catalogos };
    }

    public async Task Cambiar(string id, string operacion, CambioFicha solicitud, CancellationToken ct)
    {
        var d = Definicion(id);
        if (operacion is not ("crear" or "editar" or "eliminar")) throw Invalido("Operación desconocida.");
        bool crear = operacion == "crear", borrar = operacion == "eliminar";
        if (solicitud.Datos is null || solicitud.Datos.Keys.Any(k => !d.Campos.Any(c => c.Nombre == k)))
            throw Invalido("El formulario contiene campos desconocidos.");
        if (!crear && (solicitud.Anterior is null || d.Campos.Any(c => !solicitud.Anterior.ContainsKey(c.Nombre))))
            throw Invalido("Falta la versión original. Recarga la consulta.");
        var valores = new Fila();
        foreach (var campo in d.Campos)
        {
            if (crear && campo.Automatico) continue;
            if (borrar && !campo.Clave) continue;
            var texto = solicitud.Datos.GetValueOrDefault(campo.Nombre)?.Trim();
            if (string.IsNullOrEmpty(texto))
            {
                if (!campo.Opcional) throw Invalido($"Completa {campo.Etiqueta}.");
                valores[campo.Nombre] = null; continue;
            }
            if (campo.Tipo == "number")
            {
                if (!int.TryParse(texto, NumberStyles.None, CultureInfo.InvariantCulture, out int numero) || numero <= 0)
                    throw Invalido($"{campo.Etiqueta} debe ser un código positivo.");
                valores[campo.Nombre] = numero;
            }
            else if (campo.Tipo == "money")
            {
                if (!System.Text.RegularExpressions.Regex.IsMatch(texto, @"^\d{1,16}(\.\d{1,2})?$")
                    || !decimal.TryParse(texto, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out var monto) || monto < 0)
                    throw Invalido("Usa importes no negativos en Q, con hasta dos decimales y sin comas.");
                valores[campo.Nombre] = monto;
            }
            else if (campo.Tipo == "date")
            {
                if (!DateTime.TryParseExact(texto, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var fecha)
                    || campo.Nombre == "FechaNacimiento" && fecha.Date >= DateTime.UtcNow.AddHours(-6).Date) throw Invalido("Fecha inválida; el nacimiento debe ser anterior a hoy.");
                valores[campo.Nombre] = fecha;
            }
            else
            {
                if (texto.Length > campo.Maximo) throw Invalido($"{campo.Etiqueta}: máximo {campo.Maximo} caracteres.");
                if (campo.Nombre == "DPI" && (texto.Length != 13 || texto.Any(x => x < '0' || x > '9'))) throw Invalido("El DPI debe contener 13 dígitos.");
                if (campo.Nombre == "Genero" && texto is not ("M" or "F" or "O")) throw Invalido("Género debe ser M, F u O.");
                if (campo.Nombre == "Numero" && texto.Length < 8) throw Invalido("El teléfono requiere al menos ocho caracteres.");
                if (campo.Tipo == "email" && !new EmailAddressAttribute().IsValid(texto)) throw Invalido("Correo electrónico no válido.");
                valores[campo.Nombre] = texto;
            }
        }
        await using var cn = factory.Crear(); await cn.OpenAsync(ct);
        await using var tx = (SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var db = new ClienteSqlSesion(cn, tx);
        try
        {
            if (id is "cuotas" or "resumenes")
            {
                await using var comprobar = cn.CreateCommand();
                comprobar.Transaction = tx; comprobar.CommandType = CommandType.StoredProcedure;
                comprobar.CommandText = "api.Reporte10_Intereses";
                comprobar.Parameters.Add("@FechaCorte", SqlDbType.Date).Value = new DateTime(1900, 1, 1);
                await using var lector = await comprobar.ExecuteReaderAsync(ct);
                if (!Enumerable.Range(0, lector.FieldCount).Any(i => lector.GetName(i) == "InteresesDevengados"))
                    throw new OperacionCatalogoException(409, "La base requiere la actualización del cierre técnico antes de administrar simulaciones. Solicita su instalación.");
            }
            var filas = await db.Leer(d.Tabla, ct);
            if (valores.TryGetValue("Cuota", out var cuota) && Convert.ToInt32(cuota) > short.MaxValue)
                throw Invalido("El número de cuota no puede superar 32767.");
            if (!crear)
            {
                var actual = filas.SingleOrDefault(f => d.Campos.Where(c => c.Clave).All(c => Texto(Valor(f, c.Nombre)) == solicitud.Anterior![c.Nombre]));
                if (actual is null) throw new OperacionCatalogoException(404, "El registro ya no existe.");
                if (d.Campos.Any(c => Texto(Valor(actual, c.Nombre)) != solicitud.Anterior![c.Nombre]))
                    throw new OperacionCatalogoException(409, "Otra operación cambió este registro. Cierra y recarga antes de guardar.");
                foreach (var c in d.Campos.Where(c => c.Clave || c.Nombre == "CodigoPersona" || c.Nombre == "DPI" && Valor(actual, "DPI") is not null))
                    if (valores.ContainsKey(c.Nombre) && Texto(valores[c.Nombre]) != Texto(Valor(actual, c.Nombre)))
                        throw Invalido("La identidad y las claves del registro se conservan al editar.");
            }
            if (crear && id is "telefonos" or "direcciones")
            {
                int siguiente = filas.Where(f => Texto(Valor(f,"CodigoPersona")) == Texto(valores["CodigoPersona"]))
                    .Select(f => Convert.ToInt32(Valor(f,"Correlativo"))).DefaultIfEmpty(0).Max() + 1;
                if (siguiente > short.MaxValue) throw new OperacionCatalogoException(409, "Se agotó la numeración de contactos.");
                valores["Correlativo"] = siguiente;
            }
            await db.Ejecutar(d.Tabla + (crear ? "_Insertar" : borrar ? "_Eliminar" : "_Actualizar"), valores, ct);
            await tx.CommitAsync(ct);
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        { throw new OperacionCatalogoException(409, "La identidad o ficha ya está registrada. No dupliques personas."); }
        catch (SqlException ex) when (ex.Number == 547)
        { throw new OperacionCatalogoException(409, "Existen dependencias o un catálogo no válido. No se guardó ningún cambio."); }
        catch (SqlException ex) when (ex.Number == 51008)
        { throw new OperacionCatalogoException(404, "El registro ya no existe."); }
        catch (SqlException ex) when (ex.Number == 51003)
        { throw new OperacionCatalogoException(409, "Solo se modifican cuotas y resúmenes de borradores. El contrato aprobado conserva su historial."); }
        catch (SqlException ex) when (ex.Number is >= 51001 and <= 51015)
        { throw new OperacionCatalogoException(409, "Conserva los datos obligatorios de clientes, fiadores y vendedores, y la identidad de cada ficha."); }
    }
}
