import 'dart:math';

import 'package:flutter/material.dart';

Future<List<String>?> showTurnOrderSpinnerDialog(
  BuildContext context, {
  required List<String> players,
}) {
  if (players.length <= 1) return Future.value(null);
  return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _TurnOrderSpinnerDialog(players: players),
  );
}

class _TurnOrderSpinnerDialog extends StatefulWidget {
  const _TurnOrderSpinnerDialog({required this.players});

  final List<String> players;

  @override
  State<_TurnOrderSpinnerDialog> createState() => _TurnOrderSpinnerDialogState();
}

class _TurnOrderSpinnerDialogState extends State<_TurnOrderSpinnerDialog>
    with SingleTickerProviderStateMixin {
  late List<String> _order;
  late AnimationController _c;
  late Animation<double> _rot;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _order = [...widget.players];
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _rot = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() => _spinning = true);

    final rnd = Random();
    final next = [...widget.players]..shuffle(rnd);
    final extraTurns = 2 + rnd.nextInt(4); // 2..5 turns

    _c.reset();
    _c.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() {
      _order = next;
    });

    // finish animation with a bit more rotation
    await Future.delayed(Duration(milliseconds: 200 + extraTurns * 20));
    if (!mounted) return;
    setState(() => _spinning = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Arvo heittojärjestys'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _rot,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rot.value * pi * 6,
                child: child,
              );
            },
            child: Icon(Icons.casino, size: 48, color: cs.primary),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _order.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _order[i],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _spinning ? null : () => Navigator.of(context).pop(null),
          child: const Text('Ohita'),
        ),
        OutlinedButton(
          onPressed: _spinning ? null : _spin,
          child: const Text('Pyöritä'),
        ),
        FilledButton(
          onPressed: _spinning ? null : () => Navigator.of(context).pop(_order),
          child: const Text('Hyväksy'),
        ),
      ],
    );
  }
}

