import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app_shell.dart';

/// TRES design: minimal, monochrome + one accent, industrial, startup.
const Color _tresAccent = Color(0xFF00D1B2);
const Color _tresSurface = Color(0xFF0D0D0D);
const Color _tresSurfaceVariant = Color(0xFF1A1A1A);
const Color _tresOnSurface = Color(0xFFF5F5F5);
const Color _tresOnSurfaceVariant = Color(0xFFA3A3A3);
const Color _tresOutline = Color(0xFF2D2D2D);

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
        colorScheme: const ColorScheme.dark(
          primary: _tresAccent,
          onPrimary: Color(0xFF000000),
          primaryContainer: Color(0xFF003D35),
          onPrimaryContainer: _tresAccent,
          surface: _tresSurface,
          onSurface: _tresOnSurface,
          surfaceContainerHighest: _tresSurfaceVariant,
          onSurfaceVariant: _tresOnSurfaceVariant,
          outline: _tresOutline,
          outlineVariant: _tresOutline,
        ),
        useMaterial3: true,
        fontFamily: null,
        textTheme: _tresTextTheme(ThemeData.dark().textTheme),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: _tresOutline),
          ),
        ),
        cardTheme: CardThemeData(
          color: _tresSurfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const AppShell(),
    );
  }
}

TextTheme _tresTextTheme(TextTheme base) {
  return base.copyWith(
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontWeight: FontWeight.w500,
    ),
  );
}
