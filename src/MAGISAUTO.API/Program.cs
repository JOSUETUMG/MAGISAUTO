using MAGISAUTO.API.Datos;
using MAGISAUTO.API.Infraestructura;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.Configuration
        .AddJsonFile(Path.Combine(builder.Environment.ContentRootPath, "appsettings.Local.json"), optional: true, reloadOnChange: false)
        .AddEnvironmentVariables()
        .AddCommandLine(args);
}

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ErroresApiHandler>();
builder.Services.AddSingleton<ConexionSqlFactory>();
builder.Services.AddScoped<IMarcaRepositorio, MarcaRepositorio>();
builder.Services.AddScoped<ILineaRepositorio, LineaRepositorio>();
builder.Services.AddScoped<IAgenciaRepositorio, AgenciaRepositorio>();
builder.Services.AddScoped<IVendedorRepositorio, VendedorRepositorio>();
builder.Services.AddScoped<ClienteRepositorio>();
builder.Services.AddScoped<FiadorRepositorio>();
builder.Services.AddScoped<VehiculoRepositorio>();
builder.Services.AddScoped<ValoracionRepositorio>();
builder.Services.AddScoped<CreditoRepositorio>();
builder.Services.AddScoped<PagoRepositorio>();
builder.Services.AddScoped<ReporteRepositorio>();
builder.Services.AddScoped<CatalogoAuxiliarRepositorio>();
builder.Services.AddScoped<ParametroCreditoRepositorio>();

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

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapControllers();

app.Run();
