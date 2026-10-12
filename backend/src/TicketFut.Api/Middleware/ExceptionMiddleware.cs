using TicketFut.Application.Common;

namespace TicketFut.Api.Middleware;

/// <summary>Converte AppException em JSON {code, message}; qualquer outro erro vira 500 genérico (sem vazar detalhes).</summary>
public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _log;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> log) { _next = next; _log = log; }

    public async Task InvokeAsync(HttpContext ctx)
    {
        try
        {
            await _next(ctx);
        }
        catch (AppException ex)
        {
            ctx.Response.StatusCode = ex.Status;
            await ctx.Response.WriteAsJsonAsync(new { code = ex.Code, message = ex.Message });
        }
        catch (OperationCanceledException) when (ctx.RequestAborted.IsCancellationRequested)
        {
            // cliente desistiu; nada a responder
        }
        catch (Exception ex)
        {
            _log.LogError(ex, "Erro não tratado em {Path}", ctx.Request.Path);
            ctx.Response.StatusCode = 500;
            await ctx.Response.WriteAsJsonAsync(new { code = "internal_error", message = "Erro interno. Tente novamente." });
        }
    }
}
