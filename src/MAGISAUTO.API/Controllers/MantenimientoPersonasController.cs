using MAGISAUTO.API.Datos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/mantenimiento-personas")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class MantenimientoPersonasController(MantenimientoPersonaRepositorio repositorio) : ControllerBase
{
    [HttpGet("{id}")]
    public async Task<IActionResult> Formulario(string id, CancellationToken ct) => Ok(await repositorio.Formulario(id, ct));

    [HttpPost("{id}/{operacion}")]
    public async Task<IActionResult> Cambiar(string id, string operacion, CambioFicha solicitud, CancellationToken ct)
    {
        if (Request.Query.Count != 0) throw new OperacionCatalogoException(400, "La operación no admite filtros.");
        await repositorio.Cambiar(id, operacion, solicitud, ct);
        return NoContent();
    }
}
