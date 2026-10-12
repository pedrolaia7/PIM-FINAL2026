import '../../core/error/failures.dart';
import '../entities/match.dart';
import '../entities/payment.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Há sessão guardada no aparelho (refresh token)?
  Future<bool> get hasStoredSession;

  /// Acesso rápido por biometria está ativado neste aparelho?
  Future<bool> get isBiometricEnabled;

  /// Tenta retomar a sessão guardada (renovando o token se preciso).
  Future<Result<User>> restoreSession();

  Future<Result<User>> login({required String email, required String password, required bool enableBiometric});
  Future<Result<User>> register(RegisterData data);
  Future<Result<User>> enrollFace(String imagePath);
  Future<Result<User>> refreshUser();
  Future<Result<void>> deleteFace();

  /// [keepBiometricSession]: mantém o refresh token (protegido pela biometria) para o acesso rápido.
  Future<void> logout({required bool keepBiometricSession});
  Future<void> disableBiometric();
}

abstract class MatchRepository {
  Future<Result<List<Match>>> getMatches({
    MatchScope scope = MatchScope.mine,
    MatchStatusFilter status = MatchStatusFilter.all,
    String? search,
  });
  Future<Result<List<SectorAvailability>>> getSectors(int matchId);
}

abstract class PaymentRepository {
  Future<Result<PaymentIntent>> createIntent({
    required int matchId,
    required Sector sector,
    required PaymentMethod method,
    String? memberCode,
  });

  Future<Result<PurchaseResult>> confirm({
    required PaymentIntent intent,
    required String selfiePath,
    String? cardToken,
  });

  Future<Result<SubscriptionResult>> subscribe({
    required int planPercent,
    required PaymentMethod method,
    String? cardToken,
  });

  Future<Result<List<Ticket>>> tickets();
}

/// Biometria nativa do aparelho (Face ID / digital). Só devolve "ok ou não" localmente.
abstract class BiometricAuthenticator {
  Future<bool> get isAvailable;
  Future<bool> authenticate(String reason);
}

/// Transforma dados de cartão em token. Em produção, use o SDK do gateway de pagamento.
abstract class CardTokenizer {
  Future<String> tokenize(CardInput card);
}
