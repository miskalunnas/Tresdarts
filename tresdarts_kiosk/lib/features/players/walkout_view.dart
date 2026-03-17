import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'player_profile.dart';

/// Full-screen walkout mode: shows one player at a time with optional
/// profile photo and plays entry song (file path). Skip or auto-advance when done.
class WalkoutView extends StatefulWidget {
  const WalkoutView({
    super.key,
    required this.profiles,
    required this.onComplete,
  });

  static const routeName = '/walkout';

  final List<PlayerProfile> profiles;
  final VoidCallback onComplete;

  @override
  State<WalkoutView> createState() => _WalkoutViewState();
}

class _WalkoutViewState extends State<WalkoutView> {
  final AudioPlayer _audio = AudioPlayer();
  int _index = 0;
  bool _playing = false;
  bool _error = false;
  Timer? _autoNextTimer;

  List<PlayerProfile> get _list => widget.profiles;

  @override
  void initState() {
    super.initState();
    _audio.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _next();
      }
    });
    _playCurrent();
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _playCurrent() async {
    if (_index >= _list.length) {
      widget.onComplete();
      return;
    }
    final p = _list[_index];
    setState(() {
      _playing = false;
      _error = false;
    });

    final path = p.entrySong?.trim();
    if (path != null && path.isNotEmpty) {
      try {
        if (path.startsWith('asset:')) {
          await _audio.setAsset(path.replaceFirst('asset:', ''));
        } else if (File(path).existsSync()) {
          await _audio.setFilePath(path);
        } else {
          setState(() => _error = true);
        }
      } catch (_) {
        setState(() => _error = true);
      }
      if (mounted && !_error) {
        await _audio.play();
        setState(() => _playing = true);
      }
    }
    // When no song to play, auto-advance after 3 seconds
    if (path == null || path.isEmpty || (mounted && _error)) {
      _autoNextTimer?.cancel();
      _autoNextTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) _next();
      });
    }
  }

  void _next() {
    _autoNextTimer?.cancel();
    _audio.stop();
    setState(() {
      _index++;
      _playing = false;
      _error = false;
    });
    _playCurrent();
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _list.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = _list[_index];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Profile photo or placeholder
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(80),
                  border: Border.all(color: cs.outline, width: 2),
                  image: p.photoPath != null &&
                          p.photoPath!.trim().isNotEmpty &&
                          File(p.photoPath!).existsSync()
                      ? DecorationImage(
                          image: FileImage(File(p.photoPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: p.photoPath == null ||
                        p.photoPath!.trim().isEmpty ||
                        !File(p.photoPath!).existsSync()
                    ? Icon(
                        Icons.person,
                        size: 80,
                        color: cs.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                p.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              if (p.entrySong != null && p.entrySong!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Sisääntulobiisi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
              if (_error)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Biisiä ei voitu toistaa',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.error,
                        ),
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_playing)
                    Icon(Icons.music_note, color: cs.primary, size: 28),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.skip_next, size: 20),
                    label: const Text('Ohita / Seuraava'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
