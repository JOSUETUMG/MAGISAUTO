using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Datos;

public sealed class ConexionSqlFactory(IConfiguration configuration)
{
    public SqlConnection Crear()
    {
        var cadena = configuration.GetConnectionString("MagisAuto");
        if (string.IsNullOrWhiteSpace(cadena))
        {
            throw new ConfiguracionBaseDatosException("ausente");
        }

        try
        {
            return new SqlConnection(cadena);
        }
        catch (ArgumentException)
        {
            // No devolver la cadena ni el mensaje del proveedor: pueden contener datos privados.
            throw new ConfiguracionBaseDatosException("formato inválido");
        }
    }
}

public sealed class ConfiguracionBaseDatosException : Exception
{
    public string Motivo { get; }

    public ConfiguracionBaseDatosException(string motivo)
        : base("La conexión con la base de datos no está configurada correctamente.")
    {
        Motivo = motivo;
    }
}
