import 'package:flutter/material.dart';

import '../../players/player_profile.dart';
import '../game_rules.dart';
import '../game_mode.dart';

class X01SetupView extends StatefulWidget {
  const X01SetupView({
    super.key,
    required this.players,
    required this.profiles,
    required this.onBack,
    required this.onStart,
  });

  static const routeName = '/game/x01/setup';

  final List<String> players;
  final List<PlayerProfile> profiles;
  final VoidCallback onBack;
  final void Function(X01Setup setup, {bool entrySongsEnabled, List<PlayerProfile>? profiles}) onStart;

  @override
  State<X01SetupView> createState() => _X01SetupViewState();
}

class _X01SetupViewState extends State<X01SetupView> {
  static const _startOptions = <int>[101, 201, 301, 501, 701];

  int _startScore = 301;
  bool _entrySongsEnabled = true;

  bool get _hasAnyEntrySong =>
      widget.profiles.any((p) =>
          p.entrySong != null && p.entrySong!.trim().isNotEmpty);

  void _start() {
    widget.onStart(
      X01Setup(
        startScore: _startScore,
        players: widget.players,
      ),
      entrySongsEnabled: _entrySongsEnabled && _hasAnyEntrySong,
      profiles: widget.profiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Säännöt',
                    onPressed: () => GameRules.show(context, GameModeId.x01),
                    icon: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    'X01',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aloituspisteet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final v in _startOptions)
                          ChoiceChip(
                            label: Text('$v'),
                            selected: _startScore == v,
                            onSelected: (_) => setState(() => _startScore = v),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_hasAnyEntrySong) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _entrySongsEnabled,
                          onChanged: (v) =>
                              setState(() => _entrySongsEnabled = v ?? true),
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return cs.primary;
                            }
                            return null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sisääntulobiisit käyttöön (walkout)',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelaajat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final p in widget.players)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outline),
                            ),
                            child: Text(
                              p,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Aloita peli'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class X01Setup {
  const X01Setup({
    required this.startScore,
    required this.players,
  });

  final int startScore;
  final List<String> players;
}

