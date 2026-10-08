using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MAGISAUTO.API.Models
{
    public class PersonalReference
    {
        [Key]
        public int Id { get; set; }

        // Foreign key to Cliente
        [Required]
        public int ClienteId { get; set; }

        [ForeignKey(nameof(ClienteId))]
        public Cliente? Cliente { get; set; }

        [Required]
        [MaxLength(200)]
        public string NombreCompleto { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? Telefonos { get; set; }

        [MaxLength(200)]
        public string? LugarTrabajo { get; set; }

        [MaxLength(100)]
        public string? Parentesco { get; set; }

        [MaxLength(300)]
        public string? Direccion { get; set; }
    }
}
