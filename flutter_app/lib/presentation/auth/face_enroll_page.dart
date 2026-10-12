import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_args.dart';
import '../../core/theme/app_theme.dart';
import '../common/widgets.dart';
import 'bloc/auth_bloc.dart';
import 'face_capture_page.dart';

/// Etapa do cadastro: captura a selfie e envia ao backend (que registra o rosto no microsserviço Python).
class FaceEnrollPage extends StatelessWidget {
  const FaceEnrollPage({super.key, required this.args});
  final FaceEnrollArgs args;

  Future<void> _capture(BuildContext context) async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const FaceCapturePage(title: 'CADASTRO FACIAL')),
    );
    if (path != null && context.mounted) context.read<AuthBloc>().add(FaceEnrollSubmitted(path));
  }

  void _next(BuildContext context) {
    if (args.fromRegistration) {
      context.go(args.planPercent > 0 ? '/plans' : '/splash',
          extra: args.planPercent > 0 ? PlansArgs(initialPlan: args.planPercent, fromRegistration: true) : null);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/matches');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CADASTRO FACIAL')),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (p, c) => p.errorSeq != c.errorSeq && c.failure != null,
              listener: (context, s) => showAppSnack(context, s.failure!.message, error: true),
            ),
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (p, c) => p.faceEnrolledSeq != c.faceEnrolledSeq,
              listener: (context, s) {
                showAppSnack(context, 'Rosto cadastrado com sucesso!');
                _next(context);
              },
            ),
          ],
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Icon(Icons.face_retouching_natural, size: 96, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              const Text('VAMOS CADASTRAR SEU ROSTO',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 12),
              const Text(
                'Vamos usar a câmera frontal para tirar uma selfie. Ela será usada para confirmar suas compras com mais segurança.\n\n'
                'Dicas: boa iluminação, sem óculos escuros ou boné, só você na foto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 32),
              BusyButton(label: 'ABRIR CÂMERA', icon: Icons.camera_front, busy: state.busy, onPressed: () => _capture(context)),
              const SizedBox(height: 8),
              if (!state.busy)
                TextButton(
                  onPressed: () => _next(context),
                  child: const Text('FAZER DEPOIS', style: TextStyle(color: AppColors.muted, letterSpacing: 1.5)),
                ),
              if (!state.busy)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Sem o cadastro facial não é possível comprar ingressos.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.warning, fontSize: 12)),
                ),
            ]),
          ),
          ),
        ),
      ),
    );
  }
}
