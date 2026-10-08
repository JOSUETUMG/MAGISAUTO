using MAGISAUTO.API.Dtos;
using MAGISAUTO.API.Models;

namespace MAGISAUTO.API.Services
{
    public interface IPersonalReferenceService
    {
        Task<PersonalReference> CreateAsync(PersonalReferenceDto dto);
        Task<IEnumerable<PersonalReference>> GetByClientAsync(int clienteId);
        Task<int> CountByClientAsync(int clienteId);
        Task<bool> HasMinimumReferencesAsync(int clienteId, int minimum = 3);
        Task DeleteAsync(int id);
    }
}
