using TicketFut.Application.Contracts;
using TicketFut.Domain.Entities;
using TicketFut.Domain.Rules;

namespace TicketFut.Application.Services;

internal static class Mapping
{
    public static UserDto ToDto(User u, bool hasFace) => new(
        u.Id, u.Name, u.Email, u.Team, (int)u.Plan, MemberPlans.DisplayName(u.Plan), u.MemberCode, hasFace);

    public static MatchDto ToDto(Match m, User user, DateTime utcNow)
    {
        var discount = (int)user.Plan;
        var isAway = user.Team != Teams.Default && m.AwayTeam == user.Team;
        return new MatchDto(
            m.Id, m.HomeTeam, m.AwayTeam, Teams.DisplayName(m.HomeTeam), Teams.DisplayName(m.AwayTeam),
            DateTime.SpecifyKind(m.KickoffAt, DateTimeKind.Utc),
            m.IsFinished(utcNow) ? "finished" : "scheduled",
            m.BasePrice, Pricing.Apply(m.BasePrice, user.Plan), discount, isAway,
            new StadiumDto(m.Stadium.Name, m.Stadium.City, m.Stadium.Latitude, m.Stadium.Longitude));
    }

    public static TicketDto ToDto(Ticket t) => new(
        t.Id, t.MatchId, $"{Teams.DisplayName(t.Match.HomeTeam)} vs {Teams.DisplayName(t.Match.AwayTeam)}",
        t.Sector.ToString(), t.Code, t.Amount,
        DateTime.SpecifyKind(t.Match.KickoffAt, DateTimeKind.Utc), DateTime.SpecifyKind(t.IssuedAt, DateTimeKind.Utc));
}
