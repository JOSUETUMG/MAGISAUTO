using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddProblemDetails();

// Registrar ApplicationDbContext usando InMemory para desarrollo/pruebas
builder.Services.AddDbContext<MAGISAUTO.API.Data.ApplicationDbContext>(options =>
    options.UseInMemoryDatabase("MAGISAUTO_Db"));

// Registrar servicios
builder.Services.AddScoped<MAGISAUTO.API.Services.IPersonalReferenceService, MAGISAUTO.API.Services.PersonalReferenceService>();
builder.Services.AddScoped<MAGISAUTO.API.Repositories.IPersonalReferenceRepository, MAGISAUTO.API.Repositories.PersonalReferenceRepository>();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
else
{
    app.UseHttpsRedirection();
}

app.UseAuthorization();

// Habilitar archivos estáticos (wwwroot)
app.UseDefaultFiles();
app.UseStaticFiles();

app.MapControllers();

// Servir la página principal estática
app.MapGet("/", () => Results.Redirect("/index.html"))
    .ExcludeFromDescription();

// Seed mínimo para pruebas (rehabilitado)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<MAGISAUTO.API.Data.ApplicationDbContext>();
    if (!db.Clientes.Any())
    {
        db.Clientes.Add(new MAGISAUTO.API.Models.Cliente { NombreCompleto = "Cliente Prueba" });
        db.SaveChanges();
    }
}

app.Run();
