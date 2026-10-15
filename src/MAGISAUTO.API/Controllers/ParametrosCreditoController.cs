using System.ComponentModel.DataAnnotations;
using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Modelos;
using Microsoft.AspNetCore.Mvc;
namespace MAGISAUTO.API.Controllers;

[ApiController,Route("api/parametros-credito")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public sealed class ParametrosCreditoController(ParametroCreditoRepositorio parametros):ControllerBase
{
    private void Consulta(bool busqueda=false) {
        if(Request.Query.Any(q=>!busqueda||q.Key!="criterio"||q.Value.Count!=1)||
            (Request.Query.ContainsKey("criterio")&&string.IsNullOrWhiteSpace(Request.Query["criterio"])))
            throw new OperacionCatalogoException(400,"Usa un único criterio no vacío, o quita el filtro para ver todos.");
    }
    [HttpGet] public async Task<IActionResult> Listar([FromQuery,StringLength(200)]string? criterio,CancellationToken ct){Consulta(true);return Ok(await parametros.Listar(criterio?.Trim(),ct));}
    [HttpPost] public async Task<IActionResult> Crear(ParametroCreditoSolicitud s,CancellationToken ct){Consulta();var id=await parametros.Crear(s,ct);return StatusCode(201,new{CodigoParametro=id});}
    [HttpPut("{id:int}")] public async Task<IActionResult> Editar([Range(1,int.MaxValue)]int id,ParametroCreditoSolicitud s,CancellationToken ct){Consulta();await parametros.Cambiar(id,"Actualizar",s,ct);return NoContent();}
    [HttpPost("{id:int}/activar")] public async Task<IActionResult> Activar([Range(1,int.MaxValue)]int id,CancellationToken ct){Consulta();await parametros.Cambiar(id,"Activar",null,ct);return NoContent();}
    [HttpDelete("{id:int}")] public async Task<IActionResult> Eliminar([Range(1,int.MaxValue)]int id,CancellationToken ct){Consulta();await parametros.Cambiar(id,"Eliminar",null,ct);return NoContent();}
}
