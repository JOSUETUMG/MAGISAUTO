using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController]
[Route("api/vendedores")]
[ProducesResponseType<ValidationProblemDetails>(400)]
[ProducesResponseType<ProblemDetails>(503)]
public sealed class VendedoresController(IVendedorRepositorio vendedores) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<VendedorRespuesta>>(200)]
    public async Task<ActionResult<IReadOnlyList<VendedorRespuesta>>> Consultar(
        [FromQuery, StringLength(200)] string? criterio,
        [FromQuery, Range(1, int.MaxValue)] int? codigoAgencia, CancellationToken ct)
    {
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio))
            ModelState.AddModelError(nameof(criterio), "Escribe un criterio o quita el filtro.");
        if (Request.Query.ContainsKey("codigoAgencia") && codigoAgencia is null)
            ModelState.AddModelError(nameof(codigoAgencia), "Selecciona una agencia o quita el filtro.");
        if (!ModelState.IsValid) return ValidationProblem(ModelState);
        return Ok(await vendedores.ConsultarAsync(criterio?.Trim(), codigoAgencia, ct));
    }

    [HttpPost]
    [ProducesResponseType(201)]
    [ProducesResponseType<ProblemDetails>(409)]
    public async Task<IActionResult> Crear(VendedorSolicitud solicitud, CancellationToken ct)
    {
        var codigo = await vendedores.GuardarAsync(null, solicitud, ct);
        return StatusCode(201, new { CodigoVendedor = codigo });
    }

    [HttpPut("{codigo:int}")]
    [ProducesResponseType(204)]
    [ProducesResponseType<ProblemDetails>(404)]
    [ProducesResponseType<ProblemDetails>(409)]
    public async Task<IActionResult> Actualizar([Range(1, int.MaxValue)] int codigo, VendedorSolicitud solicitud, CancellationToken ct)
    {
        await vendedores.GuardarAsync(codigo, solicitud, ct);
        return NoContent();
    }

    [HttpDelete("{codigo:int}")]
    [ProducesResponseType(204)]
    [ProducesResponseType<ProblemDetails>(404)]
    [ProducesResponseType<ProblemDetails>(409)]
    public async Task<IActionResult> Eliminar([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    {
        await vendedores.EliminarAsync(codigo, ct);
        return NoContent();
    }
}
