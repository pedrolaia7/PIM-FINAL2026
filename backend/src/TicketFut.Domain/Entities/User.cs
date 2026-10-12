using TicketFut.Domain.Enums;

namespace TicketFut.Domain.Entities;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = "";
    public string Cpf { get; set; } = "";              // somente dígitos
    public string Email { get; set; } = "";            // minúsculo
    public string PasswordHash { get; set; } = "";
    public string Team { get; set; } = Rules.Teams.Default;   // slug: palmeiras, sao_paulo...
    public MemberPlan Plan { get; set; } = MemberPlan.None;
    public string? MemberCode { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public FaceTemplate? FaceTemplate { get; set; }
}

public class FaceTemplate
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    /// <summary>Embedding criptografado (AES-GCM). Nunca armazenamos a foto.</summary>
    public byte[] EncryptedEmbedding { get; set; } = Array.Empty<byte>();
    public string ModelVersion { get; set; } = "";
    public DateTime ConsentAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class RefreshToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = "";
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive(DateTime now) => RevokedAt is null && ExpiresAt > now;
}
