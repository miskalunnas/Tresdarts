import 'package:flutter/material.dart';

class KioskKeyboard {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    String hintText = '',
    bool multiline = false,
    int maxLength = 40,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _KeyboardSheet(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        multiline: multiline,
        maxLength: maxLength,
      ),
    );
  }
}

class _KeyboardSheet extends StatefulWidget {
  const _KeyboardSheet({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.multiline,
    required this.maxLength,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final bool multiline;
  final int maxLength;

  @override
  State<_KeyboardSheet> createState() => _KeyboardSheetState();
}

class _KeyboardSheetState extends State<_KeyboardSheet> {
  late String _value;
  bool _shift = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _add(String s) {
    if (_value.length >= widget.maxLength) return;
    setState(() => _value += s);
  }

  void _backspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  void _clear() => setState(() => _value = '');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final rows = _shift
        ? const [
            'QWERTYUIOP',
            'ASDFGHJKL',
            'ZXCVBNM',
          ]
        : const [
            'qwertyuiop',
            'asdfghjkl',
            'zxcvbnm',
          ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_value.trim()),
                  child: const Text('OK'),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline),
              ),
              child: Text(
                _value.isEmpty ? widget.hintText : _value,
                maxLines: widget.multiline ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _value.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            for (final r in rows) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final ch in r.split(''))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: _Key(
                        label: ch,
                        onTap: () => _add(ch),
                      ),
                    ),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Key(
                  icon: Icons.arrow_upward,
                  selected: _shift,
                  onTap: () => setState(() => _shift = !_shift),
                  width: 56,
                ),
                const SizedBox(width: 8),
                _Key(
                  label: 'Space',
                  onTap: () => _add(' '),
                  width: 240,
                ),
                const SizedBox(width: 8),
                _Key(
                  icon: Icons.backspace_outlined,
                  onTap: _backspace,
                  width: 56,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _value.isEmpty ? null : _clear,
                    child: const Text('Tyhjennä'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_value.trim()),
                    child: const Text('Valmis'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.onTap,
    this.width = 44,
    this.selected = false,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? cs.primaryContainer.withValues(alpha: 0.35) : null,
        ),
        onPressed: onTap,
        child: icon != null
            ? Icon(icon, size: 18)
            : Text(
                label!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
      ),
    );
  }
}

