import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match.dart';
import '../bloc/map_cubit.dart';

/// Localização do estádio (OpenStreetMap, sem chave de API) + distância do usuário + rota no app de mapas.
class StadiumLocationView extends StatelessWidget {
  const StadiumLocationView({super.key, required this.match, required this.state, required this.onLocate});
  final Match match;
  final MapState state;
  final VoidCallback onLocate;

  Future<void> _openRoute(BuildContext context) async {
    final dest = '${match.stadium.latitude},${match.stadium.longitude}';
    final origin = state.userLocation;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$dest'
      '${origin != null ? '&origin=${origin.latitude},${origin.longitude}' : ''}&travelmode=driving',
    );
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o app de mapas.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stadium = LatLng(match.stadium.latitude, match.stadium.longitude);
    final primary = Theme.of(context).colorScheme.primary;
    final user = state.userLocation;

    return Column(children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(initialCenter: stadium, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.ticketfut.app',
              ),
              MarkerLayer(markers: [
                Marker(point: stadium, width: 44, height: 44, child: Icon(Icons.stadium, color: primary, size: 40)),
                if (user != null)
                  Marker(point: user, width: 28, height: 28, child: const Icon(Icons.my_location, color: AppColors.neonCyan, size: 26)),
              ]),
              const RichAttributionWidget(attributions: [TextSourceAttribution('© colaboradores do OpenStreetMap')]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(match.stadium.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text(match.stadium.city, style: const TextStyle(color: AppColors.muted)),
            if (state.distanceMeters != null)
              Text('Você está a ${Fmt.km(state.distanceMeters!)} do estádio', style: TextStyle(color: primary, fontSize: 13)),
            if (state.locationAsked && user == null)
              const Text('Localização indisponível. Ative o GPS e a permissão.', style: TextStyle(color: AppColors.warning, fontSize: 12)),
          ]),
        ),
        IconButton(
          tooltip: 'Minha localização',
          onPressed: state.locationLoading ? null : onLocate,
          icon: state.locationLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
        ),
      ]),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: () => _openRoute(context), icon: const Icon(Icons.directions), label: const Text('COMO CHEGAR')),
    ]);
  }
}
