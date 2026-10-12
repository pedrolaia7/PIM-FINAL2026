using System.Security.Claims;
using TicketFut.Application.Common;

namespace TicketFut.Api.Extensions;

public static class ClaimsExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        // MapInboundClaims=false no Program.cs => o claim fica como "sub"
        var raw = user.FindFirstValue("sub") ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(raw, out var id) ? id : throw AppException.Unauthorized();
    }
}
