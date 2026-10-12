using TicketFut.Application.Abstractions;
using TicketFut.Application.Common;
using TicketFut.Application.Contracts;
using TicketFut.Domain.Enums;
using TicketFut.Domain.Rules;

namespace TicketFut.Application.Services;

public class MembershipService
{
    private readonly IUserRepository _users;
    private readonly IFaceTemplateRepository _faces;
    private readonly IPaymentGateway _gateway;
    private readonly IUnitOfWork _uow;

    public MembershipService(IUserRepository users, IFaceTemplateRepository faces, IPaymentGateway gateway, IUnitOfWork uow)
    {
        _users = users; _faces = faces; _gateway = gateway; _uow = uow;
    }

    public async Task<SubscribeResponse> SubscribeAsync(Guid userId, SubscribeRequest req, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ?? throw AppException.NotFound("Usuário não encontrado.");
        if (user.Plan != MemberPlan.None)
            throw AppException.Conflict("already_member", $"Você já é sócio. Seu código: {user.MemberCode}");
        if (!MemberPlans.TryParse(req.Plan, out var plan))
            throw AppException.Validation("invalid_plan", "Plano inválido.");
        if (!Enum.TryParse<PaymentMethod>(req.Method, ignoreCase: true, out var method))
            throw AppException.Validation("invalid_method", "Forma de pagamento inválida.");
        if (method != PaymentMethod.Pix && string.IsNullOrWhiteSpace(req.CardToken))
            throw AppException.Validation("card_required", "Informe os dados do cartão.");

        var charge = await _gateway.ChargeAsync(new ChargeRequest(
            MemberPlans.MonthlyPrice(plan), method, req.CardToken, $"plan-{user.Id}", MemberPlans.DisplayName(plan)), ct);
        if (!charge.Approved)
            throw new AppException(402, "payment_declined", charge.DeclineReason ?? "Pagamento recusado.");

        string code;
        var attempts = 0;
        do
        {
            code = MemberCodeGenerator.Generate();
            if (++attempts > 1000) throw new InvalidOperationException("Não foi possível gerar código único.");
        } while (await _users.MemberCodeExistsAsync(code, ct));

        user.Plan = plan;
        user.MemberCode = code;
        await _uow.SaveChangesAsync(ct);

        var hasFace = await _faces.GetByUserAsync(userId, ct) is not null;
        return new SubscribeResponse(Mapping.ToDto(user, hasFace), code, charge.PixPayload);
    }
}
