import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/router/route_args.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/device_services.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/matches/match_usecases.dart';
import 'bloc/map_cubit.dart';
import 'widgets/stadium_location_view.dart';
import 'widgets/stadium_sectors_view.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key, required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => MapCubit(sl<GetSectorsUseCase>(), sl<LocationService>(), match)..loadSectors(),
        child: _MapView(match: match),
      );
}

class _MapView extends StatelessWidget {
  const _MapView({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ARENA'),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            onTap: (i) {
              final c = context.read<MapCubit>();
              if (i == 1 && !c.state.locationAsked) c.locateUser();
            },
            tabs: const [Tab(text: 'SETORES'), Tab(text: 'ESTÁDIO')],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(match.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('📅 ${Fmt.date(match.kickoffAt)}   ⏰ ${Fmt.time(match.kickoffAt)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<MapCubit, MapState>(
                  builder: (context, state) => TabBarView(
                    physics: const NeverScrollableScrollPhysics(), // evita brigar com o gesto do mapa
                    children: [
                      _sectorsTab(context, state),
                      StadiumLocationView(
                        match: match,
                        state: state,
                        onLocate: () => context.read<MapCubit>().locateUser(),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectorsTab(BuildContext context, MapState state) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.failure != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(state.failure!.message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => context.read<MapCubit>().loadSectors(), child: const Text('TENTAR NOVAMENTE')),
        ]),
      );
    }
    return StadiumSectorsView(
      sectors: state.sectors,
      isAway: match.isAway,
      onSelect: (sector) => context.push('/checkout', extra: CheckoutArgs(match: match, sector: sector)),
    );
  }
}
