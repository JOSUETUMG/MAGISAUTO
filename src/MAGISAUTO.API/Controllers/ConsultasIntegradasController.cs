using MAGISAUTO.API.Datos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/consultas-integradas")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class ConsultasIntegradasController(ConsultaIntegradaRepositorio repositorio) : ControllerBase
{
    [HttpGet]
    public IActionResult Listar() => Ok(ConsultaIntegradaRepositorio.Definiciones);

    [HttpGet("{id}")]
    public async Task<IActionResult> Consultar(string id, CancellationToken ct) => Ok(await repositorio.Consultar(id, Request.Query, ct));

    [HttpDelete("{id}/{codigo:int}")]
    public async Task<IActionResult> Eliminar(string id, int codigo, CancellationToken ct)
    {
        if (Request.Query.Count > 0) throw new OperacionCatalogoException(400, "La eliminación no admite filtros.");
        await repositorio.Eliminar(id, codigo, ct);
        return NoContent();
    }
}
