import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Fmt {
  Fmt._();
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _time = DateFormat('HH:mm', 'pt_BR');

  static String money(num v) => _currency.format(v);
  static String date(DateTime utc) => _date.format(utc.toLocal());
  static String time(DateTime utc) => _time.format(utc.toLocal());
  static String km(double meters) =>
      meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Máscara genérica por padrão: '#' = dígito. Ex.: '###.###.###-##'
class MaskFormatter extends TextInputFormatter {
  MaskFormatter(this.mask);
  final String mask;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    var di = 0;
    for (var i = 0; i < mask.length && di < digits.length; i++) {
      if (mask[i] == '#') {
        buf.write(digits[di++]);
      } else {
        buf.write(mask[i]);
      }
    }
    final text = buf.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class Masks {
  Masks._();
  static MaskFormatter cpf() => MaskFormatter('###.###.###-##');
  static MaskFormatter card() => MaskFormatter('#### #### #### ####');
  static MaskFormatter expiry() => MaskFormatter('##/##');
}
