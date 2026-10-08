using Microsoft.EntityFrameworkCore;
using MAGISAUTO.API.Models;

namespace MAGISAUTO.API.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        public DbSet<Cliente> Clientes { get; set; } = null!;
        public DbSet<PersonalReference> PersonalReferences { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Cliente>(eb =>
            {
                eb.HasKey(e => e.Id);
                eb.Property(e => e.NombreCompleto).HasMaxLength(200);
            });

            modelBuilder.Entity<PersonalReference>(eb =>
            {
                eb.HasKey(e => e.Id);
                eb.Property(e => e.NombreCompleto).IsRequired().HasMaxLength(200);
                eb.Property(e => e.Telefonos).HasMaxLength(50);
                eb.Property(e => e.LugarTrabajo).HasMaxLength(200);
                eb.Property(e => e.Parentesco).HasMaxLength(100);
                eb.Property(e => e.Direccion).HasMaxLength(300);

                eb.HasOne(pr => pr.Cliente)
                  .WithMany()
                  .HasForeignKey(pr => pr.ClienteId)
                  .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
