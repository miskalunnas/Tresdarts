import 'package:flutter/material.dart';

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
    required this.icon,
  });

  final GameModeId id;
  final String title;
  final String subtitle;
  final IconData icon;

  static const x01 = GameMode(
    id: GameModeId.x01,
    title: 'X01',
    subtitle: '101 / 201 / 301 / 501 / 701',
    icon: Icons.exposure_plus_1,
  );

  static const cricket = GameMode(
    id: GameModeId.cricket,
    title: 'Cricket',
    subtitle: 'Sulje numerot ja kerää pisteet',
    icon: Icons.sports_cricket,
  );

  static const aroundTheClock = GameMode(
    id: GameModeId.aroundTheClock,
    title: 'Around the Clock',
    subtitle: '1 → 20 → Bull',
    icon: Icons.timelapse,
  );

  static const shanghai = GameMode(
    id: GameModeId.shanghai,
    title: 'Shanghai',
    subtitle: 'Osu 1→20, bonus tripla+tupla+sinko',
    icon: Icons.track_changes,
  );

  static const killer = GameMode(
    id: GameModeId.killer,
    title: 'Killer',
    subtitle: 'Eliminaatio ja taktiikka',
    icon: Icons.gps_fixed,
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

