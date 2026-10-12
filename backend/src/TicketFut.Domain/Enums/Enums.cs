namespace TicketFut.Domain.Enums;

/// <summary>Valor numérico = percentual de desconto (igual ao app web original).</summary>
public enum MemberPlan { None = 0, Bronze = 5, Silver = 10, Gold = 20 }

public enum PaymentMethod { Credit, Debit, Pix }

public enum PaymentStatus { Pending, Paid, Failed, Expired }

public enum Sector { Norte, Sul, Oeste, Leste }
