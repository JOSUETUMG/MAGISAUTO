using MAGISAUTO.API.Datos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController]
[Route("api/salud/base-datos")]
public sealed class SaludBaseDatosController(IMarcaRepositorio marcas) : ControllerBase
{
    /// <summary>Comprueba una consulta real mediante el procedimiento de listado de marcas.</summary>
    [HttpGet]
    [ProducesResponseType<EstadoBaseDatosRespuesta>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<EstadoBaseDatosRespuesta>> Comprobar(CancellationToken cancellationToken)
    {
        await marcas.ConsultarAsync(null, cancellationToken);
        return Ok(new EstadoBaseDatosRespuesta("Disponible", DateTimeOffset.UtcNow));
    }
}

public sealed record EstadoBaseDatosRespuesta(string Estado, DateTimeOffset FechaUtc);
