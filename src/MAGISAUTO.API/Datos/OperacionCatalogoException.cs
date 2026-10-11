namespace MAGISAUTO.API.Datos;

// Solo mensajes propios: nunca enviar el texto interno de SQL al navegador.
public sealed class OperacionCatalogoException(int estado, string mensaje) : Exception(mensaje)
{
    public int Estado { get; } = estado;
}
