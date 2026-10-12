import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/router/route_args.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/team_theme.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/matches/match_usecases.dart';
import '../auth/bloc/auth_bloc.dart';
import '../common/widgets.dart';
import 'bloc/matches_cubit.dart';
import 'widgets/match_card.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => MatchesCubit(sl<GetMatchesUseCase>())..load(),
        child: const _MatchesView(),
      );
}

class _MatchesView extends StatefulWidget {
  const _MatchesView();

  @override
  State<_MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<_MatchesView> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => context.read<MatchesCubit>().load(search: v));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    final team = TeamTheme.of(user?.team);
    final cubit = context.read<MatchesCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PARTIDAS'),
        leading: Padding(padding: const EdgeInsets.all(12), child: TeamLogo(user?.team ?? '', size: 28)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              final auth = context.read<AuthBloc>();
              switch (v) {
                case 'plans':
                  context.push('/plans', extra: const PlansArgs());
                case 'face':
                  context.push('/face-enroll', extra: const FaceEnrollArgs());
                case 'logout':
                  auth.add(const LogoutRequested());
                case 'forget':
                  auth.add(const LogoutRequested(forgetDevice: true));
              }
            },
            itemBuilder: (_) => [
              if (user != null && !user.isMember) const PopupMenuItem(value: 'plans', child: Text('Quero ser sócio')),
              PopupMenuItem(value: 'face', child: Text(user?.hasFace == true ? 'Refazer cadastro facial' : 'Cadastrar rosto')),
              const PopupMenuItem(value: 'logout', child: Text('Sair')),
              const PopupMenuItem(value: 'forget', child: Text('Sair e remover biometria')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => cubit.load(),
        child: BlocBuilder<MatchesCubit, MatchesState>(
          builder: (context, state) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                borderColor: team.primary,
                child: Text(team.news, style: const TextStyle(height: 1.4)),
              ),
              if (user != null && !user.hasFace) ...[
                const SizedBox(height: 12),
                AppCard(
                  borderColor: AppColors.warning,
                  child: Row(children: [
                    const Icon(Icons.face_retouching_natural, color: AppColors.warning),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Cadastre seu rosto para poder comprar ingressos.', style: TextStyle(fontSize: 13))),
                    TextButton(onPressed: () => context.push('/face-enroll', extra: const FaceEnrollArgs()), child: const Text('CADASTRAR')),
                  ]),
                ),
              ],
              if (user != null && user.isMember) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Row(children: [
                    Icon(Icons.workspace_premium, color: team.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${user.planName} • ${user.planPercent}% de desconto', style: const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                onChanged: _onSearch,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar time ou estádio'),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 4, children: [
                ChoiceChip(
                  label: const Text('MEU TIME'),
                  selected: state.scope == MatchScope.mine,
                  onSelected: (_) => cubit.load(scope: MatchScope.mine),
                ),
                ChoiceChip(
                  label: const Text('TODOS OS JOGOS'),
                  selected: state.scope == MatchScope.all,
                  onSelected: (_) => cubit.load(scope: MatchScope.all),
                ),
                const SizedBox(width: 8),
                for (final f in MatchStatusFilter.values)
                  FilterChip(
                    label: Text(switch (f) {
                      MatchStatusFilter.all => 'TODAS',
                      MatchStatusFilter.scheduled => 'PRÓXIMAS',
                      MatchStatusFilter.finished => 'ENCERRADAS',
                    }),
                    selected: state.filter == f,
                    onSelected: (_) => cubit.load(filter: f),
                  ),
              ]),
              const SizedBox(height: 16),
              ..._content(context, state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, MatchesState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const [Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))];
      case LoadStatus.failure:
        return [
          AppCard(
            borderColor: AppColors.danger,
            child: Column(children: [
              Text(state.failure?.message ?? 'Erro ao carregar partidas.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.read<MatchesCubit>().load(), child: const Text('TENTAR NOVAMENTE')),
            ]),
          ),
        ];
      case LoadStatus.success:
        if (state.matches.isEmpty) {
          return const [
            Padding(
              padding: EdgeInsets.all(24),
              child: Text('NENHUMA PARTIDA DISPONÍVEL.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, letterSpacing: 1.5)),
            ),
          ];
        }
        return [
          for (final m in state.matches)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MatchCard(match: m, onTap: () => context.push('/map', extra: m)),
            ),
        ];
    }
  }
}
