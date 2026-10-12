class TeamInfo {
  const TeamInfo(this.slug, this.name);
  final String slug;
  final String name;

  String get logoAsset => 'assets/logos/$slug.png';

  static const all = <TeamInfo>[
    TeamInfo('palmeiras', 'Palmeiras'),
    TeamInfo('corinthians', 'Corinthians'),
    TeamInfo('flamengo', 'Flamengo'),
    TeamInfo('sao_paulo', 'São Paulo'),
    TeamInfo('santos', 'Santos'),
  ];

  static TeamInfo? of(String slug) {
    for (final t in all) {
      if (t.slug == slug) return t;
    }
    return null;
  }
}
