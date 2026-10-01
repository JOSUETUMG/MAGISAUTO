using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController]
[Route("api/salud")]
public class SaludController : ControllerBase
{
    /// <summary>Comprueba que la API responde; no comprueba SQL Server.</summary>
    [HttpGet]
    [ProducesResponseType<EstadoApiRespuesta>(StatusCodes.Status200OK)]
    public ActionResult<EstadoApiRespuesta> ObtenerEstado()
    {
        return Ok(new EstadoApiRespuesta("MAGISAUTO.API", "Disponible", DateTimeOffset.UtcNow));
    }
}

public sealed record EstadoApiRespuesta(string Aplicacion, string Estado, DateTimeOffset FechaUtc);
