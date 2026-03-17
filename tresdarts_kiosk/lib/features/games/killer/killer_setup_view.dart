import 'package:flutter/material.dart';

class KillerSetupView extends StatefulWidget {
  const KillerSetupView({
    super.key,
    required this.players,
    required this.onBack,
    required this.onStart,
  });

  static const routeName = '/game/killer/setup';

  final List<String> players;
  final VoidCallback onBack;
  final void Function(KillerSetup setup) onStart;

  @override
  State<KillerSetupView> createState() => _KillerSetupViewState();
}

class _KillerSetupViewState extends State<KillerSetupView> {
  final Map<int, int> _numbers = {}; // playerIndex -> number 1..20

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.players.length; i++) {
      _numbers[i] = 20 - i; // simple default
      if (_numbers[i]!.clamp(1, 20) != _numbers[i]) _numbers[i] = 20;
    }
  }

  bool get _valid {
    final vals = _numbers.values.toList();
    if (vals.any((v) => v < 1 || v > 20)) return false;
    return vals.toSet().length == vals.length;
  }

  void _start() {
    if (!_valid) return;
    widget.onStart(
      KillerSetup(
        playerNumbers: Map<int, int>.from(_numbers),
        lives: 3,
        killsToBecomeKiller: 3,
      ),
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
                  Text(
                    'Killer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
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
                      'Valitse pelaajille omat numerot (1–20)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < widget.players.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.players[i],
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                initialValue: _numbers[i],
                                items: [
                                  for (var n = 1; n <= 20; n++)
                                    DropdownMenuItem(
                                      value: n,
                                      child: Text('$n'),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _numbers[i] = v ?? 20),
                                decoration: const InputDecoration(
                                  labelText: 'Numero',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_valid)
                      Text(
                        'Numeroiden pitää olla uniikkeja.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.error),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _valid ? _start : null,
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

class KillerSetup {
  const KillerSetup({
    required this.playerNumbers,
    required this.lives,
    required this.killsToBecomeKiller,
  });

  final Map<int, int> playerNumbers;
  final int lives;
  final int killsToBecomeKiller;
}

