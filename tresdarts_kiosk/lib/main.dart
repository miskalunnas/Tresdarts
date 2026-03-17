import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await WakelockPlus.enable();
  } catch (_) {
    // Pi/Linux: org.freedesktop.ScreenSaver D-Bus may be missing — continue without wakelock
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow();
      await windowManager.setFullScreen(true);
    } catch (_) {
      // Continue without fullscreen if window_manager fails (e.g. on headless/SSH)
    }
  }

  runApp(const TresdartsApp());
}

class TresdartsApp extends StatelessWidget {
  const TresdartsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tresdarts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D1B2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
