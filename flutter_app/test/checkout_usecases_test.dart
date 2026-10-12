import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ticketfut/core/error/failures.dart';
import 'package:ticketfut/domain/entities/payment.dart';
import 'package:ticketfut/domain/repositories/repositories.dart';
import 'package:ticketfut/domain/usecases/checkout/checkout_usecases.dart';

class _MockBiometric extends Mock implements BiometricAuthenticator {}

class _MockRepo extends Mock implements PaymentRepository {}

class _MockTokenizer extends Mock implements CardTokenizer {}

void main() {
  group('RequireBiometricUseCase', () {
    late _MockBiometric bio;
    setUp(() => bio = _MockBiometric());

    test('falha se o usuário cancelar', () async {
      when(() => bio.isAvailable).thenAnswer((_) async => true);
      when(() => bio.authenticate(any())).thenAnswer((_) async => false);
      final r = await RequireBiometricUseCase(bio)();
      expect(r.failureOrNull, Failure.biometricCancelled);
    });

    test('passa se autenticar', () async {
      when(() => bio.isAvailable).thenAnswer((_) async => true);
      when(() => bio.authenticate(any())).thenAnswer((_) async => true);
      expect((await RequireBiometricUseCase(bio)()).isOk, isTrue);
    });

    test('bloqueia quando não há biometria no aparelho (padrão do app)', () async {
      when(() => bio.isAvailable).thenAnswer((_) async => false);
      final r = await RequireBiometricUseCase(bio)();
      expect(r.failureOrNull, Failure.biometricUnavailable);
      verifyNever(() => bio.authenticate(any()));
    });
  });

  group('ConfirmPaymentUseCase', () {
    final intent = PaymentIntent(
      id: 'i1', nonce: 'n', amount: 100, originalAmount: 100, discountPercent: 0,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)), method: PaymentMethod.credit,
    );

    test('exige cartão quando o método é cartão', () async {
      final uc = ConfirmPaymentUseCase(_MockRepo(), _MockTokenizer());
      final r = await uc(intent: intent, selfiePath: '/tmp/s.jpg');
      expect(r.failureOrNull?.code, 'card_required');
    });

    test('recusa intenção expirada sem chamar o backend', () async {
      final repo = _MockRepo();
      final expired = PaymentIntent(
        id: 'i2', nonce: 'n', amount: 1, originalAmount: 1, discountPercent: 0,
        expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)), method: PaymentMethod.pix,
      );
      final r = await ConfirmPaymentUseCase(repo, _MockTokenizer())(intent: expired, selfiePath: 'x');
      expect(r.failureOrNull?.code, 'intent_expired');
      verifyZeroInteractions(repo);
    });
  });
}
