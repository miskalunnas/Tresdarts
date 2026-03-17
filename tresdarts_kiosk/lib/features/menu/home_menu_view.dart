import 'package:flutter/material.dart';

class HomeMenuView extends StatelessWidget {
  const HomeMenuView({
    super.key,
    required this.onSelectGameModes,
    required this.onSelectSettings,
    required this.onSelectLeaderboard,
  });

  static const routeName = '/menu';

  final VoidCallback onSelectGameModes;
  final VoidCallback onSelectSettings;
  final VoidCallback onSelectLeaderboard;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = '${_two(now.hour)}:${_two(now.minute)}';
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    cs.primary.withValues(alpha: 0.18),
                    cs.surface,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tresdarts',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Valitse toiminto',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
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
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              time,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Sulje'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _HeroCTA(
                    title: 'Darts',
                    subtitle: 'Pelimuodot, pelin aloitus ja pisteet',
                    buttonText: 'Aloita',
                    onPressed: onSelectGameModes,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 900 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.55,
                          children: [
                            _MenuTile(
                              title: 'Asetukset',
                              subtitle: 'Näyttö, kiosk ja media',
                              icon: Icons.settings,
                              onTap: onSelectSettings,
                              disabled: false,
                            ),
                            _MenuTile(
                              title: 'Tulokset',
                              subtitle: 'Leaderboard ja pelihistoriat',
                              icon: Icons.leaderboard,
                              onTap: onSelectLeaderboard,
                              disabled: false,
                            ),
                            _MenuTile(
                              title: 'Tietoja',
                              subtitle: 'Versio ja laite',
                              icon: Icons.info_outline,
                              onTap: () {},
                              disabled: true,
                            ),
                            _MenuTile(
                              title: 'Huolto',
                              subtitle: 'Tulee myöhemmin',
                              icon: Icons.build_outlined,
                              onTap: () {},
                              disabled: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCTA extends StatelessWidget {
  const _HeroCTA({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.55),
            cs.surfaceContainerHighest.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer.withValues(alpha: 0.9),
              ),
              child: Icon(
                Icons.sports,
                size: 34,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(buttonText),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: disabled ? null : onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surfaceContainerHighest.withValues(alpha: disabled ? 0.35 : 0.8),
              cs.surfaceContainerHighest.withValues(alpha: disabled ? 0.25 : 0.65),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (disabled ? cs.surface : cs.primaryContainer)
                      .withValues(alpha: 0.9),
                ),
                child: Icon(
                  icon,
                  color: disabled ? cs.onSurfaceVariant : cs.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: disabled ? cs.onSurfaceVariant : cs.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

