import 'package:flutter/material.dart';

import 'idle/idle_controller.dart';
import 'idle/idle_listener.dart';
import '../features/games/game_mode.dart';
import '../features/games/game_mode_view.dart';
import '../features/menu/home_menu_view.dart';
import '../features/screensaver/screensaver_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final IdleController _idleController;

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
              ),
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
            return MaterialPageRoute(
              settings: RouteSettings(name: name),
              builder: (_) => GameModeView(
                mode: parsedMode ?? GameMode.x01,
                onExit: () => _navigatorKey.currentState?.pop(),
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
    );
  }
}

