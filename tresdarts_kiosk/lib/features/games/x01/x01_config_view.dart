import 'package:flutter/material.dart';

import '../game_rules.dart';
import '../game_mode.dart';

class X01ConfigView extends StatefulWidget {
  const X01ConfigView({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  static const routeName = '/game/x01/config';

  final VoidCallback onBack;
  final void Function(int startScore) onContinue;

  @override
  State<X01ConfigView> createState() => _X01ConfigViewState();
}

class _X01ConfigViewState extends State<X01ConfigView> {
  static const _startOptions = <int>[101, 201, 301, 501, 701];
  int _startScore = 301;

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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => widget.onContinue(_startScore),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Valitse pelaajat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

