using System.Net.Http.Json;
using System.Text.Json;
using TicketFut.Application.Abstractions;
using TicketFut.Application.Common;

namespace TicketFut.Infrastructure.Services;

/// <summary>Cliente HTTP do microsserviço Python. Resiliência (retry/timeout/circuit breaker) vem do AddStandardResilienceHandler.</summary>
public class FaceRecognitionClient : IFaceRecognitionClient
{
    private static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true,
    };

    private readonly HttpClient _http;
    public FaceRecognitionClient(HttpClient http) => _http = http;

    private record EnrollResponse(float[] Embedding, string ModelVersion);
    private record LivenessDto(bool Checked, bool? Passed);
    private record VerifyResponse(double Similarity, bool IsMatch, double Threshold, LivenessDto Liveness, string ModelVersion);
    private record ErrorBody(string? Code, string? Message);

    public async Task<FaceEnrollResult> EnrollAsync(byte[] image, CancellationToken ct = default)
    {
        var res = await PostAsync("/v1/faces/enroll", new { image_b64 = Convert.ToBase64String(image) }, ct);
        var body = await res.Content.ReadFromJsonAsync<EnrollResponse>(Json, ct)
                   ?? throw Unavailable();
        return new FaceEnrollResult(body.Embedding, body.ModelVersion);
    }

    public async Task<FaceVerifyResult> VerifyAsync(byte[] image, float[] storedEmbedding, string purpose, CancellationToken ct = default)
    {
        var res = await PostAsync("/v1/faces/verify",
            new { image_b64 = Convert.ToBase64String(image), embedding = storedEmbedding, purpose }, ct);
        var b = await res.Content.ReadFromJsonAsync<VerifyResponse>(Json, ct) ?? throw Unavailable();
        return new FaceVerifyResult(b.Similarity, b.IsMatch, b.Threshold, b.Liveness.Checked, b.Liveness.Passed, b.ModelVersion);
    }

    private async Task<HttpResponseMessage> PostAsync(string path, object payload, CancellationToken ct)
    {
        HttpResponseMessage res;
        try
        {
            res = await _http.PostAsJsonAsync(path, payload, Json, ct);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or Polly.CircuitBreaker.BrokenCircuitException
                                       or Polly.Timeout.TimeoutRejectedException)
        {
            if (ct.IsCancellationRequested) throw;
            throw Unavailable();
        }

        if (res.IsSuccessStatusCode) return res;

        // 4xx do Python = problema com a imagem (sem rosto, borrada...) -> mensagem amigável ao usuário
        if ((int)res.StatusCode is >= 400 and < 500 && res.StatusCode != System.Net.HttpStatusCode.Unauthorized)
        {
            var err = await res.Content.ReadFromJsonAsync<ErrorBody>(Json, ct);
            throw AppException.Validation(err?.Code ?? "face_error", err?.Message ?? "Não foi possível processar a imagem.");
        }
        throw Unavailable();
    }

    private static AppException Unavailable() =>
        new(503, "face_service_unavailable", "Serviço de reconhecimento facial indisponível. Tente novamente em instantes.");
}
