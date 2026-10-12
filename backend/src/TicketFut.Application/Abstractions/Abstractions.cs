using TicketFut.Domain.Entities;
using TicketFut.Domain.Enums;

namespace TicketFut.Application.Abstractions;

public interface IUnitOfWork { Task SaveChangesAsync(CancellationToken ct = default); }

public interface IClock { DateTime UtcNow { get; } }

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task<bool> CpfExistsAsync(string cpf, CancellationToken ct = default);
    Task<bool> MemberCodeExistsAsync(string code, CancellationToken ct = default);
    Task AddAsync(User user, CancellationToken ct = default);
}

public interface IFaceTemplateRepository
{
    Task<FaceTemplate?> GetByUserAsync(Guid userId, CancellationToken ct = default);
    Task UpsertAsync(FaceTemplate template, CancellationToken ct = default);
    Task DeleteByUserAsync(Guid userId, CancellationToken ct = default);
}

public interface IRefreshTokenRepository
{
    Task AddAsync(RefreshToken token, CancellationToken ct = default);
    Task<RefreshToken?> GetByHashAsync(string hash, CancellationToken ct = default);
    Task RevokeAllForUserAsync(Guid userId, DateTime now, CancellationToken ct = default);
}

public interface IMatchRepository
{
    Task<List<Match>> ListAsync(CancellationToken ct = default);
    Task<Match?> GetAsync(int id, CancellationToken ct = default);
}

public interface IPaymentRepository
{
    Task AddIntentAsync(PaymentIntent intent, CancellationToken ct = default);
    Task<PaymentIntent?> GetIntentAsync(Guid id, CancellationToken ct = default);
    Task AddTicketAsync(Ticket ticket, CancellationToken ct = default);
    Task<List<Ticket>> ListTicketsAsync(Guid userId, CancellationToken ct = default);
    Task AddFaceLogAsync(FaceVerificationLog log, CancellationToken ct = default);
}

public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string hash, string password);
}

public record AccessToken(string Value, int ExpiresInSeconds);

public interface ITokenService
{
    AccessToken CreateAccessToken(User user);
    /// <summary>Token opaco aleatório; só o hash SHA-256 é persistido.</summary>
    (string Plain, string Hash, DateTime ExpiresAt) CreateRefreshToken();
    string HashRefreshToken(string plain);
}

public interface IEmbeddingProtector
{
    byte[] Protect(float[] embedding);
    float[] Unprotect(byte[] protectedData);
}

public record FaceEnrollResult(float[] Embedding, string ModelVersion);
public record FaceVerifyResult(
    double Similarity, bool IsMatch, double Threshold,
    bool LivenessChecked, bool? LivenessPassed, string ModelVersion);

public interface IFaceRecognitionClient
{
    Task<FaceEnrollResult> EnrollAsync(byte[] image, CancellationToken ct = default);
    Task<FaceVerifyResult> VerifyAsync(byte[] image, float[] storedEmbedding, string purpose, CancellationToken ct = default);
}

public record ChargeRequest(decimal Amount, PaymentMethod Method, string? CardToken, string Reference, string Description);
public record ChargeResult(bool Approved, string Reference, string? PixPayload, string? DeclineReason);

/// <summary>Dados de cartão NUNCA chegam ao backend: só um token gerado pelo SDK do gateway.</summary>
public interface IPaymentGateway { Task<ChargeResult> ChargeAsync(ChargeRequest request, CancellationToken ct = default); }

public class FacePolicy
{
    public bool RequireLivenessForPayment { get; set; }
    public int MaxFaceAttemptsPerIntent { get; set; } = 5;
    public int MaxImageBytes { get; set; } = 5 * 1024 * 1024;
}
