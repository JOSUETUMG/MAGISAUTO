using MAGISAUTO.API.Datos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/reportes")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class ReportesController(ReporteRepositorio reportes) : ControllerBase
{
    [HttpGet]
    public IActionResult Listar() => Ok(new { fechaGuatemala = CatalogoReportes.HoyGuatemala.ToString("yyyy-MM-dd"), reportes = CatalogoReportes.Todos });

    [HttpGet("catalogos")]
    public async Task<IActionResult> Catalogos(CancellationToken ct) => Ok(await reportes.Catalogos(ct));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Consultar(int id, CancellationToken ct) => Ok(await reportes.Consultar(id, Request.Query, ct));
}
