using MAGISAUTO.API.Modelos;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

internal static class ContactosPersona
{
    private static int Id(Fila f, string key) => Convert.ToInt32(f[key]);
    private static OperacionCatalogoException Conflicto(string texto) => new(409, texto);
    private static OperacionCatalogoException Invalido(string texto) => new(400, texto);
    public static void Validar(List<TelefonoClienteSolicitud> telefonos, List<DireccionClienteSolicitud> direcciones)
    {
        if (telefonos.Any(t => t is null) || direcciones.Any(d => d is null)) throw Invalido("No envíes contactos vacíos.");
        if (telefonos.Any(t => t.Numero.Trim().Length < 8)) throw Invalido("Cada teléfono requiere al menos ocho caracteres sin espacios exteriores.");
        if (telefonos.Where(t => t.Correlativo > 0).GroupBy(t => t.Correlativo).Any(g => g.Count() > 1)
            || direcciones.Where(d => d.Correlativo > 0).GroupBy(d => d.Correlativo).Any(g => g.Count() > 1))
            throw Invalido("No repitas el código de un contacto.");
    }

    public static async Task Guardar(ClienteSqlSesion db, int persona, List<TelefonoClienteSolicitud> telefonos,
        List<DireccionClienteSolicitud> direcciones, Dictionary<string, List<Fila>> datos, CancellationToken ct)
    {
        foreach (var tabla in new[] { "Telefono", "Direccion" })
        {
            var anteriores = datos[tabla].Where(f => Id(f, "codigoPersona") == persona).ToList();
            var entradas = tabla == "Telefono"
                ? telefonos.Select(t => new Fila { ["Correlativo"] = t.Correlativo, ["CodigoTipoTelefono"] = t.CodigoTipoTelefono, ["Numero"] = t.Numero.Trim() }).ToList()
                : direcciones.Select(d => new Fila { ["Correlativo"] = d.Correlativo, ["CodigoTipoDireccion"] = d.CodigoTipoDireccion,
                    ["CodigoDepartamento"] = d.CodigoDepartamento, ["CodigoMunicipio"] = d.CodigoMunicipio, ["Detalle"] = d.Detalle.Trim() }).ToList();
            int siguiente = anteriores.Select(a => Id(a, "correlativo")).DefaultIfEmpty(0).Max();
            foreach (var viejo in anteriores.Where(a => !entradas.Any(e => Id(e, "Correlativo") == Id(a, "correlativo"))))
                await db.Ejecutar(tabla + "_Eliminar", new Fila { ["CodigoPersona"] = persona, ["Correlativo"] = Id(viejo, "correlativo") }, ct);
            foreach (var e in entradas)
            {
                int correlativo = Id(e, "Correlativo");
                bool nuevo = correlativo == 0;
                if (!nuevo && !anteriores.Any(a => Id(a, "correlativo") == correlativo)) throw Conflicto("Un contacto ya no pertenece al expediente. Recarga antes de editar.");
                if (nuevo) correlativo = ++siguiente;
                if (correlativo > short.MaxValue) throw Conflicto("Se agotó la numeración de contactos de esta persona.");
                e["Correlativo"] = correlativo; e["CodigoPersona"] = persona;
                await db.Ejecutar(tabla + (nuevo ? "_Insertar" : "_Actualizar"), e, ct);
            }
        }
    }

}
