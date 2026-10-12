using TicketFut.Application.Abstractions;
using TicketFut.Domain.Enums;

namespace TicketFut.Infrastructure.Services;

/// <summary>
/// Gateway de SANDBOX para desenvolvimento. Aprova tudo, exceto cartões cujo token contém "_0000_"
/// (simula recusa). Substitua por Mercado Pago / Stripe / Pagar.me em produção.
/// </summary>
public class SandboxPaymentGateway : IPaymentGateway
{
    public Task<ChargeResult> ChargeAsync(ChargeRequest r, CancellationToken ct = default)
    {
        var reference = "sbx_" + Guid.NewGuid().ToString("N")[..16];

        if (r.Method == PaymentMethod.Pix)
            return Task.FromResult(new ChargeResult(true, reference, $"00020126SANDBOX{reference}", null));

        if (string.IsNullOrWhiteSpace(r.CardToken) || !r.CardToken.StartsWith("tok_sandbox_"))
            return Task.FromResult(new ChargeResult(false, reference, null, "Token de cartão inválido."));
        if (r.CardToken.Contains("_0000_"))
            return Task.FromResult(new ChargeResult(false, reference, null, "Cartão recusado pelo emissor."));

        return Task.FromResult(new ChargeResult(true, reference, null, null));
    }
}
