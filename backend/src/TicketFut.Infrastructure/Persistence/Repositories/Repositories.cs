using Microsoft.EntityFrameworkCore;
using TicketFut.Application.Abstractions;
using TicketFut.Domain.Entities;

namespace TicketFut.Infrastructure.Persistence.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _db;
    public UnitOfWork(AppDbContext db) => _db = db;
    public Task SaveChangesAsync(CancellationToken ct = default) => _db.SaveChangesAsync(ct);
}

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _db;
    public UserRepository(AppDbContext db) => _db = db;

    public Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _db.Users.FirstOrDefaultAsync(u => u.Id == id, ct);

    public Task<User?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        _db.Users.FirstOrDefaultAsync(u => u.Email == email, ct);

    public Task<bool> CpfExistsAsync(string cpf, CancellationToken ct = default) =>
        _db.Users.AnyAsync(u => u.Cpf == cpf, ct);

    public Task<bool> MemberCodeExistsAsync(string code, CancellationToken ct = default) =>
        _db.Users.AnyAsync(u => u.MemberCode == code, ct);

    public async Task AddAsync(User user, CancellationToken ct = default) => await _db.Users.AddAsync(user, ct);
}

public class FaceTemplateRepository : IFaceTemplateRepository
{
    private readonly AppDbContext _db;
    public FaceTemplateRepository(AppDbContext db) => _db = db;

    public Task<FaceTemplate?> GetByUserAsync(Guid userId, CancellationToken ct = default) =>
        _db.FaceTemplates.FirstOrDefaultAsync(f => f.UserId == userId, ct);

    public async Task UpsertAsync(FaceTemplate template, CancellationToken ct = default)
    {
        var existing = await GetByUserAsync(template.UserId, ct);
        if (existing is null) { await _db.FaceTemplates.AddAsync(template, ct); return; }
        existing.EncryptedEmbedding = template.EncryptedEmbedding;
        existing.ModelVersion = template.ModelVersion;
        existing.ConsentAt = template.ConsentAt;
        existing.CreatedAt = DateTime.UtcNow;
    }

    public async Task DeleteByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var existing = await GetByUserAsync(userId, ct);
        if (existing is not null) _db.FaceTemplates.Remove(existing);
    }
}

public class RefreshTokenRepository : IRefreshTokenRepository
{
    private readonly AppDbContext _db;
    public RefreshTokenRepository(AppDbContext db) => _db = db;

    public async Task AddAsync(RefreshToken token, CancellationToken ct = default) =>
        await _db.RefreshTokens.AddAsync(token, ct);

    public Task<RefreshToken?> GetByHashAsync(string hash, CancellationToken ct = default) =>
        _db.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == hash, ct);

    public async Task RevokeAllForUserAsync(Guid userId, DateTime now, CancellationToken ct = default)
    {
        var active = await _db.RefreshTokens.Where(t => t.UserId == userId && t.RevokedAt == null).ToListAsync(ct);
        foreach (var t in active) t.RevokedAt = now;
    }
}

public class MatchRepository : IMatchRepository
{
    private readonly AppDbContext _db;
    public MatchRepository(AppDbContext db) => _db = db;

    public Task<List<Match>> ListAsync(CancellationToken ct = default) =>
        _db.Matches.AsNoTracking().Include(m => m.Stadium).OrderBy(m => m.KickoffAt).ToListAsync(ct);

    public Task<Match?> GetAsync(int id, CancellationToken ct = default) =>
        _db.Matches.AsNoTracking().Include(m => m.Stadium).FirstOrDefaultAsync(m => m.Id == id, ct);
}

public class PaymentRepository : IPaymentRepository
{
    private readonly AppDbContext _db;
    public PaymentRepository(AppDbContext db) => _db = db;

    public async Task AddIntentAsync(PaymentIntent intent, CancellationToken ct = default) =>
        await _db.PaymentIntents.AddAsync(intent, ct);

    public Task<PaymentIntent?> GetIntentAsync(Guid id, CancellationToken ct = default) =>
        _db.PaymentIntents.Include(i => i.Match).FirstOrDefaultAsync(i => i.Id == id, ct);

    public async Task AddTicketAsync(Ticket ticket, CancellationToken ct = default) =>
        await _db.Tickets.AddAsync(ticket, ct);

    public Task<List<Ticket>> ListTicketsAsync(Guid userId, CancellationToken ct = default) =>
        _db.Tickets.AsNoTracking().Include(t => t.Match).Where(t => t.UserId == userId)
            .OrderByDescending(t => t.IssuedAt).ToListAsync(ct);

    public async Task AddFaceLogAsync(FaceVerificationLog log, CancellationToken ct = default) =>
        await _db.FaceVerificationLogs.AddAsync(log, ct);
}
