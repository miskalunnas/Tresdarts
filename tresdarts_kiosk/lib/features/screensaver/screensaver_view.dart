import 'dart:async';

import 'package:flutter/material.dart';

import 'playlist.dart';

class ScreensaverView extends StatefulWidget {
  const ScreensaverView({super.key, required this.onTap});

  static const routeName = '/screensaver';

  final VoidCallback onTap;

  @override
  State<ScreensaverView> createState() => _ScreensaverViewState();
}

class _ScreensaverViewState extends State<ScreensaverView> {
  static const _playlistAsset = 'assets/config/playlist.json';
  static const _clockTick = Duration(seconds: 1);
  static const _exitTapWindow = Duration(seconds: 2);

  final _pageController = PageController();
  Timer? _timer;
  Timer? _clockTimer;
  Timer? _armTimer;
  ScreensaverPlaylist? _playlist;
  DateTime _now = DateTime.now();
  bool _exitArmed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _clockTimer = Timer.periodic(_clockTick, (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  Future<void> _load() async {
    final playlist = await ScreensaverPlaylist.loadFromAssets(_playlistAsset);
    if (!mounted) return;
    setState(() => _playlist = playlist);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final playlist = _playlist;
    if (playlist == null || playlist.imageAssets.length <= 1) return;

    _timer = Timer.periodic(playlist.imageInterval, (_) {
      if (!_pageController.hasClients) return;
      final current = _pageController.page?.round() ?? 0;
      final next = (current + 1) % playlist.imageAssets.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clockTimer?.cancel();
    _armTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_exitArmed) {
      widget.onTap();
      return;
    }
    setState(() => _exitArmed = true);
    _armTimer?.cancel();
    _armTimer = Timer(_exitTapWindow, () {
      if (!mounted) return;
      setState(() => _exitArmed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlist = _playlist;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ScreensaverBackground(
            playlist: playlist,
            controller: _pageController,
          ),
          _TopClock(now: _now),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _BottomOverlay(
                child: _TapHint(
                  text: playlist == null
                      ? 'Ladataan…'
                      : (_exitArmed
                          ? 'Kosketa uudelleen jatkaaksesi'
                          : 'Kosketa näyttöä herättääksesi'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreensaverBackground extends StatelessWidget {
  const _ScreensaverBackground({
    required this.playlist,
    required this.controller,
  });

  final ScreensaverPlaylist? playlist;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final images = playlist?.imageAssets ?? const <String>[];

    if (images.isEmpty) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 52,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Lisää kuvia tiedostoon assets/config/playlist.json',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PageView.builder(
      controller: controller,
      itemCount: images.length,
      itemBuilder: (context, index) {
        final asset = images[index];
        return _KenBurnsAssetImage(asset: asset);
      },
    );
  }
}

class _KenBurnsAssetImage extends StatelessWidget {
  const _KenBurnsAssetImage({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    // Add a bit more life: slow zoom + subtle pan drift.
    final hash = asset.hashCode;
    final dirX = (hash % 2 == 0) ? 1.0 : -1.0;
    final dirY = (hash % 3 == 0) ? 1.0 : -1.0;
    final driftX = 18.0 * dirX;
    final driftY = 10.0 * dirY;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 14),
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        final scale = 1.02 + (0.06 * t);
        final dx = driftX * (t - 0.5);
        final dy = driftY * (t - 0.5);
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                'Puuttuva asset:\n$asset',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopClock extends StatelessWidget {
  const _TopClock({required this.now});

  final DateTime now;

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _weekdayFi => switch (now.weekday) {
        DateTime.monday => 'ma',
        DateTime.tuesday => 'ti',
        DateTime.wednesday => 'ke',
        DateTime.thursday => 'to',
        DateTime.friday => 'pe',
        DateTime.saturday => 'la',
        DateTime.sunday => 'su',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final time = '${_two(now.hour)}:${_two(now.minute)}';
    final date = '$_weekdayFi ${now.day}.${now.month}.${now.year}';
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _BottomOverlay(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}

class _TapHint extends StatelessWidget {
  const _TapHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

