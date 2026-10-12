namespace TicketFut.Application.Common;

/// <summary>Erro de negócio com código estável (o app Flutter reage ao Code) e status HTTP.</summary>
public class AppException : Exception
{
    public string Code { get; }
    public int Status { get; }

    public AppException(int status, string code, string message) : base(message)
    {
        Status = status;
        Code = code;
    }

    public static AppException Validation(string code, string message) => new(422, code, message);
    public static AppException NotFound(string message) => new(404, "not_found", message);
    public static AppException Conflict(string code, string message) => new(409, code, message);
    public static AppException Unauthorized(string message = "Credenciais inválidas.") => new(401, "unauthorized", message);
    public static AppException Forbidden(string code, string message) => new(403, code, message);
}
