using Microsoft.EntityFrameworkCore;
using MAGISAUTO.API.Data;
using MAGISAUTO.API.Dtos;
using MAGISAUTO.API.Models;
using MAGISAUTO.API.Repositories;
using MAGISAUTO.API.Services;
using Xunit;

namespace MAGISAUTO.Tests
{
    public class PersonalReferenceServiceTests
    {
        private ApplicationDbContext CreateContext(string dbName)
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(dbName)
                .Options;
            return new ApplicationDbContext(options);
        }

        [Fact]
        public async Task CreateAsync_Throws_When_ReferenceIsClient()
        {
            var db = CreateContext("test1");
            db.Clientes.Add(new Cliente { Id = 1, NombreCompleto = "Juan Perez" });
            await db.SaveChangesAsync();

            var repo = new PersonalReferenceRepository(db);
            var service = new PersonalReferenceService(db, repo);

            var dto = new PersonalReferenceDto
            {
                ClienteId = 1,
                NombreCompleto = "Juan Perez"
            };

            await Assert.ThrowsAsync<ArgumentException>(async () => await service.CreateAsync(dto));
        }

        [Fact]
        public async Task HasMinimumReferences_ReturnsTrue_When_ThreeOrMore()
        {
            var db = CreateContext("test2");
            db.Clientes.Add(new Cliente { Id = 2, NombreCompleto = "Cliente2" });
            db.PersonalReferences.AddRange(new PersonalReference { ClienteId = 2, NombreCompleto = "A" },
                                           new PersonalReference { ClienteId = 2, NombreCompleto = "B" },
                                           new PersonalReference { ClienteId = 2, NombreCompleto = "C" });
            await db.SaveChangesAsync();

            var repo = new PersonalReferenceRepository(db);
            var service = new PersonalReferenceService(db, repo);

            var result = await service.HasMinimumReferencesAsync(2);
            Assert.True(result);
        }

        [Fact]
        public async Task HasMinimumReferences_ReturnsFalse_When_LessThanThree()
        {
            var db = CreateContext("test3");
            db.Clientes.Add(new Cliente { Id = 3, NombreCompleto = "Cliente3" });
            db.PersonalReferences.Add(new PersonalReference { ClienteId = 3, NombreCompleto = "Solo" });
            await db.SaveChangesAsync();

            var repo = new PersonalReferenceRepository(db);
            var service = new PersonalReferenceService(db, repo);

            var result = await service.HasMinimumReferencesAsync(3);
            Assert.False(result);
        }
    }
}
