using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/clientes")]
[ProducesResponseType<ValidationProblemDetails>(400)]
[ProducesResponseType<ProblemDetails>(409)]
[ProducesResponseType<ProblemDetails>(503)]
public sealed class ClientesController(ClienteRepositorio clientes) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ClienteFicha>>> Consultar([FromQuery, StringLength(200)] string? criterio, CancellationToken ct)
    {
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio)) return BadRequest(new ProblemDetails { Detail = "Escribe un criterio o quita el filtro." });
        return Ok(await clientes.Consultar(criterio?.Trim(), ct));
    }

    [HttpGet("catalogos")]
    public async Task<IActionResult> Catalogos(CancellationToken ct) => Ok(await clientes.Catalogos(ct));

    [HttpGet("{codigo:int}")]
    public async Task<IActionResult> Obtener([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    {
        var ficha = (await clientes.Consultar(null, ct)).SingleOrDefault(c => c.CodigoCliente == codigo);
        return ficha is null ? NotFound(new ProblemDetails { Detail = "El cliente ya no existe." }) : Ok(ficha);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(ClienteSolicitud solicitud, CancellationToken ct) =>
        StatusCode(201, new { CodigoCliente = await clientes.Guardar(null, solicitud, ct) });

    [HttpPut("{codigo:int}")]
    public async Task<IActionResult> Actualizar([Range(1, int.MaxValue)] int codigo, ClienteSolicitud solicitud, CancellationToken ct)
    {
        await clientes.Guardar(codigo, solicitud, ct);
        return NoContent();
    }

    [HttpDelete("{codigo:int}")]
    public async Task<IActionResult> Eliminar([Range(1, int.MaxValue)] int codigo, CancellationToken ct)
    {
        await clientes.Eliminar(codigo, ct);
        return NoContent();
    }
}
