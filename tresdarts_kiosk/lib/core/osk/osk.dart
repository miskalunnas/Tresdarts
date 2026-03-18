import 'dart:io';

/// Kioski-Linux: avaa OS:n on-screen keyboard (esim. onboard) kun tekstikenttää kosketaan.
///
/// Tämä on best-effort: jos OSK ei ole asennettu, kutsu ei tee mitään.
class Osk {
  static DateTime? _lastLaunch;

  static Future<void> maybeShow() async {
    if (!Platform.isLinux) return;

    final now = DateTime.now();
    final last = _lastLaunch;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastLaunch = now;

    // Common OSK choices on Raspberry Pi / Debian.
    const candidates = <List<String>>[
      ['onboard'],
      ['wvkbd-mobintl'],
      ['wvkbd'],
    ];

    for (final cmd in candidates) {
      try {
        // runInShell helps when PATH differs under autostart/systemd.
        await Process.start(
          cmd.first,
          cmd.length > 1 ? cmd.sublist(1) : const [],
          runInShell: true,
        );
        return;
      } catch (_) {
        // Try next candidate.
      }
    }
  }
}

