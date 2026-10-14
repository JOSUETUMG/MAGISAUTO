using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;
namespace MAGISAUTO.API.Controllers;
[ApiController,Route("api/creditos")]
public sealed class CreditosController(CreditoRepositorio creditos):ControllerBase
{
    [HttpGet] public async Task<IActionResult> Listar([FromQuery,StringLength(200)] string? criterio,CancellationToken ct)=>Ok(await creditos.Listar(string.IsNullOrWhiteSpace(criterio)?null:criterio.Trim(),ct));
    [HttpGet("catalogos")] public async Task<IActionResult> Catalogos(CancellationToken ct)=>Ok(await creditos.Catalogos(ct));
    [HttpGet("{numero}")] public async Task<IActionResult> Obtener(string numero,CancellationToken ct)=>Ok(await creditos.Obtener(numero,ct));
    [HttpPost] public async Task<IActionResult> Crear(CreditoSolicitud s,CancellationToken ct){await creditos.Guardar(null,s,ct);return StatusCode(201,new{s.NumeroCredito});}
    [HttpPut("{numero}")] public async Task<IActionResult> Guardar(string numero,CreditoSolicitud s,CancellationToken ct){await creditos.Guardar(numero,s,ct);return NoContent();}
    [HttpPost("{numero}/presentar")] public async Task<IActionResult> Presentar(string numero,CreditoAccion s,CancellationToken ct){await creditos.Accion(numero,"Presentar",s,ct);return NoContent();}
    [HttpPost("{numero}/aprobar")] public async Task<IActionResult> Aprobar(string numero,CreditoAccion s,CancellationToken ct){await creditos.Accion(numero,"Aprobar",s,ct);return NoContent();}
    [HttpPost("{numero}/anular")] public async Task<IActionResult> Anular(string numero,CreditoAnulacion s,CancellationToken ct){await creditos.Accion(numero,"Anular",s,ct);return NoContent();}
    [HttpDelete("{numero}")] public async Task<IActionResult> Eliminar(string numero,CancellationToken ct){await creditos.Accion(numero,"Eliminar",null,ct);return NoContent();}
}
