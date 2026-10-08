using MAGISAUTO.API.Models;

namespace MAGISAUTO.API.Repositories
{
    public interface IPersonalReferenceRepository
    {
        Task<PersonalReference> AddAsync(PersonalReference entity);
        Task<IEnumerable<PersonalReference>> GetByClientAsync(int clienteId);
        Task<int> CountByClientAsync(int clienteId);
        Task<PersonalReference?> FindByIdAsync(int id);
        Task DeleteAsync(PersonalReference entity);
    }
}
