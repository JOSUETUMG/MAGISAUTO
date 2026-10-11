using MAGISAUTO.API.Datos;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace MAGISAUTO.API.Infraestructura;

public sealed partial class ErroresApiHandler(
    IProblemDetailsService problems,
    ILogger<ErroresApiHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext context, Exception exception, CancellationToken cancellationToken)
    {
        if (exception is OperationCanceledException && context.RequestAborted.IsCancellationRequested)
        {
            return false;
        }

        if (exception is OperacionCatalogoException operacion)
        {
            context.Response.StatusCode = operacion.Estado;
            await problems.WriteAsync(new ProblemDetailsContext
            {
                HttpContext = context,
                ProblemDetails = new ProblemDetails
                {
                    Status = operacion.Estado,
                    Title = "No se pudo completar la operación",
                    Detail = operacion.Message,
                    Instance = context.Request.Path
                }
            });
            return true;
        }

        var conexion = exception is SqlException or ConfiguracionBaseDatosException;
        var status = conexion ? StatusCodes.Status503ServiceUnavailable : StatusCodes.Status500InternalServerError;
        if (exception is SqlException sql)
        {
            ErrorSql(logger, sql.Number);
        }
        else if (exception is ConfiguracionBaseDatosException configuracion)
        {
            ConfiguracionIncompleta(logger, configuracion.Motivo);
        }
        else
        {
            ErrorInesperado(logger, context.TraceIdentifier, exception);
        }

        context.Response.StatusCode = status;
        var problem = new ProblemDetails
        {
            Status = status,
            Title = conexion ? "Base de datos no disponible" : "No se pudo completar la solicitud",
            Detail = conexion
                ? "No fue posible consultar la base de datos. Revisa la conexión y los permisos de la aplicación."
                : "Ocurrió un error inesperado. Comunica el identificador de esta solicitud.",
            Instance = context.Request.Path
        };
        problem.Extensions["traceId"] = context.TraceIdentifier;
        await problems.WriteAsync(new ProblemDetailsContext { HttpContext = context, ProblemDetails = problem });
        return true;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Falló una operación SQL. Código del proveedor: {Codigo}.")]
    private static partial void ErrorSql(ILogger logger, int codigo);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Configuración de conexión {Motivo}.")]
    private static partial void ConfiguracionIncompleta(ILogger logger, string motivo);

    [LoggerMessage(Level = LogLevel.Error, Message = "Error inesperado en la solicitud {TraceId}.")]
    private static partial void ErrorInesperado(ILogger logger, string traceId, Exception exception);
}
