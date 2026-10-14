using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/vehiculos")]
[ProducesResponseType<ValidationProblemDetails>(400)]
[ProducesResponseType<ProblemDetails>(409)]
[ProducesResponseType<ProblemDetails>(503)]
public sealed class VehiculosController(VehiculoRepositorio vehiculos) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery, StringLength(200)] string? criterio,
        [FromQuery, Range(1, int.MaxValue)] int? codigoMarca, CancellationToken ct)
    {
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio))
            return BadRequest(new ProblemDetails { Detail = "Escribe un criterio o quita el filtro." });
        if (Request.Query.ContainsKey("codigoMarca") && codigoMarca is null)
            return BadRequest(new ProblemDetails { Detail = "Selecciona una marca o quita el filtro." });
        return Ok(await vehiculos.Listar(criterio?.Trim(), codigoMarca, ct));
    }

    [HttpGet("catalogos")]
    public async Task<IActionResult> Catalogos(CancellationToken ct) => Ok(await vehiculos.Catalogos(ct));

    [HttpGet("{codigo:int}")]
    public async Task<IActionResult> Obtener([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    {
        var ficha = (await vehiculos.Listar(null, null, ct)).SingleOrDefault(v => v.CodigoGarantia == codigo);
        return ficha is null ? NotFound(new ProblemDetails { Detail = "El vehículo ya no existe." }) : Ok(ficha);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(VehiculoSolicitud solicitud, CancellationToken ct) =>
        StatusCode(201, new { CodigoGarantia = await vehiculos.Guardar(null, solicitud, ct) });

    [HttpPut("{codigo:int}")]
    public async Task<IActionResult> Actualizar([Range(1, int.MaxValue)] int codigo, VehiculoSolicitud solicitud, CancellationToken ct)
    { await vehiculos.Guardar(codigo, solicitud, ct); return NoContent(); }

    [HttpDelete("{codigo:int}")]
    public async Task<IActionResult> Eliminar([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    { await vehiculos.Eliminar(codigo, ct); return NoContent(); }
}
