using System.Security.Cryptography;
using System.Text;
using TicketFut.Application.Abstractions;
using TicketFut.Application.Common;
using TicketFut.Application.Contracts;
using TicketFut.Domain.Entities;
using TicketFut.Domain.Enums;
using TicketFut.Domain.Rules;

namespace TicketFut.Application.Services;

public class PaymentService
{
    private static readonly TimeSpan IntentLifetime = TimeSpan.FromMinutes(10);

    private readonly IUserRepository _users;
    private readonly IMatchRepository _matches;
    private readonly IPaymentRepository _payments;
    private readonly IFaceTemplateRepository _faces;
    private readonly IFaceRecognitionClient _faceClient;
    private readonly IEmbeddingProtector _protector;
    private readonly IPaymentGateway _gateway;
    private readonly IUnitOfWork _uow;
    private readonly IClock _clock;
    private readonly FacePolicy _policy;

    public PaymentService(IUserRepository users, IMatchRepository matches, IPaymentRepository payments,
        IFaceTemplateRepository faces, IFaceRecognitionClient faceClient, IEmbeddingProtector protector,
        IPaymentGateway gateway, IUnitOfWork uow, IClock clock, FacePolicy policy)
    {
        _users = users; _matches = matches; _payments = payments; _faces = faces; _faceClient = faceClient;
        _protector = protector; _gateway = gateway; _uow = uow; _clock = clock; _policy = policy;
    }

