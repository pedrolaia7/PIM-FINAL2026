using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using TicketFut.Api.Extensions;
using TicketFut.Application.Contracts;
using TicketFut.Application.Services;

namespace TicketFut.Api.Controllers;

[ApiController, Authorize, Route("api/membership")]
public class MembershipController : ControllerBase
{
    private readonly MembershipService _svc;
    public MembershipController(MembershipService svc) => _svc = svc;

    [HttpPost("subscribe")]
    public async Task<ActionResult<SubscribeResponse>> Subscribe(SubscribeRequest req, CancellationToken ct) =>
        Ok(await _svc.SubscribeAsync(User.GetUserId(), req, ct));
}

[ApiController, Authorize, Route("api/matches")]
public class MatchesController : ControllerBase
{
    private readonly MatchService _svc;
    public MatchesController(MatchService svc) => _svc = svc;

    /// <param name="team">mine (padrão) | all | slug do time</param>
    /// <param name="status">all | scheduled | finished</param>
    [HttpGet]
    public async Task<ActionResult<List<MatchDto>>> List([FromQuery] string? team, [FromQuery] string? status,
        [FromQuery] string? q, CancellationToken ct) =>
        Ok(await _svc.ListAsync(User.GetUserId(), new MatchQuery(team, status, q), ct));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<MatchDto>> Get(int id, CancellationToken ct) =>
        Ok(await _svc.GetAsync(User.GetUserId(), id, ct));

    [HttpGet("{id:int}/sectors")]
    public async Task<ActionResult<List<SectorDto>>> Sectors(int id, CancellationToken ct) =>
        Ok(await _svc.SectorsAsync(User.GetUserId(), id, ct));
}

[ApiController, Authorize, Route("api/payments")]
public class PaymentsController : ControllerBase
{
    private readonly PaymentService _svc;
    public PaymentsController(PaymentService svc) => _svc = svc;

    [HttpPost("intents")]
    public async Task<ActionResult<IntentDto>> CreateIntent(CreateIntentRequest req, CancellationToken ct) =>
        Ok(await _svc.CreateIntentAsync(User.GetUserId(), req, ct));

    /// <summary>multipart/form-data: selfie (arquivo), nonce, cardToken (opcional para Pix).</summary>
    [HttpPost("intents/{id:guid}/confirm"), EnableRateLimiting("face"), RequestSizeLimit(6 * 1024 * 1024)]
    public async Task<ActionResult<ConfirmResponse>> Confirm(Guid id, [FromForm] IFormFile selfie,
        [FromForm] string nonce, [FromForm] string? cardToken, CancellationToken ct)
    {
        await using var ms = new MemoryStream();
        await selfie.CopyToAsync(ms, ct);
        return Ok(await _svc.ConfirmAsync(User.GetUserId(), id, nonce, ms.ToArray(), cardToken, ct));
    }
}

[ApiController, Authorize, Route("api/tickets")]
public class TicketsController : ControllerBase
{
    private readonly PaymentService _svc;
    public TicketsController(PaymentService svc) => _svc = svc;

    [HttpGet]
    public async Task<ActionResult<List<TicketDto>>> Mine(CancellationToken ct) =>
        Ok(await _svc.ListTicketsAsync(User.GetUserId(), ct));
}
