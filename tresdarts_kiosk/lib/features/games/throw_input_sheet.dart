import 'package:flutter/material.dart';

import 'darts_throw.dart';

class ThrowInputSheet extends StatefulWidget {
  const ThrowInputSheet({
    super.key,
    required this.onPick,
    this.title = 'Lisää heitto',
    this.maxPicks = 1,
    this.onPickMany,
  });

  final void Function(DartThrow t) onPick;
  final String title;
  final int maxPicks;
  final void Function(List<DartThrow> throws)? onPickMany;

  static Future<void> show(
    BuildContext context, {
    required void Function(DartThrow t) onPick,
    String title = 'Lisää heitto',
    int maxPicks = 1,
    void Function(List<DartThrow> throws)? onPickMany,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ThrowInputSheet(
        onPick: onPick,
        onPickMany: onPickMany,
        maxPicks: maxPicks.clamp(1, 3),
        title: title,
      ),
    );
  }

  @override
  State<ThrowInputSheet> createState() => _ThrowInputSheetState();
}

class _ThrowInputSheetState extends State<ThrowInputSheet> {
  DartMultiplier _m = DartMultiplier.single;
  int? _selectedNumber;
  final List<DartThrow> _picked = [];

  void _pick(DartThrow t) {
    final max = widget.maxPicks.clamp(1, 3);
    if (_picked.length >= max) return;
    setState(() => _picked.add(t));
    if (_picked.length >= max) {
      _finish();
    }
  }

  void _finish() {
    if (_picked.isEmpty) return;
    widget.onPickMany?.call(List<DartThrow>.unmodifiable(_picked));
    if (widget.onPickMany == null) {
      // Backwards compatible: if caller didn't provide onPickMany, call onPick once.
      widget.onPick(_picked.first);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final max = widget.maxPicks.clamp(1, 3);
    final h = MediaQuery.of(context).size.height;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: h * 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
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
                    max > 1 ? '${widget.title} (${_picked.length + 1}/$max)' : widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                  const Spacer(),
                  if (max > 1)
                    TextButton(
                      onPressed: _picked.isEmpty ? null : _finish,
                      child: const Text('Valmis'),
                    ),
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
                        ButtonSegment(value: DartMultiplier.single, label: Text('Single')),
                        ButtonSegment(value: DartMultiplier.double, label: Text('Double')),
                        ButtonSegment(value: DartMultiplier.triple, label: Text('Triple')),
                      ],
                      selected: {_m},
                      onSelectionChanged: (s) {
                        setState(() => _m = s.first);
                      },
                    ),
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
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: 21,
                  itemBuilder: (context, index) {
                    final n = index; // 0..20
                    final selected = _selectedNumber == n;
                    return OutlinedButton(
                      onPressed: () {
                        setState(() => _selectedNumber = n);
                        _pick(
                          n == 0
                              ? const DartThrow(
                                  segment: DartSegment.miss,
                                  multiplier: DartMultiplier.single,
                                )
                              : DartThrow(
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
      ),
    );
  }
}

