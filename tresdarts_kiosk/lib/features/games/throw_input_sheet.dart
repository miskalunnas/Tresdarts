import 'package:flutter/material.dart';

import 'darts_throw.dart';

class ThrowInputSheet extends StatefulWidget {
  const ThrowInputSheet({
    super.key,
    required this.onPick,
    this.title = 'Lisää heitto',
  });

  final void Function(DartThrow t) onPick;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required void Function(DartThrow t) onPick,
    String title = 'Lisää heitto',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ThrowInputSheet(onPick: onPick, title: title),
    );
  }

  @override
  State<ThrowInputSheet> createState() => _ThrowInputSheetState();
}

class _ThrowInputSheetState extends State<ThrowInputSheet> {
  DartMultiplier _m = DartMultiplier.single;
  int? _selectedNumber;

  void _pick(DartThrow t) {
    widget.onPick(t);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<DartMultiplier>(
                    segments: const [
                      ButtonSegment(value: DartMultiplier.single, label: Text('S')),
                      ButtonSegment(value: DartMultiplier.double, label: Text('D')),
                      ButtonSegment(value: DartMultiplier.triple, label: Text('T')),
                    ],
                    selected: {_m},
                    onSelectionChanged: (s) {
                      setState(() => _m = s.first);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _pick(
                    const DartThrow(
                      segment: DartSegment.miss,
                      multiplier: DartMultiplier.single,
                    ),
                  ),
                  child: const Text('MISS'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(
                      const DartThrow(
                        segment: DartSegment.bull25,
                        multiplier: DartMultiplier.single,
                      ),
                    ),
                    child: const Text('BULL 25'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(
                      const DartThrow(
                        segment: DartSegment.bull50,
                        multiplier: DartMultiplier.single,
                      ),
                    ),
                    child: const Text('BULL 50'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  final n = index + 1;
                  final selected = _selectedNumber == n;
                  return OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedNumber = n);
                      _pick(
                        DartThrow(
                          segment: DartSegment.numbered(n),
                          multiplier: _m,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          selected ? cs.primaryContainer.withValues(alpha: 0.25) : null,
                    ),
                    child: Text('$n'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

