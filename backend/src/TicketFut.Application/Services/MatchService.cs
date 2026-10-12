using TicketFut.Application.Abstractions;
using TicketFut.Application.Common;
using TicketFut.Application.Contracts;
using TicketFut.Domain.Enums;
using TicketFut.Domain.Rules;

namespace TicketFut.Application.Services;

public class MatchService
{
    private readonly IMatchRepository _matches;
    private readonly IUserRepository _users;
    private readonly IClock _clock;

    public MatchService(IMatchRepository matches, IUserRepository users, IClock clock)
    {
        _matches = matches; _users = users; _clock = clock;
    }

    /// <summary>
    /// team: "mine" (padrão) = só jogos do time do usuário (admin/default vê todos); "all" = todos; ou um slug.
    /// status: "all" | "scheduled" | "finished".
    /// </summary>
    public async Task<List<MatchDto>> ListAsync(Guid userId, MatchQuery q, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ?? throw AppException.NotFound("Usuário não encontrado.");
        var now = _clock.UtcNow;
        IEnumerable<Domain.Entities.Match> list = await _matches.ListAsync(ct);

        var team = (q.Team ?? "mine").Trim().ToLowerInvariant();
        if (team == "mine") team = user.Team == Teams.Default ? "all" : user.Team;
        if (team != "all") list = list.Where(m => m.InvolvesTeam(team));

        var status = (q.Status ?? "all").Trim().ToLowerInvariant();
        if (status == "scheduled") list = list.Where(m => !m.IsFinished(now));
        else if (status == "finished") list = list.Where(m => m.IsFinished(now));

        if (!string.IsNullOrWhiteSpace(q.Search))
        {
            var s = Teams.Normalize(q.Search).Replace('_', ' ');
            list = list.Where(m => Teams.Normalize(Teams.DisplayName(m.HomeTeam)).Replace('_', ' ').Contains(s)
                                || Teams.Normalize(Teams.DisplayName(m.AwayTeam)).Replace('_', ' ').Contains(s)
                                || Teams.Normalize(m.Stadium.Name).Replace('_', ' ').Contains(s));
        }

        return list.OrderBy(m => m.KickoffAt).Select(m => Mapping.ToDto(m, user, now)).ToList();
    }

    public async Task<MatchDto> GetAsync(Guid userId, int id, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ?? throw AppException.NotFound("Usuário não encontrado.");
        var match = await _matches.GetAsync(id, ct) ?? throw AppException.NotFound("Partida não encontrada.");
        return Mapping.ToDto(match, user, _clock.UtcNow);
    }

    public async Task<List<SectorDto>> SectorsAsync(Guid userId, int matchId, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ?? throw AppException.NotFound("Usuário não encontrado.");
        var match = await _matches.GetAsync(matchId, ct) ?? throw AppException.NotFound("Partida não encontrada.");
        var isAway = user.Team != Teams.Default && match.AwayTeam == user.Team;
        return Enum.GetValues<Sector>()
            .Select(s => new SectorDto(s.ToString(), SectorRules.IsAllowed(s, isAway), SectorRules.BlockReason(s, isAway)))
            .ToList();
    }
}
