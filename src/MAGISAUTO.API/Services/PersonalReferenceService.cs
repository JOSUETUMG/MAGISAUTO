using Microsoft.EntityFrameworkCore;
using MAGISAUTO.API.Data;
using MAGISAUTO.API.Dtos;
using MAGISAUTO.API.Models;

namespace MAGISAUTO.API.Services
{
    public class PersonalReferenceService : IPersonalReferenceService
    {
        private readonly ApplicationDbContext _db;
        private readonly MAGISAUTO.API.Repositories.IPersonalReferenceRepository _repo;

        public PersonalReferenceService(ApplicationDbContext db, MAGISAUTO.API.Repositories.IPersonalReferenceRepository repo)
        {
            _db = db;
            _repo = repo;
        }

        public async Task<PersonalReference> CreateAsync(PersonalReferenceDto dto)
        {
            // Validate cliente exists
            var cliente = await _db.Clientes.FindAsync(dto.ClienteId);
            if (cliente == null)
                throw new ArgumentException("Cliente no encontrado.");

            // El propio cliente no puede ser su referencia (comparamos nombres)
            if (!string.IsNullOrWhiteSpace(cliente.NombreCompleto) &&
                string.Equals(cliente.NombreCompleto.Trim(), dto.NombreCompleto?.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException("El propio cliente no puede aparecer como su referencia.");
            }

            var entity = new PersonalReference
            {
                ClienteId = dto.ClienteId,
                NombreCompleto = dto.NombreCompleto ?? string.Empty,
                Telefonos = dto.Telefonos,
                LugarTrabajo = dto.LugarTrabajo,
                Parentesco = dto.Parentesco,
                Direccion = dto.Direccion
            };

            return await _repo.AddAsync(entity);
        }

        public async Task<IEnumerable<PersonalReference>> GetByClientAsync(int clienteId)
        {
            return await _repo.GetByClientAsync(clienteId);
        }

        public async Task<int> CountByClientAsync(int clienteId)
        {
            return await _repo.CountByClientAsync(clienteId);
        }

        public async Task<bool> HasMinimumReferencesAsync(int clienteId, int minimum = 3)
        {
            var count = await CountByClientAsync(clienteId);
            return count >= minimum;
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _repo.FindByIdAsync(id);
            if (entity == null) return;
            await _repo.DeleteAsync(entity);
        }
    }
}
