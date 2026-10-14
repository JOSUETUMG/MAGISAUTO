using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController]
[Route("api/catalogos/agencias")]
[ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
public sealed class AgenciasController(IAgenciaRepositorio agencias) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<AgenciaRespuesta>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<AgenciaRespuesta>>> Consultar(
        [FromQuery, StringLength(200, ErrorMessage = "El criterio admite hasta 200 caracteres.")] string? criterio,
        CancellationToken cancellationToken)
    {
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio))
        {
            ModelState.AddModelError(nameof(criterio), "Escribe un criterio o quita el filtro para listar las agencias.");
            return ValidationProblem(ModelState);
        }
        return Ok(await agencias.ConsultarAsync(criterio?.Trim(), cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType<AgenciaRespuesta>(StatusCodes.Status201Created)]
    public async Task<ActionResult<AgenciaRespuesta>> Crear(AgenciaSolicitud solicitud, CancellationToken cancellationToken)
    {
        var nombre = solicitud.Nombre.Trim();
        var region = solicitud.Region.Trim();
        var codigo = await agencias.CrearAsync(nombre, region, cancellationToken);
        return StatusCode(201, new AgenciaRespuesta(codigo, nombre, region));
    }

    [HttpPut("{codigo:int}")]
    [ProducesResponseType<AgenciaRespuesta>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AgenciaRespuesta>> Actualizar(
        [Range(1, int.MaxValue, ErrorMessage = "El código debe ser mayor que cero.")] int codigo,
        AgenciaSolicitud solicitud, CancellationToken cancellationToken)
    {
        var nombre = solicitud.Nombre.Trim();
        var region = solicitud.Region.Trim();
        await agencias.ActualizarAsync(codigo, nombre, region, cancellationToken);
        return Ok(new AgenciaRespuesta(codigo, nombre, region));
    }

    [HttpDelete("{codigo:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Eliminar(
        [Range(1, int.MaxValue, ErrorMessage = "El código debe ser mayor que cero.")] int codigo,
        CancellationToken cancellationToken)
    {
        await agencias.EliminarAsync(codigo, cancellationToken);
        return NoContent();
    }
}
