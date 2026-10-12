import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/router/route_args.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/checkout/checkout_usecases.dart';
import '../auth/bloc/auth_bloc.dart';
import '../common/widgets.dart';
import 'widgets/card_form.dart';

/// Adesão ao programa de sócio (Bronze 5%, Prata 10%, Ouro 20%) — gera o código de sócio.
class PlansPage extends StatefulWidget {
  const PlansPage({super.key, required this.args});
  final PlansArgs args;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  static const _plans = <(int, String, Color)>[
    (5, 'SÓCIO BRONZE', Color(0xFFCD7F32)),
    (10, 'SÓCIO PRATA', Color(0xFFAAAAAA)),
    (20, 'SÓCIO OURO', Color(0xFFFFC400)),
  ];

  final _card = CardFormController();
  late int _plan = widget.args.initialPlan;
  PaymentMethod _method = PaymentMethod.credit;
  bool _busy = false;

  @override
  void dispose() {
    _card.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.args.fromRegistration) {
      context.go('/splash');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/matches');
    }
  }

  Future<void> _subscribe() async {
    if (_method.isCard && !_card.validate()) return;
    setState(() => _busy = true);
    final r = await sl<SubscribePlanUseCase>()(
      planPercent: _plan,
      method: _method,
      card: _method.isCard ? _card.read() : null,
    );
    if (!mounted) return;

    final failure = r.failureOrNull;
    if (failure != null) {
      setState(() => _busy = false);
      showAppSnack(context, failure.message, error: true);
      return;
    }

    final bloc = context.read<AuthBloc>();
    final fresh = await sl<AuthRepository>().refreshUser();
    fresh.fold((_) {}, (u) => bloc.add(UserUpdated(u)));
    if (!mounted) return;
    setState(() => _busy = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Parabéns! Você agora é sócio!'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SEU CÓDIGO DE SÓCIO', style: TextStyle(fontSize: 11, letterSpacing: 2, color: AppColors.muted)),
          const SizedBox(height: 6),
          SelectableText(r.valueOrNull!.memberCode, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 10),
          const Text('Guarde este código: ele será pedido na compra de ingressos para aplicar o desconto.', style: TextStyle(fontSize: 13)),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDI'))],
      ),
    );
    if (mounted) _finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SEJA SÓCIO')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          for (final p in _plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _busy ? null : () => setState(() => _plan = p.$1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _plan == p.$1 ? p.$3.withAlpha(32) : AppColors.bgItem,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.$3, width: _plan == p.$1 ? 2 : 1),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.$2, style: TextStyle(color: p.$3, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 4),
                        Text('${p.$1}% de desconto nos ingressos', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ]),
                    ),
                    if (_plan == p.$1) Icon(Icons.check_circle, color: p.$3),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const SectionLabel('FORMA DE PAGAMENTO'),
          SizedBox(width: double.infinity, child: PaymentMethodSelector(value: _method, onChanged: (m) => setState(() => _method = m))),
          const SizedBox(height: 16),
          if (_method.isCard)
            CardForm(controller: _card)
          else
            const AppCard(child: Text('O código Pix será gerado ao confirmar a adesão.', style: TextStyle(fontSize: 13))),
          const SizedBox(height: 20),
          BusyButton(label: 'ASSINAR PLANO', busy: _busy, onPressed: _subscribe),
          if (widget.args.fromRegistration && !_busy)
            TextButton(onPressed: _finish, child: const Text('PULAR POR ENQUANTO', style: TextStyle(color: AppColors.muted, letterSpacing: 1.5))),
        ]),
      ),
    );
  }
}
