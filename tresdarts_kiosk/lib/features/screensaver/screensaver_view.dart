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

  final _pageController = PageController();
  Timer? _timer;
  ScreensaverPlaylist? _playlist;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = _playlist;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ScreensaverBackground(playlist: playlist, controller: _pageController),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: _TapHint(
                text: playlist == null
                    ? 'Ladataan…'
                    : 'Kosketa näyttöä jatkaaksesi',
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1220),
              Color(0xFF001B2E),
              Color(0xFF042F2E),
            ],
          ),
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
        return Image.asset(
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
        );
      },
    );
  }
}

class _TapHint extends StatelessWidget {
  const _TapHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.7),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app, size: 18),
          const SizedBox(width: 10),
          Text(text, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

