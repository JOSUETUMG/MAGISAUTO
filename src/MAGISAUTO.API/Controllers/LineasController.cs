using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController]
[Route("api/catalogos/lineas")]
[ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
public sealed class LineasController(ILineaRepositorio lineas, IMarcaRepositorio marcas) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<LineaListado>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<LineaListado>>> Consultar(
        [FromQuery, StringLength(200, ErrorMessage = "El criterio admite hasta 200 caracteres.")] string? criterio,
        [FromQuery, Range(1, int.MaxValue, ErrorMessage = "Selecciona una marca válida.")] int? codigoMarca,
        CancellationToken cancellationToken)
    {
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio))
            ModelState.AddModelError(nameof(criterio), "Escribe un criterio o quita el filtro para listar las líneas.");
        if (Request.Query.ContainsKey("codigoMarca") && codigoMarca is null)
            ModelState.AddModelError(nameof(codigoMarca), "Indica un código de marca o quita el filtro.");
        if (!ModelState.IsValid) return ValidationProblem(ModelState);

        var resultado = await lineas.ConsultarAsync(criterio?.Trim(), cancellationToken);
        var nombres = (await marcas.ConsultarAsync(null, cancellationToken)).ToDictionary(m => m.CodigoMarca, m => m.Descripcion);
        // Los datos provienen únicamente de procedimientos. Se enriquece el catálogo en la API.
        return Ok(resultado.Where(l => codigoMarca is null || l.CodigoMarca == codigoMarca)
            .Select(l => new LineaListado(l.CodigoMarca, l.CodigoLinea, l.Descripcion,
                nombres.GetValueOrDefault(l.CodigoMarca, $"Marca {l.CodigoMarca}"))).ToArray());
    }

    [HttpPost]
    [ProducesResponseType<LineaRespuesta>(StatusCodes.Status201Created)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<LineaRespuesta>> Crear(LineaCrearSolicitud solicitud, CancellationToken cancellationToken)
    {
        var nombre = solicitud.Descripcion.Trim();
        await lineas.CrearAsync(solicitud.CodigoMarca, solicitud.CodigoLinea, nombre, cancellationToken);
        return StatusCode(201, new LineaRespuesta(solicitud.CodigoMarca, solicitud.CodigoLinea, nombre));
    }

    [HttpPut("{codigoMarca:int}/{codigoLinea:int}")]
    [ProducesResponseType<LineaRespuesta>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<LineaRespuesta>> Actualizar(
        [Range(1, int.MaxValue, ErrorMessage = "El código de marca debe ser mayor que cero.")] int codigoMarca,
        [Range(1, int.MaxValue, ErrorMessage = "El código de línea debe ser mayor que cero.")] int codigoLinea,
        LineaEditarSolicitud solicitud, CancellationToken cancellationToken)
    {
        var nombre = solicitud.Descripcion.Trim();
        await lineas.ActualizarAsync(codigoMarca, codigoLinea, nombre, cancellationToken);
        return Ok(new LineaRespuesta(codigoMarca, codigoLinea, nombre));
    }

    [HttpDelete("{codigoMarca:int}/{codigoLinea:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Eliminar(
        [Range(1, int.MaxValue, ErrorMessage = "El código de marca debe ser mayor que cero.")] int codigoMarca,
        [Range(1, int.MaxValue, ErrorMessage = "El código de línea debe ser mayor que cero.")] int codigoLinea,
        CancellationToken cancellationToken)
    {
        await lineas.EliminarAsync(codigoMarca, codigoLinea, cancellationToken);
        return NoContent();
    }
}
