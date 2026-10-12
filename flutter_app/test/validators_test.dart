import 'package:flutter_test/flutter_test.dart';
import 'package:ticketfut/core/utils/validators.dart';

void main() {
  group('CPF', () {
    test('aceita CPF válido, com ou sem máscara', () {
      expect(Validators.isValidCpf('529.982.247-25'), isTrue);
      expect(Validators.isValidCpf('52998224725'), isTrue);
    });
    test('rejeita inválidos', () {
      expect(Validators.isValidCpf('111.111.111-11'), isFalse);
      expect(Validators.isValidCpf('529.982.247-24'), isFalse);
      expect(Validators.isValidCpf('123'), isFalse);
      expect(Validators.isValidCpf(null), isFalse);
    });
  });

  group('Cartão', () {
    test('Luhn', () {
      expect(Validators.isValidCardNumber('4111 1111 1111 1111'), isTrue);
      expect(Validators.isValidCardNumber('4111 1111 1111 1112'), isFalse);
      expect(Validators.isValidCardNumber('1234'), isFalse);
    });
    test('validade', () {
      final now = DateTime(2026, 10, 10);
      expect(Validators.cardExpiry('10/26', now: now), isNull); // vale até o fim do mês
      expect(Validators.cardExpiry('09/26', now: now), 'Cartão vencido');
      expect(Validators.cardExpiry('13/30', now: now), 'Mês inválido');
      expect(Validators.cardExpiry('1/30', now: now), 'Use MM/AA');
    });
    test('cvv', () {
      expect(Validators.cvv('123'), isNull);
      expect(Validators.cvv('12'), isNotNull);
    });
  });

  test('senha exige 8+ caracteres com letras e números', () {
    expect(Validators.password('abc12345'), isNull);
    expect(Validators.password('abcdefgh'), isNotNull);
    expect(Validators.password('abc123'), isNotNull);
  });
}
