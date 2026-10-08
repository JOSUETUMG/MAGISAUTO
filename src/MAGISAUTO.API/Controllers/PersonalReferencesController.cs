using Microsoft.AspNetCore.Mvc;
using MAGISAUTO.API.Dtos;
using MAGISAUTO.API.Services;

namespace MAGISAUTO.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PersonalReferencesController : ControllerBase
    {
        private readonly IPersonalReferenceService _service;

        public PersonalReferencesController(IPersonalReferenceService service)
        {
            _service = service;
        }

        [HttpPost]
        public async Task<IActionResult> Create(PersonalReferenceDto dto)
        {
            try
            {
                var created = await _service.CreateAsync(dto);
                return CreatedAtAction(nameof(GetByClient), new { clienteId = created.ClienteId }, created);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        [HttpGet("client/{clienteId}")]
        public async Task<IActionResult> GetByClient(int clienteId)
        {
            var list = await _service.GetByClientAsync(clienteId);
            return Ok(list);
        }

        [HttpGet("client/{clienteId}/hasminimum")]
        public async Task<IActionResult> HasMinimum(int clienteId)
        {
            var ok = await _service.HasMinimumReferencesAsync(clienteId);
            return Ok(new { clienteId, cumple = ok });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            await _service.DeleteAsync(id);
            return NoContent();
        }
    }
}
