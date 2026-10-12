import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/payment.dart';

class CardFormController {
  final formKey = GlobalKey<FormState>();
  final number = TextEditingController();
  final expiry = TextEditingController();
  final cvv = TextEditingController();
  final holder = TextEditingController();

  bool validate() => formKey.currentState?.validate() ?? false;

  CardInput read() => CardInput(number: number.text, expiry: expiry.text, cvv: cvv.text, holder: holder.text.trim());

  void dispose() {
    number.dispose();
    expiry.dispose();
    cvv.dispose();
    holder.dispose();
  }
}

/// Formulário de cartão. Os dados ficam só nos controllers (memória) e viram um token no momento do pagamento.
class CardForm extends StatelessWidget {
  const CardForm({super.key, required this.controller});
  final CardFormController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(children: [
        TextFormField(
          controller: controller.number,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.creditCardNumber],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, Masks.card()],
          decoration: const InputDecoration(labelText: 'NÚMERO DO CARTÃO'),
          validator: Validators.cardNumber,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.holder,
          textCapitalization: TextCapitalization.characters,
          autofillHints: const [AutofillHints.creditCardName],
          decoration: const InputDecoration(labelText: 'NOME NO CARTÃO'),
          validator: (v) => Validators.required(v, 'Informe o nome impresso'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: controller.expiry,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, Masks.expiry()],
              decoration: const InputDecoration(labelText: 'VALIDADE', hintText: 'MM/AA'),
              validator: Validators.cardExpiry,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller.cvv,
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              decoration: const InputDecoration(labelText: 'CVV'),
              validator: Validators.cvv,
            ),
          ),
        ]),
      ]),
    );
  }
}

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({super.key, required this.value, required this.onChanged});
  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PaymentMethod>(
      showSelectedIcon: false,
      segments: [for (final m in PaymentMethod.values) ButtonSegment(value: m, label: Text(m.label))],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
