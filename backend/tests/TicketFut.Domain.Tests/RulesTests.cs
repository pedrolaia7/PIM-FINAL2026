using TicketFut.Domain.Enums;
using TicketFut.Domain.Rules;
using Xunit;

namespace TicketFut.Domain.Tests;

public class RulesTests
{
    [Theory]
    [InlineData("529.982.247-25", true)]
    [InlineData("52998224725", true)]
    [InlineData("111.111.111-11", false)]
    [InlineData("529.982.247-24", false)]
    [InlineData("123", false)]
    [InlineData("", false)]
    public void Cpf_validation(string cpf, bool expected) => Assert.Equal(expected, Cpf.IsValid(cpf));

    [Theory]
    [InlineData(180, MemberPlan.None, 180.00)]
    [InlineData(180, MemberPlan.Bronze, 171.00)]
    [InlineData(150, MemberPlan.Silver, 135.00)]
    [InlineData(200, MemberPlan.Gold, 160.00)]
    public void Pricing_applies_member_discount(decimal basePrice, MemberPlan plan, decimal expected) =>
        Assert.Equal(expected, Pricing.Apply(basePrice, plan));

    [Theory]
    [InlineData(Sector.Norte, false, true)]
    [InlineData(Sector.Leste, false, false)]   // mandante não entra no Leste
    [InlineData(Sector.Leste, true, true)]     // visitante só no Leste
    [InlineData(Sector.Sul, true, false)]
    public void Sector_rules(Sector sector, bool isAway, bool allowed)
    {
        Assert.Equal(allowed, SectorRules.IsAllowed(sector, isAway));
        Assert.Equal(allowed, SectorRules.BlockReason(sector, isAway) is null);
    }

    [Theory]
    [InlineData("São Paulo", "sao_paulo")]
    [InlineData("  Palmeiras ", "palmeiras")]
    [InlineData("CORINTHIANS", "corinthians")]
    public void Team_normalization(string input, string expected) => Assert.Equal(expected, Teams.Normalize(input));

    [Fact]
    public void MemberCode_has_three_letters_and_three_digits()
    {
        for (var i = 0; i < 200; i++)
        {
            var c = MemberCodeGenerator.Generate();
            Assert.Equal(6, c.Length);
            Assert.True(c[..3].All(char.IsUpper));
            Assert.True(c[3..].All(char.IsDigit));
            Assert.DoesNotContain('I', c);
            Assert.DoesNotContain('O', c);
        }
    }
}
