import 'package:flutter/material.dart';

import 'idle/idle_controller.dart';
import 'idle/idle_listener.dart';
import '../features/games/game_mode.dart';
import '../features/games/game_mode_view.dart';
import '../features/games/game_start_view.dart';
import '../features/games/x01/x01_game_view.dart';
import '../features/games/x01/x01_player_select_view.dart';
import '../features/games/x01/x01_setup_view.dart';
import '../features/games/cricket/cricket_game_view.dart';
import '../features/games/around/around_game_view.dart';
import '../features/games/shanghai/shanghai_game_view.dart';
import '../features/games/killer/killer_game_view.dart';
import '../features/games/killer/killer_setup_view.dart';
import '../features/menu/home_menu_view.dart';
import '../features/screensaver/screensaver_view.dart';
import '../features/leaderboard/game_result.dart';
import '../features/leaderboard/leaderboard_repository.dart';
import '../features/leaderboard/leaderboard_view.dart';
import '../features/settings/settings_view.dart';
import '../features/about/about_view.dart';
import '../features/players/player_create_view.dart';
import '../features/players/player_edit_view.dart';
import '../features/players/player_profile.dart';
import '../features/players/player_repository.dart';
import '../features/players/walkout_view.dart';
import '../features/players/player_select_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final IdleController _idleController;
  final _leaderboardRepo = LeaderboardRepository();
  final _playerRepo = PlayerRepository();

  @override
  void initState() {
    super.initState();
    _idleController = IdleController(
      timeout: const Duration(seconds: 60),
      onTimeout: () {
        final nav = _navigatorKey.currentState;
        if (nav == null) return;
        nav.pushNamedAndRemoveUntil(
          ScreensaverView.routeName,
          (route) => false,
        );
      },
    )..start();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IdleListener(
      controller: _idleController,
      child: MouseRegion(
        cursor: SystemMouseCursors.none,
        child: Navigator(
        key: _navigatorKey,
        initialRoute: ScreensaverView.routeName,
        onGenerateRoute: (settings) {
          final name = settings.name ?? ScreensaverView.routeName;

          if (name == ScreensaverView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: ScreensaverView.routeName),
              builder: (_) => ScreensaverView(
                onTap: () => _navigatorKey.currentState?.pushReplacementNamed(
                  HomeMenuView.routeName,
                ),
              ),
            );
          }

          if (name == HomeMenuView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: HomeMenuView.routeName),
              builder: (_) => HomeMenuView(
                onSelectGameModes: () => _navigatorKey.currentState?.pushNamed(
                  GameModeSelectView.routeName,
                ),
                onSelectSettings: () =>
                    _navigatorKey.currentState?.pushNamed(SettingsView.routeName),
                onSelectLeaderboard: () => _navigatorKey.currentState?.pushNamed(
                  LeaderboardView.routeName,
                ),
                onSelectAbout: () =>
                    _navigatorKey.currentState?.pushNamed(AboutView.routeName),
                onClose: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  ScreensaverView.routeName,
                  (route) => false,
                ),
              ),
            );
          }

          if (name == AboutView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: AboutView.routeName),
              builder: (_) => const AboutView(),
            );
          }

          if (name == SettingsView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: SettingsView.routeName),
              builder: (_) => const SettingsView(),
            );
          }

          if (name == LeaderboardView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: LeaderboardView.routeName),
              builder: (_) => const LeaderboardView(),
            );
          }

          if (name == GameModeSelectView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: GameModeSelectView.routeName),
              builder: (_) => GameModeSelectView(
                modes: GameMode.defaults,
                onSelectMode: (mode) {
                  if (mode.id == GameModeId.x01) {
                    _navigatorKey.currentState
                        ?.pushNamed(X01PlayerSelectView.routeName);
                    return;
                  }
                  _navigatorKey.currentState?.pushNamed(
                    '/game/${mode.routeSegment}/players',
                    arguments: mode,
                  );
                },
              ),
            );
          }

          if (name == X01PlayerSelectView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: X01PlayerSelectView.routeName),
              builder: (context) => X01PlayerSelectView(
                onBack: () => _navigatorKey.currentState?.pop(),
                onCreateNew: () =>
                    _navigatorKey.currentState?.pushNamed(PlayerCreateView.routeName),
                onSelected: (players) {
                  final names =
                      players.map((p) => p.name).toList(growable: false);
                  final profilesJson =
                      players.map((p) => p.toJson()).toList(growable: false);
                  _navigatorKey.currentState?.pushReplacementNamed(
                    X01SetupView.routeName,
                    arguments: <String, dynamic>{
                      'names': names,
                      'profiles': profilesJson,
                    },
                  );
                },
              ),
            );
          }

          // Generic player select for other modes
          if (name.startsWith('/game/') && name.endsWith('/players')) {
            final modeArg = settings.arguments;
            final mode = modeArg is GameMode ? modeArg : GameMode.tryFromRouteName(name);
            final parsedMode = mode ?? GameMode.cricket;
            return MaterialPageRoute(
              settings: RouteSettings(name: name),
              builder: (context) => PlayerSelectView(
                title: parsedMode.title,
                minPlayers: 1,
                maxPlayers: 8,
                onBack: () => _navigatorKey.currentState?.pop(),
                onCreateNew: () =>
                    _navigatorKey.currentState?.pushNamed(PlayerCreateView.routeName),
                onContinue: (profiles) {
                  final names = profiles.map((p) => p.name).toList(growable: false);
                  final profilesJson = profiles.map((p) => p.toJson()).toList(growable: false);
                  _navigatorKey.currentState?.pushReplacementNamed(
                    GameStartView.routeName,
                    arguments: <String, dynamic>{
                      'mode': parsedMode.id.name,
                      'title': parsedMode.title,
                      'names': names,
                      'profiles': profilesJson,
                    },
                  );
                },
              ),
            );
          }

          if (name == GameStartView.routeName) {
            final args = settings.arguments;
            String title = 'Peli';
            String modeId = GameModeId.cricket.name;
            List<String> names = const ['Pelaaja 1', 'Pelaaja 2'];
            List<PlayerProfile> profiles = const [];
            if (args is Map) {
              title = (args['title'] as String?) ?? title;
              modeId = (args['mode'] as String?) ?? modeId;
              final n = args['names'];
              if (n is List) names = n.whereType<String>().toList();
              final pr = args['profiles'];
              if (pr is List) {
                profiles = pr
                    .map((e) => PlayerProfile.fromJson(
                        e is Map<String, dynamic> ? e : (e is Map ? Map<String, dynamic>.from(e) : null)))
                    .whereType<PlayerProfile>()
                    .toList();
              }
            }
            return MaterialPageRoute(
              settings: const RouteSettings(name: GameStartView.routeName),
              builder: (context) => GameStartView(
                title: title,
                players: names,
                profiles: profiles,
                onBack: () => _navigatorKey.currentState?.pop(),
                onStart: (entrySongsEnabled, profiles) {
                  if (entrySongsEnabled && profiles.isNotEmpty) {
                    _navigatorKey.currentState?.pushReplacementNamed(
                      WalkoutView.routeName,
                      arguments: <String, dynamic>{
                        'profiles': profiles.map((p) => p.toJson()).toList(),
                        'next': <String, dynamic>{
                          'mode': modeId,
                          'names': names,
                        },
                      },
                    );
                    return;
                  }
                  if (modeId == GameModeId.killer.name) {
                    _navigatorKey.currentState?.pushReplacementNamed(
                      KillerSetupView.routeName,
                      arguments: names,
                    );
                    return;
                  }
                  _navigatorKey.currentState?.pushReplacementNamed(
                    '/game/$modeId/play',
                    arguments: names,
                  );
                },
              ),
            );
          }

          if (name == PlayerCreateView.routeName) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: PlayerCreateView.routeName),
              builder: (_) => PlayerCreateView(
                onBack: () => _navigatorKey.currentState?.pop(),
                onCreated: (_) => _navigatorKey.currentState?.pop(),
              ),
            );
          }

          if (name == PlayerEditView.routeName) {
            final args = settings.arguments;
            PlayerProfile? profile;
            if (args is Map) {
              final p = args['profile'];
              if (p is Map) {
                profile = PlayerProfile.fromJson(Map<String, dynamic>.from(p));
              }
            } else if (args is PlayerProfile) {
              profile = args;
            }
            profile ??= PlayerProfile(
              id: 'invalid',
              name: '',
              entrySong: null,
              photoPath: null,
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            );
            return MaterialPageRoute(
              settings: RouteSettings(name: PlayerEditView.routeName),
              builder: (_) => PlayerEditView(
                initialProfile: profile!,
                onBack: () => _navigatorKey.currentState?.pop(),
                onSaved: (p) => _navigatorKey.currentState?.pop(p),
              ),
            );
          }

          if (name == X01SetupView.routeName) {
            final args = settings.arguments;
            List<String> names = const ['Pelaaja 1', 'Pelaaja 2'];
            List<PlayerProfile> profiles = const [];
            if (args is Map) {
              final n = args['names'];
              if (n is List) {
                names = n.whereType<String>().toList();
              }
              final pr = args['profiles'];
              if (pr is List) {
                profiles = pr
                    .map((e) => PlayerProfile.fromJson(
                        e is Map<String, dynamic> ? e : (e is Map ? Map<String, dynamic>.from(e) : null)))
                    .whereType<PlayerProfile>()
                    .toList();
              }
            }
            return MaterialPageRoute(
              settings: const RouteSettings(name: X01SetupView.routeName),
              builder: (context) => X01SetupView(
                players: names,
                profiles: profiles,
                onBack: () => _navigatorKey.currentState?.pop(),
                onStart: (setup, {entrySongsEnabled = false, List<PlayerProfile>? profiles}) {
                  if (entrySongsEnabled && profiles != null && profiles.isNotEmpty) {
                    _navigatorKey.currentState?.pushReplacementNamed(
                      WalkoutView.routeName,
                      arguments: <String, dynamic>{
                        'profiles': profiles.map((p) => p.toJson()).toList(),
                        'setup': <String, dynamic>{
                          'startScore': setup.startScore,
                          'players': setup.players,
                        },
                      },
                    );
                  } else {
                    _navigatorKey.currentState?.pushReplacementNamed(
                      X01GameView.routeName,
                      arguments: setup,
                    );
                  }
                },
              ),
            );
          }

          if (name == WalkoutView.routeName) {
            final args = settings.arguments;
            List<PlayerProfile> profiles = const [];
            X01Setup? setup;
            if (args is Map) {
              final pr = args['profiles'];
              if (pr is List) {
                profiles = pr
                    .map((e) => PlayerProfile.fromJson(
                        e is Map<String, dynamic> ? e : (e is Map ? Map<String, dynamic>.from(e) : null)))
                    .whereType<PlayerProfile>()
                    .toList();
              }
              final s = args['setup'];
              if (s is Map) {
                final startScore = s['startScore'] is int ? s['startScore'] as int : 301;
                final players = s['players'] is List
                    ? (s['players'] as List).whereType<String>().toList()
                    : const ['Pelaaja 1', 'Pelaaja 2'];
                setup = X01Setup(startScore: startScore, players: players);
              }
              final next = args['next'];
              if (setup == null && next is Map) {
                final modeId = next['mode'] as String?;
                final players = next['names'] is List
                    ? (next['names'] as List).whereType<String>().toList()
                    : const ['Pelaaja 1', 'Pelaaja 2'];
                return MaterialPageRoute(
                  settings: const RouteSettings(name: WalkoutView.routeName),
                  builder: (context) => WalkoutView(
                    profiles: profiles,
                    onComplete: () {
                      _navigatorKey.currentState?.pushReplacementNamed(
                        '/game/${modeId ?? GameModeId.cricket.name}/play',
                        arguments: players,
                      );
                    },
                  ),
                );
              }
            }
            setup ??= const X01Setup(startScore: 301, players: ['Pelaaja 1', 'Pelaaja 2']);
            return MaterialPageRoute(
              settings: const RouteSettings(name: WalkoutView.routeName),
              builder: (context) => WalkoutView(
                profiles: profiles,
                onComplete: () {
                  _navigatorKey.currentState?.pushReplacementNamed(
                    X01GameView.routeName,
                    arguments: setup,
                  );
                },
              ),
            );
          }

          if (name == '/game/${GameModeId.cricket.name}/play') {
            final args = settings.arguments;
            final players = args is List ? args.whereType<String>().toList() : const ['Pelaaja 1', 'Pelaaja 2'];
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/game/cricket/play'),
              builder: (context) => CricketGameView(
                players: players,
                onExit: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  HomeMenuView.routeName,
                  (route) => false,
                ),
                onFinished: (result) async {
                  await _leaderboardRepo.saveResult(result);
                  if (!context.mounted) return;
                  _navigatorKey.currentState?.pushNamed(LeaderboardView.routeName);
                },
              ),
            );
          }

          if (name == '/game/${GameModeId.aroundTheClock.name}/play') {
            final args = settings.arguments;
            final players = args is List ? args.whereType<String>().toList() : const ['Pelaaja 1', 'Pelaaja 2'];
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/game/around/play'),
              builder: (context) => AroundGameView(
                players: players,
                onExit: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  HomeMenuView.routeName,
                  (route) => false,
                ),
                onFinished: (result) async {
                  await _leaderboardRepo.saveResult(result);
                  if (!context.mounted) return;
                  _navigatorKey.currentState?.pushNamed(LeaderboardView.routeName);
                },
              ),
            );
          }

          if (name == '/game/${GameModeId.shanghai.name}/play') {
            final args = settings.arguments;
            final players = args is List ? args.whereType<String>().toList() : const ['Pelaaja 1', 'Pelaaja 2'];
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/game/shanghai/play'),
              builder: (context) => ShanghaiGameView(
                players: players,
                onExit: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  HomeMenuView.routeName,
                  (route) => false,
                ),
                onFinished: (result) async {
                  await _leaderboardRepo.saveResult(result);
                  if (!context.mounted) return;
                  _navigatorKey.currentState?.pushNamed(LeaderboardView.routeName);
                },
              ),
            );
          }

          if (name == '/game/${GameModeId.killer.name}/play') {
            final args = settings.arguments;
            final payload = args;
            List<String> players = const ['Pelaaja 1', 'Pelaaja 2'];
            KillerSetup? setup;
            if (payload is Map) {
              final p = payload['players'];
              if (p is List) players = p.whereType<String>().toList();
              final s = payload['setup'];
              if (s is Map) {
                final numsRaw = s['numbers'];
                final numbers = <int, int>{};
                if (numsRaw is Map) {
                  for (final e in numsRaw.entries) {
                    final k = int.tryParse(e.key.toString());
                    final v = e.value is int ? e.value as int : int.tryParse(e.value.toString());
                    if (k != null && v != null) numbers[k] = v;
                  }
                }
                setup = KillerSetup(
                  playerNumbers: numbers,
                  lives: s['lives'] is int ? s['lives'] as int : 3,
                  killsToBecomeKiller: s['killsToBecomeKiller'] is int ? s['killsToBecomeKiller'] as int : 3,
                );
              }
            } else if (payload is List) {
              players = payload.whereType<String>().toList();
            }
            setup ??= KillerSetup(
              playerNumbers: {for (var i = 0; i < players.length; i++) i: 20 - i},
              lives: 3,
              killsToBecomeKiller: 3,
            );
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/game/killer/play'),
              builder: (context) => KillerGameView(
                players: players,
                setup: setup!,
                onExit: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  HomeMenuView.routeName,
                  (route) => false,
                ),
                onFinished: (result) async {
                  await _leaderboardRepo.saveResult(result);
                  if (!context.mounted) return;
                  _navigatorKey.currentState?.pushNamed(LeaderboardView.routeName);
                },
              ),
            );
          }

          if (name == KillerSetupView.routeName) {
            final args = settings.arguments;
            final players = args is List ? args.whereType<String>().toList() : const ['Pelaaja 1', 'Pelaaja 2'];
            return MaterialPageRoute(
              settings: const RouteSettings(name: KillerSetupView.routeName),
              builder: (context) => KillerSetupView(
                players: players,
                onBack: () => _navigatorKey.currentState?.pop(),
                onStart: (setup) {
                  _navigatorKey.currentState?.pushReplacementNamed(
                    '/game/${GameModeId.killer.name}/play',
                    arguments: <String, dynamic>{
                      'players': players,
                      'setup': <String, dynamic>{
                        'numbers': setup.playerNumbers.map((k, v) => MapEntry('$k', v)),
                        'lives': setup.lives,
                        'killsToBecomeKiller': setup.killsToBecomeKiller,
                      },
                    },
                  );
                },
              ),
            );
          }

          if (name == X01GameView.routeName) {
            final args = settings.arguments;
            final setup = args is X01Setup ? args : const X01Setup(startScore: 301, players: ['Pelaaja 1', 'Pelaaja 2']);
            return MaterialPageRoute(
              settings: const RouteSettings(name: X01GameView.routeName),
              builder: (context) => X01GameView(
                startScore: setup.startScore,
                players: setup.players,
                onExit: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  HomeMenuView.routeName,
                  (route) => false,
                ),
                onFinished: (result) async {
                  await _leaderboardRepo.saveResult(result);
                  for (final name in result.players) {
                    final trimmed = name.trim();
                    if (trimmed.isEmpty) continue;
                    if (trimmed.toLowerCase().startsWith('vieras')) continue;
                    await _playerRepo.upsertByName(name: trimmed);
                  }
                  if (!context.mounted) return;
                  _navigatorKey.currentState?.pushNamed(LeaderboardView.routeName);
                },
              ),
            );
          }

          if (name.startsWith(GameModeView.routePrefix)) {
            final mode = settings.arguments;
            final parsedMode = mode is GameMode
                ? mode
                : GameMode.tryFromRouteName(name);
            final gameMode = parsedMode ?? GameMode.x01;
            return MaterialPageRoute(
              settings: RouteSettings(name: name),
              builder: (context) => GameModeView(
                mode: gameMode,
                onExit: () => _navigatorKey.currentState?.pop(),
                onGameEnd: (m) async {
                  final result = GameResult(
                    gameModeId: m.id,
                    winnerName: 'Voittaja',
                    players: ['Pelaaja 1', 'Pelaaja 2'],
                    playedAt: DateTime.now(),
                  );
                  await _leaderboardRepo.saveResult(result);
                  if (!context.mounted) return;
                  _navigatorKey.currentState?.pushNamed(LeaderboardView.routeName);
                },
              ),
            );
          }

          return MaterialPageRoute(
            settings: const RouteSettings(name: ScreensaverView.routeName),
            builder: (_) => ScreensaverView(
              onTap: () => _navigatorKey.currentState?.pushReplacementNamed(
                HomeMenuView.routeName,
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

