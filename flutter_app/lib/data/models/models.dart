import '../../domain/entities/match.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/user.dart';

double _d(Object? v) => (v as num).toDouble();

class UserModel {
  static User fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        team: j['team'] as String,
        planPercent: j['planPercent'] as int,
        planName: j['planName'] as String,
        memberCode: j['memberCode'] as String?,
        hasFace: j['hasFace'] as bool,
      );
}

class AuthResponseModel {
  AuthResponseModel(this.accessToken, this.refreshToken, this.user);
  final String accessToken;
  final String refreshToken;
  final User user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> j) => AuthResponseModel(
        j['accessToken'] as String,
        j['refreshToken'] as String,
        UserModel.fromJson(j['user'] as Map<String, dynamic>),
      );
}

class MatchModel {
  static Match fromJson(Map<String, dynamic> j) {
    final s = j['stadium'] as Map<String, dynamic>;
    return Match(
      id: j['id'] as int,
      homeTeam: j['homeTeam'] as String,
      awayTeam: j['awayTeam'] as String,
      homeName: j['homeName'] as String,
      awayName: j['awayName'] as String,
      kickoffAt: DateTime.parse(j['kickoffAt'] as String).toUtc(),
      isFinished: j['status'] == 'finished',
      basePrice: _d(j['basePrice']),
      price: _d(j['price']),
      discountPercent: j['discountPercent'] as int,
      isAway: j['isAway'] as bool,
      stadium: Stadium(
        name: s['name'] as String,
        city: s['city'] as String,
        latitude: _d(s['latitude']),
        longitude: _d(s['longitude']),
      ),
    );
  }
}

class SectorModel {
  static SectorAvailability fromJson(Map<String, dynamic> j) => SectorAvailability(
        sector: Sector.fromApi(j['sector'] as String),
        available: j['available'] as bool,
        reason: j['reason'] as String?,
      );
}

class PaymentModel {
  static PaymentIntent intentFromJson(Map<String, dynamic> j) => PaymentIntent(
        id: j['intentId'] as String,
        nonce: j['nonce'] as String,
        amount: _d(j['amount']),
        originalAmount: _d(j['originalAmount']),
        discountPercent: j['discountPercent'] as int,
        expiresAt: DateTime.parse(j['expiresAt'] as String).toUtc(),
        method: PaymentMethod.values.firstWhere(
          (m) => m.apiValue.toLowerCase() == (j['method'] as String).toLowerCase(),
        ),
      );

  static Ticket ticketFromJson(Map<String, dynamic> j) => Ticket(
        id: j['id'] as String,
        matchId: j['matchId'] as int,
        matchName: j['matchName'] as String,
        sector: Sector.fromApi(j['sector'] as String),
        code: j['code'] as String,
        amount: _d(j['amount']),
        kickoffAt: DateTime.parse(j['kickoffAt'] as String).toUtc(),
      );
}
