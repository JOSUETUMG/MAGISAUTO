using System.Text.Json.Serialization;

namespace MAGISAUTO.API.Datos;

public sealed record DefinicionAuxiliar(string Id, string Nombre, string Ayuda,
    bool UsaDepartamento, bool UsaReferenciaBancaria,
    [property: JsonIgnore] string Entidad, [property: JsonIgnore] string Clave);

public static class CatalogosAuxiliares
{
    // Lista cerrada: el cliente selecciona un catálogo, nunca una tabla o un SP arbitrario.
    public static readonly IReadOnlyList<DefinicionAuxiliar> Todos = Array.AsReadOnly(new[]
    {
        new DefinicionAuxiliar("departamentos", "Departamentos", "Ubicaciones utilizadas en las direcciones de las personas.", false, false, "Departamento", "CodigoDepartamento"),
        new DefinicionAuxiliar("municipios", "Municipios", "Cada municipio pertenece a un departamento. Su código puede repetirse en otro departamento.", true, false, "Municipio", "CodigoMunicipio"),
        new DefinicionAuxiliar("tipos-telefono", "Tipos de teléfono", "Clasifican los teléfonos registrados en los expedientes.", false, false, "TipoTelefono", "CodigoTipoTelefono"),
        new DefinicionAuxiliar("tipos-direccion", "Tipos de dirección", "Clasifican las direcciones registradas en los expedientes.", false, false, "TipoDireccion", "CodigoTipoDireccion"),
        new DefinicionAuxiliar("tipos-garantia", "Tipos de garantía", "Clasifican las garantías de los vehículos del proyecto.", false, false, "TipoGarantia", "CodigoTipoGarantia"),
        new DefinicionAuxiliar("tipos-referencia", "Tipos de referencia", "Clasifican la relación de una referencia con el cliente.", false, false, "TipoReferencia", "CodigoTipoReferencia"),
        new DefinicionAuxiliar("tipos-pago", "Tipos de pago", "Indican el medio de pago y si exige una referencia bancaria. Cambiar esa opción afecta los próximos pagos; los recibos anteriores se conservan.", false, true, "TipoPago", "CodigoTipoPago")
    });

    public static DefinicionAuxiliar Obtener(string id) => Todos.FirstOrDefault(x => x.Id == id)
        ?? throw new OperacionCatalogoException(404, "El catálogo solicitado no existe.");
}
