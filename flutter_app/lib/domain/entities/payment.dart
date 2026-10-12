import 'package:equatable/equatable.dart';

enum Sector {
  norte('Norte'),
  sul('Sul'),
  oeste('Oeste'),
  leste('Leste');

  const Sector(this.apiValue);
  final String apiValue;
  String get label => apiValue.toUpperCase();

  static Sector fromApi(String v) =>
      Sector.values.firstWhere((s) => s.apiValue.toLowerCase() == v.toLowerCase(), orElse: () => Sector.norte);
}

class SectorAvailability extends Equatable {
  const SectorAvailability({required this.sector, required this.available, this.reason});
  final Sector sector;
  final bool available;
  final String? reason;

  @override
  List<Object?> get props => [sector, available, reason];
}

enum PaymentMethod {
  credit('Credit', 'CRÉDITO'),
  debit('Debit', 'DÉBITO'),
  pix('Pix', 'PIX');

  const PaymentMethod(this.apiValue, this.label);
  final String apiValue;
  final String label;
  bool get isCard => this != PaymentMethod.pix;
}

/// Dados digitados no formulário. Vivem só na memória: viram um token e são descartados.
class CardInput extends Equatable {
  const CardInput({required this.number, required this.expiry, required this.cvv, required this.holder});
  final String number;
  final String expiry;
  final String cvv;
  final String holder;

  @override
  List<Object?> get props => [number, expiry, holder]; // CVV de fora de propósito
}

class PaymentIntent extends Equatable {
  const PaymentIntent({
    required this.id,
    required this.nonce,
    required this.amount,
    required this.originalAmount,
    required this.discountPercent,
    required this.expiresAt,
    required this.method,
  });

  final String id;
  final String nonce;
  final double amount;
  final double originalAmount;
  final int discountPercent;
  final DateTime expiresAt;
  final PaymentMethod method;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  @override
  List<Object?> get props => [id, nonce, amount, expiresAt];
}

class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.matchId,
    required this.matchName,
    required this.sector,
    required this.code,
    required this.amount,
    required this.kickoffAt,
  });

  final String id;
  final int matchId;
  final String matchName;
  final Sector sector;
  final String code;
  final double amount;
  final DateTime kickoffAt;

  @override
  List<Object?> get props => [id, code];
}

class PurchaseResult extends Equatable {
  const PurchaseResult({required this.ticket, this.pixPayload});
  final Ticket ticket;
  final String? pixPayload;

  @override
  List<Object?> get props => [ticket, pixPayload];
}

class SubscriptionResult extends Equatable {
  const SubscriptionResult({required this.memberCode, this.pixPayload});
  final String memberCode;
  final String? pixPayload;

  @override
  List<Object?> get props => [memberCode, pixPayload];
}

class RegisterData extends Equatable {
  const RegisterData({
    required this.name,
    required this.cpf,
    required this.email,
    required this.password,
    required this.team,
  });
  final String name;
  final String cpf;
  final String email;
  final String password;
  final String team;

  @override
  List<Object?> get props => [name, cpf, email, team];
}

enum MatchStatusFilter { all, scheduled, finished }

enum MatchScope { mine, all }
