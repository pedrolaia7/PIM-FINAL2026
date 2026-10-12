using System.Net.Mail;
using TicketFut.Application.Abstractions;
using TicketFut.Application.Common;
using TicketFut.Application.Contracts;
using TicketFut.Domain.Entities;
using TicketFut.Domain.Rules;

namespace TicketFut.Application.Services;

public class AuthService
{
    private readonly IUserRepository _users;
    private readonly IFaceTemplateRepository _faces;
    private readonly IRefreshTokenRepository _refreshTokens;
    private readonly IPasswordHasher _hasher;
    private readonly ITokenService _tokens;
    private readonly IFaceRecognitionClient _faceClient;
    private readonly IEmbeddingProtector _protector;
    private readonly IUnitOfWork _uow;
    private readonly IClock _clock;
    private readonly FacePolicy _policy;

    public AuthService(IUserRepository users, IFaceTemplateRepository faces, IRefreshTokenRepository refreshTokens,
        IPasswordHasher hasher, ITokenService tokens, IFaceRecognitionClient faceClient,
        IEmbeddingProtector protector, IUnitOfWork uow, IClock clock, FacePolicy policy)
    {
        _users = users; _faces = faces; _refreshTokens = refreshTokens; _hasher = hasher; _tokens = tokens;
        _faceClient = faceClient; _protector = protector; _uow = uow; _clock = clock; _policy = policy;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest req, CancellationToken ct)
    {
        var name = (req.Name ?? "").Trim();
        var email = (req.Email ?? "").Trim().ToLowerInvariant();
        var cpf = Cpf.Normalize(req.Cpf);
        var team = Teams.Normalize(req.Team);

        if (name.Length < 3) throw AppException.Validation("invalid_name", "Informe seu nome completo.");
        if (!IsValidEmail(email)) throw AppException.Validation("invalid_email", "E-mail inválido.");
        if (!Cpf.IsValid(cpf)) throw AppException.Validation("invalid_cpf", "CPF inválido.");
        if (!IsStrongPassword(req.Password))
            throw AppException.Validation("weak_password", "A senha deve ter ao menos 8 caracteres, com letras e números.");
        if (!Teams.IsValid(team)) throw AppException.Validation("invalid_team", "Time inválido.");

        if (await _users.GetByEmailAsync(email, ct) is not null)
            throw AppException.Conflict("email_taken", "Este e-mail já está cadastrado. Faça login ou use outros dados.");
        if (await _users.CpfExistsAsync(cpf, ct))
            throw AppException.Conflict("cpf_taken", "Este CPF já está cadastrado. Faça login ou use outros dados.");

        var user = new User { Name = name, Email = email, Cpf = cpf, Team = team, PasswordHash = _hasher.Hash(req.Password) };
        await _users.AddAsync(user, ct);
        var response = await IssueTokensAsync(user, hasFace: false, ct);
        await _uow.SaveChangesAsync(ct);
        return response;
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req, CancellationToken ct)
    {
        var user = await _users.GetByEmailAsync((req.Email ?? "").Trim().ToLowerInvariant(), ct);
        // Mesma mensagem para e-mail inexistente e senha errada (não revela quais e-mails existem)
        if (user is null || !_hasher.Verify(user.PasswordHash, req.Password ?? ""))
            throw AppException.Unauthorized("E-mail ou senha incorretos.");

        var hasFace = await _faces.GetByUserAsync(user.Id, ct) is not null;
        var response = await IssueTokensAsync(user, hasFace, ct);
        await _uow.SaveChangesAsync(ct);
        return response;
    }

    /// <summary>Rotação: o refresh token usado é revogado e um novo par é emitido.</summary>
    public async Task<AuthResponse> RefreshAsync(RefreshRequest req, CancellationToken ct)
    {
        var now = _clock.UtcNow;
        var stored = await _refreshTokens.GetByHashAsync(_tokens.HashRefreshToken(req.RefreshToken ?? ""), ct);
        if (stored is null || !stored.IsActive(now))
            throw AppException.Unauthorized("Sessão expirada. Faça login novamente.");

        var user = await _users.GetByIdAsync(stored.UserId, ct) ?? throw AppException.Unauthorized();
        stored.RevokedAt = now;
        var hasFace = await _faces.GetByUserAsync(user.Id, ct) is not null;
        var response = await IssueTokensAsync(user, hasFace, ct);
        await _uow.SaveChangesAsync(ct);
        return response;
    }

    public async Task LogoutAsync(Guid userId, CancellationToken ct)
    {
        await _refreshTokens.RevokeAllForUserAsync(userId, _clock.UtcNow, ct);
        await _uow.SaveChangesAsync(ct);
    }

    public async Task<UserDto> GetMeAsync(Guid userId, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ?? throw AppException.NotFound("Usuário não encontrado.");
        return Mapping.ToDto(user, await _faces.GetByUserAsync(userId, ct) is not null);
    }

    /// <summary>Cadastro facial: a selfie vai ao microsserviço Python; guardamos só o embedding criptografado.</summary>
    public async Task<UserDto> EnrollFaceAsync(Guid userId, byte[] image, bool consent, CancellationToken ct)
    {
        if (!consent)
            throw AppException.Validation("consent_required", "É necessário autorizar o uso da biometria facial.");
        if (image.Length == 0 || image.Length > _policy.MaxImageBytes)
            throw AppException.Validation("invalid_image", "Imagem inválida ou grande demais.");

        var user = await _users.GetByIdAsync(userId, ct) ?? throw AppException.NotFound("Usuário não encontrado.");
        var result = await _faceClient.EnrollAsync(image, ct);

        await _faces.UpsertAsync(new FaceTemplate
        {
            UserId = userId,
            EncryptedEmbedding = _protector.Protect(result.Embedding),
            ModelVersion = result.ModelVersion,
            ConsentAt = _clock.UtcNow,
        }, ct);
        await _uow.SaveChangesAsync(ct);
        return Mapping.ToDto(user, hasFace: true);
    }

    /// <summary>LGPD: o usuário pode apagar o próprio dado biométrico.</summary>
    public async Task DeleteFaceAsync(Guid userId, CancellationToken ct)
    {
        await _faces.DeleteByUserAsync(userId, ct);
        await _uow.SaveChangesAsync(ct);
    }

    private async Task<AuthResponse> IssueTokensAsync(User user, bool hasFace, CancellationToken ct)
    {
        var access = _tokens.CreateAccessToken(user);
        var (plain, hash, expires) = _tokens.CreateRefreshToken();
        await _refreshTokens.AddAsync(new RefreshToken { UserId = user.Id, TokenHash = hash, ExpiresAt = expires }, ct);
        return new AuthResponse(access.Value, plain, access.ExpiresInSeconds, Mapping.ToDto(user, hasFace));
    }

    private static bool IsValidEmail(string email)
    {
        if (email.Length is < 5 or > 254) return false;
        try { return new MailAddress(email).Address == email; } catch { return false; }
    }

    private static bool IsStrongPassword(string? p) =>
        p is { Length: >= 8 } && p.Any(char.IsLetter) && p.Any(char.IsDigit);
}
