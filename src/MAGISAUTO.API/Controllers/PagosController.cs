using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;
namespace MAGISAUTO.API.Controllers;
[ApiController,Route("api/pagos")]
public sealed class PagosController(PagoRepositorio pagos):ControllerBase
{
    [HttpGet] public async Task<IActionResult> Listar([FromQuery,StringLength(200)] string? criterio,[FromQuery,StringLength(20)]string? numeroCredito,CancellationToken ct)=>Ok(await pagos.Listar(string.IsNullOrWhiteSpace(criterio)?null:criterio.Trim(),string.IsNullOrWhiteSpace(numeroCredito)?null:numeroCredito.Trim(),ct));
    [HttpGet("catalogos")] public async Task<IActionResult> Catalogos(CancellationToken ct)=>Ok(await pagos.Catalogos(ct));
    [HttpGet("credito/{numero}")] public async Task<IActionResult> EstadoCuenta([StringLength(20)]string numero,CancellationToken ct)=>Ok(await pagos.EstadoCuenta(numero,ct));
    [HttpGet("{codigo:long}")] public async Task<IActionResult> Obtener([Range(1,long.MaxValue)]long codigo,CancellationToken ct)=>Ok(await pagos.Obtener(codigo,ct));
    [HttpPost] public async Task<IActionResult> Registrar(PagoSolicitud s,CancellationToken ct)=>StatusCode(201,await pagos.Registrar(s,ct));
    [HttpPut("{codigo:long}/observacion")] public async Task<IActionResult> Actualizar([Range(1,long.MaxValue)]long codigo,PagoObservacion s,CancellationToken ct){await pagos.Actualizar(codigo,s,ct);return NoContent();}
    [HttpPost("{codigo:long}/anular")] public async Task<IActionResult> Anular([Range(1,long.MaxValue)]long codigo,PagoAnulacion s,CancellationToken ct){await pagos.Anular(codigo,s,ct);return NoContent();}
    [HttpDelete("{codigo:long}")] public async Task<IActionResult> Eliminar([Range(1,long.MaxValue)]long codigo,CancellationToken ct){await pagos.Eliminar(codigo,ct);return NoContent();}
}
