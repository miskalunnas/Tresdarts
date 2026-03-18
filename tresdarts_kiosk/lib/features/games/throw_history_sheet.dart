import 'package:flutter/material.dart';

import 'darts_throw.dart';
import 'throw_input_sheet.dart';

class ThrowHistorySheet extends StatefulWidget {
  const ThrowHistorySheet({
    super.key,
    required this.throws,
    required this.onReplace,
    required this.onDelete,
  });

  final List<DartThrow> throws;
  final void Function(int index, DartThrow t) onReplace;
  final void Function(int index) onDelete;

  static Future<void> show(
    BuildContext context, {
    required List<DartThrow> throws,
    required void Function(int index, DartThrow t) onReplace,
    required void Function(int index) onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ThrowHistorySheet(
        throws: throws,
        onReplace: onReplace,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ThrowHistorySheet> createState() => _ThrowHistorySheetState();
}

class _ThrowHistorySheetState extends State<ThrowHistorySheet> {
  late List<DartThrow> _throws;

  @override
  void initState() {
    super.initState();
    _throws = [...widget.throws];
  }

  @override
  void didUpdateWidget(covariant ThrowHistorySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.throws != widget.throws) {
      _throws = [...widget.throws];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
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
                  'Muokkaa heittoja',
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
            const SizedBox(height: 8),
            if (_throws.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ei heittoja.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView.builder(
                  itemCount: _throws.length,
                  itemBuilder: (context, index) {
                    final originalIndex = _throws.length - 1 - index;
                    final t = _throws[originalIndex];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: ListTile(
                        title: Text(
                          '${index + 1}. ${t.label} (${t.points})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                        ),
                        subtitle: Text(
                          'Napauta vaihtaaksesi tai roskakori poistaaksesi',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        onTap: () {
                          ThrowInputSheet.show(
                            context,
                            title: 'Vaihda heitto',
                            onPick: (picked) {
                              setState(() => _throws[originalIndex] = picked);
                              widget.onReplace(originalIndex, picked);
                            },
                          );
                        },
                        trailing: IconButton(
                          tooltip: 'Poista',
                          onPressed: () {
                            setState(() => _throws.removeAt(originalIndex));
                            widget.onDelete(originalIndex);
                          },
                          icon: Icon(Icons.delete_outline, color: cs.onSurfaceVariant),
                        ),
                      );
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

