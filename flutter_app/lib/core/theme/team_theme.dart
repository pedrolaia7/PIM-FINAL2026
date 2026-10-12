import 'package:flutter/material.dart';

/// Tema e textos de boas-vindas por time (portados do app web: TEMAS_TIMES, SPLASH_TIMES, NOTICIAS_TIMES).
class TeamTheme {
  const TeamTheme({
    required this.primary,
    required this.hover,
    required this.splashBg,
    required this.accent2,
    required this.phrases,
    required this.welcome,
    required this.news,
  });

  final Color primary;
  final Color hover;
  final List<Color> splashBg;
  final Color accent2;
  final List<String> phrases;
  final String welcome;
  final String news;

  static const defaultSlug = 'default';

  static const _all = <String, TeamTheme>{
    'palmeiras': TeamTheme(
      primary: Color(0xFF00C853), hover: Color(0xFF009624),
      splashBg: [Color(0xFF0A1A0A), Color(0xFF0D2A0D)], accent2: Colors.white,
      phrases: ['O MAIOR CAMPEÃO DO BRASIL', 'SOCIEDADE ESPORTIVA PALMEIRAS', 'VERDÃO IMORTAL'],
      welcome: 'BEM-VINDO, PALMEIRENSE!',
      news: '🏆 Time com vantagem no Brasileirão!\nExcelente momento da equipe.',
    ),
    'flamengo': TeamTheme(
      primary: Color(0xFFE53935), hover: Color(0xFFB71C1C),
      splashBg: [Color(0xFF1A0808), Color(0xFF2A0A0A)], accent2: Colors.black,
      phrases: ['MENGÃO, O CLUBE DO POVO', 'UMA VEZ FLAMENGO, SEMPRE FLAMENGO', 'NAÇÃO RUBRO-NEGRA'],
      welcome: 'BEM-VINDO, FLAMENGUISTA!',
      news: '🔴 Flamengo em boa forma!\nOtimismo com o elenco.',
    ),
    'corinthians': TeamTheme(
      primary: Color(0xFFFFFFFF), hover: Color(0xFFCCCCCC),
      splashBg: [Color(0xFF101010), Color(0xFF1A1A1A)], accent2: Color(0xFF888888),
      phrases: ['FIEL ATÉ O FIM', 'SPORT CLUB CORINTHIANS PAULISTA', 'O TIME DO POVO'],
      welcome: 'BEM-VINDO, FIEL!',
      news: '⚠️ Time em crise!\nNecessita de reforços urgentes.',
    ),
    'sao_paulo': TeamTheme(
      primary: Color(0xFFE53935), hover: Color(0xFFB71C1C),
      splashBg: [Color(0xFF1A0808), Color(0xFF0D0D1A)], accent2: Colors.white,
      phrases: ['TRICOLOR CAMPEÃO MUNDIAL', 'SÃO PAULO FUTEBOL CLUBE', 'SOBERANO DO BRASIL'],
      welcome: 'BEM-VINDO, SÃO-PAULINO!',
      news: '📍 São Paulo buscando recuperação.\nFoco total no campeonato.',
    ),
    'santos': TeamTheme(
      primary: Color(0xFFF5F5F5), hover: Color(0xFFBDBDBD),
      splashBg: [Color(0xFF0A0A12), Color(0xFF12121A)], accent2: Color(0xFFAAAAAA),
      phrases: ['O REI DO FUTEBOL VEIO DAQUI', 'SANTOS FUTEBOL CLUBE', 'A VILA BELMIRO TE AGUARDA'],
      welcome: 'BEM-VINDO, SANTISTA!',
      news: '⚽ Santos com bom desempenho!\nTime confiante para os jogos.',
    ),
    defaultSlug: TeamTheme(
      primary: Color(0xFF00FF6A), hover: Color(0xFF00CC55),
      splashBg: [Color(0xFF0A0A0A), Color(0xFF111418)], accent2: Color(0xFF00E5FF),
      phrases: ['BEM-VINDO AO CHAMPIONS CARD', 'SEU INGRESSO COM DESCONTO', 'FUTEBOL É PAIXÃO'],
      welcome: 'BEM-VINDO!',
      news: '⚽ Acompanhe as notícias do seu time!',
    ),
  };

  static TeamTheme of(String? slug) => _all[slug] ?? _all[defaultSlug]!;
}
