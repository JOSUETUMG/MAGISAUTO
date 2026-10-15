using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/valoraciones")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
[ProducesResponseType<ValidationProblemDetails>(400)]
[ProducesResponseType<ProblemDetails>(404)]
[ProducesResponseType<ProblemDetails>(409)]
public sealed class ValoracionesController(ValoracionRepositorio valoraciones) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery, Range(1, int.MaxValue)] int? codigoGarantia, [FromQuery, StringLength(200)] string? criterio, CancellationToken ct)
    {
        if (Request.Query.Any(k => (k.Key is not "codigoGarantia" and not "criterio") || k.Value.Count != 1))
            throw new OperacionCatalogoException(400, "La consulta contiene filtros desconocidos o repetidos.");
        if (Request.Query.ContainsKey("codigoGarantia") && codigoGarantia is null)
            throw new OperacionCatalogoException(400, "Indica un vehículo válido o quita el filtro.");
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio))
            throw new OperacionCatalogoException(400, "Escribe un criterio o quita el filtro.");
        return Ok(await valoraciones.Listar(codigoGarantia, criterio?.Trim(), ct));
    }

    [HttpGet("{codigo:int}")]
    public async Task<IActionResult> Obtener([Range(1, int.MaxValue)] int codigo, CancellationToken ct) => Ok(await valoraciones.Obtener(codigo, ct));

    [HttpPost]
    public async Task<IActionResult> Crear(ValoracionSolicitud solicitud, CancellationToken ct) => StatusCode(201, new { CodigoDepreciacion = await valoraciones.Guardar(null, solicitud, ct) });

    [HttpPut("{codigo:int}")]
    public async Task<IActionResult> Actualizar([Range(1, int.MaxValue)] int codigo, ValoracionSolicitud solicitud, CancellationToken ct)
    { await valoraciones.Guardar(codigo, solicitud, ct); return NoContent(); }

    [HttpDelete("{codigo:int}")]
    public async Task<IActionResult> Eliminar([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    { await valoraciones.Eliminar(codigo, ct); return NoContent(); }
}
