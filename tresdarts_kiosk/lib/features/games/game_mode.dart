enum GameModeId {
  x01,
  cricket,
  aroundTheClock,
  shanghai,
  killer,
}

class GameMode {
  const GameMode({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final GameModeId id;
  final String title;
  final String subtitle;

  static const x01 = GameMode(
    id: GameModeId.x01,
    title: 'X01',
    subtitle: '301 / 501 / 701',
  );

  static const cricket = GameMode(
    id: GameModeId.cricket,
    title: 'Cricket',
    subtitle: 'Sulje numerot ja kerää pisteet',
  );

  static const aroundTheClock = GameMode(
    id: GameModeId.aroundTheClock,
    title: 'Around the Clock',
    subtitle: '1 → 20 → Bull',
  );

  static const shanghai = GameMode(
    id: GameModeId.shanghai,
    title: 'Shanghai',
    subtitle: 'Osu 1→20, bonus tripla+tupla+sinko',
  );

  static const killer = GameMode(
    id: GameModeId.killer,
    title: 'Killer',
    subtitle: 'Eliminaatio ja taktiikka',
  );

  static const defaults = <GameMode>[
    x01,
    cricket,
    aroundTheClock,
    shanghai,
    killer,
  ];

  static GameMode? tryFromRouteName(String routeName) {
    final parts = routeName.split('/');
    final last = parts.isNotEmpty ? parts.last : '';
    switch (last) {
      case 'x01':
        return x01;
      case 'cricket':
        return cricket;
      case 'around':
        return aroundTheClock;
      case 'shanghai':
        return shanghai;
      case 'killer':
        return killer;
      default:
        return null;
    }
  }

  String get routeSegment => switch (id) {
        GameModeId.x01 => 'x01',
        GameModeId.cricket => 'cricket',
        GameModeId.aroundTheClock => 'around',
        GameModeId.shanghai => 'shanghai',
        GameModeId.killer => 'killer',
      };
}