    /// <summary>Passo 1 do checkout: valida regras (setor, sócio), calcula o valor e emite o nonce.</summary>
    public async Task<IntentDto> CreateIntentAsync(Guid userId, CreateIntentRequest req, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ?? throw AppException.NotFound("Usuário não encontrado.");
        var match = await _matches.GetAsync(req.MatchId, ct) ?? throw AppException.NotFound("Partida não encontrada.");
        var now = _clock.UtcNow;

        if (match.IsFinished(now) || match.KickoffAt <= now)
            throw AppException.Validation("match_unavailable", "Vendas encerradas para esta partida.");
        if (!Enum.TryParse<Sector>(req.Sector, ignoreCase: true, out var sector) || !Enum.IsDefined(sector))
            throw AppException.Validation("invalid_sector", "Setor inválido.");
        if (!Enum.TryParse<PaymentMethod>(req.Method, ignoreCase: true, out var method) || !Enum.IsDefined(method))
            throw AppException.Validation("invalid_method", "Forma de pagamento inválida.");

        var isAway = user.Team != Teams.Default && match.AwayTeam == user.Team;
        var blocked = SectorRules.BlockReason(sector, isAway);
        if (blocked is not null) throw AppException.Validation("sector_blocked", blocked);

        // Regra do app web: sócio precisa informar o código para ter o desconto.
        if (user.Plan != MemberPlan.None)
        {
            var typed = (req.MemberCode ?? "").Trim();
            if (typed.Length == 0)
                throw AppException.Validation("member_code_required", "Informe seu código de sócio para aplicar o desconto.");
            if (!string.Equals(typed, user.MemberCode, StringComparison.OrdinalIgnoreCase))
                throw AppException.Validation("member_code_invalid", "Código de sócio incorreto. Verifique o código recebido no seu cadastro.");
        }

        var intent = new PaymentIntent
        {
            UserId = userId, MatchId = match.Id, Sector = sector, Method = method,
            OriginalAmount = match.BasePrice, DiscountPercent = (int)user.Plan,
            Amount = Pricing.Apply(match.BasePrice, user.Plan),
            Nonce = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32)),
            ExpiresAt = now + IntentLifetime,
        };
        await _payments.AddIntentAsync(intent, ct);
        await _uow.SaveChangesAsync(ct);
        return new IntentDto(intent.Id, intent.Nonce, intent.Amount, intent.OriginalAmount, intent.DiscountPercent, intent.ExpiresAt, method.ToString());
    }

    /// <summary>
    /// Passo 2: confirma com selfie. O servidor decide — nunca confia em "biometria OK" vinda do app.
    /// </summary>
    public async Task<ConfirmResponse> ConfirmAsync(Guid userId, Guid intentId, string nonce, byte[] selfie, string? cardToken, CancellationToken ct)
    {
        var now = _clock.UtcNow;
        var intent = await _payments.GetIntentAsync(intentId, ct);
        if (intent is null || intent.UserId != userId) throw AppException.NotFound("Intenção de pagamento não encontrada.");
        if (intent.Status != PaymentStatus.Pending)
            throw AppException.Conflict("intent_closed", "Esta compra já foi finalizada ou cancelada.");
        if (intent.ExpiresAt <= now)
        {
            intent.Status = PaymentStatus.Expired;
            await _uow.SaveChangesAsync(ct);
            throw new AppException(410, "intent_expired", "O tempo para confirmar a compra expirou. Inicie novamente.");
        }
        if (!FixedTimeEquals(intent.Nonce, nonce))
            throw AppException.Forbidden("invalid_nonce", "Requisição inválida.");
        if (selfie.Length == 0 || selfie.Length > _policy.MaxImageBytes)
            throw AppException.Validation("invalid_image", "Selfie inválida ou grande demais.");
        if (intent.Method != PaymentMethod.Pix && string.IsNullOrWhiteSpace(cardToken))
            throw AppException.Validation("card_required", "Informe os dados do cartão.");

        var template = await _faces.GetByUserAsync(userId, ct)
            ?? throw AppException.Conflict("face_not_enrolled", "Cadastre seu rosto para confirmar compras.");

        if (intent.FaceAttempts >= _policy.MaxFaceAttemptsPerIntent)
        {
            intent.Status = PaymentStatus.Failed;
            await _uow.SaveChangesAsync(ct);
            throw new AppException(429, "too_many_attempts", "Muitas tentativas de verificação. Inicie a compra novamente.");
        }

        // Conta a tentativa ANTES de verificar, para que abortar a requisição não dê tentativas grátis.
        intent.FaceAttempts++;
        await _uow.SaveChangesAsync(ct);

        var verify = await _faceClient.VerifyAsync(selfie, _protector.Unprotect(template.EncryptedEmbedding), "payment", ct);
        await _payments.AddFaceLogAsync(new FaceVerificationLog
        {
            UserId = userId, PaymentIntentId = intent.Id, Purpose = "payment",
            Similarity = verify.Similarity, IsMatch = verify.IsMatch,
        }, ct);

        if (_policy.RequireLivenessForPayment && !verify.LivenessChecked)
        {
            await _uow.SaveChangesAsync(ct);
            throw new AppException(503, "liveness_unavailable", "Verificação de prova de vida indisponível. Tente mais tarde.");
        }
        if (!verify.IsMatch)
        {
            await _uow.SaveChangesAsync(ct);
            // Não devolvemos a similaridade ao app: não ajuda o usuário legítimo e ajuda um atacante.
            throw AppException.Forbidden("face_mismatch", "Não foi possível confirmar sua identidade. Tente novamente.");
        }

        var charge = await _gateway.ChargeAsync(new ChargeRequest(
            intent.Amount, intent.Method, cardToken, $"intent-{intent.Id}", $"Ingresso partida {intent.MatchId}"), ct);
        if (!charge.Approved)
        {
            await _uow.SaveChangesAsync(ct);
            throw new AppException(402, "payment_declined", charge.DeclineReason ?? "Pagamento recusado.");
        }

        intent.Status = PaymentStatus.Paid;
        intent.PaidAt = now;
        intent.GatewayReference = charge.Reference;
        var ticket = new Ticket
        {
            PaymentIntentId = intent.Id, UserId = userId, MatchId = intent.MatchId, Sector = intent.Sector,
            Amount = intent.Amount, Code = "TF-" + Convert.ToHexString(RandomNumberGenerator.GetBytes(4)),
            IssuedAt = now,
        };
        await _payments.AddTicketAsync(ticket, ct);
        await _uow.SaveChangesAsync(ct);

        ticket.Match = intent.Match;
        return new ConfirmResponse(Mapping.ToDto(ticket), charge.PixPayload);
    }

    public async Task<List<TicketDto>> ListTicketsAsync(Guid userId, CancellationToken ct) =>
        (await _payments.ListTicketsAsync(userId, ct)).Select(Mapping.ToDto).ToList();

    private static bool FixedTimeEquals(string a, string b) =>
        CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(a), Encoding.UTF8.GetBytes(b ?? ""));
}
