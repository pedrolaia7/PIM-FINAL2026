using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using TicketFut.Application.Abstractions;
using TicketFut.Infrastructure.Persistence;
using TicketFut.Infrastructure.Persistence.Repositories;
using TicketFut.Infrastructure.Services;

namespace TicketFut.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        services.AddDbContext<AppDbContext>(o => o.UseSqlServer(config.GetConnectionString("Default")));

        services.Configure<JwtOptions>(config.GetSection("Jwt"));
        services.Configure<FaceOptions>(config.GetSection("Face"));

        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IFaceTemplateRepository, FaceTemplateRepository>();
        services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
        services.AddScoped<IMatchRepository, MatchRepository>();
        services.AddScoped<IPaymentRepository, PaymentRepository>();

        services.AddSingleton<IClock, SystemClock>();
        services.AddSingleton<Application.Abstractions.IPasswordHasher, AspNetPasswordHasher>();
        services.AddSingleton<ITokenService, TokenService>();
        services.AddSingleton<IEmbeddingProtector, AesEmbeddingProtector>();
        services.AddSingleton<IPaymentGateway, SandboxPaymentGateway>();   // troque pelo gateway real

        services.AddHttpClient<IFaceRecognitionClient, FaceRecognitionClient>((sp, http) =>
        {
            var opt = config.GetSection("Face").Get<FaceOptions>() ?? new FaceOptions();
            http.BaseAddress = new Uri(opt.BaseUrl);
            http.DefaultRequestHeaders.Add("X-API-Key", opt.ApiKey);
        }).AddStandardResilienceHandler();   // retry + circuit breaker + timeouts (Polly)

        return services;
    }
}
