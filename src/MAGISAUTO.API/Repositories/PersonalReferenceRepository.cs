using Microsoft.EntityFrameworkCore;
using MAGISAUTO.API.Data;
using MAGISAUTO.API.Models;

namespace MAGISAUTO.API.Repositories
{
    public class PersonalReferenceRepository : IPersonalReferenceRepository
    {
        private readonly ApplicationDbContext _db;

        public PersonalReferenceRepository(ApplicationDbContext db)
        {
            _db = db;
        }

        public async Task<PersonalReference> AddAsync(PersonalReference entity)
        {
            _db.PersonalReferences.Add(entity);
            await _db.SaveChangesAsync();
            return entity;
        }

        public async Task DeleteAsync(PersonalReference entity)
        {
            _db.PersonalReferences.Remove(entity);
            await _db.SaveChangesAsync();
        }

        public async Task<PersonalReference?> FindByIdAsync(int id)
        {
            return await _db.PersonalReferences.FindAsync(id);
        }

        public async Task<IEnumerable<PersonalReference>> GetByClientAsync(int clienteId)
        {
            return await _db.PersonalReferences.Where(p => p.ClienteId == clienteId).ToListAsync();
        }

        public async Task<int> CountByClientAsync(int clienteId)
        {
            return await _db.PersonalReferences.CountAsync(p => p.ClienteId == clienteId);
        }
    }
}
