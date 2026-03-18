import 'package:flutter/material.dart';

import 'kiosk_keyboard.dart';

class KioskTextField extends StatelessWidget {
  const KioskTextField({
    super.key,
    required this.controller,
    required this.title,
    this.hintText,
    this.enabled = true,
    this.maxLength = 40,
    this.multiline = false,
    this.decoration,
    this.onChanged,
  });

  final TextEditingController controller;
  final String title;
  final String? hintText;
  final bool enabled;
  final int maxLength;
  final bool multiline;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    final next = await KioskKeyboard.show(
      context,
      title: title,
      initialValue: controller.text,
      hintText: hintText ?? '',
      multiline: multiline,
      maxLength: maxLength,
    );
    if (next == null) return;
    controller.text = next;
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final d = decoration ??
        InputDecoration(
          labelText: title,
          hintText: hintText,
          border: const OutlineInputBorder(),
        );

    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: true, // disable OS keyboard
      showCursor: true,
      enableInteractiveSelection: false,
      maxLines: multiline ? 3 : 1,
      decoration: d,
      onTap: () => _open(context),
    );
  }
}

