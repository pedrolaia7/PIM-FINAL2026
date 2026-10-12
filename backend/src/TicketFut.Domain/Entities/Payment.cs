using TicketFut.Domain.Enums;

namespace TicketFut.Domain.Entities;

public class PaymentIntent
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int MatchId { get; set; }
    public Sector Sector { get; set; }
    public PaymentMethod Method { get; set; }
    public decimal OriginalAmount { get; set; }
    public int DiscountPercent { get; set; }
    public decimal Amount { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    /// <summary>Segredo entregue ao app ao criar a intenção e exigido na confirmação.</summary>
    public string Nonce { get; set; } = "";
    public DateTime ExpiresAt { get; set; }
    public int FaceAttempts { get; set; }
    public string? GatewayReference { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PaidAt { get; set; }
    public Match Match { get; set; } = null!;
}

public class Ticket
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PaymentIntentId { get; set; }
    public Guid UserId { get; set; }
    public int MatchId { get; set; }
    public Sector Sector { get; set; }
    public string Code { get; set; } = "";
    public decimal Amount { get; set; }
    public DateTime IssuedAt { get; set; } = DateTime.UtcNow;
    public Match Match { get; set; } = null!;
}

/// <summary>Trilha de auditoria das verificações faciais (sem imagens).</summary>
public class FaceVerificationLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid? PaymentIntentId { get; set; }
    public string Purpose { get; set; } = "";
    public double Similarity { get; set; }
    public bool IsMatch { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
