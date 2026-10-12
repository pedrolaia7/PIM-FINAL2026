/// Validadores puros (sem Flutter) — fáceis de testar. Retornam a mensagem de erro ou null.
class Validators {
  Validators._();

  static String digits(String v) => v.replaceAll(RegExp(r'\D'), '');

  static String? required(String? v, [String msg = 'Campo obrigatório']) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  static String? name(String? v) => (v == null || v.trim().length < 3) ? 'Informe seu nome completo' : null;

  static String? email(String? v) {
    final s = (v ?? '').trim();
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);
    return ok ? null : 'E-mail inválido';
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Mínimo de 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) return 'Use letras e números';
    return null;
  }

  static bool isValidCpf(String? value) {
    final d = digits(value ?? '');
    if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
    int check(int len) {
      var sum = 0;
      for (var i = 0; i < len; i++) {
        sum += int.parse(d[i]) * (len + 1 - i);
      }
      final r = (sum * 10) % 11;
      return r == 10 ? 0 : r;
    }

    return check(9) == int.parse(d[9]) && check(10) == int.parse(d[10]);
  }

  static String? cpf(String? v) => isValidCpf(v) ? null : 'CPF inválido';

  /// Algoritmo de Luhn.
  static bool isValidCardNumber(String? value) {
    final d = digits(value ?? '');
    if (d.length < 13 || d.length > 19) return false;
    var sum = 0;
    var alt = false;
    for (var i = d.length - 1; i >= 0; i--) {
      var n = int.parse(d[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  static String? cardNumber(String? v) => isValidCardNumber(v) ? null : 'Número de cartão inválido';

  /// MM/AA, não vencido. [now] injetável para testes.
  static String? cardExpiry(String? v, {DateTime? now}) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch((v ?? '').trim());
    if (m == null) return 'Use MM/AA';
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return 'Mês inválido';
    final today = now ?? DateTime.now();
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);
    return lastDay.isBefore(today) ? 'Cartão vencido' : null;
  }

  static String? cvv(String? v) {
    final d = digits(v ?? '');
    return (d.length == 3 || d.length == 4) ? null : 'CVV inválido';
  }
}
