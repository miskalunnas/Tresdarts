import 'package:flutter/material.dart';

import 'game_mode.dart';

class GameModeView extends StatelessWidget {
  const GameModeView({
    super.key,
    required this.mode,
    required this.onExit,
    this.onGameEnd,
  });

  final GameMode mode;
  final VoidCallback onExit;
  final void Function(GameMode mode)? onGameEnd;

  static const routePrefix = '/game';

  static String routeNameFor(GameMode mode) => '$routePrefix/${mode.routeSegment}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onExit,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  const Icon(Icons.sports_bar, size: 22),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                mode.title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                mode.subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              if (onGameEnd != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: () => onGameEnd!(mode),
                    icon: const Icon(Icons.flag),
                    label: const Text('Peli ohi – tallenna tulos'),
                  ),
                ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Tähän tulee ${mode.title}-pelin logiikka.',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameModeSelectView extends StatelessWidget {
  const GameModeSelectView({
    super.key,
    required this.modes,
    required this.onSelectMode,
  });

  static const routeName = '/modes';

  final List<GameMode> modes;
  final void Function(GameMode mode) onSelectMode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      'Pelimuodot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 900 ? 3 : 2;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.45,
                      ),
                      itemCount: modes.length,
                      itemBuilder: (context, index) {
                        final mode = modes[index];
                        return _GameModeCard(
                          mode: mode,
                          onTap: () => onSelectMode(mode),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({required this.mode, required this.onTap});

  final GameMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surfaceContainerHighest.withValues(alpha: 0.85),
              cs.surface.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer.withValues(alpha: 0.9),
                    ),
                    child: Icon(
                      mode.icon,
                      size: 30,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 28,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                mode.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                mode.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

