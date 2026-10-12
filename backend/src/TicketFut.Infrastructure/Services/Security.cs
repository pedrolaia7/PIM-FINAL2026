using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using TicketFut.Application.Abstractions;
using TicketFut.Domain.Entities;

namespace TicketFut.Infrastructure.Services;

public class SystemClock : IClock { public DateTime UtcNow => DateTime.UtcNow; }

public class AspNetPasswordHasher : Application.Abstractions.IPasswordHasher
{
    private readonly PasswordHasher<object> _inner = new();
    public string Hash(string password) => _inner.HashPassword(new object(), password);
    public bool Verify(string hash, string password) =>
        _inner.VerifyHashedPassword(new object(), hash, password) != PasswordVerificationResult.Failed;
}

public class JwtOptions
{
    public string Issuer { get; set; } = "ticketfut";
    public string Audience { get; set; } = "ticketfut-app";
    public string Key { get; set; } = "";
    public int AccessMinutes { get; set; } = 15;
    public int RefreshDays { get; set; } = 30;
}

public class TokenService : ITokenService
{
    private readonly JwtOptions _opt;
    private readonly IClock _clock;
    public TokenService(IOptions<JwtOptions> opt, IClock clock) { _opt = opt.Value; _clock = clock; }

    public AccessToken CreateAccessToken(User user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_opt.Key));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var now = _clock.UtcNow;
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };
        var token = new JwtSecurityToken(_opt.Issuer, _opt.Audience, claims,
            notBefore: now, expires: now.AddMinutes(_opt.AccessMinutes), signingCredentials: creds);
        return new AccessToken(new JwtSecurityTokenHandler().WriteToken(token), _opt.AccessMinutes * 60);
    }

    public (string Plain, string Hash, DateTime ExpiresAt) CreateRefreshToken()
    {
        var plain = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        return (plain, HashRefreshToken(plain), _clock.UtcNow.AddDays(_opt.RefreshDays));
    }

    public string HashRefreshToken(string plain) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(plain))).ToLowerInvariant();
}

public class FaceOptions
{
    public string BaseUrl { get; set; } = "http://localhost:8000";
    public string ApiKey { get; set; } = "";
    /// <summary>Chave AES-256 em base64 (32 bytes). Gere com: openssl rand -base64 32</summary>
    public string EncryptionKey { get; set; } = "";
}

/// <summary>AES-256-GCM. Formato: nonce(12) | tag(16) | ciphertext.</summary>
public class AesEmbeddingProtector : IEmbeddingProtector
{
    private readonly byte[] _key;

    public AesEmbeddingProtector(IOptions<FaceOptions> opt)
    {
        _key = Convert.FromBase64String(opt.Value.EncryptionKey);
        if (_key.Length != 32) throw new InvalidOperationException("Face:EncryptionKey deve ter 32 bytes (base64).");
    }

    public byte[] Protect(float[] embedding)
    {
        var plain = new byte[embedding.Length * sizeof(float)];
        Buffer.BlockCopy(embedding, 0, plain, 0, plain.Length);
        var nonce = RandomNumberGenerator.GetBytes(12);
        var cipher = new byte[plain.Length];
        var tag = new byte[16];
        using var aes = new AesGcm(_key, 16);
        aes.Encrypt(nonce, plain, cipher, tag);
        return nonce.Concat(tag).Concat(cipher).ToArray();
    }

    public float[] Unprotect(byte[] data)
    {
        var nonce = data[..12];
        var tag = data[12..28];
        var cipher = data[28..];
        var plain = new byte[cipher.Length];
        using var aes = new AesGcm(_key, 16);
        aes.Decrypt(nonce, cipher, tag, plain);
        var result = new float[plain.Length / sizeof(float)];
        Buffer.BlockCopy(plain, 0, result, 0, plain.Length);
        return result;
    }
}
