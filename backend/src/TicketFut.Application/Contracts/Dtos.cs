namespace TicketFut.Application.Contracts;

public record RegisterRequest(string Name, string Cpf, string Email, string Password, string Team);
public record LoginRequest(string Email, string Password);
public record RefreshRequest(string RefreshToken);

public record UserDto(Guid Id, string Name, string Email, string Team, int PlanPercent, string PlanName, string? MemberCode, bool HasFace);
public record AuthResponse(string AccessToken, string RefreshToken, int ExpiresInSeconds, UserDto User);

public record SubscribeRequest(int Plan, string Method, string? CardToken);
public record SubscribeResponse(UserDto User, string MemberCode, string? PixPayload);

public record StadiumDto(string Name, string City, double Latitude, double Longitude);
public record MatchDto(
    int Id, string HomeTeam, string AwayTeam, string HomeName, string AwayName,
    DateTime KickoffAt, string Status, decimal BasePrice, decimal Price, int DiscountPercent,
    bool IsAway, StadiumDto Stadium);
public record SectorDto(string Sector, bool Available, string? Reason);

public record CreateIntentRequest(int MatchId, string Sector, string Method, string? MemberCode);
public record IntentDto(Guid IntentId, string Nonce, decimal Amount, decimal OriginalAmount, int DiscountPercent, DateTime ExpiresAt, string Method);

public record TicketDto(Guid Id, int MatchId, string MatchName, string Sector, string Code, decimal Amount, DateTime KickoffAt, DateTime IssuedAt);
public record ConfirmResponse(TicketDto Ticket, string? PixPayload);

public record MatchQuery(string? Team, string? Status, string? Search);
