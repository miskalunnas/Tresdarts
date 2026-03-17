import 'package:flutter/material.dart';

class HomeMenuView extends StatelessWidget {
  const HomeMenuView({super.key, required this.onSelectGameModes});

  static const routeName = '/menu';

  final VoidCallback onSelectGameModes;

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
                  Text(
                    'Tresdarts',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Sulje'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Valitse toiminto',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 900
                        ? 3
                        : width >= 600
                            ? 2
                            : 1;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.35,
                      children: [
                        _MenuTile(
                          title: 'Darts',
                          subtitle: 'Pelimuodot ja pelin aloitus',
                          icon: Icons.sports,
                          onTap: onSelectGameModes,
                        ),
                        _MenuTile(
                          title: 'Media',
                          subtitle: 'Tulee myöhemmin',
                          icon: Icons.slideshow,
                          onTap: () {},
                          disabled: true,
                        ),
                        _MenuTile(
                          title: 'Asetukset',
                          subtitle: 'Tulee myöhemmin',
                          icon: Icons.settings,
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

