using Microsoft.EntityFrameworkCore;
using TicketFut.Domain.Entities;

namespace TicketFut.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<FaceTemplate> FaceTemplates => Set<FaceTemplate>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Stadium> Stadiums => Set<Stadium>();
    public DbSet<Match> Matches => Set<Match>();
    public DbSet<PaymentIntent> PaymentIntents => Set<PaymentIntent>();
    public DbSet<Ticket> Tickets => Set<Ticket>();
    public DbSet<FaceVerificationLog> FaceVerificationLogs => Set<FaceVerificationLog>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<User>(e =>
        {
            e.ToTable("Users");
            e.Property(x => x.Name).HasMaxLength(120).IsRequired();
            e.Property(x => x.Cpf).HasMaxLength(11).IsRequired();
            e.Property(x => x.Email).HasMaxLength(254).IsRequired();
            e.Property(x => x.PasswordHash).HasMaxLength(512).IsRequired();
            e.Property(x => x.Team).HasMaxLength(30).IsRequired();
            e.Property(x => x.MemberCode).HasMaxLength(6);
            e.Property(x => x.Plan).HasConversion<int>();
            e.HasIndex(x => x.Email).IsUnique();
            e.HasIndex(x => x.Cpf).IsUnique();
            e.HasIndex(x => x.MemberCode).IsUnique().HasFilter("[MemberCode] IS NOT NULL");
            e.HasOne(x => x.FaceTemplate).WithOne().HasForeignKey<FaceTemplate>(f => f.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        b.Entity<FaceTemplate>(e =>
        {
            e.ToTable("FaceTemplates");
            e.HasIndex(x => x.UserId).IsUnique();
            e.Property(x => x.ModelVersion).HasMaxLength(60);
        });

        b.Entity<RefreshToken>(e =>
        {
            e.ToTable("RefreshTokens");
            e.Property(x => x.TokenHash).HasMaxLength(64).IsRequired();
            e.HasIndex(x => x.TokenHash).IsUnique();
            e.HasIndex(x => x.UserId);
        });

        b.Entity<Stadium>(e =>
        {
            e.ToTable("Stadiums");
            e.Property(x => x.Name).HasMaxLength(100).IsRequired();
            e.Property(x => x.City).HasMaxLength(60).IsRequired();
            e.Property(x => x.TeamSlug).HasMaxLength(30).IsRequired();
        });

        b.Entity<Match>(e =>
        {
            e.ToTable("Matches");
            e.Property(x => x.HomeTeam).HasMaxLength(30).IsRequired();
            e.Property(x => x.AwayTeam).HasMaxLength(30).IsRequired();
            e.Property(x => x.BasePrice).HasPrecision(18, 2);
            e.HasOne(x => x.Stadium).WithMany().HasForeignKey(x => x.StadiumId).OnDelete(DeleteBehavior.Restrict);
        });

        b.Entity<PaymentIntent>(e =>
        {
            e.ToTable("PaymentIntents");
            e.Property(x => x.Amount).HasPrecision(18, 2);
            e.Property(x => x.OriginalAmount).HasPrecision(18, 2);
            e.Property(x => x.Nonce).HasMaxLength(64).IsRequired();
            e.Property(x => x.GatewayReference).HasMaxLength(100);
            e.Property(x => x.Sector).HasConversion<string>().HasMaxLength(10);
            e.Property(x => x.Method).HasConversion<string>().HasMaxLength(10);
            e.Property(x => x.Status).HasConversion<string>().HasMaxLength(10);
            e.HasOne(x => x.Match).WithMany().HasForeignKey(x => x.MatchId).OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => x.UserId);
        });

        b.Entity<Ticket>(e =>
        {
            e.ToTable("Tickets");
            e.Property(x => x.Amount).HasPrecision(18, 2);
            e.Property(x => x.Code).HasMaxLength(20).IsRequired();
            e.Property(x => x.Sector).HasConversion<string>().HasMaxLength(10);
            e.HasIndex(x => x.Code).IsUnique();
            e.HasIndex(x => x.PaymentIntentId).IsUnique();   // 1 ingresso por pagamento (idempotência)
            e.HasIndex(x => x.UserId);
            e.HasOne(x => x.Match).WithMany().HasForeignKey(x => x.MatchId).OnDelete(DeleteBehavior.Restrict);
        });

        b.Entity<FaceVerificationLog>(e =>
        {
            e.ToTable("FaceVerificationLogs");
            e.Property(x => x.Purpose).HasMaxLength(20);
            e.HasIndex(x => x.UserId);
        });
    }
}
