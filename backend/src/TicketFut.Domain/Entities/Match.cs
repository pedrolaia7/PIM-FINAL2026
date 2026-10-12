namespace TicketFut.Domain.Entities;

public class Stadium
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string City { get; set; } = "";
    public string TeamSlug { get; set; } = "";
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class Match
{
    public int Id { get; set; }
    public string HomeTeam { get; set; } = "";   // mandante (times[0] no app web)
    public string AwayTeam { get; set; } = "";   // visitante (times[1])
    public decimal BasePrice { get; set; }
    public DateTime KickoffAt { get; set; }      // UTC
    public int StadiumId { get; set; }
    public Stadium Stadium { get; set; } = null!;

    public bool IsFinished(DateTime utcNow) => KickoffAt.AddHours(2) <= utcNow;
    public bool InvolvesTeam(string slug) => HomeTeam == slug || AwayTeam == slug;
}
