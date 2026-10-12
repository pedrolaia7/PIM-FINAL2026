import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/payment.dart';

/// Mapa da arena: NORTE / SUL / OESTE / LESTE. Setores indisponíveis ficam bloqueados com o motivo.
/// Regra: mandante em qualquer setor menos LESTE; visitante apenas no LESTE.
class StadiumSectorsView extends StatelessWidget {
  const StadiumSectorsView({super.key, required this.sectors, required this.isAway, required this.onSelect});
  final List<SectorAvailability> sectors;
  final bool isAway;
  final ValueChanged<Sector> onSelect;

  SectorAvailability _of(Sector s) =>
      sectors.firstWhere((e) => e.sector == s, orElse: () => SectorAvailability(sector: s, available: false));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _Banner(isAway: isAway),
      const SizedBox(height: 12),
      Expanded(
        child: Column(children: [
          _tile(context, Sector.norte, height: 70),
          const SizedBox(height: 8),
          Expanded(
            child: Row(children: [
              _tile(context, Sector.oeste, width: 70),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E3B1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F7A3D), width: 2),
                  ),
                  child: const Center(child: Icon(Icons.sports_soccer, color: Color(0xFF1F7A3D), size: 40)),
                ),
              ),
              const SizedBox(width: 8),
              _tile(context, Sector.leste, width: 70),
            ]),
          ),
          const SizedBox(height: 8),
          _tile(context, Sector.sul, height: 70),
        ]),
      ),
    ]);
  }

  Widget _tile(BuildContext context, Sector sector, {double? width, double? height}) {
    final a = _of(sector);
    final primary = Theme.of(context).colorScheme.primary;
    final color = a.available ? primary : AppColors.muted;
    final vertical = width != null;
    final label = RotatedBox(
      quarterTurns: vertical ? 3 : 0,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!a.available) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.lock, size: 14, color: AppColors.muted)),
        Text(sector.label, style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
      ]),
    );
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: a.available ? primary.withAlpha(24) : AppColors.bgItem,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withAlpha(a.available ? 255 : 90))),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: a.available
              ? () => onSelect(sector)
              : () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(a.reason ?? 'Setor indisponível.'))),
          child: Center(child: label),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.isAway});
  final bool isAway;

  @override
  Widget build(BuildContext context) {
    final color = isAway ? AppColors.warning : Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(24), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        isAway
            ? 'Seu time é o VISITANTE nesta partida. Apenas o setor LESTE está disponível.'
            : 'O setor LESTE é exclusivo da torcida visitante. Escolha um dos demais setores.',
        style: TextStyle(color: color, fontSize: 12.5, height: 1.35),
      ),
    );
  }
}
