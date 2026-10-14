using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/fiadores")]
[ProducesResponseType<ValidationProblemDetails>(400)]
[ProducesResponseType<ProblemDetails>(409)]
[ProducesResponseType<ProblemDetails>(503)]
public sealed class FiadoresController(FiadorRepositorio fiadores) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<FiadorFicha>>> Consultar([FromQuery, StringLength(200)] string? criterio, CancellationToken ct)
    {
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio)) return BadRequest(new ProblemDetails { Detail = "Escribe un criterio o quita el filtro." });
        return Ok(await fiadores.Consultar(criterio?.Trim(), ct));
    }

    [HttpGet("catalogos")]
    public async Task<IActionResult> Catalogos(CancellationToken ct) => Ok(await fiadores.Catalogos(ct));

    [HttpGet("{codigo:int}")]
    public async Task<IActionResult> Obtener([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    {
        var ficha = (await fiadores.Consultar(null, ct)).SingleOrDefault(c => c.CodigoFiador == codigo);
        return ficha is null ? NotFound(new ProblemDetails { Detail = "El fiador ya no existe." }) : Ok(ficha);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(FiadorSolicitud solicitud, CancellationToken ct) =>
        StatusCode(201, new { CodigoFiador = await fiadores.Guardar(null, solicitud, ct) });

    [HttpPut("{codigo:int}")]
    public async Task<IActionResult> Actualizar([Range(1, int.MaxValue)] int codigo, FiadorSolicitud solicitud, CancellationToken ct)
    {
        await fiadores.Guardar(codigo, solicitud, ct);
        return NoContent();
    }

    [HttpDelete("{codigo:int}")]
    public async Task<IActionResult> Eliminar([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    {
        await fiadores.Eliminar(codigo, ct);
        return NoContent();
    }
}
