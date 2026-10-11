namespace MAGISAUTO.API.Modelos;

public sealed record LineaRespuesta(int CodigoMarca, int CodigoLinea, string Descripcion);
public sealed record LineaListado(int CodigoMarca, int CodigoLinea, string Descripcion, string NombreMarca);
