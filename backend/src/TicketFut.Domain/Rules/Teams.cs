using System.Globalization;
using System.Text;

namespace TicketFut.Domain.Rules;

public static class Teams
{
    public const string Default = "default";

    private static readonly Dictionary<string, string> Names = new()
    {
        ["palmeiras"] = "Palmeiras",
        ["corinthians"] = "Corinthians",
        ["flamengo"] = "Flamengo",
        ["sao_paulo"] = "São Paulo",
        ["santos"] = "Santos",
    };

    public static IReadOnlyCollection<string> All => Names.Keys;
    public static bool IsValid(string slug) => Names.ContainsKey(slug);
    public static string DisplayName(string slug) => Names.TryGetValue(slug, out var n) ? n : slug;

    /// <summary>"São Paulo" -> "sao_paulo"</summary>
    public static string Normalize(string? input)
    {
        var decomposed = (input ?? "").Trim().ToLowerInvariant().Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in decomposed)
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c == ' ' ? '_' : c);
        return sb.ToString();
    }
}
