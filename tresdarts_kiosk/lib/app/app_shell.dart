import 'package:flutter/material.dart';

import 'idle/idle_controller.dart';
import 'idle/idle_listener.dart';
import '../features/games/game_mode.dart';
import '../features/games/game_mode_view.dart';
import '../features/menu/home_menu_view.dart';
import '../features/screensaver/screensaver_view.dart';
import '../features/leaderboard/game_result.dart';
import '../features/leaderboard/leaderboard_repository.dart';
import '../features/leaderboard/leaderboard_view.dart';
import '../features/settings/settings_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final IdleController _idleController;
  final _leaderboardRepo = LeaderboardRepository();

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
                onClose: () => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  ScreensaverView.routeName,
                  (route) => false,
                ),
              ),
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
                onSelectMode: (mode) =>
                    _navigatorKey.currentState?.pushNamed(
                  GameModeView.routeNameFor(mode),
                  arguments: mode,
                ),
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

