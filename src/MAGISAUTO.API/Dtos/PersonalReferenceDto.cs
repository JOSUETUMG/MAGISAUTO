namespace MAGISAUTO.API.Dtos
{
    public class PersonalReferenceDto
    {
        public int? Id { get; set; }
        public int ClienteId { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string? Telefonos { get; set; }
        public string? LugarTrabajo { get; set; }
        public string? Parentesco { get; set; }
        public string? Direccion { get; set; }
    }
}
