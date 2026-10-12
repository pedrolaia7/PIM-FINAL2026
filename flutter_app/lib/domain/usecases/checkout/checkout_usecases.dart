import '../../../core/config/env.dart';
import '../../../core/error/failures.dart';
import '../../entities/payment.dart';
import '../../repositories/repositories.dart';

class CreatePaymentIntentUseCase {
  CreatePaymentIntentUseCase(this._repo);
  final PaymentRepository _repo;

  Future<Result<PaymentIntent>> call({
    required int matchId,
    required Sector sector,
    required PaymentMethod method,
    String? memberCode,
  }) =>
      _repo.createIntent(matchId: matchId, sector: sector, method: method, memberCode: memberCode);
}

/// Camada extra obrigatória ANTES de finalizar a compra: biometria nativa do aparelho.
class RequireBiometricUseCase {
  RequireBiometricUseCase(this._biometric);
  final BiometricAuthenticator _biometric;

  Future<Result<void>> call({String reason = 'Confirme sua compra'}) async {
    if (!await _biometric.isAvailable) {
      return Env.requireLocalBiometricForPurchase ? const Err(Failure.biometricUnavailable) : const Ok(null);
    }
    return await _biometric.authenticate(reason) ? const Ok(null) : const Err(Failure.biometricCancelled);
  }
}

/// Tokeniza o cartão (se houver) e envia a selfie ao backend, que decide a aprovação.
class ConfirmPaymentUseCase {
  ConfirmPaymentUseCase(this._repo, this._tokenizer);
  final PaymentRepository _repo;
  final CardTokenizer _tokenizer;

  Future<Result<PurchaseResult>> call({
    required PaymentIntent intent,
    required String selfiePath,
    CardInput? card,
  }) async {
    if (intent.isExpired) {
      return const Err(Failure('intent_expired', 'O tempo para confirmar a compra expirou. Inicie novamente.'));
    }
    String? token;
    if (intent.method.isCard) {
      if (card == null) return const Err(Failure('card_required', 'Informe os dados do cartão.'));
      token = await _tokenizer.tokenize(card);
    }
    return _repo.confirm(intent: intent, selfiePath: selfiePath, cardToken: token);
  }
}

class SubscribePlanUseCase {
  SubscribePlanUseCase(this._repo, this._tokenizer);
  final PaymentRepository _repo;
  final CardTokenizer _tokenizer;

  Future<Result<SubscriptionResult>> call({
    required int planPercent,
    required PaymentMethod method,
    CardInput? card,
  }) async {
    String? token;
    if (method.isCard) {
      if (card == null) return const Err(Failure('card_required', 'Informe os dados do cartão.'));
      token = await _tokenizer.tokenize(card);
    }
    return _repo.subscribe(planPercent: planPercent, method: method, cardToken: token);
  }
}
