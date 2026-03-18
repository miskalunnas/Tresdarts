import 'package:flutter/material.dart';

import 'darts_throw.dart';

class ThrowInputSheet extends StatefulWidget {
  const ThrowInputSheet({
    super.key,
    required this.onPick,
    this.title = 'Lisää heitto',
    this.maxPicks = 1,
    this.onPickMany,
    this.remainingPoints,
    this.checkoutText,
  });

  final void Function(DartThrow t) onPick;
  final String title;
  final int maxPicks;
  final void Function(List<DartThrow> throws)? onPickMany;
  final int? remainingPoints;
  final String? checkoutText;

  static Future<void> show(
    BuildContext context, {
    required void Function(DartThrow t) onPick,
    String title = 'Lisää heitto',
    int maxPicks = 1,
    void Function(List<DartThrow> throws)? onPickMany,
    int? remainingPoints,
    String? checkoutText,
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
        remainingPoints: remainingPoints,
        checkoutText: checkoutText,
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
        height: h * 0.88,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.remainingPoints != null || (widget.checkoutText != null && widget.checkoutText!.isNotEmpty)) ...[
                Row(
                  children: [
                    if (widget.remainingPoints != null)
                      Text(
                        'Jäljellä: ${widget.remainingPoints}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                      ),
                    if (widget.remainingPoints != null && widget.checkoutText != null && widget.checkoutText!.isNotEmpty)
                      const SizedBox(width: 16),
                    if (widget.checkoutText != null && widget.checkoutText!.isNotEmpty)
                      Flexible(
                        child: Text(
                          'Lopetus: ${widget.checkoutText}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Text(
                    max > 1 ? '${_picked.length + 1}/$max' : 'Pisteet',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                    icon: const Icon(Icons.close, size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Kerroin (S/D/T)
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
                ],
              ),
              const SizedBox(height: 8),
              // Bullit
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
                      child: const Text('25'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(
                        const DartThrow(
                          segment: DartSegment.bull50,
                          multiplier: DartMultiplier.single,
                        ),
                      ),
                      child: const Text('50'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Kaikki numerot 0–20: 7 saraketta = 3 riviä, ei scrollia
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 21,
                  itemBuilder: (context, index) {
                    final n = index;
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor:
                            selected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
                      ),
                      child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w600)),
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

