using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using TicketFut.Api.Middleware;
using TicketFut.Application.Abstractions;
using TicketFut.Application.Services;
using TicketFut.Infrastructure;
using TicketFut.Infrastructure.Persistence;

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;

// ---- Segurança: falha cedo se a configuração crítica estiver faltando ----
var jwtKey = config["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey) || jwtKey.Length < 32)
    throw new InvalidOperationException("Configure Jwt:Key com 32+ caracteres (user-secrets ou variável de ambiente Jwt__Key).");
if (string.IsNullOrWhiteSpace(config["Face:EncryptionKey"]))
    throw new InvalidOperationException("Configure Face:EncryptionKey (base64, 32 bytes). Gere com: openssl rand -base64 32");

builder.Services.AddInfrastructure(config);

// ---- Application ----
builder.Services.AddSingleton(config.GetSection("Face:Policy").Get<FacePolicy>() ?? new FacePolicy());
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<MembershipService>();
builder.Services.AddScoped<MatchService>();
builder.Services.AddScoped<PaymentService>();

// ---- Auth (JWT) ----
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.MapInboundClaims = false;   // mantém "sub" como "sub"
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true, ValidIssuer = config["Jwt:Issuer"],
            ValidateAudience = true, ValidAudience = config["Jwt:Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateLifetime = true, ClockSkew = TimeSpan.FromSeconds(30),
        };
    });
builder.Services.AddAuthorization();

// ---- Rate limiting (anti força-bruta em login e verificação facial) ----
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.AddPolicy("auth", ctx => RateLimitPartition.GetFixedWindowLimiter(
        ctx.Connection.RemoteIpAddress?.ToString() ?? "anon",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1) }));
    o.AddPolicy("face", ctx => RateLimitPartition.GetFixedWindowLimiter(
        ctx.User.FindFirst("sub")?.Value ?? ctx.Connection.RemoteIpAddress?.ToString() ?? "anon",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1) }));
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();

var app = builder.Build();

// ---- Banco ----
if (config.GetValue<bool>("Database:AutoCreate"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var hasher = scope.ServiceProvider.GetRequiredService<TicketFut.Application.Abstractions.IPasswordHasher>();
    // Em produção prefira migrations: dotnet ef database update
    await db.Database.EnsureCreatedAsync();
    await DbSeeder.SeedAsync(db, hasher, seedDevAdmin: app.Environment.IsDevelopment());
}

app.UseMiddleware<ExceptionMiddleware>();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseHttpsRedirection();
}
app.UseAuthentication();
app.UseRateLimiter();   // depois do auth: a política "face" particiona por usuário
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");
app.Run();
