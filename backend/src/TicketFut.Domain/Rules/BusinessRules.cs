using System.Security.Cryptography;
using TicketFut.Domain.Enums;

namespace TicketFut.Domain.Rules;

public static class Cpf
{
    public static string Normalize(string? value) => new((value ?? "").Where(char.IsDigit).ToArray());

    public static bool IsValid(string? value)
    {
        var d = Normalize(value);
        if (d.Length != 11 || d.Distinct().Count() == 1) return false;
        return CheckDigit(d, 9) == d[9] - '0' && CheckDigit(d, 10) == d[10] - '0';
    }

    private static int CheckDigit(string d, int len)
    {
        var sum = 0;
        for (var i = 0; i < len; i++) sum += (d[i] - '0') * (len + 1 - i);
        var r = sum * 10 % 11;
        return r == 10 ? 0 : r;
    }
}

public static class Pricing
{
    public static decimal Apply(decimal basePrice, MemberPlan plan) =>
        Math.Round(basePrice * (100 - (int)plan) / 100m, 2, MidpointRounding.AwayFromZero);
}

public static class SectorRules
{
    /// <summary>Visitante só no LESTE; mandante em qualquer setor menos o LESTE (regra do app web).</summary>
    public static bool IsAllowed(Sector sector, bool isAway) =>
        isAway ? sector == Sector.Leste : sector != Sector.Leste;

    public static string? BlockReason(Sector sector, bool isAway)
    {
        if (IsAllowed(sector, isAway)) return null;
        return isAway
            ? "Seu time é o visitante nesta partida. Apenas o setor LESTE está disponível para torcedores visitantes."
            : "O setor LESTE é exclusivo para a torcida visitante.";
    }
}

public static class MemberPlans
{
    // Preços mensais: valores de EXEMPLO. Ajuste conforme a regra comercial.
    public static decimal MonthlyPrice(MemberPlan plan) => plan switch
    {
        MemberPlan.Bronze => 19.90m,
        MemberPlan.Silver => 39.90m,
        MemberPlan.Gold => 69.90m,
        _ => 0m,
    };

    public static string DisplayName(MemberPlan plan) => plan switch
    {
        MemberPlan.Bronze => "Sócio Bronze",
        MemberPlan.Silver => "Sócio Prata",
        MemberPlan.Gold => "Sócio Ouro",
        _ => "Sem plano",
    };

    public static bool TryParse(int percent, out MemberPlan plan)
    {
        plan = (MemberPlan)percent;
        return plan is MemberPlan.Bronze or MemberPlan.Silver or MemberPlan.Gold;
    }
}

public static class MemberCodeGenerator
{
    private const string Letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"; // sem I e O, como no app web
    private const string Digits = "0123456789";

    /// <summary>3 letras + 3 dígitos. Ex.: ABC123</summary>
    public static string Generate()
    {
        var chars = new char[6];
        for (var i = 0; i < 3; i++) chars[i] = Letters[RandomNumberGenerator.GetInt32(Letters.Length)];
        for (var i = 3; i < 6; i++) chars[i] = Digits[RandomNumberGenerator.GetInt32(Digits.Length)];
        return new string(chars);
    }
}
