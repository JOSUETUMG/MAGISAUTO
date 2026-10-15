using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;

namespace MAGISAUTO.API.Controllers;

[ApiController, Route("api/catalogos/auxiliares")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class CatalogosAuxiliaresController(CatalogoAuxiliarRepositorio repositorio) : ControllerBase
{
    private void ValidarConsulta(params string[] admitidos)
    {
        if (Request.Query.Any(q => !admitidos.Contains(q.Key) || q.Value.Count != 1))
            throw new OperacionCatalogoException(400, "La consulta contiene filtros desconocidos o repetidos.");
        if (Request.Query.TryGetValue("codigoDepartamento", out var valor) && string.IsNullOrWhiteSpace(valor))
            throw new OperacionCatalogoException(400, "Selecciona un departamento o quita el filtro.");
    }

    [HttpGet]
    public IActionResult Definiciones() => Ok(CatalogosAuxiliares.Todos);

    [HttpGet("{catalogo}")]
    public async Task<IActionResult> Listar(string catalogo,
        [FromQuery, StringLength(200)] string? criterio,
        [FromQuery, Range(1, int.MaxValue)] int? codigoDepartamento, CancellationToken ct)
    {
        var d = CatalogosAuxiliares.Obtener(catalogo);
        ValidarConsulta("criterio", "codigoDepartamento");
        if (Request.Query.ContainsKey("criterio") && string.IsNullOrWhiteSpace(criterio))
            return BadRequest(new ProblemDetails { Detail = "Escribe un criterio o quita el filtro para ver todos." });
        return Ok(await repositorio.Listar(d, criterio?.Trim(), codigoDepartamento, ct));
    }

    [HttpPost("{catalogo}")]
    public async Task<IActionResult> Crear(string catalogo, CatalogoAuxiliarCrear s, CancellationToken ct)
    {
        var d = CatalogosAuxiliares.Obtener(catalogo);
        ValidarConsulta();
        await repositorio.Guardar(d, s.Codigo, s.CodigoDepartamento, s, true, ct);
        return StatusCode(201, new CatalogoAuxiliarFila(s.Codigo, s.Descripcion.Trim(), s.CodigoDepartamento, s.RequiereReferencia));
    }

    [HttpPut("{catalogo}/{codigo:int}")]
    public async Task<IActionResult> Actualizar(string catalogo, [Range(1, int.MaxValue)] int codigo,
        [FromQuery, Range(1, int.MaxValue)] int? codigoDepartamento, CatalogoAuxiliarEditar s, CancellationToken ct)
    {
        var d = CatalogosAuxiliares.Obtener(catalogo);
        ValidarConsulta("codigoDepartamento");
        await repositorio.Guardar(d, codigo, codigoDepartamento, s, false, ct);
        return Ok(new CatalogoAuxiliarFila(codigo, s.Descripcion.Trim(), codigoDepartamento, s.RequiereReferencia));
    }

    [HttpDelete("{catalogo}/{codigo:int}")]
    public async Task<IActionResult> Eliminar(string catalogo, [Range(1, int.MaxValue)] int codigo,
        [FromQuery, Range(1, int.MaxValue)] int? codigoDepartamento, CancellationToken ct)
    {
        var d = CatalogosAuxiliares.Obtener(catalogo);
        ValidarConsulta("codigoDepartamento");
        await repositorio.Guardar(d, codigo, codigoDepartamento, null, false, ct);
        return NoContent();
    }
}
