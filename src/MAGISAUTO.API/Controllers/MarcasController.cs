using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController]
[Route("api/catalogos/marcas")]
public sealed class MarcasController(IMarcaRepositorio marcas) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType<MarcaRespuesta>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<MarcaRespuesta>> Crear(MarcaCrearSolicitud solicitud, CancellationToken cancellationToken)
    {
        var nombre = solicitud.Descripcion.Trim();
        await marcas.CrearAsync(solicitud.CodigoMarca, nombre, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, new MarcaRespuesta(solicitud.CodigoMarca, nombre));
    }

    [HttpPut("{codigo:int}")]
    [ProducesResponseType<MarcaRespuesta>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<MarcaRespuesta>> Actualizar(
        [Range(1, int.MaxValue, ErrorMessage = "El código debe ser mayor que cero.")] int codigo,
        MarcaEditarSolicitud solicitud, CancellationToken cancellationToken)
    {
        var nombre = solicitud.Descripcion.Trim();
        await marcas.ActualizarAsync(codigo, nombre, cancellationToken);
        return Ok(new MarcaRespuesta(codigo, nombre));
    }

    [HttpDelete("{codigo:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> Eliminar(
        [Range(1, int.MaxValue, ErrorMessage = "El código debe ser mayor que cero.")] int codigo,
        CancellationToken cancellationToken)
    {
        await marcas.EliminarAsync(codigo, cancellationToken);
        return NoContent();
    }

    /// <summary>Lista marcas o busca por código/descripción mediante procedimientos almacenados.</summary>
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<MarcaRespuesta>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<IReadOnlyList<MarcaRespuesta>>> Consultar(
        [FromQuery, StringLength(200, ErrorMessage = "El criterio admite hasta 200 caracteres.")]
        string? criterio,
        CancellationToken cancellationToken)
    {
        // MVC puede convertir una cadena vacía en null: distinguirla de un parámetro ausente.
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio))
        {
            ModelState.AddModelError(nameof(criterio), "Escribe un criterio o quita el filtro para listar todas las marcas.");
            return ValidationProblem(ModelState);
        }

        return Ok(await marcas.ConsultarAsync(criterio?.Trim(), cancellationToken));
    }
}
