using Microsoft.EntityFrameworkCore;
using TicketFut.Application.Abstractions;
using TicketFut.Domain.Entities;

namespace TicketFut.Infrastructure.Persistence;

public static class DbSeeder
{
    public static async Task SeedAsync(AppDbContext db, Application.Abstractions.IPasswordHasher hasher, bool seedDevAdmin)
    {
        if (!await db.Stadiums.AnyAsync())
        {
            db.Stadiums.AddRange(
                new Stadium { Name = "Allianz Parque", City = "São Paulo", TeamSlug = "palmeiras", Latitude = -23.5275, Longitude = -46.6786 },
                new Stadium { Name = "Maracanã", City = "Rio de Janeiro", TeamSlug = "flamengo", Latitude = -22.9122, Longitude = -43.2302 },
                new Stadium { Name = "Neo Química Arena", City = "São Paulo", TeamSlug = "corinthians", Latitude = -23.5455, Longitude = -46.4742 },
                new Stadium { Name = "Morumbis", City = "São Paulo", TeamSlug = "sao_paulo", Latitude = -23.6001, Longitude = -46.7222 },
                new Stadium { Name = "Vila Belmiro", City = "Santos", TeamSlug = "santos", Latitude = -23.9511, Longitude = -46.3402 });
            await db.SaveChangesAsync();
        }

        if (!await db.Matches.AnyAsync())
        {
            var s = await db.Stadiums.ToDictionaryAsync(x => x.TeamSlug, x => x.Id);

            // Mesmas partidas, preços e horários do app web. As datas originais (maio/2026) já passaram,
            // então reaproveitamos o espaçamento a partir do próximo domingo. Horários em Brasília (UTC-3).
            var today = DateTime.UtcNow.Date;
            var daysToSunday = (7 - (int)today.DayOfWeek) % 7;
            var nextSunday = today.AddDays(daysToSunday == 0 ? 7 : daysToSunday);
            DateTime At(int dayOffset, int hour, int minute) => nextSunday.AddDays(dayOffset).AddHours(hour + 3).AddMinutes(minute);

            db.Matches.AddRange(
                new Match { HomeTeam = "palmeiras", AwayTeam = "flamengo", BasePrice = 180, KickoffAt = At(0, 16, 0), StadiumId = s["palmeiras"] },
                new Match { HomeTeam = "corinthians", AwayTeam = "sao_paulo", BasePrice = 150, KickoffAt = At(1, 18, 30), StadiumId = s["corinthians"] },
                new Match { HomeTeam = "flamengo", AwayTeam = "corinthians", BasePrice = 200, KickoffAt = At(7, 20, 0), StadiumId = s["flamengo"] },
                new Match { HomeTeam = "palmeiras", AwayTeam = "corinthians", BasePrice = 160, KickoffAt = At(8, 16, 0), StadiumId = s["palmeiras"] },
                new Match { HomeTeam = "sao_paulo", AwayTeam = "flamengo", BasePrice = 170, KickoffAt = At(14, 19, 0), StadiumId = s["sao_paulo"] },
                new Match { HomeTeam = "santos", AwayTeam = "palmeiras", BasePrice = 140, KickoffAt = At(15, 11, 0), StadiumId = s["santos"] });
            await db.SaveChangesAsync();
        }

        if (seedDevAdmin && !await db.Users.AnyAsync(u => u.Email == "admin@ticketfut.com"))
        {
            db.Users.Add(new User
            {
                Name = "Admin", Email = "admin@ticketfut.com", Cpf = "52998224725", Team = Domain.Rules.Teams.Default,
                PasswordHash = hasher.Hash("Admin@1234"),
            });
            await db.SaveChangesAsync();
        }
    }
}
